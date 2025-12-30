Class {
	#name : 'TtNote2',
	#superclass : 'Timespan',
	#traits : 'TtSerializedObjetTrait',
	#classTraits : 'TtSerializedObjetTrait classTrait',
	#instVars : [
		'page',
		'database'
	],
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'initialization' }
TtNote2 class >> initialize [
	super initialize.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newReader.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : 'serialization' }
TtNote2 class >> leJsonV3MappingFor: aNeoJSONMapper [
	| database |
	aNeoJSONMapper
		for: self
		do: [ :aMapping | 
			aMapping
				mapProperty: #__type
				getter: [ :object | object class leJsonV4Name ]
				setter: [ :um | self error: 'Objects should not be read here' ].
			aMapping
				mapProperty: #database
				getter: [ :aTtNote | [ aTtNote database uuidString ] on: MessageNotUnderstood do: [ nil ] ]
				setter: [ :aString | 
					database := (LeLogicalDatabase allSubInstances
							collect: [ :each | each databaseWithID: aString ifNone: [ nil ] ])
							detect: #isNotNil
							ifNone: [ nil ] ].
			aMapping
				mapProperty: #page
				getter: [ :aTtNote | [ aTtNote page uidString ] on: MessageNotUnderstood do: [ nil ] ]
				setter: [ :aString | database pageWithID: aString ifAbsent: [ nil ] ].
			aMapping mapInstVars: #(duration start) ]
]

{ #category : 'lepiter-store' }
TtNote2 class >> leJsonV3Name [
	^ #TtNote
]

{ #category : 'serialization' }
TtNote2 class >> leJsonV4MappingFor: aNeoJSONMapper [
	| database |
	aNeoJSONMapper
		for: self
		do: [ :aMapping | 
			aMapping
				mapProperty: #__type
				getter: [ :object | object class leJsonV4Name ]
				setter: [ :um | self error: 'Objects should not be read here' ].
			aMapping
				mapProperty: #database
				getter: [ :aTtNote | [ aTtNote database uuidString ] on: MessageNotUnderstood do: [ nil ] ]
				setter: [ :aString | 
					database := (LeLogicalDatabase allSubInstances
							collect: [ :each | each databaseWithID: aString ifNone: [ nil ] ])
							detect: #isNotNil
							ifNone: [ nil ] ].
			aMapping
				mapProperty: #page
				getter: [ :aTtNote | [ aTtNote page uidString ] on: MessageNotUnderstood do: [ nil ] ]
				setter: [ :aString | database pageWithID: aString ifAbsent: [ nil ] ].
			aMapping mapInstVars: #(duration start) ]
]

{ #category : 'lepiter-store' }
TtNote2 class >> leJsonV4Name [
	^ #TtNote
]

{ #category : 'serialization' }
TtNote2 class >> snippetClass [
	^ TtNoteSnippet
]

{ #category : 'accessing' }
TtNote2 >> database [
	^ database
]

{ #category : 'accessing' }
TtNote2 >> database: aLeDatabase [
	database := aLeDatabase
]

{ #category : 'views' }
TtNote2 >> gtDeleteActionFor: anAction [
	<gtAction>
	^ anAction button
		icon: BrGlamorousVectorIcons remove;
		tooltip: 'Delete the Note.';
		priority: 2;
		action: [ :aBrButton :aBrTab :aBrButtonModel :anEvent | 
			anEvent consumed: true.
			self delete ]
]

{ #category : 'views' }
TtNote2 >> gtPreviewFor: aView [
	<gtView>
	self page ifNil: [ ^ aView empty ].
	^ aView forward
		title: 'Linked Page';
		object: [ self page ];
		view: #gtLiveFor:
]

{ #category : 'testing' }
TtNote2 >> isNote [
	^ true
]

{ #category : 'accessing' }
TtNote2 >> page [
	^ page
]

{ #category : 'accessing' }
TtNote2 >> page: aLePage [
	page := aLePage
]
