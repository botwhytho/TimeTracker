Class {
	#name : #MyGtCalendarElement,
	#superclass : #BrHorizontalGrid,
	#instVars : [
		'date',
		'currentMonth'
	],
	#category : #'TimeTracker-Calendar'
}

{ #category : #'instance creation' }
MyGtCalendarElement class >> forDate: aDate [
	^ (self new)
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
					hMatchParent;
					vFitContent;
					padding: (BlInsets all: 1);
					layout: BlLinearLayout horizontal alignCenter;
					label: current dayOfMonth printString;
					action: [ self dispatchEvent: (GtCalendarDateClickedEvent forDate: selectedDate) ];
					actionWithModifiers: [ :aButtonElement :aButtonModel :anEvent | 
						self
							dispatchEvent: (GtCalendarDateClickedWithModifiersEvent
									forDate: selectedDate
									modifiers: anEvent modifiers) ].
			labelAptitude
				labelDo: [ :aLabel | 
					aLabel text size = 1
						ifTrue: [ aLabel
								text: (('0' , aLabel text asString) asRopedText
										in: [ :aRopedText | 
											(aRopedText from: 1 to: 1) foreground: Color transparent.
											aRopedText ]) ].
					aLabel text glamorousMonospace ].
			date = current
				ifTrue: [ label
						geometry: BlCircleGeometry new;
						border: (BlBorder paint: BrGlamorousColors textHighlightColor width: 2) ].
			self
				addChild: (BrHorizontalPane new
						id: #dayContainer;
						fitContent;
						addChild: label).
			current := current addDays: 1 ]
]

{ #category : #'private ui' }
MyGtCalendarElement >> buildHeader [
	self
		addChild: (BrButton new
				id: #previousMonth;
				size: 10 @ 10;
				margin: (BlInsets top: 5 left: 5);
				aptitude: BrGlamorousButtonIconAptitude;
				icon: BrGlamorousVectorIcons left;
				layout: BlLinearLayout horizontal alignCenter;
				beTinySize;
				action: [ currentMonth := currentMonth addMonths: -1.
					self enqueueTask: (BlTaskAction new action: [ self buildMonth ]) ]).
	self
		addChild: (BrLabel new
				id: #monthAndYear;
				aptitude: BrGlamorousLabelAptitude new;
				constraintsDo: [ :c | c grid horizontal span: 5 ];
				hMatchParent;
				layout: BlLinearLayout horizontal alignCenter;
				text: currentMonth monthName asString , ' ' , currentMonth year printString).
	self
		addChild: (BrButton new
				id: #nextMonth;
				size: 10 @ 10;
				margin: (BlInsets top: 5 left: 7);
				aptitude: BrGlamorousButtonIconAptitude;
				icon: BrGlamorousVectorIcons right;
				layout: BlLinearLayout horizontal alignCenter;
				beTinySize;
				action: [ currentMonth := currentMonth addMonths: 1.
					self enqueueTask: (BlTaskAction new action: [ self buildMonth ]) ]).
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
	self buildHeader.
	self buildDays
]

{ #category : #accessing }
MyGtCalendarElement >> date: aDate [
	date := aDate.
	currentMonth := Date newDay: date firstDayOfMonth year: date year.
	self buildMonth
]

{ #category : #initialization }
MyGtCalendarElement >> initialize [
	super initialize.
	self columnCount: 7.
	self width: 150.
	self vFitContent
]
