Trait {
	#name : 'TtSerializedObjetTrait',
	#instVars : [
		'snippet',
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

{ #category : 'deleting' }
TtSerializedObjetTrait >> delete [
	[ self collection remove: self ] on: NotFound do: [  ].
	[ self rootCollection remove: self ] on: NotFound do: [  ].
	self snippet removeSelf
]

{ #category : 'accessing' }
TtSerializedObjetTrait >> page [
	^ self snippet ifNil: [ nil ] ifNotNil: [ :aSnippet | aSnippet page ]
]

{ #category : 'accessing' }
TtSerializedObjetTrait >> rootCollection [
	^ self collection rootCollection
]

{ #category : 'serialization' }
TtSerializedObjetTrait >> serialize [
	self snippet
		ifNil: [ | newSnippet |
			newSnippet := self class snippetClass new object: self.
			self rootCollection page ifNotNil: [ :aPage | aPage addSnippet: newSnippet ] ]
		ifNotNil: [ :notNil | notNil serialize ]
]

{ #category : 'accessing' }
TtSerializedObjetTrait >> snippet [
	^ snippet
]

{ #category : 'accessing' }
TtSerializedObjetTrait >> snippet: aSnippet [
	snippet := aSnippet
]
