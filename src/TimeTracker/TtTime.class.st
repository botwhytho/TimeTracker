Class {
	#name : #TtTime,
	#superclass : #Object,
	#instVars : [
		'days'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtTime >> TtTimeDashboard: aView [
	<gtView>
	^ aView columnedList
		title: 'Dashboard' translated;
		priority: 1;
		items: [ self days ];
		column: 'Days' text: [ :aDay | aDay date ]
]

{ #category : #accessing }
TtTime >> days [
	^ days ifNil: [ days := SortedCollection sortUsing: [:a :b | a date > b date] ]
]
