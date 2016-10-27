;;;
;;; Returns the next character on a pushable-repeater that is waiting to
;;; be read. If the repeater is exhausted it returns *TERMIN.
;;;
define peekChar( procedure r );
    r() ->> r()
enddefine;
