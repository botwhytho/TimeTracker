Class {
	#name : 'TtTrackedTimeSnippet',
	#superclass : 'LeSerializedObjectSnippet',
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'api - accessing menu' }
TtTrackedTimeSnippet class >> contextMenuItemSpecification [
	"<leSnippetSpecification>"

	^ LeContextMenuItemSpecification new
		snippetClass: self;
		title: self description
]

{ #category : 'initialization' }
TtTrackedTimeSnippet class >> initialize [
	super initialize.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newReader.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : 'lepiter-store' }
TtTrackedTimeSnippet class >> leJsonV3Name [
	^ #TtTrackedTimeSnippet
]

{ #category : 'lepiter-store' }
TtTrackedTimeSnippet class >> leJsonV4Name [
	^ #TtTrackedTimeSnippet
]
