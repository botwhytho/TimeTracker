Class {
	#name : #TtPlaceholderCategory,
	#superclass : #TtCategory,
	#classInstVars : [
		'categories'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtPlaceholderCategory class >> categories [
	^ categories ifNil: [ categories := Dictionary new ]
]

{ #category : #initialization }
TtPlaceholderCategory class >> fromName: categoryName [
	^ self categories at: categoryName ifAbsentPut: [ self new name: categoryName ]
]
