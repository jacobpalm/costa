DECLARE SUB ConvertDesktop ()
DECLARE FUNCTION File.Exists% (TargetFile AS STRING)
DECLARE SUB ConvertTheme ()
DECLARE SUB ConvertImage ()
OPTION EXPLICIT
DEFINT A-Z

'$INCLUDE: 'C:\VBDOS\VBDOS.BI'

TYPE ThemeType
  Name AS STRING * 25
  Author AS STRING * 25
  Desktop AS INTEGER
  DesktopText AS INTEGER
  Window AS INTEGER
  WindowText AS INTEGER
  Button AS INTEGER
  Textbox AS INTEGER
  TextboxText AS INTEGER
  Light AS INTEGER
  Shadow AS INTEGER
  TitleBar AS INTEGER
  TitleBarText AS INTEGER
  Select AS INTEGER
  SelectText AS INTEGER
END TYPE

TYPE DeskLinkType
	Caption AS STRING * 25
	Filename AS STRING * 50
	Path AS STRING * 50
	Parameters AS STRING * 50
	ImageFile AS STRING * 8
	PauseOnExit AS INTEGER
	Left AS INTEGER
	Top AS INTEGER
END TYPE

TYPE DTAtype
	Drive AS STRING * 1
	SearchTemplate AS STRING * 11
	SearchAttr AS STRING * 1
	EntryCount AS STRING * 2
	ClusterNumber AS STRING * 2
	Reserved AS STRING * 4
	FileBits AS STRING * 1
	FileTime AS STRING * 2
	FileDate AS STRING * 2
	FileSize AS STRING * 4
	ASCIIZfilename AS STRING * 13
END TYPE

CONST False = 0
CONST True = NOT False

DIM Key$

PRINT "Costa 2.0 and newer uses different file formats than previous versions."
PRINT
PRINT "This utility will convert all data files (images, themes, and desktop configs)"
PRINT "from older versions to a raw, plain text format. This format will then be"
PRINT "converted automatically by another utility into the format used in the new"
PRINT "version of Costa."
PRINT
PRINT "Do you wish to continue (Y/N)?"
DO
	Key$ = LCASE$(INKEY$)
	IF Key$ = "y" THEN EXIT DO
	IF Key$ = "n" THEN END
LOOP

ConvertTheme
ConvertDesktop
ConvertImage

PRINT "All files converted to RAW format."
PRINT
PRINT "Next step is running RAWTOPAS.EXE, which will convert to the new format."
PRINT "Running now..."

SHELL "RAWTOPAS.EXE"

PRINT "Cleaning up RAW files..."

ON ERROR RESUME NEXT
KILL "..\DATA\THEMES\*.RAW"
KILL "..\DATA\CONFIG\*.RAW"
KILL "..\DATA\IMAGES\*.RAW"
PRINT
PRINT "Conversion completed."

SUB ConvertDesktop ()
	DIM LinkCount, LinkLoad, DesktopID
	DIM DeskLinkFile AS STRING, OutputFile AS STRING
	DIM DeskLink AS DeskLinkType

	PRINT "Converting desktop files..."

	FOR DesktopID = 1 TO 5
		DeskLinkFile = "..\DATA\CONFIG\DESKLNK" + LTRIM$(STR$(DesktopID)) + ".DAT"
		OutputFile = "..\DATA\CONFIG\DESKLNK" + LTRIM$(STR$(DesktopID)) + ".RAW"

		IF File.Exists(DeskLinkFile) THEN
		
			OPEN DeskLinkFile FOR BINARY AS #1
			IF NOT LOF(1) = 0 THEN GET #1, , LinkCount

			IF LinkCount > 1 THEN
				PRINT "DESKLNK" + LTRIM$(STR$(DesktopID)) + ".DAT => DESKLNK" + LTRIM$(STR$(DesktopID)) + ".RAW ";
				OPEN OutputFile FOR OUTPUT AS #2
				PRINT #2, LinkCount
				FOR LinkLoad = 0 TO LinkCount - 1
					GET #1, , DeskLink
					PRINT #2, RTRIM$(DeskLink.Caption)
					PRINT #2, RTRIM$(DeskLink.Filename)
					PRINT #2, RTRIM$(DeskLink.Path)
					PRINT #2, RTRIM$(DeskLink.Parameters)
					PRINT #2, RTRIM$(DeskLink.ImageFile)
					PRINT #2, DeskLink.PauseOnExit
					PRINT #2, DeskLink.Left
					PRINT #2, DeskLink.Top
				NEXT
				CLOSE #2
				PRINT "[OK]"
			END IF

			CLOSE #1
		END IF
	NEXT
	PRINT
END SUB

