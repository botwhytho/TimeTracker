Extension { #name : 'GtPlotterSingleScaleValueBasedElement' }

{ #category : '*TimeTracker' }
GtPlotterSingleScaleValueBasedElement >> initializeElements [
	"Overriding this method until https://github.com/feenkcom/gtoolkit/issues/3521 is merged."
	| theChildren |

	self removeChildren: elements.
	
	"we could use collectWithIndex:, however we would like to use as generic
	collection API as possible to accomodate custom or domain specific collections"
	theChildren := OrderedCollection new.
	self values do: [ :eachValue |
		| aScaleContext eachIndex eachElement aScaledValue |
		
		"intentionally starts with 0"
		eachIndex := theChildren size.
		
		aScaledValue := scaleData value: eachValue.

		aScaleContext := GtPlotterSingleScaleContext new.
		aScaleContext
			scale: scale;
			originalValue: eachValue;
			scaledValue: aScaledValue;
			mappedValue: (scale map: aScaledValue);
			index: eachIndex.

		eachElement := (valueElement scaleContext: aScaleContext) asElement.

		eachElement := (valueLayout
			element: eachElement;
			scaleContext: aScaleContext) asElement.

		eachElement := (valueStyle
			element: eachElement;
			scaleContext: aScaleContext) asElement.
		
		theChildren add: eachElement ].
	
	self addChildren: (elements := theChildren)
]
