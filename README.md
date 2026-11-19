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
- [uv](https://docs.astral.sh/uv/), which manages the Python side. uv installs Python 3.11 itself if needed.
- Network access on first use, to download the Python packages: `vowpalwabbit`, `gtoolkit-bridge` and their dependencies, from PyPI.
- A platform with `vowpalwabbit` wheels. Linux x86-64 is tested; other platforms are unverified.
- The repository loaded from git (Metacello does this for `github://` loads), because the Python code is read from its `python/` folder.

How it works: TimeTracker-Suggestions runs its own Python bridge process from the repository's `python/` uv project. It is separate from GT's default Python bridge, which is left untouched. Training uses only your local entries, and nothing is sent anywhere.

Current limitations, which the next development stage addresses:
- uv is looked for at the [mise](https://mise.jdx.dev/) shim location (`~/.local/share/mise/shims/uv`). Set `TtUvPythonBridgeProcess uvPath:` if yours is elsewhere.
- GT's stock Python setup runs `pipenv install` unless an empty `python/complete.log` file exists. Create it once (it is gitignored).
- Errors surface in the debugger rather than as a notification.

See [`python/README.md`](python/README.md) for the Python side and its offline experiments.
## Usage
You will need to set some globals in your environment for this to work (script below, change values to your own, don't add something like this to source control). If you navigate to the `TtEventCollection` class you will see a view with a list of pages with tracked time. Click on one to see a summary view; if empty, click on `import` button on the top right to load data from external source.

```Smalltalk
Smalltalk globals
	at: #TrelloKey put: 'yourTrelloKeySecretValue';
	at: #TrelloToken put: 'yourTrelloTokenSecretValue';
	at: #TrelloTimeTrackerList put: 'yourTrelloListIDValue'
```
