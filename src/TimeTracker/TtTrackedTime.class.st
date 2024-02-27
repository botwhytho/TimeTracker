Class {
	#name : #TtTrackedTime,
	#superclass : #Timespan,
	#instVars : [
		'goals',
		'reflection',
		'uid'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtTrackedTime class >> dataPageName [
	^ 'Time Tracker Entries'
]

{ #category : #accessing }
TtTrackedTime >> asDictionary [
	^ ((self class superclass slots , self class slots collect: #name) , {#end}
		collect: [ :each | each -> (self perform: each) asString ]) asDictionary
]

{ #category : #accessing }
TtTrackedTime >> displayPomodoro [
	^ (BrVerticalPane new
		exact: 600 @ 300;
		aptitude: BrShadowAptitude;
		margin: (BlInsets all: 6);
		background: Color white;
		addChildren: {BrHorizontalPane new alignCenter
					background: Color white;
					aptitude: BrGlamorousEditorAptitude + BrShadowAptitude;
					constraintsDo: [ :c | 
						c horizontal matchParent.
						c vertical matchParent ];
					margin: (BlInsets all: 20);
					addChildren: {BrLabel new
								margin: (BlInsets all: 10);
								aptitude: BrGlamorousLabelAptitude;
								text: 'Start: '.
							BrButton new
								margin: (BlInsets all: 10);
								aptitude: BrGlamorousButtonWithLabelAptitude;
								label: self start printToSeconds.
							BrLabel new
								margin: (BlInsets all: 10);
								aptitude: BrGlamorousLabelAptitude;
								text: 'Duration: '.
							BrButton new
								margin: (BlInsets all: 10);
								aptitude: BrGlamorousButtonWithLabelAptitude;
								label: self duration asString.
							BrLabel new
								margin: (BlInsets all: 10);
								aptitude: BrGlamorousLabelAptitude;
								text: 'End: '.
							BrButton new
								margin: (BlInsets all: 10);
								aptitude: BrGlamorousButtonWithLabelAptitude;
								label: self end printToSeconds}.
				BrLabel new
					margin: (BlInsets all: 10);
					aptitude: BrGlamorousLabelAptitude;
					text: 'Goals:'.
				BrEditor new
					background: Color white;
					aptitude: BrGlamorousEditorAptitude + BrShadowAptitude;
					margin: (BlInsets all: 20);
					beReadOnlyWithSelection;
					text: self goals.
				BrLabel new
					margin: (BlInsets all: 10);
					aptitude: BrGlamorousLabelAptitude;
					text: 'Reflections:'.
				BrEditableLabel new
					margin: (BlInsets all: 10);
					aptitude: BrGlamorousEditableLabelAptitude;
					text: (self reflection ifNil: [ '' ]);
					in: [ :aLabel | aLabel userData at: #model put: self ];
					when: BrEditorAcceptWish
						do: [ :aWish | 
							self reflection: aWish text asString.
							self
								serializeWithCounter: (GtPomodoroSettings default pomodoros
										indexOf: (aWish target userData at: #model)) ]}) asStencil
]

{ #category : #accessing }
TtTrackedTime >> goals [
	^ goals
]

{ #category : #accessing }
TtTrackedTime >> goals: anObject [
	goals := anObject
]

{ #category : #accessing }
TtTrackedTime >> gtPomodoroFor: aView [
	<gtView>
	^ aView explicit
		title: 'Summary';
		priority: 1;
		stencil: self displayPomodoro
]

{ #category : #printing }
TtTrackedTime >> printOn: aStream [
	aStream
		nextPutAll: 'a GtPomodoro (Starting at: ';
		nextPutAll: self start asTime printMinutes , ' for ' , self duration asMinutes rounded asString
				, (' minute'
						in: [ :aString | self duration minutes = 1 ifTrue: [ aString ] ifFalse: [ aString , 's' ] ]);
		nextPut: $)
]

{ #category : #accessing }
TtTrackedTime >> reflection [
	^ reflection
]

{ #category : #accessing }
TtTrackedTime >> reflection: anObject [
	reflection := anObject
]

{ #category : #accessing }
TtTrackedTime >> serializeSnippet: aTextSnippet [
	^ NeoJSONObject
		fromString: (String
				streamContents: [ :s | 
					LeJsonV4 uniqueInstance
						serialize: aTextSnippet
						on: s
						prettyPrint: true ])
]

{ #category : #accessing }
TtTrackedTime >> serializeToJSON: aCounter [
	| folder |
	folder := ('.' asFileReference / #pomodoro) ensureCreateDirectory.
	folder / aCounter asString , 'json'
		writeStreamDo: [ :aStream | STONJSON put: self asDictionary onStreamPretty: aStream ]
]

{ #category : #accessing }
TtTrackedTime >> serializeWithCounter: aCounter [
	GtPomodoroSettings default serializeWithLepiter
		ifTrue: [ self serializeWithLepiter ]
		ifFalse: [ self serializeToJSON: aCounter ]
]

{ #category : #accessing }
TtTrackedTime >> serializeWithLepiter [
	| lepiterPage aTextSnippet snippetJSON serialized anUnknownSnippet |
	lepiterPage := LeDatabasesRegistry defaultLogicalDatabase
			pageNamed: self class dataPageName
			ifAbsent: [ | newPage |
				newPage := LePage named: self class dataPageName.
				LeDatabasesRegistry defaultLogicalDatabase addPage: newPage.
				newPage addFirstSnippet: (LeTextSnippet string: '').
				newPage ].
	lepiterPage children
		detect: [ :aSnippet | aSnippet uidString = self uid ]
		ifFound: [ :foundSnippet | 
			snippetJSON := self serializeSnippet: foundSnippet.
			serialized := NeoJSONWriter toStringPretty: snippetJSON.
			foundSnippet jsonString: serialized source: lepiterPage ]
		ifNone: [ aTextSnippet := LeTextSnippet string: ''.
			lepiterPage addSnippet: aTextSnippet.
			self uid: aTextSnippet uidString.
			snippetJSON := self serializeSnippet: aTextSnippet.
			snippetJSON __type: LeUnknownSnippet leJsonV4Name.
			snippetJSON data: self asDictionary.
			serialized := NeoJSONWriter toStringPretty: snippetJSON.
			anUnknownSnippet := LeUnknownSnippet new
					jsonString: serialized
					source: lepiterPage.
			aTextSnippet removeSelf.
			lepiterPage addSnippet: anUnknownSnippet.
			self uid: anUnknownSnippet uidString ]
]

{ #category : #accessing }
TtTrackedTime >> uid [
	^ uid
]

{ #category : #accessing }
TtTrackedTime >> uid: anObject [
	uid := anObject
]
