;;;
;;; Returns true if -heading_string- has a digit as the first character.
;;;
define isNumbering( heading_string );
    unless heading_string.isstring do
        mishap( 'String needed', [ ^heading_string ] )
    endunless;
    0 < heading_string.datalength and
    lblock
        lvars ch = subscrs( 1, heading_string );
        `0` <= ch and ch <= `9`
    endlblock
enddefine;
