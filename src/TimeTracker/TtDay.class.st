Class {
	#name : #TtDay,
	#superclass : #Object,
	#instVars : [
		'date',
		'entries'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtDay >> TtDayDashboard: aView [
	<gtView>
	^ aView columnedList
		title: 'Dashboard' translated;
		priority: 1;
		items: [ self entries ];
		column: 'Time' text: [ :anEntry | anEntry span ];
		column: 'Activities' text: [ :anEntry | anEntry activities ]
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
	^ entries ifNil: [ entries := SortedCollection sortUsing: [:a :b | a span < b span] ]
]
