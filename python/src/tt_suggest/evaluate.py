"""Progressive-validation experiments: online-from-zero vs 20% warm start."""

from __future__ import annotations

import random
from collections import Counter, defaultdict
from dataclasses import dataclass, field

from tt_suggest.features import Encoder
from tt_suggest.load import Entry
from tt_suggest.model import Suggester
from tt_suggest.tree import CategoryTree


@dataclass
class Record:
    i: int
    truth: str
    top: list[str]
    cold: bool  # description never seen before this point
    slot: frozenset[str]  # all categories typed on the same raw line


@dataclass
class Run:
    name: str
    scenario: str  # online | warm20-frozen | warm20-online | baseline
    features: str
    records: list[Record] = field(default_factory=list)


def _slots(entries: list[Entry]) -> dict[int, frozenset[str]]:
    g: dict[int, set[str]] = defaultdict(set)
    for e in entries:
        g[e.group].add(e.category)
    return {k: frozenset(v) for k, v in g.items()}


def run_vw(entries, tree, feature_set, scenario, warm_frac=0.2, passes=3, ancestors=True,
           graded_cost=False, seed=0, label=None) -> Run:
    enc = Encoder(tree, feature_set, ancestors, graded_cost)
    model = Suggester(enc)
    slots = _slots(entries)
    split = int(len(entries) * warm_frac) if scenario.startswith("warm") else 0
    seen: set[str] = set()
    if split:
        warm = entries[:split]
        rng = random.Random(seed)
        for _ in range(passes):
            block = warm[:]
            rng.shuffle(block)
            for e in block:
                model.learn(e)
        seen |= {e.description.lower() for e in warm}
    variant = {(True, False): "", (False, False): " (flat)", (True, True): " (+graded cost)",
               (False, True): " (graded cost only)"}[(ancestors, graded_cost)]
    run = Run(label or feature_set + variant, scenario, feature_set)
    keep_learning = scenario != "warm20-frozen"
    for i in range(split, len(entries)):
        e = entries[i]
        d = e.description.lower()
        run.records.append(Record(i, e.category, model.predict_topk(e, 3), d not in seen, slots[e.group]))
        seen.add(d)
        if keep_learning:
            model.learn(e)
    return run


def run_baselines(entries, tree: CategoryTree, start=0) -> list[Run]:
    """Streaming count-based baselines (predict-then-update), no ML."""
    slots = _slots(entries)
    glob: Counter = Counter()
    by_desc: dict[str, Counter] = defaultdict(Counter)
    by_slot: dict[tuple, Counter] = defaultdict(Counter)
    runs = {k: Run(k, "baseline", k) for k in ("majority", "desc lookup", "dow×hour majority")}
    seen: set[str] = set()

    def top(c: Counter, fallback: Counter) -> list[str]:
        out = [k for k, _ in c.most_common(3)]
        out += [k for k, _ in fallback.most_common(6) if k not in out]
        return out[:3] or tree.names[:1]  # nothing seen yet: any valid category

    for i, e in enumerate(entries):
        d = e.description.lower()
        key = (e.start.weekday(), e.start.hour)
        if i >= start:
            cold = d not in seen
            runs["majority"].records.append(Record(i, e.category, top(glob, glob), cold, slots[e.group]))
            runs["desc lookup"].records.append(Record(i, e.category, top(by_desc[d], glob), cold, slots[e.group]))
            runs["dow×hour majority"].records.append(Record(i, e.category, top(by_slot[key], glob), cold, slots[e.group]))
        seen.add(d)
        glob[e.category] += 1
        by_desc[d][e.category] += 1
        by_slot[key][e.category] += 1
    return list(runs.values())


def summarize(run: Run, tree: CategoryTree, start: int = 0) -> dict:
    recs = [r for r in run.records if r.i >= start]
    n = len(recs)
    cold = [r for r in recs if r.cold]
    return {
        "run": run.name,
        "scenario": run.scenario,
        "n": n,
        "top1": sum(r.top[0] == r.truth for r in recs) / n,
        "top3": sum(r.truth in r.top for r in recs) / n,
        "root": sum(tree.root(r.top[0]) == tree.root(r.truth) for r in recs) / n,
        "hier_cost": sum(tree.cost(r.top[0], r.truth) for r in recs) / n,
        "slot_hit": sum(r.top[0] in r.slot for r in recs) / n,
        "slot_hit3": sum(bool(r.slot & set(r.top)) for r in recs) / n,
        "cold_n": len(cold),
        "cold_top1": (sum(r.top[0] == r.truth for r in cold) / len(cold)) if cold else float("nan"),
        "cold_root": (sum(tree.root(r.top[0]) == tree.root(r.truth) for r in cold) / len(cold)) if cold else float("nan"),
    }


def rolling(run: Run, window: int = 500, step: int = 100, metric: str = "top1") -> list[tuple[int, float]]:
    def hit(r: Record) -> float:
        if metric == "top1":
            return float(r.top[0] == r.truth)
        if metric == "top3":
            return float(r.truth in r.top)
        if metric == "slot_hit":
            return float(r.top[0] in r.slot)
        raise ValueError(metric)

    vals = [hit(r) for r in run.records]
    idx = [r.i for r in run.records]
    out = []
    for end in range(window, len(vals) + 1, step):
        out.append((idx[end - 1], sum(vals[end - window:end]) / window))
    return out


def per_category(run: Run, start: int = 0) -> list[tuple[str, int, float, str]]:
    """(category, support, recall, most common wrong prediction)."""
    sup: Counter = Counter()
    ok: Counter = Counter()
    wrong: dict[str, Counter] = defaultdict(Counter)
    for r in run.records:
        if r.i < start:
            continue
        sup[r.truth] += 1
        if r.top[0] == r.truth:
            ok[r.truth] += 1
        else:
            wrong[r.truth][r.top[0]] += 1
    return sorted(
        ((c, n, ok[c] / n, (wrong[c].most_common(1)[0][0] if wrong[c] else "")) for c, n in sup.items()),
        key=lambda t: -t[1],
    )


@dataclass
class DayRecord:
    day: str  # day page id
    date: str  # date of the page's first entry
    n: int
    errors: int  # entries whose top-1 suggestion is wrong (would need a correction)
    errors_top3: int  # entries whose truth isn't even in the top-3
    cold: int  # entries with a description never seen on an earlier day


def run_daily(entries: list[Entry], tree: CategoryTree, feature_set: str = "full") -> list[DayRecord]:
    """Day-batch simulation: model is frozen while it suggests a whole day page,
    then learns that page's (corrected) labels. Starts from an empty model."""
    model = Suggester(Encoder(tree, feature_set))
    days: dict[str, list[Entry]] = {}
    for e in entries:
        days.setdefault(e.day, []).append(e)
    order = sorted(days.values(), key=lambda es: min(e.start for e in es))
    seen: set[str] = set()
    out = []
    for es in order:
        tops = [model.predict_topk(e, 3) for e in es]
        out.append(DayRecord(
            day=es[0].day,
            date=min(e.start for e in es).date().isoformat(),
            n=len(es),
            errors=sum(t[0] != e.category for t, e in zip(tops, es)),
            errors_top3=sum(e.category not in t for t, e in zip(tops, es)),
            cold=sum(e.description.lower() not in seen for e in es),
        ))
        for e in es:
            model.learn(e)
        seen |= {e.description.lower() for e in es}
    return out
