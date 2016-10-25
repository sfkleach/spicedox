define rightpart( str, n );
    allbutfirst( n, str )
;;;     consstring(#|
;;;         lvars i;
;;;         for i from n + 1 to str.datalength do
;;;             subscrs( i, str )
;;;         endfor
;;;     |#)
enddefine;
