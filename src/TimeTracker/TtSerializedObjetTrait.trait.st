Trait {
	#name : 'TtSerializedObjetTrait',
	#instVars : [
		'collection'
	],
	#traits : 'TLeSerializedProtoObject',
	#classTraits : 'TLeSerializedProtoObject classTrait',
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
	^ self rootCollection ifNotNil: #page
]

{ #category : 'loading' }
TtSerializedObjetTrait >> onLoadedFromLepiter [
]

{ #category : 'deleting' }
TtSerializedObjetTrait >> preDeleteAction [
	self collection
		ifNotNil: [ [ self collection remove: self ] on: NotFound do: [  ].
			[ self rootCollection remove: self ] on: NotFound do: [  ] ]
]

{ #category : 'accessing' }
TtSerializedObjetTrait >> rootCollection [
	^ self collection ifNotNil: #rootCollection
]
