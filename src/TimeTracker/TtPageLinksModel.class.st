Class {
	#name : #TtPageLinksModel,
	#superclass : #BrWidgetModel,
	#instVars : [
		'pageLinks',
		'timespan',
		'collection'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtPageLinksModel >> collection [
	^ collection
]

{ #category : #accessing }
TtPageLinksModel >> collection: aTtEventCollection [
	collection := aTtEventCollection
]

{ #category : #initialization }
TtPageLinksModel >> initializeListeners [
	self
		when: TtPageLinkAddedEvent
		do: [ :anEvent | anEvent consumed: true. self onTtPageLinkAddedEvent: anEvent  ].
	

]

{ #category : #initialization }
TtPageLinksModel >> onTtPageLinkAddedEvent: anEvent [
	self pageLinks add: anEvent page.
	self updatePageLinksButtonLabel.
	self pageLinks size > 0
		ifTrue: [ self widget pageLinksButton visibility: BlVisibility visible ]
]

{ #category : #accessing }
TtPageLinksModel >> pageLinks [
	^ pageLinks
]

{ #category : #accessing }
TtPageLinksModel >> pageLinks: aCollection [
	pageLinks := aCollection asSet.
	self updatePageLinksButtonLabel.
	pageLinks size = 0
		ifTrue: [ self widget pageLinksButton visibility: BlVisibility gone ]
]

{ #category : #accessing }
TtPageLinksModel >> timespan [
	^ timespan
]

{ #category : #accessing }
TtPageLinksModel >> timespan: aTimespan [
	timespan := aTimespan
]

{ #category : #initialization }
TtPageLinksModel >> updatePageLinksButtonLabel [
	self pageLinks size > 1
		ifTrue: [ self widget pageLinksButton label: self pageLinks size asString ]
]
