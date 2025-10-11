Class {
	#name : #TtTrackedTime,
	#superclass : #Timespan,
	#instVars : [
		'description',
		'details',
		'uid',
		'rawData',
		'daySerializedFrom',
		'category',
		'labels',
		'isPlanned',
		'isRecurring',
		'firstTimeScheduled',
		'collection'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtTrackedTime class >> dataPageName [
	^ 'Time Tracker Entries'
]

{ #category : #serialization }
TtTrackedTime class >> neoJsonMapping: aNeoJSONMapper [
	aNeoJSONMapper
		for: self
			do: [ :aMapping | 
				aMapping
					mapInstVars: #(description details firstTimeScheduled isPlanned isRecurring rawData daySerializedFrom).
				(aMapping mapInstVar: #start) valueSchema: DateAndTime.
				(aMapping mapInstVar: #duration) valueSchema: Duration.
				(aMapping mapInstVar: #category) valueSchema: #Category ];
		for: DateAndTime
			customDo: [ :mapping | 
				mapping decoder: [ :string | DateAndTime fromString: string ].
				mapping encoder: [ :dateAndTime | dateAndTime printString ] ];
		for: Duration
			customDo: [ :mapping | 
				mapping decoder: [ :aString | aString asDuration ].
				mapping encoder: [ :aDuration | aDuration asString ] ];
		for: #Category
			customDo: [ :categoryMapping | 
				categoryMapping
					reader: [ :jsonReader | 
						| categoryName aCollection |
						aCollection := thisContext stack
								detect: [ :each | each receiver class = TtEventCollection ]
								ifFound: [ :found | found receiver ]
								ifNone: [ TtEventCollection default ].
						categoryName := jsonReader next.
						aCollection categories
							detect: [ :each | each name = categoryName ]
							ifNone: [ categoryName ifNotNil: [ TtPlaceholderCategory fromName: categoryName ] ] ];
					writer: [ :jsonWriter :aCategory | aCategory name neoJsonOn: jsonWriter ] ]
]

{ #category : #serialization }
TtTrackedTime class >> snippetClass [
	^ TtTrackedTimeSnippet
]

{ #category : #comparing }
TtTrackedTime >> <= other [
	self flag: #DEPRECATE.	"This looks redundant with superclass chain definitions. Test and remove"
	^ self start <= other start
]

{ #category : #accessing }
TtTrackedTime >> asTimespan [
	^ self as: self value class superclass
]

{ #category : #accessing }
TtTrackedTime >> category [
	^ category
]

{ #category : #accessing }
TtTrackedTime >> category: anObject [
	category := anObject
]

{ #category : #accessing }
TtTrackedTime >> collection [
	^ collection
]

{ #category : #accessing }
TtTrackedTime >> collection: aTtEventCollection [
	collection := aTtEventCollection
]

{ #category : #accessing }
TtTrackedTime >> createCategoriesSnippetInPage: newPage [ 
]

{ #category : #accessing }
TtTrackedTime >> daySerializedFrom [
	^ daySerializedFrom
]

{ #category : #accessing }
TtTrackedTime >> daySerializedFrom: anObject [
	daySerializedFrom := anObject
]

{ #category : #deleting }
TtTrackedTime >> delete [
	self collection page
		ifNotNil: [ :aPage | 
			(aPage children detect: [ :aSnippet | aSnippet uidString = self uid ])
				removeSelf ].
	self rootCollection items remove: self
]

{ #category : #accessing }
TtTrackedTime >> description [
	^ description
]

{ #category : #accessing }
TtTrackedTime >> description: anObject [
	description := anObject
]

{ #category : #accessing }
TtTrackedTime >> details [
	^ details
]

{ #category : #accessing }
TtTrackedTime >> details: anObject [
	details := anObject
]

{ #category : #initialization }
TtTrackedTime >> falseAllBooleans [
	isPlanned := false.
	isRecurring := false.
	firstTimeScheduled := false
]

{ #category : #accessing }
TtTrackedTime >> firstTimeScheduled [
	^ firstTimeScheduled
]

{ #category : #accessing }
TtTrackedTime >> firstTimeScheduled: anObject [
	firstTimeScheduled := anObject
]

{ #category : #accessing }
TtTrackedTime >> generateCheckboxForBoolean: aSelector [
	^ BrCheckbox new
		aptitude: BrGlamorousCheckboxAptitude;
		checked: (self perform: aSelector);
		whenCheckedDo: [ :anEvent | 
			| entity |
			entity := anEvent target phlow firstParentWithViewContent phlow
					firstParentWithViewContent phlow entity.
			self perform: aSelector asMutator withArguments: #(true).
			self collection class serializeWithLepiter: self.
			entity buildContext context navigationContext object viewFilterContext
				asLowercase = aSelector asLowercase
				ifTrue: [ entity definingMethodProvider definingMethod selector = #gtSummaryFor:context:
						ifTrue: [ anEvent target phlow fireViewUpdateWish ] ] ];
		whenUncheckedDo: [ :anEvent | 
			| entity |
			entity := anEvent target phlow firstParentWithViewContent phlow
					firstParentWithViewContent phlow entity.
			self perform: aSelector asMutator withArguments: #(false).
			self collection class serializeWithLepiter: self.
			entity buildContext context navigationContext object viewFilterContext
				asLowercase = aSelector asLowercase
				ifTrue: [ entity definingMethodProvider definingMethod selector = #gtSummaryFor:context:
						ifTrue: [ anEvent target phlow fireViewUpdateWish ] ] ]
]

{ #category : #action }
TtTrackedTime >> gtDeleteActionFor: anAction [
	<gtAction>
	^ anAction button
		icon: BrGlamorousVectorIcons remove;
		tooltip: 'Delete the Tracked Time.';
		priority: 2;
		action: [ :aBrButton :aBrTab :aBrButtonModel :anEvent | 
			anEvent consumed: true.
			self delete ]
]

{ #category : #action }
TtTrackedTime >> gtGoToTrelloFor: anAction [
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

{ #category : #views }
TtTrackedTime >> gtPreviewFor: aView [
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
									self collection rootCollection
										ifNotNil: [ :notNil | notNil class serializeWithLepiter: self ] ] ]
					ifFalse: [ BrLabel new
							aptitude: BrGlamorousLabelAptitude;
							text: each value ] ];
		send: #value
]

{ #category : #views }
TtTrackedTime >> gtSummary [
	^ {'Start' -> start.
		'Duration' -> duration.
		'Description' -> description.
		'Details' -> details.
		'Category' -> category}
]

{ #category : #accessing }
TtTrackedTime >> isContiguous: aTrackedTime [
	^ aTrackedTime end rounded = self start
		or: [ super = aTrackedTime or: [ self end rounded = aTrackedTime start ] ]
]

{ #category : #accessing }
TtTrackedTime >> isPlanned [
	^ isPlanned
]

{ #category : #accessing }
TtTrackedTime >> isPlanned: anObject [
	isPlanned := anObject
]

{ #category : #accessing }
TtTrackedTime >> isRecurring [
	^ isRecurring
]

{ #category : #accessing }
TtTrackedTime >> isRecurring: anObject [
	isRecurring := anObject
]

{ #category : #testing }
TtTrackedTime >> isTimeEntry [
	^ true
]

{ #category : #accessing }
TtTrackedTime >> labels [
	^ labels
]

{ #category : #accessing }
TtTrackedTime >> labels: anObject [
	labels := anObject
]

{ #category : #printing }
TtTrackedTime >> printOn: aStream [
	aStream
		nextPutAll: 'a TtTrackedTime (Starting at: ';
		nextPutAll: self start asTime printMinutes , ' for ' , self duration asHours asString
				, (' hour'
						in: [ :aString | self duration asHours = 1 ifTrue: [ aString ] ifFalse: [ aString , 's' ] ]);
		nextPut: $)
]

{ #category : #accessing }
TtTrackedTime >> printOnDetailed [
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

{ #category : #accessing }
TtTrackedTime >> rawData [
	^ rawData
]

{ #category : #accessing }
TtTrackedTime >> rawData: anObject [
	rawData := anObject
]

{ #category : #accessing }
TtTrackedTime >> rootCollection [
	^ self collection rootCollection
]

{ #category : #accessing }
TtTrackedTime >> serializeSnippet: aTextSnippet [
	^ NeoJSONObject
		fromString: (String
				streamContents: [ :s | 
					LeJsonV4 uniqueInstance
						serialize: aTextSnippet
						on: s
						prettyPrint: true ])
]

{ #category : #accessing }
TtTrackedTime >> uid [
	^ uid
]

{ #category : #accessing }
TtTrackedTime >> uid: anObject [
	uid := anObject
]
