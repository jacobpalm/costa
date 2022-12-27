OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION File.Exists (TargetFile AS STRING)
DECLARE FUNCTION Setup.InputPath () AS STRING
DECLARE FUNCTION Setup.UseDetectedPath% ()
DECLARE SUB Setup.DrawScreen ()
DECLARE SUB Setup.Exit ()
DECLARE SUB Setup.ExitPrompt ()
DECLARE SUB Setup.Main ()
DECLARE SUB Setup.WriteFile (TargetFolder AS STRING)

'$INCLUDE: 'C:\VBDOS\VBDOS.BI'
'$INCLUDE: 'C:\COSTA\SOURCE\APPINFO.BI'
'$INCLUDE: 'C:\COSTA\SOURCE\SYSPATH.BI'

CONST False = 0
CONST True = -1
CONST strIndent = "          "

IF COMMAND$ = "/?" OR COMMAND$ = "/VER" OR COMMAND$ = "/HELP" THEN
	PRINT
	PRINT appName + " setup utility"
	PRINT "Version " + appVersion + " - Made in 2004-" + appYear + " by Jacob Palm"
	PRINT
	END
END IF

Setup.Main

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

SUB Setup.DrawScreen ()

	DIM strToPrint AS STRING

	VIEW PRINT
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

END SUB

SUB Setup.Exit ()
	VIEW PRINT 1 TO 25
	COLOR 7, 0
	CLS
	END
END SUB

SUB Setup.ExitPrompt ()
	PRINT
	PRINT
	PRINT strIndent + "To exit this utility, ";
	COLOR 15, 1
	PRINT "press any key."
	DO: LOOP UNTIL LEN(INKEY$)
END SUB

