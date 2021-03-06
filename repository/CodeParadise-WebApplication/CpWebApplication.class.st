"
I am a ServerApplication with Web-specific behavior. I work with WebComponents, meaning I know how to update their appearance (template and style).

"
Class {
	#name : #CpWebApplication,
	#superclass : #CpServerApplication,
	#classVars : [
		'IdentifierGenerator'
	],
	#category : #'CodeParadise-WebApplication-Core'
}

{ #category : #accessing }
CpWebApplication class >> clientBehaviorClass [

	^ CpWebClientBehavior
]

{ #category : #'class initialization' }
CpWebApplication class >> initialize [

	IdentifierGenerator := CpWebIdentifierGenerator new
]

{ #category : #'as yet unclassified' }
CpWebApplication class >> openInBrowser [
	WebBrowser openOn: 'http://localhost:8080/static/app.html?' , self app
]

{ #category : #accessing }
CpWebApplication class >> webResourceCSS [

	^ #css
]

{ #category : #accessing }
CpWebApplication class >> webResourceHTML [

	^ #html
]

{ #category : #accessing }
CpWebApplication class >> webResourcePragmaName [

	^ #webResource:
]

{ #category : #accessing }
CpWebApplication >> clientBehaviorClass [

	"Answer the class of the receiver's ClientBehavior"

	^ self class clientBehaviorClass
]

{ #category : #installing }
CpWebApplication >> installExtensionMethods [

	"Install the extension methods from known Classes"

	self installExtensionMethodsFor: #webApplicationExtension
]

{ #category : #installing }
CpWebApplication >> installExtensionMethodsFor: aSymbol [

	"Install the extension methods for specified (pragma) Symbol.

	Implementation:
	First find senders of specified Symbol and then explicitly check for
	pragma in both instance and class methods."

	((CpFinder allSendersOf: aSymbol) collect: [ :each | each realClass ]) asSet
		do: [ :eachClass |

			"Install instance methods"
			(Pragma allNamed: aSymbol in: eachClass) do: [ :eachPragma |
self crTrace: 'Install ', eachPragma method selector, ' from ', eachClass printString.
				self environment addMethod: eachPragma method ].

			"Install class methods"
			(Pragma allNamed: aSymbol in: eachClass class) do: [ :eachPragma |
self crTrace: 'Install ', eachPragma method selector, ' from ', eachClass printString, ' class'.
				self environment addMethod: eachPragma method ] ]
]

{ #category : #actions }
CpWebApplication >> load [

	"Perform the initial loading of the receiver"

	super load.

	"Install required extensions"
	self installExtensionMethods.

	"Install the ClientBehavior"
	self clientBehaviorClass
		installIn: self environment ;
		createIn: self environment
]

{ #category : #updating }
CpWebApplication >> methodChanged: anAnnouncement [

	"Update the View if a resource method is uodated.
	Answer a Boolean indicating whether the method is installed in the client.
	Implementation: Answer true is the super call answered true, since the method got installed."

	| method pragma resourceType methodClass |

	(super methodChanged: anAnnouncement)
		ifFalse: [ ^ false ].

	method := anAnnouncement method.
	methodClass := method methodClass instanceSide.
	pragma := method pragmaAt: self class webResourcePragmaName.
	pragma ifNil: [ ^ true ].
	resourceType := pragma argumentAt: 1.
	resourceType == self class webResourceCSS
		ifTrue: [
			self updateStyleViewClass: methodClass.
			^ true ].
	resourceType == self class webResourceHTML
		ifTrue: [
			self updateTemplateViewClass: methodClass.
			^ true ].

	^ true
]

{ #category : #actions }
CpWebApplication >> reload [

	"Perform reloading of the receiver"

	super reload.

	"Create an instance of the ClientBehavior in the ClientEnvironment
	(class is already installed during initial #load)"
	self clientBehaviorClass createIn: self environment
]

{ #category : #updating }
CpWebApplication >> updateStyleViewClass: aViewClass [

	self clientBehaviorClass updateStyleViewClass: aViewClass in: self environment
]

{ #category : #updating }
CpWebApplication >> updateTemplateViewClass: aViewClass [

	self clientBehaviorClass updateTemplateViewClass: aViewClass in: self environment
]
