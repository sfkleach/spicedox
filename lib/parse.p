uses newpushable
uses @

;;; -- Token --------------------------------------------------

defclass Token {
    tokenValue,
    tokenSynProps
};

;;; -- Syntactic Properties -----------------------------------

defclass SynProps {
    synPropsStrength,
    synPropsStyle,
    synPropsOpeningBracketAux,
    synPropsClosingBracketAux,
    synPropsRank,
    synPropsActionWord
};

define newAnySynProps( strength, style, opener, closer, rank, action );
    lvars is_brackets = ( style == "FxendF" or style == "endF" );
    if opener then
        unless is_brackets then
            mishap( 'Invalid opener', [ ^opener ] )
        endunless
    endif;
    if closer then
        unless is_brackets then
            mishap( 'Invalid closer', [ ^closer ] )
        endunless
    endif;
    unless rank.isinteger do
        mishap( 'Invalid rank', [ ^rank ] )
    endunless;
    unless lmember( strength, [ weak strong daft ] ) do
        mishap( 'Invalid strength', [ ^strength ] )
    endunless;
    unless lmember( style, [ F x Fx xFx $ FxendF endF ] ) do
        mishap( 'Invalid style', [ ^style ] )
    endunless;
    unless action.isword do
        mishap( 'Word or procedure needed', [ ^action ] )
    endunless;
    consSynProps( strength, style, opener, closer, rank, action )
enddefine;

define newOpSynProps( strength, style, rank, action );
    newAnySynProps(  strength, style, false, false, rank, action )
enddefine;

define newSingleSynProps( strength, style, action );
    newAnySynProps( strength, style, false, false, 0, action )
enddefine;

define newPairedSynProps( strength, opener, closer, action );
    newAnySynProps( strength, "FxendF", opener, closer, 0, action );
    newAnySynProps( strength, "endF", opener, closer, 0, action );
enddefine;

define synPropsClosingBracket( s );
    lvars b = s.synPropsClosingBracketAux;
    unless b.isword do
        mishap( 'Trying to use undefined closer', [% s %] )
    endunless;
    b
enddefine;

define synPropsOpeningBracket( s );
    lvars b = s.synPropsOpeningBracketAux;
    unless b.isword do
        mishap( 'Trying to use undefined closer', [ ^s ] )
    endunless;
    b
enddefine;

define synPropsTable =
    newanyproperty(
        [], 64, 1, false,
        false, false, "perm",
        newSingleSynProps( "weak", "x", "EvalWord" ),
        false
    )
enddefine;

define newToken( w );
    lvars props = w.synPropsTable;
    consToken( w, w.synPropsTable )
enddefine;

;;; -- Meanings -----------------------------------------------

defclass Meaning {
    meanTitle,          ;;; debugging only
    meanStrength,
    meanArg,
    meanAction
};

define newAnyMeaning( token, strength, arg );
    unless lmember( strength, [ weak strong daft ] ) do
        mishap( 'Invalid Meaning strength', [ ^strength ] )
    endunless;
    unless arg.islist do
        mishap( 'Invalid arg (list needed)', [ ^arg ] )
    endunless;
    lvars action_word = token.tokenSynProps.synPropsActionWord;
    consMeaning(
        token.tokenValue,
        strength,
        arg,
        action_word
    )
enddefine;

define newMeaning( token, arg );
    newAnyMeaning( token, token.tokenSynProps.synPropsStrength, arg )
enddefine;

define newDaftMeaning( token, arg );
    newAnyMeaning( token, "daft", arg )
enddefine;

define lengthMeaning( m );
    lvars A = m.meanArg;
    lvars L = A.listlength;
    lvars i;
    for i in A do
        i.pepperLength + L -> L
    endfor;
    L
enddefine;

lengthMeaning -> class_pepperLength( Meaning_key );


define formString( s, endsWithNewline );
    lconstant weaksp = newSingleSynProps( "weak", "x", "EvalString" );
    lconstant strongsp = newSingleSynProps( "strong", "x", "EvalString" );
    consToken( s, if endsWithNewline then strongsp else weaksp endif )
enddefine;

define formTermin();
    consToken(
        termin,
        newSingleSynProps( "weak", "endF", "OopsTermin" )
    )
enddefine;


;;; -- Tokenization -------------------------------------------

;;;
;;; Mode is a positive integer that counts how deeply
;;; nested we are in a quasi-quoted content.  I use the phrase
;;; quasi-quoted with some trepidation, I doubt it is correct!
;;;


defclass Tokenizer {
    tokenizerSource,
    tokenizerMode       : pint,
    tokenizerDump
};

define newTokenizer( procedure r );
    consTokenizer(
        r.newpushable,  ;;; The character repeater.
        0,              ;;; In the normal context.
        []              ;;; The nested modes.
    )
enddefine;

define saveTokenizerMode( t );
    conspair( t.tokenizerMode, t.tokenizerDump ) -> t.tokenizerDump
enddefine;

define restoreTokenizerMode( t );
     t.tokenizerDump.dest ->  t.tokenizerDump -> t.tokenizerMode;
enddefine;

define enterQuasiQuoting( t );
    t.tokenizerMode + 1 -> t.tokenizerMode;
enddefine;



define peekCh( procedure r );
    r() ->> r()
enddefine;

vars procedure ( newToken );

define nextToken( procedure r, mode );

    define lconstant cantExtend( ch, chType );
        lvars newType = doxchartype( ch );
        not(
            newType == chType or
            ( chType == CHAR_letter and newType == CHAR_digit )
        )
    enddefine;

    define lconstant eatString( procedure r, ch );
        consstring(#|
            ch;
            repeat
                lvars newCh = r();
                lvars nextCh = newCh == termin and termin or r.peekCh;
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
        |#) @formString ( newCh == `\n` )
    enddefine;

    repeat
        lvars ch = r();
        quitunless( ch == ` ` or ch == `\n` or ch == `\t` );
    endrepeat;
    if ch == termin then
        formTermin()
    elseif ch == `\\` then
        lvars nextCh = r();
        if `a` <= nextCh and nextCh <= `z` then
            consword(#|
                nextCh;
                repeat
                    lvars newCh = r();
                    quitunless( `a` <= newCh and newCh <= `z` );
                    newCh
                endrepeat
            |#) @newToken, newCh -> r()
        elseif nextCh == `\\` then
            r @eatString nextCh
        else
            consword(#| nextCh |#) @newToken
        endif;
    elseif mode == 0 then
        r @eatString ch
    elseif ch == `\"` then
        consstring(#|
            ch,
            repeat
                lvars newCh = r();
                quitif( newCh == termin or newCh == ch or newCh == `\n` );
                newCh
            endrepeat,
            ch
        |#) @formString false
    else
        lvars chType = doxchartype( ch );
        if chType == CHAR_simple then
            consword(#| ch |#)
        else
            consword(#|
                ch;
                repeat
                    lvars newCh = r();
                    quitif( newCh == termin or ( newCh @cantExtend chType ) );
                    newCh
                endrepeat
            |#), newCh -> r()
        endif @newToken
    endif
enddefine;


define readToken( tokenizer );
    nextToken( tokenizer.tokenizerSource, tokenizer.tokenizerMode )
enddefine;

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
