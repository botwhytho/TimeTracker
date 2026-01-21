Class {
	#name : 'TtIdealsSnippet',
	#superclass : 'LeAbstractSerializedObjectSnippet',
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'initialization' }
TtIdealsSnippet class >> initialize [
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newReader.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : 'lepiter-store' }
TtIdealsSnippet class >> leJsonV4Name [
	^ #TtIdealsSnippet
]
