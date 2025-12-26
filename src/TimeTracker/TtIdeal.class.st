Class {
	#name : 'TtIdeal',
	#superclass : 'Object',
	#instVars : [
		'category',
		'leeway',
		'minValue',
		'maxValue',
		'priority',
		'timePeriod',
		'computation',
		'description'
	],
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'accessing' }
TtIdeal >> category [
	^ category
]

{ #category : 'accessing' }
TtIdeal >> category: aTtCategory [
	category := aTtCategory
]

{ #category : 'accessing' }
TtIdeal >> computation [
	^ computation
]

{ #category : 'accessing' }
TtIdeal >> computation: aValuable [
	computation := aValuable
]

{ #category : 'accessing' }
TtIdeal >> description [
	^ description
]

{ #category : 'accessing' }
TtIdeal >> description: anObject [
	description := anObject
]

{ #category : 'accessing' }
TtIdeal >> leeway [
	^ leeway
]

{ #category : 'accessing' }
TtIdeal >> leeway: anObject [
	leeway := anObject
]

{ #category : 'accessing' }
TtIdeal >> maxValue [
	^ maxValue
]

{ #category : 'accessing' }
TtIdeal >> maxValue: anObject [
	maxValue := anObject
]

{ #category : 'accessing' }
TtIdeal >> minValue [
	^ minValue
]

{ #category : 'accessing' }
TtIdeal >> minValue: anObject [
	minValue := anObject
]

{ #category : 'printing' }
TtIdeal >> printOn: aStream [
	aStream
		nextPutAll: (self category ifNil: [ self description ] ifNotNil: [ :notNil | notNil name ])
				, ' for ' , (self minValue * 100 printShowingDecimalPlaces: 2) , '-'
				, (self maxValue * 100 printShowingDecimalPlaces: 2) , '% of your time'
]

{ #category : 'accessing' }
TtIdeal >> priority [
	^ priority
]

{ #category : 'accessing' }
TtIdeal >> priority: anObject [
	priority := anObject
]

{ #category : 'accessing' }
TtIdeal >> timePeriod [
	^ timePeriod
]

{ #category : 'accessing' }
TtIdeal >> timePeriod: anObject [
	timePeriod := anObject
]
