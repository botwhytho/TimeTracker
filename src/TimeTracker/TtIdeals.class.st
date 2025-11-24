Class {
	#name : #TtIdeals,
	#superclass : #Timespan,
	#instVars : [
		'ideals',
		'description',
		'notes',
		'collection'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtIdeals >> collection [
	^ collection
]

{ #category : #accessing }
TtIdeals >> collection: anObject [
	collection := anObject
]

{ #category : #accessing }
TtIdeals >> description [
	^ description
]

{ #category : #accessing }
TtIdeals >> description: aString [
	description := aString
]

{ #category : #accessing }
TtIdeals >> ideals [
	^ ideals
		ifNil: [ ideals := SortedCollection sortUsing: [ :each | each maxValue ] descending ]
]

{ #category : #accessing }
TtIdeals >> ideals: anObject [
	ideals := anObject
]

{ #category : #accessing }
TtIdeals >> notes [
	^ notes ifNil: [ notes := OrderedCollection new ]
]

{ #category : #accessing }
TtIdeals >> notes: anObject [
	notes := anObject
]
