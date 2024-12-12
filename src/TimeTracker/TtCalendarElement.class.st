Class {
	#name : #TtCalendarElement,
	#superclass : #GtCalendarElement,
	#category : #'TimeTracker-Calendar'
}

{ #category : #'private ui' }
TtCalendarElement >> buildDays [
	| current last |
	self flag: #TEMPFIX.	"This subclass shouldn't be needed after upstream PRs are merged, GtCalendarDateClickedEvent should forward the click event"
	current := currentMonth.
	last := currentMonth addMonths: 1.
	1
		to: current dayOfWeek - 1
		do: [ :i | self addChild: (BlElement new size: 0 @ 0) ].
	[ current < last ]
		whileTrue: [ | label selectedDate |
			selectedDate := current.
			label := BrButton new
					enableAllModifiers;
					aptitude: BrGlamorousLabelAptitude + GtAnyModifierClickAptitude;
					hMatchParent;
					vFitContent;
					padding: (BlInsets all: 1);
					layout: BlLinearLayout horizontal alignCenter;
					label: current dayOfMonth printString;
					action: [ :aBrButton :aBrButtonModel :aBlClickEvent | 
						self
							dispatchEvent: (TtCalendarDateClickedEvent new
									date: selectedDate;
									clickEvent: aBlClickEvent) ].
			date = current
				ifTrue: [ label
						geometry: BlCircleGeometry new;
						border: (BlBorder paint: BrGlamorousColors textHighlightColor width: 2) ].
			self addChild: label.
			current := current addDays: 1 ]
]
