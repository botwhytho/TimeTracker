import os
from pathlib import Path

import pytest

from tt_suggest.load import load

# Real data is personal and never committed: point TT_LEPITER_PAGE at a local .lepiter page to run this.
DATA = Path(os.environ.get("TT_LEPITER_PAGE", "")).expanduser()


@pytest.mark.skipif(not os.environ.get("TT_LEPITER_PAGE") or not DATA.is_file(),
                    reason="set TT_LEPITER_PAGE to a local TimeTracker Lepiter page")
def test_load_real_data():
    entries, tree = load(DATA)
    assert entries
    assert all(e.category in tree.paths for e in entries)
    assert [e.start for e in entries] == sorted(e.start for e in entries)
    # activities split from one raw line know about each other
    multi = [e for e in entries if ";" in e.raw]
    assert multi and sum(bool(e.siblings) for e in multi) >= 0.99 * len(multi)
    planned = sum(e.is_planned for e in entries)
    assert len(load(DATA, include_planned=False)[0]) == len(entries) - planned
