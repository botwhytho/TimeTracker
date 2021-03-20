Class {
	#name : #TtTrelloImporter,
	#superclass : #Object,
	#category : #TimeTracker
}

{ #category : #import }
TtTrelloImporter class >> fetch [
	| result |
	result := NeoJSONReader
		fromString:
			(ZnClient new
				get:
					'https://api.trello.com/1/lists/' , TrelloTimeTrackerList
						, '/cards?key=' , TrelloKey , '&token=' , TrelloToken).
	^ (result
		reject:
			[ :item | [ [ (item at: 'name') asDate ] ifError: [ false ] ] value isBoolean ]
		thenCollect: [ :item | (item at: 'name') asDate -> (item at: 'desc') ])
		asDictionary
]
