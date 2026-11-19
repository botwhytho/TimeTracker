"
I run the Python Bridge server (the gtoolkit_bridge PyPI package) from a uv project instead of a pipenv runtime directory.

The application's working directory must be the uv project (it holds pyproject.toml, and gtoolkit_bridge is in its `gt` dependency group). It must also contain an empty marker file `complete.log`, so that PBNewPharoPlatform>>#ensureEnvironmentForApp: skips its pipenv install step.

Dependencies are managed with `uv add`, not through #installModule:in:.
"
Class {
	#name : 'TtUvPythonBridgeProcess',
	#superclass : 'PBNewPharoPipenvProcess',
	#classInstVars : [
		'uvPath'
	],
	#category : 'TimeTracker-Suggestions-Python',
	#package : 'TimeTracker-Suggestions',
	#tag : 'Python'
}

{ #category : 'accessing' }
TtUvPythonBridgeProcess class >> uvPath [
	"An explicit #uvPath: wins; otherwise ask GT, the same way PythonBridge locates pipenv:
	GtOsSystemInfo>>#findExecutable: runs `which uv` in the user's login shell, so whatever
	installed uv (official installer, Homebrew, mise, ...) is found. Cached; reset with #uvPath: nil.
	Signals an Error when uv cannot be found."

	^ uvPath ifNil: [ uvPath := GtOsSystemInfo current findExecutable: 'uv' ]
]

{ #category : 'accessing' }
TtUvPythonBridgeProcess class >> uvPath: aFileReference [
	uvPath := aFileReference
]

{ #category : 'installing' }
TtUvPythonBridgeProcess >> installModule: aModule in: anApplication [
	self
		error: 'Add Python dependencies with `uv add` in ' , self workingDirectory fullName
]

{ #category : 'private' }
TtUvPythonBridgeProcess >> newExternalProcessBuilder [
	^ GtExternalProcessBuilder new
		command: self class uvPath fullName;
		workingDirectory: self workingDirectory;
		yourself
]

{ #category : 'accessing' }
TtUvPythonBridgeProcess >> pipenvPath [
	"Superclass code that asks for the pipenv executable gets uv instead."

	^ self class uvPath
]

{ #category : 'private' }
TtUvPythonBridgeProcess >> processArguments [
	"Superclass answers: run python -u -m gtoolkit_bridge --port ... ; we swap the leading 'run python' for 'run --group gt python'."

	| inherited |
	inherited := super processArguments.
	^ (OrderedCollection withAll: #('run' '--group' 'gt' 'python'))
		addAll: (inherited allButFirst: 2);
		yourself
]
