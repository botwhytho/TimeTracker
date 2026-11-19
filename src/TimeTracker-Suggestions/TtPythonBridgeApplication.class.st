"
I am a PythonBridge application that runs from the TimeTracker uv project (the `python/` folder of the TimeTracker git repository) instead of GT's stock pipenv runtime. I am independent of the global `PBApplication uniqueInstance`, which keeps its stock setup.

Before my handlers are built I set my own settings (process class {{gtClass:TtUvPythonBridgeProcess}}, working directory) and use {{gtClass:TtPythonBridgeHandler}}. That handler creates its process from those settings; the stock PBPythonHandler uses the global PBPlatform strategy and would ignore them.

The project directory must contain an empty marker file `complete.log`, so GT skips its pipenv install.
"
Class {
	#name : 'TtPythonBridgeApplication',
	#superclass : 'PBApplication',
	#classInstVars : [
		'projectDirectory'
	],
	#category : 'TimeTracker-Suggestions-Python',
	#package : 'TimeTracker-Suggestions',
	#tag : 'Python'
}

{ #category : 'accessing' }
TtPythonBridgeApplication class >> projectDirectory [
	"The uv project: the python/ folder of the TimeTracker git repository, wherever Iceberg has it checked out."

	^ projectDirectory
		ifNil: [ (IceRepository registry detect: [ :each | each name = 'TimeTracker' ])
				location / 'python' ]
]

{ #category : 'accessing' }
TtPythonBridgeApplication class >> projectDirectory: aFileReference [
	projectDirectory := aFileReference
]

{ #category : 'initialization' }
TtPythonBridgeApplication >> initialize [
	"PBApplication>>#initialize builds handlers from default settings; rebuild them once our settings are in place."

	super initialize.
	settings
		serverProcessClass: TtUvPythonBridgeProcess;
		workingDirectory: self class projectDirectory.
	self initializeHandlers
]

{ #category : 'initialization' }
TtPythonBridgeApplication >> initializeHandlers [
	super initializeHandlers.
	processHandler := TtPythonBridgeHandler application: self
]
