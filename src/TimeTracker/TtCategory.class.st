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

{ #category : #accessing }
TtCategory >> children [
	^ children
		ifNil: [ children := SortedCollection
					sortUsing: [ :aCategory | aCategory name ] ascending ]
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
