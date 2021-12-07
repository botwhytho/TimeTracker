Class {
	#name : #TtDay,
	#superclass : #Object,
	#instVars : [
		'date',
		'entries',
		'comments',
		'rawImport'
	],
	#category : #TimeTracker
}

{ #category : #view }
TtDay >> TtDayDashboardFor: aView [
	<gtView>
	| view |
	view := aView columnedTree
		expandAll;
		title: 'Dashboard' translated;
		priority: 1;
		items: [ self entries ];
		children: [ :each | 
			((each isKindOf: TtTimeEntry) and: [ each activities size > 1 ])
				ifTrue: [ each activities ]
				ifFalse: [ #() ] ];
		column: 'Time'
			text: [ :anEntry | 
			(anEntry isKindOf: Association)
				ifTrue: [ '' ]
				ifFalse: [ anEntry span start asTime printMinutes , '-'
						, anEntry span end asTime printMinutes ] ];
		column: 'Activities'
			text: [ :anEntry | 
			(anEntry isKindOf: TtTimeEntry)
				ifTrue: [ anEntry activities size > 1
						ifTrue: [ '' ]
						ifFalse: [ anEntry activities first key ] ]
				ifFalse: [ anEntry key ] ];
		column: 'Categories'
			icon: [ :anItem | 
			| horizontalPane |
			horizontalPane := BrHorizontalPane new
				hMatchParent;
				alignCenterLeft;
				vFitContent.
			((anItem isKindOf: TtTimeEntry) and: [ anItem activities size > 1 ])
				ifFalse: [ horizontalPane addChildren: (self categoryButtons: anItem) ]
				ifTrue: [ horizontalPane addChild: BlElement new ] ].
	view columns first weight: 0.35.
	view columns third weight: 1.2.
	^ view
]

{ #category : #'building ui' }
TtDay >> buildCategorizerButton: anActivity [
	| button model |
	(anActivity isKindOf: TtTimeEntry)
		ifTrue: [ model := anActivity activities first ]
		ifFalse: [ model := anActivity ].
	button := BrButton new.
	button
		label:
			(model value
				ifNil: [ 'Please Choose a Category' ]
				ifNotNil: [ :c | c name ]);
		aptitude:
			BrGlamorousButtonWithLabelAptitude
				+
					(BrGlamorousWithDropdownAptitude
						handle: [ self editableLabel: button with: model ]
						content: [ self dropdownList: button with:  model ]).
	^ button
]

{ #category : #'building ui' }
TtDay >> categoryButtons: anActivity [
	^
	self suggestionsPlaceHolder ,
	{self buildCategorizerButton: anActivity}.

]

{ #category : #accessing }
TtDay >> comments [
	^ comments
]

{ #category : #accessing }
TtDay >> comments: aComment [
	comments := aComment
]

{ #category : #'building ui' }
TtDay >> completions [
	| completions |
	completions := GtStringsCompletionStrategy new.
	completions completions
		addAll: (TtCategories testInstance sampleCategories categories collect: #name).
	^ completions
]

{ #category : #accessing }
TtDay >> date [
	^ date
]

{ #category : #accessing }
TtDay >> date: aDate [
	date := aDate
]

{ #category : #'building ui' }
TtDay >> dropdownList: aButton with: aModel [
	| labelText simpleList |
	simpleList := BrSimpleList new.
	simpleList
		vFitContentLimited;
		hExact: 250;
		itemStencil: [ BrButton new
				beSmallSize;
				hMatchParent;
				alignCenterLeft;
				aptitude: BrGlamorousButtonRectangularAptitude + BrGlamorousButtonLabelAptitude;
				action: [ :aListItem :aButtonModel | 
					aListItem fireEvent: BrDropdownHideWish new.
					labelText := (aButtonModel widgetModels
						detect: [ :inner | inner isKindOf: BrLabelModel ]) text asString.
					aModel
						value:
							(TtCategories testInstance sampleCategories categories
								detect: [ :each | each name = labelText ]
								ifNone: [ aModel value ]).
					aButton
						label:
							(aModel value
								ifNil: [ 'Please select an existing category' ]
								ifNotNil: [ aModel value ]) ] ];
		itemDataBinder: [ :eachElement :eachCategory :eachIndex | 
			eachElement viewModel model: eachCategory.
			eachElement label: eachCategory name ];
		items: TtCategories testInstance sampleCategories categories.
	^ simpleList
]

{ #category : #'building ui' }
TtDay >> editableLabel: aButton with: aModel [
	| anEditor |
	anEditor := BrEditableLabel new
		text: 'Please Select a Category';
		constraintsDo: [ :c | c minWidth: 100 ];
		aptitude:
			(BrGlamorousEditableLabelAptitude new
				glamorousCodeFont;
				defaultForeground: Color black;
				fontSize: 13);
		padding: (BlInsets all: 4);
		switchToEditor;
		requestFocus;
		when: BrEditorAcceptWish
			do: [ :aWish | 
			aWish currentTarget fireEvent: BrDropdownHideWish new.
			aModel
				value:
					(TtCategories testInstance sampleCategories categories
						detect: [ :each | each name = aWish text asString ]
						ifNone: [ aModel value ]).
			aButton
				label:
					(aModel value
						ifNil: [ 'Please select an existing category' ]
						ifNotNil: [ aWish text asString ]) ];
		when: BrEditorCancelWish
			do: [ :aWish | aWish currentTarget fireEvent: BrDropdownHideWish new ];
		whenKey: BlKeyCombination primaryC
			labelDo:
				[ :aShortcutEvent :aShortcut | Clipboard clipboardText: aShortcutEvent currentTarget text asString ].
	(GtCompletionController on: anEditor strategy: self completions)
		install.
	^ anEditor
]

{ #category : #accessing }
TtDay >> entries [
	^ entries ifNil: [ entries := SortedCollection sortUsing: [:a :b | a span start < b span start] ]
]

{ #category : #printing }
TtDay >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: ' (' , self date asString , ')'
]

{ #category : #accessing }
TtDay >> rawData [

	^ rawImport
]

{ #category : #accessing }
TtDay >> rawData: rawExternalData [
	rawImport := rawExternalData
]

{ #category : #'building ui' }
TtDay >> suggestionsPlaceHolder [
	^ {(BrButton new
		label: 'Suggestion 1';
		aptitude: BrGlamorousButtonWithLabelAptitude).
	(BrButton new
		label: 'Suggestion 2';
		aptitude: BrGlamorousButtonWithLabelAptitude).
	(BrButton new
		label: 'Suggestion 3';
		aptitude: BrGlamorousButtonWithLabelAptitude)}
]
