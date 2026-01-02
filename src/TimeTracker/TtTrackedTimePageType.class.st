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
TtTrackedTimePageType class >> leJsonV4Name [
	^ #TtTrackedTimePageType
]

{ #category : 'lepiter' }
TtTrackedTimePageType >> asLepiterPagePhlowToolFocusStatus: aBoolean [
	^ GtPhlowExplicitCompositeTool new
		toolStencil: [ GtPhlowCompositeTool new
				addTool: (GtInspectorTool new withLabelAndIconAptitude
						name: 'Time Tracker';
						object: (TtEventCollection pageRegistry at: self page));
				addTool: (GtInspectorTool new withLabelAndIconAptitude
						name: 'Page Type';
						object: self);
				addTool: (GtInspectorTool new withLabelAndIconAptitude
						name: 'Page';
						object: self page);
				addTool: (LePagePhlowTool new
						shouldFocusFirstSnippet: aBoolean;
						page: self page) ]
]

{ #category : 'printing' }
TtTrackedTimePageType >> printOn: aStream [

	aStream 
		nextPutAll: 'Tracked Time Page: ';
		print: title
]
