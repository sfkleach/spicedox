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

define newStringToken( s, endsWithNewline );
    lconstant weaksp = newSingleSynProps( "weak", "x", "EvalString" );
    lconstant strongsp = newSingleSynProps( "strong", "x", "EvalString" );
    consToken( s, if endsWithNewline then strongsp else weaksp endif )
enddefine;

define newTerminToken();
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

define nextToken( procedure r, mode );
    ;;; Eat white space.
    repeat
        lvars ch = r();
        quitunless( ch == ` ` or ch == `\n` or ch == `\t` );
    endrepeat;

    if ch == termin then        ;;; Check for end-of-input.
        newTerminToken()
    elseif ch == `\\` then      ;;; Check for keyword, otherwise it's a string.
        lvars nextCh = r();
        if `a` <= nextCh and nextCh <= `z` then
            consword(#|
                nextCh;
                repeat
                    lvars newCh = r.peekChar;
                    quitunless( `a` <= newCh and newCh <= `z` );
                    r()
                endrepeat;
            |#) @newToken;
        elseif nextCh == `\\` then
            r @eatString nextCh
        else
            consword(#| nextCh |#) @newToken
        endif
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
        |#) @newStringToken false
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
