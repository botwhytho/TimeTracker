Class {
	#name : #TtCategory,
	#superclass : #Object,
	#instVars : [
		'name',
		'hierarchy',
		'children',
		'parentCategory',
		'colorOverride',
		'defaultColor'
	],
	#category : #TimeTracker
}

{ #category : #serialization }
TtCategory class >> neoJsonMapping: aNeoJSONMapper [
	aNeoJSONMapper
		for: self
			do: [ :aMapping | 
				aMapping mapInstVar: #name.
				(aMapping mapInstVar: #children) valueSchema: #Children.
				(aMapping mapInstVar: #colorOverride) valueSchema: #ColorOverride ];
		for: #Children
			customDo: [ :childrenMapping | childrenMapping listOfElementSchema: TtCategory ];
		for: #ColorOverride
			customDo: [ :colorOverrideMapping | 
				colorOverrideMapping
					decoder: [ :aMap | 
						Color
							r: aMap r
							g: aMap g
							b: aMap b
							alpha: aMap alpha ];
					encoder: [ :aColor | 
						{#r -> aColor red.
							#g -> aColor green.
							#b -> aColor blue.
							#alpha -> aColor alpha} asDictionary ] ].
	(aNeoJSONMapper isKindOf: NeoJSONReader)
		ifTrue: [ aNeoJSONMapper
				listClass: SortedCollection;
				mapClass: NeoJSONObject ]
]

{ #category : #serialization }
TtCategory class >> snippetClass [
	^ TtCategoriesSnippet
]

{ #category : #comparing }
TtCategory >> <= other [
	^ self name <= other name
]

{ #category : #comparing }
TtCategory >> = anObject [
	^ self species = anObject species and: [ self name = anObject name ]
]

{ #category : #accessing }
TtCategory >> children [
	^ children ifNil: [ children := SortedCollection new ]
]

{ #category : #accessing }
TtCategory >> color [
	^ self colorOverride ifNil: [ self defaultColor ]
]

{ #category : #accessing }
TtCategory >> colorOverride [
	^ colorOverride
]

{ #category : #accessing }
TtCategory >> colorOverride: aColor [
	colorOverride := aColor
]

{ #category : #accessing }
TtCategory >> defaultColor [
	^ defaultColor ifNil: [ defaultColor := self stringToColorHash ]
]

{ #category : #action }
TtCategory >> gtColorFor: anAction [
	<gtAction>
	| isRoot |
	isRoot := self isKindOf: TtRootCategory.
	^ anAction explicit
		priority: -5;
		stencil: [ BrButton new
				aptitude: BrGlamorousButtonWithIconAptitude;
				in: [ :aButton | 
					aButton icon: (aButton icon asElement background: self color).
					aButton ] ]
]

{ #category : #views }
TtCategory >> gtParentAndChildrenFor: aView [
	<gtView>
	^ aView columnedTree
		title: 'Local Hierarchy';
		priority: 5;
		items: [ self parentAndChildren ];
		children: #value;
		column: 'Category'
			text: [ :each | 
				each key isString
					ifTrue: [ each key ]
					ifFalse: [ each key ifNil: [ '' ] ifNotNil: #name ] ];
		send: #key;
		expandAll
]

{ #category : #action }
TtCategory >> gtRootActionFor: anAction [
	<gtAction>
	| isRoot |
	isRoot := self isKindOf: TtRootCategory.
	^ anAction button
		label: (isRoot ifTrue: [ 'Hierarchy' ] ifFalse: [ 'Root' ]);
		action: [ :aBrButton :aBrTab :aBrButttonModel :aBlClickEvent | 
			aBrButton phlow
				spawnObject: (isRoot ifTrue: [ self hierarchy ] ifFalse: [ self rootCategory ]) ]
]

{ #category : #comparing }
TtCategory >> hash [
	^ self class hash hashMultiply bitXor: self name hash
]

{ #category : #accessing }
TtCategory >> hierarchy [
	^ hierarchy ifNil: [ self rootCategory hierarchy ]
]

{ #category : #accessing }
TtCategory >> hierarchy: aTtCategories [
	hierarchy := aTtCategories
]

{ #category : #accessing }
TtCategory >> isPlaceholder [
	^ false
]

{ #category : #accessing }
TtCategory >> name [
	^ name
]

{ #category : #accessing }
TtCategory >> name: aName [
	name := aName
]

{ #category : #views }
TtCategory >> parentAndChildren [
	^ {'Parent Category' -> {self parentCategory -> #()}.
		'Children Categories'
			-> (children
					ifNil: [ {children -> #()} ]
					ifNotNil: [ children collect: [ :each | each -> #() ] ])}
]

{ #category : #accessing }
TtCategory >> parentCategory [
	^ parentCategory
]

{ #category : #accessing }
TtCategory >> parentCategory: aTtCategory [
	parentCategory := aTtCategory
]

{ #category : #printing }
TtCategory >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPut: $(;
		nextPutAll: self name;
		nextPut: $)
]

{ #category : #accessing }
TtCategory >> rootCategory [
	| category |
	category := self.
	[ category parentCategory ] whileNotNil: [ category := category parentCategory ].
	^ category
]

{ #category : #accessing }
TtCategory >> stringToColorHash [
	| angle md5BitDepthMax stringHash |
	self flag: #TODO.	"Test other algorithms, colors look too alike"
	md5BitDepthMax := 2 ** 128.
	stringHash := (MD5 hashMessage: self name) asInteger.
	angle := stringHash / md5BitDepthMax * 360.
	^ Color
		h: angle
		s: 1
		l: 0.5
]

{ #category : #accessing }
TtCategory >> stringToColorHash2 [
	| stringHash firstNum secondNum mappedNum hue variation saturation brightness |
	stringHash := MD5 hashMessage: self name.
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
