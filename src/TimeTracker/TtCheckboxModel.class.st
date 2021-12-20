Class {
	#name : #TtCheckboxModel,
	#superclass : #BrCheckboxModel,
	#category : #TimeTracker
}

{ #category : #'mouse handlers' }
TtCheckboxModel >> clickEvent: anEvent [

	| anElement |
	anEvent consumed: true.

	anElement := anEvent currentTarget widget.

	anElement states isDisabled ifTrue: [ ^ self ].
	anEvent button = BlMouseButton primary ifTrue: [ 
		anElement requestFocus.
		(anElement isUnchecked or: [ anElement isIndeterminate ]) ifTrue: [ 
			^ anElement check ] ]
]

{ #category : #initialization }
TtCheckboxModel >> initializeListeners [

	super initializeListeners.

	self when: BlClickEvent do: [ :anEvent | self clickEvent: anEvent ].
	self when: BlKeyDownEvent do: [ :anEvent | self keyEvent: anEvent ]
]

{ #category : #'keyboard handlers' }
TtCheckboxModel >> keyEvent: anEvent [

	| anElement |
	anEvent consumed: true.

	anElement := anEvent currentTarget widget.

	anEvent key = BlKeyboardKey arrowLeft ifTrue: [ 
		anElement
			previousSiblingSuchThat: [ :sibling | sibling isFocusable ]
			do: [ :sibling | sibling requestFocus ] ].
	anEvent key = BlKeyboardKey arrowRight ifTrue: [ 
		anElement
			nextSiblingSuchThat: [ :sibling | sibling isFocusable ]
			do: [ :sibling | sibling requestFocus ] ].
	anEvent key = BlKeyboardKey return ifTrue: [ "self halt." 
		anElement isChecked ifFalse: [ anEvent currentTarget check ] ]
]
