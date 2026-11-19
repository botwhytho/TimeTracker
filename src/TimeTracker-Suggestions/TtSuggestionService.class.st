"
I own the Python side of TimeTracker category suggestions: one {{gtClass:TtPythonBridgeApplication}} running the `tt_suggest.gt` facade from the repository's `python/` uv project.

I move plain data only (Arrays, Dictionaries, strings, numbers); converting TimeTracker objects is {{gtClass:TtSuggester}}'s job. #call:with: is the only way into Python: it allows just the facade functions, passes all arguments in one binding and deletes it inside the same call, because PythonBridge bindings otherwise stay alive in the bridge's globals.

State: #stopped, #starting, #training, #ready or #unavailable (see #reason). Every step runs behind #guard:, so problems such as uv missing set #unavailable and post one GT notification (click it to inspect me) instead of opening a debugger. Set `TtSuggestionService debugMode: true` while developing to get the debugger instead.

`TtSuggestionService default` is the shared instance; `TtSuggestionService resetDefault` stops it.
"
Class {
	#name : 'TtSuggestionService',
	#superclass : 'Object',
	#instVars : [
		'application',
		'state',
		'reason',
		'lastError',
		'lastTrainStatus',
		'calls',
		'mutex',
		'trainingProcess',
		'retrainRequested'
	],
	#classInstVars : [
		'default',
		'debugMode'
	],
	#category : 'TimeTracker-Suggestions-Service',
	#package : 'TimeTracker-Suggestions',
	#tag : 'Service'
}

