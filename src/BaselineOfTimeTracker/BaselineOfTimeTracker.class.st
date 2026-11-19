Class {
	#name : 'BaselineOfTimeTracker',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfTimeTracker',
	#package : 'BaselineOfTimeTracker'
}

{ #category : 'baseline' }
BaselineOfTimeTracker >> baseline: spec [
	<baseline>
	spec
		for: #common
		do: [ spec
				package: 'TimeTracker';
				package: 'TimeTracker-Suggestions'
					with: [ spec requires: #('TimeTracker') ].	"'default' is what a plain dependency on this baseline loads: no Python, no uv.
			Opt in to category suggestions with loads: #('default' 'suggestions');
			they need uv (https://docs.astral.sh/uv/) and download Python packages on first use."
			spec
				group: 'default' with: #('TimeTracker');
				group: 'suggestions' with: #('TimeTracker-Suggestions') ]
]
