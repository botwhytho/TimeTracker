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
						aBrButton phlow fireToolUpdateWish ].
					BrHorizontalPane new
						matchParent;
						alignCenter;
						addChildren: {BrButton new
									beLargeSize;
									margin: (BlInsets all: 25);
									aptitude: BrGlamorousButtonWithLabelAptitude;
									label: 'Create Empty Category Hierarchy';
									action: buttonAction.
								BrButton new
									beLargeSize;
									margin: (BlInsets all: 25);
									aptitude: BrGlamorousButtonWithLabelAptitude;
									label: 'Create Category Hierarchy from Template';
									action: buttonAction} ] ].
	^ aView mondrian
		title: 'Categories' translated;
		priority: 10;
		painting: [ :view | 
			view nodes
				shape: [ :aCategory | 
					| pane textElement |
					textElement := self editableCategoryLabel: aCategory.
					pane := BrHorizontalPane new.
					pane
						border: (BlBorder paint: Color gray width: 1);
						padding: (BlInsets all: 5);
						background: Color white;
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
																			self
																				detect: [ :each | each name = aWish text asString ]
																				ifFound: [ self
																						inform: 'A category with that name already Exists' ]
																				ifNone: [ aCategory children
																						add: (TtCategory new
																								name: aWish text asString;
																								parentCategory: aCategory).
																					self calculateHierarchy.
																					self root collection
																						ifNotNil: [ :notNil | notNil class serializeWithLepiter: self root ].
																					aContext
																						at: #TtTrackedTime
																						ifPresent: [ textElement phlow fireViewSyncUpdateWish ]
																						ifAbsent: [ textElement phlow fireToolUpdateWish ] ] ];
																	when: BrEditorCancelWish
																		do: [ :aWish | aWish currentTarget fireEvent: BrDropdownHideWish new ]) ]);
									icon: BrGlamorousVectorIcons add;
									label: 'Create a new Child Category'}.
					(aCategory isKindOf: TtRootCategory)
						ifFalse: [ pane
								addChild: (BrButton new
										beTinySize;
										aptitude: BrGlamorousButtonWithIconAptitude;
										icon: BrGlamorousVectorIcons remove;
										label: 'Delete Category';
										action: [ :aBrButton :aBrButtonModel :anEvent | 
											| categorizedEntries |
											anEvent consumed: true.
											self root collection
												ifNil: [ categorizedEntries := #() ]
												ifNotNil: [ :notNil | 
													categorizedEntries := notNil rootCollection timeEntries
															select: [ :aTrackedTime | aTrackedTime category hasCategoryOrParentCategoryNamed: aCategory name ] ].
											categorizedEntries
												ifNotEmpty: [ self
														inform: 'This category is beind used and can''t be deleted. First re-categorize (or delete) all time entries. You can also rename the current category if that is useful, instead of deleting it'.
													anEvent target phlow spawnObject: categorizedEntries.
													anEvent target fireEvent: BrDropdownHideWish new ]
												ifEmpty: [ aCategory parentCategory children remove: aCategory.
													self calculateHierarchy.
													self root collection
														ifNotNil: [ :notNil | notNil class serializeWithLepiter: self root ].
													aContext
														at: #TtTrackedTime
														ifPresent: [ aBrButton phlow fireViewSyncUpdateWish ]
														ifAbsent: [ aBrButton phlow fireToolUpdateWish ] ] ]) ].
					aContext
						at: #TtTrackedTime
						ifPresent: [ :arguments | 
							pane
								when: BlClickEvent
								do: [ :aBlClickEvent | 
									aBlClickEvent consumed: true.
									pane phlow spawnObject: aCategory.
									(aContext at: #TtTrackedTime) fourth hide ].
							(aCategory isKindOf: TtRootCategory)
								ifFalse: [ pane
										addChild: (BrButton new
												beTinySize;
												aptitude: BrGlamorousButtonWithIconAptitude;
												icon: BrGlamorousVectorIcons accept;
												label: 'Use Category';
												action: [ :aBrButton :aBrButtonModel :anEvent | 
													| aCollection aTtTrackedTime categorizeButton viewElement |
													aCollection := (aContext at: #TtTrackedTime) first.
													aTtTrackedTime := (aContext at: #TtTrackedTime) second.
													categorizeButton := (aContext at: #TtTrackedTime) third.
													viewElement := categorizeButton phlow firstParentWithViewContent.
													anEvent consumed: true.
													aTtTrackedTime category: aCategory.
													aCollection class serializeWithLepiter: aTtTrackedTime.
													categorizeButton label: aCategory name.
													categorizeButton icon background: aCategory color.
													viewElement phlow fireViewSyncUpdateWish.
													(aContext at: #TtTrackedTime) fourth hide.
													(aContext at: #TtTrackedTime) first categoryPicker removeFromParent ]) ] ]
						ifAbsent: [ pane
								when: BlClickEvent
								do: [ :aBlClickEvent | 
									aBlClickEvent consumed: true.
									pane phlow spawnObject: aCategory ].
							([ aContext navigation object isKindOf: TtEventCollection ]
								ifError: [ false ])
								ifTrue: [ pane
										addChild: (BrButton new
												aptitude: (BrGlamorousButtonWithLabelAptitude new foreground: Color red);
												label: 'USE FOR ALL';
												action: [ :aBrButton :aBrButtonModel :anEvent | 
													| aCollection |
													aCollection := aContext navigation object.
													anEvent consumed: true.
													aCollection timeEntries
														do: [ :aTtTrackedTime | 
															aTtTrackedTime category: aCategory.
															aCollection class serializeWithLepiter: aTtTrackedTime ] ]) ] ].
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

{ #category : #view }
TtCategories >> editableCategoryLabel: aCategory [
	| label |
	label := BrEditableLabel new.
	label
		aptitude: (BrGlamorousEditableLabelAptitude new
				glamorousCodeFont;
				defaultForeground: Color black;
				fontSize: 14);
		text: aCategory name;
		when: BrEditorAcceptWish
			do: [ :aWish | 
				| newValue |
				newValue := aWish text asString.
				newValue ~= aCategory name
					ifTrue: [ self
							detect: [ :each | each name = newValue ]
							ifFound: [ label text: aCategory name.
								self inform: 'A category with that name already exists' ]
							ifNone: [ aCategory name: newValue.
								self collection
									ifNotNil: [ :notNil | 
										| rootCollection |
										rootCollection := notNil rootCollection.
										rootCollection class serializeWithLepiter: self root.
										(rootCollection timeEntries
											select: [ :aTrackedTime | aTrackedTime category = aCategory ])
											do: [ :aTrackedTime | rootCollection class serializeWithLepiter: aTrackedTime ] ] ] ] ].
	^ label
]

{ #category : #views }
TtCategories >> gtCollectionActionFor: anAction [
	<gtAction>
	^ anAction button
		label: 'Colllection';
		action: [ :aBrButton :aBrTab :aBrButttonModel :aBlClickEvent | aBrButton phlow spawnObject: self collection ]
]

{ #category : #views }
TtCategories >> gtItemsByCategoryFor: aView [
	<gtView>
	| itemsByCategory emptyCategories |
	self collection
		ifNil: [ ^ aView empty ]
		ifNotNil: [ :notNil | notNil ifEmpty: [ ^ aView empty ] ].
	itemsByCategory := self collection groupedByCategory.
	emptyCategories := self allButFirst items difference: itemsByCategory keys.
	emptyCategories do: [ :each | itemsByCategory at: each put: #() ].
	^ aView columnedList
		title: 'Items by Category';
		priority: 20;
		items: [ itemsByCategory associations sorted: [ :each | each value size ] descending ];
		column: 'Category'
			text: [ :each | each key name ]
			spawn: #key;
		column: 'Items'
			text: [ :each | each value size ]
			weight: 0.25;
		column: 'Has Children'
			icon: [ :each | 
				each key children isEmpty
					ifTrue: [ BlElement new ]
					ifFalse: [ BrGlamorousVectorIcons accept ] ]
			weight: 0.25;
		send: #value
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
