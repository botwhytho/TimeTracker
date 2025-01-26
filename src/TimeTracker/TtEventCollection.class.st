Class {
	#name : #TtEventCollection,
	#superclass : #Object,
	#traits : 'TGtGroupWithItems + TGtUniqueInstance',
	#classTraits : 'TGtGroupWithItems classTrait + TGtUniqueInstance classTrait',
	#instVars : [
		'categories',
		'page',
		'viewFilterContext',
		'includeUntracked',
		'groupingLevel'
	],
	#classInstVars : [
		'uniqueInstance',
		'pageRegistry'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtEventCollection class >> defaultPageName [
	^ 'Time Tracker Entries'
]

{ #category : #views }
TtEventCollection class >> gtPageRegistryFor: aView [
	<gtClassView>
	self pageRegistry ifEmpty: [ ^ aView empty ].
	^ aView columnedList
		title: 'Page Registry';
		priority: 1;
		items: [ self pageRegistry associations ];
		column: 'Database' text: [ :each | each key database databaseName ];
		column: 'Page' text: [ :each | each key title ];
		send: [ :each | each value latestWeek ]
]

{ #category : #initialization }
TtEventCollection class >> loadFromLepiter [
	^ self default loadFromLepiter
]

{ #category : #'instance creation' }
TtEventCollection class >> newFrom: aCollection [
	^ self withAll: aCollection
]

{ #category : #accessing }
TtEventCollection class >> pageRegistry [
	^ pageRegistry
		ifNil: [ self loadFromLepiter.
			pageRegistry := Dictionary new
					at: self default page put: self default;
					yourself ]
]

{ #category : #accessing }
TtEventCollection class >> pageRegistry: aDictionary [
	pageRegistry := aDictionary
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
			foundSnippet jsonString: serialized source: lepiterPage.
			foundSnippet domainObject ifNil: [ foundSnippet domainObject: anEntity ] ]
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
			anUnknownSnippet domainObject
				ifNil: [ anUnknownSnippet domainObject: anEntity ].
			anEntity uid: anUnknownSnippet uidString ]
]

{ #category : #serialization }
TtEventCollection class >> supportedSnippetTypes [
	^ {TtTrackedTimeSnippet.
		TtNoteSnippet}
]

{ #category : #views }
TtEventCollection >> TtCategoriesFor: aView context: aContext [
	<gtView>
	self categories ifNil: [ ^ aView empty ].
	^ aView forward
		title: 'Categories';
		priority: 6;
		object: self categories;
		view: #TtCategoriesFor:context:;
		actionButtonIcon: BrGlamorousVectorIcons inspect
			label: 'Categories'
			action: [ :aBrButton :aBrTab :aBrButtonModel :aBlClickEvent | aBrButton phlow spawnObject: self categories ]
]

{ #category : #filtering }
TtEventCollection >> allCategorized [
	^ self select: [ :each | each category isNotNil ]
]

{ #category : #filtering }
TtEventCollection >> allEqualTo: aTtTrackedTime [
	"Returns all entries happening at the same time. Had to define identityBefore/identityAfter (that use `identityIndexOf:`) for this to work properly as `indexOf:` just compares by `=`"

	| before after previous next sortedCollection |
	sortedCollection := self items value.
	before := OrderedCollection new.
	after := OrderedCollection new.
	previous := sortedCollection identityBefore: aTtTrackedTime ifAbsent: [ nil ].
	next := sortedCollection identityAfter: aTtTrackedTime ifAbsent: [ nil ].

	[ previous isNotNil and: [ aTtTrackedTime = previous ] ]
		whileTrue: [ before add: previous.
			previous := sortedCollection identityBefore: previous ifAbsent: [ nil ] ].
	[ next isNotNil and: [ aTtTrackedTime = next ] ]
		whileTrue: [ after add: next.
			next := sortedCollection identityAfter: next ifAbsent: [ nil ] ].
	^ before , after
]

{ #category : #filtering }
TtEventCollection >> allOverlappingWith: aTtTrackedTime [
	"Returns all entries overlapping with the entry at some point (both shorter and longer timespans)."

	self flag: #EXPENSIVE.	"What would we use this for that can't be achieve more cheaply. This iterates whole collection and does (potentially) expensive comparisons"
	^ self items value asArray
		select: [ :each | 
			(each == aTtTrackedTime) not
				and: [ (aTtTrackedTime includes: each) or: [ each includes: aTtTrackedTime ] ] ]
]

{ #category : #filtering }
TtEventCollection >> allUncategorized [
	^ self select: [ :each | each category isNil ]
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
				each category name , ' ('
					, (each sum asHours / totalTime * 100 round: 1) asString , '%)' ].
	theData := theData background: [ :each | each category color ].

	maxLines := theData
			inject: 0
			intoValues: [ :anAmount :eachValue | anAmount max: eachValue sum asHours / totalTime ].
	aBarWidthScale := GtPlotterLinearScale new domainFrom: 0 to: maxLines.

	barChart := GtPlotterHorizontalBarChart new.
	barChart
		barElement: [ :aGtPlotterContext | 
			| categoryName |
			categoryName := aGtPlotterContext originalValue category name.
			BlElement new
				id: categoryName;
				border: (BlBorder paint: Color lightGray width: 1);
				aptitude: (BrGlamorousWithLabelTooltipAptitude new
						text: (aGtPlotterContext originalValue
								in: [ :helper | 
									(helper sum / self groupedByDay keys size roundUpTo: 1 minute) asString
										, ' avg, '
										, (helper sum / helper collection groupedByDay keys size roundUpTo: 1 minute)
												asString , '/day, '
										, ((helper sum roundUpTo: 1 minute) asHours round: 1) asString
										, ' total' ]));
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
		barLabelSpacing: 160;
		barWidthScale: aBarWidthScale;
		barWidthData: [ :eachValue | eachValue sum asHours / totalTime ];
		tickLabelFormat: [ :eachFloat | (eachFloat * 100 round: 1) asString , '%' ];
		amountOfTicks: 4;
		with: theData.

	container := barChart asElement id: #buildBars:.
	^ container
]

{ #category : #views }
TtEventCollection >> buildDailySummary: data [
	| days flattenedData |
	flattenedData := (data
			reject: [ :each | each category = TtCategories untracked ])
			flatCollect: [ :aTtCategorizedEventsHelper | 
				aTtCategorizedEventsHelper collection
					collect: [ :aTtTrackedTime | aTtCategorizedEventsHelper category -> aTtTrackedTime ] ].
	days := flattenedData groupedBy: [ :each | each value start asDate ].
	days := (flattenedData groupedBy: [ :each | each value start asWeek ]) size = 1
			ifTrue: [ days associations sorted: #key ascending ]
			ifFalse: [ days associations sorted: #key descending ].
	^ GtPhlowView new columnedList
		title: 'Daily Summary';
		priority: 6;
		items: [ days , {nil -> nil} ];
		column: 'Day'
			stencil: [ :each | 
				each key
					ifNil: [ BlElement new ]
					ifNotNil: [ BrButton new
							aptitude: BrGlamorousButtonWithLabelAptitude;
							label: each key yyyymmdd , '-' , (each key weekday first: 3);
							action: [ :anElement | anElement phlow spawnObject: (self withAll: (each value collect: #value)) ] ] ]
			weight: 0.1;
		column: 'Tracked Time'
			stencil: [ :each | 
				each key
					ifNil: [ self hourlyTicksElement ]
					ifNotNil: [ self dailyTimePlot: each value ] ]
			weight: 0.9;
		send: [  ];
		asElementDo: [ :anElement | anElement id: #buildDailySummary: ]
]

{ #category : #'building ui' }
TtEventCollection >> buildDonut: data [
	| element |
	element := BlElement new.
	^ element
		id: #buildDonut:;
		size: 400 @ 400;
		addChildren: (data
				collect: [ :each | 
					| categoryName color |
					categoryName := each category name.
					color := each category color.
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
						geometry: (BlAnnulusSectorGeometry new
								startAngle: each startAngle;
								endAngle: each endAngle;
								innerRadius: 0.85);
						border: (BlBorder paint: Color lightGray width: 1);
						background: color;
						constraintsDo: [ :c | 
							c horizontal matchParent.
							c vertical matchParent ] ])
]

{ #category : #views }
TtEventCollection >> buildEntriesByDay: aContext [
	| entriesByDay notes timeEntries timeEntriesAndDays |
	timeEntries := self timeEntries.
	entriesByDay := timeEntries groupedByWeek size = 1
			ifTrue: [ timeEntries groupedByDay associations sorted: #key ascending ]
			ifFalse: [ timeEntries groupedByDay associations sorted: #key descending ].
	timeEntriesAndDays := timeEntries asArray
			, (self groupedByDay keys
					collect: [ :each | Timespan starting: each duration: each asDuration ]).
	self flag: #EXPENSIVE.	"Should we cache the below calculation?"
	notes := self rootCollection notes asArray
			flatCollect: [ :each | 
				timeEntriesAndDays
					select: [ :inner | each includes: inner ]
					thenCollect: [ :inner | inner -> each ] ].
	^ GtPhlowView new columnedTree
		items: entriesByDay;
		children: [ :each | each isAssociation ifTrue: [ each value ] ifFalse: [ #() ] ];
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
			stencil: [ :each :rowIndex :columnIndex |
				self flag: #TODO. "Wrap category view in domain object, have a unique Instance and re-use/cache?" 
				each isAssociation
					ifTrue: [ BlElement new size: 1 @ 1 ]
					ifFalse: [ | aButton |
						aButton := BrButton new.
						aButton
							aptitude: BrGlamorousButtonWithIconAndLabelAptitude
									+ (BrWithExplicitDropdownAptitude new
											stencil: [ BrMenuExplicit new
													stencil: [ :anExplicitMenu | 
														BrFrame new
															size: ((GtWorld spaceWithId: GtWorld defaultId do: #yourself) extent
																	in: [ :screenSize | (screenSize x * 0.45) @ screenSize y * 0.9 ]);
															padding: (BlInsets all: 15);
															addChild: (self categories
																	TtCategoriesFor: GtPhlowView empty
																	context: (GtPhlowContext new
																			at: #TtTrackedTime
																				put: {self.
																						each.
																						aButton.
																						anExplicitMenu};
																			yourself)) asElement ] ]).
						each category
							ifNotNil: [ :notNil | 
								aButton
									label: notNil name;
									icon: (BlElement new
											size: 15 @ 15;
											geometry: BlCircleGeometry new;
											background: each category color) ]
							ifNil: [ aButton
									label: 'Categorize' asRopedText;
									icon: (BlElement new
											size: 15 @ 15;
											geometry: BlCircleGeometry new;
											background: Color transparent) ] ] ];
		column: 'Notes'
			stencil: [ :each | 
				| aTimespan pageLinks |
				aTimespan := each isAssociation
						ifTrue: [ Timespan starting: each key duration: each key asDuration ]
						ifFalse: [ each ].
				pageLinks := notes
						select: [ :anAssociation | 
							aTimespan isTimeEntry
								ifTrue: [ anAssociation key == aTimespan ]
								ifFalse: [ anAssociation key = aTimespan ] ]
						thenCollect: #value.
				TtPageLinks new
					timespan: aTimespan;
					pageLinks: pageLinks;
					collection: self rootCollection ];
		column: 'Delete Day'
			stencil: [ :each | 
				each isAssociation
					ifTrue: [ BrButton new
							aptitude: BrGlamorousButtonWithIconAptitude;
							icon: BrGlamorousVectorIcons remove;
							action: [ :aBrButton :aBrButtonModel :anEvent | 
								| viewElement |
								anEvent consumed: true.
								viewElement := aBrButton phlow firstParentWithViewContent phlow
										firstParentWithViewContent.
								each value do: [ :aTrackedTime | aTrackedTime delete ].
								(self
									perform: viewElement id asSymbol
									withArguments: {GtPhlowEmptyView new.
											GtPhlowContext new}) updateContent: viewElement ] ]
					ifFalse: [ BlElement new size: 1 @ 1 ] ];
		send: [ :each | each isAssociation ifTrue: [ each value ] ifFalse: [ each ] ];
		expandAll;
		asElementDo: [ :element | 
			self
				detect: [ :each | each category isNil ]
				ifFound: [ :aTrackedTime | 
					| anIndex aBrTree indexInTree |
					anIndex := self items identityIndexOf: aTrackedTime.
					aBrTree := element childAt: 2.
					indexInTree := anIndex + aBrTree viewModel root value size.
					aBrTree
						scrollToIndex: (indexInTree - 3 max: 1);
						selectOne: indexInTree ]
				ifNone: [  ].
			element ]
]

{ #category : #'building ui' }
TtEventCollection >> calculateAnglesForDonut [
	| sortedCategories totalTime |
	sortedCategories := self groupedAndSortedByDuration.
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

{ #category : #views }
TtEventCollection >> dailyTimePlot: aTTEventCollection [
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
							(aGtPlotterSingleScaleContext originalValue value
								sorted: [ :each | each key name ] ascending)
								do: [ :aTtTrackedTime | 
									| element |
									element := BlElement new
											constraintsDo: [ :c | 
												c vertical matchParent.
												c horizontal matchParent ];
											border: (BlBorder paint: Color darkGray width: 0.5);
											background: aTtTrackedTime key color.
									aBrVerticalPane addChild: element ].
							aBrVerticalPane ]);
				when: BlClickEvent
					do: [ :anEvent | 
						| newCollection someTrackedTimes |
						someTrackedTimes := aGtPlotterSingleScaleContext originalValue value value.
						newCollection := self class new
								categories: someTrackedTimes first value collection categories;
								page: someTrackedTimes first value collection page;
								addAll: (someTrackedTimes collect: #value).
						anEvent consumed: true.
						anEvent target phlow spawnObject: newCollection ] ];
		values: (aTTEventCollection groupedBy: [ :each | each value asTimespan ]) associations;
		when: BlDoubleClickEvent
			do: [ :anEvent | anEvent target phlow spawnObject: aTTEventCollection ]
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
TtEventCollection >> groupIntoContiguous [
	| contiguousCollections timeEntries |
	timeEntries := self timeEntries.
	contiguousCollections := timeEntries items value allButFirst
			inject: (OrderedCollection with: (OrderedCollection with: timeEntries first))
			into: [ :collection :each | 
				(each isContiguous: collection last last)
					ifFalse: [ collection add: OrderedCollection new ].
				collection last add: each.
				collection ].
	^ contiguousCollections
		collect: [ :each | (Timespan starting: each first start ending: each last end rounded) -> each ]
]

{ #category : #acccessing }
TtEventCollection >> groupedAndSortedByDuration [
	| groupedActivities groupedByTimespan summedGroupings |
	groupedByTimespan := self timeEntries groupedByTimespan.
	groupedActivities := self timeEntries groupedByFilter.
	summedGroupings := groupedActivities associations
			collect: [ :anAssociation | 
				TtCategorizedEventsHelper new
					category: anAssociation key;
					collection: anAssociation value;
					sum: (anAssociation value
							collect: [ :each | each duration / (groupedByTimespan at: each asTimespan) size ])
							sum ].
	summedGroupings
		detect: [ :each | each category = TtCategories untracked ]
		ifFound: [ :found | found sum: self timeEntries groupedByDay keys size days - groupedByTimespan keys sum ]
		ifNone: [  ].
	^ summedGroupings sorted: #sum descending
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
						categories: self categories;
						viewFilterContext: self viewFilterContext;
						includeUntracked: self includeUntracked;
						groupingLevel: self groupingLevel) ].

	^ result
]

{ #category : #'accessing - grouping' }
TtEventCollection >> groupedByCategory [
	| daysWithUntrackedTime grouped |
	grouped := self
			groupedBy: [ :each | 
				each category
					ifNil: [ TtCategories uncategorized ]
					ifNotNil: [ :aCategory | 
						self groupingLevel isSymbol
							ifTrue: [ aCategory topMostCategory ]
							ifFalse: [ aCategory moveUpHierarchy: self groupingLevel ] ] ].
	daysWithUntrackedTime := self groupedByDay associations
			select: [ :anAssociation | 
				(anAssociation value
					groupedBy: [ :each | each value as: each value class superclass ]) keys sum
					< 1 day ]
			thenCollect: #key.
	self includeUntracked
		ifTrue: [ daysWithUntrackedTime
				ifNotEmpty: [ grouped
						at: TtCategories untracked
						put: (self select: [ :each | daysWithUntrackedTime includes: each start asDate ]) ] ].
	^ grouped
]

{ #category : #views }
TtEventCollection >> groupedByCategoryForLineGraph [
	^ (((self groupedByCategory
		associationsSelect: [ :each | (#('Uncategorized' 'Untracked') includes: each key name) not ])
		associations
		collect: [ :each | 
			each key
				-> (each value groupedByDay associations
						collect: [ :inner | 
							{#category -> each key.
								#duration -> (inner value items sum: #duration) asHours.
								#date -> inner key} asDictionary as: NeoJSONObject ]) ]) collect: #value)
		flatten sorted: [ :each | each date ] ascending
]

{ #category : #'accessing - grouping' }
TtEventCollection >> groupedByDay [
	^ self groupedBy: [ :each | each start asDate ]
]

{ #category : #'accessing - grouping' }
TtEventCollection >> groupedByFilter [
	^ self perform: #groupedBy , self viewFilterContext
]

{ #category : #'accessing - grouping' }
TtEventCollection >> groupedByFirstTimeScheduled [
	^ self
		groupedBy: [ :each | 
			each firstTimeScheduled
				ifTrue: [ TtCategories firstTimeScheduled ]
				ifFalse: [ TtCategories rescheduled ] ]
]

{ #category : #'accessing - grouping' }
TtEventCollection >> groupedByIsPlanned [
	^ self
		groupedBy: [ :each | 
			each isPlanned
				ifTrue: [ TtCategories planned ]
				ifFalse: [ TtCategories unplanned ] ]
]

{ #category : #'accessing - grouping' }
TtEventCollection >> groupedByIsRecurring [
	^ self
		groupedBy: [ :each | 
			each isRecurring
				ifTrue: [ TtCategories recurring ]
				ifFalse: [ TtCategories oneTime ] ]
]

{ #category : #'accessing - grouping' }
TtEventCollection >> groupedByTimespan [
	^ self groupedBy: #asTimespan
]

{ #category : #'accessing - grouping' }
TtEventCollection >> groupedByWeek [
	^ self groupedBy: [ :each | each start asWeek ]
]

{ #category : #accessing }
TtEventCollection >> groupingLevel [
	^ groupingLevel ifNil: [ groupingLevel := 0 ]
]

{ #category : #accessing }
TtEventCollection >> groupingLevel: anObject [
	groupingLevel := anObject
]

{ #category : #'as yet unclassified' }
TtEventCollection >> gtCalendarViewFor: aView [
	"(self items collectAsSet: #category)"

	<gtView>
	self groupedByCategory keys size > 2 ifTrue: [ ^ aView empty ].
	^ aView explicit
		title: 'Calendar View';
		priority: 4;
		stencil: [ | grid months |
			months := self groupedBy: [ :each | each start asMonth ].
			grid := BrHorizontalGrid new
					matchParent;
					columnCount: 3.
			months keys min index % 3
				in: [ :anIndex | 
					anIndex ~= 1
						ifTrue: [ ((2 - (months keys min index % 3) + 2) / 3.0) ceiling
								timesRepeat: [ grid addChild: (BlElement new size: 0 @ 0) ] ] ].
			grid
				addChildren: ((self groupedBy: [ :each | each start asMonth ]) associations
						collect: [ :aMonth | 
							| calendar byDay |
							calendar := MyGtCalendarElement new
									highlightToday: false;
									date: aMonth value last start asDate.
							byDay := aMonth value groupedByDay associations.
							calendar
								enqueueTask: [ calendar dayElements
										do: [ :aContainer | 
											byDay
												detect: [ :aDay | aDay key dayOfMonth asString = aContainer children first label asString ]
												ifFound: [ :found | 
													| element |
													element := BlElement new.
													aContainer
														addChild: (element
																id: #categoryElement;
																zIndex: 1000;
																constraintsDo: [ :c | 
																	c ignoreByLayout.
																	c vertical exact: aContainer children first height * 0.95.
																	c horizontal exact: calendar defaultWidth / 7.0 * 0.95 ];
																background: (found value first category color alpha: 0.25);
																when: BlClickEvent
																	do: [ :aBlClickEvent | 
																		aBlClickEvent consumed: true.
																		element phlow spawnObject: found value ]) ] ] ] asBlTask.
							calendar asScalableElement margin: (BlInsets all: 10) ]) ]
]

{ #category : #views }
TtEventCollection >> gtEntriesByDayFor: aView context: aContext [
	<gtView>
	| pomodoros |
	pomodoros := self timeEntries groupedByDay associations sorted: #key descending.
	^ aView explicit
		title: 'Entries By Day';
		priority: 5;
		stencil: [ BrFrame new
				id: #gtEntriesByDayFor:context:;
				matchParent;
				addChild: (self buildEntriesByDay: aContext) ]
]

{ #category : #views }
TtEventCollection >> gtGroupedByDescriptionFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Grouped By Description';
		priority: 2;
		items: [ (self groupedBy: [ :each | each description capitalized ]) associations
				sorted: [ :each | each value items sum ] descending ];
		column: 'Activity' text: #key;
		column: 'Category' text: [ :each | each value first category name ];
		column: 'Ocurrences' text: [ :each | each value size ];
		column: 'Average Time'
			text: [ :each | each value items average roundTo: 1 minute ];
		column: 'Total Time'
			text: [ :each | 
				(each value items sum roundTo: 1 minute)
					in: [ :aDuration | aDuration asString , ' (' , (aDuration asHours round: 1) asString , ' hours)' ] ];
		send: [ :each | each value size = 1 ifTrue: [ each value first ] ifFalse: [ each value ] ]
]

{ #category : #views }
TtEventCollection >> gtGroupedByDetailFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Grouped By Detail';
		priority: 1;
		items: [ (self
				groupedBy: [ :each | 
					{each description capitalized.
						each details ifNil: [ '' ] ifNotNil: [ :notNil | notNil capitalized ]} ])
				associations sorted: [ :each | each value items sum ] descending ];
		column: 'Activity' text: [ :each | each key first ];
		column: 'Details' text: [ :each | each key second ];
		column: 'Category' text: [ :each | each value first category name ];
		column: 'Ocurrences' text: [ :each | each value size ];
		column: 'Average Time'
			text: [ :each | each value items average roundTo: 1 minute ];
		column: 'Total Time' text: [ :each | each value items sum roundTo: 1 minute ];
		send: [ :each | each value size = 1 ifTrue: [ each value first ] ifFalse: [ each value ] ]
]

{ #category : #import }
TtEventCollection >> gtImportActionFor: anAction context: aContext [
	<gtAction>
	self flag: #TODO.	"Generalize import through some type of interface"
	(aContext navigation previousContext
		ifNil: [ false ]
		ifNotNil: [ :notNil | notNil object isKindOf: TtEventCollection ])
		ifTrue: [ ^ anAction noAction ].
	^ anAction button
		icon: BrGlamorousVectorIcons inspect;
		label: 'Import';
		tooltip: 'Import new data';
		priority: 0.5;
		action: [ :aButton :aBrTab | 
			| aContainer |
			self importFromTrello.
			self flag: #CAUTION.	"This updates an object inspector in place, implementation could break if Gt internals change"
			aContainer := aBrTab phlow firstParentWithViewContent parent parent.
			aContainer parent
				replaceChild: aContainer
				with: (GtInspector newOn: self rootCollection latestWeek) ]
]

{ #category : #inspecting }
TtEventCollection >> gtInspectActionFor: anAction [
	<gtAction>
	^ anAction button
		icon: BrGlamorousVectorIcons inspect;
		label: 'ALL TIME';
		tooltip: 'View ALL historical data';
		priority: 1;
		action: [ :aButton | aButton phlow spawnObject: self rootCollection ]
]

{ #category : #views }
TtEventCollection >> gtLineGraphFor: aView [
	<gtView>
	^ aView explicit
		title: 'Line Graph';
		priority: 4;
		stencil: [ | aChart aData aRawData |
			aRawData := self groupedByCategoryForLineGraph.
			aData := GtPlotterDataGroup new values: aRawData.
			aData := aData
					groupedBy: #category
					labelled: #name
					colored: #color.
			aChart := GtPlotterLineChart new
					with: aData;
					valueX: #date;
					scaleX: GtPlotterTimeScale new;
					titleX: 'Date';
					ticksX: ((self groupedBy: #asWeek) keys size
							in: [ :size | size > 1 ifTrue: [ size ] ifFalse: [ (aRawData groupedBy: #date) keys size - 1 ] ]);
					labelFormatX: self labelFormatX;
					valueY: #duration;
					scaleY: GtPlotterLinearScale new;
					titleY: 'Hours per Day';
					ticksY: ((aRawData collect: #duration)
							in: [ :durations | (durations max - durations min) asInteger ]).
			aChart ]
]

{ #category : #views }
TtEventCollection >> gtNotesFor: aView [
	<gtView>
	| notes notesByPage |
	notes := self noteToTrackedTimeAssociations.
	notesByPage := (notes groupedBy: [ :each | each key page ]) associations
			collect: [ :each | each key -> (self withAll: (each value collect: #value) flatten) ].
	^ aView columnedTree
		title: 'Notes';
		priority: 5.5;
		items: [ notesByPage ];
		children: [ :each | each isAssociation ifTrue: [ {each value} ] ifFalse: [ #() ] ];
		column: 'Lepiter Pages & Linked Entries'
			text: [ :each | each isAssociation ifTrue: [ each key title ] ifFalse: [ each asString ] ];
		sendTool: [ :anItem :anIndex | 
			anItem isAssociation
				ifTrue: [ anItem key asLepiterPagePhlowTool ]
				ifFalse: [ GtInspectorTool forObject: anItem ] ];
		action: [ :anAction | 
			anAction explicit
				stencil: [ :aBrButton :aBrTab | 
					| contiguousGroups |
					contiguousGroups := self groupIntoContiguous collect: #key.
					GtSpotterDropdownButtonStencil new
						icon: BrGlamorousVectorIcons note;
						label: 'Add Note';
						tooltip: 'Link Lepiter page to all items in collection';
						object: TtLepiterPageSearchStart new;
						actOn: [ :anActOnEvent :anItem :aDropdownButton | 
							| aPage note viewElement |
							viewElement := aDropdownButton phlow firstParentWithViewContent phlow
									firstChildWithViewContent.
							anActOnEvent beActed.
							aPage := (anItem isKindOf: LePage)
									ifTrue: [ anItem ]
									ifFalse: [ anItem createWithoutPager ].
							(contiguousGroups
								allSatisfy: [ :aGroup | 
									self noteToTrackedTimeAssociations
										detect: [ :existingNote | (existingNote key as: Timespan) = aGroup and: [ existingNote key page = aPage ] ]
										ifFound: [ true ]
										ifNone: [ false ] ])
								ifTrue: [  ];
								ifFalse: [ contiguousGroups
										do: [ :aTimespan | 
											note := TtNote new
													start: aTimespan start;
													duration: aTimespan duration;
													database: aPage database;
													page: aPage;
													collection: self rootCollection.
											self rootCollection add: note ].
									aDropdownButton
										enqueueTask: [ (self perform: #gtNotesFor: withArguments: {GtPhlowEmptyView new})
												updateContent: viewElement ] asBlTask ].
							aDropdownButton fireEvent: BrDropdownHideWish new.
							aDropdownButton phlow spawnTool: aPage asLepiterPagePhlowTool ] ] ];
		action: [ :anAction | 
			anAction button
				icon: BrGlamorousVectorIcons inspect;
				tooltip: 'Inspect Note Objects';
				action: [ :aBrButton :aBrTab | 
					aBrButton phlow
						spawnObject: ((self noteToTrackedTimeAssociations collect: #key) groupedBy: #page) ] ];
		expandAll
]

{ #category : #'gt - advice' }
TtEventCollection >> gtRecategorizeAdviceFor: aGtAdvice [
	<gtAdvice>
	| categorizedWithPlaceholder |
	categorizedWithPlaceholder := self
			select: [ :each | each category ifNil: [ false ] ifNotNil: [ :notNil | notNil isPlaceholder ] ].
	categorizedWithPlaceholder ifEmpty: [ ^ aGtAdvice none ].
	^ aGtAdvice item
		priority: -50;
		description: [ :class | 
			'Collection has placeholder categories. Please categorize these entries.'
				asRopedText ];
		compute: [ categorizedWithPlaceholder ];
		action: [ :class | GtPhlowObjectAdviceAction object: categorizedWithPlaceholder ]
]

{ #category : #search }
TtEventCollection >> gtSearchFor: aSearch [
	<gtSearch>
	self flag: #TODO.	"Need to fix nesting into categories, play with methods like GtSpotterSearch>>#categoryToActOn:from:"
	^ aSearch list
		priority: 1;
		title: 'Search by Tracked Time entries';
		items: [ self timeEntries ];
		itemName: [ :each | 
			each start asDate yyyymmdd , ' | ' , each description
				, (each details ifNotNil: [ :notNil | ': ' , notNil ] ifNil: [ '' ]) ];
		send: [ :aRawObject :aStep :thisSearch | 
			TtEventCollection new
				categories: self categories;
				page: self page;
				add: aRawObject;
				viewFilterContext: self viewFilterContext;
				yourself ];
		sendCategory: [ :aCategory :aStep :thisSearch | 
			| context |
			context := {aCategory.
					aStep.
					thisSearch}.
			(TtEventCollection withAll: aCategory items contents)
				categories: self categories;
				page: self page;
				viewFilterContext: self viewFilterContext ];
		previewElement: [ :aTrackedTime | (aTrackedTime gtPreviewFor: GtPhlowEmptyView new) asElement ];
		filterBySubstring;
		wantsToDisplayOnEmptyQuery: true
]

{ #category : #views }
TtEventCollection >> gtSummaryFor: aView context: aContext [
	<gtView>
	| groupingLevelLabel groupingLevelLabelMapping |
	groupingLevelLabelMapping := {'Original' -> 0.
			'2nd Level' -> 1.
			'3rd level' -> 2.
			'4th Level' -> 3.
			'5th Level' -> 4.
			'Top Level' -> #topMostCategory}.
	groupingLevelLabel := [ 'Grouping ('
			, (groupingLevelLabelMapping detect: [ :each | each value = self groupingLevel ])
					key , ')' ].
	aContext navigation previousContext
		ifNotNil: [ :notNil | 
			((notNil object isKindOf: TtEventCollection)
				and: [ notNil object == self rootCollection ])
				ifTrue: [ groupingLevel isSymbol
						ifTrue: [ self groupingLevel: 0.
							self includeUntracked: false ] ] ].
	self groupedByCategory keys size = (1 + self includeUntracked asBit)
		ifTrue: [ self includeUntracked: true ].
	^ aView explicit
		title: ((self groupedBy: #asWeek) keys size = 1
				ifTrue: [ 'Weekly Summary' ]
				ifFalse: [ 'Summary' ]);
		priority: 0;
		stencil: [ | dailySummary data entriesByDay horizontalPane resizer verticalPane |
			data := self calculateAnglesForDonut.
			horizontalPane := BrHorizontalPane new
					vFitContent;
					hMatchParent;
					alignCenter.
			dailySummary := self buildDailySummary: data.
			resizer := BrResizer new
					aptitude: BrGlamorousResizerAptitude;
					elevation: (BlRelativeElevation elevation: 1000);
					beBottom;
					target: dailySummary.
			entriesByDay := self buildEntriesByDay: aContext.
			horizontalPane
				addChildren: {self buildDonut: data.
						self buildBars: data}.
			verticalPane := BrVerticalPane new
					id: #gtSummaryFor:context:;
					matchParent;
					alignCenter;
					addChildren: {horizontalPane.
							dailySummary.
							resizer.
							entriesByDay}.
			verticalPane ];
		actionButtonLabel: 'Toggle Untracked'
			action: [ :aButton :aBrTab | 
				self toggleUntracked.
				(self gtSummaryFor: GtPhlowEmptyView new context: aContext)
					updateContent: aBrTab viewContentElement ];
		actionDropdownButtonLabel: groupingLevelLabel value
			content: [ :aButton :aBrTab | 
				BrSimpleList new
					margin: (BlInsets all: 5);
					items: groupingLevelLabelMapping;
					itemStencil: [ BrLabel new hMatchParent
							aptitude: BrGlamorousLabelAptitude + BrGlamorousListItemAptitude ];
					itemDataBinder: [ :aLabel :aViewFilter | 
						aLabel
							text: aViewFilter key;
							when: BlClickEvent
								do: [ :_ | 
									aButton fireEvent: BrDropdownHideWish new.
									self groupingLevel: aViewFilter value.
									aButton label: groupingLevelLabel value.
									(self gtSummaryFor: GtPhlowEmptyView new context: aContext)
										updateContent: aBrTab viewContentElement ] ] ];
		actionDropdownButtonLabel: 'Group By'
			content: [ :aButton :aBrTab | 
				| groupByLabelMapping |
				groupByLabelMapping := {'Group by Category' -> #Category.
						'Group by Recurrence' -> #IsRecurring.
						'Group by Planned' -> #IsPlanned.
						'Group by Re-scheduled' -> #FirstTimeScheduled}.
				BrSimpleList new
					margin: (BlInsets all: 5);
					items: groupByLabelMapping;
					itemStencil: [ BrLabel new hMatchParent
							aptitude: BrGlamorousLabelAptitude + BrGlamorousListItemAptitude ];
					itemDataBinder: [ :aLabel :aViewFilter | 
						aLabel
							text: aViewFilter key;
							when: BlClickEvent
								do: [ :_ | 
									aButton fireEvent: BrDropdownHideWish new.
									self viewFilterContext: aViewFilter value.
									(self gtSummaryFor: GtPhlowEmptyView new context: aContext)
										updateContent: aBrTab viewContentElement ] ] ]
]

{ #category : #inspecting }
TtEventCollection >> gtTrackedDaysFor: anAction context: aContext [
	<gtAction>
	| isSingleCategory |
	isSingleCategory := self groupedByCategory keys size = 2.
	^ anAction button
		priority: 0.25;
		label: (self groupedByDay keys
				in: [ :days | 
					| firstDay lastDay trackedDays totalDays |
					firstDay := days min.
					lastDay := days max.
					trackedDays := days size.
					totalDays := (days max - days min) days + 1.
					isSingleCategory
						ifTrue: [ | totalTrackedDays |
							totalTrackedDays := ((aContext navigation previousContext isNil
									or: [ (aContext navigation previousContext object isKindOf: TtEventCollection) not ])
									ifTrue: [ self rootCollection ]
									ifFalse: [ aContext navigation previousContext object ]) groupedByDay
									keys size.
							trackedDays asString , '/' , totalTrackedDays asString , ' tracked ('
								, (trackedDays / totalTrackedDays * 100 roundTo: 1) asString , '%)' ]
						ifFalse: [ trackedDays asString , '/' , totalDays asString , ' tracked ('
								, (trackedDays / totalDays * 100 roundTo: 1) asString , '%)' ] ])
]

{ #category : #accessing }
TtEventCollection >> gtWeekFor: anAction [
	<gtAction>
	^ anAction dropdown
		icon: [ BrGlamorousVectorIcons timeTrackerCalendar asElement asScalableElement
				size: 20 @ 20 ] asStencil;
		tooltip: 'Select a Week to Analyze';
		priority: 1;
		content: [ :aButton | 
			| firstDate element |
			firstDate := nil.
			element := MyGtCalendarElement
					forDate: self rootCollection groupedByDay keys max.
			element
				when: GtCalendarDateClickedEvent
					do: [ :anEvent | 
						anEvent consumed: true.
						aButton fireEvent: BrDropdownHideWish new.
						aButton phlow
							spawnObject: (self rootCollection weekFromDate: anEvent date) ];
				when: GtCalendarDateClickedWithModifiersEvent
					do: [ :anEvent | 
						anEvent modifiers = BlKeyModifiers shift
							ifTrue: [ firstDate
									ifNil: [ firstDate := anEvent date ]
									ifNotNil: [ | sortedDates |
										sortedDates := {firstDate.
												anEvent date} sorted: #yourself ascending.
										aButton fireEvent: BrDropdownHideWish new.
										aButton phlow
											spawnObject: (self rootCollection
													select: [ :each | 
														each start asDate >= sortedDates first
															and: [ each start asDate <= sortedDates second ] ]).
										firstDate := nil ].
								anEvent consumed: true ] ] ]
]

{ #category : #accessing }
TtEventCollection >> hourlyTicksElement [
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

{ #category : #import }
TtEventCollection >> importFromTrello [
	| response daysToImport existingDays |
	self flag: #TODO.	"This should eventually call a properly configured class that implements a trait that knows how to import data"
	[ response := TtTrelloImporter fetch ] on: NameLookupFailure do: [ ^ self ].
	self rootCollection loadFromLepiter.
	existingDays := (self rootCollection
			collect: [ :each | each start asDate ]
			as: Set) asArray sorted: #yourself descending.
	daysToImport := ((response keys reject: [ :each | each = Date today ])
			difference: existingDays) asArray sorted: #yourself ascending.
	daysToImport
		select: [ :each | [ each < existingDays first ] on: SubscriptOutOfBounds do: [ false ] ]
		thenDo: [ :each | self inform: 'Date: ' , each asString , ' may be a typo as it is historical.' ].
	daysToImport
		do: [ :day | 
			TtTrelloParser new
				add: (response associationAt: day)
				toCollection: self rootCollection ]
]

{ #category : #accessing }
TtEventCollection >> includeUntracked [
	^ includeUntracked ifNil: [ includeUntracked := true ]
]

{ #category : #accessing }
TtEventCollection >> includeUntracked: aBoolean [
	includeUntracked := aBoolean
]

{ #category : #accessing }
TtEventCollection >> items [
	^ items ifNil: [
		items := SortedCollection new ]
]

{ #category : #views }
TtEventCollection >> labelFormatX [
^ [ :each | 
						(self groupedBy: #asWeek) keys size
							in: [ :size | 
								size > 1
									ifTrue: [ (each asMonth
											in: [ :aMonth | aMonth year asString , '-' , (aMonth monthName first: 3) ])
											, '-Wk'
											, (each asMonth weeks detectIndex: [ :inner | inner includes: each ]) asString ]
									ifFalse: [ each asDate
											in: [ :aDate | 
												(aDate weekday first: 3) , ', ' , (aDate month monthName first: 3) , ' '
													, aDate dayOfMonth asString ] ] ] ]
]

{ #category : #accessing }
TtEventCollection >> latestWeek [
	^ self rootCollection weekFromDate: self rootCollection groupedByDay keys max
]

{ #category : #accessing }
TtEventCollection >> loadCategories [
	self page children
		detect: [ :aSnippet | aSnippet isKindOf: TtCategoriesSnippet ]
		ifFound: [ :aCategorySnippet | 
			| someCategories |
			someCategories := (TtCategories
					fromRoot: (NeoJSONReader
							fromString: aCategorySnippet jsonString
							as: CategorySnippetDeserializer) data) collection: self.
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
				select: [ :each | self class supportedSnippetTypes includes: each class ]
				thenDo: [ :each | 
					self
						add: ((NeoJSONReader fromString: each jsonString as: each class deserializerClass)
								data
								in: [ :aTimeTrackerObject | 
									aTimeTrackerObject
										uid: each uidString;
										collection: self.
									each domainObject: aTimeTrackerObject.
									aTimeTrackerObject ]) ].
			self serializeCollection ]
]

{ #category : #accessing }
TtEventCollection >> loadPage [
	^ page
		ifNil: [ [ page := self perform: #customPage ]
				on: MessageNotUnderstood
				do: [ page := self defaultPage ] ]
]

{ #category : #filtering }
TtEventCollection >> noteToTrackedTimeAssociations [
	^ self rootCollection notes asArray
		collect: [ :aTtNote | 
			aTtNote
				-> (self timeEntries asArray
						select: [ :aTtTrackedTime | aTtNote includes: aTtTrackedTime ]) ]
		thenSelect: [ :each | each value isNotEmpty ]
]

{ #category : #accessing }
TtEventCollection >> notes [
	^ self select: #isNote
]

{ #category : #accessing }
TtEventCollection >> page [
	^ page
]

{ #category : #accessing }
TtEventCollection >> page: aLepiterPage [
	page := aLepiterPage
]

{ #category : #accessing }
TtEventCollection >> pomodoros [
	^ self select: #isPomodoro
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
		categories: self categories;
		viewFilterContext: self viewFilterContext;
		includeUntracked: self includeUntracked;
		groupingLevel: self groupingLevel
]

{ #category : #accessing }
TtEventCollection >> rootCollection [
	^ self class pageRegistry at: self page
]

{ #category : #enumerating }
TtEventCollection >> select: aBlock [
	^ (self species withAll: (self items select: aBlock))
		page: self page;
		categories: self categories;
		viewFilterContext: self viewFilterContext;
		includeUntracked: self includeUntracked;
		groupingLevel: self groupingLevel
]

{ #category : #import }
TtEventCollection >> serializeCollection [
	self items isValueHolder
		ifFalse: [ items := self items asValueHolder.
			items whenAddedDo: [ :newValue | self class serializeWithLepiter: newValue ] ]
]

{ #category : #accessing }
TtEventCollection >> thisWeek [
	| lastSunday today |
	today := Date today.
	lastSunday := (today
			- (today weekdayIndex - 1 = 0 ifTrue: [ 7 ] ifFalse: [ today weekdayIndex - 1 ])
					days) asDate.
	^ self select: [ :each | each start asDate > lastSunday ]
]

{ #category : #accessing }
TtEventCollection >> timeEntries [
	^ self select: #isTimeEntry
]

{ #category : #views }
TtEventCollection >> toggleUntracked [
	self includeUntracked.
	includeUntracked := includeUntracked not
]

{ #category : #accessing }
TtEventCollection >> valueHolder: anObject [
	collection := anObject
]

{ #category : #accessing }
TtEventCollection >> viewFilterContext [
	^ viewFilterContext ifNil: [ viewFilterContext := #Category ]
]

{ #category : #accessing }
TtEventCollection >> viewFilterContext: anObject [
	viewFilterContext := anObject
]

{ #category : #accessing }
TtEventCollection >> weekFromDate: aDate [
	| lastSunday nextMonday today thisWeek|
"	today := aDate.
	lastSunday := (today
			- (today weekdayIndex - 1 = 0 ifTrue: [ 7 ] ifFalse: [ today weekdayIndex - 1 ])
					days) asDate.
	nextMonday := (lastSunday + 8 days) asDate.
	^ self
		select: [ :each | each start asDate > lastSunday and: [ each start asDate < nextMonday ] ]"
	thisWeek := aDate asMonth weeks detect: [:aWeek | aWeek includes: aDate].
	^ self select: [:each| thisWeek includes: each ]
]

{ #category : #'instance - creation' }
TtEventCollection >> withAll: aCollection [
	^ self class new
		page: self page;
		categories: self categories;
		viewFilterContext: self viewFilterContext;
		includeUntracked: self includeUntracked;
		groupingLevel: self groupingLevel;
		addAll: aCollection
]
