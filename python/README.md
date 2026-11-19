# tt-suggest: Vowpal Wabbit category suggestions (POC)

This is a standalone Python proof of concept. It suggests TimeTracker categories for new time entries with an online
Vowpal Wabbit model trained on the entries already tagged in a Lepiter page.

```sh
uv sync
uv run pytest
export TT_LEPITER_PAGE=path/to/page.lepiter   # your TimeTracker Lepiter page (personal data, never committed)
uv run tt-suggest eval            # replays all entries, writes results/results.json + results/report.html
uv run tt-suggest eval --exclude-planned --data path/to/page.lepiter
uv run tt-suggest report          # re-render the HTML from results.json
```

Open `results/report.html` for the findings: charts, the discussion of the category hierarchy, and the integration design.
`results/` is gitignored because it is built from personal data; keep it that way.

## Layout
- `load.py`: parses the Lepiter JSON into `Entry` objects and a `CategoryTree`. Entries are sorted by start, and activities
  typed on the same raw line are grouped as siblings.
- `tree.py`: category paths, tree distance, and the graded cost.
- `features.py`: builds the VW ADF examples. The shared line carries description char n-grams, details, time context and
  sibling activities. Each candidate line carries the category plus its ancestors.
- `model.py`: `Suggester` (`scores`, `predict_topk`, `learn`, `save`) on top of `--csoaa_ldf m`.
- `evaluate.py`: progressive validation (online from zero, warm start on 20% then frozen or online), streaming baselines, metrics.
- `report.py`: static HTML page with inline SVG charts and no external assets.

## Known quirk
In vowpalwabbit 9.11.9, the Python bindings segfault when predicting on unlabeled `csoaa_ldf` lines. Prediction therefore
sends dummy costs and reads each candidate's partial prediction (`Encoder.example(e, None)`).

## Integration notes (Glamorous Toolkit)
- **Retrain from scratch instead of persisting a model.** A full retrain takes a few seconds, so retrain whenever entries
  are loaded: at GT startup, or lazily when the
  TimeTracker UI first opens, wherever entries are already parsed and mirrored into their collection. Then there is no model file
  to save, version or invalidate. Saving one (~3 MB at `-b 20`) is optional.
- **The same retrain backs a "Retrain" action** and runs automatically after renaming or moving categories, or bulk re-tagging.
  Debounce it so a bulk edit triggers one retrain, and run it in the background while serving the previous model. Adding a new
  category needs no retrain.
- **Batch across the bridge, never per entry.** Crossing the GT↔Python bridge (or spawning a sub-process or shell) thousands of
  times is the cost to avoid. Train in one call, either by passing the Lepiter page path so Python parses it itself (tiny
  payload, but misses unsaved in-image edits) or by sending all entries as one serialized list. Suggest a whole day page in one
  call too. Per-entry `learn` on save is fine: about 0.5 ms of Python, so the bridge overhead dominates.
  Planned API: `train_all(entries | path)`, `suggest_many(entries, k)`, `learn(entry)`.
- Day-by-day simulation (`uv run tt-suggest daily`): replays the history one day page at a time and estimates the time saved
  under a grid of manual/review/correction-time assumptions (report section 1).

## Notes
- `scripts/confidence_analysis.py`: measures which per-entry signals (novel description, low score margin, ambiguous
  history) catch wrong suggestions in the day-by-day replay. Its output describes personal data, so the write-up is kept
  outside this repo.
