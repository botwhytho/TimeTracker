Class {
	#name : 'TtTrackedTime2',
	#superclass : 'Timespan',
	#traits : 'TtSerializedObjetTrait',
	#classTraits : 'TtSerializedObjetTrait classTrait',
	#instVars : [
		'description',
		'details',
		'rawData',
		'daySerializedFrom',
		'category',
		'labels',
		'isPlanned',
		'isRecurring',
		'firstTimeScheduled'
	],
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'initialization' }
TtTrackedTime2 class >> initialize [
	super initialize.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newReader.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : 'lepiter-store' }
TtTrackedTime2 class >> leFromJsonV4Dictionary2: aDictionary [
	| aTrackedTime |
	self flag: #TODO. "DELETE once I confirm this logic can happen when loading into collection"
	aTrackedTime := super leFromJsonV4Dictionary: aDictionary.
	aTrackedTime
		category: (aTrackedTime category
				in: [ :categoryName | 
					| aCollection |
					aCollection := thisContext stack
							detect: [ :each | each receiver class = TtEventCollection ]
							ifFound: [ :found | found receiver ]
							ifNone: [ TtEventCollection new categories: TtCategories new"default" ].
					aCollection categories
						detect: [ :each | each name = categoryName ]
						ifNone: [ categoryName ifNotNil: [ TtPlaceholderCategory fromName: categoryName ] ] ]).
	^ aTrackedTime
]

