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


define xxmeanArg( x );
    lvars a = x.meanArg;
    if a.null then
        mishap( x, 1, 'argh! it has a null arg!' )
    endif;
    a
enddefine;

;;; Returns true if -items- starts with a Meaning whose
;;; first member has an argument whose 1st element is -word-
;;; or is a member of -word-.
define startsWith( items, word );
    if items.null then false
    elseif word.islist then items.hd.xxmeanArg.front @member word
    else items.hd.xxmeanArg.front == word
    endif
enddefine;
