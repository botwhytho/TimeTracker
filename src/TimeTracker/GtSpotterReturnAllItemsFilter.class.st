Class {
	#name : 'GtSpotterReturnAllItemsFilter',
	#superclass : 'GtSpotterSubstringFilter',
	#category : 'TimeTracker-Filters',
	#package : 'TimeTracker',
	#tag : 'Filters'
}

{ #category : 'evaluating' }
GtSpotterReturnAllItemsFilter >> applyInScope: aStream context: aSpotterContext [
	^ (GtSpotterSubstringFilterStream
		forStream: aStream
		search: aSpotterContext searchQuery)
		itemString: [ :_ | aSpotterContext searchQuery ]
]
