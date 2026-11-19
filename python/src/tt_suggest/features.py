"""Turn entries into VW action-dependent-feature (ADF) multiline examples.

Shared line = context about the entry; one line per candidate category carrying
the category and its ancestors, so evidence is shared along the hierarchy.
"""

from __future__ import annotations

import math
import re
from dataclasses import dataclass

from tt_suggest.load import Entry
from tt_suggest.tree import CategoryTree

_TOKEN = re.compile(r"[a-z0-9]+")

# Feature sets for ablations. Namespaces: d=description, x=details, t=time, s=siblings.
FEATURE_SETS: dict[str, set[str]] = {
    "full": {"d", "x", "t", "s"},
    "desc": {"d", "x"},
    "time": {"t"},
    "time+siblings": {"t", "s_count"},
}


def _tokens(text: str) -> list[str]:
    return _TOKEN.findall(text.lower())


def _char_ngrams(text: str, ns=(3, 4)) -> list[str]:
    s = "_" + "_".join(_tokens(text)) + "_"
    return [f"g{n}_{s[i:i + n]}" for n in ns for i in range(len(s) - n + 1)]


def _duration_bucket(seconds: int) -> str:
    for limit, name in [(900, "15m"), (1800, "30m"), (2700, "45m"), (3600, "1h"),
                        (5400, "1h30"), (7200, "2h"), (10800, "3h"), (14400, "4h")]:
        if seconds <= limit:
            return name
    return "4h+"


def _part_of_day(hour: int) -> str:
    if hour < 6:
        return "night"
    if hour < 12:
        return "morning"
    if hour < 17:
        return "afternoon"
    if hour < 21:
        return "evening"
    return "late"


def shared_line(e: Entry, feats: set[str]) -> str:
    parts = ["shared"]
    if "d" in feats and e.description:
        toks = _tokens(e.description)
        parts.append("|d " + " ".join(["w_" + t for t in toks] + ["full_" + "_".join(toks)]
                                      + _char_ngrams(e.description)))
    if "x" in feats and e.details:
        parts.append("|x " + " ".join("w_" + t for t in _tokens(e.details)))
    if "t" in feats:
        h = e.start.hour
        dow = e.start.weekday()
        frac = (h + e.start.minute / 60) / 24
        parts.append(
            "|t "
            + " ".join([
                f"h{h}", f"dow{dow}", f"dh{dow}_{h}", "weekend" if dow >= 5 else "weekday",
                _part_of_day(h), "dur_" + _duration_bucket(e.duration_s),
                f"pd_{_part_of_day(h)}_{_duration_bucket(e.duration_s)}",
                "planned" if e.is_planned else "actual",
                f"sinh:{math.sin(2 * math.pi * frac):.4f}", f"cosh:{math.cos(2 * math.pi * frac):.4f}",
                f"logdur:{math.log1p(e.duration_s / 900):.4f}",
            ])
        )
    if "s" in feats or "s_count" in feats:
        sib = [f"n{len(e.siblings) + 1}"]
        if "s" in feats:
            sib += ["o_" + "_".join(_tokens(s)) for s in e.siblings]
        parts.append("|s " + " ".join(sib))
    return " ".join(parts)


def action_line(name: str, tree: CategoryTree, ancestors: bool) -> str:
    path = tree.path(name)
    feats = ["c=" + _safe(name)]
    if ancestors:
        # ancestors (excluding the node itself), tagged by depth
        feats += [f"a{i}=" + _safe(p) for i, p in enumerate(path[:-1])]
    return "|c " + " ".join(feats)


def _safe(s: str) -> str:
    return re.sub(r"[^A-Za-z0-9]+", "_", s)


@dataclass
class Encoder:
    tree: CategoryTree
    feature_set: str = "full"
    ancestors: bool = True  # candidate lines carry ancestor features
    graded_cost: bool = False  # tree-distance costs instead of 0/1 (hurts ranking, see report)

    def __post_init__(self) -> None:
        self.feats = FEATURE_SETS[self.feature_set]
        self.candidates = self.tree.names
        self._actions = [action_line(c, self.tree, self.ancestors) for c in self.candidates]

    def cost(self, candidate: str, truth: str) -> float:
        if self.graded_cost:
            return self.tree.cost(candidate, truth)
        return 0.0 if candidate == truth else 1.0

    def example(self, e: Entry, truth: str | None) -> list[str]:
        """Multiline example. With truth=None, dummy costs are used: the Python
        bindings segfault on unlabeled csoaa_ldf lines, and labels are ignored by predict."""
        lines = [shared_line(e, self.feats)]
        for i, (c, a) in enumerate(zip(self.candidates, self._actions), start=1):
            cost = 1.0 if truth is None else self.cost(c, truth)
            lines.append(f"{i}:{cost:g} {a}")
        return lines

    def interactions(self) -> list[str]:
        ns = {"d": "d", "x": "x", "t": "t", "s": "s", "s_count": "s"}
        used = sorted({ns[f] for f in self.feats})
        return [f"-q {n}c" for n in used]
