Class {
	#name : #TtPageLinks,
	#superclass : #BlElement,
	#traits : 'TBrLayoutResizable + TBrLayoutAlignable',
	#classTraits : 'TBrLayoutResizable classTrait + TBrLayoutAlignable classTrait',
	#instVars : [
		'addPageLinkButton',
		'pageLinksButton'
	],
	#category : #TimeTracker
}

{ #category : #initialization }
TtPageLinks >> addPageLinkButton [
	^ addPageLinkButton
		ifNil: [ addPageLinkButton := BrButton new
					aptitude: BrGlamorousButtonWithIconAndLabelAptitude;
					icon: BrGlamorousVectorIcons search;
					label: '';
					action: [ :aBrButton :aBrButtonModel :aBlClickEvent | aBrButton fireEvent: (TtPageLinkAddedEvent new page: aBrButton label) ] ]
]

{ #category : #initialization }
TtPageLinks >> initialize [
	super initialize.
	self viewModel: TtPageLinksModel new.
	self layout: BlLinearLayout horizontal.
	self aptitude: BrLayoutAlignmentStatelessAptitude new.
	self
		matchParent;
		alignCenter;
		addChildren: {self addPageLinkButton.
				self pageLinksButton}
]

{ #category : #accessing }
TtPageLinks >> pageLinks [
	^ self viewModel pageLinks
]

{ #category : #accessing }
TtPageLinks >> pageLinks: aCollection [
	self viewModel pageLinks: aCollection
]

{ #category : #initialization }
TtPageLinks >> pageLinksButton [
	^ pageLinksButton
		ifNil: [ pageLinksButton := BrButton new
					aptitude: BrGlamorousButtonWithIconAndLabelAptitude;
					label: '';
					icon: BrGlamorousVectorIcons note;
					action: [ :aBrButton :aBrButtonModel :aBlClickEvent |  ] ]
]
