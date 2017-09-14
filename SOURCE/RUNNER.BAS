DECLARE FUNCTION File.Exists% (FileToCheck AS STRING)

DEFINT A-Z

PRINT
PRINT "The Costa Graphical Shell"
PRINT "Copyright 2004-2009 Jacob Palm"
PRINT
PRINT "Version 0.9.8"
PRINT

IF INSTR(COMMAND$, "/VER") OR INSTR(COMMAND$, "/?") THEN END

DIM StartTime AS SINGLE, EndTime AS SINGLE
StartTime = TIMER
EndTime = StartTime + 1

DO
LOOP UNTIL TIMER > EndTime OR TIMER < StartTime


DIM FileHandle
DIM Sys.Path AS STRING

FileHandle = FREEFILE
IF File.Exists("C:\CPATH.INI") THEN
	OPEN "C:\CPATH.INI" FOR INPUT AS #FileHandle
	LINE INPUT #FileHandle, Sys.Path
	CLOSE #FileHandle
ELSE
	PRINT "Costa needs to know where it's files are located. Please enter the path to the"
	PRINT "directory in which Costa is located (examples: C:\COSTA or C:\GUIS\COSTA)."
	PRINT
	DIM Tries
	DO
		INPUT "Path to Costa: ", Sys.Path
		IF NOT RIGHT$(Sys.Path, 1) = "\" THEN Sys.Path = Sys.Path + "\"
		PRINT
		IF File.Exists(Sys.Path + "DESKTOP.EXE") THEN EXIT DO
		PRINT "Costa is not located in that directory. Please try again."
		Tries = Tries + 1
		IF Tries = 2 THEN
			CLS
			PRINT "Please find out which directory Costa is located in, and make sure all files"
			PRINT "are present."
			PRINT
			END
		END IF
	LOOP
	CLS
	OPEN "C:\CPATH.INI" FOR OUTPUT AS #FileHandle
	PRINT #FileHandle, Sys.Path
	CLOSE #FileHandle
END IF

IF File.Exists(Sys.Path + "DATA\TEMP\RUNSTAT.TMP") OR File.Exists(Sys.Path + "DATA\TEMP\RUN.DAT") THEN
	PRINT "Costa is either already running, or was not exited correctly. If Costa is"
	PRINT "already running, you should not run another copy as this will result in a"
	PRINT "crash. If it's not running, just continue."
	PRINT
	PRINT "Continue [Y,N]?";
	DIM Key$
	DO
		Key$ = INKEY$
		IF LCASE$(Key$) = "y" THEN
			PRINT "Y"
			IF File.Exists(Sys.Path + "DATA\TEMP\RUN.DAT") THEN KILL Sys.Path + "DATA\TEMP\RUN.DAT"
			EXIT DO
		END IF
		IF LCASE$(Key$) = "n" THEN PRINT "N": PRINT : END
	LOOP
END IF

SHELL "CD " + LEFT$(Sys.Path, LEN(Sys.Path) - 1)
SHELL "MOUSE.COM"

ON ERROR RESUME NEXT
MKDIR "DATA"
CHDIR "DATA"
MKDIR "TEMP"
MKDIR "CONFIG"
MKDIR "FONTS"
MKDIR "IMAGES"
MKDIR "THEMES"
CHDIR ".."
KILL Sys.Path + "DATA\TEMP\*.DAT"
KILL Sys.Path + "DATA\TEMP\*.TMP"
KILL Sys.Path + "DATA\TEMP\*.INT"
KILL Sys.Path + "DATA\TEMP\*.BLU"
KILL Sys.Path + "DATA\TEMP\*.RED"
KILL Sys.Path + "DATA\TEMP\*.GRN"
ON ERROR GOTO 0

OPEN Sys.Path + "DATA\TEMP\RUNSTAT.TMP" FOR OUTPUT AS #FileHandle
PRINT #FileHandle, "1"
CLOSE #FileHandle

SCREEN 12

DIM RunCmd$, RunPath$, PauseOnExit

DO
	RunCmd$ = ""
	RunPath$ = ""

	IF File.Exists(Sys.Path + "DATA\TEMP\RUN.DAT") THEN
		OPEN Sys.Path + "DATA\TEMP\RUN.DAT" FOR INPUT AS #1
		IF LOF(1) > 0 THEN LINE INPUT #1, RunCmd$
		IF NOT EOF(1) THEN LINE INPUT #1, RunPath$
		IF NOT EOF(1) THEN
			INPUT #1, PauseOnExit
		ELSE
			PauseOnExit = 0
		END IF
		CLOSE #1
		KILL Sys.Path + "DATA\TEMP\RUN.DAT"
	END IF

	IF RunPath$ = "" THEN RunPath$ = Sys.Path
	IF RIGHT$(RunPath$, 1) = "\" THEN RunPath$ = LEFT$(RunPath$, LEN(RunPath$) - 1)

	IF RunCmd$ = "" THEN
		RunCmd$ = "DESKTOP"
		PauseOnExit = 0
		ON ERROR RESUME NEXT
		KILL Sys.Path + "DATA\TEMP\DESKTOP.INT"
		ON ERROR GOTO 0
	END IF


	IF RunCmd$ = "PLEASEGOAWAY" THEN EXIT DO

	IF MID$(RunPath$, 2, 1) = ":" THEN CHDRIVE LEFT$(RunPath$, 1)
	IF LEN(RunPath$) = 2 AND RIGHT$(RunPath$, 1) = ":" THEN
		CHDIR "\"
	ELSE
		CHDIR RunPath$
	END IF
	IF PauseOnExit = 1 THEN SCREEN 0: COLOR 7, 0
	SHELL RunCmd$
	IF PauseOnExit = 1 THEN
		SCREEN 0
		COLOR 0, 7
		LOCATE 25, 1: PRINT "Press any key to return to Costa..." + SPACE$(45);
		DO: LOOP WHILE LEN(INKEY$)
		DO: LOOP UNTIL LEN(INKEY$)
	END IF
LOOP

ON ERROR RESUME NEXT
KILL Sys.Path + "DATA\TEMP\*.DAT"
KILL Sys.Path + "DATA\TEMP\*.TMP"
KILL Sys.Path + "DATA\TEMP\*.INT"
KILL Sys.Path + "DATA\TEMP\*.BLU"
KILL Sys.Path + "DATA\TEMP\*.RED"
KILL Sys.Path + "DATA\TEMP\*.GRN"

SCREEN 0
COLOR 7, 0
CLS
PRINT "Thank you for using The Costa Graphical Shell."
PRINT
CHDIR "\"

FUNCTION File.Exists (FileToCheck AS STRING)

	DIM CheckFile

	'Turn on error handling
	ON LOCAL ERROR GOTO FileDoesntExist
	ERR = 0

	File.Exists = -1

	'Open the file and close it again
	CheckFile = FREEFILE
	OPEN FileToCheck FOR INPUT AS #CheckFile
	CLOSE #CheckFile

	ON LOCAL ERROR GOTO 0

	EXIT FUNCTION

FileDoesntExist:
	ERR = 0
	File.Exists = 0
	RESUME NEXT
END FUNCTION

