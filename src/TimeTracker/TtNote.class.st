Class {
	#name : #TtNote,
	#superclass : #Timespan,
	#instVars : [
		'collection',
		'page',
		'database',
		'uid'
	],
	#category : #TimeTracker
}

{ #category : #serialization }
TtNote class >> neoJsonMapping: aNeoJSONMapper [
	| database |
	aNeoJSONMapper
		for: self
			do: [ :aMapping | 
				(aMapping mapInstVar: #start) valueSchema: DateAndTime.
				(aMapping mapInstVar: #duration) valueSchema: Duration.
				(aMapping mapInstVar: #database) valueSchema: LeDatabase.
				(aMapping mapInstVar: #page) valueSchema: LePage ];
		for: DateAndTime
			customDo: [ :mapping | 
				mapping decoder: [ :string | DateAndTime fromString: string ].
				mapping encoder: [ :dateAndTime | dateAndTime printString ] ];
		for: Duration
			customDo: [ :mapping | 
				mapping decoder: [ :aString | aString asDuration ].
				mapping encoder: [ :aDuration | aDuration asString ] ];
		for: LeDatabase
			customDo: [ :mapping | 
				mapping
					decoder: [ :aString | 
						database := (LeLogicalDatabase allSubInstances
								collect: [ :each | each databaseWithID: aString ifNone: [ nil ] ])
								detect: #isNotNil
								ifNone: [ nil ] ].
				mapping
					encoder: [ :aLeDatabase | [ aLeDatabase uuidString ] on: MessageNotUnderstood do: [ nil ] ] ];
		for: LePage
			customDo: [ :mapping | 
				mapping decoder: [ :aString | 
				self flag: #TODO. "Do better error handling. Create custom (or re-use) error for db/page not found and wrap IDs"
				database pageWithID: aString ifAbsent: [ nil ] ].
				mapping
					encoder: [ :aLePage | [ aLePage uidString ] on: MessageNotUnderstood do: [ nil ] ] ]
]

{ #category : #serialization }
TtNote class >> snippetClass [
	^ TtNoteSnippet
]

{ #category : #accessing }
TtNote >> asTimespan [
	^ self as: self value class superclass
]

{ #category : #accessing }
TtNote >> collection [
	^ collection
]

{ #category : #accessing }
TtNote >> collection: aTtEventCollection [
	collection := aTtEventCollection
]

{ #category : #accessing }
TtNote >> database [
	^ database
]

{ #category : #accessing }
TtNote >> database: aLeDatabase [
	database := aLeDatabase
]

{ #category : #deleting }
TtNote >> delete [
	self collection page
		ifNotNil: [ :aPage | 
			(aPage children detect: [ :aSnippet | aSnippet uidString = self uid ])
				removeSelf ].
	self rootCollection items remove: self
]

{ #category : #views }
TtNote >> gtDeleteActionFor: anAction [
	<gtAction>
	^ anAction button
		icon: BrGlamorousVectorIcons remove;
		tooltip: 'Delete the Note.';
		priority: 2;
		action: [ :aBrButton :aBrTab :aBrButtonModel :anEvent | 
			anEvent consumed: true.
			self delete ]
]

{ #category : #views }
TtNote >> gtPreviewFor: aView [
	<gtView>
	self page ifNil: [ ^ aView empty ].
	^ aView forward
		title: 'Linked Page';
		object: [ self page ];
		view: #gtLiveFor:
]

{ #category : #testing }
TtNote >> isNote [
	^ true
]

{ #category : #accessing }
TtNote >> page [
	^ page
]

{ #category : #accessing }
TtNote >> page: aLePage [
	page := aLePage
]

{ #category : #accessing }
TtNote >> rootCollection [
	^ self collection rootCollection
]

{ #category : #accessing }
TtNote >> uid [
	^ uid
]

{ #category : #accessing }
TtNote >> uid: anObject [
	uid := anObject
]
