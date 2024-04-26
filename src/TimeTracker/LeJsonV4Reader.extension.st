Extension { #name : #LeJsonV4Reader }

{ #category : #'*TimeTracker' }
LeJsonV4Reader >> unknownSnippetTypeFrom: map [
	"If the supplied map looks like a snippet, answer an unknown snippet, otherwise raise an exception"

	| children class snippet type |
	"map is considered a snippet if it has all the keys of LeBlock"
	((LeSnippet leJsonV4AttributeMapping collect: #key as: Set)
		difference: map keys) ifNotEmpty: [ self error: 'Unknown snippet type' ].

	children := map at: #children.
	map at: #children put: LeSnippets new.
	type := map at: #__type.
	self flag: #TODO "Should probably figure out proper custom snippet types for 'TimeTracker' package uses".
	class := LeUnknownSnippet withAllSubclasses
			detect: [ :each | each leJsonV4Name = type ]
			ifNone: [ LeUnknownSnippet ].
	snippet := class
			jsonString: (String
					streamContents: [ :stream | 
						LeJsonV4 uniqueInstance
							serialize: map
							on: stream
							prettyPrint: true ]).
	snippet
		children: children;
		uid: (map at: #uid).
	^ snippet
]
