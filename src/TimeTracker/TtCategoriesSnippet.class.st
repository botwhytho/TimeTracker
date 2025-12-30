Class {
	#name : 'TtCategoriesSnippet',
	#superclass : 'LeSerializedObjectSnippet',
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'api - accessing menu' }
TtCategoriesSnippet class >> contextMenuItemSpecification [
	"<leSnippetSpecification>"

	^ LeContextMenuItemSpecification new
		snippetClass: self;
		title: self description
]

{ #category : 'initialization' }
TtCategoriesSnippet class >> initialize [
	super initialize.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newReader.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : 'lepiter-store' }
TtCategoriesSnippet class >> leJsonV4Name [
	^ #TtCategoriesSnippet
]
