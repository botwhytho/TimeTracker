Class {
	#name : #LeJsonSnippetElement,
	#superclass : #LeEvaluatedSnippetElement,
	#instVars : [
		'contentElement',
		'bindingEditor',
		'indicatorElement',
		'indicatorStencil'
	],
	#category : #TimeTracker
}

{ #category : #'private - accessing' }
LeJsonSnippetElement >> editorElement [
	"Answer the BrEditor used by the receiver"

	^ editorElement
]

{ #category : #initialization }
LeJsonSnippetElement >> go [
	| string bindingName sharedBindings binding |
	string := editorElement text asString.
	self snippetViewModel contentString: string.
	bindingName := bindingEditor text asString.
	self snippetViewModel bindingName: bindingName.
	sharedBindings := self snippetViewModel snippetBindings.
	binding := sharedBindings bindingOf: bindingName asSymbol.
	binding value: string.
	^ string
]

{ #category : #initialization }
LeJsonSnippetElement >> initialize [
	super initialize.
	self initializeEditorElement.
	contentElement := BrFrame new
			hMatchParent;
			vFitContent;
			addChild: editorElement
]

{ #category : #initialization }
LeJsonSnippetElement >> initializeEditorElement [
	editorElement := GtSourceCoderEditorElement new
			hMatchParent;
			vFitContentLimited;
			padding: (BlInsets
					top: 5
					left: 7
					bottom: 5
					right: 0);
			margin: BlInsets empty.
	editorElement editor
		addEventHandler: (LeEditorReachedBorderEventHandler new snippetElement: self);
		ensureNoUndoRedoShortcuts.

	true
		ifFalse: [ editorElement aptitudeDo: [ :aLook | aLook glamorousRegularDefaultFont ] ]
]

{ #category : #'api - snippet view model' }
LeJsonSnippetElement >> onSnippetViewModelChanged [
	super onSnippetViewModelChanged.
	self updateElement
]

{ #category : #'private - announcement handling' }
LeJsonSnippetElement >> onStringFormatChanged: anAnnouncement [
	BlTaskAction
		enqueueElement: self
		action: [ self updateIndicatorElement.
			self updateEditorElement ]
]

{ #category : #accessing }
LeJsonSnippetElement >> snippetContent [
	^ contentElement
]

{ #category : #'api - snippet view model' }
LeJsonSnippetElement >> subscribeToSnippetViewModel [
	super subscribeToSnippetViewModel.

	self snippetViewModel announcer weak
		when: LeStringFormatChanged
		send: #onStringFormatChanged:
		to: self
]

{ #category : #'api - snippet view model' }
LeJsonSnippetElement >> unsubscribeFromSnippetViewModel [
	super unsubscribeFromSnippetViewModel.

	self snippetViewModel announcer unsubscribe: self
]

{ #category : #'private - updating' }
LeJsonSnippetElement >> updateBindingElement [
	bindingEditor
		text: (self snippetViewModel bindingName ifNil: [ String new ]) asRopedText
]

{ #category : #'private - updating' }
LeJsonSnippetElement >> updateEditorElement [
	| aParserClass |
	editorElement
		text: (self snippetViewModel contentString ifNil: [ String empty ]) asRopedText.

	aParserClass := self snippetViewModel parser.
	(aParserClass isNotNil and: [ aParserClass gtStyler isNotNil ])
		ifTrue: [ editorElement styler: aParserClass gtStyler ]
]

{ #category : #'private - updating' }
LeJsonSnippetElement >> updateElement [
	self updateEditorElement.
	self updateBindingElement.
	self updateIndicatorElement.
]

{ #category : #'private - updating' }
LeJsonSnippetElement >> updateIndicatorElement [
	| aParserClass aParserName anIndicatorLabel |
	aParserClass := self snippetViewModel parser.
	aParserName := LeStringParserNameBuilder new
			parserClass: aParserClass;
			build.
	anIndicatorLabel := aParserName
			ifNil: [ 'String' ]
			ifNotNil: [ 'String ({1})' format: {aParserName} ].
	indicatorElement label: anIndicatorLabel.
	indicatorStencil label: anIndicatorLabel
]
