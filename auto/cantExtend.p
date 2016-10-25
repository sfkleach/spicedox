;;; If the character ch can extend the dox-character-type chType then
;;; return false, otherwise true.
;;;
define cantExtend( ch, chType );
    not( canExtend( ch, chType ) )
enddefine;
