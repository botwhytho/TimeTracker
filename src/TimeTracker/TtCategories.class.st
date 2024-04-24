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

{ #category : #initialization }
TtCategories class >> fromJSON: aString [
	| collection hierarchy |
	self flag: #TODO "May want to dreprecate this as `fromRoot:` should suffice. Deserializing logic now exists in more generic class to get to snippet data".
	collection := self new.
	hierarchy := NeoJSONReader fromString: aString as: TtRootCategory.
	hierarchy hierarchy: collection.
	collection root: hierarchy.
	collection calculateHierarchy.
	^ collection
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

{ #category : #'building ui' }
TtCategories class >> testInstance [
	^ testInstance ifNil: [ testInstance := self new ]
]

{ #category : #view }
TtCategories >> TtCategoriesFor: aView context: aContext [
	<gtView>
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
								BlElement new background: (self stringToColorHash: aCategory name).
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
									icon: BrGlamorousVectorIcons add}.
					(aCategory isKindOf: TtRootCategory)
						ifFalse: [ pane
								addChild: (BrButton new
										beTinySize;
										aptitude: BrGlamorousButtonWithIconAptitude;
										icon: BrGlamorousVectorIcons close;
										action: [ :aBrButton :aBrButtonModel :anEvent | 
											anEvent consumed: true.
											aCategory parentCategory children remove: aCategory.
											self calculateHierarchy.
											aBrButton phlow firstParentWithView phlow syncUpdate ]) ].
					aContext
						at: #TtTrackedTime
						ifPresent: [ :anAssociation | 
							(aCategory isKindOf: TtRootCategory)
								ifFalse: [ pane
										addChild: (BrButton new
												beTinySize;
												aptitude: BrGlamorousButtonWithIconAptitude;
												icon: BrGlamorousVectorIcons accept;
												action: [ :aBrButton :aBrButtonModel :anEvent | 
													anEvent consumed: true.
													anAssociation key
														category: aCategory;
														serializeWithLepiter.
													anAssociation value label: aCategory name.
													anAssociation value fireEvent: BrDropdownHideWish new ]) ] ]
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

{ #category : #initialization }
TtCategories >> initialize [
	super initialize.
	self
		root: (TtRootCategory new
				name: 'Create Categories';
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

{ #category : #view }
TtCategories >> stringToColorHash2: aString [
	| stringHash firstNum secondNum mappedNum hue variation saturation brightness |
	stringHash := MD5 hashMessage: aString.
	firstNum := stringHash first.
	secondNum := stringHash second.
	mappedNum := (firstNum / 256 * 360) asInteger.
	hue := mappedNum % 360 / 360.
	variation := secondNum / 256 / 2 - 0.25.
	saturation := 0.8 + variation min: 1.0.
	brightness := 0.7 + variation min: 1.0.
	^ Color
		h: hue
		s: saturation
		v: brightness
]

{ #category : #view }
TtCategories >> stringToColorHash: aString [
	| angle md5BitDepthMax stringHash |
	md5BitDepthMax := 2 ** 128.
	stringHash := (MD5 hashMessage: aString) asInteger.
	angle := stringHash / md5BitDepthMax * 360.
	^ Color
		h: angle
		s: 1
		l: 0.5
]
