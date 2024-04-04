Class {
	#name : #TtCategories,
	#superclass : #Object,
	#instVars : [
		'categories'
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
		listClass: OrderedCollection;
		for: TtCategory
			do: [ :m | 
				m mapInstVar: #name.
				(m mapInstVar: #children) valueSchema: #Children ].
	hierarchy := reader
			for: #Children
				customDo: [ :mapping | mapping listOfElementSchema: TtCategory ];
			nextAs: TtCategory.
	collection categories add: hierarchy.
	hierarchy
		withDeep: #children
		relationDo: [ :parent :child | 
			child parent: child.
			collection categories add: child ].
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
					BrHorizontalPane new
						border: (BlBorder paint: Color gray width: 1);
						fitContent;
						alignCenter;
						addChildren: {BlTextElement new
									text: aCategory name asRopedText;
									constraintsDo: [ :c | c padding: (BlInsets all: 10) ].
								BrGlamorousVectorIcons add asElement
									when: BlClickEvent
									do: [ :anEvent | 
										anEvent consumed: true.
										aCategory children
											add: (TtCategory new
													name: 'Test';
													parent: aCategory) ].
								BrGlamorousVectorIcons close asElement
									when: BlClickEvent
									do: [ :anEvent | 
										anEvent consumed: true.
										anEvent target inform: 'TODO: sort out logic for category deletion' ]} ];
				with: self categories.
			view edges
				fromRightCenter;
				toLeftCenter;
				connectToAll: #children.
			view layout horizontalTree ]
]

{ #category : #accessing }
TtCategories >> categories [
	^ categories ifNil: [ categories := OrderedCollection new ]
]

{ #category : #accessing }
TtCategories >> sampleCategories [
	"Some nested categories"

	<gtExample>
	| categoryHierarchy root node1 node2 node3 leaf1_1 leaf2_1 leaf2_2 leaf2_3 leaf3_1 leaf3_2 leaf3_3 leaf1 leaf2 leaf3 |
	categoryHierarchy := TtCategories new.
	root := TtCategory new
			name: 'Root';
			hierarchy: categoryHierarchy.
	node1 := TtCategory new
			name: 'Errands';
			parent: root.
	node2 := TtCategory new
			name: 'Food';
			parent: root.
	node3 := TtCategory new
			name: 'Habits';
			parent: root.
	root children
		addAll: {node1.
				node2.
				node3}.
	leaf1_1 := TtCategory new
			name: 'Groceries';
			parent: node1.
	node1 children addAll: {leaf1_1}.
	leaf2_1 := TtCategory new
			name: 'Cook';
			parent: node2.
	leaf2_2 := TtCategory new
			name: 'Dishes';
			parent: node2.
	leaf2_3 := TtCategory new
			name: 'Eat';
			parent: node2.
	node2 children
		addAll: {leaf2_1.
				leaf2_2.
				leaf2_3}.
	leaf3_1 := TtCategory new
			name: 'Meditate';
			parent: node3.
	leaf3_2 := TtCategory new
			name: 'Read';
			parent: node3.
	leaf3_3 := TtCategory new
			name: 'Write';
			parent: node3.
	node3 children
		addAll: {leaf3_1.
				leaf3_2.
				leaf3_3}.
	leaf1 := TtCategory new
			name: 'Leisure';
			parent: root.
	leaf2 := TtCategory new
			name: 'Sleep';
			parent: root.
	leaf3 := TtCategory new
			name: 'Work';
			parent: root.
	root children
		addAll: {leaf1.
				leaf2.
				leaf3}.
	categoryHierarchy categories
		addAll: {root.
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
