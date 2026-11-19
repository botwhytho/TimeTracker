"""Tests for the GT facade, on synthetic data only (no personal data in this repo)."""

import os
from datetime import datetime, timedelta
from pathlib import Path

import pytest

from tt_suggest import gt
from tt_suggest.load import Entry

TREE = {"children": [
    {"name": "Food", "children": [
        {"name": "Fruit", "children": [{"name": "Citrus", "children": []},
                                       {"name": "Berry", "children": []}]}]},
    {"name": "Tools", "children": [{"name": "Hammer", "children": []}]},
]}

# description -> category; "pick" is deliberately ambiguous (split between two categories).
PATTERN = [("lemon", "Citrus"), ("strawberry", "Berry"), ("nail", "Hammer"), ("pick", "Berry"), ("pick", "Hammer")]


def _entries(days: int = 60) -> list[dict]:
    out = []
    t0 = datetime(2030, 1, 1, 8, 0)
    for d in range(days):
        for i, (desc, cat) in enumerate(PATTERN):
            start = t0 + timedelta(days=d, hours=2 * i)
            out.append({"description": desc, "start": start.isoformat(), "duration": 900, "category": cat,
                        "rawData": f"- {desc}", "day": f"d{d}"})
    return out


@pytest.fixture(autouse=True)
def fresh_state():
    gt.reset()
    yield
    gt.reset()


def test_entry_dict_round_trip():
    d = _entries(1)[0]
    e = Entry.from_dict(d)
    assert e.description == "lemon" and e.category == "Citrus" and e.duration_s == 900
    assert Entry.from_dict(e.as_dict()).as_dict() == e.as_dict()


def test_requires_training():
    assert gt.status() == {"trained": False}
    with pytest.raises(RuntimeError):
        gt.suggest_many([{"description": "lemon", "start": "2030-03-01T08:00:00", "duration": 900}])


def test_train_and_suggest_known_descriptions():
    status = gt.train(TREE, _entries())
    assert status["trained"] and status["entries"] == 60 * len(PATTERN) and status["categories"] == 6
    assert status["calibration_entries"] == 60 * len(PATTERN)  # fewer than CALIBRATION_TAIL: all scored
    [lemon, nail] = gt.suggest_many([
        {"description": "lemon", "start": "2030-03-01T08:00:00", "duration": 900},
        {"description": "nail", "start": "2030-03-01T12:00:00", "duration": 900},
    ])
    assert lemon["category"] == "Citrus" and lemon["path"] == ["Food", "Fruit", "Citrus"]
    assert nail["category"] == "Hammer"
    assert not lemon["is_new"] and not lemon["needs_check"] and lemon["confidence"] > 0.5
    assert len(lemon["alternatives"]) == 2


def test_flags_new_and_ambiguous_descriptions():
    gt.train(TREE, _entries())
    [new, ambiguous] = gt.suggest_many([
        {"description": "grapefruit", "start": "2030-03-01T08:00:00", "duration": 900},
        {"description": "pick", "start": "2030-03-01T14:00:00", "duration": 900},
    ])
    assert new["is_new"] and new["needs_check"] and "new description" in new["reasons"]
    assert not ambiguous["is_new"] and "description used with several categories" in ambiguous["reasons"]


def test_learn_makes_description_known():
    gt.train(TREE, _entries())
    entry = {"description": "grapefruit", "start": "2030-03-01T08:00:00", "duration": 900, "category": "Citrus"}
    gt.learn(entry)
    [after] = gt.suggest_many([{k: v for k, v in entry.items() if k != "category"}])
    assert not after["is_new"]
    assert gt.status()["learned_since_training"] == 1


def test_learn_rejects_unknown_or_missing_category():
    gt.train(TREE, _entries())
    base = {"description": "x", "start": "2030-03-01T08:00:00", "duration": 900}
    with pytest.raises(ValueError):
        gt.learn(base)
    with pytest.raises(ValueError):
        gt.learn({**base, "category": "Not In Tree"})


def test_train_rejects_categories_missing_from_tree():
    bad = _entries(1) + [{"description": "y", "start": "2030-01-02T08:00:00", "duration": 900, "category": "Nope"}]
    with pytest.raises(ValueError):
        gt.train(TREE, bad)


def test_uncategorized_entries_are_ignored_for_training():
    entries = _entries(5) + [{"description": "todo", "start": "2030-01-09T08:00:00", "duration": 900}]
    assert gt.train(TREE, entries)["entries"] == 5 * len(PATTERN)


DATA = os.environ.get("TT_LEPITER_PAGE")


@pytest.mark.skipif(not DATA or not Path(DATA).expanduser().is_file(), reason="set TT_LEPITER_PAGE to run")
def test_train_from_path_real_data():
    status = gt.train_from_path(DATA)
    assert status["trained"] and status["entries"] > 0
    assert status["calibration_entries"] == min(gt.CALIBRATION_TAIL, status["entries"])
    assert 0 < status["low_margin_threshold"]