{ #category : 'serialization' }
TtTrackedTime2 class >> leJsonV4MappingFor: aNeoJSONMapper [
	aNeoJSONMapper
		for: self
		do: [ :aMapping | 
			aMapping
				mapProperty: #__type
				getter: [ :object | object class leJsonV4Name ]
				setter: [ :um | self error: 'Objects should not be read here' ].
			aMapping
				mapProperty: #category
				getter: [ :aTrackedTime | aTrackedTime category name ]
				setter: [ :um | self error: 'Objects should not be read here' ].
			aMapping
				mapInstVars: #(daySerializedFrom description details duration firstTimeScheduled isPlanned isRecurring rawData start) ]
]

{ #category : 'lepiter-store' }
TtTrackedTime2 class >> leJsonV4Name [
	^ #TtTrackedTime
]

{ #category : 'serialization' }
TtTrackedTime2 class >> snippetClass [
	^ TtTrackedTimeSnippet
]

{ #category : 'arithmetic' }
TtTrackedTime2 >> / aNumber [
	^ self duration asHours / aNumber
]

{ #category : 'comparing' }
TtTrackedTime2 >> <= other [
	self flag: #DEPRECATE.	"This looks redundant with superclass chain definitions. Test and remove"
	^ self start <= other start
]

{ #category : 'accessing' }
TtTrackedTime2 >> category [
	^ category
]

{ #category : 'accessing' }
TtTrackedTime2 >> category: anObject [
	category := anObject
]

{ #category : 'accessing' }
TtTrackedTime2 >> createCategoriesSnippetInPage: newPage [ 
]

{ #category : 'accessing' }
TtTrackedTime2 >> daySerializedFrom [
	^ daySerializedFrom
]

{ #category : 'accessing' }
TtTrackedTime2 >> daySerializedFrom: anObject [
	daySerializedFrom := anObject
]

{ #category : 'accessing' }
TtTrackedTime2 >> description [
	^ description
]

{ #category : 'accessing' }
TtTrackedTime2 >> description: anObject [
	description := anObject
]

{ #category : 'accessing' }
TtTrackedTime2 >> details [
	^ details
]

{ #category : 'accessing' }
TtTrackedTime2 >> details: anObject [
	details := anObject
]

{ #category : 'initialization' }
TtTrackedTime2 >> falseAllBooleans [
	isPlanned := false.
	isRecurring := false.
	firstTimeScheduled := false
]

{ #category : 'accessing' }
TtTrackedTime2 >> firstTimeScheduled [
	^ firstTimeScheduled
]

{ #category : 'accessing' }
TtTrackedTime2 >> firstTimeScheduled: anObject [
	firstTimeScheduled := anObject
]

{ #category : 'accessing' }
TtTrackedTime2 >> generateCheckboxForBoolean: aSelector [
	^ BrCheckbox new
		aptitude: BrGlamorousCheckboxAptitude;
		checked: (self perform: aSelector);
		whenCheckedDo: [ :anEvent | 
			| entity |
			entity := anEvent target phlow firstParentWithViewContent phlow
					firstParentWithViewContent phlow entity.
			self perform: aSelector asMutator withArguments: #(true).
			self serialize.
			entity buildContext context navigationContext object viewFilterContext
				asLowercase = aSelector asLowercase
				ifTrue: [ entity definingMethodProvider definingMethod selector = #gtSummaryFor:context:
						ifTrue: [ anEvent target phlow firstParentWithViewContent phlow fireViewSyncUpdateWish ] ] ];
		whenUncheckedDo: [ :anEvent | 
			| entity |
			entity := anEvent target phlow firstParentWithViewContent phlow
					firstParentWithViewContent phlow entity.
			self perform: aSelector asMutator withArguments: #(false).
			self serialize.
			entity buildContext context navigationContext object viewFilterContext
				asLowercase = aSelector asLowercase
				ifTrue: [ entity definingMethodProvider definingMethod selector = #gtSummaryFor:context:
						ifTrue: [ anEvent target phlow firstParentWithViewContent phlow fireViewSyncUpdateWish ] ] ]
]

{ #category : 'action' }
TtTrackedTime2 >> gtDeleteActionFor: anAction [
	<gtAction>
	^ anAction button
		icon: BrGlamorousVectorIcons remove;
		tooltip: 'Delete the Tracked Time.';
		priority: 2;
		action: [ :aBrButton :aBrTab :aBrButtonModel :anEvent | 
			anEvent consumed: true.
			self delete ]
]

{ #category : 'action' }
TtTrackedTime2 >> gtGoToTrelloFor: anAction [
	<gtAction>
	self daySerializedFrom ifNil: [ ^ anAction noAction ].
	^ anAction button
		icon: BrGlamorousVectorIcons link;
		tooltip: 'Open day in browser.';
		priority: 1;
		action: [ :aBrButton :aBrTab :aBrButtonModel :anEvent | 
			anEvent consumed: true.
			WebBrowser openOn: 'https://trello.com/c/' , self daySerializedFrom ]
]

{ #category : 'views' }
TtTrackedTime2 >> gtPreviewFor: aView [
	<gtView>
	^ aView columnedList
		title: 'In Brief';
		items: [ self gtSummary ];
		column: 'Property'
			text: #key
			width: 120;
		column: 'Value'
			stencil: [ :each | 
				(#('Description' 'Details') includes: each key)
					ifTrue: [ | label |
						label := BrEditableLabel new.
						label
							aptitude: (BrGlamorousEditableLabelAptitude new
									glamorousCodeFont;
									defaultForeground: Color black;
									fontSize: 13);
							text: each value;
							when: BrEditorAcceptWish
								do: [ :aWish | 
									| newValue |
									newValue := aWish text asString.
									each key = 'Description'
										ifTrue: [ self description: newValue ]
										ifFalse: [ self details: newValue ].
									self serialize ] ]
					ifFalse: [ BrLabel new
							aptitude: BrGlamorousLabelAptitude;
							text: each value ] ];
		send: #value
]

{ #category : 'views' }
TtTrackedTime2 >> gtSummary [
	^ {'Start' -> start.
		'Duration' -> duration.
		'Description' -> description.
		'Details' -> details.
		'Category' -> category}
]

{ #category : 'accessing' }
TtTrackedTime2 >> isContiguous: aTrackedTime [
	^ aTrackedTime end rounded = self start
		or: [ super = aTrackedTime or: [ self end rounded = aTrackedTime start ] ]
]

{ #category : 'accessing' }
TtTrackedTime2 >> isPlanned [
	^ isPlanned
]

{ #category : 'accessing' }
TtTrackedTime2 >> isPlanned: anObject [
	isPlanned := anObject
]

{ #category : 'accessing' }
TtTrackedTime2 >> isRecurring [
	^ isRecurring
]

{ #category : 'accessing' }
TtTrackedTime2 >> isRecurring: anObject [
	isRecurring := anObject
]

{ #category : 'testing' }
TtTrackedTime2 >> isTimeEntry [
	^ true
]

{ #category : 'accessing' }
TtTrackedTime2 >> labels [
	^ labels
]

{ #category : 'accessing' }
TtTrackedTime2 >> labels: anObject [
	labels := anObject
]

{ #category : 'comparing' }
TtTrackedTime2 >> max: aValue [
	^ self duration asHours max: aValue
]

{ #category : 'printing' }
TtTrackedTime2 >> printOn: aStream [
	aStream
		nextPutAll: 'a TtTrackedTime (Starting at: ';
		nextPutAll: self start asTime printMinutes , ' for ' , self duration asHours asString
				, (' hour'
						in: [ :aString | self duration asHours = 1 ifTrue: [ aString ] ifFalse: [ aString , 's' ] ]);
		nextPut: $)
]

{ #category : 'accessing' }
TtTrackedTime2 >> printOnDetailed [
	^ String
		streamContents: [ :aStream | 
			aStream
				nextPutAll: self start asTime hhmm24;
				nextPut: $-;
				nextPutAll: (self end asTime
						in: [ :aTime | aTime asSeconds < 86399 ifTrue: [ aTime addSeconds: 1 ] ifFalse: [ (self end + 1 day) asDate asTime ] ])
						hhmm24;
				nextPut: Character space;
				nextPutAll: self description.
			self details
				ifNotNil: [ aStream
						nextPutAll: ': ';
						nextPutAll: (self details ifNil: [ '' ]) ] ]
]

{ #category : 'accessing' }
TtTrackedTime2 >> rawData [
	^ rawData
]

{ #category : 'accessing' }
TtTrackedTime2 >> rawData: anObject [
	rawData := anObject
]
