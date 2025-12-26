Class {
	#name : 'TtTrelloImporter',
	#superclass : 'Object',
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'import' }
TtTrelloImporter class >> fetch [
	| result |
	result := NeoJSONReader
			fromString: (ZnClient new
					get: 'https://api.trello.com/1/lists/' , TrelloTimeTrackerList , '/cards?key='
							, TrelloKey , '&token=' , TrelloToken).
	^ (result
		reject: [ :item | ([ (item at: 'name') asDate ] ifError: [ false ]) isBoolean ]
		thenCollect: [ :item | 
			(item at: 'name') asDate
				-> {'description' -> (item at: 'desc').
						'id' -> (item at: 'id').
						'trelloUrl' -> (item at: 'shortUrl')} asDictionary ]) asDictionary
]

{ #category : 'import' }
TtTrelloImporter >> fetchRaw [
	| result |
	result := NeoJSONReader
			fromString: (ZnClient new
					get: 'https://api.trello.com/1/lists/' , TrelloTimeTrackerList , '/cards?key='
							, TrelloKey , '&token=' , TrelloToken).
	^ (result
		reject: [ :item | [ [ (item at: 'name') asDate ] ifError: [ false ] ] value isBoolean ]
		thenCollect: [ :item | 
			(item at: 'name') asDate
				-> {'description' -> (item at: 'desc').
						'raw' -> item} asDictionary ]) asDictionary
]
