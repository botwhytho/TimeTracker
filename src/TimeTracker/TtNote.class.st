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
	aNeoJSONMapper
		for: self
			do: [ :aMapping | 
				aMapping mapInstVars: #(database page).
				(aMapping mapInstVar: #start) valueSchema: DateAndTime.
				(aMapping mapInstVar: #duration) valueSchema: Duration ];
		for: DateAndTime
			customDo: [ :mapping | 
				mapping decoder: [ :string | DateAndTime fromString: string ].
				mapping encoder: [ :dateAndTime | dateAndTime printString ] ];
		for: Duration
			customDo: [ :mapping | 
				mapping decoder: [ :aString | aString asDuration ].
				mapping encoder: [ :aDuration | aDuration asString ] ]
]

{ #category : #serialization }
TtNote class >> snippetClass [
	^ TtNoteSnippet
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

{ #category : #accessing }
TtNote >> page [
	^ page
]

{ #category : #accessing }
TtNote >> page: aLePage [
	page := aLePage
]

{ #category : #accessing }
TtNote >> uid [
	^ uid
]

{ #category : #accessing }
TtNote >> uid: anObject [
	uid := anObject
]
