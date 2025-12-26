Class {
	#name : 'TtPageLinkAddedEvent',
	#superclass : 'BlEvent',
	#instVars : [
		'page'
	],
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'accessing' }
TtPageLinkAddedEvent >> page [
	^ page
]

{ #category : 'accessing' }
TtPageLinkAddedEvent >> page: aLePage [
	page := aLePage
]
