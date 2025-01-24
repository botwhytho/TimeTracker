Class {
	#name : #MyGtCalendarElement,
	#superclass : #BrHorizontalGrid,
	#instVars : [
		'date',
		'currentMonth',
		'controls',
		'dayElements'
	],
	#category : #'TimeTracker-Calendar'
}

{ #category : #'instance creation' }
MyGtCalendarElement class >> forDate: aDate [
	^ self new
		enableControls;
		date: aDate;
		yourself
]

{ #category : #'private ui' }
MyGtCalendarElement >> buildDays [
	| current last |
	current := currentMonth.
	last := currentMonth addMonths: 1.
	1
		to: current dayOfWeek - 1
		do: [ :i | self addChild: (BlElement new size: 0 @ 0) ].
	[ current < last ]
		whileTrue: [ | label labelAptitude selectedDate |
			selectedDate := current.
			label := BrButton new
					id: #dayLabel;
					aptitude: (labelAptitude := BrGlamorousLabelAptitude new);
					fitContent;
					padding: (BlInsets all: 1);
					layout: BlLinearLayout horizontal alignCenter;
					label: current dayOfMonth printString.

			controls
				ifTrue: [ label
						action: [ self dispatchEvent: (GtCalendarDateClickedEvent forDate: selectedDate) ];
						actionWithModifiers: [ :aButtonElement :aButtonModel :anEvent | 
							self
								dispatchEvent: (GtCalendarDateClickedWithModifiersEvent
										forDate: selectedDate
										modifiers: anEvent modifiers) ].
					date = current
						ifTrue: [ label
								geometry: BlCircleGeometry new;
								border: (BlBorder paint: BrGlamorousColors textHighlightColor width: 2) ] ].
			self
				addChild: (BrVerticalPane new
						clipChildren: false;
						id: #dayContainer;
						fitContent;
						addChild: label;
						in: [ :aBrVerticalPane | 
							self dayElements at: current dayOfMonth put: aBrVerticalPane.
							aBrVerticalPane ]).
			current := current addDays: 1 ]
]

{ #category : #'private ui' }
MyGtCalendarElement >> buildHeader [
	self
		addChild: (controls
				ifTrue: [ BrButton new
						id: #previousMonth;
						size: 10 @ 10;
						margin: (BlInsets top: 5 left: 5);
						aptitude: BrGlamorousButtonIconAptitude;
						icon: BrGlamorousVectorIcons left;
						layout: BlLinearLayout horizontal alignCenter;
						beTinySize;
						action: [ currentMonth := currentMonth addMonths: -1.
							self enqueueTask: (BlTaskAction new action: [ self buildMonth ]) ] ]
				ifFalse: [ BlElement new size: 0 @ 0 ]).
	self
		addChild: (BrHorizontalPane new
				hMatchParent;
				vFitContent;
				constraintsDo: [ :c | c grid horizontal span: 5 ];
				flag: #TODO; "Dropdowns and/or editable labels to select month and year"
				addChildren: {BrLabel new
							id: #month;
							aptitude: BrGlamorousLabelAptitude new;
							hMatchParent;
							layout: BlLinearLayout horizontal alignCenter;
							text: currentMonth monthName asString.
						BrLabel new
							id: #year;
							aptitude: BrGlamorousLabelAptitude new;
							hMatchParent;
							layout: BlLinearLayout horizontal alignCenter;
							text: currentMonth year printString}).
	self
		addChild: (controls
				ifTrue: [ BrButton new
						id: #nextMonth;
						size: 10 @ 10;
						margin: (BlInsets top: 5 left: 7);
						aptitude: BrGlamorousButtonIconAptitude;
						icon: BrGlamorousVectorIcons right;
						layout: BlLinearLayout horizontal alignCenter;
						beTinySize;
						action: [ currentMonth := currentMonth addMonths: 1.
							self enqueueTask: (BlTaskAction new action: [ self buildMonth ]) ] ]
				ifFalse: [ BlElement new size: 0 @ 0 ]).
	(Week dayNames collect: [ :aDayName | aDayName first: 3 ])
		do: [ :aDay | 
			self
				addChild: (BrLabel new
						id: #dayNames;
						beTinySize;
						aptitude: BrGlamorousLabelAptitude new;
						hMatchParent;
						layout: BlLinearLayout horizontal alignCenter;
						text: aDay) ]
]

{ #category : #'private ui' }
MyGtCalendarElement >> buildMonth [
	self removeChildren.
	self dayElements removeAll.
	self buildHeader.
	self buildDays
]

{ #category : #accessing }
MyGtCalendarElement >> date: aDate [
	date := aDate.
	currentMonth := Date newDay: date firstDayOfMonth year: date year.
	self buildMonth
]

{ #category : #'private ui' }
MyGtCalendarElement >> dayElements [
	^ dayElements ifNil: [ dayElements := Dictionary new ]
]

{ #category : #initialization }
MyGtCalendarElement >> defaultWidth [
	^ 150
]

{ #category : #initialization }
MyGtCalendarElement >> disableControls [
	controls := false
]

{ #category : #'instance creation' }
MyGtCalendarElement >> enableControls [
	controls := true
]

{ #category : #initialization }
MyGtCalendarElement >> initialize [
	super initialize.
	self columnCount: 7.
	self width: self defaultWidth.
	self vFitContent.
	self disableControls
]
