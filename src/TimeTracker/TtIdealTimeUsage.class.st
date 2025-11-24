Class {
	#name : #TtIdealTimeUsage,
	#superclass : #Timespan,
	#instVars : [
		'category',
		'leeway',
		'minValue',
		'maxValue',
		'priority',
		'timePeriod',
		'computation',
		'description'
	],
	#category : #TimeTracker
}

{ #category : #comparing }
TtIdealTimeUsage >> = comparand [
	self flag: #NOTE.	"Below asumes that two ideal times on same time span cannot exist on the same category, seems like a mistake that the UI should prevent from doing. If not, need to compare and hash on many other fields"
	^ super = comparand
		and: [ self category = comparand category
				and: [ self description = comparand description ] ]
]

{ #category : #accessing }
TtIdealTimeUsage >> category [
	^ category
]

{ #category : #accessing }
TtIdealTimeUsage >> category: anObject [
	category := anObject
]

{ #category : #accessing }
TtIdealTimeUsage >> computation [
	^ computation
]

{ #category : #accessing }
TtIdealTimeUsage >> computation: anObject [
	computation := anObject
]

{ #category : #accessing }
TtIdealTimeUsage >> description [
	^ description
]

{ #category : #accessing }
TtIdealTimeUsage >> description: anObject [
	description := anObject
]

{ #category : #comparing }
TtIdealTimeUsage >> hash [
	^ super hash + category hash + description hash
]

{ #category : #accessing }
TtIdealTimeUsage >> leeway [
	^ leeway
]

{ #category : #accessing }
TtIdealTimeUsage >> leeway: anObject [
	leeway := anObject
]

{ #category : #accessing }
TtIdealTimeUsage >> maxValue [
	^ maxValue
]

{ #category : #accessing }
TtIdealTimeUsage >> maxValue: anObject [
	maxValue := anObject
]

{ #category : #accessing }
TtIdealTimeUsage >> minValue [
	^ minValue
]

{ #category : #accessing }
TtIdealTimeUsage >> minValue: anObject [
	minValue := anObject
]

{ #category : #printing }
TtIdealTimeUsage >> printOn: aStream [
	aStream
		nextPutAll: (self category ifNil: [ self description ] ifNotNil: [ :notNil | notNil name ])
				, ' for ' , (self minValue * 100 printShowingDecimalPlaces: 2) , '-'
				, (self maxValue * 100 printShowingDecimalPlaces: 2) , '% of your time'
]

{ #category : #accessing }
TtIdealTimeUsage >> priority [
	^ priority
]

{ #category : #accessing }
TtIdealTimeUsage >> priority: anObject [
	priority := anObject
]

{ #category : #accessing }
TtIdealTimeUsage >> timePeriod [
	^ timePeriod
]

{ #category : #accessing }
TtIdealTimeUsage >> timePeriod: anObject [
	timePeriod := anObject
]
