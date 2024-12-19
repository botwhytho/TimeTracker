Class {
	#name : #TtLepiterPageSearchStart,
	#superclass : #Object,
	#instVars : [
		'knowledgeBase'
	],
	#category : #TimeTracker
}

{ #category : #spotter }
TtLepiterPageSearchStart >> gtDefaultSearchFor: aSearch [
	<gtSearch>
	self flag: #TODO "What to do when you enspect a category instead of item?".
	^ aSearch list
		priority: 1;
		items: [ {LeNotePlaygroundStencil new
				knowledgeBase: self knowledgeBase".
				GtPlaygroundStencil new knowledgeBase: self knowledgeBase"} ];
		title: 'Create a New Page';
		filter: GtSpotterReturnAllItemsFilter new;
		previewElement: [ :aStencil | aStencil asPreviewElement asElement ];
		withoutItemAction;
		wantsToDisplayOnEmptyQuery: true
]

{ #category : #spotter }
TtLepiterPageSearchStart >> gtSearchPagesByTitleFor: aSearch [
	<gtSearch>
	self flag: #TODO "What to do when you enspect a category instead of item?".
	^ aSearch explicit
		title: 'Named pages';
		priority: 2;
		search: [ :aContext | self knowledgeBase asyncPagesForWord: aContext searchQuery ];
		itemName: #title;
		withoutItemAction;
		wantsToDisplayOnEmptyQuery: false
]

{ #category : #spotter }
TtLepiterPageSearchStart >> gtSpotterContainingSubPartsFor: aSearch [
	<gtSearch>
	self flag: #TODO "What to do when you enspect a category instead of item?".
	^ aSearch explicit
		priority: 3;
		title: 'Page contents';
		search: [ :aContext | 
			[ | filter results |
			results := OrderedCollection new.
			filter := LeSubstringFilter new
					caseSensitive: false;
					query: aContext searchQuery.
			self knowledgeBase
				pagesWithNameDo: [ :eachPage | (filter isMatchedItem: eachPage) ifTrue: [ results add: eachPage ] ].
			self knowledgeBase
				unnamedPagesDo: [ :eachPage | (filter isMatchedItem: eachPage) ifTrue: [ results add: eachPage ] ].
			results asAsyncStream ] asAsyncFuture asAsyncStream flatten ];
		itemName: #spotterItemName
]

{ #category : #accessing }
TtLepiterPageSearchStart >> knowledgeBase [
	self flag: #TODO.	"Enable cross-database search"
	^ knowledgeBase
		ifNil: [ LeDatabasesRegistry uniqueInstance currentLoadedDefaultLogicalDatabase ]
]

{ #category : #accessing }
TtLepiterPageSearchStart >> knowledgeBase: anObject [
	knowledgeBase := anObject
]

{ #category : #'as yet unclassified' }
TtLepiterPageSearchStart >> printOn: aStream [
	"super printOn: aStream."

	aStream nextPutAll: 'Link time entry to new or existing Lepiter Page'
]
