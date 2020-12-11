Class {
	#name : #TtCategories,
	#superclass : #Object,
	#instVars : [
		'categories'
	],
	#category : #TimeTracker
}

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
	leaf1_1 := TtCategory new
		name: 'Groceries';
		parent: node1.
	leaf2_1 := TtCategory new
		name: 'Cook';
		parent: node2.
	leaf2_2 := TtCategory new
		name: 'Dishes';
		parent: node2.
	leaf2_3 := TtCategory new
		name: 'Eat';
		parent: node2.
	leaf3_1 := TtCategory new
		name: 'Meditate';
		parent: node3.
	leaf3_2 := TtCategory new
		name: 'Read';
		parent: node3.
	leaf3_3 := TtCategory new
		name: 'Write';
		parent: node3.
	leaf1 := TtCategory new
		name: 'Leisure';
		parent: root.
	leaf2 := TtCategory new
		name: 'Sleep';
		parent: root.
	leaf3 := TtCategory new
		name: 'Work';
		parent: root.
	categoryHierarchy categories
		addAll:
			{root.
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