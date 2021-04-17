OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION File.Exists (TargetFile AS STRING)

'$INCLUDE: 'C:\COSTA\SOURCE\APPINFO.BI'

CONST False = 0
CONST True = -1

DIM Sys.Path AS STRING

IF NOT COMMAND$ = "/?" AND NOT COMMAND$ = "/VER" THEN
    COLOR 7, 0
    CLS
ELSE
    PRINT ""
END IF

PRINT appName + " setup utility"
PRINT "Version " + appVersion + " - Made in 2004-" + appYear + " by Jacob Palm"
PRINT

IF COMMAND$ = "/?" OR COMMAND$ = "/VER" THEN END

PRINT "This program should only be used when COSTA.BAT is unable to launch Costa."
PRINT "It will ask you for the path to Costa, and recreate COSTA.BAT."
PRINT
PRINT
PRINT "Type the path to Costa's files below (leave blank to cancel):"

DO
    INPUT "Path: ", Sys.Path
    
    IF Sys.Path = "" THEN
        PRINT
        PRINT "This program wil now end. Nothing was changed."
        PRINT
        END
    END IF

    IF LEN(Sys.Path) > 1 THEN
        IF RIGHT$(Sys.Path, 1) = "\" OR RIGHT$(Sys.Path, 1) = "/" THEN Sys.Path = LEFT$(Sys.Path, LEN(Sys.Path) - 1)
    END IF

    IF File.Exists(Sys.Path + "\" + appExeName + ".EXE") THEN EXIT DO

    PRINT
    PRINT "Costa is not located in that directory. Please try again."
LOOP

PRINT
PRINT "Costa was found in the specified path. Writing new COSTA.BAT..."

ON ERROR GOTO WriteErr
OPEN Sys.Path + "\COSTA.BAT" FOR OUTPUT AS #1
PRINT #1, "@ECHO OFF"
PRINT #1, ""
PRINT #1, "REM " + appName + " " + appVersion + " - Made in 2004-" + appYear + " by Jacob Palm"
PRINT #1, ""
PRINT #1, "SET " + appEnviron + "=" + UCASE$(Sys.Path)
PRINT #1, "IF NOT EXIST %" + appEnviron + "%\" + appExeName + ".EXE GOTO ExeNotFound"
PRINT #1, "%" + appEnviron + "%\MOUSE.COM >NUL"
PRINT #1, "%" + appEnviron + "%\" + appExeName + ".EXE /BOOT"
PRINT #1, ":LoopStart"
PRINT #1, "IF ERRORLEVEL = 2 GOTO RunBat"
PRINT #1, "IF ERRORLEVEL = 1 GOTO Exit"
PRINT #1, "%" + appEnviron + "%\" + appExeName + ".EXE"
PRINT #1, "GOTO LoopStart"
PRINT #1, ":RunBat"
PRINT #1, "CALL %" + appEnviron + "%\DATA\TEMP\RUN.BAT"
PRINT #1, "DEL %" + appEnviron + "%\DATA\TEMP\RUN.BAT"
PRINT #1, "%" + appEnviron + "%\" + appExeName + ".EXE"
PRINT #1, "GOTO LoopStart"
PRINT #1, ":ExeNotFound"
PRINT #1, "ECHO."
PRINT #1, "ECHO " + appExeName + ".EXE was not found in %" + appEnviron + "%."
PRINT #1, "ECHO."
PRINT #1, "ECHO Run SETUP.EXE to fix this issue."
PRINT #1, "ECHO."
PRINT #1, "SET " + appEnviron + "="
PRINT #1, "GOTO EndOfBAT"
PRINT #1, ":Exit"
PRINT #1, "SET " + appEnviron + "="
PRINT #1, "CD \"
PRINT #1, "CLS"
PRINT #1, "ECHO Thank you for using " + appName + "."
PRINT #1, "ECHO."
PRINT #1, ":EndOfBAT"
CLOSE #1

PRINT
PRINT "Your COSTA.BAT has been recreated and should now be able to launch Costa."
PRINT

END

WriteErr:
PRINT
PRINT "There was en error writing to " + Sys.Path + "\COSTA.BAT"
PRINT "If the file already exists, make sure it isn't read-only."
PRINT
CLOSE
END

FUNCTION File.Exists (TargetFile AS STRING)

    DIM FileHandle
    FileHandle = FREEFILE
    ON LOCAL ERROR RESUME NEXT
    OPEN TargetFile FOR BINARY AS #FileHandle

    IF LOF(FileHandle) = 0 THEN
        'File doesn't exist
        CLOSE #FileHandle
        KILL TargetFile
        File.Exists = False
        EXIT FUNCTION
    ELSE
        CLOSE #FileHandle
        File.Exists = True
        EXIT FUNCTION
    END IF

END FUNCTION

