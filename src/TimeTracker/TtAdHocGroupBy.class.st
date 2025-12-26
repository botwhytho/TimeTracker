Class {
	#name : 'TtAdHocGroupBy',
	#superclass : 'Object',
	#instVars : [
		'name',
		'description',
		'filter',
		'groupByComputation',
		'collection'
	],
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'accessing' }
TtAdHocGroupBy >> collection [
	^ collection
]

{ #category : 'accessing' }
TtAdHocGroupBy >> collection: anObject [
	collection := anObject
]

{ #category : 'accessing' }
TtAdHocGroupBy >> create [
	| filtered groupedBy |
	filtered := self filter
			ifNil: [ self collection ]
			ifNotNil: [ self collection select: self filter ].
	groupedBy := filtered groupedBy: self groupByComputation.
	^ (groupedBy associations
		collect: [ :anAssociation | 
			(anAssociation key isKindOf: TtCategory)
				ifFalse: [ anAssociation key: (TtPseudoCategory new name: anAssociation key asString) ].
			anAssociation ]) asOrderedDictionary
]

{ #category : 'accessing' }
TtAdHocGroupBy >> description [
	^ description
]

{ #category : 'accessing' }
TtAdHocGroupBy >> description: anObject [
	description := anObject
]

{ #category : 'accessing' }
TtAdHocGroupBy >> filter [
	^ filter
]

{ #category : 'accessing' }
TtAdHocGroupBy >> filter: anObject [
	filter := anObject
]

{ #category : 'accessing' }
TtAdHocGroupBy >> groupByComputation [
	^ groupByComputation
]

{ #category : 'accessing' }
TtAdHocGroupBy >> groupByComputation: anObject [
	groupByComputation := anObject
]

{ #category : 'accessing' }
TtAdHocGroupBy >> name [
	^ name
]

{ #category : 'accessing' }
TtAdHocGroupBy >> name: anObject [
	name := anObject
]
