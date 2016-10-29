

;;; -- Parser -------------------------------------------------

constant maxRank = 200;

define makeOperand( T );
    newMeaning( T, [% T.tokenValue %] )
enddefine;

define makeNiladic( T );
    newDaftMeaning( T, [] )
enddefine;

define makeMonadic( L, T );
    newDaftMeaning( T, , [ ^L ] )
enddefine;

define makeMonadicWrapped( Ls, T );
    newDaftMeaning( T, Ls )
enddefine;

define makeDyadic( L, R, T );
    newDaftMeaning( T, [ ^L ^R ] )
enddefine;


vars unwrappers = [];

vars procedure ( parseStuff, parseRepeatedly, parseFromTokenizer );

define parseOperand( it, tokenizer, width ) -> ( answer, token );
    lvars it_syn = it.tokenSynProps;
    lvars s = it_syn.synPropsStyle;
    lvars rank = it_syn.synPropsRank;
;;;    [`parse operand starting`, s].reportln;
    if s == "Fx" and rank <= width then
        lvars ( R, newNext ) = readToken( tokenizer ) @parseStuff (tokenizer, rank - 1);
        R @makeMonadic it, newNext
    elseif s == "FxendF" then
        lvars wantedb = it_syn.synPropsClosingBracket;
        dlocal unwrappers = [ ^wantedb ^^unwrappers ];
        saveTokenizerMode( tokenizer );
        lvars ( X, closer ) = tokenizer.parseFromTokenizer;
        X @makeMonadicWrapped it;
        restoreTokenizerMode( tokenizer );
        lvars gotb = closer.tokenSynProps.synPropsClosingBracket;
        if gotb == wantedb then
            ;;; good; advance to the next token ...
            readToken( tokenizer )
        else
            ;;; ah. we have a random closer.
            if lmember( gotb, unwrappers ) then
                ;;; someone missed out *our* closer! Complain & deliver it.
                warning( 'missing closer', [% wantedb, "got", gotb %] );
                closer
            else
                ;;; this one is lonely. Discard it.
                warning( 'unexpected closer', [% gotb, 'nested in', unwrappers %] );
                readToken( tokenizer )
            endif
        endif
    elseif s == "x" then
        it.makeOperand, readToken( tokenizer )
    elseif s == "F" then
        it @makeNiladic,  readToken( tokenizer )
    elseif s == "$" then
        tokenizer.enterQuasiQuoting;
        readToken( tokenizer ) @parseOperand (tokenizer, width)
    else
        mishap( 'what sort of starter is this?', [^it] )
    endif -> ( answer, token );
    unless answer.isMeaning do
        mishap( 'ParseOperand says Meaning needed', [ ^answer ] )
    endunless;
enddefine;

define parseStuff( this, tokenizer, width ) -> ( L, next );
    (this) @parseOperand (tokenizer, width) -> ( L, next );
    repeat
        lvars next_syn = next.tokenSynProps;
        lvars s = next_syn.synPropsStyle;
        lvars rank = next_syn.synPropsRank;
        quitunless( s == "xF" or s == "xFx" ) and ( rank <= width );
        if s == "xF" then
            ;;; [`-- that is postfix`].reportln;
            L @makeMonadic next -> L,  readToken( tokenizer ) -> next
        else
            ;;; [`-- that is infix`].reportln;
            lvars ( R, newNext ) =  readToken( tokenizer ) @parseStuff (tokenizer, rank - 1);
            (L, R) @makeDyadic next -> L, newNext -> next
        endif
    endrepeat;
    unless L.isMeaning do
        mishap( 'parseStuff says Meaning needed', [ ^L ] )
    endunless;
enddefine;

define parseRepeatedly( tokenizer, width );
    lvars this = tokenizer.readToken;
    [%
        until this.tokenSynProps.synPropsStyle == "endF" do
            (this) @parseStuff (tokenizer, width) -> this
        enduntil
    %];
    this
enddefine;

define parseFromTokenizer( tokenizer );
    parseRepeatedly( tokenizer, maxRank )
enddefine;

;;; -----------------------------------------------------------


define defWrapper( name, endName, action );
    lvars ( a, b ) = newPairedSynProps( "strong", name, endName, action );
    ( [ ^name ^a ], [ ^endName ^b ] )
enddefine;

define defWeakWrapper( name, endName, action );
    lvars ( a, b ) = newPairedSynProps( "weak", name, endName, action );
    ( [ ^name ^a ], [ ^endName ^b ] )
enddefine;

define defSimple( name, action );
    [% name, newSingleSynProps( "strong", "F", action ) %]
enddefine;

;;; define defSimpleWrapper( name, wrapper );
;;;     lvars endName = consword(#| 'end'.explode, name.explode |#);
;;;     defWrapper( name, endName, evalWrap(% wrapper %) )
;;; enddefine;
;;;
;;; define defSimpleNoParaWrapper( name, wrapper );
;;;     lvars endName = "end" <> name;
;;;     defWeakWrapper( name, endName, evalNoParaWrap(% wrapper %) )
;;; enddefine;
;;;
;;; define defOperator( name, rank, proc );
;;;     [% name, newOpSynProps( "strong", "plain", rank, evalOp(% name, proc %) ) %]
;;; enddefine;

define defInfix( name, level, action );
    [% name, newOpSynProps( "weak", "xFx", level, action ) %]
enddefine;

define defPrefix( name, action );
    [% name, newOpSynProps( "weak", "Fx", 20, action ) %]
enddefine;

;;; -----------------------------------------------------------


define addToSynPropsTable( list );
    lvars key_value;
    for key_value in list do
        key_value(2) -> synPropsTable( key_value(1) )
    endfor
enddefine;

[%
    defInfix( "linkto", 20, "EvalLinkto" ),
    defPrefix( "label", "EvalLabel" ),
    defInfix( "ref", 20, "EvalRef" ),
    ;;; defSimpleNoParaWrapper( "asis", "pre" ),
    defWrapper( "part", "endpart", "EvalPart" ),
    defWrapper( "indented", "endindented", "EvalIndented" ),
    defWrapper( "title", "endtitle", "EvalTitle" ),
    defWrapper( "chapter", "endchapter", "EvalChapter" ),
    defWrapper( "appendix", "endappendix", "EvalAppendix" ),
    defWrapper( "section", "endsection", "EvalSection" ),
    defWrapper( "passage", "endpassage", "EvalPassage" ),
    defWrapper( "fragment", "endfragment", "EvalFragment" ),
    defWrapper( "list", "endlist", "EvalList" ),
    defWrapper( "syntax", "endsyntax", "EvalSyntax" ),
    defWrapper( "issue", "endissue", "EvalIssue" ),
    defWrapper( "row", "endrow", "EvalRow" ),
    defWrapper( "spice", "endspice", "EvalSpice" ),
    defWrapper( "table", "endtable", "EvalTable" ),
    defSimple( "allsyntax", "EvalAllSyntax" ),
    defSimple( "allissues", "EvalAllIssues" ),
    defSimple( "n", "EvalN" ),
    defSimple( "t", "EvalT" ),
    defSimple( "contents", "EvalContents" ),
    [ $ % newSingleSynProps( "daft", "$", "Oops" ) %],
%].addToSynPropsTable;
