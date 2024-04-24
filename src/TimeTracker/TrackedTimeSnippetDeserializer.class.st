Class {
	#name : #TrackedTimeSnippetDeserializer,
	#superclass : #DataSnippetDeserializer,
	#category : #TimeTracker
}

{ #category : #accessing }
TrackedTimeSnippetDeserializer class >> schemaClass [
	^ TtTrackedTime
]
