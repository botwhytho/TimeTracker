Class {
	#name : #TtTime,
	#superclass : #Object,
	#instVars : [
		'days',
		'categories'
	],
	#classVars : [
		'Cache',
		'Directory'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtTime class >> initialize [

	| settings |
	"maybe use `settingsLocation` but not sure if that will already be available on initialize"
	settings := FileLocator preferences / #pharo / #TimeTracker
	            / 'settings.json'.
	settings exists ifFalse: [ 
		settings ensureCreateFile.
		STON
			put: { (#cacheDirectory -> nil) } asDictionary
			asJsonOnStreamPretty: settings writeStream
		"serializeToFileNamed"
		"writeStreamDo: [ :stream | 
					stream nextPutAll: (NeoJSONWriter toStringPretty:
									 { (#cacheDirectory -> nil) } asDictionary) ] ]" ].
	((STON fromStream: settings readStream) at: 'cacheDirectory')
		ifNil: [ 
			| file |
			file := settings parent / 'TimeTracker.fuel'.
			file exists ifTrue: [ 
				Cache := FLMaterializer materializeFromFileNamed: file pathString ] ]
		ifNotNil: [ :directory | 
			| file |
			file := directory asFileReference / 'TimeTracker.fuel'.
			file exists ifTrue: [ 
				Cache := FLMaterializer materializeFromFileNamed: file pathString ] ]
]

{ #category : #accessing }
TtTime class >> settingsLocation [

	^ FileLocator preferences / #pharo / #TimeTracker
]

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
	"This should eventually call a properly configured class that implements a trait that knows how to import data"
	| data |
	data := TtTrelloImporter fetch.
	data
		associationsDo:
			[ :day | self days at: day key ifAbsentPut: (TtTrelloDayParser new import: day) ]
]
