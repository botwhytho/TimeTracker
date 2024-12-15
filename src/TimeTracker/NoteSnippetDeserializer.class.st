Class {
	#name : #NoteSnippetDeserializer,
	#superclass : #DataSnippetDeserializer,
	#category : #TimeTracker
}

{ #category : #accessing }
NoteSnippetDeserializer class >> schemaClass [
	^ TtNote
]
