Class {
	#name : #TtEventCollection,
	#superclass : #Object,
	#traits : 'TGtGroupWithItems + TGtUniqueInstance',
	#classTraits : 'TGtGroupWithItems classTrait + TGtUniqueInstance classTrait',
	#instVars : [
		'groupedByDay',
		'collection',
		'categories',
		'page'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtEventCollection class >> dailyTimePlot: somePomodoros [
	^ GtPlotterHorizontalValueProjectionsElement new
		padding: (BlInsets
				top: 1
				left: 10
				bottom: 1
				right: 10);
		margin: (BlInsets all: 4);
		aptitude: BrShadowAptitude;
		background: Color white;
		scale: (GtPlotterLinearScale new
				domainFrom: 0
				to: (24 * 60));
		scaleData: [ :each | (each start asDuration asMinutes + (each duration asMinutes / 2)) rounded ];
		constraintsDo: [ :c | c vertical fitContent ];
		valueElement: [ :aGtPlotterSingleScaleContext | BlElement new ];
		valueStyle: [ :anElement :aGtPlotterSingleScaleContext | 
			anElement
				border: (BlBorder paint: Color black width: 1);
				background: Color lightGray;
				constraintsDo: [ :c | 
					c horizontal matchParent.
					c frame horizontal
						weight: aGtPlotterSingleScaleContext originalValue duration asMinutes rounded / (24 * 60) ];
				when: BlClickEvent
					do: [ :anEvent | anEvent target phlow spawnObject: aGtPlotterSingleScaleContext originalValue ] ];
		values: somePomodoros;
		when: BlDoubleClickEvent
			do: [ :anEvent | anEvent target phlow spawnObject: somePomodoros ]
]

{ #category : #accessing }
TtEventCollection class >> defaultPageName [
	^ 'Time Tracker Entries'
]

{ #category : #views }
TtEventCollection class >> gtTrackedTimeFor: aView [
	<gtClassView>
	^ aView forward
		title: 'Entries By Day';
		priority: 5;
		object: self loadFromLepiter;
		view: #gtTrackedTimeFor:
]

{ #category : #views }
TtEventCollection class >> gtWeeklySummaryFor: aView [
	<gtView>
	<gtClassView>
	^ aView forward
		title: 'Pomodoros By Week';
		priority: 6;
		object: self new;
		view: #gtWeeklySummaryFor:
]

{ #category : #accessing }
TtEventCollection class >> hourlyTicksElement [
	| aContainer ticksObject theTicks aLength |
	ticksObject := GtPlotterNumberTicks
			from: 0
			to: 24
			count: 24.
	theTicks := ticksObject asArray.
	aLength := (theTicks first - theTicks last) abs.
	aLength isZero ifTrue: [ aLength := 1 ].

	aContainer := BlElement new
			layout: BlFrameLayout new;
			padding: (BlInsets all: 10);
			constraintsDo: [ :c | 
				c horizontal matchParent.
				c vertical matchParent ];
			addChild: (BlElement new
					background: Color gray;
					constraintsDo: [ :c | 
						c horizontal matchParent.
						c vertical exact: 1 ]);
			addChildren: ({theTicks first.
					theTicks last}
					collect: [ :eachTick | 
						BlElement new
							background: Color gray;
							constraintsDo: [ :c | 
								c frame horizontal alignCenterAt: (eachTick - theTicks first) / aLength.
								c horizontal exact: 1.
								c vertical exact: 10 ] ]);
			addChildren: (theTicks
					collect: [ :eachTick | 
						BlElement new
							background: Color gray;
							constraintsDo: [ :c | 
								c frame horizontal alignCenterAt: (eachTick - theTicks first) / aLength.
								c horizontal exact: 1.
								c vertical exact: 10 ] ]);
			addChildren: (theTicks
					collect: [ :eachTick | 
						BlTextElement new
							text: (eachTick printString asRopedText thin fontSize: 9);
							margin: (BlInsets top: 13);
							constraintsDo: [ :c | c frame horizontal alignCenterAt: (eachTick - theTicks first) / aLength ] ]).
	^ aContainer
]

{ #category : #initialization }
TtEventCollection class >> loadFromLepiter [
	^ self default loadFromLepiter
]

{ #category : #'instance creation' }
TtEventCollection class >> newFrom: aCollection [
	^ self withAll: aCollection
]

{ #category : #import }
TtEventCollection class >> serializeCollection [
	^ self new serializeCollection
]

{ #category : #serialization }
TtEventCollection class >> serializeSnippet: aTextSnippet [
	^ NeoJSONObject
		fromString: (String
				streamContents: [ :s | 
					LeJsonV4 uniqueInstance
						serialize: aTextSnippet
						on: s
						prettyPrint: true ])
]

{ #category : #serialization }
TtEventCollection class >> serializeWithLepiter: anEntity [
	| anUnknownSnippet aTextSnippet lepiterPage serialized snippetJSON |
	lepiterPage := anEntity collection page.
	lepiterPage children
		detect: [ :aSnippet | aSnippet uidString = anEntity uid ]
		ifFound: [ :foundSnippet | 
			snippetJSON := self serializeSnippet: foundSnippet.
			snippetJSON data: anEntity.
			serialized := NeoJSONWriter toStringPretty: snippetJSON.
			foundSnippet jsonString: serialized source: lepiterPage ]
		ifNone: [ aTextSnippet := LeTextSnippet string: ''.
			lepiterPage addSnippet: aTextSnippet.
			snippetJSON := self serializeSnippet: aTextSnippet.
			snippetJSON __type: anEntity class snippetClass leJsonV4Name.
			snippetJSON data: anEntity.
			serialized := NeoJSONWriter toStringPretty: snippetJSON.
			anUnknownSnippet := anEntity class snippetClass new
					jsonString: serialized
					source: lepiterPage.
			aTextSnippet removeSelf.
			lepiterPage addSnippet: anUnknownSnippet.
			anEntity uid: anUnknownSnippet uidString ]
]

{ #category : #'instance - creation' }
TtEventCollection class >> withAll: aCollection [
	self flag: 'Explore why items is an OrderedCollection and how we can turn it into a SortedCollection'.
	^ self new 
		initializeWith: aCollection
]

{ #category : #accessing }
TtEventCollection >> add: anItem [
	self collection add: anItem
]

{ #category : #accessing }
TtEventCollection >> addAll: aCollection [
	self collection addAll: aCollection
]

{ #category : #'building ui' }
TtEventCollection >> buildDonut: data [
	^ BlElement new
		size: 400 @ 400;
		addChildren: (data
				collect: [ :each | 
					BlElement new
						when: BlClickEvent do: [ :e | e target phlow spawnObject: each last ];
						geometry: (BlAnnulusSector new
								startAngle: each third first;
								endAngle: each third last;
								innerRadius: 0.85);
						border: (BlBorder paint: Color lightGray width: 1);
						background: each fourth;
						constraintsDo: [ :c | 
							c horizontal matchParent.
							c vertical matchParent ] ])
]

{ #category : #'building ui' }
TtEventCollection >> calculateAnglesForDonut [
	| sortedCategories totalTime |
	sortedCategories := self sortedEntries.
	totalTime := sortedCategories sum: [ :each | each second ].
	sortedCategories
		inject: -90
		into: [ :sum :each | 
			| color temp |
			temp := (each second / totalTime * 360 + sum) asInteger.
			each
				add: {sum.
						temp}
				afterIndex: 2.
			color := TtCategories stringToColorHash: each first.
			each first = 'Uncategorized' ifTrue: [ color := color alpha: 0.1 ].
			each add: color afterIndex: 3.
			temp ].	"Completing the circle, fixing any rounding differences by hard coding smallest entry's stop angle. Distorts it a bit but okay compromise for now"
	sortedCategories last
		at: 3
		put: {sortedCategories last third first.
				270}.
	^ sortedCategories
]

{ #category : #accessing }
TtEventCollection >> categories [
	^ categories
]

{ #category : #accessing }
TtEventCollection >> categories: aTtCategories [
	categories := aTtCategories
]

{ #category : #accessing }
TtEventCollection >> collection [
	^ collection
		ifNil: [ collection := SortedCollection
					sortUsing: [ :aPomodoro | aPomodoro start ] ascending ]
]

{ #category : #accessing }
TtEventCollection >> defaultPage [
	^ LeDatabasesRegistry defaultLogicalDatabase
		pageNamed: self class defaultPageName
		ifAbsent: [ | newPage |
			newPage := LePage named: self class defaultPageName.
			LeDatabasesRegistry defaultLogicalDatabase addPage: newPage.
			newPage addFirstSnippet: (LeTextSnippet string: '').
			newPage ]
]

{ #category : #views }
TtEventCollection >> groupedByDay [
	self flag: #TODO "Maybe remover caching? Might be premature optimization, if not, need to make sure to update cache.".
	^ "groupedByDay
		ifNil: [ groupedByDay :=" self groupedBy: [ :each | each start asDate ] "]"
]

{ #category : #accessing }
TtEventCollection >> gtDonutFor: aView [
	<gtView>
	^ aView explicit
		title: 'Categories' translated;
		priority: 1;
		stencil: [ | data horizontalPane verticalPane |
			data := self calculateAnglesForDonut.
			horizontalPane := BrHorizontalPane new
					hMatchParent;
					alignCenter;
					vFitContent.
			horizontalPane addChildren: {self buildDonut: data}.	"(self buildBars: data) "
			verticalPane := BrVerticalPane new
					hMatchParent;
					alignCenter;
					vMatchParent.
			verticalPane addChildren: {horizontalPane}.
			verticalPane ]
]

{ #category : #views }
TtEventCollection >> gtTrackedTimeFor: aView [
	<gtView>
	| pomodoros |
	pomodoros := self groupedByDay associations sorted: #key descending.
	^ aView columnedTree
		title: 'Entries By Day';
		priority: 5;
		items: pomodoros;
		children: [ :each | each isAssociation ifTrue: [ each value ] ifFalse: [ #() ] ];
		actionUpdateButton;
		column: 'Tracked Time'
			text: [ :each | 
				each isAssociation
					ifTrue: [ each key asString ]
					ifFalse: [ each printOnDetailed ] ];
		column: 'Is Recurring'
			stencil: [ :each | 
				each isAssociation
					ifTrue: [ BlElement new ]
					ifFalse: [ each generateCheckboxForBoolean: #isRecurring ] ];
		column: 'Is Planned'
			stencil: [ :each | 
				each isAssociation
					ifTrue: [ BlElement new ]
					ifFalse: [ each generateCheckboxForBoolean: #isPlanned ] ];
		column: 'First Time Scheduled'
			stencil: [ :each | 
				each isAssociation
					ifTrue: [ BlElement new ]
					ifFalse: [ each generateCheckboxForBoolean: #firstTimeScheduled ] ];
		column: 'Category'
			stencil: [ :each | 
				each isAssociation
					ifTrue: [ BlElement new ]
					ifFalse: [ | aButton |
						aButton := BrButton new.
						aButton
							aptitude: BrGlamorousButtonWithIconAndLabelAptitude
									+ (BrGlamorousWithDropdownAptitude
											handle: [ BrButton new
													aptitude: BrGlamorousButtonWithIconAndLabelAptitude;
													label: ('Categorize' asRopedText fontSize: 12);
													icon: (BlElement new
															size: 15 @ 15;
															geometry: BlCircleGeometry new;
															background: Color transparent) ]
											content: [ BrHorizontalPane new
													size: 800 @ 800;
													padding: (BlInsets all: 15);
													addChild: (self categories
															TtCategoriesFor: GtPhlowView empty
															context: (GtPhlowContext new
																	at: #TtTrackedTime put: each -> aButton;
																	yourself)) asElement ]).
						each category
							ifNotNil: [ :notNil | 
								aButton
									label: notNil name;
									icon: (BlElement new
											size: 15 @ 15;
											geometry: BlCircleGeometry new;
											background: (TtCategories stringToColorHash: notNil name)) ]
							ifNil: [ aButton
									label: ('Categorize' asRopedText fontSize: 12);
									icon: (BlElement new
											size: 15 @ 15;
											geometry: BlCircleGeometry new;
											background: Color transparent) ] ] ];
		send: [ :each | each isAssociation ifTrue: [ each value ] ifFalse: [ each ] ];
		expandAll
]

{ #category : #accessing }
TtEventCollection >> gtWeeklySummaryFor: aView [
	<gtView>
	| days weeks |
	days := self groupedByDay associations.
	weeks := (days collectAsSet: [ :each | each key asWeek ]) asArray sorted.
	^ aView columnedList
		title: 'Weekly Summary';
		priority: 0;
		items: [ ((days select: [ :aDay | aDay key asWeek = weeks last ])
				sorted: [ :each | Week indexOfDay: each key dayOfWeekName ] ascending)
				, {nil -> nil} ];
		column: 'Day'
			stencil: [ :each | 
				each key
					ifNil: [ BlElement new ]
					ifNotNil: [ BrButton new
							aptitude: BrGlamorousButtonWithLabelAptitude;
							label: each key weekday;
							action: [ :anElement | anElement phlow spawnObject: each value ] ] ]
			weight: 0.1;
		column: 'Tracked Time'
			stencil: [ :each | 
				each key
					ifNil: [ self class hourlyTicksElement ]
					ifNotNil: [ self class dailyTimePlot: each value ] ]
			weight: 0.9;
		send: [  ];
		actionDropdownButtonIcon: [ BrGlamorousVectorIcons calendar asElement asScalableElement size: 20 @ 20 ]
					asStencil
			content: [ :aButton :aBrTab | 
				| element |
				element := GtCalendarElement forDate: Date today.
				element
					when: GtCalendarDateClickedEvent
					do: [ :anEvent | 
						anEvent consumed: true.
						aButton fireEvent: BrDropdownHideWish new.
						aButton phlow
							spawnObject: (self
									select: [ :aPomodoro | aPomodoro start asDate asWeek = anEvent date asWeek ]) ] ]
]

{ #category : #import }
TtEventCollection >> importFromTrello [
	| response |
	self flag: #TODO.	"This should eventually call a properly configured class that implements a trait that knows how to import data"
	[ response := TtTrelloImporter fetch ] on: NameLookupFailure do: [ ^ self ].
	self
		serializeCollection;
		loadPage;
		loadCategories.
	self flag: #TODO.	"Add logic to take difference from days from Trello and ones in Lepiter and only import those"
	response associations first in:
		"associationsDo:" [ :day | TtTrelloParser new add: day toCollection: self ]
]

{ #category : #accessing }
TtEventCollection >> items [
	^ items ifNil: [ items := self collection value ]
]

{ #category : #accessing }
TtEventCollection >> loadCategories [
	self page children
		detect: [ :aSnippet | aSnippet isKindOf: TtCategoriesSnippet ]
		ifFound: [ :aCategorySnippet | 
			| someCategories |
			someCategories := TtCategories
					fromRoot: (NeoJSONReader
							fromString: aCategorySnippet jsonString
							as: CategorySnippetDeserializer) data.
			someCategories root
				collection: self;
				uid: aCategorySnippet uidString.
			self categories: someCategories ]
		ifNone: [ self
				categories: (TtCategories new
						in: [ :someCategories | 
							someCategories root collection: self.
							someCategories ]).
			self class serializeWithLepiter: self categories root ]
]

{ #category : #initialization }
TtEventCollection >> loadFromLepiter [
	self size = 0
		ifTrue: [ self loadPage.
			self loadCategories.
			self page children asArray
				select: [ :each | each isKindOf: TtTrackedTimeSnippet ]
				thenDo: [ :each | 
					self items
						add: ((NeoJSONReader fromString: each jsonString as: TrackedTimeSnippetDeserializer)
								data
								in: [ :aTrackedTime | 
									aTrackedTime
										uid: each uidString;
										collection: self;
										yourself ]) ] ]
]

{ #category : #accessing }
TtEventCollection >> loadPage [
	page
		ifNil: [ [ page := self perform: #customPage ]
				on: MessageNotUnderstood
				do: [ page := self defaultPage ] ]
]

{ #category : #accessing }
TtEventCollection >> page [
	^ page
]

{ #category : #accessing }
TtEventCollection >> page: aLepiterPage [
	page := aLepiterPage
]

{ #category : #printing }
TtEventCollection >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPut: $(;
		nextPutAll: (self groupedByDay keys
				in: [ :someDates | someDates min asString , ' - ' , someDates max asString ]);
		nextPutAll: ' [';
		nextPutAll: self size asString , ' items';
		nextPutAll: '])'
]

{ #category : #accessing }
TtEventCollection >> recalculateGroupedByDay [
	groupedByDay := nil.
	^ self groupedByDay
]

{ #category : #import }
TtEventCollection >> serializeCollection [
	collection := self collection asValueHolder.
	collection
		whenAddedDo: [ :newValue | self class serializeWithLepiter: newValue ]
]

{ #category : #'building ui' }
TtEventCollection >> sortedEntries [
	| categorizedActivities sumOfCategories |
	categorizedActivities := (self items
			collect: [ :entry | entry category -> entry ]) 
			groupedBy: [ :each | each key ifNil: [ 'Uncategorized' ] ifNotNil: [ :key | key name ] ]
			affect: [ :each | "TtEventCollection withAll:" (each collect: #value) ].
	sumOfCategories := categorizedActivities
			collect: [ :each | 
				{each sum: [ :entry | entry value duration ].
					TtEventCollection withAll:each} ].
	^ (sumOfCategories associations
		sorted: [ :a :b | a value first > b value first ])
		collect: [ :each | OrderedCollection withAll: {each key} , each value ]
]

{ #category : #accessing }
TtEventCollection >> valueHolder: anObject [
	collection := anObject
]
