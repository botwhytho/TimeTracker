Class {
	#name : #TtDay,
	#superclass : #Object,
	#instVars : [
		'date',
		'entries',
		'comments',
		'rawImport'
	],
	#category : #TimeTracker
}

{ #category : #view }
TtDay >> TtDayCategorizeEntiresFor: aView [

	<gtView>
	| view |
	view := aView columnedTree
		        expandAll;
		        title: 'Categorize Entries' translated;
		        priority: 2;
		        items: [ self entries ];
		        children: [ :each | 
			        ((each isKindOf: TtTimeEntry) and: [ 
					         each activities size > 1 ])
				        ifTrue: [ each activities ]
				        ifFalse: [ #(  ) ] ];
		        column: 'Time' text: [ :anEntry | 
			        (anEntry isKindOf: Association)
				        ifTrue: [ '' ]
				        ifFalse: [ 
					        anEntry span start asTime printMinutes , '-'
					        , anEntry span end asTime printMinutes ] ];
		        column: 'Activities' text: [ :anEntry | 
			        (anEntry isKindOf: TtTimeEntry)
				        ifTrue: [ 
					        anEntry activities size > 1
						        ifTrue: [ '' ]
						        ifFalse: [ anEntry activities first key ] ]
				        ifFalse: [ anEntry key ] ];
		        column: 'Categories' icon: [ :anItem | 
			        | horizontalPane |
			        horizontalPane := BrHorizontalPane new
				                          hMatchParent;
				                          alignCenterLeft;
				                          vFitContent.

			        self flag:
				        'This is not working with BrFromFuture.'.
			        #( #( #Left #previous ) #( #Right #next ) ) do: [ 
				        :direction | 
				        horizontalPane addShortcut: (BlShortcutWithAction new
						         combination:
							         (BlKeyCombination perform: #arrow , direction first);
						         action: [ :anEvent | self halt.
							         anEvent currentTarget deepestFocusedChild ifNotNil: [ 
									         :aFocusedChild | 
									         anEvent currentTarget
										         perform: direction second , #SiblingDo:
										         with: [ :sibling | sibling requestFocus ] ] ]) ].

					 self flag:
				        'Getting rather nested. Refactor out when move this code to other class.'.
			        #( #( #Up #previous ) #( #Down #next ) ) do: [ :direction | 
				        horizontalPane addShortcut: (BlShortcutWithAction new
						         combination:
							         (BlKeyCombination perform: #arrow , direction first);
						         action: [ :anEvent | 
							         anEvent currentTarget deepestFocusedChild ifNotNil: [ 
									         :aFocusedChild | 
									         anEvent currentTarget parent parent parent
										         perform: direction second , #SiblingDo:
										         with: [ :sibling | 
											         (sibling query // aFocusedChild id) anyOne
												         ifNotNil: [ :element | element requestFocus ]
												         ifNil: [ 
													         sibling
														         perform: direction second , #SiblingDo:
														         with: [ :nextSibling | 
															         (nextSibling query // aFocusedChild id) anyOne
																         requestFocus ] ] ] ] ]) ].

			        ((anItem isKindOf: TtTimeEntry) and: [ 
				         anItem activities size > 1 ])
				        ifFalse: [ 
				        horizontalPane addChildren: (self categoryButtons: anItem) ]
				        ifTrue: [ horizontalPane addChild: BlElement new ] ].
	view columns first weight: 0.35.
	view columns third weight: 1.2.
	^ view
]

{ #category : #view }
TtDay >> TtDayDashboardFor: aView [

	<gtView>
	^ aView explicit
		  title: 'Dashboard' translated;
		  priority: 1;
		  stencil: [ 
			  | data horizontalPane verticalPane |
			  data := self calculateAnglesForDonut.
			  horizontalPane := BrHorizontalPane new
				                    hMatchParent;
				                    alignCenter;
				                    vFitContent.
			  horizontalPane addChildren: { 
					  (self buildDonut: data).
					  (self buildBars: data) }.
			  verticalPane := BrVerticalPane new
				                  hMatchParent;
				                  alignCenter;
				                  vMatchParent.
			  verticalPane addChildren: { 
					  horizontalPane.
					  (self TtDayCategorizeEntiresFor: GtPhlowView empty) asElement }.
			  verticalPane ]
]

{ #category : #'building ui' }
TtDay >> buildBars: data [

	| theData aBarWidthScale barChart |
	theData := GtPlotterDataGroup new values: data.
	theData := theData labelled: [ :each | each first ].
	theData := theData colored: [ :each | each fourth ].
	aBarWidthScale := GtPlotterLinearScale new
		                  domainFrom: 0
		                  to: data first second asHours.

	barChart := GtPlotterHorizontalBarChart new.
	barChart barElement: [ :aGtPlotterContext | 
		BlElement new aptitude:
			((BrGlamorousWithTooltipAptitude content: [ 
					  BrLabel new
						  text: aGtPlotterContext originalValue second;
						  aptitude:
							  (BrGlamorousLabelAptitude new padding: (BlInsets all: 1)) ])
				 hideDelay: 0;
				 showDelay: 0) ].
	barChart barLabelWidth: 160.
	barChart barWidthScale: aBarWidthScale.
	barChart barWidthData: [ :eachValue | eachValue second asHours ].
	barChart amountOfTicks: 4.
	barChart with: theData.
	^ barChart asElement
]

{ #category : #'building ui' }
TtDay >> buildCategorizerButton: anActivity [
	| button model |
	(anActivity isKindOf: TtTimeEntry)
		ifTrue: [ model := anActivity activities first ]
		ifFalse: [ model := anActivity ].
	button := BrButton new.
	button
		label:
			(model value
				ifNil: [ 'Please Choose a Category' ]
				ifNotNil: [ :c | c name ]);
		aptitude:
			BrGlamorousButtonWithLabelAptitude
				+
					(BrGlamorousWithDropdownAptitude
						handle: [ self editableLabel: button with: model ]
						content: [ self dropdownList: button with:  model ]).
	^ button
]

{ #category : #'building ui' }
TtDay >> buildDonut: data [

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
TtDay >> calculateAnglesForDonut [

	| categories totalTime |
	categories := self sortedEntries.
	totalTime := categories sum: [ :each | each second ].
	categories inject: -90 into: [ :sum :each | 
		| color temp |
		temp := (each second / totalTime * 360 + sum) asInteger.
		each
			add: { 
					sum.
					temp }
			afterIndex: 2.
		color := Color random.
		each first = 'Uncategorized' ifTrue: [ color := color alpha: 0.1 ].
		each add: color afterIndex: 3.
		temp ].
	"Completing the circle, fixing any rounding differences by hard coding smallest entry's stop angle. Distorts it a bit but okay compromise for now"
	categories last at: 3 put: { 
			categories last third first.
			270 }.
	^ categories
]

{ #category : #'building ui' }
TtDay >> categoryButtons: anActivity [
	^
	self suggestionsPlaceHolder ,
	{self buildCategorizerButton: anActivity}.

]

{ #category : #accessing }
TtDay >> comments [
	^ comments
]

{ #category : #accessing }
TtDay >> comments: aComment [
	comments := aComment
]

{ #category : #'building ui' }
TtDay >> completions [
	| completions |
	completions := GtStringsCompletionStrategy new.
	completions completions
		addAll: (TtCategories testInstance sampleCategories categories collect: #name).
	^ completions
]

{ #category : #accessing }
TtDay >> date [
	^ date
]

{ #category : #accessing }
TtDay >> date: aDate [
	date := aDate
]

{ #category : #'building ui' }
TtDay >> dropdownList: aButton with: aModel [

	| labelText simpleList |
	simpleList := BrSimpleList new.
	simpleList
		vFitContentLimited;
		hExact: 250;
		itemStencil: [ 
			BrButton new
				beSmallSize;
				hMatchParent;
				alignCenterLeft;
				aptitude:
					BrGlamorousButtonRectangularAptitude
					+ BrGlamorousButtonLabelAptitude;
				action: [ :aListItem :aButtonModel | 
					aListItem fireEvent: BrDropdownHideWish new.
					labelText := (aButtonModel widgetModels detect: [ :inner | 
							              inner isKindOf: BrLabelModel ]) text asString.
					aModel value:
							(TtCategories testInstance sampleCategories categories
								 detect: [ :each | each name = labelText ]
								 ifNone: [ aModel value ]).
					aButton label: (aModel value
								 ifNil: [ 'Please select an existing category' ]
								 ifNotNil: [ labelText ]) ] ];
		itemDataBinder: [ :eachElement :eachCategory :eachIndex | 
			eachElement viewModel model: eachCategory.
			eachElement label: eachCategory name ];
		items:
			(TtCategories testInstance sampleCategories categories sorted:
				 #name ascending).
	^ simpleList
]

{ #category : #'building ui' }
TtDay >> editableLabel: aButton with: aModel [
	| anEditor |
	anEditor := BrEditableLabel new
		text: 'Please Select a Category';
		constraintsDo: [ :c | c minWidth: 100 ];
		aptitude:
			(BrGlamorousEditableLabelAptitude new
				glamorousCodeFont;
				defaultForeground: Color black;
				fontSize: 13);
		padding: (BlInsets all: 4);
		switchToEditor;
		requestFocus;
		when: BrEditorAcceptWish
			do: [ :aWish | 
			aWish currentTarget fireEvent: BrDropdownHideWish new.
			aModel
				value:
					(TtCategories testInstance sampleCategories categories
						detect: [ :each | each name = aWish text asString ]
						ifNone: [ aModel value ]).
			aButton
				label:
					(aModel value
						ifNil: [ 'Please select an existing category' ]
						ifNotNil: [ aWish text asString ]) ];
		when: BrEditorCancelWish
			do: [ :aWish | aWish currentTarget fireEvent: BrDropdownHideWish new ];
		whenKey: BlKeyCombination primaryC
			labelDo:
				[ :aShortcutEvent :aShortcut | Clipboard clipboardText: aShortcutEvent currentTarget text asString ].
	(GtCompletionController on: anEditor strategy: self completions)
		install.
	^ anEditor
]

{ #category : #accessing }
TtDay >> entries [
	^ entries ifNil: [ entries := SortedCollection sortUsing: [:a :b | a span start < b span start] ]
]

{ #category : #printing }
TtDay >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: ' (' , self date asString , ')'
]

{ #category : #accessing }
TtDay >> rawData [

	^ rawImport
]

{ #category : #accessing }
TtDay >> rawData: rawExternalData [
	rawImport := rawExternalData
]

{ #category : #accessing }
TtDay >> sortedEntries [

	| categorizedActivities sumOfCategories |
	categorizedActivities := (self entries collect: [ :entry | 
		                          entry categories collect: [ :inner | 
			                          inner -> entry ] ]) flatten
		                         groupedBy: [ :each | 
			                         each key
				                         ifNil: [ 'Uncategorized' ]
				                         ifNotNil: [ :key | key name ] ]
		                         affect: [ :each | each collect: #value ].
	sumOfCategories := categorizedActivities collect: [ :each | 
		                   { 
			                   (each sum: [ :entry | 
				                    entry value span asDuration - 1 minutes
				                    / entry value activities size ]).
			                   each } ].
	^ (sumOfCategories associations sorted: [ :a :b | 
		   a value first > b value first ]) collect: [ :each | 
		  OrderedCollection withAll: { each key } , each value ]
]

{ #category : #'building ui' }
TtDay >> suggestionsPlaceHolder [

	^ 3 timesCollect: [ :n | 
		  BrFromFuture new
			  fitContent;
			  future: [ 
				  (20 atRandom * 100) milliSeconds wait.
				  (TtCategories testInstance sampleCategories categories collect:
						   #name) atRandom ]
			  initialValue: 'Calculating';
			  stencil: [ 
				  BrEditableLabel new
					  aptitude:
						  BrGlamorousEditableLabelAptitude new
							  glamorousRegularFontAndSize;
					  id: 'Suggestion ' , n asString ];
			  dataBinder: [ :aLabel :aDataSnapshot | 
				  aDataSnapshot
					  ifSuccess: [ :aName | aLabel text: aName ]
					  ifError: [ :anError | 
						  aLabel text:
							  (anError description asRopedText foreground: Color red) ]
					  ifPending: [ :anInitialValue | aLabel text: anInitialValue ] ] ]
]
