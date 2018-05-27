DEFINT A-Z
OPTION EXPLICIT

DECLARE FUNCTION File.Browse (BYVAL WindowCaption AS STRING, BYVAL StartPath AS STRING) AS STRING

TYPE IconDataType
    Pixel(31, 31) AS INTEGER
END TYPE

DIM SHARED IconData AS IconDataType
DIM SHARED IconFileName AS STRING

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

STACK 5120

IF File.Exists(Sys.Path + "DATA\TEMP\RUNSTAT.TMP") = False THEN
    'DEBUG - not for final releases
    IF NOT COMMAND$ = "/DEV" THEN 'Debug - not for final release
        PRINT "This program is a part of " + appName + " and should not be executed"
        PRINT "directly from the command prompt."
        PRINT
        PRINT "To start Costa, run COSTA.BAT. If that file doesn't exist, run SETUP.EXE."
        PRINT
        END
    END IF
END IF

IF Sys.Path = "" OR File.Exists(Sys.Path + appExeName + ".exe") = False THEN
    CLS
    PRINT "The environment variable " + appExeName + ", which contains the path to Costa, is either"
    PRINT "not set or contains an invalid path."
    PRINT
    PRINT "Run SETUP.EXE to fix this issue."
    PRINT
    END
END IF

                                                      'DEBUG - not for final releases
IF NOT COMMAND$ = "/?" AND NOT COMMAND$ = "/VER" AND NOT COMMAND$ = "/DEV" THEN
    IconFileName = COMMAND$
END IF

Sys.Load

DIM TestFile$

TestFile$ = File.Browse("Please select a file to test", "C:\VBDOS")

FUNCTION File.Browse (BYVAL WindowCaption AS STRING, BYVAL StartPath AS STRING) AS STRING

    'Declarations
    DIM CurrentPath AS STRING
    DIM winFile AS WindowType, txtFilelist AS TextboxType
    DIM ReadFilename AS STRING
    DIM FileItems(1 TO 1) AS STRING * 14

    'DEBUG - check if start path exists

    'If StartPath is empty, set to root of the drive Costa is installed on
    IF StartPath = "" THEN StartPath = LEFT$(Sys.Path, 3)
    CurrentPath = StartPath

    'DEBUG
    DIM x1, y1
    x1 = 50
    y1 = 50


    WindowCaption = LTRIM$(RTRIM$(WindowCaption))
    IF WindowCaption = "" THEN WindowCaption = "Select file"
    winFile.Caption = WindowCaption
    Obj.SetSize winFile.Pos, x1, y1, 494, 374
    
    Obj.DrawWin winFile
    Font.Print "Current path: " + CurrentPath, x1 + 12, y1 + 32, ClrWindowText, FontNormal

    Obj.SetSize txtFilelist.Pos, x1 + 12, y1 + 50, 470, 312
    Obj.DrawTxt txtFilelist, "", False

    'DEBUG - drive list if above root?

    'DEBUG - if not root folder, add ".." entry

    'DEBUG - find folders first and add to array, surrounded by []

LoadFilelist:
    IF NOT RIGHT$(CurrentPath, 1) = "\" THEN CurrentPath = CurrentPath + "\"
    ReadFilename = DIR$(CurrentPath + "\")
    IF NOT ReadFilename = "" THEN
        FileItems(1) = ReadFilename
        DO
            ReadFilename = DIR$
            IF ReadFilename = "" THEN
                EXIT DO
            ELSE
                REDIM PRESERVE FileItems(1 TO UBOUND(FileItems) + 1) AS STRING * 14
                FileItems(UBOUND(FileItems)) = ReadFilename
            END IF
        LOOP
    END IF

PrintFileList:
    DIM I, XOffset, YOffset
    FOR I = 1 TO 100
        IF I < UBOUND(FileItems) THEN
            IF I <= 25 THEN
                XOffset = 0
                YOffset = 0
            ELSEIF I <= 50 THEN
                XOffset = 120
                YOffset = 25 * 12
            ELSEIF I <= 75 THEN
                XOffset = 240
                YOffset = 50 * 12
            ELSEIF I <= 100 THEN
                XOffset = 360
                YOffset = 75 * 12
            END IF
            Font.Print FileItems(I), txtFilelist.Pos.Left + 8 + XOffset, txtFilelist.Pos.Top - 4 + (12 * I) - YOffset, ClrTextboxText, FontSystem
        END IF
    NEXT


    
END FUNCTION

