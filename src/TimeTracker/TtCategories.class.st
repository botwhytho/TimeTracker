Class {
	#name : #TtCategories,
	#superclass : #Object,
	#traits : 'TGtGroupWithItems',
	#classTraits : 'TGtGroupWithItems classTrait',
	#instVars : [
		'root'
	],
	#classInstVars : [
		'testInstance'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtCategories class >> fromJSON: aString [
	| collection hierarchy reader |
	collection := self new.
	reader := NeoJSONReader on: aString readStream.
	reader
		listClass: SortedCollection;
		for: TtCategory
			do: [ :m | 
				m mapInstVar: #name.
				(m mapInstVar: #children) valueSchema: #Children ].
	hierarchy := reader
			for: #Children
				customDo: [ :mapping | mapping listOfElementSchema: TtCategory ];
			nextAs: TtCategory.
	hierarchy hierarchy: collection.
	collection root: hierarchy.
	collection calculateHierarchy.
	^ collection
]

{ #category : #'building ui' }
TtCategories class >> testInstance [
	^ testInstance ifNil: [ testInstance := self new ]
]

{ #category : #view }
TtCategories >> TtCategoriesFor: aView [
	<gtView>
	^ aView mondrian
		title: 'Categories' translated;
		priority: 10;
		painting: [ :view | 
			view nodes
				shape: [ :aCategory | 
					| textElement |
					textElement := BlTextElement new.
					BrHorizontalPane new
						border: (BlBorder paint: Color gray width: 1);
						padding: (BlInsets all: 5);
						fitContent;
						alignCenter;
						addChildren: {textElement
									text: aCategory name asRopedText;
									constraintsDo: [ :c | c padding: (BlInsets all: 10) ].
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
																			textElement phlow firstParentWithView phlow syncUpdate ];
																	when: BrEditorCancelWish
																		do: [ :aWish | aWish currentTarget fireEvent: BrDropdownHideWish new ]) ]);
									icon: BrGlamorousVectorIcons add.
								BrButton new
									beTinySize;
									aptitude: BrGlamorousButtonWithIconAptitude;
									icon: BrGlamorousVectorIcons close;
									action: [ :aBrButton :aBrButtonModel :anEvent | 
										anEvent consumed: true.
										aCategory parentCategory children remove: aCategory.
										self calculateHierarchy.
										aBrButton phlow firstParentWithView phlow syncUpdate ];
									in: [ :aDeleteButton | 
										aCategory name = 'Root' ifTrue: [ aDeleteButton visibility: BlVisibility gone ].
										aDeleteButton ]} ];
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

{ #category : #initialization }
TtCategories >> initialize [
	super initialize.
	self
		root: (TtCategory new
				name: 'Root';
				hierarchy: self).
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
