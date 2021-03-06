"
I am a View representing the Screen of the web browser I live in. 
"
Class {
	#name : #CpScreen,
	#superclass : #CpView,
	#category : #'CodeParadise-WebApplication-MVP-Core'
}

{ #category : #'web resources' }
CpScreen class >> style [

	<webResource: #css>

	^':host {
		position: absolute;
		left: 0;
		top: 0;
		width: 100vw;
		height: 100vh;
		overflow: hidden;
	}
	.dragging * {
		pointer-events: none;
		-moz-user-select: none;
		-webkit-user-select: none;
		-ms-user-select: none;
		user-select: none;
	}
	.container {
		width: 100%;
		height: 100%;
	}'
]

{ #category : #'web resources' }
CpScreen class >> template [

	<webResource: #html>

	^ '<div class="container">
			<slot></slot>
		</div>'
]

{ #category : #initialization }
CpScreen >> initialize [

	super initialize.

	"Add some default styling to the full document"
	CpHtmlElement documentHead appendChild: ((CpHtmlElement newWithTag: #style)
		textContent: '
			*, *:before, *:after {
				box-sizing: border-box;
			}
			html {
				font-size: 100%;
				-webkit-text-size-adjust: 100%;
				font-family: "SF Pro Text", "Helvetica Neue", Helvetica, Arial, sans-serif;
			}' ;
		yourself)
]

{ #category : #dragging }
CpScreen >> makeDraggable: aView [

	(CpHtmlElement elementWithId: self id)
		addClass: #dragging.
	aView addClass: #dragging
]

{ #category : #dragging }
CpScreen >> stopDragging: aView [

	(CpHtmlElement elementWithId: self id)
		removeClass: #dragging.
	aView removeClass: #dragging
]
