Class {
	#name : #TtTime,
	#superclass : #Object,
	#instVars : [
		'days',
		'categories'
	],
	#category : #TimeTracker
}

{ #category : #view }
TtTime >> TtCategoriesFor: aView [
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

{ #category : #view }
TtTime >> TtTimeDashboardFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Dashboard' translated;
		priority: 10;
		items: [ self days values sorted: #date descending ];
		column: 'Days' text: [ :aDay | aDay date ]
]

{ #category : #example }
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
	^ days ifNil: [ days := Dictionary new ]
]

{ #category : #import }
TtTime >> import [
	| data |
	data := TtTrelloImporter fetch.
	data
		associationsDo:
			[ :day | self days at: day key ifAbsentPut: (TtTrelloDayParser new import: day) ]
]
