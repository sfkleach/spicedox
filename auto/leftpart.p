define leftpart( str, n );
    allfirst( n - 1, str )
;;;     consstring(#|
;;;         lvars i;
;;;         for i from 1 to n - 1 do
;;;             subscrs( i, str )
;;;         endfor
;;;     |#)
enddefine;
