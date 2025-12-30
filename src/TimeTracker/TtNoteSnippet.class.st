Class {
	#name : 'TtNoteSnippet',
	#superclass : 'LeAbstractSerializedObjectSnippet',
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'initialization' }
TtNoteSnippet class >> initialize [
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newReader.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : 'lepiter-store' }
TtNoteSnippet class >> leJsonV4Name [
	^ #TtNoteSnippet
]

{ #category : 'as yet unclassified' }
TtNoteSnippet >> gtInspectNoteFor: anAction [
	<gtAction>
	self object ifNil: [ ^ anAction noAction ].
	^ anAction button
		icon: BrGlamorousVectorIcons inspect;
		label: 'Inspect Note';
		action: [ :aBrButton :aBrTab :aBrButtonModel :aBlClickEvent | aBrButton phlow spawnObject: self object ]
]

{ #category : 'views' }
TtNoteSnippet >> gtPageFor: aView [
	<gtView>
	(self object isNil and: [ self object page isNil ]) ifTrue: [ ^ aView empty ].
	^ aView forward
		title: 'Linked Page';
		priority: 1.5;
		object: [ self object ];
		view: #gtPreviewFor:
]
