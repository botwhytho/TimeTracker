# TimeTracker

A tool to import time tracking data from external sources to visualize and analyze it in [Glamorous Toolkit](https://gtoolkit.com/).
## Installation

```Smalltalk
[ EpMonitor current
	disableDuring: [ Metacello new
			repository: 'github://botwhytho/TimeTracker:main/src';
			baseline: 'TimeTracker';
			load ] ] asAsyncPromiseWithUserBackgroundPriority
```
To depend on this package add this to your baseline:

```Smalltalk
spec baseline: 'TimeTracker' with: [spec repository: 'github://botwhytho/TimeTracker:main/src']
```

Both of the above load the `default` group: TimeTracker itself, with no Python involved.

## Usage
You will need to set some globals in your environment for this to work (script below, change values to your own, don't add something like this to source control). If you navigate to the `TtEventCollection` class you will see a view with a list of pages with tracked time. Click on one to see a summary view; if empty, click on `import` button on the top right to load data from external source.

```Smalltalk
Smalltalk globals
	at: #TrelloKey put: 'yourTrelloKeySecretValue';
	at: #TrelloToken put: 'yourTrelloTokenSecretValue';
	at: #TrelloTimeTrackerList put: 'yourTrelloListIDValue'
```

## Optional: category suggestions (experimental)

An opt-in feature that suggests categories for time entries, using an online [Vowpal Wabbit](https://vowpalwabbit.org/) model trained on your own already-categorized entries. It lives in the `TimeTracker-Suggestions` package and the [`python/`](python/) folder, and is still in development.

To opt in, load the `suggestions` group as well:

```Smalltalk
spec baseline: 'TimeTracker' with: [
	spec
		repository: 'github://botwhytho/TimeTracker:main/src';
		loads: #('default' 'suggestions') ]
```

Requirements:
- [uv](https://docs.astral.sh/uv/) on your PATH; it manages the Python side and installs Python 3.11 itself if needed. TimeTracker finds it the same way GT finds its own tools (a `which uv` in your login shell). If that fails, set it explicitly: `TtUvPythonBridgeProcess uvPath: '/path/to/uv' asFileReference`.
- Network access on first use, to download the Python packages: `vowpalwabbit`, `gtoolkit-bridge` and their dependencies, from PyPI.
- A platform with `vowpalwabbit` wheels. Linux x86-64 is tested; other platforms are unverified.
- The repository loaded from git (Metacello does this for `github://` loads), because the Python code is read from its `python/` folder.

How it works: TimeTracker-Suggestions runs its own Python bridge process from the repository's `python/` uv project, running `uv sync` first (on first use this downloads the packages, so it takes longer). It is separate from GT's default Python bridge, which is left untouched. Training uses only your local entries, and nothing is sent anywhere.

If something goes wrong (for example uv is missing), suggestions become unavailable and GT shows one notification; click it, or inspect `TtSuggestionService default`, to see the reason. The rest of TimeTracker is unaffected.

Using it: open a Time Tracker page's **Entries By Day** view. Training starts in the background when the page loads (a few seconds; refresh the view if you open it before training finishes).
- An uncategorized entry's Category button shows the proposed category in italics with a hollow ring. Entries worth a look are marked **new** (a description never seen before) or **check** (an uncertain proposal). Click the button to confirm or pick another category as usual.
- A day with proposals that are not flagged shows **Accept N** in its Category cell. It accepts only those, for entries that are still uncategorized; entries you categorized yourself are never changed.
- Proposals are not saved until you accept them, and the model learns from every category you set.

See [`python/README.md`](python/README.md) for the Python side and its offline experiments.
