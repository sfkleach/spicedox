;;; -- pepperLength -------------------------------------------

define class_pepperLength =
    newanyproperty(
        [
            [ ^string_key ^datalength ]
            [ ^pair_key ^length ]
            [ ^nil_key ^length ]
            [ ^word_key ^length ]
        ], 8, 1, false,
        false, false, "perm",
        procedure( x );
            mishap( x, 1, 'Trying to call pepperLength on this' )
        endprocedure,
        false
    )
enddefine;

define pepperLength( x );
    class_pepperLength( x.datakey )( x )
enddefine;


