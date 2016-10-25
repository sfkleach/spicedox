define catStrings( n );
    lvars L = conslist( n );
    consstring(#| applist( L, explode ) |#)
enddefine;
