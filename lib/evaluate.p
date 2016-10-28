;;; -- Main ---------------------------------------------------

defclass Evaluator {
};

vars procedure ( evalWrap, evalNoParaWrap, evalOp, evalItem, literal );

define evalWord( w, self );
    w.dl
enddefine;

define evalString( w, self );
    w @applist identfn
enddefine;

define evalOp( x, name, proc, self );
    lvars ( L, R ) = x.dest.hd;
    `(`, L @evalItem self, name, R @evalItem self, `)`
enddefine;

define evalLinkto( x, self );
    lvars ( L, R ) = x.dest.hd;
    L @evalItem self, ' (', R @evalItem self, ')'
enddefine;

define evalLabel( x, self );
    consstring(#|
        '\\label{'.explode,
        x.front.meanArg.front.explode,
        '}'.explode
    |#) @literal
enddefine;

define evalRef( x, self );
    lvars ( L, R ) = x.dest.hd;
    consstring(#|
        '\\ref={'.explode,
        L.meanArg.front.explode,
        '}'.explode
    |#) @literal,
    R @evalItem self
enddefine;

define evalBrackets( x, self );
    x @applist evalItem(% self %)
enddefine;

define evalN( x, self );
    '\\\\ \n' @literal
enddefine;

define evalT( x, self );
    ' \\> ' @literal
enddefine;

define evalBoxes( x, self );
    x @applist evalItem(% self %)
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

vars procedure ( evalItemParaList );

vars savedTitle = false;

define evalTitle( x, self );
    x @maplist evalItem(% self %) -> savedTitle;
    ;;; "<h1>", savedTitle.dl, "</h1>"
enddefine;

define delayedTitle();
    if savedTitle then
        '\\title{' @literal,
        savedTitle.dl;
        '}\n' @literal;
    endif
enddefine;

define doHeaded( x, level, command, self );
    unless self.isEvaluator do
        mishap( 'Evaluator needed', [ ^self] )
    endunless;
    lvars ( numeric, title ) = x.front.splitTitle;
    ;;; val header = catStrings(# level @nextNumber numeric, space, title.evalItem #);
    lvars header = title @evalItem self;
    [ ^level ^^contentsList] -> contentsList;
    '\\' @literal, command, '{' @literal, header, '}\n' @literal,
    x.tl @evalItemParaList self
enddefine;

vars inAppendix = false;

define setAppendix();
    unless inAppendix do
        '\\appendix\n' @literal, true -> inAppendix
    endunless
enddefine;

define evalAppendix( x, self );
    setAppendix, x @doHeaded (1, 'chapter', self)
enddefine;

define evalChapter( x, self );
    x @doHeaded (1, 'chapter', self)
enddefine;

define evalSection( x, self );
    x @doHeaded (2, 'section', self)
enddefine;

define evalPassage( x, self );
    x @doHeaded (3, 'subsection', self)
enddefine;

define evalFragment( x, self );
    x @doHeaded (4, 'subsubsection', self )
enddefine;

define evalIndented( x, self );
    '\\begin{quote}' @literal,
    x @applist evalItem(% self %),
    '\\end{quote}' @literal
enddefine;

define evalPart( x, self );
    '\\part{' @literal,
    x.hd @evalItem self,
    '}\n' @literal,
    x.tl @applist evalItem(% self %), '\n\n'
enddefine;

define evalList( elems, self );
    '\\begin{itemize}' @literal,
    lvars x;
    for x in elems do '\\item ' @literal, x @evalItem self, '\n\n' endfor,
    '\\end{itemize}' @literal
enddefine;

define evalSpice( blocks, self );
    lvars gap = '';
    '\\begin{quote}\n' @literal,
    '\\begin{verbatim}\n' @literal,
    lvars x;
    for x in blocks do
        gap, '\n' -> gap, [% x @evalItem self %] @maplist literal
    endfor,
    '\\end{verbatim}\n' @literal,
    '\\end{quote}\n' @literal
enddefine;

vars theseIssues = [];

vars procedure ( evalItemPara );

define evalIssue( x, self );
    lvars thisIssue;
    [%
        '\n\n',
        '{\\bf ' @literal, x.front @evalItemPara, '}' @literal,
        x.back @evalItemParaList self,
        ''
    %] -> thisIssue;
    thisIssue @conspair theseIssues -> theseIssues;
    thisIssue.dl
enddefine;

define evalAllIssues( x );
    theseIssues.rev @applist dl
enddefine;

vars syntaxDefs = [];
vars syntaxCount = 0;

define evalAllSyntax( x, self );
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

define evalVisibleBrackets( x, self );
    "(", x @showSeq ('', true, self), ")"
enddefine;

define evalVisibleBoxes( x, self );
    '[', x @showSeq ('', true, self), ']'
enddefine;

define showItem( item, nested, self );
    unless self.isEvaluator do
        mishap( 'Evaluator needed', [ ^self ] )
    endunless;
    if item.isMeaning then
        item @evalItem self
    else
        lvars key = item.front;
        if key == "SEQ" then
            "(", item.back @showSeq ('', true, self), ")"
        elseif key == "ALT" then
            "(", showAlts( '', item, '', true, self), ")"
        elseif key == "STAR" then
            item.back.back.front @showItem ( true, self ),
            item.back.front @showItem ( true, self ) @literal
        elseif key == "OPT" then
            '[', item.back.front @showItem ( true, self ), ']'
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

define showSeq( seq, prefix, nested, self );
    unless self.isEvaluator do
        mishap( 'Evaluator needed', [ ^self ] )
    endunless;
    lvars gap = '';
    lvars k = seq.blobLength;
    ;;; ["blobLength", k].reportln;
    if k < 72 or nested then
        lvars item;
        for item in_list seq do
            prefix, gap, ' ' -> gap, item @showItem ( true, self )
        endfor
    else
        '\\begin{tabular}{l}\n' @literal,
        lvars item;
        for item in_list seq do
            prefix, gap, ' ' -> gap, item @showItem ( nested, self ), ' \\\\ \n' @literal
        endfor,
        '\\end{tabular}\n' @literal
    endif
enddefine;

define showAlts( prefix, alts, suffix, nested, self );
    unless self.isEvaluator do
        mishap( 'Evaluator needed', [ ^self ] )
    endunless;
    lvars sep = '';
    if nested then
        lvars alt;
        for alt in_list alts.back do
            prefix, sep, alt.back @showSeq ('', true, self), suffix,
            ' !| ' -> sep
        endfor
    else
        lvars alt;
        for alt in_list alts.back do
            prefix, sep, alt.back @showSeq ('', nested, self), suffix,
            ' !| ' -> sep
        endfor
    endif
enddefine;

define formRhs( items, self );
    lvars maxWidth = 72;
    lvars n = sumapplist( items, pepperLength );
    lvars alts;
    items.parseAlts -> (alts, items);
    showAlts (
        '\\hspace*{3mm}{\\tt ' @literal,
        alts,
        '} \\\\ \n' @literal,
        false,
        self
    )
enddefine;

define evalSyntax( x, self );
    lvars count = syntaxCount + 1 ->> syntaxCount;
    lvars thisDef = (
        [%
            '\\begin{tabular}{l}\n' @literal,
            '{\\bf ' @literal,
                "def", consstring(#| count @printOn identfn, `.` |#), ' ',
                x.front @evalItem self, ' ::= ',
            '}' @literal,
            '\\\\ \n' @literal,
            x.back @formRhs self,
            '\\end{tabular}\n\n' @literal
        %]
    );
    thisDef @conspair syntaxDefs -> syntaxDefs;
    thisDef.dl
enddefine;

define evalRow( L, self );
    L @maplist evalItem(% self %)
enddefine;

define evalTable( L, self );
    '\\begin{tabular}' @literal,
    '{|' @literal, repeat L.hd.pepperLength times 'l' endrepeat, '|}' @literal, '\n',
    lvars row;
    for row in L @maplist evalItem(% self %) do
        lvars sep = '';
        lvars item;
        for item in_list row do
            sep, item, ' &' @literal -> sep
        endfor,
        '\\\\ \n' @literal
    endfor,
    '\\end{tabular}\n' @literal
enddefine;

define evalItemPara( x, self );
    '\n\n', x @evalItem self
enddefine;

define evalItemParaList( xL, self );
    unless self.isEvaluator do
        mishap( 'Evaluator needed', [ ^self ] )
    endunless;
    ;;; when should paragraphs breaks be inserted?
    ;;; -- between successive strings, I think. So ...
    lvars pending = [];
    until xL.null do
        lvars this;
        xL.dest -> ( this, xL );
        if this.meanStrength == "strong" then
            '\n\n';
            lvars i;
            for i in pending.rev do
                evalItem( i, self )
            endfor;
            this @evalItem self;
            '';
            [] -> pending
        else
            this @conspair pending -> pending
        endif
    enduntil;
    unless pending.null do
        '\n\n', pending.rev @applist evalItem(% self %), ''
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

define evalItem( item, self );
    unless self.isEvaluator do
        mishap( 'Evaluator needed', [ ^self ] )
    endunless;
    lvars action = item.meanAction;
    lvars arg = item.meanArg;
    if action.isprocedure then
        mishap( 'Deprecated (temporarily) procedure not allowed', [ ^action ^arg ] );
        action
    elseif action.isword then
        evaluateActionWord( action )
    else
        mishap( 'Procedure or word needed', [ ^action ^arg ] )
    endif( arg, self )
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

define evaluate( parser );
    [%
        '\\documentclass{report}\n' @literal,
        '\\setlength{\\parindent}{0in}\n' @literal,
        '\\setlength{\\parskip}{2mm}\n' @literal,
        delayedTitle,
        '\\author{Chris Dollin}\n' @literal,
        '\\begin{document}\n' @literal,
        '\\maketitle\n' @literal,
        '\\tableofcontents\n' @literal,
        applist( parser(), evalItemPara(% consEvaluator() %) ),
        '\\end{document}\n' @literal
    %] @applist printItem
enddefine;

define runFromRepeater( r ); lvars procedure r;
    evaluate( newParser( newTokenizer( r ) ) )
enddefine;

;;; -----------------------------------------------------------

define evalOops( L, self );
    oops( L )
enddefine;

define evalOopsTermin( L, self );
    oops( termin )
enddefine;

;;; -----------------------------------------------------------

evalLinkto -> evaluateActionWord( "EvalLinkto" );
evalLabel -> evaluateActionWord( "EvalLabel" );
evalRef -> evaluateActionWord( "EvalRef" );
evalPart -> evaluateActionWord( "EvalPart" );
evalIndented -> evaluateActionWord( "EvalIndented" );
evalTitle -> evaluateActionWord( "EvalTitle" );
evalChapter -> evaluateActionWord( "EvalChapter" );
evalAppendix -> evaluateActionWord( "EvalAppendix" );
evalSection -> evaluateActionWord( "EvalSection" );
evalPassage -> evaluateActionWord( "EvalPassage" );
evalFragment -> evaluateActionWord( "EvalFragment" );
evalList -> evaluateActionWord( "EvalList" );
evalSyntax -> evaluateActionWord( "EvalSyntax" );
evalIssue -> evaluateActionWord( "EvalIssue" );
evalRow -> evaluateActionWord( "EvalRow" );
evalSpice -> evaluateActionWord( "EvalSpice" );
evalTable -> evaluateActionWord( "EvalTable" );
evalAllSyntax -> evaluateActionWord( "EvalAllSyntax" );
evalAllIssues -> evaluateActionWord( "EvalAllIssues" );
evalN -> evaluateActionWord( "EvalN" );
evalT -> evaluateActionWord( "EvalT" );
;;; evalContents -> evaluateActionWord( "EvalContents" );

evalOops -> evaluateActionWord( "Oops" );
evalOopsTermin -> evaluateActionWord( "OopsTermin" );
evalWord -> evaluateActionWord( "EvalWord" );
evalString -> evaluateActionWord( "EvalString" );

;;; -----------------------------------------------------------
