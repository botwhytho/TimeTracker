Class {
	#name : #TtCalendarDateClickedEvent,
	#superclass : #GtCalendarDateClickedEvent,
	#instVars : [
		'clickEvent'
	],
	#category : #'TimeTracker-Calendar'
}

{ #category : #accessing }
TtCalendarDateClickedEvent >> clickEvent [
	^ clickEvent
]

{ #category : #accessing }
TtCalendarDateClickedEvent >> clickEvent: aBlClickEvent [
	clickEvent := aBlClickEvent
]
