Class {
	#name : #TtTimeEntry,
	#superclass : #Object,
	#instVars : [
		'span',
		'activities'
	],
	#category : #TimeTracker
}

{ #category : #view }
TtTimeEntry >> TtTimeEntryDashboardFor: aView [
	<gtView>
	^ aView columnedList
		title:
			self span start asTime printMinutes , '-'
				, self span end asTime printMinutes;
		priority: 1;
		items: [ self activities ];
		column: 'Activities' text: [ :anEntry | anEntry key ];
		column: 'Categories' text: [ :anEntry | anEntry value name ]
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
TtTimeEntry >> span [
	^ span
]

{ #category : #accessing }
TtTimeEntry >> span: aTimeSpan [
	span := aTimeSpan
]
