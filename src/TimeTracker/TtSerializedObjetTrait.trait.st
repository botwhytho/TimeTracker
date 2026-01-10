Trait {
	#name : 'TtSerializedObjetTrait',
	#instVars : [
		'collection'
	],
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'converting' }
TtSerializedObjetTrait >> asTimespan [
	^ (self isKindOf: Timespan)
		ifTrue: [ self as: self value class superclass ]
		ifFalse: [ nil ]
]

{ #category : 'accessing' }
TtSerializedObjetTrait >> collection [
	^ collection
]

{ #category : 'accessing' }
TtSerializedObjetTrait >> collection: aTtEventCollection [
	collection := aTtEventCollection
]

{ #category : 'serialization' }
TtSerializedObjetTrait >> findPage [
	^ self rootCollection page
]

{ #category : 'deleting' }
TtSerializedObjetTrait >> preDeleteAction [
	[ self collection remove: self ] on: NotFound do: [  ].
	[ self rootCollection remove: self ] on: NotFound do: [  ]
]

{ #category : 'accessing' }
TtSerializedObjetTrait >> rootCollection [
	^ self collection rootCollection
]
