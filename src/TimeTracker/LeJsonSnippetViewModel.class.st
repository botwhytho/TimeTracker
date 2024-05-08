Class {
	#name : #LeJsonSnippetViewModel,
	#superclass : #LeCodeSnippetViewModel,
	#category : #TimeTracker
}

{ #category : #accessing }
LeJsonSnippetViewModel >> bindingName [
	^ self snippetModel bindingName
]

{ #category : #accessing }
LeJsonSnippetViewModel >> bindingName: aNameString [
	^ self snippetModel bindingName: aNameString
]

{ #category : #accessing }
LeJsonSnippetViewModel >> contentString [
	^ self snippetModel contentString
]

{ #category : #accessing }
LeJsonSnippetViewModel >> contentString: aString [
	^ self snippetModel contentString: aString
]

{ #category : #accessing }
LeJsonSnippetViewModel >> format [
	^ self snippet format
]

{ #category : #accessing }
LeJsonSnippetViewModel >> format: aFormatString [
	^ self snippet format: aFormatString
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

	self updateResultVariableBindings
]

{ #category : #'api - snippet model' }
LeJsonSnippetViewModel >> onStringBindingNameChanged: anAnnouncement [
	LeBindingNameUpdater new
		oldName: anAnnouncement oldName;
		newName: anAnnouncement newName;
		newValue: self contentString; 
		bindings: self snippetBindings;
		onSuccess: [ self announce: anAnnouncement ];
		update
]

{ #category : #'private - announcement handling' }
LeJsonSnippetViewModel >> onStringFormatChanged: anAnnouncement [
	self announcer announce: anAnnouncement
]

{ #category : #accessing }
LeJsonSnippetViewModel >> parser [
	^ self snippetModel parser
]

{ #category : #'api - shared context' }
LeJsonSnippetViewModel >> sharedSnippetContext: aLeSharedSnippetContext [
	super sharedSnippetContext: aLeSharedSnippetContext.
	
	self updateResultVariableBindings
]

{ #category : #accessing }
LeJsonSnippetViewModel >> snippetElementClass [
	^ LeStringSnippetElement
]

{ #category : #'api - snippet model' }
LeJsonSnippetViewModel >> subscribeToSnippetModel [
	super subscribeToSnippetModel.

	self snippetModel announcer weak
		when: LeStringFormatChanged
		send: #onStringFormatChanged:
		to: self;
		when: LeStringBindingNameChanged
		send: #onStringBindingNameChanged:
		to: self
]

{ #category : #'api - snippet model' }
LeJsonSnippetViewModel >> unsubscribeFromSnippetModel [
	super unsubscribeFromSnippetModel.

	self snippetModel announcer unsubscribe: self
]

{ #category : #'private - updating' }
LeJsonSnippetViewModel >> updateResultVariableBindings [
	LeBindingNameUpdater new
		newName: self bindingName;
		newValue: self contentString;
		bindings: self snippetBindings;
		update
]
