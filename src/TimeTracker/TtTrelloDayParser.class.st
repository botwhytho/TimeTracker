Class {
	#name : #TtTrelloDayParser,
	#superclass : #Object,
	#category : #'TimeTracker-TimeTracker'
}

{ #category : #parsing }
TtTrelloDayParser >> entry [
	^ self timeEntry / self line
]

{ #category : #import }
TtTrelloDayParser >> import: anAssociation [

	| metadata day entries |
	day := TtDay new
		       date: anAssociation key;
		       rawData: (anAssociation value at: 'raw').
	metadata := OrderedCollection new.
	entries := self lines parse: (anAssociation value at: 'description').
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
			ifFalse: [ metadata add: parsed ] ].
	day comments: metadata.
	^ day
]

{ #category : #parsing }
TtTrelloDayParser >> line [
	^ #newline asPParser negate plus flatten
]

{ #category : #parsing }
TtTrelloDayParser >> lines [
	^ ((self line , #newline asPParser optional) ==> #first) plus
]

{ #category : #parsing }
TtTrelloDayParser >> minOrHour [
	^ (#digit asPParser min: 1 max: 2) flatten
]

{ #category : #parsing }
TtTrelloDayParser >> parseTimeSpan: anArray date: aDate [
	^ Timespan
		starting:
			aDate + (anArray first first asNumber * 3600)
				+ (anArray first second asNumber * 60)
		ending:
			aDate + (anArray second first asNumber * 3600)
				+ (anArray second second asNumber * 60) + 60
]

{ #category : #parsing }
TtTrelloDayParser >> time [
	^ (self minOrHour , ':' asPParser optional , self minOrHour optional)
		==> [ :t | 
			{t first.
			(t third ifNil: [ '0' ])} ]
]

{ #category : #parsing }
TtTrelloDayParser >> timeEntry [
	^ (self timeRange , self line)
		==> [ :te | 
			{te first.
			te second trim} ]
]

{ #category : #parsing }
TtTrelloDayParser >> timeRange [

	^ ('-' asPParser / '*' asPParser , #space asPParser plus) optional
	  , self time , '-' asPParser , self time ==> [ :tr | 
	  { 
		  tr second.
		  tr fourth } ]
]
