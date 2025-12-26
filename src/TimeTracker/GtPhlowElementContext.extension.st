Extension { #name : 'GtPhlowElementContext' }

{ #category : '*TimeTracker' }
GtPhlowElementContext >> fireViewSyncUpdateWish [
	"I fire an update wish to inform a Phlow view, that it should update its widgets. I do not delay"

	self firstParentWithViewContent phlow syncUpdate
]
