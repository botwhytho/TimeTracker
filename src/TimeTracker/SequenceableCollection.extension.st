Extension { #name : #SequenceableCollection }

{ #category : #'*TimeTracker' }
SequenceableCollection >> identityAfter: target ifAbsent: exceptionBlock [
	"Answer the element after target.  Answer the result of evaluation
	the exceptionBlock if target is not in the receiver, or if there are
	no elements after it."
	"(#(a b c d) after: #b ifAbsent: #z) >>> #c"
	"(#(a b c d) after: #x ifAbsent: #z) >>> #z"

	| index |
	index := self identityIndexOf: target.
	^ (index = 0 or: [index = self size])
		ifTrue: [exceptionBlock value]
		ifFalse: [self at: index + 1]
]

{ #category : #'*TimeTracker' }
SequenceableCollection >> identityBefore: target ifAbsent: exceptionBlock [
	"Answer the receiver's element immediately before target. Answer
	the result of evaluating the exceptionBlock if target is not an element
	of the receiver, or if there are no elements before it."
	"(#(11 22 33) before: 22 ifAbsent: 55) >>> 11"
	"(#(11 22 33) before: 44 ifAbsent: 55) >>> 55"

	| index |
	index := self identityIndexOf: target.
	^ (index = 0 or: [index = 1])
		ifTrue: [exceptionBlock value]
		ifFalse: [self at: index - 1]
]
