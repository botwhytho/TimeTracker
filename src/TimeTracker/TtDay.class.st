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
TtDay >> TtDayDashboard: aView [
	<gtView>
	^ aView columnedTree
		expandAll;
		title: 'Dashboard' translated;
		priority: 1;
		items: [ self entries ];
		children: [ :each | 
			(each isString not and: [ each activities size > 1 ])
				ifTrue: [ each activities ]
				ifFalse: [ #() ] ];
		column: 'Time'
			text: [ :anEntry | 
			anEntry isString
				ifTrue: [ '' ]
				ifFalse: [ anEntry span start asTime printMinutes , '-'
						, anEntry span end asTime printMinutes ] ];
		column: 'Activities'
			text: [ :anEntry | 
			anEntry isString
				ifTrue: [ anEntry ]
				ifFalse: [ anEntry activities size > 1
						ifTrue: [ '' ]
						ifFalse: [ anEntry activities first ] ] ];
		column: 'Categories' text: ''
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
