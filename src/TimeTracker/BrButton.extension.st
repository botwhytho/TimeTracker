Extension { #name : #BrButton }

{ #category : #'*TimeTracker' }
BrButton >> enableAllModifiers [
	self flag: #TEMPFIX.	"Fickle implementation. This should be implemented properly upstream with a PR."
	self eventDispatcher
		removeEventHandler: (self eventDispatcher handlers
				detect: [ :each | 
					(each isKindOf: BlEventForwarder)
						and: [ each eventHandler eventClass = BlClickEvent
								and: [ each eventTarget isKindOf: BrButtonModel ] ] ])
]
