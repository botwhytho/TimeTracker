Class {
	#name : #LeJsonSnippetViewModel,
	#superclass : #LeCodeSnippetViewModel,
	#category : #TimeTracker
}

{ #category : #accessing }
LeJsonSnippetViewModel >> contentString [
	^ self snippetModel contentString
]

{ #category : #accessing }
LeJsonSnippetViewModel >> contentString: aString [
	^ self snippetModel contentString: aString
]

{ #category : #initialization }
LeJsonSnippetViewModel >> initializeCoderAddOns: aTextualCoderViewModel [
	"Initialise the keyboard shortcuts in the code editor"

	super initializeCoderAddOns: aTextualCoderViewModel.
	
	aTextualCoderViewModel
		"Indent LeSnippet"
		addShortcut: (LeSnippetIndentSnippetShortcut new combination: (self keyboardShortcut: #IndentSnippet));
		"Unindent LeSnippet"
		addShortcut: (LeSnippetUnindentSnippetShortcut new combination: (self keyboardShortcut: #UnindentSnippet));
		"Move Snippet up"
		addShortcut: (LeSnippetMoveSnippetUpShortcut new combination: (self keyboardShortcut: #MoveSnippetUp));
		"Move Snippet down"
		addShortcut: (LeSnippetMoveSnippetDownShortcut new combination: (self keyboardShortcut: #MoveSnippetDown))
]

{ #category : #'api - snippet model' }
LeJsonSnippetViewModel >> onSnippetModelChanged [
	super onSnippetModelChanged.
	self onTextChanged: LeSnippetTextChanged new.
]

{ #category : #'private - announcement handling' }
LeJsonSnippetViewModel >> onTextChanged: anAnnouncement [
	self announcer announce: anAnnouncement
]

{ #category : #accessing }
LeJsonSnippetViewModel >> parser [
	^ self snippetModel parser
]

{ #category : #accessing }
LeJsonSnippetViewModel >> snippetElementClass [
	^ LeJsonSnippetElement
]

{ #category : #'api - snippet model' }
LeJsonSnippetViewModel >> subscribeToSnippetModel [
	super subscribeToSnippetModel.

	self snippetModel announcer weak
		when: LeSnippetTextChanged
			send: #onTextChanged:
			to: self
]

{ #category : #'api - snippet model' }
LeJsonSnippetViewModel >> unsubscribeFromSnippetModel [
	super unsubscribeFromSnippetModel.

	self snippetModel announcer unsubscribe: self
]
