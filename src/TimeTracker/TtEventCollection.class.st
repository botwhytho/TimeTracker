Class {
	#name : #TtEventCollection,
	#superclass : #Object,
	#traits : 'TGtGroupWithItems',
	#classTraits : 'TGtGroupWithItems classTrait',
	#instVars : [
		'groupedByDay',
		'collection'
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

{ #category : #views }
TtEventCollection class >> gtPomodorosFor: aView [
	<gtView>
	<gtClassView>
	^ aView forward
		title: 'Pomodoros By Day';
		priority: 5;
		object: self new;
		view: #gtPomodorosFor:
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

{ #category : #'instance creation' }
TtEventCollection class >> newFrom: aCollection [
	^ self withAll: aCollection
]

{ #category : #import }
TtEventCollection class >> serializeCollection [
	^ self new serializeCollection
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
		  addChildren: (data collect: [ :each | 
					   BlElement new
						   when: BlClickEvent
						   do: [ :e | e target phlow spawnObject: each last ];
						   geometry: (BlAnnulusSector new
								    startAngle: each third first;
								    endAngle: each third last;
								    innerRadius: 0.85);
						   background: each fourth;
						   constraintsDo: [ :c | 
							   c horizontal matchParent.
							   c vertical matchParent ] ])
]

{ #category : #'building ui' }
TtEventCollection >> calculateAnglesForDonut [
	| categories totalTime |
	categories := self sortedEntries.
	totalTime := categories sum: [ :each | each second ].
	categories
		inject: -90
		into: [ :sum :each | 
			| color temp |
			temp := (each second / totalTime * 360 + sum) asInteger.
			each
				add: {sum.
						temp}
				afterIndex: 2.
			color := Color random.
			each first = 'Uncategorized' ifTrue: [ color := color alpha: 0.1 ].
			each add: color afterIndex: 3.
			temp ].	"Completing the circle, fixing any rounding differences by hard coding smallest entry's stop angle. Distorts it a bit but okay compromise for now"
	categories last
		at: 3
		put: {categories last third first.
				270}.
	^ categories
]

{ #category : #accessing }
TtEventCollection >> collection [
	^ collection
		ifNil: [ collection := SortedCollection
					sortUsing: [ :aPomodoro | aPomodoro start ] ascending ]
]

{ #category : #views }
TtEventCollection >> groupedByDay [
	^ groupedByDay
		ifNil: [ groupedByDay := self groupedBy: [ :each | each start asDate ] ]
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
TtEventCollection >> gtPomodorosFor: aView [
	<gtView>
	| pomodoros |
	self ifEmpty: [ ^ aView empty ].
	pomodoros := self groupedByDay associations sorted: #key descending.
	^ aView columnedTree
		title: 'Entries By Day';
		priority: 5;
		items: pomodoros;
		children: [ :each | each isAssociation ifTrue: [ each value ] ifFalse: [ #() ] ];
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

{ #category : #initialization }
TtEventCollection >> initialize [
	super initialize.
	self flag: #TODO.	"Below is a code smell, should only load from disk by calling code as this collection just became more generic as can re-use for daily/weekly views"
	thisContext sender sender selector = #withAll:
		ifFalse: [ | page |
			page := LeDatabasesRegistry defaultLogicalDatabase
					pageNamed: TtTrackedTime dataPageName
					ifAbsent: [ | newPage |
						newPage := LePage named: TtTrackedTime dataPageName.
						LeDatabasesRegistry defaultLogicalDatabase addPage: newPage.
						newPage addFirstSnippet: (LeTextSnippet string: '').
						newPage ].
			page children asArray
				select: [ :each | each isKindOf: LeUnknownSnippet ]
				thenDo: [ :each | 
					| json |
					json := (NeoJSONObject fromString: each jsonString) at: 'data'.
					self items
						add: (TtTrackedTime new
								start: json start asDateAndTime;
								duration: json duration asDuration;
								description: json description;
								details: json details;
								rawData: json rawData;
								yourself) ] ]
]

{ #category : #accessing }
TtEventCollection >> items [
	^ items ifNil: [ items := self collection value ]
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
	collection := collection asValueHolder.
	collection whenAddedDo: [ :newValue | newValue serializeWithLepiter ]
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
