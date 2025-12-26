Class {
	#name : 'TrackedTimeSnippetDeserializer',
	#superclass : 'DataSnippetDeserializer',
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'accessing' }
TrackedTimeSnippetDeserializer class >> schemaClass [
	^ TtTrackedTime
]
