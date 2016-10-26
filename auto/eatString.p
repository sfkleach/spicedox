;;;
;;; Given a (pushable) repeater -r- and the last read character -ch-,
;;; read characters from -r- until we hit EITHER a syntax-word (e.g. \foo)
;;; OR a pair of newlines OR end of file. The -ch- and the set of
;;; characters that were read up to but not including the characters
;;; of the end-condition are bundled into the constructed string.
;;;
define eatString( procedure r, ch );
    consstring(#|
        ch;
        repeat
            lvars newCh = r();
            lvars nextCh = newCh == termin and termin or r.peekChar;
            quitif(
                newCh == termin or
                ( newCh == `\\` and nextCh /== `\\` ) or
                ( newCh == `\n` and nextCh == `\n` )
            );
            if newCh == `\\` and nextCh == `\\` then
                `\\`, r() -> _
            else
                newCh
            endif;
        endrepeat;
        newCh -> r();
    |#) @newStringToken ( newCh == `\n` )
enddefine;
