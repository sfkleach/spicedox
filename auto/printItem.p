;;; -----------------------------------------------------------

defclass Printer {
    printerInSuper,
    printerInSub,
    printerInBold,
    printerInCode,
    printerInItalics,
    printerInMaths,
    printerReally
};

define newPrinter();
    consPrinter( false, false, false, false, false, false, false, false )
enddefine;

;;; -----------------------------------------------------------


;;; vars inSuper = false;
;;; vars inSub = false;
;;; vars inBold = false;
;;; vars inCode = false;
;;; vars inItalics = false;
;;; vars inMaths = false;
;;;
;;; vars really = false;

;;; convert characters for output, keeping track of various settings

vars procedure outputSink;

define print( x );
    dlocal cucharout = outputSink;
    pr( x )
enddefine;

define literal( x );
    print(% x %)
enddefine;

define texLiteral( ch, self );
    if ch == `_` then       `\\`.outputSink, ch.outputSink
    elseif ch == `{` then   `\\`.outputSink, ch.outputSink
    elseif ch == `}` then   `\\`.outputSink, ch.outputSink
    elseif ch == `#` then   `\\`.outputSink, ch.outputSink
    elseif ch == `%` then   `\\`.outputSink, ch.outputSink
    elseif ch == `$` then   `\\`.outputSink, ch.outputSink
    elseif ch == `&` then   `\\`.outputSink, ch.outputSink
    elseif ch == `[` then   '{[}'.print
    elseif ch == `]` then   '{]}'.print
    elseif ch == `^` then
        unless self.printerInMaths do `$`.outputSink endunless;
        '^\\wedge'.print;
        unless self.printerInMaths do `$`.outputSink endunless;
    elseif ch == `\\` then
        unless self.printerInMaths do `$`.outputSink endunless;
        '\\setminus'.print;
        unless self.printerInMaths do `$`.outputSink endunless;
    elseif ch == `<` then
        unless self.printerInMaths do `$`.outputSink endunless;
        '<'.print;
        unless self.printerInMaths do `$`.outputSink endunless;
    elseif ch == `>` then
        unless self.printerInMaths do `$`.outputSink endunless;
        '>'.print;
        unless self.printerInMaths do `$`.outputSink endunless;
    elseif ch == `|` then
        unless self.printerInMaths do `$`.outputSink endunless;
        '\\mid'.print;
        unless self.printerInMaths do `$`.outputSink endunless;
    else
        ch.outputSink
    endif
enddefine;



define texOutput( ch, self );
    if self.printerReally then
        ch @texLiteral self;
        false -> self.printerReally
    else
        if ch == `!` then
            true -> self.printerReally
        elseif ch == `_` then
            if self.printerInBold then '}'.print; false -> self.printerInBold
            else '{\\bf '.print; true -> self.printerInBold
            endif
        elseif ch == `*` then
            if self.printerInItalics then '}'.print; false -> self.printerInItalics
            else '{\\em '.print; true -> self.printerInItalics
            endif
        elseif ch == `~` then
            if self.printerInSub then '$'.print; false -> self.printerInSub
            else '$_ '.print; true -> self.printerInSub
            endif
        elseif ch == `^` then
            if self.printerInSuper then '$'.print; false -> self.printerInSuper
            else '$^ '.print; true -> self.printerInSuper
            endif
        elseif ch == `|` then
            if self.printerInCode then '}'.print; false -> self.printerInCode
            else '{\\tt '.print; true -> self.printerInCode
            endif
        else
            ch @texLiteral self
        endif
    endif
enddefine;


define printItem( item );

    lvars printer = newPrinter();

    lvars texOutputOnPrinter = (
        procedure( ch );
            texOutput( ch, printer )
        endprocedure
    );

    define printThisItem( item );
        if item.islist then item @applist printThisItem
        elseif item.isprocedure then [% item() %] @applist printThisItem
        else item @printOn texOutputOnPrinter
        endif
    enddefine;

    printThisItem( item )

enddefine;



;;; define printItem( item );
;;;     if item.islist then item @applist printItem
;;;     elseif item.isprocedure then [% item() %] @applist printItem
;;;     else item @printOn texOutput
;;;     endif
;;; enddefine;
;;;
