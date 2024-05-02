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
	^ aSearch list
		priority: 1;
		items: [ LeNotePlaygroundStencil new
				knowledgeBase: self knowledgeBase;
				asArray ];
		title: 'Create a New Page';
		filterBySubstring;
		previewElement: [ :aStencil | aStencil asPreviewElement asElement ];
		withoutItemAction;
		wantsToDisplayOnEmptyQuery: true
]

{ #category : #spotter }
TtLepiterPageSearchStart >> gtSearchPagesByTitleFor: aSearch [
	<gtSearch>
	^ aSearch explicit
		title: 'Named pages';
		priority: 22;
		search: [ :aContext | self knowledgeBase asyncPagesForWord: aContext searchQuery ];
		itemName: #title;
		withoutItemAction;
		wantsToDisplayOnEmptyQuery: false
]

{ #category : #spotter }
TtLepiterPageSearchStart >> gtSpotterContainingSubPartsFor: aSearch [
	<gtSearch>
	^ aSearch explicit
		priority: 23;
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
	^ knowledgeBase
		ifNil: [ LeDatabasesRegistry uniqueInstance currentLoadedDefaultLogicalDatabase ]
]

{ #category : #accessing }
TtLepiterPageSearchStart >> knowledgeBase: anObject [
	knowledgeBase := anObject
]
