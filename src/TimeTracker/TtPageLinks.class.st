Class {
	#name : #TtPageLinks,
	#superclass : #BrWidgetContainer,
	#traits : 'TBrLayoutResizable',
	#classTraits : 'TBrLayoutResizable classTrait',
	#instVars : [
		'addPageLinkButton',
		'pageLinksButton'
	],
	#category : #TimeTracker
}

{ #category : #initialization }
TtPageLinks >> addPageLinkButton [
	^ addPageLinkButton
		ifNil: [ addPageLinkButton := GtSpotterDropdownButtonStencil new
					tooltip: 'Link to New or Existing Lepiter Page';
					object: TtLepiterPageSearchStart new;
					actOn: [ :anActOnEvent :anItem :aBrButton | 
						| aPage note |
						anActOnEvent beActed.
						aPage := (anItem isKindOf: LePage)
								ifTrue: [ anItem ]
								ifFalse: [ anItem createWithoutPager ].
						((self pageLinks collect: #page) includes: aPage)
							ifFalse: [ note := TtNote new
										start: self timespan start;
										duration: self timespan duration;
										database: aPage database;
										page: aPage;
										collection: self collection.
								self collection add: note ].
						aBrButton fireEvent: (TtPageLinkAddedEvent new page: aPage).
						aBrButton phlow spawnTool: aPage asLepiterPagePhlowTool.
						aBrButton fireEvent: BrDropdownHideWish new ];
					create ]
]

{ #category : #'accessing\t' }
TtPageLinks >> collection [
	^ self viewModel collection
]

{ #category : #'accessing\t' }
TtPageLinks >> collection: aTtEventCollection [
	self viewModel collection: aTtEventCollection
]

{ #category : #initialization }
TtPageLinks >> initialize [
	super initialize.
	self viewModel: TtPageLinksModel new.
	self layout: BlLinearLayout horizontal.
	self aptitude: BrLayoutAlignmentStatelessAptitude new.
	self
		matchParent;
		addChildren: {self addPageLinkButton.
				self pageLinksButton}
]

{ #category : #accessing }
TtPageLinks >> pageLinks [
	^ self viewModel pageLinks
]

{ #category : #accessing }
TtPageLinks >> pageLinks: aCollection [
	self viewModel pageLinks: aCollection asIdentitySet
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
													label: eachPage page title;
													action: [ :aBrButton :aBrButtonModel :aBlClickEvent | 
														aBlClickEvent consumed: true.
														pageLinksButton phlow spawnTool: eachPage page asLepiterPagePhlowTool.
														aBrButton fireEvent: BrDropdownHideWish new ] ];
											items: self pageLinks asArray ]) ]
]

{ #category : #'accessing\t' }
TtPageLinks >> timespan [
	^ self viewModel timespan
]

{ #category : #'accessing\t' }
TtPageLinks >> timespan: aTimespan [
	self viewModel timespan: aTimespan
]
