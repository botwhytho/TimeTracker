Class {
	#name : 'TtNote',
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
TtNote class >> initialize [
	super initialize.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newReader.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : 'serialization' }
TtNote class >> leJsonV4MappingFor: aNeoJSONMapper [
	aNeoJSONMapper
		for: self
		do: [ :aMapping | 
			aMapping
				mapProperty: #__type
				getter: [ :object | object class leJsonV4Name ]
				setter: [ :um | self error: 'Objects should not be read here' ].
			aMapping
				mapProperty: #database
				getter: [ :aTtNote | aTtNote database ifNotNil: #uuidString ]
				setter: [ :um | self error: 'Objects should not be read here' ].
			aMapping
				mapProperty: #page
				getter: [ :aTtNote | aTtNote page ifNotNil: #uidString ]
				setter: [ :um | self error: 'Objects should not be read here' ].
			aMapping mapInstVars: #(duration start) ]
]

{ #category : 'lepiter-store' }
TtNote class >> leJsonV4Name [
	^ #TtNote
]

{ #category : 'serialization' }
TtNote class >> snippetClass [
	^ TtNoteSnippet
]

{ #category : 'accessing' }
TtNote >> database [
	^ database
]

{ #category : 'accessing' }
TtNote >> database: aLeDatabase [
	database := aLeDatabase
]

{ #category : 'views' }
TtNote >> gtPreviewFor: aView [
	<gtView>
	self page ifNil: [ ^ aView empty ].
	^ aView forward
		title: 'Linked Page';
		object: [ self page ];
		view: #gtLiveFor:
]

{ #category : 'testing' }
TtNote >> isNote [
	^ true
]

{ #category : 'loading' }
TtNote >> onLoadedFromLepiter [
	| aDatabase aPage |
	self page isString
		ifTrue: [ aDatabase := (LeLogicalDatabase allSubInstances
					collect: [ :each | each databaseWithID: self database ifNone: [ nil ] ])
					detect: #isNotNil
					ifNone: [ nil ].

			aPage := aDatabase
					ifNil: [ nil ]
					ifNotNil: [ :notNil | notNil pageWithID: self page ifAbsent: [ nil ] ].

			aPage
				ifNotNil: [ self database: aDatabase.
					self page: aPage ] ]
]

{ #category : 'accessing' }
TtNote >> page [
	^ page
]

{ #category : 'accessing' }
TtNote >> page: aLePage [
	page := aLePage
]
