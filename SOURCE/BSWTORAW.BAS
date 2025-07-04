DIM TargetImg AS STRING
TargetImg = "CALC"

SCREEN 9
DIM scrBuffer(260)
DEF SEG = VARSEG(scrBuffer(0))
BLOAD "DATA\IMAGES\" + TargetImg + ".BSV", VARPTR(scrBuffer(0))
DEF SEG
PUT (0, 0), scrBuffer, PSET

OPEN "DATA\IMAGES\" + TargetImg + ".RAW" FOR OUTPUT AS #1
FOR X = 0 TO 31
    FOR Y = 0 TO 31
        PRINT #1, POINT(X, Y)
    NEXT
NEXT
CLOSE #1

