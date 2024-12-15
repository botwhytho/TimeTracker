Class {
	#name : #TtNoteSnippet,
	#superclass : #LeUnknownSnippet,
	#category : #TimeTracker
}

{ #category : #initialization }
TtNoteSnippet class >> initialize [
	super initialize.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : #accessing }
TtNoteSnippet class >> leJsonV4Name [

	^ 'noteSnippet'
]
