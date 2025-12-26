Class {
	#name : 'TtRootCategory',
	#superclass : 'TtCategory',
	#instVars : [
		'collection',
		'uid'
	],
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'accessing' }
TtRootCategory >> collection [
	^ collection
]

{ #category : 'accessing' }
TtRootCategory >> collection: aTtEventCollection [
	collection := aTtEventCollection
]

{ #category : 'views' }
TtRootCategory >> gtCollectionActionFor: anAction [
	<gtAction>
	^ anAction button
		label: 'Colllection';
		action: [ :aBrButton :aBrTab :aBrButttonModel :aBlClickEvent | aBrButton phlow spawnObject: self collection ]
]

{ #category : 'views' }
TtRootCategory >> gtHierarchyFor: aView [
	<gtView>
	^ aView forward
		title: 'Hierarchy';
		priority: 1;
		object: [ hierarchy ];
		view: #TtCategoriesFor:context:
]

{ #category : 'search' }
TtRootCategory >> gtSpotterForCategoryFor: aSearch [
	self flag: #TODO	"Be able to search category hierarchiex"
]

{ #category : 'accessing' }
TtRootCategory >> uid [
	^ uid
]

{ #category : 'accessing' }
TtRootCategory >> uid: anObject [
	uid := anObject
]
