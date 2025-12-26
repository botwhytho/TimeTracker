Class {
	#name : 'TtCategoriesSnippet',
	#superclass : 'LeUnknownSnippet',
	#instVars : [
		'domainObject'
	],
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'initialization' }
TtCategoriesSnippet class >> initialize [
	super initialize.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : 'accessing' }
TtCategoriesSnippet class >> leJsonV4Name [

	^ 'categorySnippet'
]

{ #category : 'accessing' }
TtCategoriesSnippet >> domainObject [
	^ domainObject
]

{ #category : 'accessing' }
TtCategoriesSnippet >> domainObject: aTtCategories [
	domainObject := aTtCategories
]
