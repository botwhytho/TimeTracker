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

{ #category : #accessing }
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
		scaleData: [ :each | (each start asDuration asMinutes + (each duration asMinutes / 2)) rounded ];
		constraintsDo: [ :c | c vertical fitContent ];
		valueElement: [ :aGtPlotterSingleScaleContext | BlElement new ];
		valueStyle: [ :anElement :aGtPlotterSingleScaleContext | 
			anElement
				border: (BlBorder paint: Color darkGray width: 0.5);
				background: (aGtPlotterSingleScaleContext originalValue category
						ifNotNil: [ :notNil | TtCategories stringToColorHash: notNil name ]
						ifNil: [ Color veryVeryLightGray ]);
				constraintsDo: [ :c | 
					c horizontal matchParent.
					c frame horizontal
						weight: aGtPlotterSingleScaleContext originalValue duration asMinutes rounded
								/ (24 * 60) ];
				when: BlClickEvent
					do: [ :anEvent | 
						anEvent target phlow
							spawnObject: (aTTEventCollection
									select: [ :each | each = aGtPlotterSingleScaleContext originalValue ]) ] ];
		values: aTTEventCollection;
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
		tooltip: 'Default Tracked Time Collection';
		priority: 1;
		action: [ :aButton | aButton phlow spawnObject: self default ]
]

{ #category : #views }
TtEventCollection class >> gtSummaryFor: aView [
	<gtClassView>
	^ aView forward
		title: 'Summary';
		priority: 1;
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
TtEventCollection >> buildBars: data [
	| theData maxLines aBarWidthScale barChart totalTime |
	theData := GtPlotterDataGroup new values: data.
	totalTime := data sum: #sum.
	theData := theData
			labelled: [ :each | 
				each category = 'Uncategorized'
					ifTrue: [ each category ]
					ifFalse: [ each category name ] ].
	theData := theData
			colored: [ :each | 
				each category = 'Uncategorized'
					ifTrue: [ Color transparent ]
					ifFalse: [ TtCategories stringToColorHash: each category name ] ].

	maxLines := theData
			inject: 0
			intoValues: [ :anAmount :eachValue | anAmount max: eachValue sum asHours ].
	aBarWidthScale := GtPlotterLinearScale new domainFrom: 0 to: maxLines.

	barChart := GtPlotterHorizontalBarChart new.
	barChart
		barElement: [ :aGtPlotterContext | 
			BlElement new
				aptitude: ((BrGlamorousWithTooltipAptitude2
						content: [ BrLabel new
								text: (aGtPlotterContext originalValue category = 'Uncategorized'
										ifTrue: [ aGtPlotterContext originalValue category ]
										ifFalse: [ aGtPlotterContext originalValue category name ]);
								aptitude: (BrGlamorousLabelAptitude new padding: (BlInsets all: 1)) ])
						hideDelay: 0;
						showDelay: 0) ].
	barChart barLabelWidth: 160.
	barChart barWidthScale: aBarWidthScale.
	barChart barWidthData: [ :eachValue | eachValue sum asHours ].
	barChart amountOfTicks: 4.
	barChart with: theData.

	^ barChart asElement
]

{ #category : #'building ui' }
TtEventCollection >> buildDonut: data [
	^ BlElement new
		size: 400 @ 400;
		addChildren: (data
				collect: [ :each | 
					| color |
					color := each category = 'Uncategorized'
							ifTrue: [ Color transparent ]
							ifFalse: [ TtCategories stringToColorHash: each category name ].
					BlElement new
						when: BlClickEvent
							do: [ :e | 
								e consumed: true.
								e target phlow spawnObject: each events ];
						when: BlDoubleClickEvent
							do: [ :e | 
								e consumed: true.
								e target phlow spawnObject: each ];
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
					events: anAssociation value;
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

{ #category : #accessing }
TtEventCollection >> gtSummaryFor: aView [
	<gtView>
	self flag: #TODO "Changes in categorizing should re-render graphs in realtime".
	^ aView explicit
		title: 'Summary' translated;
		priority: 0;
		actionUpdateButton;
		stencil: [ | data horizontalPane verticalPane |
			data := self calculateAnglesForDonut.
			horizontalPane := BrHorizontalPane new
					matchParent;
					alignCenter.
			horizontalPane
				flag: #TODO; "Use percentage on bars as hours past 1 day don't make sense"
				flag: #TODO; "Bars need to spawn collection correctly. Currently spawning helper object."
				flag: #TODO; "On hover 'select' both categories on bar graph and donut"
				addChildren: {self buildDonut: data.
						self buildBars: data}.
			verticalPane := BrVerticalPane new
					matchParent;
					alignCenter;
					addChildren: {horizontalPane.
							(self gtWeeklySummaryFor: GtPhlowView empty) asElement.
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
		flag: #TODO "Using calendar SVG asset from different package, duplicate or add GtPomodoro as dependency.";
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
									select: [ :aTrackedTime | aTrackedTime start asDate asWeek = anEvent date asWeek ]) ] ]
]

{ #category : #import }
TtEventCollection >> importFromTrello [
	| response daysToImport |
	self flag: #TODO.	"This should eventually call a properly configured class that implements a trait that knows how to import data"
	[ response := TtTrelloImporter fetch ] on: NameLookupFailure do: [ ^ self ].
	self
		serializeCollection;
		loadFromLepiter.
	daysToImport := (response keys difference: (self collect: [:each| each start asDate] as: Set)) asArray sorted: #yourself ascending.
	(daysToImport first: 1) do: [ :day | TtTrelloParser new add: (response associationAt: day) toCollection: self ].
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
