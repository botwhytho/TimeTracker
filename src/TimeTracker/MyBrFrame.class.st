Class {
	#name : #MyBrFrame,
	#superclass : #BrFrame,
	#category : #'TimeTracker-Layout Widgets'
}

{ #category : #'api - displaying' }
MyBrFrame >> hide [
	self flag: #HACK. "Maintaingng this here for compatibility with BrWithExplicitMenuAptitude. Remove this class when upstream catches up"
	self removeFromParent.
]
