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
					action: [ :aBrButton :aBrButtonModel :aBlClickEvent | aBrButton fireEvent: (TtPageLinkAddedEvent new page: self pageLinks asArray first) ] ]
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
					label: '';
					icon: BrGlamorousVectorIcons note;
					aptitude: BrGlamorousButtonWithIconAndLabelAptitude
							+ (BrGlamorousWithDropdownAptitude
									handle: [ BrButton new
											label: pageLinksButton label;
											icon: BrGlamorousVectorIcons note;
											aptitude: BrGlamorousButtonWithIconAndLabelAptitude ]
									content: [ BrSimpleList new
											padding: (BlInsets all: 5);
											itemStencil: [ BrButton new
													hMatchParent;
													vFitContent;
													aptitude: BrGlamorousButtonWithLabelAptitude ];
											itemDataBinder: [ :eachElement :eachPage :eachIndex | 
												eachElement
													label: eachPage title;
													action: [ :aBrButton :aBrButtonModel :aBlClickEvent | 
														aBlClickEvent consumed: true.
														aBrButton phlow spawnTool: eachPage asLepiterPagePhlowTool.
														aBrButton fireEvent: BrDropdownHideWish new ] ];
											items: self pageLinks ]) ]
]
