Class {
	#name : #TtCategory,
	#superclass : #Object,
	#instVars : [
		'parent',
		'name',
		'hierarchy',
		'children'
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
	^ hierarchy
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
TtCategory >> parent [
	^ parent ifNil: [ ^ #() ] ifNotNil: [ ^ {parent} ]
]

{ #category : #accessing }
TtCategory >> parent: aTtCategory [
	parent := aTtCategory
]
