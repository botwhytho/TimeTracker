"""CLI: run all experiments, write results JSON + static HTML report."""

from __future__ import annotations

import argparse
import json
import os
import time
from dataclasses import asdict
from pathlib import Path

from tt_suggest import evaluate as ev
from tt_suggest.load import load

# The TimeTracker Lepiter page (*.lepiter) to read; pass --data or set TT_LEPITER_PAGE.
DEFAULT_DATA = os.environ.get("TT_LEPITER_PAGE")
FEATURES = ["full", "desc", "time", "time+siblings"]
SCENARIOS = ["online", "warm20-frozen", "warm20-online"]


def run_all(data: str, include_planned: bool, out: Path) -> dict:
    entries, tree = load(Path(data).expanduser(), include_planned)
    split = int(len(entries) * 0.2)
    runs: list[ev.Run] = []
    timings = {}
    for f in FEATURES:
        for s in SCENARIOS:
            t = time.time()
            runs.append(ev.run_vw(entries, tree, f, s))
            timings[f"{f}/{s}"] = time.time() - t
            print(f"  {f:14s} {s:14s} {timings[f'{f}/{s}']:.1f}s", flush=True)
    # hierarchy ablation: which of the two hierarchy mechanisms matters?
    for f in ("full", "time"):
        for anc, graded in ((False, False), (True, True), (False, True)):
            runs.append(ev.run_vw(entries, tree, f, "online", ancestors=anc, graded_cost=graded))
    baselines = ev.run_baselines(entries, tree)

    def summary(r: ev.Run) -> dict:
        s = {"tail": ev.summarize(r, tree, split)}
        if r.scenario in ("online", "baseline"):
            s["all"] = ev.summarize(r, tree, 0)
        return s

    result = {
        "meta": {
            "n_entries": len(entries),
            "n_planned": sum(e.is_planned for e in entries),
            "n_categories_used": len({e.category for e in entries}),
            "n_tree_nodes": len(tree.names),
            "n_descriptions": len({e.description.lower() for e in entries}),
            "split_index": split,
            "split_date": entries[split].start.date().isoformat(),
            "first": entries[0].start.date().isoformat(),
            "last": entries[-1].start.date().isoformat(),
            "include_planned": include_planned,
            "timings_s": timings,
        },
        "tree": {n: list(p) for n, p in tree.paths.items()},
        "dates": [e.start.date().isoformat() for e in entries],
        "runs": [
            {
                "name": r.name,
                "scenario": r.scenario,
                "features": r.features,
                "summary": summary(r),
                "rolling": {m: ev.rolling(r, metric=m) for m in ("top1", "top3", "slot_hit")},
            }
            for r in runs + baselines
        ],
        "per_category": {
            "full": ev.per_category(next(r for r in runs if r.name == "full" and r.scenario == "online"), split),
            "time": ev.per_category(next(r for r in runs if r.name == "time" and r.scenario == "online"), split),
        },
    }
    result["daily"] = daily(entries, tree)
    out.mkdir(parents=True, exist_ok=True)
    (out / "results.json").write_text(json.dumps(result, indent=1))
    return result


def daily(entries, tree) -> list[dict]:
    t = time.time()
    days = [asdict(d) for d in ev.run_daily(entries, tree, "full")]
    print(f"  daily batches  {len(days)} days    {time.time() - t:.1f}s", flush=True)
    return days


def main() -> None:
    p = argparse.ArgumentParser(prog="tt-suggest")
    sub = p.add_subparsers(dest="cmd", required=True)
    e = sub.add_parser("eval", help="run experiments and write report")
    e.add_argument("--data", default=DEFAULT_DATA, required=DEFAULT_DATA is None)
    e.add_argument("--exclude-planned", action="store_true")
    e.add_argument("--out", default="results")
    r = sub.add_parser("report", help="re-render HTML from results.json")
    r.add_argument("--out", default="results")
    d = sub.add_parser("daily", help="(re)run only the day-by-day simulation, update results.json and report")
    d.add_argument("--data", default=DEFAULT_DATA, required=DEFAULT_DATA is None)
    d.add_argument("--exclude-planned", action="store_true")
    d.add_argument("--out", default="results")
    a = p.parse_args()
    out = Path(a.out)
    if a.cmd == "eval":
        run_all(a.data, not a.exclude_planned, out)
    elif a.cmd == "daily":
        res = json.loads((out / "results.json").read_text())
        entries, tree = load(Path(a.data).expanduser(), not a.exclude_planned)
        res["daily"] = daily(entries, tree)
        (out / "results.json").write_text(json.dumps(res, indent=1))
    from tt_suggest.report import render

    render(json.loads((out / "results.json").read_text()), out / "report.html")
    print(f"wrote {out / 'results.json'} and {out / 'report.html'}")
