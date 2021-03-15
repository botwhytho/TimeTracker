Class {
	#name : #TtTimeEntry,
	#superclass : #Object,
	#instVars : [
		'span',
		'activities',
		'categories'
	],
	#category : #TimeTracker
}

{ #category : #view }
TtTimeEntry >> TtTimeEntryDashboard: aView [
	<gtView>
	^ aView columnedList
		title: (self span start asTime printMinutes , '-' , self span end asTime printMinutes);
		priority: 1;
		items: [ { self } ];
		column: 'Activities' text: [ :anEntry | anEntry activities ];
		column: 'Categories' text: [ :anEntry | ', ' join: anEntry categories ]
]

{ #category : #accessing }
TtTimeEntry >> activities [
	^ activities
]

{ #category : #accessing }
TtTimeEntry >> activities: someActivities [
	activities := someActivities
]

{ #category : #accessing }
TtTimeEntry >> categories [
	^ categories ifNil: [ categories := OrderedCollection new ]
]

{ #category : #accessing }
TtTimeEntry >> span [
	^ span
]

{ #category : #accessing }
TtTimeEntry >> span: aTimeSpan [
	span := aTimeSpan
]
