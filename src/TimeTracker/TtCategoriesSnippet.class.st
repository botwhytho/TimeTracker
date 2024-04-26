Class {
	#name : #TtCategoriesSnippet,
	#superclass : #LeUnknownSnippet,
	#category : #TimeTracker
}

{ #category : #initialization }
TtCategoriesSnippet class >> initialize [
	super initialize.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : #accessing }
TtCategoriesSnippet class >> leJsonV4Name [

	^ 'categorySnippet'
]
