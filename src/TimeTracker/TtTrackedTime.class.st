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
		'links',
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
							ifNone: [ nil ] ];
					writer: [ :jsonWriter :aCategory | aCategory name neoJsonOn: jsonWriter ] ]
]

{ #category : #serialization }
TtTrackedTime class >> snippetClass [
	^ TtTrackedTimeSnippet
]

{ #category : #comparing }
TtTrackedTime >> <= other [
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
	self collection page ifNotNil: [:aPage| (aPage children detect: [:aSnippet | aSnippet uidString = self uid ]) removeSelf ].
	self collection items remove: self. 
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
			self perform: aSelector asMutator withArguments: #(true).
			self collection class serializeWithLepiter: self ];
		whenUncheckedDo: [ :anEvent | 
			self perform: aSelector asMutator withArguments: #(false).
			self collection class serializeWithLepiter: self ]
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
	^ anAction button
		icon: BrGlamorousVectorIcons link;
		tooltip: 'Open day in browser.';
		priority: 1;
		action: [ :aBrButton :aBrTab :aBrButtonModel :anEvent | 
			anEvent consumed: true.
			WebBrowser openOn: 'https://trello.com/c/' , self daySerializedFrom ]
]

{ #category : #accessing }
TtTrackedTime >> gtTrackedTimeFor: aView [
	<gtView>
	^ aView explicit
		title: 'Summary';
		priority: 1;
		stencil: self displayTrackedTime
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

{ #category : #accessing }
TtTrackedTime >> labels [
	^ labels
]

{ #category : #accessing }
TtTrackedTime >> labels: anObject [
	labels := anObject
]

{ #category : #accessing }
TtTrackedTime >> links [
	^ links
]

{ #category : #accessing }
TtTrackedTime >> links: anObject [
	links := anObject
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
				nextPutAll: (self end asTime addSeconds: 1) hhmm24;
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
TtTrackedTime >> serializeWithLepiter [
	| lepiterPage aTextSnippet snippetJSON serialized anUnknownSnippet |
	lepiterPage := LeDatabasesRegistry defaultLogicalDatabase
			pageNamed: self class dataPageName
			ifAbsent: [ | newPage |
				newPage := LePage named: self class dataPageName.
				LeDatabasesRegistry defaultLogicalDatabase addPage: newPage.
				newPage addFirstSnippet: (LeTextSnippet string: '').
				self createCategoriesSnippetInPage: newPage.
				newPage ].
	lepiterPage children
		detect: [ :aSnippet | aSnippet uidString = self uid ]
		ifFound: [ :foundSnippet | 
			snippetJSON := self serializeSnippet: foundSnippet.
			snippetJSON data: self.
			serialized := NeoJSONWriter toStringPretty: snippetJSON.
			foundSnippet jsonString: serialized source: lepiterPage ]
		ifNone: [ aTextSnippet := LeTextSnippet string: ''.
			lepiterPage addSnippet: aTextSnippet.
			snippetJSON := self serializeSnippet: aTextSnippet.
			snippetJSON __type: TtTrackedTimeSnippet leJsonV4Name.
			snippetJSON data: self.
			serialized := NeoJSONWriter toStringPretty: snippetJSON.
			anUnknownSnippet := TtTrackedTimeSnippet new
					jsonString: serialized
					source: lepiterPage.
			aTextSnippet removeSelf.
			lepiterPage addSnippet: anUnknownSnippet.
			self uid: anUnknownSnippet uidString ]
]

{ #category : #accessing }
TtTrackedTime >> uid [
	^ uid
]

{ #category : #accessing }
TtTrackedTime >> uid: anObject [
	uid := anObject
]
