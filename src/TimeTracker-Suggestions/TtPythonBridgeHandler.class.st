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

{ #category : 'starting' }
TtPythonBridgeHandler >> start [
	"Instead of PBPlatform>>#ensureEnvironmentForApp: (which runs `pipenv install` unless a
	complete.log marker exists), make sure the uv project's environment is in sync, then start."

	self syncUvProject.
	^ process start
]

{ #category : 'starting' }
TtPythonBridgeHandler >> syncUvProject [
	"Idempotent and fast when up to date. On first use it downloads Python and the packages,
	before the bridge starts, so the bridge's startup wait never covers downloads."

	| uv output |
	uv := TtUvPythonBridgeProcess uvPath.
	uv isFile ifFalse: [ ^ self error: 'Unable to find: uv at ' , uv fullName ].
	output := GtExternalProcessBuilder new
			command: uv fullName;
			args: #('sync' '--group' 'gt');
			workingDirectory: self application settings workingDirectory;
			output.
	output status isSuccess
		ifFalse: [ self
				error: 'uv sync failed in ' , self application settings workingDirectory fullName
						, ': ' , output stderr ]
]
