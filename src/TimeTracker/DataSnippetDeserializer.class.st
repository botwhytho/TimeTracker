Class {
	#name : 'DataSnippetDeserializer',
	#superclass : 'Object',
	#instVars : [
		'data'
	],
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'serialization' }
DataSnippetDeserializer class >> neoJsonMapping: aNeoJSONMapper [
	self flag: #TODO.	"This is some indirection because we are 'overloading' the `LeUnkownSnippet` class by adding a 'data' key into the JSON representation of snippets. Might be better to create a generic 'data snippet' at some point."
	aNeoJSONMapper
		for: self
		do: [ :aMapping | (aMapping mapInstVar: #data) valueSchema: self schemaClass ]
]

{ #category : 'accessing' }
DataSnippetDeserializer class >> schemaClass [
	self subclassResponsibility
]

{ #category : 'accessing' }
DataSnippetDeserializer >> data [
	^ data
]
