DECLARE SUB Script.Parse (TargetSub AS STRING)
DECLARE SUB Script.Main ()
DEFINT A-Z
OPTION EXPLICIT

DIM SHARED ScriptFileName AS STRING

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

STACK 5120

IF File.Exists(Sys.Path + "DATA\TEMP\RUNSTAT.TMP") = False THEN
    IF NOT COMMAND$ = "/DEV" THEN 'Debug - ikke for final release
        CLS
        PRINT "This program is a part of The Costa Graphical Shell and should not be executed"
        PRINT "directly from the command prompt."
        PRINT
        PRINT "To start Costa, run COSTA.BAT. If that file doesn't exist, run SETUP.EXE."
        PRINT
        END
    END IF
END IF

IF Sys.Path = "" OR File.Exists(Sys.Path + "COSTA100.EXE") = False THEN
    CLS
    PRINT "The environment variable COSTA100, which contains the path to Costa, is either"
    PRINT "not set or contains an invalid path."
    PRINT
    PRINT "Run SETUP.EXE to fix this issue."
    PRINT
    END
END IF

IF NOT COMMAND$ = "/?" AND NOT COMMAND$ = "/VER" AND NOT COMMAND$ = "/DEV" THEN
    ScriptFileName = COMMAND$
END IF

Sys.Load

Script.Main

SUB Calc.Main ()
END SUB

SUB Conf.Main ()
END SUB

SUB Script.Main ()

    DIM Dummy

    IF RTRIM$(ScriptFileName) = "" THEN
        Dummy = Sys.MsgBox("No script specified", "To run a script, pass its filename as" + CHR$(13) + "a parameter to this program.", msgInfo)
        END
    END IF
    IF NOT File.Exists(ScriptFileName) THEN
        Dummy = Sys.MsgBox("Script not found", "The filename specified is either invalid," + CHR$(13) + "or the file doesn't exist.", msgError)
        END
    END IF

    Script.Parse "Script_Load"

    'Main loop to check for keypress, click etc.
    DO

        'DEBUG
        IF INKEY$ = CHR$(27) THEN END

    LOOP


END SUB

SUB Script.Parse (TargetSub AS STRING)

    DIM ToDo$
    DIM ScriptHandle, Dummy
    DIM Param(1 TO 6) AS STRING

    'Open the script file
    ScriptHandle = FREEFILE
    OPEN ScriptFileName FOR INPUT AS #ScriptHandle
    
    'Find the right Sub
    TargetSub = LCASE$(TargetSub)
    WHILE NOT EOF(ScriptHandle)
        LINE INPUT #1, ToDo$
        ToDo$ = LTRIM$(RTRIM$(LCASE$(ToDo$)))

        IF LEN(ToDo$) >= LEN(TargetSub) + 4 THEN
            IF LEFT$(ToDo$, LEN(TargetSub) + 4) = "sub " + TargetSub THEN
                GOTO SubFound
            END IF
        END IF
    WEND

    Dummy = Sys.MsgBox("SUB not found", "The specified sub was not found in the script:" + CHR$(13) + TargetSub + CHR$(13) + "Script execution will be halted.", msgError)
    END

SubFound:

    'Get commands.
    'Ignore lines starting with apostrophe - '
    'Divide into command and parameters
    'Perform commands. Full error checking
    
    DO
GetCommand:
        IF EOF(ScriptHandle) THEN
            Dummy = Sys.MsgBox("Missing END SUB", "The end of the script file was reached, because an" + CHR$(13) + "END SUB was missing for the current sub:" + CHR$(13) + TargetSub + CHR$(13) + "Script execution will be halted.", msgError)
            END
        END IF

        LINE INPUT #ScriptHandle, ToDo$
        ToDo$ = LTRIM$(RTRIM$(ToDo$))

        IF LEN(ToDo$) = 0 THEN GOTO GetCommand
        IF LEFT$(ToDo$, 1) = "'" THEN GOTO GetCommand
        IF LCASE$(ToDo$) = "end sub" THEN EXIT DO

        'Split command and parameters here

    LOOP

    CLOSE #ScriptHandle

END SUB

SUB Tic.Main ()
END SUB

SUB TView.Main (FileToView AS STRING)
END SUB

