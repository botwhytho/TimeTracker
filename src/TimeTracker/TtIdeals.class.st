Class {
	#name : #TtIdeals,
	#superclass : #Timespan,
	#instVars : [
		'ideals',
		'description',
		'notes',
		'collection',
		'needsFlushing'
	],
	#category : #TimeTracker
}

{ #category : #accessing }
TtIdeals >> collection [
	^ collection
]

{ #category : #accessing }
TtIdeals >> collection: anObject [
	collection := anObject
]

{ #category : #accessing }
TtIdeals >> description [
	^ description
]

{ #category : #accessing }
TtIdeals >> description: aString [
	description := aString
]

{ #category : #views }
TtIdeals >> gtPreviewFor: aView [
	<gtView>
	self flag: #TODO.	"Might need to incorporate Maggritte"
	^ aView columnedList
		title: 'Ideals';
		priority: 1;
		items: [ self ideals ];
		column: 'Name' text: #asString;
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

{ #category : #accessing }
TtIdeals >> ideals [
	^ ideals
		ifNil: [ ideals := SortedCollection sortUsing: [ :each | each maxValue ] descending ]
]

{ #category : #accessing }
TtIdeals >> ideals: anObject [
	ideals := anObject
]

{ #category : #accessing }
TtIdeals >> needsFlushing [
	^ needsFlushing ifNil: [ needsFlushing := false ]
]

{ #category : #accessing }
TtIdeals >> needsFlushing: anObject [
	needsFlushing := anObject
]

{ #category : #accessing }
TtIdeals >> notes [
	^ notes ifNil: [ notes := OrderedCollection new ]
]

{ #category : #accessing }
TtIdeals >> notes: anObject [
	notes := anObject
]
