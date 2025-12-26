Class {
	#name : 'NoteSnippetDeserializer',
	#superclass : 'DataSnippetDeserializer',
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'accessing' }
NoteSnippetDeserializer class >> schemaClass [
	^ TtNote
]
