uses newpushable;
uses @;
uses load;

loadcompiler( 'utils.p' );
loadcompiler( 'pepperLength.p' );
loadcompiler( 'parse.p' );
loadcompiler( 'evaluate.p' );

define addToSynPropsTable( list );
    lvars key_value;
    for key_value in list do
        key_value(2) -> synPropsTable( key_value(1) )
    endfor
enddefine;

evalLinkto -> evaluateActionWord( "EvalLinkto" );
evalLabel -> evaluateActionWord( "EvalLabel" );
evalRef -> evaluateActionWord( "EvalRef" );
evalPart -> evaluateActionWord( "EvalPart" );
evalIndented -> evaluateActionWord( "EvalIndented" );
evalTitle -> evaluateActionWord( "EvalTitle" );
evalChapter -> evaluateActionWord( "EvalChapter" );
evalAppendix -> evaluateActionWord( "EvalAppendix" );
evalSection -> evaluateActionWord( "EvalSection" );
evalPassage -> evaluateActionWord( "EvalPassage" );
evalFragment -> evaluateActionWord( "EvalFragment" );
evalList -> evaluateActionWord( "EvalList" );
evalSyntax -> evaluateActionWord( "EvalSyntax" );
evalIssue -> evaluateActionWord( "EvalIssue" );
evalRow -> evaluateActionWord( "EvalRow" );
evalSpice -> evaluateActionWord( "EvalSpice" );
evalTable -> evaluateActionWord( "EvalTable" );
evalAllSyntax -> evaluateActionWord( "EvalAllSyntax" );
evalAllIssues -> evaluateActionWord( "EvalAllIssues" );
evalN -> evaluateActionWord( "EvalN" );
evalT -> evaluateActionWord( "EvalT" );
evalContents -> evaluateActionWord( "EvalContents" );

oops -> evaluateActionWord( "Oops" );
oops(% termin %) -> evaluateActionWord( "OopsTermin" );
evalWord -> evaluateActionWord( "EvalWord" );
evalString -> evaluateActionWord( "EvalString" );

[%
    defInfix( "linkto", 20, "EvalLinkto" ),
    defPrefix( "label", "EvalLabel" ),
    defInfix( "ref", 20, "EvalRef" ),
    ;;; defSimpleNoParaWrapper( "asis", "pre" ),
    defWrapper( "part", "endpart", "EvalPart" ),
    defWrapper( "indented", "endindented", "EvalIndented" ),
    defWrapper( "title", "endtitle", "EvalTitle" ),
    defWrapper( "chapter", "endchapter", "EvalChapter" ),
    defWrapper( "appendix", "endappendix", "EvalAppendix" ),
    defWrapper( "section", "endsection", "EvalSection" ),
    defWrapper( "passage", "endpassage", "EvalPassage" ),
    defWrapper( "fragment", "endfragment", "EvalFragment" ),
    defWrapper( "list", "endlist", "EvalList" ),
    defWrapper( "syntax", "endsyntax", "EvalSyntax" ),
    defWrapper( "issue", "endissue", "EvalIssue" ),
    defWrapper( "row", "endrow", "EvalRow" ),
    defWrapper( "spice", "endspice", "EvalSpice" ),
    defWrapper( "table", "endtable", "EvalTable" ),
    defSimple( "allsyntax", "EvalAllSyntax" ),
    defSimple( "allissues", "EvalAllIssues" ),
    defSimple( "n", "EvalN" ),
    defSimple( "t", "EvalT" ),
    defSimple( "contents", "EvalContents" ),
    [ $ % newSingleSynProps( "daft", "$", "Oops" ) %],
%].addToSynPropsTable;

define handleFile( arg );
    runFromRepeater( arg.discin )
enddefine;

define main( source_file, output_file );
    dlocal outputSink = output_file.discout;
    handleFile( source_file );
    outputSink( termin )
enddefine;

;;; -----------------------------------------------------------
