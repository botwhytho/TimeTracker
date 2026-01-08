Extension { #name : 'LeDatabase' }

{ #category : '*TimeTracker' }
LeDatabase >> pagesByName [
	"Answer the pages by name.
	This is internal structure that may change."

	"^ pagesByType at: LeNamedPageType"
	| namedPageClasses |
	namedPageClasses := (pagesByType associations
			select: [ :each | each key = LeNamedPageType or: [ each key inheritsFrom: LeNamedPageType ] ])
			sorted: [ :each | each value size ] descending.
	^ namedPageClasses allButFirst
		inject: namedPageClasses first value
		into: [ :acc :each | acc , each value ]
]
