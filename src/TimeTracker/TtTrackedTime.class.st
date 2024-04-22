Class {
	#name : #TtTrackedTime,
	#superclass : #Timespan,
	#instVars : [
		'description',
		'details',
		'uid',
		'rawData',
		'daySerializedFrom',
		'category',
		'labels',
		'links',
		'isPlanned',
		'isRecurring',
		'firstTimeScheduled'
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
TtTrackedTime >> category [
	^ category
]

{ #category : #accessing }
TtTrackedTime >> category: anObject [
	category := anObject
]

{ #category : #accessing }
TtTrackedTime >> daySerializedFrom [
	^ daySerializedFrom
]

{ #category : #accessing }
TtTrackedTime >> daySerializedFrom: anObject [
	daySerializedFrom := anObject
]

{ #category : #accessing }
TtTrackedTime >> description [
	^ description
]

{ #category : #accessing }
TtTrackedTime >> description: anObject [
	description := anObject
]

{ #category : #accessing }
TtTrackedTime >> details [
	^ details
]

{ #category : #accessing }
TtTrackedTime >> details: anObject [
	details := anObject
]

{ #category : #accessing }
TtTrackedTime >> displayTrackedTime [
	self flag: 'DEPRECATE: should be able to modify as needed through simple columned list views.'.
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
								serializeWithLepiter ]}) asStencil
]

{ #category : #accessing }
TtTrackedTime >> firstTimeScheduled [
	^ firstTimeScheduled
]

{ #category : #accessing }
TtTrackedTime >> firstTimeScheduled: anObject [
	firstTimeScheduled := anObject
]

{ #category : #accessing }
TtTrackedTime >> generateCheckboxForBoolean: aSelector [
	^ BrCheckbox new
		aptitude: BrGlamorousCheckboxAptitude;
		in: [ :aCheckbox | 
			((self perform: aSelector) isNil
				or: [ (self perform: aSelector) = 'nil' or: [ (self perform: aSelector) = false ] ])
				ifTrue: [ aCheckbox uncheck ]
				ifFalse: [ aCheckbox check ].
			aCheckbox ];
		whenCheckedDo: [ :anEvent | 
			self perform: aSelector , ':' withArguments: #(true).
			self serializeWithLepiter ];
		whenUncheckedDo: [ :anEvent | 
			self perform: aSelector , ':' withArguments: #(false).
			self serializeWithLepiter ]
]

{ #category : #accessing }
TtTrackedTime >> gtTrackedTimeFor: aView [
	<gtView>
	^ aView explicit
		title: 'Summary';
		priority: 1;
		stencil: self displayTrackedTime
]

{ #category : #accessing }
TtTrackedTime >> isPlanned [
	^ isPlanned
]

{ #category : #accessing }
TtTrackedTime >> isPlanned: anObject [
	isPlanned := anObject
]

{ #category : #accessing }
TtTrackedTime >> isRecurring [
	^ isRecurring
]

{ #category : #accessing }
TtTrackedTime >> isRecurring: anObject [
	isRecurring := anObject
]

{ #category : #accessing }
TtTrackedTime >> labels [
	^ labels
]

{ #category : #accessing }
TtTrackedTime >> labels: anObject [
	labels := anObject
]

{ #category : #accessing }
TtTrackedTime >> links [
	^ links
]

{ #category : #accessing }
TtTrackedTime >> links: anObject [
	links := anObject
]

{ #category : #printing }
TtTrackedTime >> printOn: aStream [
	aStream
		nextPutAll: 'a TtTrackedTime (Starting at: ';
		nextPutAll: self start asTime printMinutes , ' for ' , self duration asMinutes rounded asString
				, (' minute'
						in: [ :aString | self duration minutes = 1 ifTrue: [ aString ] ifFalse: [ aString , 's' ] ]);
		nextPut: $)
]

{ #category : #accessing }
TtTrackedTime >> printOnDetailed [
	^ String
		streamContents: [ :aStream | 
			aStream
				nextPutAll: self start asTime hhmm24;
				nextPut: $-;
				nextPutAll: self end asTime hhmm24;
				nextPut: Character space;
				nextPutAll: self description.
			self details
				ifNotNil: [ aStream
						nextPutAll: ': ';
						nextPutAll: (self details ifNil: [ '' ]) ] ]
]

{ #category : #accessing }
TtTrackedTime >> rawData [
	^ rawData
]

{ #category : #accessing }
TtTrackedTime >> rawData: anObject [
	rawData := anObject
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
