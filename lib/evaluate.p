uses @ ;

;;; -- Main ---------------------------------------------------

vars procedure ( evalWrap, evalNoParaWrap, evalOp, evalItem, literal );

define evalWord( w );
    w.dl
enddefine;

define evalString( w );
    w @applist identfn
enddefine;

define evalOp( x, name, proc );
    lvars ( L, R ) = x.dest.hd;
    `(`, L.evalItem, name, R.evalItem, `)`
enddefine;

/*
define defInfix( name, level, action );
    [% name, newOpSynProps( "weak", "xFx", level, action ) %]
enddefine;

define defPrefix( name, action );
    [% name, newOpSynProps( "weak", "Fx", 20, action ) %]
enddefine;
*/

define evalLinkto( x );
    lvars ( L, R ) = x.dest.hd;
    L.evalItem, ' (', R.evalItem, ')'
enddefine;

define evalLabel( x );
    consstring(#|
        '\\label{'.explode,
        x.front.meanArg.front.explode,
        '}'.explode
    |#) @literal
enddefine;

define evalRef( x );
    lvars ( L, R ) = x.dest.hd;
    consstring(#|
        '\\ref={'.explode,
        L.meanArg.front.explode,
        '}'.explode
    |#) @literal,
    R.evalItem
enddefine;

define evalBrackets( x );
    x @applist evalItem
enddefine;

define evalN( x );
    '\\\\ \n' @literal
enddefine;

define evalT( x );
    ' \\> ' @literal
enddefine;

define evalBoxes( x );
    x @applist evalItem
enddefine;

define splitTitle( stuff );
    lvars x = stuff.meanArg.front;
    if x.isNumbering then
        lvars i = 1;
        while i <= x.pepperLength do
            lvars ch = subscrs( i, x );
            quitunless( ch == `.` or ch.isnumbercode );
            i + 1 -> i
        endwhile;
        ( x @leftpart i-1, x @rightpart i -> stuff.meanArg.front, stuff )
    else
        ('', stuff)
    endif
enddefine;

vars contentsList = [];

/*
define displayContents();
;;;     for c in_list contentsList.rev do
;;;         if c.left <= 3 then
;;;             "<br>",
;;;             if c.left == 2 then " SPACE; " endif,
;;;             if c.left == 3 then " SPACE;SPACE;" endif,
;;;             c.right
;;;         endif
;;;     endfor
enddefine;

define evalContents( x );
    displayContents
enddefine;
*/

vars procedure ( evalItemParaList );

/*
define evalWrap( x, wrapper );
    catStrings(#| '<', wrapper, '>' |#),
    x @evalItemParaList,
    catStrings(#| '</', wrapper, '>' |#)
enddefine;

define evalNoParaWrap( x, wrapper );
    catStrings(#| '<', wrapper, '>' |#),
    x @applist evalItem,
    catStrings(#| '</', wrapper, '>' |#)
enddefine;
*/

vars savedTitle = false;

define evalTitle( x );
    x @maplist evalItem -> savedTitle;
    ;;; "<h1>", savedTitle.dl, "</h1>"
enddefine;

define delayedTitle();
    if savedTitle then
        '\\title{' @literal,
        savedTitle.dl;
        '}\n' @literal;
    endif
enddefine;

define doHeaded( x, level, command );
    lvars ( numeric, title ) = x.front.splitTitle;
    ;;; val header = catStrings(# level @nextNumber numeric, space, title.evalItem #);
    lvars header = title.evalItem;
    [ ^level ^^contentsList] -> contentsList;
    '\\' @literal, command, '{' @literal, header, '}\n' @literal,
    x.tl @evalItemParaList
enddefine;

vars inAppendix = false;

define setAppendix();
    unless inAppendix do
        '\\appendix\n' @literal, true -> inAppendix
    endunless
enddefine;

define evalAppendix( x );
    setAppendix, x @doHeaded (1, 'chapter')
enddefine;

define evalChapter( x );
    x @doHeaded (1, 'chapter')
enddefine;

define evalSection( x );
    x @doHeaded (2, 'section')
enddefine;

define evalPassage( x );
    x @doHeaded (3, 'subsection')
enddefine;

define evalFragment( x );
    x @doHeaded (4, 'subsubsection')
enddefine;

define evalIndented( x );
    '\\begin{quote}' @literal,
    x @applist evalItem,
    '\\end{quote}' @literal
enddefine;

define evalPart( x );
    '\\part{' @literal,
    x.hd.evalItem,
    '}\n' @literal,
    x.tl @applist evalItem, '\n\n'
enddefine;

define evalList( elems );
    '\\begin{itemize}' @literal,
    lvars x;
    for x in elems do '\\item ' @literal, x.evalItem, '\n\n' endfor,
    '\\end{itemize}' @literal
enddefine;

define evalSpice( blocks );
    lvars gap = '';
    '\\begin{quote}\n' @literal,
    '\\begin{verbatim}\n' @literal,
    lvars x;
    for x in blocks do
        gap, '\n' -> gap, [%x.evalItem%] @maplist literal
    endfor,
    '\\end{verbatim}\n' @literal,
    '\\end{quote}\n' @literal
enddefine;

vars theseIssues = [];

vars procedure ( evalItemPara );

define evalIssue( x );
    lvars thisIssue;
    [%
        '\n\n',
        '{\\bf ' @literal, x.front @evalItemPara, '}' @literal,
        x.back @evalItemParaList,
        ''
    %] -> thisIssue;
    thisIssue @conspair theseIssues -> theseIssues;
    thisIssue.dl
enddefine;

define evalAllIssues( x );
    theseIssues.rev @applist dl
enddefine;

vars syntaxDefs = [];

define evalAllSyntax( x );
    syntaxDefs.rev @applist dl
enddefine;


define xxmeanArg( x );
    lvars a = x.meanArg;
    if a.null then
        mishap( x, 1, 'argh! it has a null arg!' )
    endif;
    a
enddefine;

define startsWith( items, word );
    if items.null then false
    elseif word.islist then items.hd.xxmeanArg.front @member word
    else items.hd.xxmeanArg.front == word
    endif
enddefine;

vars procedure ( parseAlts );

define parseItem( items );
    lvars it;
    if items @startsWith "(" then
        items.back.parseAlts -> ( it, items );
        it, items.back
    elseif items @startsWith "[" then
        items.back.parseAlts -> ( it, items );
        [% "OPT", it %], items.back
    else
        items.dest
    endif
enddefine;

define parseAlt( items );
    lconstant toks = conslist(#| "|", "]", ")" |#);
    [%"SEQ",
        repeat
            quitif( items.null or ( items @startsWith toks ) );
            lvars it;
            items.parseItem -> ( it, items );
            if ( items @startsWith "*" ) or ( items @startsWith "**" )
            or ( items @startsWith "+" ) or ( items @startsWith "++" )
            then [% "STAR", items.hd, it %], items.tl -> items
            else it
            endif
        endrepeat
    %], items
enddefine;

define parseAlts( items );
    [%"ALT",
        repeat
            lvars alt;
            items.parseAlt -> ( alt, items );
            alt;
            quitunless( items @startsWith "|" );
            items.tl -> items
        endrepeat
    %], items
enddefine;

vars procedure ( showSeq, showAlts );

define evalVisibleBrackets( x );
    "(", x @showSeq ('', true), ")"
enddefine;

define evalVisibleBoxes( x );
    '[', x @showSeq ('', true), ']'
enddefine;

define showItem( item, nested );
    if item.isMeaning then
        item @evalItem
    else
        lvars key = item.front;
        if key == "SEQ" then
            "(", item.back @showSeq ('', true), ")"
        elseif key == "ALT" then
            "(", showAlts( '', item, '', true), ")"
        elseif key == "STAR" then
            item.back.back.front @showItem true,
            item.back.front @showItem true @literal
        elseif key == "OPT" then
            '[', item.back.front @showItem true, ']'
        else
            mishap( item, 1, 'oh dear' )
        endif
    endif
enddefine;

vars procedure ( blobSum );

define blobLength( x );
    if x.islist then (0, x) @applist blobSum
    else x.pepperLength
    endif
enddefine;

define blobSum( n, x );
    n + x.blobLength + 1
enddefine;

define showSeq( seq, prefix, nested );
    lvars gap = '';
    lvars k = seq.blobLength;
    ;;; ["blobLength", k].reportln;
    if k < 72 or nested then
        lvars item;
        for item in_list seq do
            prefix, gap, ' ' -> gap, item @showItem true
        endfor
    else
        '\\begin{tabular}{l}\n' @literal,
        lvars item;
        for item in_list seq do
            prefix, gap, ' ' -> gap, item @showItem nested, ' \\\\ \n' @literal
        endfor,
        '\\end{tabular}\n' @literal
    endif
enddefine;

define showAlts( prefix, alts, suffix, nested );
    lvars sep = '';
    if nested then
        lvars alt;
        for alt in_list alts.back do
            prefix, sep, alt.back @showSeq ('', true), suffix,
            ' !| ' -> sep
        endfor
    else
        lvars alt;
        for alt in_list alts.back do
            prefix, sep, alt.back @showSeq ('', nested), suffix,
            ' !| ' -> sep
        endfor
    endif
enddefine;

vars procedure ( report );

define formRhs( items );
    lvars maxWidth = 72;
    lvars n = sumapplist( items, pepperLength );
    lvars alts;
    items.parseAlts -> (alts, items);
    showAlts (
        '\\hspace*{3mm}{\\tt ' @literal,
        alts,
        '} \\\\ \n' @literal,
        false
    )
enddefine;

define evalSyntax( x );
    lvars thisDef = (
        [%
            '\\begin{tabular}{l}\n' @literal,
            '{\\bf ' @literal,
                "def", consstring(#| count @printOn identfn, `.` |#), ' ',
                x.front.evalItem, ' ::= ',
            '}' @literal,
            '\\\\ \n' @literal,
            x.back.formRhs,
            '\\end{tabular}\n\n' @literal
        %]
    );
    thisDef @conspair syntaxDefs -> syntaxDefs;
    thisDef.dl
enddefine;

define evalRow( L );
    L @maplist evalItem
enddefine;

define evalTable( L );
    '\\begin{tabular}' @literal,
    '{|' @literal, repeat L.hd.pepperLength times 'l' endrepeat, '|}' @literal, '\n',
    lvars row;
    for row in L @maplist evalItem do
        lvars sep = '';
        lvars item;
        for item in_list row do
            sep, item, ' &' @literal -> sep
        endfor,
        '\\\\ \n' @literal
    endfor,
    '\\end{tabular}\n' @literal
enddefine;

define evalItemPara( x );
    '\n\n', x.evalItem
enddefine;

define evalItemParaList( xL );
    ;;; when should paragraphs breaks be inserted?
    ;;; -- between successive strings, I think. So ...
    lvars pending = [];
    until xL.null do
        lvars this;
        xL.dest -> ( this, xL );
        if this.meanStrength == "strong" then
            '\n\n', pending.rev @applist evalItem, this.evalItem, '';
            [] -> pending
        else
            this @conspair pending -> pending
        endif
    enduntil;
    unless pending.null do
        '\n\n', pending.rev @applist evalItem, ''
    endunless;
enddefine;

define evaluateActionWord =
    newanyproperty(
        [], 64, 1, false,
        false, false, "perm",
        mishap(% 1, 'Unrecognised word in evaluateActionWord' %),
        false
    )
enddefine;

define evalItem( item );
    lvars action = item.meanAction;
    lvars arg = item.meanArg;
    if action.isprocedure then
        mishap( 'Deprecated (temporarily) procedure not allowed', [ ^action ^arg ] );
        action
    elseif action.isword then
        evaluateActionWord( action )
    else
        mishap( 'Procedure or word needed', [ ^action ^arg ] )
    endif( arg )
enddefine;

vars inSuper = false;
vars inSub = false;
vars inBold = false;
vars inCode = false;
vars inItalics = false;
vars inMaths = false;

vars really = false;

;;; convert characters for output, keeping track of various settings

vars procedure outputSink;

define print( x );
    dlocal cucharout = outputSink;
    pr( x )
enddefine;

define literal( x );
    print(% x %)
enddefine;

define texLiteral( ch );
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
        unless inMaths do `$`.outputSink endunless;
        '^\\wedge'.print;
        unless inMaths do `$`.outputSink endunless;
    elseif ch == `\\` then
        unless inMaths do `$`.outputSink endunless;
        '\\setminus'.print;
        unless inMaths do `$`.outputSink endunless;
    elseif ch == `<` then
        unless inMaths do `$`.outputSink endunless;
        '<'.print;
        unless inMaths do `$`.outputSink endunless;
    elseif ch == `>` then
        unless inMaths do `$`.outputSink endunless;
        '>'.print;
        unless inMaths do `$`.outputSink endunless;
    elseif ch == `|` then
        unless inMaths do `$`.outputSink endunless;
        '\\mid'.print;
        unless inMaths do `$`.outputSink endunless;
    else
        ch.outputSink
    endif
enddefine;

define texOutput( ch );
    if really then
        ch.texLiteral;
        false -> really
    else
        if ch == `!` then
            true -> really
        elseif ch == `_` then
            if inBold then '}'.print; false -> inBold
            else '{\\bf '.print; true -> inBold
            endif
        elseif ch == `*` then
            if inItalics then '}'.print; false -> inItalics
            else '{\\em '.print; true -> inItalics
            endif
        elseif ch == `~` then
            if inSub then '$'.print; false -> inSub
            else '$_ '.print; true -> inSub
            endif
        elseif ch == `^` then
            if inSuper then '$'.print; false -> inSuper
            else '$^ '.print; true -> inSuper
            endif
        elseif ch == `|` then
            if inCode then '}'.print; false -> inCode
            else '{\\tt '.print; true -> inCode
            endif
        else
            ch.texLiteral
        endif
    endif
enddefine;

define printItem( item );
    if item.islist then item @applist printItem
    elseif item.isprocedure then [% item() %] @applist printItem
    else item @printOn texOutput
    endif
enddefine;

define runFromRepeater( r );
    lvars tokenizer = newTokenizer( r );
    [%
        '\\documentclass{report}\n' @literal,
        '\\setlength{\\parindent}{0in}\n' @literal,
        '\\setlength{\\parskip}{2mm}\n' @literal,
        delayedTitle,
        '\\author{Chris Dollin}\n' @literal,
        '\\begin{document}\n' @literal,
        '\\maketitle\n' @literal,
        '\\tableofcontents\n' @literal,
        applist( parseFromTokenizer( tokenizer ) -> _, evalItemPara ),
        '\\end{document}\n' @literal
    %] @applist printItem
enddefine;

;;; -----------------------------------------------------------
