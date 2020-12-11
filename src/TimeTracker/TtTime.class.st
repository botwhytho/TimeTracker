Class {
	#name : #TtTime,
	#superclass : #Object,
	#instVars : [
		'days',
		'categories'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtTime >> Categories: aView [
	<gtView>
	^ aView mondrian
		title: 'Categories' translated;
		priority: '11';
		painting: [ :view |
			view nodes
				shape: [ :aCategory |
					BlTextElement new
						text: aCategory name asRopedText;
						border: (BlBorder paint: Color gray width: 1);
						constraintsDo: [ :c |
							c padding: (BlInsets all: 10) ] ]; 
				with: self categories categories.
			view edges
				fromRightCenter;
				toLeftCenter;
				connectFromAll: #parent.
			view layout horizontalTree ].
]

{ #category : #accessing }
TtTime >> TtTimeDashboard: aView [
	<gtView>
	^ aView columnedList
		title: 'Dashboard' translated;
		priority: 10;
		items: [ self days ];
		column: 'Days' text: [ :aDay | aDay date ]
]

{ #category : #accessing }
TtTime >> aTimeExample [
	"An example TtTime with sample categories"
	<gtExample>
	| time |
	time := TtTime new categories: (TtCategories new sampleCategories).
	^ time
	
]

{ #category : #accessing }
TtTime >> categories [
	^ categories
]

{ #category : #accessing }
TtTime >> categories: aCategoryHierarchy [
	categories := aCategoryHierarchy
]

{ #category : #accessing }
TtTime >> cetagories: aCategoryHierarchy [
	categories := aCategoryHierarchy
]

{ #category : #accessing }
TtTime >> days [
	^ days ifNil: [ days := SortedCollection sortUsing: [:a :b | a date > b date] ]
]
