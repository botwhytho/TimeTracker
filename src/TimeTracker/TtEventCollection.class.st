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
		'groupingLevel',
		'categoryPicker',
		'categoryContext'
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
		column: 'Page' text: [ :each | each key title ] spawn: [:anAssociation :index | anAssociation key] ;
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
	| aBarWidthScale barChart categoriesToFilter categoriesToFilterOut container maxLines theData totalTime |
	categoriesToFilter := OrderedCollection new.
	categoriesToFilterOut := OrderedCollection new.
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
				aptitude: (BrGlamorousWithExplicitTooltipAptitude new
						text: (aGtPlotterContext originalValue
								in: [ :helper | 
									(helper sum / self groupedByDay keys size roundUpTo: 1 minute) asString
										, ' avg, '
										, ((helper sum / (helper collection groupedByDay keys size max: 1)) roundUpTo: 1 minute)
												asString , '/day, '
										, ((helper sum roundUpTo: 1 minute) asHours round: 1) asString
										, ' total' ]));
				when: BlClickEvent
					do: [ :aBlClickEvent | 
						aBlClickEvent consumed: true.
						aBlClickEvent modifiers = BlKeyModifiers alt
							ifTrue: [ aBlClickEvent target phlow
									spawnObject: (self timeEntries
											select: [ :aTrackedTime | 
												(aTrackedTime category
													hasCategoryOrParentCategoryNamed: aGtPlotterContext originalValue category name)
													not ]) ].
						aBlClickEvent modifiers isShift
							ifTrue: [ aBlClickEvent modifiers isAlt
									ifTrue: [ categoriesToFilterOut add: aGtPlotterContext originalValue category ]
									ifFalse: [ categoriesToFilter add: aGtPlotterContext originalValue category ] ].
						aBlClickEvent modifiers = BlKeyModifiers new
							ifTrue: [ categoriesToFilter isEmpty & categoriesToFilterOut isEmpty
									ifTrue: [ aBlClickEvent currentTarget phlow
											spawnObject: aGtPlotterContext originalValue collection ]
									ifFalse: [ categoriesToFilter
											ifNotEmpty: [ categoriesToFilter add: aGtPlotterContext originalValue category.
												aBlClickEvent target phlow
													spawnObject: (self timeEntries
															select: [ :aTrackedTime | 
																categoriesToFilter
																	anySatisfy: [ :aCategory | aTrackedTime category hasCategoryOrParentCategoryNamed: aCategory name ] ]) ]
											ifEmpty: [ categoriesToFilterOut
													add: aGtPlotterContext originalValue category.
												aBlClickEvent target phlow
													spawnObject: (self timeEntries
															reject: [ :aTrackedTime | 
																categoriesToFilterOut
																	anySatisfy: [ :aCategory | aTrackedTime category hasCategoryOrParentCategoryNamed: aCategory name ] ]) ].
										categoriesToFilter removeAll.
										categoriesToFilterOut removeAll ] ] ];
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
							action: [ :aBrButton :aBrButtonModel :aBlClickEvent | aBrButton phlow spawnObject: (self withAll: (each value collect: #value)) ];
							actionWithModifiers: [ :aBrButton :aBrButtonModel :aBlClickEvent | 
								aBlClickEvent modifiers = BlKeyModifiers alt
									ifTrue: [ aBrButton phlow
											spawnObject: (self
													reject: [ :aTrackedTime | aTrackedTime start asDate asDateAndTime asUTC = each key asDateAndTime asUTC ]) ] ] ] ]
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
	| element categoriesToFilter categoriesToFilterOut |
	categoriesToFilter := OrderedCollection new.
	categoriesToFilterOut := OrderedCollection new.
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
							do: [ :aBlClickEvent | 
								aBlClickEvent consumed: true.
								aBlClickEvent modifiers = BlKeyModifiers alt
									ifTrue: [ aBlClickEvent target phlow
											spawnObject: (self timeEntries
													select: [ :aTrackedTime | (aTrackedTime category hasCategoryOrParentCategoryNamed: each category name) not ]) ].
								aBlClickEvent modifiers isShift
									ifTrue: [ aBlClickEvent modifiers isAlt
											ifTrue: [ categoriesToFilterOut add: each category ]
											ifFalse: [ categoriesToFilter add: each category ] ].
								aBlClickEvent modifiers = BlKeyModifiers new
									ifTrue: [ categoriesToFilter isEmpty & categoriesToFilterOut isEmpty
											ifTrue: [ aBlClickEvent target phlow spawnObject: each collection ]
											ifFalse: [ categoriesToFilter
													ifNotEmpty: [ categoriesToFilter add: each category.
														aBlClickEvent target phlow
															spawnObject: (self timeEntries
																	select: [ :aTrackedTime | 
																		categoriesToFilter
																			anySatisfy: [ :aCategory | aTrackedTime category hasCategoryOrParentCategoryNamed: aCategory name ] ]) ]
													ifEmpty: [ categoriesToFilterOut add: each category.
														aBlClickEvent target phlow
															spawnObject: (self timeEntries
																	reject: [ :aTrackedTime | 
																		categoriesToFilterOut
																			anySatisfy: [ :aCategory | aTrackedTime category hasCategoryOrParentCategoryNamed: aCategory name ] ]) ].
												categoriesToFilter removeAll.
												categoriesToFilterOut removeAll ] ] ];
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
			, (self timeEntries groupedByDay keys
					collect: [ :each | Timespan starting: each duration: each asDuration ]).
	self flag: #EXPENSIVE.	"Should we cache the below calculation?"
	notes := self rootCollection notes asArray
			flatCollect: [ :each | 
				timeEntriesAndDays
					select: [ :inner | each includes: inner ]
					thenCollect: [ :inner | inner -> each ] ].
	self categoryPicker
		ifNil: [ self
				categoryContext: (GtPhlowContext new
						at: #TtTrackedTime put: nil;
						yourself).
			self
				categoryPicker: ((self categories
						TtCategoriesFor: GtPhlowView empty
						context: self categoryContext) asElement
						when: BlElementRemovedFromSceneGraphEvent
						do: [ :anEvent | anEvent currentTarget removeFromParent ]) ].
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
				self flag: #TODO.	"Wrap category view in domain object, have a unique Instance and re-use/cache?"
				each isAssociation
					ifTrue: [ BlElement new size: 1 @ 1 ]
					ifFalse: [ | aButton |
						aButton := BrButton new.
						aButton
							aptitude: BrGlamorousButtonWithIconAndLabelAptitude
									+ (BrWithExplicitDropdownAptitude new
											withoutHandle;
											stencil: [ BrMenuExplicit new
													stencil: [ :anExplicitMenu | 
														self categoryContext
															at: #TtTrackedTime
															put: {self.
																	each.
																	aButton.
																	anExplicitMenu}.
														BrFrame new
															size: ((GtWorld spaceWithId: GtWorld defaultId do: #yourself) extent
																	in: [ :screenSize | (screenSize x * 0.45) @ screenSize y * 0.9 ]);
															padding: (BlInsets all: 15);
															addChild: self categoryPicker asElement ] ]).
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
								each value do: [ :aTrackedTime | self items remove: aTrackedTime ].
								aBrButton phlow fireToolUpdateWish ] ]
					ifFalse: [ BlElement new size: 1 @ 1 ] ];
		send: [ :each | each isAssociation ifTrue: [ each value ] ifFalse: [ each ] ];
		expandAll;
		asElementDo: [ :element | 
			self timeEntries
				detect: [ :each | each category isNil ]
				ifFound: [ :aTrackedTime | 
					| anIndex aBrTree indexInTree |
					anIndex := self timeEntries items identityIndexOf: aTrackedTime.
					aBrTree := element childAt: 2.
					indexInTree := anIndex + aBrTree viewModel root value size.
					aBrTree
						scrollToIndex: (indexInTree - 3 - entriesByDay size max: 1);
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

{ #category : #accessing }
TtEventCollection >> categoryContext [
	^ categoryContext
]

{ #category : #accessing }
TtEventCollection >> categoryContext: anObject [
	categoryContext := anObject
]

{ #category : #accessing }
TtEventCollection >> categoryPicker [
	^ categoryPicker
]

{ #category : #accessing }
TtEventCollection >> categoryPicker: anObject [
	categoryPicker := anObject
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
							| concurrentEntries sizeOfOtherEntriesInRootCollection |
							concurrentEntries := aGtPlotterSingleScaleContext originalValue value asOrderedCollection
									sorted: [ :each | each key name ] ascending.

							(concurrentEntries size = 1
								and: [ sizeOfOtherEntriesInRootCollection := ((self rootCollection
											allEqualTo: concurrentEntries first value) select: #isTimeEntry) size.
									sizeOfOtherEntriesInRootCollection  > 0 ])
								ifTrue: [ sizeOfOtherEntriesInRootCollection
										timesRepeat: [ concurrentEntries add: nil -> nil ] ].
							concurrentEntries
								do: [ :aTtTrackedTime | 
									| element |
									element := BlElement new
											constraintsDo: [ :c | 
												c vertical matchParent.
												c horizontal matchParent ];
											border: (BlBorder paint: Color darkGray width: 0.5);
											background: (aTtTrackedTime key ifNil: [ Color transparent ] ifNotNil: #color).
									aBrVerticalPane addChild: element ].
							aBrVerticalPane ]);
				when: BlClickEvent
					do: [ :anEvent | 
						| newCollection someTrackedTimes |
						someTrackedTimes := aGtPlotterSingleScaleContext originalValue value value.
						self flag: #TODO.	"Pass other context like in select: or use proper pager contexts and remove from over there"
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
					sum: (anAssociation value items sum: self partialDurationWhenMultiTasking) ].
	summedGroupings
		detect: [ :each | each category = TtCategories untracked ]
		ifFound: [ :found | 
			found
				sum: self timeEntries groupedByDay keys size days - groupedByTimespan keys sum ]
		ifNone: [  ].
	^ summedGroupings sorted: #sum descending
]

{ #category : #accessing }
TtEventCollection >> groupedBy: aBlock [
	"Override this method here and not reuse the one in collection
	because we want the keys to be groups, not simple collections"

	| result |
	result := OrderedDictionary new.
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
	grouped := self timeEntries
			groupedBy: [ :each | 
				each category
					ifNil: [ TtCategories uncategorized ]
					ifNotNil: [ :aCategory | 
						self groupingLevel isSymbol
							ifTrue: [ aCategory topMostCategory ]
							ifFalse: [ aCategory moveUpHierarchy: self groupingLevel ] ] ].
	daysWithUntrackedTime := self timeEntries groupedByDay associations
			select: [ :anAssociation | 
				(anAssociation value
					groupedBy: [ :each | each value as: each value class superclass ]) keys sum
					< 1 day ]
			thenCollect: #key.
	self includeUntracked
		ifTrue: [ daysWithUntrackedTime
				ifNotEmpty: [ grouped
						at: TtCategories untracked
						put: (self timeEntries select: [ :each | daysWithUntrackedTime includes: each start asDate ]) ] ].
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
	^ self groupedBy: [ :each | each start asDate translateToUTC ]
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
TtEventCollection >> groupedByMonth [
	^ self groupedBy: [ :each | each start asMonth translateToUTC ]
]

{ #category : #'accessing - grouping' }
TtEventCollection >> groupedByTimespan [
	^ self groupedBy: #asTimespan
]

{ #category : #'accessing - grouping' }
TtEventCollection >> groupedByWeek [
	^ self groupedBy: [ :each | each start asWeek translateToUTC ]
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
	self flag: #TODO.	"Improve calendar view when sparse"
	self groupedByCategory keys size > 2 ifTrue: [ ^ aView empty ].
	^ aView explicit
		title: 'Calendar View';
		priority: 4;
		stencil: [ | grid months |
			months := self groupedByMonth.
			grid := BrHorizontalGrid new
					matchParent;
					columnCount: 3.
			months keys min index % 3
				in: [ :anIndex | 
					anIndex ~= 1
						ifTrue: [ ((2 - (months keys min index % 3) + 2) / 3.0) ceiling
								timesRepeat: [ grid addChild: (BlElement new size: 0 @ 0) ] ] ].
			grid
				addChildren: ((months associations sorted: #key ascending)
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
		items: [ (self timeEntries groupedBy: [ :each | each description capitalized ])
				associations
				sorted: [ :each | each value items sum: self partialDurationWhenMultiTasking ]
						descending ];
		column: 'Activity' text: #key;
		column: 'Category' text: [ :each | each value first category name ];
		column: 'Ocurrences' text: [ :each | each value size ];
		column: 'Average Time'
			text: [ :each | 
				(each value items sum: self partialDurationWhenMultiTasking)
					/ each value items size roundTo: 1 minute ];
		column: 'Total Time'
			text: [ :each | 
				((each value items sum: self partialDurationWhenMultiTasking) roundTo: 1 minute)
					in: [ :aDuration | aDuration asString , ' (' , (aDuration asHours round: 1) asString , ' hours)' ] ];
		send: #value
]

{ #category : #views }
TtEventCollection >> gtGroupedByDetailFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Grouped By Detail';
		priority: 1;
		items: [ (self timeEntries
				groupedBy: [ :each | 
					{each description capitalized.
						each details ifNil: [ '' ] ifNotNil: [ :notNil | notNil capitalized ]} ])
				associations
				sorted: [ :each | each value items sum: self partialDurationWhenMultiTasking ]
						descending ];
		column: 'Activity' text: [ :each | each key first ];
		column: 'Details' text: [ :each | each key second ];
		column: 'Category' text: [ :each | each value first category name ];
		column: 'Ocurrences' text: [ :each | each value size ];
		column: 'Average Time'
			text: [ :each | 
				(each value items sum: self partialDurationWhenMultiTasking)
					/ each value items size roundTo: 1 minute ];
		column: 'Total Time'
			text: [ :each | 
				((each value items sum: self partialDurationWhenMultiTasking) roundTo: 1 minute)
					in: [ :aDuration | aDuration asString , ' (' , (aDuration asHours round: 1) asString , ' hours)' ] ];
		send: #value
]

{ #category : #views }
TtEventCollection >> gtIdealTimeUsageFor: aView context: aContext [
	<gtView>
	| weeks |
	weeks := self groupedByWeek.
	weeks keys size > 1
		ifTrue: [ ^ self gtIdealTimeUsageMultipleWeeks: aView context: aContext ]
		ifFalse: [ ^ self gtIdealTimeUsageSingleWeek: aView context: aContext ]
]

{ #category : #views }
TtEventCollection >> gtIdealTimeUsageMultipleWeeks: aView context: aContext [
	| ideals groupedByYearAndWeeks |
	groupedByYearAndWeeks := self groupedByWeek associations
			groupedBy: [ :each | each key year ].
	ideals := self ideals.
	^ aView columnedTree
		title: 'Ideals';
		priority: 0;
		items: [ groupedByYearAndWeeks associations ];
		children: [ :each | each key isInteger ifTrue: [ {each value -> nil} ] ifFalse: [ #() ] ];
		column: 'Year'
			text: [ :each | each key isInteger ifTrue: [ each key asString ] ifFalse: [ '' ] ];
		column: 'Weeks'
			stencil: [ :each | 
				each key isInteger
					ifTrue: [ BlElement new size: 0 @ 0 ]
					ifFalse: [ | container weeks |
						container := BlElement new
								layout: (BlGridLayout horizontal columnCount: 7);
								constraintsDo: [ :c | 
									c vertical fitContent.
									c horizontal fitContent ].
						weeks := (1 to: 53)
								collect: [ :anInteger | Week year: each key first key year week: anInteger ].
						weeks
							doWithIndex: [ :aWeek :anIndex | 
								container
									addChild: (BrVerticalPane new alignTopCenter
											size: 100 @ 100;
											margin: (BlInsets all: 5);
											in: [ :aVerticalPane | 
												| association |
												(each key
													detect: [ :anAssociation | 
														anAssociation key start asDate yyyymmdd
															= (aWeek start asDate - 1 day) start asDate yyyymmdd ]
													ifFound: [ :found | 
														association := found.
														true ]
													ifNone: [ false ])
													ifTrue: [ | idealsModifiedInThisWeek |
														idealsModifiedInThisWeek := ideals
																anySatisfy: [ :anIdeal | 
																	(aWeek start asDate - 1 day) start asDate yyyymmdd
																		= anIdeal start asDate yyyymmdd ].
														aVerticalPane
															border: Color black asBlBorder;
															addChildren: {BlTextElement new
																		margin: (BlInsets all: 5);
																		zIndex: 100;
																		text: (((idealsModifiedInThisWeek ifTrue: [ '*' ] ifFalse: [ '' ]) , 'Week '
																				, anIndex asString) asRopedText fontSize: 16).
																	BlTextElement new
																		margin: (BlInsets all: 5);
																		zIndex: 100;
																		text: (association key start asDate yyyymmdd asRopedText fontSize: 12).
																	BlTextElement new
																		margin: (BlInsets all: 5);
																		zIndex: 100;
																		text: (self weeklyIdealGrade: association value) asRopedText};
															when: BlClickEvent
																do: [ :aClickEvent | 
																	aClickEvent consumed: true.
																	aClickEvent target phlow spawnObject: association value ].
														(ideals
															anySatisfy: [ :anIdeal | (aWeek start asDate - 1 day) start asDate >= anIdeal start asDate ])
															ifTrue: [ aVerticalPane background: Color lightGreen ] ].
												aVerticalPane ]) ].

						container ] ]
			weight: 6;
		expandAll
]

{ #category : #views }
TtEventCollection >> gtIdealTimeUsageSingleWeek: aView context: aContext [
	| activeIdeals daysWithData dynamicPriority groupedByIdeals ideals idealsWithNoTrackedTime |
	ideals := self ideals groupedBy: [ :each | each as: Timespan ].
	activeIdeals := (aContext at: 'ideals')
			ifNil: [ self ideals
					select: [ "ideals associations
					detect: [ :each | each key includes: self first start ]
					ifFound: [ :found | found value ]
					ifNone: [ ideals associations last value ]" :each | each duration = Duration zero ] ]
			ifNotNil: #yourself.
	self flag: #BUG.	"Need to take into account parallel time entries. Not fractionally counting and worse, if two parallel tasks match the ideal, they may be counted as 4 times the duration?"
	groupedByIdeals := self timeEntries
			groupedBy: [ :aTrackedTime | 
				activeIdeals
					detect: [ :anIdeal | 
						anIdeal category
							ifNil: [ anIdeal computation value: aTrackedTime ]
							ifNotNil: [ :notNil | (aTrackedTime category ifNil: [ TtCategory new ]) = notNil ] ]
					ifNone: [ 'Time Without Ideals' ] ].
	self flag: #HACK.	"Using NeoJSONObject's override of DNU for duck typing for when no time has been categorized as the category in an ideal. Clean up with smarter domain objects"
	idealsWithNoTrackedTime := (activeIdeals difference: groupedByIdeals keys)
			collect: [ :each | 
				each
					-> ({'items'
								-> ({{'duration' -> 0 minutes} asDictionary as: NeoJSONObject} as: NeoJSONArray)}
							asDictionary as: NeoJSONObject) ].
	groupedByIdeals := (groupedByIdeals associations , idealsWithNoTrackedTime)
			asOrderedDictionary.
	groupedByIdeals size < 2 ifTrue: [ ^ aView empty ].
	daysWithData := self groupedByDay keys size.
	dynamicPriority := (aContext navigationContext withAllNavigationContexts second
			gtOverview allSatisfy: [ :each | each value isNil ])
			ifTrue: [ -5 ]
			ifFalse: [ 0 ].
	^ aView columnedList
		title: 'Ideals';
		priority: dynamicPriority;
		items: [ groupedByIdeals associations ];
		column: 'Ideal Time Usage'
			text: [ :each | 
				each key isString
					ifTrue: [ each key ]
					ifFalse: [ each key category
							ifNil: [ each key description ]
							ifNotNil: [ :notNil | notNil name ] ] ]
			weight: 0.75;
		column: 'Progress'
			text: [ :each | 
				| progressPercent dailyCatchupAmount |
				each key isString
					ifTrue: [ | hoursPerDay percentWithIdeals percentWithoutIdeals roomForImprovement string totalHours |
						totalHours := each value items sum: self partialDurationWhenMultiTasking.
						hoursPerDay := (totalHours / daysWithData) asHours.
						percentWithoutIdeals := hoursPerDay / 24.
						string := 'Time without ideals is '
								, (hoursPerDay printShowingDecimalPlaces: 2) , ' hours/day ('
								, (percentWithoutIdeals * 100) asInteger asString , '%)'.
						percentWithIdeals := (groupedByIdeals keys reject: #isString)
								sum: #minValue.
						roomForImprovement := percentWithIdeals - (1 - percentWithoutIdeals).
						roomForImprovement > 0
							ifTrue: [ string := string , '. '
										, (roomForImprovement * 24 printShowingDecimalPlaces: 2)
										, ' hours/day were not used ideally.' ].
						string ]
					ifFalse: [ progressPercent := ((each value items
								sum: self partialDurationWhenMultiTasking) / daysWithData days) asFloat
								/ each key minValue.
						dailyCatchupAmount := daysWithData days
								* ((1 - progressPercent) * each key minValue)
								/ (each key timePeriod asDays - daysWithData
										in: [ :aNumber | aNumber = 0 ifTrue: [ 1 ] ifFalse: [ aNumber ] ]).
						self flag: #NOTE.	"The hours 'not used ideally' may be actually higher than calculated below if one goes past goals in some category. It subtracts, for now, from time without ideals that should be spent ideally"
						'You are tracking to '
							, (progressPercent * 100 printShowingDecimalPlaces: 2)
							, '% of your goal of '
							, ({each key minValue.
									each key maxValue} average * 24 printShowingDecimalPlaces: 2)
							, ' hours/day. '
							, (dailyCatchupAmount asHours printShowingDecimalPlaces: 2)
							, ' catch-up hours/day' ] ]
			weight: 1.75;
		column: 'Graphical Progress' stencil: self idealsDailyProgressBarChartStencil;
		send: #value;
		actionDropdownButtonLabel: 'Change Ideals'
			content: [ :aButton :aBrTab | 
				| groupByLabelMapping |
				self flag: #NOTE.	"Below displays odd list at the moment as defining ideals as 'latest' or ones with no duration, which may have different start dates. Later will wrap individual ideals in Ideals collection wrapper and use that."
				groupByLabelMapping := {'Ideal for Date range' -> nil}
						, (ideals associations
								collect: [ :each | 
									(each key start asDate yyyymmdd , ' - '
										, (each key duration isZero
												ifTrue: [ 'Today' ]
												ifFalse: [ each key end asDate yyyymmdd ])) -> each value ]).
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
									aContext at: 'ideals' put: aViewFilter value.
									aButton fireEvent: BrDropdownHideWish new.
									aButton phlow fireToolUpdateWish ] ] ]
]

{ #category : #import }
TtEventCollection >> gtImportActionFor: anAction context: aContext [
	<gtAction>
	self flag: #TODO.	"Generalize import through some type of interface"
	(aContext navigation previousContext
		ifNil: [ false ]
		ifNotNil: [ :notNil | notNil object isKindOf: TtEventCollection ])
		ifTrue: [ ^ anAction noAction ].
	^ anAction explicit
		priority: 0.5;
		stencil: [ :aBrTab | 
			BrButton new
				aptitude: BrGlamorousButtonWithIconAndLabelAptitude;
				icon: BrGlamorousVectorIcons inspect;
				label: 'Import';
				flag: #CAUTION;
				action: [ :aBrButton "The first 3 options in dropdown update an object inspector in place, implementation could break if Gt internals change" :aBrButtonModel :aBlClickEvent | 
					| aDropdownAptitude |
					aBrButton
						aptitudeDo: [ :anAptitude | 
							anAptitude
								withAllActorsBreadthFirstDo: [ :eachActor | 
									BrGlamorousWithExplicitDropdownAptitude = eachActor class
										ifTrue: [ aBrButton removeAptitude: eachActor ] ] ].
					aBrButton
						addAptitude: (aDropdownAptitude := BrGlamorousWithExplicitDropdownAptitude new
									withoutHandle;
									stencil: [ | aMenuItems |
										aMenuItems := BrMenuItems new.
										aMenuItems
											addItemLabel: 'Import Latest'
											action: [ | latestWeek |
												self importLatestFromTrello.
												latestWeek := self rootCollection latestWeek.
												self flag: #NOTE.	"The below assumes we DO NOT want overlapping times AND we don't have missing data. Good quick check for data entry errors on my end. This assumption may not hold for all users in all use cases"
												latestWeek groupIntoContiguous size > 1
													ifTrue: [ self
															inform: 'There are overlapping time entries in collection. Send `groupIntoContiguous` to collection to see the time where the error happens' ].
												aContext navigationContext object
													in: [ :aTtEventCollection | 
														aTtEventCollection class = TtEventCollection
															ifTrue: [ aTtEventCollection becomeForward: latestWeek.
																aBrButton phlow fireToolUpdateWish ] ].
												aDropdownAptitude hide ].
										aMenuItems
											addItemLabel: 'Import Earliest'
											action: [ | latestWeek |
												self importEarliestFromTrello.
												latestWeek := self rootCollection latestWeek.
												latestWeek groupIntoContiguous size > 1
													ifTrue: [ self
															inform: 'There are overlapping time entries in collection. Send `groupIntoContiguous` to collection to see the time where the error happens' ].
												aContext navigationContext object
													in: [ :aTtEventCollection | 
														aTtEventCollection class = TtEventCollection
															ifTrue: [ aTtEventCollection becomeForward: latestWeek.
																aBrButton phlow fireToolUpdateWish ] ].
												aDropdownAptitude hide ].
										aMenuItems
											addItemLabel: 'Import All'
											action: [ | latestWeek |
												self importAllFromTrello.
												latestWeek := self rootCollection latestWeek.
												latestWeek groupIntoContiguous size > 1
													ifTrue: [ self
															inform: 'There are overlapping time entries in collection. Send `groupIntoContiguous` to collection to see the time where the error happens' ].
												aContext navigationContext object
													in: [ :aTtEventCollection | 
														aTtEventCollection class = TtEventCollection
															ifTrue: [ aTtEventCollection becomeForward: latestWeek.
																aBrButton phlow fireToolUpdateWish ] ].
												aDropdownAptitude hide ].
										aMenuItems
											addItemLabel: 'List Pending Days'
											action: [ self unimportedDaysCalendar
													ifNotNil: [ :notNil | aBrButton phlow spawnObject: notNil ].
												aDropdownAptitude hide ].
										aMenuItems ]).
					aDropdownAptitude show ] ]
]

{ #category : #inspecting }
TtEventCollection >> gtInspectActionFor: anAction [
	<gtAction>
	^ anAction dropdown
		icon: BrGlamorousVectorIcons inspect;
		label: 'ALL TIME';
		tooltip: 'View ALL historical data';
		priority: 1;
		content: [ :aButton | 
			BrGlamorousSimpleContextMenuContent new
				items: {'ALL IN CURRENT DAYS'
							-> [ :e | 
								| days |
								days := self groupedByDay keys.
								e phlow
									spawnObject: (self rootCollection select: [ :each | days includes: each start asDate ]).
								e fireEvent: BrDropdownHideWish new ].
						'ALL IN CURRENT TIME RANGES'
							-> [ :e | 
								| timeRanges |
								timeRanges := self groupIntoContiguous collect: #key.
								e phlow
									spawnObject: (self rootCollection
											select: [ :each | timeRanges anySatisfy: [ :aTimespan | aTimespan includes: each ] ]).
								e fireEvent: BrDropdownHideWish new ].
						'ALL EXCLUDING CURRENT TIME RANGES'
							-> [ :e | 
								| timeRanges |
								timeRanges := self groupIntoContiguous collect: #key.
								e phlow
									spawnObject: (self rootCollection
											select: [ :each | timeRanges noneSatisfy: [ :aTimespan | aTimespan includes: each ] ]).
								e fireEvent: BrDropdownHideWish new ].
						'ALL TIME'
							-> [ :e | 
								e phlow spawnObject: self rootCollection.
								e fireEvent: BrDropdownHideWish new ]} ]
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
	self flag: #BUG.	"When you click on the collection tied to a note, more items appear on the list and the daily bar graph duplicates them"
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
									aBrButton phlow fireToolUpdateWish ].
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
	categorizedWithPlaceholder := self timeEntries
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

{ #category : #searching }
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
		priority: -1;
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
				aButton phlow fireViewUpdateWish ];
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
									aButton phlow fireViewUpdateWish ] ] ];
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
									aButton phlow fireViewUpdateWish ] ] ]
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
	^ anAction explicit
		priority: 1;
		stencil: [ :aBrTab | 
			BrButton new
				aptitude: BrGlamorousButtonWithIconAptitude;
				icon: [ BrGlamorousVectorIcons timeTrackerCalendar asElement asScalableElement
						size: 20 @ 20 ] asStencil;
				label: 'Select Days to Analyze/Compare';
				action: [ :aBrButton :aBrButtonModel :aBlClickEvent | 
					| aDropdownAptitude firstDate element |
					aBrButton
						aptitudeDo: [ :anAptitude | 
							anAptitude
								withAllActorsBreadthFirstDo: [ :eachActor | 
									BrGlamorousWithExplicitDropdownAptitude = eachActor class
										ifTrue: [ aBrButton removeAptitude: eachActor ] ] ].
					firstDate := nil.
					aDropdownAptitude := BrGlamorousWithExplicitDropdownAptitude new.
					aBrButton
						addAptitude: (aDropdownAptitude
								withoutHandle;
								stencil: [ BrMenuExplicit new
										stencil: [ :anExplicitMenu | 
											| daysWithData |
											daysWithData := self rootCollection groupedByDay keys.
											element := MyGtCalendarElement
													forDate: self groupedByDay keys max
													asElementDo: [ :calendarElement | 
														| daysInMonth |
														daysInMonth := daysWithData
																select: [ :aDay | calendarElement currentMonth asMonth includes: aDay ]
																thenCollect: #dayOfMonth.
														calendarElement dayElements
															associationsDo: [ :anAssociation | 
																(daysInMonth includes: anAssociation key)
																	ifTrue: [ anAssociation value background: Color veryVeryLightGray ] ] ].
											element
												when: GtCalendarDateClickedEvent
													do: [ :anEvent | 
														anEvent consumed: true.
														aBrButton phlow
															spawnObject: (self rootCollection weekFromDate: anEvent date).
														anExplicitMenu hide ];
												when: GtCalendarDateClickedWithModifiersEvent
													do: [ :anEvent | 
														anEvent modifiers = BlKeyModifiers shift
															ifTrue: [ firstDate
																	ifNil: [ firstDate := anEvent date ]
																	ifNotNil: [ | sortedDates |
																		sortedDates := {firstDate.
																				anEvent date} sorted: #yourself ascending.
																		self flag: #TODO.	"Need to deal with daylight savings time"
																		aBrButton phlow
																			spawnObject: (self rootCollection
																					select: [ :each | 
																						each start asDate >= sortedDates first
																							and: [ each start asDate <= sortedDates second ] ]).
																		firstDate := nil.
																		anExplicitMenu hide ].
																anEvent consumed: true ] ] ] ]).
					aDropdownAptitude show ];
				actionWithModifiers: [ :aBrButton :aBrButtonModel :aBlClickEvent | 
					| calendar1 calendar2 aDropdownAptitude week1 week2 |
					aBlClickEvent modifiers = BlKeyModifiers primary
						ifTrue: [ aBrButton
								aptitudeDo: [ :anAptitude | 
									anAptitude
										withAllActorsBreadthFirstDo: [ :eachActor | 
											BrGlamorousWithExplicitDropdownAptitude = eachActor class
												ifTrue: [ aBrButton removeAptitude: eachActor ] ] ].
							aDropdownAptitude := BrGlamorousWithExplicitDropdownAptitude new.
							aBrButton
								addAptitude: (aDropdownAptitude
										withoutHandle;
										stencil: [ BrMenuExplicit new
												stencil: [ :anExplicitMenu | 
													calendar1 := MyGtCalendarElement
															forDate: self rootCollection groupedByDay keys max.
													calendar1
														when: GtCalendarDateClickedEvent
														do: [ :anEvent | 
															anEvent consumed: true.
															week1 := self rootCollection weekFromDate: anEvent date ].
													calendar2 := MyGtCalendarElement
															forDate: self rootCollection groupedByDay keys max.
													calendar2
														when: GtCalendarDateClickedEvent
														do: [ :anEvent | 
															anEvent consumed: true.
															week2 := self rootCollection weekFromDate: anEvent date.
															aBrButton phlow
																spawnObject: (GtPhlowExplicitTool new
																		name: 'Compare Weeks';
																		stencil: [ BrHorizontalPane new matchParent
																				addChildren: {GtPager createWrappedOn: week1 gtDefaultInspectorTool.
																						GtPager createWrappedOn: week2 gtDefaultInspectorTool} ]).
															anExplicitMenu hide ].
													BrHorizontalPane new fitContent
														addChildren: {calendar1.
																calendar2} ] ]).
							aDropdownAptitude show ] ] ]
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

{ #category : #accessing }
TtEventCollection >> ideals [
	^ self rootCollection items select: #isIdealTimeUsage
]

{ #category : #views }
TtEventCollection >> idealsDailyProgressBarChartStencil [
	^ [ :each | 
	| barChart container dailyCatchupAmount daysWithData groupedByDay indexOfCurrentDayOfWeek latestDay progressPercent |
	daysWithData := self groupedByDay keys size.
	each key isString
		ifFalse: [ progressPercent := ((each value items
					sum: self partialDurationWhenMultiTasking) / daysWithData days) asFloat
					/ each key minValue.
			dailyCatchupAmount := [ daysWithData days
					* ((1 - progressPercent) * each key minValue)
					/ (each key timePeriod asDays - daysWithData) ] on: ZeroDivide do: [ 0 ].
			groupedByDay := [ each value groupedByDay associations collect: #value ]
					on: MessageNotUnderstood
					do: [ #() ].
			groupedByDay := groupedByDay
					, ((self groupedByDay keys
							difference: (groupedByDay
									collect: [ :aTtEventCollection | aTtEventCollection first start asDate ]))
							collect: [ :aDate | aDate -> 0 ]).
			groupedByDay := groupedByDay
					sorted: [ :aDay | aDay isCollection ifTrue: [ aDay first start asDate ] ifFalse: [ aDay key ] ]
							ascending.
			indexOfCurrentDayOfWeek := groupedByDay size.
			latestDay := groupedByDay last
					in: [ :aDay | aDay isCollection ifTrue: [ aDay first start asDate ] ifFalse: [ aDay key ] ].
			groupedByDay := groupedByDay
					, (((1 to: 7 - latestDay weekdayIndex)
							collect: [ :aDay | (latestDay + aDay day) asDate ])
							collect: [ :aDate | aDate -> (each key minValue * 24 + dailyCatchupAmount asHours) ]).
			barChart := GtPlotterVerticalBarChart new
					with: ((GtPlotterDataGroup new
							values: groupedByDay;
							labelled: [ :aDay | 
								aDay isCollection
									ifTrue: [ aDay first start asDate weekday first: 3 ]
									ifFalse: [ aDay key weekday first: 3 ] ])
							background: [ :aDay | 
								aDay isCollection
									ifTrue: [ | color ideal value |
										value := (aDay value items sum: self partialDurationWhenMultiTasking)
												asHours.
										ideal := each key minValue * 24.
										value < (ideal - (each key leeway * 24))
											ifTrue: [ color := Color lightRed ].
										(value >= (ideal - (each key leeway * 24)) and: [ value < ideal ])
											ifTrue: [ color := Color lightYellow ].
										value >= ideal ifTrue: [ color := Color lightGreen ].
										color ]
									ifFalse: [ Color transparent ] ]);
					barHeightScale: (GtPlotterLinearScale new
							domainFrom: 0
								to: (groupedByDay
										max: [ :aDay | 
											aDay isCollection
												ifTrue: [ (aDay value items sum: self partialDurationWhenMultiTasking) asHours ]
												ifFalse: [ aDay value ] ]) + 2;
							yourself);
					barHeightData: [ :aDay | 
						aDay isCollection
							ifTrue: [ (aDay value items sum: self partialDurationWhenMultiTasking) asHours ]
							ifFalse: [ aDay value ] ];
					barElement: [ :aGtPlotterContext | BlElement new border: (BlBorder paint: Color black width: 1) ].
			barChart newHorizontalLine dataValue: each key minValue * 24.
			barChart newHorizontalLine
				lineStencil: [ BlLineElement new
						border: (BlBorderBuilder new
								paint: Color black;
								dashed;
								width: 1;
								build) ];
				dataValue: (each key minValue - each key leeway) * 24.
			barChart newHorizontalLine
				lineStencil: [ BlLineElement new
						border: (BlBorderBuilder new
								paint: Color black;
								dashed;
								width: 1;
								build) ];
				dataValue: (each key minValue + each key leeway) * 24.
			container := barChart create
					margin: (BlInsets all: 5);
					border: Color black asBlBorder;
					constraintsDo: [ :c | 
						c horizontal matchParent.
						c vertical exact: 200 ].
			container ]
		ifTrue: [ BrVerticalPane new
				alignCenter;
				margin: (BlInsets all: 5);
				constraintsDo: [ :c | 
					c horizontal matchParent.
					c vertical exact: 200 ];
				addChild: (BrButton new
						aptitude: BrGlamorousButtonWithLabelAptitude;
						label: 'Click To View Time Without Ideals';
						action: [ :aBrButton :aBrButtonModel :aBlClickEvent | 
							aBlClickEvent consumed: true.
							aBrButton phlow spawnObject: each value ]) ] ]
]

{ #category : #import }
TtEventCollection >> importAllFromTrello [
	self importFromTrello: Float infinity
]

{ #category : #import }
TtEventCollection >> importEarliestFromTrello [
	self importFromTrello: 1
]

{ #category : #import }
TtEventCollection >> importFromTrello: aNumberOrDate [
	| response daysToImport existingDays |
	self flag: #TODO.	"This should eventually call a properly configured class that implements a trait that knows how to import data"
	[ response := TtTrelloImporter fetch ] on: NameLookupFailure do: [ ^ self ].
	self rootCollection loadFromLepiter.
	existingDays := self rootCollection groupedByDay keys.
	daysToImport := aNumberOrDate class = Date
			ifTrue: [ ((response keys
					select: [ :each | each translateToUTC = aNumberOrDate translateToUTC ])
					difference: existingDays) asArray ]
			ifFalse: [ ((response keys collect: #translateToUTC) difference: existingDays)
					asArray
					, (response keys
							select: [ :each | each translateToUTC = Date today translateToUTC ])
							asArray
					sorted: (#yourself
							in: [ :anObject | 
								aNumberOrDate negative
									ifTrue: [ anObject perform: #descending ]
									ifFalse: [ anObject perform: #ascending ] ]) ].
	(daysToImport
		first: (([ aNumberOrDate abs ] on: MessageNotUnderstood do: [ 1 ])
				min: daysToImport size))
		do: [ :day | 
			TtTrelloParser new
				add: (response associations detect: [ :each | each key translateToUTC = day translateToUTC ])
				toCollection: self rootCollection ]
]

{ #category : #import }
TtEventCollection >> importLatestFromTrello [
	self importFromTrello: -1
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

{ #category : #import }
TtEventCollection >> listUnimportedDays [
	| response daysToImport |
	[ response := TtTrelloImporter fetch ] on: NameLookupFailure do: [ ^ self ].
	self rootCollection loadFromLepiter.
	daysToImport := (response keys collect: #translateToUTC)
			difference: self rootCollection groupedByDay keys.
	^ daysToImport
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

{ #category : #views }
TtEventCollection >> partialDurationWhenMultiTasking [
	^ [ :aTrackedTime | 
	| concurrentTrackedTime |
	concurrentTrackedTime := self rootCollection allEqualTo: aTrackedTime.
	aTrackedTime duration / (concurrentTrackedTime size + 1) ]
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
								ifFalse: [ ' - ' , someDates max yyyymmdd , '-' , (someDates max weekday first: 3) ])
						, ' [' , someDates size asString
						, (someDates size = 1 ifTrue: [ ' day, ' ] ifFalse: [ ' days, ' ]) ]);
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

{ #category : #import }
TtEventCollection >> unimportedDaysCalendar [
	| grid days months |
	days := self listUnimportedDays.
	days size > 0
		ifTrue: [ months := days groupedBy: [ :each | each start asMonth ].
			grid := BrHorizontalGrid new
					matchParent;
					columnCount: 3.
			months keys min index % 3
				in: [ :anIndex | 
					anIndex ~= 1
						ifTrue: [ ((2 - (months keys min index % 3) + 2) / 3.0) ceiling
								timesRepeat: [ grid addChild: (BlElement new size: 0 @ 0) ] ] ].
			grid
				addChildren: ((months associations sorted: #key ascending)
						collect: [ :aMonth | 
							| calendar daysWithData |
							calendar := MyGtCalendarElement new
									highlightToday: (aMonth key includes: Date today);
									date: aMonth value last start asDate.
							daysWithData := aMonth value.
							calendar
								enqueueTask: [ calendar dayElements
										do: [ :aContainer | 
											daysWithData
												detect: [ :aDay | aDay dayOfMonth asString = aContainer children first label asString ]
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
																background: (Color orange alpha: 0.25);
																when: BlClickEvent
																	do: [ :aBlClickEvent | 
																		aBlClickEvent consumed: true.
																		self importFromTrello: found value.
																		element phlow
																			spawnObject: (self rootCollection weekFromDate: found value) ]) ]
												ifNone: [  ] ] ] asBlTask.
							calendar asScalableElement margin: (BlInsets all: 10) ]) ].
	^ grid
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
	| thisWeek |
	thisWeek := aDate translateToUTC asMonth weeks
			detect: [ :aWeek | aWeek includes: aDate translateToUTC ].
	^ self select: [ :each | thisWeek includes: each start translateToUTC ]
]

{ #category : #views }
TtEventCollection >> weeklyIdealGrade: aTtEventCollection [
	| activeIdeals daysWithData groupedByIdeals ideals idealsWithNoTrackedTime idealProgress |
	ideals := self ideals groupedBy: [ :each | each as: Timespan ].
	^ (self ideals
		anySatisfy: [ :anIdeal | aTtEventCollection first start asDate >= anIdeal start asDate ])
		ifTrue: [ activeIdeals := ideals associations
					detect: [ :each | each key includes: self first start ]
					ifFound: [ :found | found value ]
					ifNone: [ ideals associations last value ].

			groupedByIdeals := aTtEventCollection timeEntries
					groupedBy: [ :aTrackedTime | 
						activeIdeals
							detect: [ :anIdeal | 
								anIdeal category
									ifNil: [ anIdeal computation value: aTrackedTime ]
									ifNotNil: [ :notNil | 
										(aTrackedTime category ifNil: [ TtCategory new ]) categoryLineage
											includes: notNil ] ]
							ifNone: [ 'Time Without Ideals' ] ].
			idealsWithNoTrackedTime := (activeIdeals difference: groupedByIdeals keys)
					collect: [ :each | 
						each
							-> ({'items'
										-> ({{'duration' -> 0 minutes} asDictionary as: NeoJSONObject} as: NeoJSONArray)}
									asDictionary as: NeoJSONObject) ].
			groupedByIdeals := groupedByIdeals associations , idealsWithNoTrackedTime
					reject: [ :each | each key isString ].
			daysWithData := aTtEventCollection groupedByDay keys size.
			idealProgress := groupedByIdeals
					collect: [ :each | 
						| progressPercent |
						progressPercent := ((each value items
								sum: self partialDurationWhenMultiTasking) / daysWithData days) asFloat
								/ each key minValue min: 1.
						{progressPercent >= 1 ifTrue: [ 1 ] ifFalse: [ 0 ].
							progressPercent} ].
			(idealProgress collect: #first) sum asString , '/'
				, groupedByIdeals size asString , ' , '
				, ((idealProgress collect: #second) sum / groupedByIdeals size * 100
						printShowingDecimalPlaces: 0) , '%' ]
		ifFalse: [ '' ]
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
