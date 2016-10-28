define handleFile( arg );
    runFromRepeater( arg.discin )
enddefine;

define main( source_file, output_file );
    dlocal outputSink = output_file.discout;
    handleFile( source_file );
    outputSink( termin )
enddefine;

;;; -----------------------------------------------------------
