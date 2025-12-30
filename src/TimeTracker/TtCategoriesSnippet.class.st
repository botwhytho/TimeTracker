Class {
	#name : 'TtCategoriesSnippet',
	#superclass : 'LeAbstractSerializedObjectSnippet',
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'initialization' }
TtCategoriesSnippet class >> initialize [
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newReader.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : 'lepiter-store' }
TtCategoriesSnippet class >> leJsonV4Name [
	^ #TtCategoriesSnippet
]
