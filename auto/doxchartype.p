
constant CHAR_plain = 0;
constant CHAR_digit = 1;
constant CHAR_letter = 2;
constant CHAR_simple = 3;
constant CHAR_sign = 4;
constant CHAR_termin = 5;
constant CHAR_slash = 6;
constant CHAR_layout = 7;
constant CHAR_dollar = 8;

lconstant answer = consstring(#| repeat 256 times CHAR_plain endrepeat |#);

constant charTable = (
    lblock

        define lconstant setType( charType, chars, table );
            lvars i;
            for i from 1 to chars.datalength do
                charType -> subscrs( subscrs( i, chars ), table )
            endfor
        enddefine;

        setType( CHAR_digit, '0123456789', answer );
        setType( CHAR_simple, '(){}[];', answer );
        setType( CHAR_layout, '\n\t\s', answer );
        setType( CHAR_slash, '\\', answer );
        setType( CHAR_dollar, '$', answer );
        setType( CHAR_sign, '!@#~%^&*+-=|:<>?/', answer );
        setType( CHAR_letter, 'abcdefghijklmnopqrstuvwxyz', answer );
        setType( CHAR_letter, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', answer );
        answer
    endlblock
);

define doxchartype( ch );
    subscrs( ch, charTable )
enddefine;
