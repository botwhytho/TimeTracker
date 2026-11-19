"""Facade for Glamorous Toolkit: the only module GT's PythonBridge calls.

Plain data in, plain data out (dicts, lists, strings, numbers), so nothing Python-specific leaks into
Smalltalk and the internals can change freely. The model lives in this module's state for the life of the
bridge process; it is never saved, because retraining from the full history takes seconds.

Entry dicts mirror TtTrackedTime (see Entry.from_dict): description, details, start (ISO 8601),
duration (seconds), isPlanned, category (absent when a suggestion is wanted), rawData, day.
Category trees are nested {"name": ..., "children": [...]} dicts, as in TtRootCategory.

Separation of concerns: GT owns storage. It sends one clean category tree plus entries (`train`); any
stitching across Lepiter pages happens in Smalltalk, so this module never knows how entries are stored.
Callers must delete their PythonBridge bindings after each call: bound values otherwise stay alive in the
bridge's globals (measured: all 14k+ entry dicts survived a train call).
"""

from __future__ import annotations

import math
import time
from collections import Counter, defaultdict
from pathlib import Path

from tt_suggest.features import Encoder
from tt_suggest.load import Entry, link_siblings, load
from tt_suggest.model import Suggester
from tt_suggest.tree import CategoryTree

# Flag thresholds; see the confidence analysis script for how they were chosen.
AMBIGUOUS_SHARE = 0.9  # a seen description is ambiguous if its top category has < 90% of its history
LOW_MARGIN_QUANTILE = 0.05  # "low margin" = the bottom 5% of margins on held-out predictions
CALIBRATION_TAIL = 3000  # score this many final training entries before learning them
SOFTMAX_TEMPERATURE = 0.1

_state: dict = {}


def reset() -> None:
    _state.clear()


def train_from_path(path: str, include_planned: bool = True) -> dict:
    """Developer tooling only (CLI experiments, tests): train from a Lepiter page file on disk.
    GT must use `train`, so storage stays a Smalltalk concern. Returns status()."""
    entries, tree = load(Path(path).expanduser(), include_planned)
    return _train(entries, tree)


def train(tree: dict, entries: list[dict]) -> dict:
    """The GT training path: a fresh model from in-image data, one category tree plus all entries
    (uncategorized ones are skipped). Returns status()."""
    parsed = [Entry.from_dict(d, i) for i, d in enumerate(entries) if d.get("category")]
    link_siblings(parsed)
    parsed.sort(key=lambda e: (e.start, e.idx))
    return _train(parsed, CategoryTree.from_json(tree))


def suggest_many(entries: list[dict], k: int = 3) -> list[dict]:
    """Suggestions for a batch, typically one day page, in input order. Entries in the same batch
    are treated as one page, so activities typed on the same line see each other as siblings."""
    model = _require_model()
    parsed = [Entry.from_dict(d, i) for i, d in enumerate(entries)]
    link_siblings(parsed)
    return [_suggest(model, e, k) for e in parsed]


def learn(entry: dict) -> None:
    """Learn one saved or corrected entry (it must have a category)."""
    model = _require_model()
    e = Entry.from_dict(entry)
    if not e.category:
        raise ValueError("learn needs an entry with a category")
    if e.category not in _state["tree"].paths:
        raise ValueError(f"unknown category {e.category!r}; retrain after changing the category tree")
    model.learn(e)
    _state["history"][_key(e)][e.category] += 1
    _state["learned_since_training"] += 1


def status() -> dict:
    if "model" not in _state:
        return {"trained": False}
    return {
        "trained": True,
        "entries": _state["entries"],
        "categories": len(_state["tree"].names),
        "train_seconds": round(_state["train_seconds"], 2),
        "low_margin_threshold": _state["low_margin_threshold"],
        "calibration_entries": _state["calibration_entries"],
        "calibration_top1": _state["calibration_top1"],
        "learned_since_training": _state["learned_since_training"],
    }


# ---------------------------------------------------------------------------------------- internals

def _require_model() -> Suggester:
    if "model" not in _state:
        raise RuntimeError("not trained: call train or train_from_path first")
    return _state["model"]


def _key(e: Entry) -> str:
    return e.description.strip().lower()


def _train(entries: list[Entry], tree: CategoryTree) -> dict:
    unknown = {e.category for e in entries} - set(tree.paths)
    if unknown:
        raise ValueError(f"entries use categories missing from the tree: {sorted(unknown)}")
    t0 = time.time()
    model = Suggester(Encoder(tree))
    history: dict[str, Counter] = defaultdict(Counter)
    tail_start = max(0, len(entries) - CALIBRATION_TAIL)
    margins, hits = [], 0
    for i, e in enumerate(entries):
        if i >= tail_start:  # held-out scoring before learning, to calibrate the low-margin flag
            scored = model.scores(e)
            margins.append(scored[1][1] - scored[0][1])
            hits += scored[0][0] == e.category
        model.learn(e)
        history[_key(e)][e.category] += 1
    margins.sort()
    reset()
    _state.update(
        model=model,
        tree=tree,
        history=history,
        entries=len(entries),
        train_seconds=time.time() - t0,
        low_margin_threshold=round(margins[int(LOW_MARGIN_QUANTILE * len(margins))], 4) if margins else 0.0,
        calibration_entries=len(margins),
        calibration_top1=round(hits / len(margins), 4) if margins else None,
        learned_since_training=0,
    )
    return status()


def _suggest(model: Suggester, e: Entry, k: int) -> dict:
    scored = model.scores(e)
    top = scored[:k]
    weights = [math.exp(-cost / SOFTMAX_TEMPERATURE) for _, cost in scored]
    confidence = weights[0] / sum(weights)
    margin = scored[1][1] - scored[0][1] if len(scored) > 1 else math.inf

    seen = _state["history"].get(_key(e))
    reasons = []
    is_new = not seen
    if is_new:
        reasons.append("new description")
    else:
        majority, count = seen.most_common(1)[0]
        if count / sum(seen.values()) < AMBIGUOUS_SHARE:
            reasons.append("description used with several categories")
        if majority != top[0][0]:
            reasons.append(f"usually {majority}")
    if margin < _state["low_margin_threshold"]:
        reasons.append("low margin")
    return {
        "category": top[0][0],
        "path": list(_state["tree"].path(top[0][0])),
        "alternatives": [c for c, _ in top[1:]],
        "confidence": round(confidence, 4),
        "margin": round(margin, 4),
        "is_new": is_new,
        "needs_check": bool(reasons),
        "reasons": reasons,
    }
