"
I create my Python process from my application's settings (`serverProcessClass`) instead of the global `PBPlatform current` strategy. See {{gtClass:TtPythonBridgeApplication}}.
"
Class {
	#name : 'TtPythonBridgeHandler',
	#superclass : 'PBPythonHandler',
	#category : 'TimeTracker-Suggestions-Python',
	#package : 'TimeTracker-Suggestions',
	#tag : 'Python'
}

{ #category : 'initialization' }
TtPythonBridgeHandler >> initializeHandler [
	super initializeHandler.
	process := self application settings serverProcessClass
			application: self application
]
