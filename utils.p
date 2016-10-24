uses popgospl
uses_project pop11

define oops( x );
    mishap( x, 1, 'oops' )
enddefine;

define catStrings( n );
    lvars L = conslist( n );
    consstring(#| applist( L, explode ) |#)
enddefine;

define sumapplist( list, procedure p );
    0;
    repeat #| applist( list, p ) |# times
        nonop +()
    endrepeat
enddefine;

define leftpart( str, n );
    allfirst( n - 1, str )
;;;     consstring(#|
;;;         lvars i;
;;;         for i from 1 to n - 1 do
;;;             subscrs( i, str )
;;;         endfor
;;;     |#)
enddefine;

define rightpart( str, n );
    allbutfirst( n, str )
;;;     consstring(#|
;;;         lvars i;
;;;         for i from n + 1 to str.datalength do
;;;             subscrs( i, str )
;;;         endfor
;;;     |#)
enddefine;
