DEFINT A-Z
OPTION EXPLICIT

TYPE IconDataType
    Pixel(31, 31) AS INTEGER 'STRING * 1
END TYPE

DIM IconData AS IconDataType
DIM XPos, YPos
DIM scrBuffer(260)
DIM InputFile AS STRING, OutputFile AS STRING

SCREEN 12
PRINT
PRINT
PRINT
PRINT "Costa icon conversion utility"
PRINT "============================="
PRINT
PRINT "Use this utility to convert old icons in BSV format from Costa versions older"
PRINT "than 1.7.1 to the new BSV format."
PRINT
PRINT "To exit, simple leave filename blank."
PRINT

'Get filenames
INPUT "Input file (3KB file with .BSV extension: ", InputFile
IF LEN(InputFile) = 0 THEN END
INPUT "Output file (.BSV extension):             ", OutputFile
IF LEN(OutputFile) = 0 THEN END

'Load data in to array from old file
PRINT
PRINT "Loading and drawing icon..."
DEF SEG = VARSEG(IconData.Pixel(0, 0))
BLOAD InputFile, VARPTR(IconData.Pixel(0, 0))
DEF SEG

'Draw icon in top left screen corner
FOR XPos = 0 TO 31
    FOR YPos = 0 TO 31
        PSET (XPos, YPos), IconData.Pixel(XPos, YPos)
    NEXT
NEXT

'Capture icon from video memory, BSAVE to output file
PRINT "Capturing and saving icon to new file..."
GET (0, 0)-(31, 31), scrBuffer
DEF SEG = VARSEG(scrBuffer(0))
BSAVE OutputFile, VARPTR(scrBuffer(0)), UBOUND(scrBuffer) * 2
DEF SEG

PRINT
PRINT
PRINT "Done. Press any key to exit."

SLEEP
SCREEN 0

