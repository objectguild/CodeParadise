Class {
	#name : #CpRadioButtonGroup,
	#superclass : #CpControlGroup,
	#category : #'CodeParadise-Beach-Components'
}

{ #category : #'web resources' }
CpRadioButtonGroup class >> style [

	<webResource: #css>

	^ '*, *:before, *:after {
			-moz-box-sizing: border-box;
			-webkit-box-sizing: border-box;
			box-sizing: border-box;
		}
		:host {
			display: inline-grid;
		}
		:host(:not([vertical])) {
			grid-template-columns: 1fr;
			grid-auto-flow: column;
			grid-auto-columns: 1fr;
			column-gap: 1em;
		}
		:host([vertical]) {
			grid-template-rows: 1fr;
			grid-auto-flow: row;
			grid-auto-rows: 1fr;
			row-gap: .2em;
		}'
]

{ #category : #'web resources' }
CpRadioButtonGroup class >> template [

	<webResource: #html>

	^ '<slot></slot>'
]

{ #category : #'adding/removing' }
CpRadioButtonGroup >> appendChild: anElement [

	"Append radio button to the receiver"

	"If newly added item is selected, prevent others from being selected"
	anElement ifSelected: [ self deselectAll ].

	self registerEventHandlerFor: anElement.
	^ super appendChild: anElement
]

{ #category : #'state handling' }
CpRadioButtonGroup >> beReadOnly [

	"Make the receiver read only.
	
	Implementation:
	If receiver is not already read only, also make all children read only."

	(self attributeAt: #readonly)
		ifNil: [
			self attributeAdd: #readonly.
			self children do: [ :each | each beReadOnlySecundary ] ]
]

{ #category : #'state handling' }
CpRadioButtonGroup >> beWritable [

	"Make the receiver writable.
	
	Implementation:
	If receiver is not already writable, also make all children writable."

	(self attributeAt: #readonly)
		ifNotNil: [
			self removeAttributeAt: #readonly.
			self children do: [ :each | each beWritableSecundary ] ]
]

{ #category : #'state handling' }
CpRadioButtonGroup >> deselectAll [

	self children do: [ :each | each deselect ]
]

{ #category : #'state handling' }
CpRadioButtonGroup >> deselectAllBut: anElement [

	self children do: [ :each |
		each = anElement
			ifFalse: [ each deselect ] ]
]

{ #category : #'event handling' }
CpRadioButtonGroup >> handleSelectionChanged: aSelectionChanged [

	| selectedElement |

	(selectedElement := aSelectionChanged element)
		ifNotSelected: [ ^ self ].

	self deselectAllBut: selectedElement
]

{ #category : #initialization }
CpRadioButtonGroup >> initialize [

	super initialize.

	self children do: [ :each | self registerEventHandlerFor: each ]
]

{ #category : #'adding/removing' }
CpRadioButtonGroup >> insertChild: childElement before: siblingElement [

	"Insert radio button before the specified sibling into the receiver"

	"If newly inserted item is selected, prevent others from being selected"
	childElement ifSelected: [ self deselectAll ].

	self registerEventHandlerFor: childElement.
	^ super insertChild: childElement before: siblingElement
]

{ #category : #'adding/removing' }
CpRadioButtonGroup >> registerEventHandlerFor: anElement [

	anElement when: CpSelectionChanged send: #handleSelectionChanged: to: self
]

{ #category : #'adding/removing' }
CpRadioButtonGroup >> replaceChild: childElement with: replacementElement [

	"Replace the specified existing radio button with specified replacement"

	"If newly replaced item is selected, prevent others from being selected"
	replacementElement ifSelected: [ self deselectAllBut: childElement ].

	self registerEventHandlerFor: replacementElement.
	^ super replaceChild: childElement with: replacementElement
]
