Class {
	#name : #TtCategories,
	#superclass : #Object,
	#traits : 'TGtGroupWithItems',
	#classTraits : 'TGtGroupWithItems classTrait',
	#instVars : [
		'root',
		'collection'
	],
	#classVars : [
		'SystemCategories',
		'TestInstance'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtCategories class >> firstTimeScheduled [
	^ self systemCategories at: 'First Time Scheduled'
]

{ #category : #initialization }
TtCategories class >> fromRoot: aRootCategory [
	| collection |
	collection := self new.
	aRootCategory hierarchy: collection.
	collection root: aRootCategory.
	collection calculateHierarchy.
	^ collection
]

{ #category : #initialization }
TtCategories class >> initialize [
	super initialize.
	SystemCategories := Dictionary new.
	SystemCategories
		at: 'Uncategorized'
			put: (TtCategory new
					name: 'Uncategorized';
					colorOverride: Color veryVeryLightGray);
		at: 'Untracked'
			put: (TtCategory new
					name: 'Untracked';
					colorOverride: Color transparent);
		at: 'Planned'
			put: (TtCategory new
					name: 'Planned';
					colorOverride: BrGlamorousColors successBackgroundColor);
		at: 'Unplanned'
			put: (TtCategory new
					name: 'Unplanned';
					colorOverride: BrGlamorousColors failureBackgroundColor);
		at: 'Recurring'
			put: (TtCategory new
					name: 'Recurring';
					colorOverride: BrGlamorousColors successBackgroundColor);
		at: 'One Time'
			put: (TtCategory new
					name: 'One Time';
					colorOverride: BrGlamorousColors newsBackgroundColor);
		at: 'First Time Scheduled'
			put: (TtCategory new
					name: 'When Planned';
					colorOverride: BrGlamorousColors successBackgroundColor);
		at: 'Rescheduled'
			put: (TtCategory new
					name: 'Rescheduled';
					colorOverride: BrGlamorousColors failureBackgroundColor)
]

{ #category : #accessing }
TtCategories class >> oneTime [
	^ self systemCategories at: 'One Time'
]

{ #category : #accessing }
TtCategories class >> planned [
	^ self systemCategories at: 'Planned'
]

{ #category : #accessing }
TtCategories class >> recurring [
	^ self systemCategories at: 'Recurring'
]

{ #category : #accessing }
TtCategories class >> rescheduled [
	^ self systemCategories at: 'Rescheduled'
]

{ #category : #accessing }
TtCategories class >> systemCategories [
	^ SystemCategories
]

{ #category : #testing }
TtCategories class >> testInstance [
	^ TestInstance ifNil: [ TestInstance := self new ]
]

{ #category : #accessing }
TtCategories class >> uncategorized [

	^ self systemCategories at: 'Uncategorized'
]

{ #category : #accessing }
TtCategories class >> unplanned [
	^ self systemCategories at: 'Unplanned'
]

{ #category : #accessing }
TtCategories class >> untracked [
	^ self systemCategories at: 'Untracked'
]

{ #category : #view }
TtCategories >> TtCategoriesFor: aView context: aContext [
	<gtView>
	self
		ifEmpty: [ ^ aView explicit
				title: 'Categories' translated;
				priority: 10;
				stencil: [ | buttonAction |
					buttonAction := [ :aBrButton :aBrButtonModel :anEvent | 
						| aChild aBRFrame |
						aBRFrame := aBrButton phlow firstParentWithView phlow element.
						aChild := aBRFrame childAt: 1.
						anEvent consumed: true.
						(aBrButton label asString includesSubstring: 'Template')
							ifTrue: [ | aCollection |
								aCollection := self collection.
								self
									becomeForward: (TtCategories new sampleCategories
											in: [ :categories | 
												categories collection: aCollection.
												categories root collection: aCollection.
												categories ]) ]
							ifFalse: [ self initialize ].
						self collection
							ifNotNil: [ :notNil | notNil class serializeWithLepiter: self root ].
						aBRFrame
							replaceChild: aChild
							with: (self TtCategoriesFor: GtPhlowView empty context: aContext) asElement ].
					BrFrame new
						id: #categoriesFrame;
						matchParent;
						addChild: (BrHorizontalPane new matchParent
								addChildren: {BrButton new
											aptitude: BrGlamorousButtonWithLabelAptitude;
											label: 'Create Empty Category Hierarchy';
											action: buttonAction.
										BrButton new
											aptitude: BrGlamorousButtonWithLabelAptitude;
											label: 'Create Category Hierarchy from Template';
											action: buttonAction}) ] ].
	^ aView mondrian
		title: 'Categories' translated;
		priority: 10;
		painting: [ :view | 
			view nodes
				shape: [ :aCategory | 
					| pane textElement |
					textElement := BlTextElement new.
					pane := BrHorizontalPane new.
					pane
						border: (BlBorder paint: Color gray width: 1);
						padding: (BlInsets all: 5);
						fitContent;
						alignCenter;
						addChildren: {textElement
									text: aCategory name asRopedText;
									constraintsDo: [ :c | c padding: (BlInsets all: 10) ].
								BlElement new background: aCategory color.
								BrButton new
									beTinySize;
									aptitude: BrGlamorousButtonWithIconAptitude
											+ (BrGlamorousWithDropdownAptitude
													handle: [ BrButton new
															beTinySize;
															aptitude: BrGlamorousButtonWithIconAptitude;
															icon: BrGlamorousVectorIcons add ]
													content: [ BrHorizontalPane new
															matchParent;
															padding: (BlInsets all: 15);
															addChild: (BrEditableLabel new
																	text: 'Create a new Category';
																	requestFocus;
																	constraintsDo: [ :c | c minWidth: 100 ];
																	aptitude: (BrGlamorousEditableLabelAptitude new
																			glamorousCodeFont;
																			defaultForeground: Color black;
																			fontSize: 13);
																	when: BrEditorAcceptWish
																		do: [ :aWish | 
																			aWish currentTarget fireEvent: BrDropdownHideWish new.
																			aCategory children
																				add: (TtCategory new
																						name: aWish text asString;
																						parentCategory: aCategory).
																			self calculateHierarchy.
																			self root collection
																				ifNotNil: [ :notNil | notNil class serializeWithLepiter: self root ].
																			textElement phlow firstParentWithView phlow syncUpdate ];
																	when: BrEditorCancelWish
																		do: [ :aWish | aWish currentTarget fireEvent: BrDropdownHideWish new ]) ]);
									icon: BrGlamorousVectorIcons add}.
					(aCategory isKindOf: TtRootCategory)
						ifFalse: [ pane
								addChild: (BrButton new
										beTinySize;
										aptitude: BrGlamorousButtonWithIconAptitude;
										icon: BrGlamorousVectorIcons remove;
										action: [ :aBrButton :aBrButtonModel :anEvent | 
											| isUsed |
											anEvent consumed: true.
											self flag: #TODO.	"Figure out logic for when categories are deleted"
											self root collection
												ifNil: [ isUsed := false ]
												ifNotNil: [ :notNil | isUsed := notNil anySatisfy: [ :each | each category = aCategory ] ].
											isUsed
												ifTrue: [ self inform: 'This category is beind used and can''t be deleted'.
													anEvent target fireEvent: BrDropdownHideWish new ]
												ifFalse: [ aCategory parentCategory children remove: aCategory.
													self calculateHierarchy.
													aBrButton phlow firstParentWithView phlow syncUpdate ] ]) ].
					aContext
						at: #TtTrackedTime
						ifPresent: [ :arguments | 
							(aCategory isKindOf: TtRootCategory)
								ifFalse: [ pane
										addChild: (BrButton new
												beTinySize;
												aptitude: BrGlamorousButtonWithIconAptitude;
												icon: BrGlamorousVectorIcons accept;
												action: [ :aBrButton :aBrButtonModel :anEvent | 
													| aCollection aTtTrackedTime categorizeButton viewElement |
													aCollection := arguments first.
													aTtTrackedTime := arguments second.
													categorizeButton := arguments third.
													viewElement := categorizeButton phlow firstParentWithView phlow
															firstParentWithView.
													anEvent consumed: true.
													aTtTrackedTime category: aCategory.
													aCollection class
														serializeWithLepiter: aTtTrackedTime.
													categorizeButton label: aCategory name.
													categorizeButton icon background: aCategory color.
													categorizeButton fireEvent: BrDropdownHideWish new.
													(aCollection
														perform: viewElement id asSymbol
														withArguments: {GtPhlowEmptyView new.
																GtPhlowContext new}) updateContent: viewElement ]) ] ]
						ifAbsent: [  ].
					pane ];
				with: self.
			view edges
				fromRightCenter;
				toLeftCenter;
				connectToAll: #children.
			view layout horizontalTree ]
]

{ #category : #view }
TtCategories >> calculateHierarchy [
	self items removeAll.
	self add: self root.
	self root
		withDeep: #children
		relationDo: [ :parent :child | 
			child parentCategory: parent.
			self add: child ]
]

{ #category : #accessing }
TtCategories >> collection [
	^ collection
]

{ #category : #accessing }
TtCategories >> collection: anObject [
	collection := anObject
]

{ #category : #initialization }
TtCategories >> initialize [
	super initialize.
	self
		root: (TtRootCategory new
				name: 'Create Categories';
				hierarchy: self;
				collection: self collection).
	self add: self root
]

{ #category : #accessing }
TtCategories >> root [
	^ root
]

{ #category : #accessing }
TtCategories >> root: anObject [
	root := anObject
]

{ #category : #accessing }
TtCategories >> sampleCategories [
	"Some nested categories"

	<gtExample>
	| node1 node2 node3 leaf1_1 leaf2_1 leaf2_2 leaf2_3 leaf3_1 leaf3_2 leaf3_3 leaf1 leaf2 leaf3 |
	node1 := TtCategory new
			name: 'Errands';
			parentCategory: root.
	node2 := TtCategory new
			name: 'Food';
			parentCategory: root.
	node3 := TtCategory new
			name: 'Habits';
			parentCategory: root.
	root children
		addAll: {node1.
				node2.
				node3}.
	leaf1_1 := TtCategory new
			name: 'Groceries';
			parentCategory: node1.
	node1 children addAll: {leaf1_1}.
	leaf2_1 := TtCategory new
			name: 'Cook';
			parentCategory: node2.
	leaf2_2 := TtCategory new
			name: 'Dishes';
			parentCategory: node2.
	leaf2_3 := TtCategory new
			name: 'Eat';
			parentCategory: node2.
	node2 children
		addAll: {leaf2_1.
				leaf2_2.
				leaf2_3}.
	leaf3_1 := TtCategory new
			name: 'Meditate';
			parentCategory: node3.
	leaf3_2 := TtCategory new
			name: 'Read';
			parentCategory: node3.
	leaf3_3 := TtCategory new
			name: 'Write';
			parentCategory: node3.
	node3 children
		addAll: {leaf3_1.
				leaf3_2.
				leaf3_3}.
	leaf1 := TtCategory new
			name: 'Leisure';
			parentCategory: root.
	leaf2 := TtCategory new
			name: 'Sleep';
			parentCategory: root.
	leaf3 := TtCategory new
			name: 'Work';
			parentCategory: root.
	root children
		addAll: {leaf1.
				leaf2.
				leaf3}.
	self
		addAll: {node1.
				node2.
				node3.
				leaf1_1.
				leaf2_1.
				leaf2_2.
				leaf2_3.
				leaf3_1.
				leaf3_2.
				leaf3_3.
				leaf1.
				leaf2.
				leaf3}.
	^ self
]