SUB ConvertImage ()
	DIM TargetFile$, FoundFile$
	DIM X, Y
	DIM scrBuffer(260)

	SCREEN 9
	PRINT
	PRINT "Converting BSV images to raw integer data, please wait."

	FoundFile$ = DIR$("..\DATA\IMAGES\*.BSV")
	DO WHILE NOT FoundFile$ = ""
		TargetFile$ = LEFT$(FoundFile$, LEN(FoundFile$) - 4)

		PRINT TargetFile$ + ".DAT => " + TargetFile$ + ".RAW ";

		'Load image and put on screen
		DEF SEG = VARSEG(scrBuffer(0))
		BLOAD "..\DATA\IMAGES\" + TargetFile$ + ".BSV", VARPTR(scrBuffer(0))
		DEF SEG
		PUT (400, 50), scrBuffer, PSET

		'Read each pixel and output to RAW file as integer color values
		OPEN "..\DATA\IMAGES\" + TargetFile$ + ".RAW" FOR OUTPUT AS #1
		FOR X = 0 TO 31
			FOR Y = 0 TO 31
				PRINT #1, POINT(X + 400, Y + 50)
			NEXT
		NEXT
		CLOSE #1

		LINE (400, 50)-(432, 82), 0, BF
		PRINT "[OK]"

		'Get next file, if any
		FoundFile$ = DIR$
	LOOP

	SCREEN 0
END SUB

SUB ConvertTheme ()
	DIM TargetFile$, FoundFile$
	DIM Theme AS ThemeType

	CLS
	PRINT "Converting DAT themes to raw string and integer data, please wait."

	FoundFile$ = DIR$("..\DATA\THEMES\*.DAT")
	DO WHILE NOT FoundFile$ = ""
		TargetFile$ = LEFT$(FoundFile$, LEN(FoundFile$) - 4)

		PRINT TargetFile$ + ".DAT => " + TargetFile$ + ".RAW ";

		'Load theme
		OPEN "..\DATA\THEMES\" + TargetFile$ + ".DAT" FOR BINARY AS #1
		GET #1, , Theme
		CLOSE #1

		'Output name/author and integer color values to file
		OPEN "..\DATA\THEMES\" + TargetFile$ + ".RAW" FOR OUTPUT AS #1
		PRINT #1, RTRIM$(Theme.Name)
		PRINT #1, RTRIM$(Theme.Author)
		PRINT #1, Theme.Desktop
		PRINT #1, Theme.DesktopText
		PRINT #1, Theme.Window
		PRINT #1, Theme.WindowText
		PRINT #1, Theme.Button
		PRINT #1, Theme.Textbox
		PRINT #1, Theme.TextboxText
		PRINT #1, Theme.Light
		PRINT #1, Theme.Shadow
		PRINT #1, Theme.TitleBar
		PRINT #1, Theme.TitleBarText
		PRINT #1, Theme.Select
		PRINT #1, Theme.SelectText
		CLOSE #1

		PRINT "[OK]"

		'Get next file, if any
		FoundFile$ = DIR$
	LOOP
	PRINT
END SUB

FUNCTION File.Exists (TargetFile AS STRING)
	DIM InRegsX AS RegTypeX, OutRegsX AS RegTypeX
	DIM DTAfile AS DTAtype
	DIM ASCIIZ AS STRING * 260
	DIM Current.DTA.SEG AS INTEGER, Current.DTA.OFF AS INTEGER

	ASCIIZ = TargetFile + CHR$(0)

	'Retrieve current DTA, so it can be reset later
	InRegsX.ax = &H2F00
	CALL INTERRUPTX(&H21, InRegsX, OutRegsX)
	Current.DTA.SEG = OutRegsX.es
	Current.DTA.OFF = OutRegsX.bx

	'Store function DTA
	InRegsX.ax = &H1A00
	InRegsX.ds = VARSEG(DTAfile)
	InRegsX.dx = VARPTR(DTAfile)
	CALL INTERRUPTX(&H21, InRegsX, OutRegsX)

	'Find first file
	InRegsX.ax = &H4E00
	InRegsX.cx = &H37
	InRegsX.ds = VARSEG(ASCIIZ)
	InRegsX.dx = VARPTR(ASCIIZ)
	CALL INTERRUPTX(&H21, InRegsX, OutRegsX)

	IF (OutRegsX.flags AND &H1) = &H0 THEN
		File.Exists = True
	ELSE
		File.Exists = False
	END IF

	'Restore previous DTA
	InRegsX.ax = &H1A00
	InRegsX.ds = Current.DTA.SEG
	InRegsX.dx = Current.DTA.OFF
	CALL INTERRUPTX(&H21, InRegsX, OutRegsX)
END FUNCTION

