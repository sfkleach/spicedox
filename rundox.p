uses load;
extend_searchlist( '$poplib/auto', popautolist ) -> popautolist;
extend_searchlist( '$poplib/lib', popuseslist ) -> popuseslist;

loadcompiler( 'dox.p' );

main( 'manual.web', '_test/manual.tex' );
