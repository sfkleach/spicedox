#from collections import deque

class Tokenizer:

	def __init__( self, fileobj ):
		self.fileobj = fileobj
		self.buffer = []	 # Alternatively a deque.

	def getChar( self ):
		if self.buffer:
			return self.buffer.pop()
		else:
			return self.fileobj.read( 1 )

	def pushChar( self, ch ):
		self.buffer.append( ch )

	def peekChar( self ):
		if self.buffer:
			return self.buffer[ 0 ]
		else:
			ch = self.fileobj.read( 1 )
			self.buffer.push( ch )
			return ch

	def isNextChar( self, ch ):
		return self.peekChar() == ch

	def tryGetChar( self, ch ):
		if self.buffer:
			if self.buffer[ -1 ] == ch:
				self.buffer.pop()
				return True
			else:
				return False
		else:
			ch1 = self.fileobj.read( 1 )
			if ch1 == ch:
				return True
			else:
				self.pushChar( ch1 )
				return False

	def readToken( self ):
		if self.tryGetChar( '\n' ):
			return '\n'
		token = []
		if self.isNextChar( ' ' ):
			while self.tryGetChar( ' ' ):
				token.append( ' ' )
			return ''.join( token )
		else:
			while True:
				ch = self.getChar()
				if ch.isspace():
					self.pushChar( ch )
					return ''.join( token )
				elif ch:
					token.append( ch )
				else:
					return ''.join( token )
