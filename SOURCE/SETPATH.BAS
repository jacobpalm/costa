OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION File.Exists (TargetFile AS STRING)

'$INCLUDE: 'VBDOS.BI'
'$INCLUDE: 'C:\COSTA\SOURCE\APPINFO.BI'

CONST False = 0
CONST True = -1
CONST strIndent = "          "

DIM Sys.Path AS STRING
DIM strToPrint AS STRING, Tries

IF COMMAND$ = "/?" OR COMMAND$ = "/VER" OR COMMAND$ = "/HELP" THEN
	PRINT
	PRINT appName + " setup utility"
	PRINT "Version " + appVersion + " - Made in 2004-" + appYear + " by Jacob Palm"
	PRINT
	END
END IF

SCREEN 0
WIDTH 80, 25
COLOR 7, 1
CLS

'Draw header
COLOR 15, 1
PRINT
strToPrint = appName + " setup utility"
PRINT " " + strToPrint
PRINT " " + STRING$(LEN(strToPrint), "=")
COLOR 7, 1

'Draw info bar at bottom
LOCATE 25, 1
COLOR 0, 7
PRINT SPACE$(80);
LOCATE 25, 2
PRINT "Version " + appVersion;
strToPrint = "Made in 2004-" + appYear + " by Jacob Palm"
LOCATE 25, 80 - LEN(strToPrint)
PRINT strToPrint;

'Limit screen rows to middle of screen
LOCATE 5, 1
COLOR 7, 1
VIEW PRINT 5 TO 23
PRINT strIndent + "Welcome to the setup utility for Costa."
PRINT

IF COMMAND$ = "/?" OR COMMAND$ = "/VER" THEN END

PRINT strIndent + "If this is the first time you are starting Costa, use this"
PRINT strIndent + "utility to create a COSTA.BAT file which can then be used to"
PRINT strIndent + "launch Costa."
PRINT
PRINT strIndent + "You can also run this utility if Costa has been moved to"
PRINT strIndent + "another directory, to recreate the COSTA.BAT file."
PRINT
PRINT strIndent + "If Costa is already working as expecting,";
COLOR 15, 1
PRINT " leave the prompt"
PRINT strIndent + "blank to exit";
COLOR 7, 1
PRINT " without modifying COSTA.BAT."
PRINT
PRINT strIndent + "Type the path to Costa's files below - for example, C:\COSTA"
PRINT

DO
		COLOR 15, 1
		PRINT strIndent + "Path: ";
		COLOR 7, 1
		INPUT "", Sys.Path
		
		IF Sys.Path = "" THEN
				PRINT
				PRINT strIndent + "Nothing was changed."
				GOTO ExitUtility
		END IF

		IF LEN(Sys.Path) > 1 THEN
				IF RIGHT$(Sys.Path, 1) = "\" OR RIGHT$(Sys.Path, 1) = "/" THEN Sys.Path = LEFT$(Sys.Path, LEN(Sys.Path) - 1)
		END IF

		IF File.Exists(Sys.Path + "\" + appExeName + ".EXE") THEN EXIT DO

		Tries = Tries + 1
		IF Tries = 3 THEN
			PRINT
			PRINT strIndent + "Costa was not located in any of the directories entered."
			PRINT
			PRINT strIndent + "Please verify that all files are present in the directory,"
			PRINT strIndent + "and that the directory path is correct. Then run this"
			PRINT strIndent + "utility again."
			GOTO ExitUtility
		END IF

		PRINT
		PRINT strIndent + "Costa is not located in that directory. Please try again."
		PRINT
LOOP

PRINT
PRINT strIndent + "Costa was found in the specified path."
PRINT
PRINT strIndent + "Writing new COSTA.BAT... ";

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

PRINT "Done!"

PRINT
PRINT strIndent + "Your COSTA.BAT has been created, and you should now be able"
PRINT strIndent + "to launch Costa."

GOTO ExitUtility

WriteErr:
COLOR 12, 1
PRINT "Failed!"
COLOR 7, 1
PRINT
PRINT strIndent + "There was en error writing to"
PRINT strIndent + "  " + Sys.Path + "\COSTA.BAT"
PRINT
PRINT strIndent + "If the file already exists, make sure it isn't read-only."
CLOSE

ExitUtility:
PRINT
PRINT
COLOR 15, 1
PRINT strIndent + "Press any key to exit this utility."
DO: LOOP UNTIL LEN(INKEY$)

VIEW PRINT 1 TO 25
COLOR 7, 0
CLS

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

