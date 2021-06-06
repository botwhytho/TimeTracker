Class {
	#name : #TtDay,
	#superclass : #Object,
	#instVars : [
		'date',
		'entries',
		'comments'
	],
	#category : #TimeTracker
}

{ #category : #view }
TtDay >> TtDayDashboardFor: aView [
	<gtView>
	^ aView columnedTree
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
			text: [ :anEntry | 
			(anEntry isKindOf: TtTimeEntry)
				ifTrue: [ anEntry activities size > 1
						ifTrue: [ '' ]
						ifFalse: [ anEntry activities first value ] ]
				ifFalse: [ anEntry value ] ]
]

{ #category : #accessing }
TtDay >> comments [
	^ comments
]

{ #category : #accessing }
TtDay >> comments: aComment [
	comments := aComment
]

{ #category : #accessing }
TtDay >> date [
	^ date
]

{ #category : #accessing }
TtDay >> date: aDate [
	date := aDate
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
