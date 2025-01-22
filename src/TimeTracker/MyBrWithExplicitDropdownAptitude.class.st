Class {
	#name : #MyBrWithExplicitDropdownAptitude,
	#superclass : #BrWithExplicitMenuAptitude,
	#category : #TimeTracker
}

{ #category : #'instance creation' }
MyBrWithExplicitDropdownAptitude class >> handle: aHandleStencil content: aContentStencil [
	^ self new
		handle: aHandleStencil
		submenu: (BrMenuExplicit new stencil: aContentStencil)
]

{ #category : #initialization }
MyBrWithExplicitDropdownAptitude >> initialize [
	super initialize.
	self
		usePrimaryMouseButton;
		withWidgetBoundsRelocator
]

{ #category : #initialization }
MyBrWithExplicitDropdownAptitude >> initializeEventHandlers [
	addedToSceneEventHandler := BlEventHandler
			on: BlElementAddedToSceneGraphEvent
			do: [ :anEvent | self onWidgetAddedToSceneGraph: anEvent ].

	removedFromSceneEventHandler := BlEventHandler
			on: BlElementRemovedFromSceneGraphEvent
			do: [ :anEvent | self onWidgetRemovedFromSceneGraph: anEvent ].

	extentChangedEventHandler := BlEventHandler
			on: BlElementExtentChangedEvent
			do: [ :anEvent | self onWidgetExtentChanged: anEvent ].

	positionInSpaceChangedEventHandler := BlEventHandler
			on: BlElementPositionInSpaceChangedEvent
			do: [ :anEvent | self onWidgetPositionChanged: anEvent ].

	clickOutsideEventHandler := BlEventHandler
			on: BlMouseUpEvent
			do: [ :anEvent | 
				self onClickedOutsideMouseUpEvent: anEvent.
				self widget deactivate ].

	pressEscEventHandler := BlShortcutWithAction new
			combination: BlKeyCombination escape;
			action: [ :anEvent | 
				self hide.
				self widget deactivate ]
]

{ #category : #'event handling' }
MyBrWithExplicitDropdownAptitude >> onMouseUp: anEvent [
	anEvent button = mouseButton ifFalse: [ ^ self ].

	(modifiersMatcher value: anEvent modifiers) ifFalse: [ ^ self ].

	anEvent consumed: true.

	self widgetDo: [ :aWidget | relocator mouseUp: anEvent given: aWidget ].
	self widget isActivated ifTrue: [ self hide ] ifFalse: [ self show ]
]
