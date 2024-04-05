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
	collection add: hierarchy.
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
	| viewObject |
	viewObject := aView mondrian.
	^ viewObject
		title: 'Categories' translated;
		priority: 10;
		painting: [ :view | 
			view nodes
				shape: [ :aCategory | 
					BrHorizontalPane new
						border: (BlBorder paint: Color gray width: 1);
						padding: (BlInsets all: 5);
						fitContent;
						alignCenter;
						addChildren: {BlTextElement new
									text: aCategory name asRopedText;
									constraintsDo: [ :c | c padding: (BlInsets all: 10) ].
								BrButton new
									beTinySize;
									aptitude: BrGlamorousButtonWithIconAptitude;
									icon: BrGlamorousVectorIcons add;
									action: [ :aBrButton :aBrButtonModel :anEvent | 
										anEvent consumed: true.
										aCategory children
											add: (TtCategory new
													name: 'Test';
													parentCategory: aCategory).
										self calculateHierarchy.
										viewObject updateContent: aBrButton phlow firstParentWithView ].
								BrButton new
									beTinySize;
									aptitude: BrGlamorousButtonWithIconAptitude;
									icon: BrGlamorousVectorIcons close;
									action: [ :aBrButton :aBrButtonModel :anEvent | 
										anEvent consumed: true.
										aCategory parentCategory children remove: aCategory.
										self calculateHierarchy.
										viewObject updateContent: aBrButton phlow firstParentWithView ]} ];
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
	| categoryHierarchy rootCategory node1 node2 node3 leaf1_1 leaf2_1 leaf2_2 leaf2_3 leaf3_1 leaf3_2 leaf3_3 leaf1 leaf2 leaf3 |
	categoryHierarchy := self class new.
	rootCategory := TtCategory new
			name: 'Root';
			hierarchy: categoryHierarchy.
	node1 := TtCategory new
			name: 'Errands';
			parentCategory: rootCategory.
	node2 := TtCategory new
			name: 'Food';
			parentCategory: rootCategory.
	node3 := TtCategory new
			name: 'Habits';
			parentCategory: rootCategory.
	rootCategory children
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
			parentCategory: rootCategory.
	leaf2 := TtCategory new
			name: 'Sleep';
			parentCategory: rootCategory.
	leaf3 := TtCategory new
			name: 'Work';
			parentCategory: rootCategory.
	rootCategory children
		addAll: {leaf1.
				leaf2.
				leaf3}.
	categoryHierarchy root: rootCategory.
	categoryHierarchy
		addAll: {rootCategory.
				node1.
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
	^ categoryHierarchy
]
