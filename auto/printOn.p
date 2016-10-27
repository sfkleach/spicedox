;;;
;;; Prints an item -x- using cucharout dynamically bound to
;;; a user-defined consumer.
;;;
define printOn( x, consumer );
    dlvars procedure consumer;
    dlvars procedure previous = cucharout;

    define dlocal cucharout( ch );
        dlocal cucharout = previous;
        consumer( ch )
    enddefine;

    pr( x )
enddefine;
