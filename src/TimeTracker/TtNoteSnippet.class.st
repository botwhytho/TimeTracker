Class {
	#name : #TtNoteSnippet,
	#superclass : #LeUnknownSnippet,
	#instVars : [
		'domainObject'
	],
	#category : #TimeTracker
}

{ #category : #serialization }
TtNoteSnippet class >> deserializerClass [
	^ NoteSnippetDeserializer
]

{ #category : #initialization }
TtNoteSnippet class >> initialize [
	super initialize.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : #accessing }
TtNoteSnippet class >> leJsonV4Name [

	^ 'noteSnippet'
]

{ #category : #accessing }
TtNoteSnippet >> domainObject [
	^ domainObject
]

{ #category : #accessing }
TtNoteSnippet >> domainObject: aTtNote [
	domainObject := aTtNote
]
