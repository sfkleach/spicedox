#!/usr/bin/env python3

import os
import os.path

FILE = '_test/manual.tex'
BASEFILE = 'base-manual.tex'

def fileContents( fname ):
    with open( fname, 'r' ) as f:
        return f.read()

if __name__ == "__main__":

    if os.path.exists( FILE ):
        os.remove( FILE )

    os.system( 'pop11 rundox.p' );

    if fileContents( BASEFILE ) == fileContents( FILE ):
        print( 'OK' )
    else:
        print( 'FAIL' )
