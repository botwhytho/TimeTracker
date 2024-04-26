Class {
	#name : #TtTrelloParser,
	#superclass : #Object,
	#category : #'TimeTracker-TimeTracker'
}

{ #category : #import }
TtTrelloParser >> add: anAssociation toCollection: aCollection [
	| entries |
	entries := (anAssociation value at: 'description') lines.
	entries
		do: [ :line | 
			| parsed |
			parsed := self entry parse: line.
			parsed isArray
				ifTrue: [ ($; split: parsed second)
						do: [ :each | 
							aCollection
								add: ((self parseTimeSpan: parsed first date: anAssociation key)
										in: [ :aTrackedTime | 
											| activity |
											activity := ($: split: each) collect: #trim.
											aTrackedTime description: activity first.
											activity size > 1 ifTrue: [ aTrackedTime details: activity last ].
											aTrackedTime
												rawData: line;
												collection: aCollection.
											aTrackedTime ]) ] ] ]
]

{ #category : #parsing }
TtTrelloParser >> entry [

	^ self timeEntry
]

{ #category : #import }
TtTrelloParser >> import: anAssociation [

	| metadata day entries |
	day := TtDay new
		       date: anAssociation key;
		       rawData: (anAssociation value at: 'raw').
	metadata := OrderedCollection new.
	entries := (anAssociation value at: 'description') lines.
	entries do: [ :line | 
		| parsed |
		parsed := self entry parse: line.
		parsed isArray
			ifTrue: [ 
				day entries add: (TtTimeEntry new
						 span:
							 (self parseTimeSpan: parsed first date: anAssociation key);
						 activities:
							 (($; split: parsed second) collect: [ :each | 
									  each trim -> nil ]);
						 yourself) ]
			ifFalse: [ metadata add: line ] ].
	day comments: (Character lf join: metadata).
	^ day
]

{ #category : #parsing }
TtTrelloParser >> line [
	^ #newline asPParser negate plus flatten
]

{ #category : #parsing }
TtTrelloParser >> minOrHour [
	^ (#digit asPParser min: 1 max: 2) flatten
]

{ #category : #parsing }
TtTrelloParser >> parseTimeSpan: anArray date: aDate [
	^ TtTrackedTime
		starting:
			aDate + (anArray first first asNumber * 3600)
				+ (anArray first second asNumber * 60)
		ending:
			aDate + (anArray second first asNumber * 3600)
				+ (anArray second second asNumber * 60)
]

{ #category : #parsing }
TtTrelloParser >> time [
	^ (self minOrHour , ':' asPParser optional , self minOrHour optional)
		==> [ :t | 
			{t first.
			(t third ifNil: [ '0' ])} ]
]

{ #category : #parsing }
TtTrelloParser >> timeEntry [
	^ (self timeRange , self line)
		==> [ :te | 
			{te first.
			te second trim} ]
]

{ #category : #parsing }
TtTrelloParser >> timeRange [

	^ ('-' asPParser / '*' asPParser , #space asPParser plus) optional
	  , self time , '-' asPParser , self time ==> [ :tr | 
	  { 
		  tr second.
		  tr fourth } ]
]
