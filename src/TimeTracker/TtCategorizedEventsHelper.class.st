Class {
	#name : 'TtCategorizedEventsHelper',
	#superclass : 'Object',
	#instVars : [
		'category',
		'collection',
		'sum',
		'startAngle',
		'endAngle'
	],
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'accessing' }
TtCategorizedEventsHelper >> category [
	^ category
]

{ #category : 'accessing' }
TtCategorizedEventsHelper >> category: anObject [
	category := anObject
]

{ #category : 'accessing' }
TtCategorizedEventsHelper >> collection [
	^ collection
]

{ #category : 'accessing' }
TtCategorizedEventsHelper >> collection: aTtEventCollection [
	collection := aTtEventCollection
]

{ #category : 'accessing' }
TtCategorizedEventsHelper >> endAngle [
	^ endAngle
]

{ #category : 'accessing' }
TtCategorizedEventsHelper >> endAngle: anObject [
	endAngle := anObject
]

{ #category : 'printing' }
TtCategorizedEventsHelper >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPut: $(;
		nextPutAll: self collection size asString , ' events categorized as '''
				, (self category isString
						ifTrue: [ 'Uncategorized' ]
						ifFalse: [ self category name ]) , ''' lasting ' , self sum asHours asString
				, ' hours';
		nextPut: $)
]

{ #category : 'accessing' }
TtCategorizedEventsHelper >> startAngle [
	^ startAngle
]

{ #category : 'accessing' }
TtCategorizedEventsHelper >> startAngle: anObject [
	startAngle := anObject
]

{ #category : 'accessing' }
TtCategorizedEventsHelper >> sum [
	^ sum
]

{ #category : 'accessing' }
TtCategorizedEventsHelper >> sum: anObject [
	sum := anObject
]
