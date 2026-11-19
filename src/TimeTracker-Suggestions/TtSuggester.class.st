"
I am the category proposer that TimeTracker-Suggestions registers with {{gtClass:TtEventCollection}} (see TtEventCollection class>>#proposer). I convert TimeTracker objects to plain data for {{gtClass:TtSuggestionService}}: I train in the background when a collection loads, propose for all uncategorized entries in one batch when the Entries By Day view asks, accept a day's unflagged proposals (category: + serialize, like the category picker), and learn from every categorization.

My class-side #initialize registers me; Metacello runs it on load. When creating me in a live image, run `TtSuggester initialize` by hand.
"
Class {
	#name : 'TtSuggester',
	#superclass : 'Object',
	#instVars : [
		'proposals'
	],
	#classInstVars : [
		'default'
	],
	#category : 'TimeTracker-Suggestions-Model',
	#package : 'TimeTracker-Suggestions',
	#tag : 'Model'
}

{ #category : 'accessing' }
TtSuggester class >> default [
	^ default ifNil: [ default := self new ]
]

{ #category : 'class initialization' }
TtSuggester class >> initialize [
	"Register as TimeTracker's category proposer. Metacello runs this on load."

	TtEventCollection proposer: self default
]

{ #category : 'class initialization' }
TtSuggester class >> unregister [
	TtEventCollection proposer == default
		ifTrue: [ TtEventCollection proposer: nil ]
]

{ #category : 'proposer protocol' }
TtSuggester >> acceptProposalsIn: aCollectionOfTrackedTime [
	"Accept unflagged proposals exactly like the category picker does (category: + serialize),
	then learn from each. Entries categorized by hand are never touched."

	(self acceptableProposalsIn: aCollectionOfTrackedTime)
		do: [ :anEntry | 
			(proposals at: anEntry) category
				ifNotNil: [ :aCategory | 
					anEntry category: aCategory.
					anEntry serialize.
					proposals removeKey: anEntry ifAbsent: [  ].
					self learn: anEntry ] ]
]

{ #category : 'proposer protocol' }
TtSuggester >> acceptableProposalsIn: aCollectionOfTrackedTime [
	"Still uncategorized entries whose proposal is unflagged."

	^ (self
		quietly: [ aCollectionOfTrackedTime
				select: [ :each | 
					each category isNil
						and: [ (self proposalFor: each)
								ifNil: [ false ]
								ifNotNil: [ :aSuggestion | aSuggestion isAcceptable ] ] ] ])
		ifNil: [ #() ]
]

{ #category : 'converting' }
TtSuggester >> categoryNameOf: aTrackedTime [
	"A real category's name, or nil (none yet, or a placeholder for an unknown name)."

	| category |
	category := aTrackedTime category.
	category ifNil: [ ^ nil ].
	category isString ifTrue: [ ^ category ].
	^ category isPlaceholder ifTrue: [ nil ] ifFalse: [ category name ]
]

{ #category : 'proposer protocol' }
TtSuggester >> collectionLoaded: aTtEventCollection [
	self retrain
]

{ #category : 'proposer protocol' }
TtSuggester >> decorateCategorizeButton: aButton for: aTrackedTime [
	self
		quietly: [ (self proposalFor: aTrackedTime)
				ifNotNil: [ :aSuggestion | aSuggestion decorate: aButton ] ]
]

{ #category : 'proposer protocol' }
TtSuggester >> entryCategorized: aTrackedTime [
	proposals removeKey: aTrackedTime ifAbsent: [  ].
	self learn: aTrackedTime
]

{ #category : 'converting' }
TtSuggester >> entryDictionaryFor: aTrackedTime [
	"Plain data mirroring TtTrackedTime, as tt_suggest.gt expects (see Entry.from_dict)."

	| dictionary |
	dictionary := Dictionary new
			at: 'description' put: aTrackedTime description;
			at: 'details' put: aTrackedTime details;
			at: 'start' put: aTrackedTime start printString;
			at: 'duration' put: aTrackedTime duration asSeconds;
			at: 'isPlanned' put: aTrackedTime isPlanned;
			at: 'rawData' put: aTrackedTime rawData;
			at: 'day' put: aTrackedTime daySerializedFrom;
			yourself.
	(self categoryNameOf: aTrackedTime)
		ifNotNil: [ :aName | dictionary at: 'category' put: aName ].
	^ dictionary
]

{ #category : 'initialization' }
TtSuggester >> initialize [
	super initialize.
	proposals := IdentityDictionary new
]

{ #category : 'training' }
TtSuggester >> learn: aTrackedTime [
	self service isReady ifFalse: [ ^ self ].
	(self categoryNameOf: aTrackedTime) ifNil: [ ^ self ].
	self service
		guard: [ self service
				call: 'learn'
				with: (Dictionary new
						at: 'entry' put: (self entryDictionaryFor: aTrackedTime);
						yourself) ]
]

{ #category : 'proposing' }
TtSuggester >> proposalFor: aTrackedTime [
	"Answer a TtSuggestion or nil. The first request proposes for every uncategorized entry of the
	collection in one call; later ones read the cache."

	aTrackedTime category ifNotNil: [ ^ nil ].
	self service isReady ifFalse: [ ^ nil ].
	(proposals includesKey: aTrackedTime)
		ifFalse: [ self
				proposeForUncategorizedIn: (aTrackedTime rootCollection ifNil: [ aTrackedTime collection ]) ].
	^ proposals at: aTrackedTime ifAbsent: [ nil ]
]

{ #category : 'accessing' }
TtSuggester >> proposals [
	^ proposals
]

{ #category : 'proposing' }
TtSuggester >> proposeForUncategorizedIn: aTtEventCollection [
	| pending results |
	aTtEventCollection ifNil: [ ^ self ].
	pending := (aTtEventCollection timeEntries
			select: [ :each | each category isNil and: [ (proposals includesKey: each) not ] ])
			asArray.
	pending ifEmpty: [ ^ self ].
	results := self service
			guard: [ self service
					call: 'suggest_many'
					with: (Dictionary new
							at: 'entries'
								put: (pending collect: [ :each | self entryDictionaryFor: each ]);
							at: 'k' put: 3;
							yourself) ].
	results ifNil: [ ^ self ].
	pending
		with: results asArray
		do: [ :anEntry :aDictionary | 
			proposals
				at: anEntry
				put: (TtSuggestion fromDictionary: aDictionary entry: anEntry) ]
]

{ #category : 'private' }
TtSuggester >> quietly: aBlock [
	"Proposer calls come from the UI: never break a view. Errors go to the debugger only in debug mode."

	^ [ aBlock value ]
		on: Error
		do: [ :anError | 
			TtSuggestionService debugMode ifTrue: [ anError pass ].
			nil ]
]

{ #category : 'training' }
TtSuggester >> retrain [
	proposals := IdentityDictionary new.
	self service trainInBackground: [ self trainingPayload ]
]

{ #category : 'accessing' }
TtSuggester >> service [
	^ TtSuggestionService default
]

{ #category : 'training' }
TtSuggester >> trainingPayload [
	"One category tree plus every categorized entry of every loaded collection. Pages share one
	tree (the UI keeps it that way), so the first loaded collection's tree is used."

	| collections |
	collections := TtEventCollection pageRegistry values
			select: [ :each | each size > 0 ].
	^ Dictionary new
		at: 'tree' put: (self treeDictionaryFor: collections first categories root);
		at: 'entries'
			put: ((collections flatCollect: [ :each | each timeEntries ])
					select: [ :each | (self categoryNameOf: each) notNil ]
					thenCollect: [ :each | self entryDictionaryFor: each ]) asArray;
		yourself
]

{ #category : 'converting' }
TtSuggester >> treeDictionaryFor: aCategory [
	^ Dictionary new
		at: 'name' put: aCategory name;
		at: 'children'
			put: (aCategory children collect: [ :each | self treeDictionaryFor: each ]) asArray;
		yourself
]
