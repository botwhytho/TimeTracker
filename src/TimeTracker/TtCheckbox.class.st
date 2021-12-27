Class {
	#name : #TtCheckbox,
	#superclass : #BrCheckbox,
	#category : #TimeTracker
}

{ #category : #accessing }
TtCheckbox >> icon [

	^ ((self userData at: #brickLook) children detect: [ :each | 
		   each isKindOf: BrGlamorousButtonIconAptitude ]) icon
]

{ #category : #accessing }
TtCheckbox >> icon: anIcon [

	((self userData at: #brickLook) children detect: [ :each | 
		 each isKindOf: BrGlamorousButtonIconAptitude ]) icon: anIcon
]

{ #category : #initialization }
TtCheckbox >> initialize [
	super initialize.

	self
		vLocal;
		hLocal;
		beNormalSize.

	self viewModel: (
		BrButtonModel new
			addAll: {
				TtCheckboxModel new.
				(BrInteractiveModel new
					addStates: {
						BrLayoutAlignmentModel center.
					}) } ).
					
	self uncheck
]

{ #category : #accessing }
TtCheckbox >> text [

	^ ((self userData at: #brickLook) children detect: [ :each | 
		   each isKindOf: BrGlamorousButtonLabelAptitude ]) text asString
]

{ #category : #accessing }
TtCheckbox >> text: aString [

	((self userData at: #brickLook) children detect: [ :each | 
		 each isKindOf: BrGlamorousButtonLabelAptitude ]) text:
		aString asRopedText
]
