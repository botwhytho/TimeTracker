"""Parse a TimeTracker Lepiter page (JSON) into entries and the category tree."""

from __future__ import annotations

import json
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

from tt_suggest.tree import CategoryTree


@dataclass
class Entry:
    idx: int  # position in the page (stable tie-breaker)
    category: str
    description: str
    details: str
    start: datetime  # wall-clock local time (offset kept)
    duration_s: int
    is_planned: bool
    raw: str
    # filled in after grouping: other activities typed on the same raw line
    day: str = ""  # day page id (daySerializedFrom); entries are categorised one page at a time
    siblings: tuple[str, ...] = ()
    group: int = -1

    def as_dict(self) -> dict:
        """Plain dict mirroring TtTrackedTime; the shape GT would send."""
        return {
            "description": self.description,
            "details": self.details,
            "start": self.start.isoformat(),
            "duration": self.duration_s,
            "isPlanned": self.is_planned,
            "siblings": list(self.siblings),
        }


def load(path: str | Path, include_planned: bool = True) -> tuple[list[Entry], CategoryTree]:
    page = json.loads(Path(path).read_text())
    items = page["children"]["items"]
    tree = None
    entries: list[Entry] = []
    for i, snip in enumerate(items):
        kind = snip["__type"]
        if kind == "TtCategoriesSnippet":
            tree = CategoryTree.from_json(snip["object"])
        elif kind == "TtTrackedTimeSnippet":
            o = snip["object"]
            if o.get("isPlanned") and not include_planned:
                continue
            entries.append(
                Entry(
                    idx=i,
                    category=o["category"],
                    description=o.get("description") or "",
                    details=o.get("details") or "",
                    start=datetime.fromisoformat(o["start"]["dateAndTimeString"]),
                    duration_s=int(o["duration"]["seconds"]),
                    is_planned=bool(o.get("isPlanned")),
                    raw=o.get("rawData") or "",
                    day=o.get("daySerializedFrom") or o["start"]["dateAndTimeString"][:10],
                )
            )
    if tree is None:
        raise ValueError("no TtCategoriesSnippet found")

    # Group activities split from the same raw line (same start, raw text, duration).
    # Note: isPlanned can differ between activities of one line, so it is not part of the key.
    groups: dict[tuple, list[Entry]] = {}
    for e in entries:
        groups.setdefault((e.start, e.raw, e.duration_s), []).append(e)
    for gid, members in enumerate(groups.values()):
        for e in members:
            e.group = gid
            e.siblings = tuple(m.description for m in members if m is not e)

    entries.sort(key=lambda e: (e.start, e.idx))
    return entries, tree
