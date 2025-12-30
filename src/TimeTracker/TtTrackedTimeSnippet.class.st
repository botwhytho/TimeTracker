Class {
	#name : 'TtTrackedTimeSnippet',
	#superclass : 'LeAbstractSerializedObjectSnippet',
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'initialization' }
TtTrackedTimeSnippet class >> initialize [
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newReader.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : 'lepiter-store' }
TtTrackedTimeSnippet class >> leJsonV4Name [
	^ #TtTrackedTimeSnippet
]
