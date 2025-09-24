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
## Usage
You will need to set some globals in your environment for this to work (script below, change values to your own, don't add something like this to source control). If you navigate to the `TtEventCollection` class you will see a view with a list of pages with tracked time. Click on one to see a summary view; if empty, click on `import` button on the top right to load data from external source.

```Smalltalk
Smalltalk globals
	at: #TrelloKey put: 'yourTrelloKeySecretValue';
	at: #TrelloToken put: 'yourTrelloTokenSecretValue';
	at: #TrelloTimeTrackerList put: 'yourTrelloListIDValue'
```
