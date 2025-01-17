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

{ #category : #'as yet unclassified' }
TtNoteSnippet >> gtInspectNoteFor: anAction [
	<gtAction>
	self domainObject ifNil: [ ^ anAction noAction ].
	^ anAction button
		icon: BrGlamorousVectorIcons inspect;
		label: 'Inspect Note';
		action: [ :aBrButton :aBrTab :aBrButtonModel :aBlClickEvent | aBrButton phlow spawnObject: self domainObject ]
]

{ #category : #views }
TtNoteSnippet >> gtPageFor: aView [
	<gtView>
	(self domainObject isNil and: [ self domainObject page isNil ])
		ifTrue: [ ^ aView empty ].
	^ aView forward
		title: 'Linked Page';
		priority: 1.5;
		object: [ self domainObject ];
		view: #gtPreviewFor:
]
