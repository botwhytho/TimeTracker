Class {
	#name : #LeJsonSnippet,
	#superclass : #LeCodeSnippet,
	#instVars : [
		'contentString',
		'schema'
	],
	#classInstVars : [
		'schema'
	],
	#category : #TimeTracker
}

{ #category : #'api - accessing menu' }
LeJsonSnippet class >> contextMenuItemSpecification [
	<leSnippetSpecification>
	self flag: #TODO "Remove this, only have this for testing but shouldn't be able to chose from meny as this snippet type is for programatic use".
	^ LeContextMenuItemSpecification new
		snippetClass: self;
		title: 'JSON'
]

{ #category : #accessing }
LeJsonSnippet class >> empty [
	^ self new
]

{ #category : #accessing }
LeJsonSnippet class >> leJsonV4AttributeMapping [
	^ LeSnippet leJsonV4AttributeMapping
		add: (#contentString -> #contentString);
		add: (#schema -> #schema);
		yourself
]

{ #category : #accessing }
LeJsonSnippet class >> leJsonV4Name [
	^ 'jsonSnippet'
]

{ #category : #accessing }
LeJsonSnippet class >> schema [
	^ schema
]

{ #category : #accessing }
LeJsonSnippet class >> schema: anObject [
	schema := anObject
]

{ #category : #visiting }
LeJsonSnippet >> acceptVisitor: aVisitor [
 
	^ aVisitor visitJsonSnippet: self
]

{ #category : #'api - editing' }
LeJsonSnippet >> announceTextChangedBy: anObject withTextEditCommand: aTextEditCommand [ 
	"Notify all dependents that the receiver's text has changed"

	self notifyAnnouncement: (LeSnippetTextChanged new
		source: anObject;
		snippet: self;
		textEditCommand: aTextEditCommand)
]

{ #category : #'api - editing' }
LeJsonSnippet >> appendText: aText [
	self shouldNotImplement
]

{ #category : #converting }
LeJsonSnippet >> asPhlowTool [
	^ GtPhlowCompositeTool new
		addTool: (LeIsolatedSnippetPhlowTool snippet: self);
		addTool: (GtPhlowTool default object: self)
]

{ #category : #converting }
LeJsonSnippet >> asSnippetViewModel [
	<return: #LeSnippetViewModel>
	^ LeJsonSnippetViewModel new snippetModel: self
]

{ #category : #accessing }
LeJsonSnippet >> ast [
	self contentString ifEmpty: [ ^ nil ].
	^ self parser parseWithErrors: self contentAsString
]

{ #category : #accessing }
LeJsonSnippet >> contentAsString [
	^ self contentString ifNil: [ String new ]
]

{ #category : #accessing }
LeJsonSnippet >> contentString [
	^ contentString ifNil: [ contentString := String empty ]
]

{ #category : #accessing }
LeJsonSnippet >> contentString: aString [
	contentString := aString.
	self announceTextChangedBy: self
]

{ #category : #initialization }
LeJsonSnippet >> defaultPreviewHeight [
	^ 300
]

{ #category : #accessing }
LeJsonSnippet >> deserialize [
	self schema
		ifNil: [ self class schema
				ifNil: [ ^ NeoJSONReader fromString: self contentString ]
				ifNotNil: [ ^ NeoJSONReader fromString: self contentString as: self class schema ] ]
		ifNotNil: [ ^ NeoJSONReader fromString: self contentString as: self schema ]
]

{ #category : #initialization }
LeJsonSnippet >> newCoder [
	^ GtTextCoder new
]

{ #category : #'api - accessing' }
LeJsonSnippet >> paragraphStyle [
	^ LeParagraphStyle text
]

{ #category : #accessing }
LeJsonSnippet >> parser [
	^ JSONParser
]

{ #category : #accessing }
LeJsonSnippet >> schema [
	^ schema
]

{ #category : #accessing }
LeJsonSnippet >> schema: anObject [
	schema := anObject
]

{ #category : #accessing }
LeJsonSnippet >> text [
	^ self contentString asRopedText
]
