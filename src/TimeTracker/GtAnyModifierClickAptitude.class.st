Class {
	#name : #GtAnyModifierClickAptitude,
	#superclass : #BrAptitude,
	#category : #TimeTracker
}

{ #category : #initialization }
GtAnyModifierClickAptitude >> initializeListeners [
	self flag: #TEMPFIX.	"This aptitude shouldn't be needed at all when upstream changes are merged in BrButton to enable modifiers"
	super initializeListeners.

	self
		when: BlClickEvent
		do: [ :aBlClickEvent | self widget viewModel clickEvent: aBlClickEvent ]
]
