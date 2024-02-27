Class {
	#name : #TtEventCollection,
	#superclass : #Object,
	#traits : 'TGtGroupWithItems',
	#classTraits : 'TGtGroupWithItems classTrait',
	#instVars : [
		'valueHolder',
		'counter'
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
		title: 'Pomodoros By Day';
		priority: 1;
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

{ #category : #accessing }
TtEventCollection >> add: anItem [
	self valueHolder add: anItem
]

{ #category : #accessing }
TtEventCollection >> addAll: aCollection [
	self valueHolder addAll: aCollection
]

{ #category : #accessing }
TtEventCollection >> counter [
	^ counter
		ifNil: [ self ifEmpty: [ counter := 1 ] ifNotEmpty: [ counter := self size + 1 ] ]
]

{ #category : #accessing }
TtEventCollection >> counter: anInteger [
	counter := anInteger
]

{ #category : #views }
TtEventCollection >> groupByDay [
	^ self groupedBy: [ :each | each start asDate ]
]

{ #category : #views }
TtEventCollection >> gtPomodorosFor: aView [
	<gtView>
	| pomodoros |
	self ifEmpty: [ ^ aView empty ].
	pomodoros := self groupByDay associations sorted: #key descending.
	^ aView columnedTree
		title: 'Pomodoros By Day';
		priority: 5;
		items: pomodoros;
		children: [ :each | each isAssociation ifTrue: [ each value ] ifFalse: [ #() ] ];
		column: 'Pomodoros'
			text: [ :each | each isAssociation ifTrue: [ each key asString ] ifFalse: [ each asString ] ];
		column: 'Has Reflection'
			stencil: [ :each | 
				each isAssociation
					ifTrue: [ BlElement new ]
					ifFalse: [ BrCheckbox new
							aptitude: BrGlamorousCheckboxAptitude;
							in: [ :aCheckbox | 
								(each reflection isNil or: [ each reflection = 'nil' ])
									ifTrue: [ aCheckbox uncheck ]
									ifFalse: [ aCheckbox check ].
								aCheckbox ];
							disable ] ];
		send: [ :each | each isAssociation ifTrue: [ each value ] ifFalse: [ each ] ];
		expandAll
]

{ #category : #accessing }
TtEventCollection >> gtWeeklySummaryFor: aView [
	<gtView>
	| days weeks |
	days := self groupByDay associations.
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
		ifFalse: [ GtPomodoroSettings default serializeWithLepiter
				ifTrue: [ | page |
					page := LeDatabasesRegistry defaultLogicalDatabase
							pageNamed: 'GtPomodoro Entries'
							ifAbsent: [ | newPage |
								newPage := LePage named: 'GtPomodoro Entries'.
								LeDatabasesRegistry defaultLogicalDatabase addPage: newPage.
								newPage addFirstSnippet: (LeTextSnippet string: '').
								newPage ].
					page children asArray
						select: [ :each | each isKindOf: LeUnknownSnippet ]
						thenDo: [ :each | 
							| json |
							json := (NeoJSONObject fromString: each jsonString) at: 'data'.
							self items
								add: (GtPomodoro new
										start: json start asDateAndTime;
										duration: json duration asDuration;
										goals: json goals;
										reflection: json reflection yourself) ] ]
				ifFalse: [ | folder |
					folder := '.' asFileReference / #pomodoro.
					(folder exists
						and: [ folder files anySatisfy: [ :aFile | aFile extension = 'json' ] ])
						ifTrue: [ folder files
								select: [ :aFile | aFile extension = 'json' ]
								thenDo: [ :aFile | 
									| json |
									json := NeoJSONObject fromString: aFile contents.
									self items
										add: (GtPomodoro new
												start: json start asDateAndTime;
												duration: json duration asDuration;
												goals: json goals;
												reflection: json reflection yourself) ] ] ] ]
]

{ #category : #accessing }
TtEventCollection >> items [
	^ items ifNil: [ items := self valueHolder value ]
]

{ #category : #printing }
TtEventCollection >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPut: $(;
		nextPutAll: (self groupByDay keys
				in: [ :someDates | someDates min asString , ' - ' , someDates max asString ]);
		nextPutAll: ' [';
		nextPutAll: self size asString , ' items';
		nextPutAll: '])'
]

{ #category : #accessing }
TtEventCollection >> valueHolder [
	^ valueHolder
		ifNil: [ valueHolder := (SortedCollection
					sortUsing: [ :aPomodoro | aPomodoro start ] ascending) asValueHolder.
			valueHolder
				whenAddedDo: [ :newValue | 
					newValue serializeWithCounter: self counter.
					self counter: self counter + 1 ].
			valueHolder ]
]

{ #category : #accessing }
TtEventCollection >> valueHolder: anObject [
	valueHolder := anObject
]
