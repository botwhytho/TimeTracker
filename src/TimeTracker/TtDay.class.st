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
	^ aView columnedList
		title: 'Dashboard' translated;
		priority: 1;
		items: [ self entries ];
		column: 'Time' text: [ :anEntry | anEntry span start asTime printMinutes , '-' , anEntry span end asTime printMinutes ];
		column: 'Activities' text: [ :anEntry | anEntry activities ];
		column: 'Categories' text: [ :anEntry | ', ' join: anEntry categories ]
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
