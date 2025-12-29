Class {
	#name : 'TtTrackedTimePageType',
	#superclass : 'LeNamedPageType',
	#category : 'TimeTracker-Model',
	#package : 'TimeTracker',
	#tag : 'Model'
}

{ #category : 'initialization' }
TtTrackedTimePageType class >> initialize [
	super initialize.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newReader.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter.
	LeDatabasesRegistry defaultLogicalDatabase databases
		do: [ :aDatabase | aDatabase pagesByType at: self ifAbsentPut: [ GtStringContentDictionary new ] ]
]

{ #category : 'lepiter-store' }
TtTrackedTimePageType class >> leJsonV3Name [
	^ #TtTrackedTimePageType
]

{ #category : 'lepiter-store' }
TtTrackedTimePageType class >> leJsonV4Name [
	^ #TtTrackedTimePageType
]

{ #category : 'printing' }
TtTrackedTimePageType >> printOn: aStream [

	aStream 
		nextPutAll: 'Tracked Time Page: ';
		print: title
]
