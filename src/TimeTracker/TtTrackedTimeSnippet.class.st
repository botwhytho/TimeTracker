Class {
	#name : #TtTrackedTimeSnippet,
	#superclass : #LeUnknownSnippet,
	#category : #TimeTracker
}

{ #category : #serialization }
TtTrackedTimeSnippet class >> deserializerClass [
	^ TrackedTimeSnippetDeserializer
]

{ #category : #initialization }
TtTrackedTimeSnippet class >> initialize [
	super initialize.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : #accessing }
TtTrackedTimeSnippet class >> leJsonV4Name [

	^ 'trackedTimeSnippet'
]
