Class {
	#name : #TtRootCategory,
	#superclass : #TtCategory,
	#instVars : [
		'collection',
		'uid'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtRootCategory >> collection [
	^ collection
]

{ #category : #accessing }
TtRootCategory >> collection: aTtEventCollection [
	collection := aTtEventCollection
]

{ #category : #accessing }
TtRootCategory >> uid [
	^ uid
]

{ #category : #accessing }
TtRootCategory >> uid: anObject [
	uid := anObject
]
