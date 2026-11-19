"
I am one proposed category for a {{gtClass:TtTrackedTime}} that has none yet, as answered by the Python facade (tt_suggest.gt.suggest_many). I am never written to the entry until accepted. #needsCheck flags entries a person should look at (new description, ambiguous history, low margin); only unflagged suggestions are accepted in bulk.
"
Class {
	#name : 'TtSuggestion',
	#superclass : 'Object',
	#instVars : [
		'entry',
		'categoryName',
		'path',
		'alternatives',
		'confidence',
		'margin',
		'isNew',
		'needsCheck',
		'reasons'
	],
	#category : 'TimeTracker-Suggestions-Model',
	#package : 'TimeTracker-Suggestions',
	#tag : 'Model'
}

{ #category : 'instance creation' }
TtSuggestion class >> fromDictionary: aDictionary entry: aTrackedTime [
	^ self new initializeFrom: aDictionary entry: aTrackedTime
]

{ #category : 'accessing' }
TtSuggestion >> alternatives [
	^ alternatives
]

{ #category : 'accessing' }
TtSuggestion >> category [
	"The TtCategory with my name in the entry's category tree, or nil."

	^ entry rootCollection
		ifNotNil: [ :aCollection | 
			aCollection categories
				detect: [ :each | each name = categoryName ]
				ifNone: [ nil ] ]
]

{ #category : 'accessing' }
TtSuggestion >> categoryName [
	^ categoryName
]

{ #category : 'accessing' }
TtSuggestion >> confidence [
	^ confidence
]

{ #category : 'ui' }
TtSuggestion >> decorate: aButton [
	"Proposed, not chosen: italic grey name (plus a marker when flagged) and a hollow ring."

	| text color |
	text := categoryName asRopedText italic foreground: Color gray.
	needsCheck
		ifTrue: [ text := text
					, ((isNew ifTrue: [ '  new' ] ifFalse: [ '  check' ]) asRopedText
							foreground: Color orange) ].
	color := self category
			ifNil: [ Color gray ]
			ifNotNil: [ :aCategory | aCategory color ].
	aButton
		label: text;
		icon: (BlElement new
				size: 15 @ 15;
				geometry: BlCircleGeometry new;
				background: Color transparent;
				border: (BlBorder paint: color width: 2))
]

{ #category : 'accessing' }
TtSuggestion >> entry [
	^ entry
]

{ #category : 'initialization' }
TtSuggestion >> initializeFrom: aDictionary entry: aTrackedTime [
	entry := aTrackedTime.
	categoryName := aDictionary at: 'category'.
	path := aDictionary at: 'path' ifAbsent: [ #() ].
	alternatives := aDictionary at: 'alternatives' ifAbsent: [ #() ].
	confidence := aDictionary at: 'confidence' ifAbsent: [ nil ].
	margin := aDictionary at: 'margin' ifAbsent: [ nil ].
	isNew := aDictionary at: 'is_new' ifAbsent: [ false ].
	needsCheck := aDictionary at: 'needs_check' ifAbsent: [ true ].
	reasons := aDictionary at: 'reasons' ifAbsent: [ #() ]
]

{ #category : 'testing' }
TtSuggestion >> isAcceptable [
	"Only unflagged suggestions are accepted in bulk."

	^ needsCheck not
]

{ #category : 'testing' }
TtSuggestion >> isNew [
	^ isNew
]

{ #category : 'testing' }
TtSuggestion >> needsCheck [
	^ needsCheck
]

{ #category : 'printing' }
TtSuggestion >> printOn: aStream [
	super printOn: aStream.
	aStream
		nextPut: $(;
		nextPutAll: categoryName asString.
	needsCheck
		ifTrue: [ aStream
				nextPutAll: ', check: ';
				nextPutAll: (', ' join: reasons) ].
	aStream nextPut: $)
]

{ #category : 'accessing' }
TtSuggestion >> reasons [
	^ reasons
]
