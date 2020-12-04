Class {
	#name : #BaselineOfTimeTracker,
	#superclass : #BaselineOf,
	#category : 'BaselineOfTimeTracker'
}

{ #category : #baseline }
BaselineOfTimeTracker >> baseline: spec [
	<baseline>
	spec for: #'common' do: [
		spec
			package: 'TimeTracker'. ].

]
