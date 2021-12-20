Class {
	#name : #TtCheckboxGroupChanged,
	#superclass : #BrStateChangedEvent,
	#instVars : [
		'category'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtCheckboxGroupChanged >> category [

	^ category
]

{ #category : #accessing }
TtCheckboxGroupChanged >> category: anObject [

	category := anObject
]
