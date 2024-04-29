Class {
	#name : #TtEventCollection,
	#superclass : #Object,
	#traits : 'TGtGroupWithItems + TGtUniqueInstance',
	#classTraits : 'TGtGroupWithItems classTrait + TGtUniqueInstance classTrait',
	#instVars : [
		'groupedByDay',
		'categories',
		'page'
	],
	#classInstVars : [
		'uniqueInstance'
	],
	#category : #TimeTracker
}

{ #category : #views }
TtEventCollection class >> dailyTimePlot: aTTEventCollection [
	^ GtPlotterHorizontalValueProjectionsElement new
		padding: (BlInsets
				top: 1
				left: 10
				bottom: 1
				right: 10);
		margin: (BlInsets all: 4);
		aptitude: BrShadowAptitude;
		background: Color white;
		scale: (GtPlotterLinearScale new domainFrom: 0 to: 24 * 60);
		scaleData: [ :each | 
			(each key start asDuration asMinutes + (each key duration asMinutes / 2))
				rounded ];
		constraintsDo: [ :c | c vertical fitContent ];
		valueElement: [ :aGtPlotterSingleScaleContext | BlElement new ];
		valueStyle: [ :anElement :aGtPlotterSingleScaleContext | 
			anElement
				constraintsDo: [ :c | 
					c horizontal matchParent.
					c frame horizontal
						weight: aGtPlotterSingleScaleContext originalValue key duration asMinutes rounded
								/ (24 * 60) ].
			anElement
				addChild: (BrVerticalPane new
						matchParent;
						in: [ :aBrVerticalPane | 
							aGtPlotterSingleScaleContext originalValue value
								do: [ :aTtTrackedTime | 
									| element |
									element := BlElement new
											constraintsDo: [ :c | 
												c vertical matchParent.
												c horizontal matchParent ];
											border: (BlBorder paint: Color darkGray width: 0.5);
											background: (aTtTrackedTime category
													ifNotNil: [ :notNil | TtCategories stringToColorHash: notNil name ]
													ifNil: [ Color veryVeryLightGray ]).
									aBrVerticalPane addChild: element ].
							aBrVerticalPane ]);
				when: BlClickEvent
					do: [ :anEvent |
						anEvent consumed: true. 
						anEvent target phlow
							spawnObject: aGtPlotterSingleScaleContext originalValue value ] ];
		values: aTTEventCollection groupedByTimespan associations;
		when: BlDoubleClickEvent
			do: [ :anEvent | anEvent target phlow spawnObject: aTTEventCollection ]
]

{ #category : #accessing }
TtEventCollection class >> defaultPageName [
	^ 'Time Tracker Entries'
]

{ #category : #inspecting }
TtEventCollection class >> gtInspectActionFor: anAction [
	<gtAction>
	<gtClassAction>
	^ anAction button
		icon: BrGlamorousVectorIcons inspect;
		label: 'ALL TIME';
		tooltip: 'Default Tracked Time Collection';
		priority: 1;
		action: [ :aButton | aButton phlow spawnObject: self default ]
]

{ #category : #views }
TtEventCollection class >> gtSummaryFor: aView [
	<gtClassView>
	^ aView forward
		title: 'Summary';
		priority: 10;
		object: self loadFromLepiter;
		view: #gtSummaryFor:
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

{ #category : #accessing }
TtEventCollection >> asAsyncStream [
	^ self items asAsyncStream
]

{ #category : #accessing }
TtEventCollection >> buildBars: data [
	| aBarWidthScale barChart container maxLines theData totalTime |
	theData := GtPlotterDataGroup new values: data.
	totalTime := (data sum: #sum) asHours.
	theData := theData
			labelled: [ :each | 
				(each category = 'Uncategorized'
					ifTrue: [ each category ]
					ifFalse: [ each category name ]) , ' ('
					, (each sum asHours / totalTime * 100 round: 1) asString , '%)' ].
	theData := theData
			colored: [ :each | 
				each category = 'Uncategorized'
					ifTrue: [ Color transparent ]
					ifFalse: [ TtCategories stringToColorHash: each category name ] ].

	maxLines := theData
			inject: 0
			intoValues: [ :anAmount :eachValue | anAmount max: eachValue sum asHours / totalTime ].
	aBarWidthScale := GtPlotterLinearScale new domainFrom: 0 to: maxLines.

	barChart := GtPlotterHorizontalBarChart new.
	barChart
		barElement: [ :aGtPlotterContext | 
			| categoryName |
			categoryName := [ aGtPlotterContext originalValue category name ]
					on: MessageNotUnderstood
					do: [ 'Uncategorized' ].
			BlElement new
				id: categoryName;
				border: (BlBorder paint: Color lightGray width: 1);
				when: BlClickEvent
					do: [ :anEvent | 
						anEvent consumed: true.
						anEvent currentTarget phlow
							spawnObject: aGtPlotterContext originalValue collection ];
				when: BlDoubleClickEvent
					do: [ :anEvent | 
						anEvent consumed: true.
						anEvent currentTarget phlow spawnObject: aGtPlotterContext originalValue ];
				when: BlMouseEnterEvent
					do: [ :anEvent | 
						anEvent consumed: true.
						(BlBorder paint: Color black width: 2)
							in: [ :aColor | 
								anEvent currentTarget border: aColor.
								container
									previousSiblingDo: [ :aDonut | aDonut childNamed: categoryName ifFound: [ :found | found border: aColor ] ] ] ];
				when: BlMouseLeaveEvent
					do: [ :anEvent | 
						anEvent consumed: true.
						(BlBorder paint: Color lightGray width: 1)
							in: [ :aColor | 
								anEvent currentTarget border: aColor.
								container
									previousSiblingDo: [ :aDonut | aDonut childNamed: categoryName ifFound: [ :found | found border: aColor ] ] ] ] ];
		barLabelWidth: 160;
		barWidthScale: aBarWidthScale;
		barWidthData: [ :eachValue | eachValue sum asHours / totalTime ];
		tickLabelFormat: [ :eachFloat | (eachFloat * 100 round: 1) asString , '%' ];
		amountOfTicks: 4;
		with: theData.

	container := barChart asElement.
	^ container
]

{ #category : #'building ui' }
TtEventCollection >> buildDonut: data [
	| element |
	element := BlElement new.
	^ element
		size: 400 @ 400;
		addChildren: (data
				collect: [ :each | 
					| categoryName color |
					categoryName := [ each category name ]
							on: MessageNotUnderstood
							do: [ 'Uncategorized' ].
					color := each category = 'Uncategorized'
							ifTrue: [ Color transparent ]
							ifFalse: [ TtCategories stringToColorHash: each category name ].
					BlElement new
						id: categoryName;
						when: BlClickEvent
							do: [ :e | 
								e consumed: true.
								e target phlow spawnObject: each collection ];
						when: BlDoubleClickEvent
							do: [ :e | 
								e consumed: true.
								e target phlow spawnObject: each ];
						when: BlMouseEnterEvent
							do: [ :anEvent | 
								anEvent consumed: true.
								(BlBorder paint: Color black width: 2)
									in: [ :aColor | 
										anEvent currentTarget border: aColor.
										element
											nextSiblingDo: [ :aDonut | aDonut childNamed: categoryName ifFound: [ :found | found border: aColor ] ] ] ];
						when: BlMouseLeaveEvent
							do: [ :anEvent | 
								anEvent consumed: true.
								(BlBorder paint: Color lightGray width: 1)
									in: [ :aColor | 
										anEvent currentTarget border: aColor.
										element
											nextSiblingDo: [ :aDonut | aDonut childNamed: categoryName ifFound: [ :found | found border: aColor ] ] ] ];
						geometry: (BlAnnulusSector new
								startAngle: each startAngle;
								endAngle: each endAngle;
								innerRadius: 0.85);
						border: (BlBorder paint: Color lightGray width: 1);
						background: color;
						constraintsDo: [ :c | 
							c horizontal matchParent.
							c vertical matchParent ] ])
]

{ #category : #'building ui' }
TtEventCollection >> calculateAnglesForDonut [
	| sortedCategories totalTime |
	sortedCategories := self categoriesSortedByDuration.
	totalTime := sortedCategories sum: #sum.
	sortedCategories
		inject: -90
		into: [ :sum :each | 
			| endAngle |
			endAngle := (each sum / totalTime * 360 + sum) asInteger.
			each
				startAngle: sum;
				endAngle: endAngle.
			endAngle ].
	self
		flag: 'Completing the circle, fixing any rounding differences by hard coding smallest entry''s stop angle. Distorts it a bit but okay compromise for now'.
	sortedCategories last endAngle: 270.
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

{ #category : #'building ui' }
TtEventCollection >> categoriesSortedByDuration [
	| categorizedActivities sumOfCategories |
	categorizedActivities := self
			groupedBy: [ :each | each category ifNil: [ 'Uncategorized' ] ].
	sumOfCategories := categorizedActivities associations
			collect: [ :anAssociation | 
				TtCategorizedEventsHelper new
					category: anAssociation key;
					collection: anAssociation value;
					sum: (anAssociation value collect: #duration) sum ].
	^ sumOfCategories sorted: #sum descending
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

{ #category : #accessing }
TtEventCollection >> groupedBy: aBlock [
	"Override this method here and not reuse the one in collection
	because we want the keys to be groups, not simple collections"

	| result |
	result := Dictionary new.
	self
		do: [ :each | 
			| key collection |
			key := aBlock value: each.
			collection := result at: key ifAbsentPut: [ SortedCollection new ].
			collection add: each ].

	result
		keysAndValuesDo: [ :key :value | 
			result
				at: key
				put: ((self species withAll: value)
						page: self page;
						categories: self categories) ].

	^ result
]

{ #category : #views }
TtEventCollection >> groupedByDay [
	^ self groupedBy: [ :each | each start asDate ]
]

{ #category : #'accessing - grouping' }
TtEventCollection >> groupedByTimespan [
	^ self groupedBy: [ :each | each as: each class superclass ]
]

{ #category : #views }
TtEventCollection >> gtDailySummaryFor: aView [
	| days  |
	days := self groupedByDay associations sorted: #key ascending.
	^ aView columnedList
		title: 'Weekly Summary';
		priority: 6;
		items: [ days
				, {nil -> nil} ];
		column: 'Day'
			stencil: [ :each | 
				each key
					ifNil: [ BlElement new ]
					ifNotNil: [ BrButton new
							aptitude: BrGlamorousButtonWithLabelAptitude;
							label: (each key yyyymmdd , '-' , (each key weekday first: 3));
							action: [ :anElement | anElement phlow spawnObject: each value ] ] ]
			weight: 0.1;
		column: 'Tracked Time'
			stencil: [ :each | 
				each key
					ifNil: [ self class hourlyTicksElement ]
					ifNotNil: [ self class dailyTimePlot: each value ] ]
			weight: 0.9;
		send: [  ]
]

{ #category : #search }
TtEventCollection >> gtSearchFor: aSearch [
	<gtSearch>
	^ aSearch list
		priority: 1;
		title: 'Search by Tracked Time entries';
		items: [ self ];
		itemName: [ :each | 
			each start asDate yyyymmdd , ' | ' , each description
				, (each details ifNotNil: [ :notNil | ': ' , notNil ] ifNil: [ '' ]) ];
		send: [ :aRawObject :aStep :thisSearch | 
			TtEventCollection new
				categories: self categories;
				page: self page;
				add: aRawObject;
				yourself ];
		sendCategory: [ :aCategory :aStep :thisSearch | 
			| context |
			context := {aCategory.
					aStep.
					thisSearch}.
			(TtEventCollection withAll: aCategory items contents)
				categories: self categories;
				page: self page ];
		previewElement: [ :aTrackedTime | (aTrackedTime gtPreviewFor: GtPhlowEmptyView new) asElement ];
		filterBySubstring;
		wantsToDisplayOnEmptyQuery: true
]

{ #category : #views }
TtEventCollection >> gtSummaryFor: aView [
	<gtView>
	self flag: #TODO "Changes in categorizing should re-render graphs in realtime".
	self flag: #TODO "Add un-tracked time to charts".
	^ aView explicit
		title: 'Summary' translated;
		priority: 0;
		flag: #TODO "change to dropdown for different in place filters";
		actionUpdateButton;
		stencil: [ | data horizontalPane verticalPane |
			data := self calculateAnglesForDonut.
			horizontalPane := BrHorizontalPane new
					matchParent;
					alignCenter.
			horizontalPane
				addChildren: {self buildDonut: data.
						self buildBars: data}.
			verticalPane := BrVerticalPane new
					matchParent;
					alignCenter;
					addChildren: {horizontalPane.
							(self gtDailySummaryFor: GtPhlowView empty) asElement.
							(self gtTrackedTimeByDayFor: GtPhlowView empty) asElement}.
			verticalPane ]
]

{ #category : #views }
TtEventCollection >> gtTrackedTimeByDayFor: aView [
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
					ifTrue: [ each key yyyymmdd , '-' , (each key weekday first: 3) ]
					ifFalse: [ each printOnDetailed ] ];
		column: 'Is Recurring'
			stencil: [ :each | 
				each isAssociation
					ifTrue: [ BlElement new size: 1 @ 1 ]
					ifFalse: [ each generateCheckboxForBoolean: #isRecurring ] ];
		column: 'Is Planned'
			stencil: [ :each | 
				each isAssociation
					ifTrue: [ BlElement new size: 1 @ 1 ]
					ifFalse: [ each generateCheckboxForBoolean: #isPlanned ] ];
		column: 'First Time Scheduled'
			stencil: [ :each | 
				each isAssociation
					ifTrue: [ BlElement new size: 1 @ 1 ]
					ifFalse: [ each generateCheckboxForBoolean: #firstTimeScheduled ] ];
		column: 'Category'
			stencil: [ :each | 
				each isAssociation
					ifTrue: [ BlElement new size: 1 @ 1 ]
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
		column: 'Delete Day'
			stencil: [ :each | 
				each isAssociation
					ifTrue: [ BrButton new
							aptitude: BrGlamorousButtonWithIconAptitude;
							icon: BrGlamorousVectorIcons remove;
							action: [ :aBrButton :aBrButtonModel :anEvent | 
								anEvent consumed: true.
								each value do: [ :aTrackedTime | aTrackedTime delete ].
								aBrButton phlow firstParentWithView phlow syncUpdate ] ]
					ifFalse: [ BlElement new size: 1 @ 1 ] ];
		send: [ :each | each isAssociation ifTrue: [ each value ] ifFalse: [ each ] ];
		expandAll
]

{ #category : #views }
TtEventCollection >> gtWeeklySummaryFor: aView [
	<gtView>
	| days weeks |
	days := self groupedByDay associations.
	weeks := (days collectAsSet: [ :each | each key asWeek ]) asArray sorted.
	^ aView columnedList
		title: 'Weekly Summary';
		priority: 6;
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
		flag: #TODO; "Using calendar SVG asset from different package, duplicate or add GtPomodoro as dependency."
		actionDropdownButtonIcon: [ BrGlamorousVectorIcons calendar asElement asScalableElement size: 20 @ 20 ]
					asStencil
			content: [ :aButton :aBrTab | 
				| element |
				element := GtCalendarElement forDate: Date today.
				element
					when: GtCalendarDateClickedEvent
					do: [ :anEvent | 
						| rootCollection |
						rootCollection := self
								detect: [ :each | each category isNotNil ]
								ifFound: [ :found | found category rootCategory collection ]
								ifNone: [ rootCollection := self ].
						anEvent consumed: true.
						aButton fireEvent: BrDropdownHideWish new.
						aButton phlow
							spawnObject: (rootCollection
									select: [ :aTrackedTime | aTrackedTime start asDate asWeek = anEvent date asWeek ]) ] ]
]

{ #category : #import }
TtEventCollection >> importFromTrello [
	| response daysToImport existingDays |
	self flag: #TODO.	"This should eventually call a properly configured class that implements a trait that knows how to import data"
	[ response := TtTrelloImporter fetch ] on: NameLookupFailure do: [ ^ self ].
	self
		serializeCollection;
		loadFromLepiter.
	existingDays := (self collect: [ :each | each start asDate ] as: Set) asArray
			sorted: #yourself descending.
	daysToImport := (response keys difference: existingDays) asArray
			sorted: #yourself ascending.
	daysToImport
		select: [ :each | [ each < existingDays first ] on: SubscriptOutOfBounds do: [ false ] ]
		thenDo: [ :each | self inform: 'Date: ' , each asString , ' may be a typo as it is historical.' ].
	(daysToImport first: 1)
		do: [ :day | TtTrelloParser new add: (response associationAt: day) toCollection: self ]
		 "response associations first in:
		associationsDo: [ :day | TtTrelloParser new add: day toCollection: self ]"
]

{ #category : #accessing }
TtEventCollection >> items [
	^ items ifNil: [
		items := SortedCollection new ]
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
		ifNone: [ self categories: (TtCategories basicNew collection: self) ]
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
				in: [ :someDates | 
					someDates min yyyymmdd , '-' , (someDates min weekday first: 3)
						, (someDates min = someDates max
								ifTrue: [ '' ]
								ifFalse: [ ' - ' , someDates max yyyymmdd , '-' , (someDates max weekday first: 3) ]) ]);
		nextPutAll: ' [';
		nextPutAll: self size asString , ' items';
		nextPutAll: '])'
]

{ #category : #accessing }
TtEventCollection >> recalculateGroupedByDay [
	groupedByDay := nil.
	^ self groupedByDay
]

{ #category : #enumerating }
TtEventCollection >> reject: aBlock [
	^ (self species withAll: (self items reject: aBlock))
		page: self page;
		categories: self categories
]

{ #category : #enumerating }
TtEventCollection >> select: aBlock [
	^ (self species withAll: (self items select: aBlock))
		page: self page;
		categories: self categories
]

{ #category : #import }
TtEventCollection >> serializeCollection [
	self items isValueHolder
		ifFalse: [ items := self items asValueHolder.
			items whenAddedDo: [ :newValue | self class serializeWithLepiter: newValue ] ]
]

{ #category : #accessing }
TtEventCollection >> valueHolder: anObject [
	collection := anObject
]