FUNCTION Setup.InputPath () AS STRING

	DIM InputSysPath AS STRING
	DIM Tries

	Setup.DrawScreen
	PRINT strIndent + "Type the path to Costa below - for example, C:\COSTA"
	PRINT
	
	DO
		COLOR 15, 1
		PRINT strIndent + "Path: ";
		COLOR 7, 1
		INPUT "", InputSysPath

		InputSysPath = UCASE$(LTRIM$(RTRIM$(InputSysPath)))

		IF LEN(InputSysPath) > 1 THEN
			IF RIGHT$(InputSysPath, 1) = "\" OR RIGHT$(InputSysPath, 1) = "/" THEN InputSysPath = LEFT$(InputSysPath, LEN(InputSysPath) - 1)
		END IF

		IF File.Exists(InputSysPath + "\" + "DESKTOP.EXE") AND File.Exists(InputSysPath + "\" + "SETUP.EXE") THEN
			Setup.InputPath = InputSysPath
			EXIT FUNCTION
		END IF

		Tries = Tries + 1
		IF Tries = 3 THEN
			Setup.DrawScreen
			PRINT strIndent + "Costa was not located in any of the directories entered."
			PRINT
			PRINT strIndent + "Please verify that all files are present in the directory,"
			PRINT strIndent + "and that the directory path is correct. Then run this"
			PRINT strIndent + "utility again."
			Setup.ExitPrompt
			Setup.Exit
		END IF

		PRINT
		PRINT strIndent + "Costa is not located in that directory. Please try again."
		PRINT
	LOOP
																			
END FUNCTION

SUB Setup.Main ()

	DIM Path AS STRING

	SCREEN 0
	WIDTH 80, 25
	Setup.DrawScreen
	
	PRINT strIndent + "Welcome to the setup utility for Costa."
	PRINT

	PRINT strIndent + "If this is the first time you are starting Costa, use this"
	PRINT strIndent + "utility to create a COSTA.BAT file which can then be used to"
	PRINT strIndent + "launch Costa."
	PRINT
	PRINT strIndent + "You can also run this utility if Costa has been moved to"
	PRINT strIndent + "another directory, to recreate the COSTA.BAT file."
	PRINT

	IF Setup.UseDetectedPath THEN
		Setup.WriteFile Sys.Path
	ELSE
		Setup.WriteFile Setup.InputPath
	END IF

	Setup.ExitPrompt
	Setup.Exit

END SUB

FUNCTION Setup.UseDetectedPath ()

	DIM Key$

	PRINT strIndent + "Costa has been detected in the following path:"
	COLOR 15, 1
	PRINT strIndent + Sys.Path
	PRINT
	COLOR 7, 1
	PRINT strIndent + "To use this path, ";
	COLOR 15, 1
	PRINT "press the Enter key."
	PRINT
	COLOR 7, 1
	PRINT strIndent + "To use another path, ";
	COLOR 15, 1
	PRINT "press the Space key."
	PRINT
	COLOR 7, 1
	PRINT strIndent + "To exit without modifying anything, ";
	COLOR 15, 1
	PRINT "press the Escape key."
	COLOR 7, 1

	DO
		Key$ = INKEY$

		IF Key$ = CHR$(13) THEN
			Setup.UseDetectedPath = True
			EXIT FUNCTION
		END IF

		IF Key$ = CHR$(27) THEN
			Setup.Exit
		END IF

		IF Key$ = CHR$(32) THEN
			Setup.UseDetectedPath = False
			EXIT FUNCTION
		END IF

	LOOP

END FUNCTION

SUB Setup.WriteFile (TargetFolder AS STRING)

	IF RIGHT$(TargetFolder, 1) = "\" OR RIGHT$(TargetFolder, 1) = "/" THEN TargetFolder = LEFT$(TargetFolder, LEN(TargetFolder) - 1)

	ON LOCAL ERROR GOTO WriteFileError
	OPEN TargetFolder + "\COSTA.BAT" FOR OUTPUT AS #1
	PRINT #1, "@ECHO OFF"
	PRINT #1, ""
	PRINT #1, "REM " + appName + " " + appVersion + " - Made in 2004-" + appYear + " by Jacob Palm"
	PRINT #1, ""
	PRINT #1, "IF NOT EXIST " + TargetFolder + "\DESKTOP.EXE GOTO ExeNotFound"
	PRINT #1, "SET COSTEMP=%TEMP%"
	PRINT #1, "IF ""%COSTEMP%""=="""" SET COSTEMP=" + TargetFolder + "\DATA\TEMP"
	PRINT #1, "" + TargetFolder + "\MOUSE.COM >NUL"
	PRINT #1, "" + TargetFolder + "\DESKTOP.EXE /BOOT"
	PRINT #1, ":LoopStart"
	PRINT #1, "IF ERRORLEVEL = 2 GOTO RunBat"
	PRINT #1, "IF ERRORLEVEL = 1 GOTO Exit"
	PRINT #1, "" + TargetFolder + "\DESKTOP.EXE"
	PRINT #1, "GOTO LoopStart"
	PRINT #1, ":RunBat"
	PRINT #1, "CALL %COSTEMP%\RUN.BAT"
	PRINT #1, "DEL %COSTEMP%\RUN.BAT"
	PRINT #1, "" + TargetFolder + "\DESKTOP.EXE"
	PRINT #1, "GOTO LoopStart"
	PRINT #1, ":ExeNotFound"
	PRINT #1, "ECHO."
	PRINT #1, "ECHO DESKTOP.EXE was not found in " + TargetFolder + "."
	PRINT #1, "ECHO."
	PRINT #1, "ECHO Run SETUP.EXE to fix this issue."
	PRINT #1, "ECHO."
	PRINT #1, "GOTO EndOfBAT"
	PRINT #1, ":Exit"
	PRINT #1, "CD \"
	PRINT #1, "CLS"
	PRINT #1, "ECHO Thank you for using " + appName + "."
	PRINT #1, "ECHO."
	PRINT #1, ":EndOfBAT"
	CLOSE #1

	Setup.DrawScreen
	PRINT strIndent + "Your COSTA.BAT has been created, and you should now be able"
	PRINT strIndent + "to launch Costa by running:"
	PRINT
	COLOR 15, 1
	PRINT strIndent + "  " + TargetFolder + "\COSTA.BAT"
	COLOR 7, 1
	
	EXIT SUB

WriteFileError:

	Setup.DrawScreen
	COLOR 12, 1
	PRINT strIndent + "Failed to write file!"
	COLOR 7, 1
	PRINT
	PRINT strIndent + "There was en error writing to"
	COLOR 15, 1
	PRINT strIndent + "  " + TargetFolder + "\COSTA.BAT"
	PRINT
	COLOR 7, 1
	PRINT strIndent + "Make sure the path exists, and isn't marked as read-only."
	Setup.ExitPrompt
	Setup.Exit

	CLOSE
	
END SUB