{ #category : 'settings' }
TtSuggestionService class >> debugMode [
	"When true, errors open the debugger instead of making the service #unavailable. For development."

	^ debugMode ifNil: [ false ]
]

{ #category : 'settings' }
TtSuggestionService class >> debugMode: aBoolean [
	debugMode := aBoolean
]

{ #category : 'accessing' }
TtSuggestionService class >> default [
	^ default ifNil: [ default := self new ]
]

{ #category : 'accessing' }
TtSuggestionService class >> facadeFunctions [
	"The tt_suggest.gt functions that #call:with: may invoke."

	^ #('train' 'suggest_many' 'learn' 'status' 'reset')
]

{ #category : 'accessing' }
TtSuggestionService class >> resetDefault [
	default ifNotNil: [ :aService | aService stop ].
	default := nil
]

{ #category : 'error handling' }
TtSuggestionService >> becomeUnavailable: anError [
	lastError := anError.
	state := #unavailable.
	reason := self describe: anError.
	self notifyUnavailable
]

{ #category : 'calling' }
TtSuggestionService >> call: functionName with: aDictionary [
	"Call tt_suggest.gt.<functionName>(**aDictionary) and answer its plain-data result.
	All arguments travel in one binding that the script deletes, so nothing lingers in the bridge."

	| result milliseconds |
	(self class facadeFunctions includes: functionName)
		ifFalse: [ ^ self error: 'Not a tt_suggest.gt facade function: ' , functionName ].
	mutex
		critical: [ self ensureStarted.
			milliseconds := Time
					millisecondsToRun: [ result := application newCommandStringFactory
								bindingAt: #tt_args put: aDictionary;
								script: (self scriptFor: functionName);
								resultExpression: 'tt_result';
								sendAndWait ] ].
	self recordCall: functionName milliseconds: milliseconds.
	^ result
]

{ #category : 'accessing' }
TtSuggestionService >> calls [
	"Recent facade calls, newest first: { functionName. milliseconds. timestamp }."

	^ calls
]

{ #category : 'error handling' }
TtSuggestionService >> describe: anError [
	| text |
	text := anError messageText asString.
	(text includesSubstring: 'Unable to find: uv')
		ifTrue: [ ^ 'uv was not found. Install it from https://docs.astral.sh/uv/ (or set TtUvPythonBridgeProcess uvPath:).' ].
	(text includesSubstring: 'uv sync failed')
		ifTrue: [ ^ 'Setting up the Python environment failed (uv sync). Inspect the last error for uv''s output.' ].
	^ text
]

{ #category : 'lifecycle' }
TtSuggestionService >> ensureStarted [
	(application notNil and: [ application isRunning ]) ifTrue: [ ^ self ].
	state := #starting.
	reason := nil.
	application := TtPythonBridgeApplication new.
	application start
]

{ #category : 'views' }
TtSuggestionService >> gtCallsFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Calls';
		priority: 2;
		items: [ calls ];
		column: 'Function' text: [ :each | each first ];
		column: 'ms'
			text: [ :each | each second ]
			width: 80;
		column: 'At' text: [ :each | each third ];
		actionUpdateButton
]

{ #category : 'views' }
TtSuggestionService >> gtStatusFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Status';
		priority: 1;
		items: [ self statusItems ];
		column: 'Property'
			text: #key
			width: 160;
		column: 'Value' text: [ :each | each value ifNil: [ '' ] ];
		send: #value;
		actionUpdateButton
]

{ #category : 'error handling' }
TtSuggestionService >> guard: aBlock [
	"The single error boundary: problems make the service #unavailable with a reason and one
	notification, instead of a debugger. Answers nil on failure. See class-side #debugMode."

	^ [ aBlock value ]
		on: Error
		do: [ :anError | 
			self class debugMode ifTrue: [ anError pass ].
			self becomeUnavailable: anError.
			nil ]
]

{ #category : 'initialization' }
TtSuggestionService >> initialize [
	super initialize.
	state := #stopped.
	calls := OrderedCollection new.
	mutex := Mutex new.
	retrainRequested := false
]

{ #category : 'testing' }
TtSuggestionService >> isReady [
	^ state = #ready
]

{ #category : 'testing' }
TtSuggestionService >> isTraining [
	^ trainingProcess notNil and: [ trainingProcess isTerminated not ]
]

{ #category : 'accessing' }
TtSuggestionService >> lastError [
	^ lastError
]

{ #category : 'accessing' }
TtSuggestionService >> lastTrainStatus [
	^ lastTrainStatus
]

{ #category : 'error handling' }
TtSuggestionService >> notifyUnavailable [
	GtObjectNotificationMessage new
		message: 'TimeTracker suggestions unavailable: ' , reason;
		tooltip: 'Inspect the suggestion service';
		object: self;
		showNotifications;
		registerNotifications
]

{ #category : 'printing' }
TtSuggestionService >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPut: $(;
		print: state;
		nextPut: $)
]

{ #category : 'accessing' }
TtSuggestionService >> reason [
	"Why the service is #unavailable, in words a user can act on."

	^ reason
]

{ #category : 'private' }
TtSuggestionService >> recordCall: functionName milliseconds: milliseconds [
	calls
		addFirst: {functionName.
				milliseconds.
				DateAndTime now}.
	calls size > 50 ifTrue: [ calls removeLast ]
]

{ #category : 'private' }
TtSuggestionService >> scriptFor: functionName [
	^ 'from tt_suggest import gt as _tt_gt
try:
    tt_result = _tt_gt.'
		, functionName , '(**tt_args)
finally:
    del tt_args'
]

{ #category : 'accessing' }
TtSuggestionService >> state [
	^ state
]

{ #category : 'views' }
TtSuggestionService >> statusItems [
	| uv |
	uv := [ TtUvPythonBridgeProcess uvPath fullName ]
			on: Error
			do: [ :e | 'not found' ].
	^ {'State' -> state.
		'Reason' -> reason.
		'Training now' -> self isTraining.
		'Bridge running' -> (application notNil and: [ application isRunning ]).
		'uv' -> uv.
		'Python project'
			-> ([ TtPythonBridgeApplication projectDirectory fullName ]
					on: Error
					do: [ :e | e messageText ]).
		'Last training' -> lastTrainStatus.
		'Last error' -> lastError.
		'Bridge application' -> application}
]

{ #category : 'lifecycle' }
TtSuggestionService >> stop [
	trainingProcess ifNotNil: [ :aProcess | aProcess terminate ].
	trainingProcess := nil.
	application
		ifNotNil: [ :anApplication | anApplication isRunning ifTrue: [ anApplication stop ] ].
	application := nil.
	state := #stopped
]

{ #category : 'training' }
TtSuggestionService >> train: aPayload [
	"Synchronous. aPayload is a Dictionary with 'tree' and 'entries' (plain data, see TtSuggester).
	Answers the facade's status, or nil if the service became #unavailable."

	^ self
		guard: [ self ensureStarted.
			state := #training.
			lastTrainStatus := self call: 'train' with: aPayload.
			state := #ready.
			lastTrainStatus ]
]

{ #category : 'training' }
TtSuggestionService >> trainInBackground: aPayloadBlock [
	"Train in a background process; aPayloadBlock builds the payload there too. One training at a
	time: a request during training just schedules one more run, with fresh data, afterwards."

	self isTraining
		ifTrue: [ retrainRequested := true.
			^ self ].
	trainingProcess := [ [ retrainRequested := false.
		self guard: [ self train: aPayloadBlock value ].
		retrainRequested and: [ state ~= #unavailable ] ] whileTrue.
		trainingProcess := nil ]
			forkAt: Processor userBackgroundPriority
			named: 'TimeTracker suggestions training'
]
