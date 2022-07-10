DECLARE FUNCTION File.Select (Pattern AS STRING) AS STRING
DEFINT A-Z
OPTION EXPLICIT

DECLARE SUB File.GetChildren (Path$, FilePattern$)

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

'$INCLUDE: 'C:\VBDOS\VBDOS.BI'
'$INCLUDE: 'SOURCE\COSTALIB.BI'

DIM SHARED FolderCount AS INTEGER, FileCount AS INTEGER
DIM SHARED SubFolders() AS STRING
DIM SHARED SubFiles() AS STRING

Sys.Load

DIM Filename AS STRING
Filename = File.Select("*.*")

PRINT Filename
END

DEFSNG A-Z
SUB File.GetChildren (Path$, FilePattern$)
	DIM InRegsX AS RegTypeX, OutRegsX AS RegTypeX
	DIM DTAfile AS DTAtype
	DIM ASCIIZ AS STRING * 260
	DIM Current.DTA.SEG AS INTEGER, Current.DTA.OFF AS INTEGER
	DIM CurrentPath AS STRING, Filename AS STRING
	
	'Save current dir, and switch to target dir
	CurrentPath$ = CURDIR$
	CHDIR Path$
	
	ASCIIZ = UCASE$(FilePattern$) + CHR$(0)

	'Clear current shared variables
	FolderCount = 0: FileCount = 0
	REDIM SubFolders(1 TO 1) AS STRING
	REDIM SubFiles(1 TO 1) AS STRING

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

	DO

		IF (OutRegsX.flags AND &H1) = &H0 THEN

			'Result found, isolate filename
			Filename = LEFT$(DTAfile.ASCIIZfilename, INSTR(DTAfile.ASCIIZfilename, CHR$(0)) - 1)

			IF (ASC(DTAfile.FileBits) AND &H10) = &H10 THEN

				'Directory bit was set, add to SubFolder array if it's a real folder
				IF (NOT Filename = ".") AND (NOT Filename = "..") THEN
					FolderCount = FolderCount + 1
					REDIM PRESERVE SubFolders(1 TO FolderCount) AS STRING
					SubFolders(FolderCount) = Filename
				END IF

			ELSE

				'We're dealing with a file, add to SubFile array
				FileCount = FileCount + 1
				REDIM PRESERVE SubFiles(1 TO FileCount) AS STRING
				SubFiles(FileCount) = Filename

			END IF

			'Find next match
			InRegsX.ax = &H4F00
			CALL INTERRUPTX(&H21, InRegsX, OutRegsX)

		ELSE

			'No more results found
			EXIT DO

		END IF

	LOOP

	'Restore previous DTA
	InRegsX.ax = &H1A00
	InRegsX.ds = Current.DTA.SEG
	InRegsX.dx = Current.DTA.OFF
	CALL INTERRUPTX(&H21, InRegsX, OutRegsX)

	'Return to previous directory
	CHDIR CurrentPath$

END SUB

DEFINT A-Z
FUNCTION File.Select (DefaultPattern AS STRING) AS STRING

	DIM winFileSelect AS WindowType
	DIM txtFilelist AS TextboxType, txtFolderlist AS TextboxType
	DIM txtDrive AS TextboxType, txtFilename AS TextboxType
	DIM btnSelect AS ButtonType, btnCancel AS ButtonType

	DIM Path AS STRING, Pattern AS STRING
	DIM Key$

	'Start out with contents of current directory
	Path = CURDIR$
	Pattern = DefaultPattern
	
	Obj.SetSize winFileSelect.Pos, 25, 25, 500, 300
	winFileSelect.Caption = "Select File"

	Obj.SetSize txtFilename.Pos, winFileSelect.Pos.Left + 15, winFileSelect.Pos.Top + 47, 150, -1
	Obj.SetSize txtDrive.Pos, winFileSelect.Pos.Left + 170, winFileSelect.Pos.Top + 47, 150, -1
	Obj.SetSize txtFilelist.Pos, winFileSelect.Pos.Left + 15, winFileSelect.Pos.Top + 90, 150, 180
	Obj.SetSize txtFolderlist.Pos, winFileSelect.Pos.Left + 170, winFileSelect.Pos.Top + 90, 150, 180
	Obj.SetSize btnSelect.Pos, winFileSelect.Pos.Left + 330, winFileSelect.Pos.Top + 47, -1, -1
	Obj.SetSize btnCancel.Pos, winFileSelect.Pos.Left + 330, winFileSelect.Pos.Top + 77, -1, -1

	btnSelect.Caption = "Select"
	btnSelect.HotKey = 1
	btnCancel.Caption = "Cancel"
	btnCancel.HotKey = 1

	Obj.DrawWin winFileSelect
	Obj.DrawTxt txtFilename, Pattern, False
	Obj.DrawTxt txtDrive, "C", False
	Obj.DrawTxt txtFilelist, "WWWWWWWW.WWW", False
	Obj.DrawTxt txtFolderlist, "WWWWWWWW.WWW", False
	Obj.DrawBtn btnSelect, False
	Obj.DrawBtn btnCancel, False
	Font.Print "Filter:", winFileSelect.Pos.Left + 15, winFileSelect.Pos.Top + 33, SystemTheme.WindowText, fontNormal
	Font.Print "Drive:", winFileSelect.Pos.Left + 170, winFileSelect.Pos.Top + 33, SystemTheme.WindowText, fontNormal
	Font.Print "Files:", winFileSelect.Pos.Left + 15, winFileSelect.Pos.Top + 76, SystemTheme.WindowText, fontNormal
	Font.Print "Folders:", winFileSelect.Pos.Left + 170, winFileSelect.Pos.Top + 76, SystemTheme.WindowText, fontNormal
	

	File.GetChildren CURDIR$, Pattern

	DO
		Key$ = INKEY$

		IF Obj.BtnClick(btnCancel) OR Key$ = "C" THEN EXIT FUNCTION

	LOOP

	'SubFolders array contains subfolder names, SubFiles array contains files
	'Count of each type is stored in FolderCount and FileCount, respectively
	
END FUNCTION

