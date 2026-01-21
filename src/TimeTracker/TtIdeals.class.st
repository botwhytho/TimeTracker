Class {
	#name : 'TtIdeals',
	#superclass : 'Timespan',
	#traits : 'TtSerializedObjetTrait',
	#classTraits : 'TtSerializedObjetTrait classTrait',
	#instVars : [
		'ideals',
		'description',
		'notes',
		'collection',
		'needsFlushing'
	],
	#category : 'TimeTracker',
	#package : 'TimeTracker'
}

{ #category : 'initialization' }
TtIdeals class >> initialize [
	super initialize.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newReader.
	self leJsonV4MappingFor: LeJsonV4 uniqueInstance newWriter
]

{ #category : 'serialization' }
TtIdeals class >> leJsonV4MappingFor: aNeoJSONMapper [
	aNeoJSONMapper
		for: self
		do: [ :aMapping | 
			aMapping
				mapProperty: #__type
				getter: [ :object | object class leJsonV4Name ]
				setter: [ :um | self error: 'Objects should not be read here' ].
			aMapping mapInstVars: #(description duration ideals notes start) ]
]

{ #category : 'lepiter-store' }
TtIdeals class >> leJsonV4Name [
	^ #TtIdeals
]

{ #category : 'accessing' }
TtIdeals class >> snippetClass [
	^ TtIdealsSnippet
]

{ #category : 'accessing' }
TtIdeals >> collection [
	^ collection
]

{ #category : 'accessing' }
TtIdeals >> collection: anObject [
	collection := anObject
]

{ #category : 'accessing' }
TtIdeals >> description [
	^ description
]

{ #category : 'accessing' }
TtIdeals >> description: aString [
	description := aString
]

{ #category : 'views' }
TtIdeals >> gtPreviewFor: aView [
	<gtView>
	self flag: #TODO.	"Might need to incorporate Maggritte"
	^ aView columnedList
		title: 'Ideals';
		priority: 1;
		items: [ self ideals ];
		column: 'Name'
			text: [ :each | 
				each description
					ifNil: [ each category ifNil: [ '' ] ifNotNil: [ :notNil | notNil name ] ] ];
		column: 'Min Value'
			text: [ :each | 
				each minValue isFraction
					ifTrue: [ each minValue asString ]
					ifFalse: [ each minValue printShowingDecimalPlaces: 4 ] ];
		column: 'Min Value'
			text: [ :each | 
				each maxValue isFraction
					ifTrue: [ each maxValue asString ]
					ifFalse: [ each maxValue printShowingDecimalPlaces: 4 ] ];
		column: 'Leeway'
			text: [ :each | 
				each leeway isFraction
					ifTrue: [ each leeway asString ]
					ifFalse: [ each leeway printShowingDecimalPlaces: 4 ] ];
		column: 'Categories'
			stencil: [ :each | 
				| aMenuItems |
				aMenuItems := BrMenuItems new.
				self collection categories
					do: [ :aCategory | aMenuItems addItemLabel: aCategory name action: [  ] ].
				aMenuItems.
				BrButton new
					aptitude: BrGlamorousButtonWithLabelAptitude;
					label: 'Test';
					addAptitude: (BrWithExplicitDropdownAptitude
							handle: [ BrButton new
									aptitude: BrGlamorousButtonWithLabelAptitude - BrGlamorousButtonExteriorAptitude;
									label: 'Test' ]
							menu: (BrMenuSubmenuItem new
									label: 'test';
									action: [ :one :two :three :four | self halt ];
									submenuItem: (BrMenuActionItem new
											label: 'test2';
											action: [  ]) ));
					yourself ];
		actionDropdownButtonDo: [ :aDropdown | 
			aDropdown
				icon: [ BrGlamorousVectorIcons timeTrackerCalendar asElement asScalableElement
						size: 20 @ 20 ] asStencil;
				label: 'From: ' , self start asDate yyyymmdd;
				content: [ :aBrButton :aBrTab :aBrMenuExplicit | 
					(MyGtCalendarElement forDate: self start asDate)
						when: GtCalendarDateClickedEvent
						do: [ :anEvent | 
							anEvent consumed: true.
							self start: anEvent date asDateAndTime.
							self needsFlushing: true.
							aBrButton phlow fireToolUpdateWish ] ] ];
		actionDropdownButtonDo: [ :aDropdown | 
			aDropdown
				icon: [ BrGlamorousVectorIcons timeTrackerCalendar asElement asScalableElement
						size: 20 @ 20 ] asStencil;
				label: 'To: ' , self end asDate yyyymmdd;
				content: [ :aBrButton :aBrTab :aBrMenuExplicit | 
					(MyGtCalendarElement forDate: self end asDate)
						when: GtCalendarDateClickedEvent
						do: [ :anEvent | 
							anEvent consumed: true.
							self duration: anEvent date asDateAndTime - self start.
							self needsFlushing: true.
							aBrButton phlow fireToolUpdateWish ] ] ];
		actionButtonIcon: BrGlamorousVectorIcons accept
			label: 'Save' , (self needsFlushing ifTrue: [ '*' ] ifFalse: [ '' ])
			action: [ :aBrButton :aBrTab :aBrButtonModel :aBlClickEvent | 
				self needsFlushing: false.
				aBrButton phlow fireToolUpdateWish ];
		actionDropdownButtonDo: [ :aDropdown | 
			aDropdown
				icon: BrGlamorousVectorIcons copyToClipboard;
				label: 'Clone';
				menu: [ :aBrButton :aBrTab | 
					| menuItems |
					menuItems := BrMenuItems new.
					menuItems
						addItemLabel: 'Clone Starting Today'
							action: [ :aBrMenuActionItemElement :aBrButtonModel :aBlClickEvent |  ];
						addItemLabel: 'Clone Starting Tomorrow'
							action: [ :aBrMenuActionItemElement :aBrButtonModel :aBlClickEvent |  ];
						addItemLabel: 'Clone Starting Next Week'
							action: [ :aBrMenuActionItemElement :aBrButtonModel :aBlClickEvent |  ];
						addItemLabel: 'Clone With Custom Date Range'
							action: [ :aBrMenuActionItemElement :aBrButtonModel :aBlClickEvent |  ] ] ]
]

{ #category : 'accessing' }
TtIdeals >> ideals [
	^ ideals
		ifNil: [ ideals := SortedCollection sortUsing: [ :each | each maxValue ] descending ]
]

{ #category : 'accessing' }
TtIdeals >> ideals: anObject [
	ideals := anObject
]

{ #category : 'accessing' }
TtIdeals >> needsFlushing [
	^ needsFlushing ifNil: [ needsFlushing := false ]
]

{ #category : 'accessing' }
TtIdeals >> needsFlushing: anObject [
	needsFlushing := anObject
]

{ #category : 'accessing' }
TtIdeals >> notes [
	^ notes ifNil: [ notes := OrderedCollection new ]
]

{ #category : 'accessing' }
TtIdeals >> notes: anObject [
	notes := anObject
]
