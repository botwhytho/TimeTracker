Class {
	#name : 'TtRootCategory',
	#superclass : 'TtCategory',
	#traits : 'TtSerializedObjetTrait',
	#classTraits : 'TtSerializedObjetTrait classTrait',
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'initialization' }
TtRootCategory class >> initialize [
	super initialize.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newReader.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : 'lepiter-store' }
TtRootCategory class >> leJsonV3Name [
	^ #TtRootCategory
]

{ #category : 'lepiter-store' }
TtRootCategory class >> leJsonV4Name [
	^ #TtRootCategory
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
TtRootCategory >> rootCollection [
	^ self collection rootCollection
]
