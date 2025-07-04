OPTION EXPLICIT
DEFINT A-Z

DIM TargetImg$, FoundFile$
DIM X, Y
DIM scrBuffer(260)

SCREEN 9
PRINT "Converting BSV images to raw integer data, please wait."

FoundFile$ = DIR$("DATA\IMAGES\*.BSV")
DO WHILE NOT FoundFile$ = ""
    TargetImg$ = LEFT$(FoundFile$, LEN(FoundFile$) - 4)

    LOCATE 2, 1: PRINT STRING$(8, " ")
    LOCATE 2, 1: PRINT TargetImg$

    'Load image and put on screen
    DEF SEG = VARSEG(scrBuffer(0))
    BLOAD "DATA\IMAGES\" + TargetImg$ + ".BSV", VARPTR(scrBuffer(0))
    DEF SEG
    PUT (50, 50), scrBuffer, PSET

    'Read each pixel and output to RAW file as integer color values
    OPEN "DATA\IMAGES\" + TargetImg$ + ".RAW" FOR OUTPUT AS #1
    FOR X = 0 TO 31
        FOR Y = 0 TO 31
            PRINT #1, POINT(X + 50, Y + 50)
        NEXT
    NEXT
    CLOSE #1

    'Get next file, if any
    FoundFile$ = DIR$
LOOP

SCREEN 0
PRINT "All images converted."

