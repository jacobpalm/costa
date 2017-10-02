DECLARE FUNCTION File.Browse (BYVAL WindowCaption AS STRING, BYVAL StartPath AS STRING) AS STRING
DECLARE SUB IconEdit.Preview ()
DECLARE FUNCTION IconEdit.SaveIcon% ()
DECLARE FUNCTION IconEdit.LoadIcon% ()

DEFINT A-Z
OPTION EXPLICIT

DECLARE SUB IconEdit.Main ()

TYPE IconDataType
    Pixel(31, 31) AS INTEGER
END TYPE

DIM SHARED IconData AS IconDataType
DIM SHARED IconFileName AS STRING

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

STACK 5120

IF File.Exists(Sys.Path + "DATA\TEMP\RUNSTAT.TMP") = False THEN
    'DEBUG - not for final releases
    IF NOT COMMAND$ = "/DEV" THEN 'Debug - ikke for final release
        PRINT "This program is a part of The Costa Graphical Shell and should not be executed"
        PRINT "directly from the command prompt."
        PRINT
        PRINT "To start Costa, run COSTA.BAT. If that file doesn't exist, run SETUP.EXE."
        PRINT
        END
    END IF
END IF

IF Sys.Path = "" OR File.Exists(Sys.Path + "COSTA110.EXE") = False THEN
    CLS
    PRINT "The environment variable COSTA110, which contains the path to Costa, is either"
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

SUB Calc.Main ()
END SUB

SUB Conf.Main ()
END SUB

FUNCTION File.Browse (BYVAL WindowCaption AS STRING, BYVAL StartPath AS STRING) AS STRING

    'Declarations
    DIM CurrentPath AS STRING
    DIM winFile AS WindowType, txtFileList AS TextboxType

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
    Obj.SetSize winFile.Pos, x1, y1, 300, 300
    
    Obj.DrawWin winFile
    Font.Print "Current path: " + CurrentPath, x1 + 20, y1 + 30, clrWindowText, FontNormal

    Obj.SetSize txtFileList.Pos, x1 + 20, y1 + 40, 200, 250
    Obj.DrawTxt txtFileList, "", False


    DIM FileItems() AS STRING * 8
    
    'Hvis ikke root, tilf›j ".." element
    'Find mapper f›rst og tilf›j til array

    FILES



    SLEEP

END FUNCTION

SUB Tic.Main ()
END SUB

SUB TView.Main (FileToView AS STRING)
END SUB

