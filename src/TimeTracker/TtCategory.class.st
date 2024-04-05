Class {
	#name : #TtCategory,
	#superclass : #Object,
	#instVars : [
		'name',
		'hierarchy',
		'children',
		'parentCategory'
	],
	#category : #TimeTracker
}

{ #category : #comparing }
TtCategory >> <= other [
	^ self name <= other name
]

{ #category : #accessing }
TtCategory >> children [
	^ children ifNil: [ children := SortedCollection new ]
]

{ #category : #accessing }
TtCategory >> hierarchy [
	^ hierarchy ifNil: [ self rootCategory hierarchy ]
]

{ #category : #accessing }
TtCategory >> hierarchy: aTtCategories [
	hierarchy := aTtCategories
]

{ #category : #accessing }
TtCategory >> name [
	^ name
]

{ #category : #accessing }
TtCategory >> name: aName [
	name := aName
]

{ #category : #serialization }
TtCategory >> neoJsonOn: aWriter [
	{'name' -> name.
		'children' -> (children ifNil: [ #() ])} asDictionary neoJsonOn: aWriter
]

{ #category : #accessing }
TtCategory >> parentCategory [
	^ parentCategory
]

{ #category : #accessing }
TtCategory >> parentCategory: aTtCategory [
	parentCategory := aTtCategory
]

{ #category : #printing }
TtCategory >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPut: $(;
		nextPutAll: self name;
		nextPut: $)
]

{ #category : #accessing }
TtCategory >> rootCategory [
	| category |
	category := self.
	[ category parentCategory ] whileNotNil: [ category := category parentCategory ].
	^ category
]
