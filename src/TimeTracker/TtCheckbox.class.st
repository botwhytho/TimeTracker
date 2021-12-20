Class {
	#name : #TtCheckbox,
	#superclass : #BrCheckbox,
	#category : #TimeTracker
}

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
