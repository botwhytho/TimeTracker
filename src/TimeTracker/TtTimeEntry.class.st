Class {
	#name : #TtTimeEntry,
	#superclass : #Object,
	#instVars : [
		'span',
		'activities'
	],
	#category : #TimeTracker
}

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
