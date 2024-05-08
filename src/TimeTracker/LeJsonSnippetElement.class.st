Class {
	#name : #LeJsonSnippetElement,
	#superclass : #LeEvaluatedSnippetElement,
	#instVars : [
		'contentElement'
	],
	#category : #TimeTracker
}

{ #category : #'private - accessing' }
LeJsonSnippetElement >> editorElement [
	"Answer the BrEditor used by the receiver"

	^ editorElement
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
			margin: BlInsets empty;
			beMode: BrTextEditorReadonlyWithSelectionMode new.
	editorElement editor ensureNoUndoRedoShortcuts.

	true
		ifFalse: [ editorElement aptitudeDo: [ :aLook | aLook glamorousRegularDefaultFont ] ]
]

{ #category : #'api - snippet view model' }
LeJsonSnippetElement >> onSnippetViewModelChanged [
	super onSnippetViewModelChanged.
	self updateElement
]

{ #category : #'private - announcement handling' }
LeJsonSnippetElement >> onTextChanged: anAnnouncement [
	BlTaskAction enqueueElement: self action: [ self updateElement ]
]

{ #category : #accessing }
LeJsonSnippetElement >> snippetContent [
	^ contentElement
]

{ #category : #'api - snippet view model' }
LeJsonSnippetElement >> subscribeToSnippetViewModel [
	super subscribeToSnippetViewModel.

	self snippetViewModel announcer weak
		when: LeSnippetTextChanged
		send: #onTextChanged:
		to: self
]

{ #category : #'api - snippet view model' }
LeJsonSnippetElement >> unsubscribeFromSnippetViewModel [
	super unsubscribeFromSnippetViewModel.

	self snippetViewModel announcer unsubscribe: self
]

{ #category : #'private - updating' }
LeJsonSnippetElement >> updateCoderUIModel [
	editorElement textualCoderViewModel: self snippetViewModel coderViewModel
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
	self updateEditorElement
]
