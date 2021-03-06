"
I am an Object Decoder. See the comment of my companion ObjectEncoder.
"
Class {
	#name : #CpObjectDecoder,
	#superclass : #Object,
	#instVars : [
		'readStream',
		'currentMethod'
	],
	#category : #'CodeParadise-RemoteEnvironment-Serialization'
}

{ #category : #'instance creation' }
CpObjectDecoder class >> on: aByteStream [

	^ self new
		on: aByteStream
]

{ #category : #utilities }
CpObjectDecoder class >> putInstVars: instVars in: anObject [

	instVars withIndexDo: [ :instVar :index | anObject instVarAt: index put: instVar ]
]

{ #category : #decoding }
CpObjectDecoder >> decodeAdditionalMethodState [

	"Decode AdditionalMethodState assuming only Pragmas are relevant.
	An AdditionalMethodState is only decoded in the context of a CompiledMethod."

	| additionalMethodState selector pragmas |

	selector := self readString asSymbol.
	pragmas := self readArray.

	additionalMethodState := AdditionalMethodState new: pragmas size.
	pragmas withIndexDo: [ :eachPragma :index | additionalMethodState basicAt: index put: eachPragma ].

	"Set the method for the AdditionalMethodState (will in turn set the method for the Pragmas)"
	currentMethod ifNil: [ self error: 'Decoding AdditionalMethodState without a method' ].
	additionalMethodState setMethod: currentMethod.

	"Set the selector for the method"
	additionalMethodState selector: selector.

	^ additionalMethodState
]

{ #category : #decoding }
CpObjectDecoder >> decodeAnnouncement [

	"Decode an Announcement"

	| announcement className instVars |

	"Read class name"
	className := self readString.

	"Read instance variables"
	instVars := self readArray.

	"Instanciate new announcement"
	announcement := (Smalltalk classNamed: className) new.
	self class putInstVars: instVars in: announcement.

	^ announcement
]

{ #category : #decoding }
CpObjectDecoder >> decodeArray [

	"Decode Array"

	^ self readArray
]

{ #category : #decoding }
CpObjectDecoder >> decodeAssociation [

	"Decode Association"

	^ Association key: self decodeNext value: self decodeNext
]

{ #category : #decoding }
CpObjectDecoder >> decodeCharacter [

	"Decode a Character based on a Unicode value written using UTF-8"

	^ self readUTF8CodePoint
]

{ #category : #decoding }
CpObjectDecoder >> decodeClass [

	"Decode a Class and install it. Answer the newly installed Class or nil if this failed.
	A failure will occur when the superclass specified does not exist."

	| newClass theSuperclass className superclassName instVarNames classVarNames |

	"Raise error if the receiver is not running in the ClientEnvironment"
	CpClientEnvironment isRunning
		ifFalse: [ ^ self error: 'ClientEnvironment sent Class to ServerEnvironment' ].

	"Read class and superclass name"
	className := self readString asSymbol.
	superclassName := self readString asSymbol.

	"Read instance variable, class variable and share pool names"
	instVarNames := self readArray.
	classVarNames := self readArray.

	"Retrieve super class"
	theSuperclass := Smalltalk classNamed: superclassName.
	theSuperclass ifNil: [
		"Read both instance and class methods, so the decoder continues correctly"
		self readArray ; readArray.
		^ nil ].

	"Create new subclass"
	newClass := theSuperclass
		subclass: className
		instanceVariableNames: instVarNames
		classVariableNames: classVarNames.

	"Store class in Smalltalk globals (for referencing from methods)"
	Smalltalk at: className put: newClass.

	"Read and install instance and class methods"
	newClass methodDictionary: self readMethodDictionary.
	newClass class methodDictionary: self readMethodDictionary.

	^ newClass

]

{ #category : #decoding }
CpObjectDecoder >> decodeClassReference [

	| name class |

	name := self readString asSymbol.
	class := Smalltalk classNamed: name.
	class ifNil: [ self error: 'Unknown class named ', name ].

	^ Association key: name value: class
]

{ #category : #decoding }
CpObjectDecoder >> decodeClassVariable [

	| name |

	name := self readString asSymbol.

	^ (Smalltalk at: #ClassVariable)
		key: name
		value: nil
]

{ #category : #decoding }
CpObjectDecoder >> decodeCompiledMethod [

	"Decode a CompiledMethod. Although it is not installed here, it will have its bound Class set
	since this is one of the CompiledMethod's literals."

	| method header bytecodeSize initialPC endPC |

	"Raise error if the receiver is not running in the ClientEnvironment"
	CpClientEnvironment isRunning
		ifFalse: [ ^ self error: 'ClientEnvironment sent CompiledMethod to ServerEnvironment' ].

	"Read header and bytecode size"
	header := self readUInt32.
	bytecodeSize := self readLength.

	"Create empty method instance"
	method := CompiledMethod newMethod: bytecodeSize + 4 header: header.

	"Keep reference to this method in instvar 'currentMethod' for use when decoding AdditionalMethodState or Pragmas"
	currentMethod := method.

	"Add bytecode to the method"
	initialPC := method initialPC.
	endPC := method endPC.
	initialPC to: endPC do: [ :byteIndex | method byteAt: byteIndex put: readStream next ].

	"Add literals"
	1 to: method numLiterals do: [ :index | method literalAt: index put: self decodeNext ].

	"Reference to currentMethod no longer needed (can't be nested so just set to nil)"
	currentMethod := nil.

	^ method
]

{ #category : #decoding }
CpObjectDecoder >> decodeDictionary [

	^ self readArray asDictionary
]

{ #category : #decoding }
CpObjectDecoder >> decodeFalse [

	^ false
]

{ #category : #decoding }
CpObjectDecoder >> decodeFloat [

	| word1 word2 |

	word1 := self readUInt32.
	word2 := self readUInt32.

	^ (Float new: 2)
		basicAt: 1 put: word1 ;
		basicAt: 2 put: word2 ;
		yourself
]

{ #category : #decoding }
CpObjectDecoder >> decodeGlobalVariable [

	| name |

	name := self readString asSymbol.

	^ (Smalltalk at: #GlobalVariable)
		key: name
		value: (Smalltalk at: name ifAbsent: [ self error: 'Unknown global ', name ])
]

{ #category : #decoding }
CpObjectDecoder >> decodeInteger0 [

	^ 0
]

{ #category : #decoding }
CpObjectDecoder >> decodeInteger1Byte [

	^ self readIntegerWithBytes: 1
]

{ #category : #decoding }
CpObjectDecoder >> decodeInteger2Bytes [

	^ self readIntegerWithBytes: 2
]

{ #category : #decoding }
CpObjectDecoder >> decodeInteger3Bytes [

	^ self readIntegerWithBytes: 3
]

{ #category : #decoding }
CpObjectDecoder >> decodeInteger4Bytes [

	^ self readIntegerWithBytes: 4
]

{ #category : #decoding }
CpObjectDecoder >> decodeLargeNegativeInteger [

	"Large integers are stored as special type and therefore do not need a sign bit anymore.
	Large integers are therefore stored using their positive value."

	^ self readLargePositiveInteger negated
]

{ #category : #decoding }
CpObjectDecoder >> decodeLargePositiveInteger [

	^ self readLargePositiveInteger
]

{ #category : #decoding }
CpObjectDecoder >> decodeMessage [

	"Decode a Message (lookupClass is ignored"

	^ Message
		selector: self readString asSymbol
		arguments: self decodeNext
]

{ #category : #decoding }
CpObjectDecoder >> decodeMessageSend [

	"Decode a MessageSend"

	^ MessageSend
		receiver: self decodeNext
		selector: self readString asSymbol
		arguments: self decodeNext
]

{ #category : #decoding }
CpObjectDecoder >> decodeMetaclassReference [

	| name class |

	name := self readString asSymbol.
	class := Smalltalk classNamed: name.
	class ifNil: [ self error: 'Unknown class named ', name ].

	^ Association key: nil value: class class
]

{ #category : #decoding }
CpObjectDecoder >> decodeNext [

	| type selector |

	type := readStream next.
	selector := #(
		decodeNil
		decodeTrue
		decodeFalse
		decodeCharacter
		decodeSymbol
		decodeString
		decodeInteger0
		decodeInteger1Byte
		decodeInteger2Bytes
		decodeInteger3Bytes
		decodeInteger4Bytes
		decodeLargePositiveInteger
		decodeLargeNegativeInteger
		decodeFloat
		decodeArray
		decodeAssociation
		decodeDictionary
		decodeCompiledMethod
		decodeAdditionalMethodState
		decodePragma
		decodeClassReference
		decodeMetaclassReference
		decodeClassVariable
		decodeGlobalVariable
		decodeClass
		decodeAnnouncement
		decodeMessageSend
		decodeMessage
	) at: type ifAbsent: [ self error: 'Unknown type in decode stream' ].

	^ self perform: selector
]

{ #category : #decoding }
CpObjectDecoder >> decodeNil [

	^ nil
]

{ #category : #decoding }
CpObjectDecoder >> decodePragma [

	"Decode Pragma using its selector (fka keyword) and arguments.
	A Pragma is only decoded in the context of a CompiledMethod."

	| selector arguments |

	"The Pragma's method will be set in #decodeAdditionalMethodState just use keyword and arguments"
	selector := self readString.
	arguments := self readArray.

	^ Pragma new
		selector: selector ;
		arguments: arguments ;
		yourself
]

{ #category : #decoding }
CpObjectDecoder >> decodeString [

	^ self readString
]

{ #category : #decoding }
CpObjectDecoder >> decodeSymbol [

	^ self readString asSymbol
]

{ #category : #decoding }
CpObjectDecoder >> decodeTrue [

	^ true
]

{ #category : #reading }
CpObjectDecoder >> doPeek: aBlock [

	"Evaluate aBlock while preserving the current read stream position"

	| position |

	position := readStream position.
	[ aBlock value ] ensure: [ readStream position: position ]

]

{ #category : #errors }
CpObjectDecoder >> errorMalformedUTF8 [

	self error: 'Malformed UTF-8 character'
]

{ #category : #testing }
CpObjectDecoder >> hasMoreData [

	^ readStream atEnd not
]

{ #category : #'instance creation' }
CpObjectDecoder >> on: aByteStream [

	readStream := ReadStream on: aByteStream
]

{ #category : #reading }
CpObjectDecoder >> readArray [

	| array size |

	size := self readLength.
	array := Array new: size.
	1 to: size do: [ :index | array at: index put: self decodeNext ].

	^ array
]

{ #category : #reading }
CpObjectDecoder >> readIntegerWithBytes: byteSize [

	"Read an integer from the read stream consisting of byteSize bytes.
	It is assumed that the integer is stored in 2's complement representation and little endian order."

	| integer highByteShift |

	"Read integer as positive integer (ignore possible sign)"
	integer := self readPositiveIntegerWithSize: byteSize.

	"Update sign (and value) of integer if high bit is set"
	highByteShift := 8 * (byteSize - 1).
	(integer bitAnd: (16r80 bitShift: highByteShift)) = 0
		ifFalse: [ integer := integer - (16r100 bitShift: highByteShift) ].

	^ integer
]

{ #category : #reading }
CpObjectDecoder >> readLargePositiveInteger [

	"Read a (possibly large) integer from the read stream in little endian order.
	The number of bytes is assumed to be present on the read stream (size in 2 bytes, little endian order).
	The integer is assumed to be positive (ie no sign bit)."

	| byteSize |

	"Retrieve size of integer"
	byteSize := self readLength.

	^ self readPositiveIntegerWithSize: byteSize
]

{ #category : #reading }
CpObjectDecoder >> readLength [

	"Read a length value using a byte encoding where the high (8th) bit is designated to mark the final byte.
	The resulting length will be either 0 or a positive integer.
	The length is stored in little endian (least significant byte first) order."

	| length byte bitShift |

	length := 0.

	"Read 7 bits of the length at a time (little endian order)"
	bitShift := 0.
	[
		byte := readStream next.
		length := length bitOr: ((byte bitAnd: 16r7f) bitShift: bitShift).
		bitShift := bitShift + 7.
		(byte bitAnd: 16r80) = 16r80 ] whileFalse.

	^ length
]

{ #category : #decoding }
CpObjectDecoder >> readMethodDictionary [

	"Create and answer a MethodDictionary from the methods read.

	Implementation:
	Create the MethodDictionary with enough size to hold all methods and be performant for
	accessing elements (hash behavior). This also prevents having to grow the MethodDictionary
	during installation of individual methods. See Set >> #fullCheck."

	| methods methodDictionary |

	methods := self readArray.
	methodDictionary := MethodDictionary new: methods size + (methods size // 4 max: 1).
	methods do: [ :eachMethod | methodDictionary at: eachMethod selector put: eachMethod ].

	^ methodDictionary
]

{ #category : #reading }
CpObjectDecoder >> readPositiveIntegerWithSize: byteSize [

	"Read integer from readStream as positive integer (ignore possible sign bit).
	Assume integer is byteSize bytes long and is stored in little endian order."

	| integer |

	integer := 0.
	0 to: byteSize - 1 do: [ :byteShift | integer := integer bitOr: (readStream next bitShift: 8 * byteShift) ].

	^ integer
]

{ #category : #reading }
CpObjectDecoder >> readString [

	"Read a String consisting of UTF-8 characters.
	The end of the String is marked by a 16rff byte value (which cannot be part of an UTF-8 encoding).
	Its position (and therefore character count) is calculated before actually decoding the characters."

	| string characterCount byte |

	"Find length of string"
	characterCount := 0.
	self doPeek: [
		[ readStream atEnd not and: [ (byte := readStream next) ~= 16rff ] ]
			whileTrue: [
				"Only count bytes which are not continuations of a character"
				(byte bitAnd: 16rc0) = 16r80
					ifFalse: [ characterCount := characterCount + 1 ] ] ].

	"Create and fill the string"
	string := String new: characterCount.
	1 to: characterCount do: [  :index | string at: index put: self readUTF8CodePoint ].

	"Skip the end of string marker"
	(readStream peekFor: 16rff)
		ifFalse: [ self errorMalformedUTF8 ].

	^ string
]

{ #category : #reading }
CpObjectDecoder >> readUInt32 [

	"Read uint32 using little endian (least significant byte first) order"

	^ self readPositiveIntegerWithSize: 4
]

{ #category : #reading }
CpObjectDecoder >> readUTF8CodePoint [

	"Read a Character based on a Unicode value written using UTF-8.
	See also https://en.wikipedia.org/wiki/UTF-8"

	| unicode |

	unicode := readStream next.
	(unicode bitAnd: 16r80) = 0 	"Encoding 0xxxxxxx for single byte UTF-8 character"
		ifFalse: [

			| bytesToRead byte |

			"Decide additional number of bytes to read"
			(unicode bitAnd: 16re0) = 16rc0 	"Encoding 110xxxxx for 2-byte UTF-8 character"
				ifTrue: [ bytesToRead := 1 ]
				ifFalse: [
					(unicode bitAnd: 16rf0) = 16re0 	"Encoding 1110xxxx for 3-byte UTF-8 character"
						ifTrue: [ bytesToRead := 2 ]
						ifFalse: [
							(unicode bitAnd: 16rf8) = 16rf0 	"Encoding 11110xxx for 4-byte UTF-character"
								ifTrue: [ bytesToRead := 3 ]
								ifFalse: [ self errorMalformedUTF8 ] ] ].

			"Remove encoding bits from first unicode byte"
			unicode := unicode bitAnd: (16r3f bitShift: bytesToRead negated).

			"Read additional bytes (removing encoding bits 10xxxxxx)"
			bytesToRead timesRepeat: [
				byte := readStream next.
				(byte bitAnd: 16rc0) = 16r80 	"check continuation bit"
					ifFalse: [ self errorMalformedUTF8 ].
				unicode := (unicode bitShift: 6) bitOr: (byte bitAnd: 16r3f) ] ].

	^ Character value: unicode
]

{ #category : #accessing }
CpObjectDecoder >> remainingBytes [

	"Answer the remaining bytes of the receiver"

	^ readStream upToEnd
]
