;;;
;;; Can the character ch extend the dox-character-type chType?
;;; It can if it is the same dtype OR if it is digit following a letter.
;;;
define canExtend( ch, chType );
    lvars newType = doxchartype( ch );
    return (
        newType == chType or
        ( chType == CHAR_letter and newType == CHAR_digit )
    )
enddefine;
