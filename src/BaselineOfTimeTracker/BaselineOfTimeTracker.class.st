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
					with: [ spec requires: #('TimeTracker') ] ]
]
