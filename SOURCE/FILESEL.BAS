DECLARE SUB File.GetChildFolders (Path$)
DECLARE SUB File.GetChildFiles (Path$, FilePattern$)
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
SUB File.GetChildFiles (Path$, FilePattern$)

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
	FileCount = 0
	REDIM SubFiles(0 TO 0) AS STRING

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

			IF NOT (ASC(DTAfile.FileBits) AND &H10) = &H10 THEN

				'Folder bit not set.
				'We're dealing with a file, add to SubFile array
				FileCount = FileCount + 1
				REDIM PRESERVE SubFiles(0 TO FileCount - 1) AS STRING
				SubFiles(FileCount - 1) = Filename

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
SUB File.GetChildFolders (Path$)
	DIM InRegsX AS RegTypeX, OutRegsX AS RegTypeX
	DIM DTAfile AS DTAtype
	DIM ASCIIZ AS STRING * 260
	DIM Current.DTA.SEG AS INTEGER, Current.DTA.OFF AS INTEGER
	DIM CurrentPath AS STRING, Filename AS STRING

	'Save current dir, and switch to target dir
	CurrentPath$ = CURDIR$
	CHDIR Path$

	ASCIIZ = "*.*" + CHR$(0)

	'Clear current shared variables
	FolderCount = 0
	REDIM SubFolders(0 TO 0) AS STRING
	
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

	'If we're not at the root, add a '..' indicator as the first entry in
	'the folder list
	IF LEN(Path$) > 3 THEN
		FolderCount = 1
		SubFolders(0) = ".."
	END IF

	DO

		IF (OutRegsX.flags AND &H1) = &H0 THEN

			'Result found, isolate filename
			Filename = LEFT$(DTAfile.ASCIIZfilename, INSTR(DTAfile.ASCIIZfilename, CHR$(0)) - 1)

			IF (ASC(DTAfile.FileBits) AND &H10) = &H10 THEN

				'Directory bit was set, add to SubFolder array if it's a real folder
				IF (NOT Filename = ".") AND (NOT Filename = "..") THEN
					FolderCount = FolderCount + 1
					REDIM PRESERVE SubFolders(0 TO FolderCount - 1) AS STRING
					SubFolders(FolderCount - 1) = Filename
				END IF

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

FUNCTION File.Select (DefaultPattern AS STRING) AS STRING

	DIM winFileSelect AS WindowType
	DIM txtFileList AS TextboxType, txtFolderList AS TextboxType
	DIM txtDrive AS TextboxType, txtPattern AS TextboxType
	DIM btnSelect AS ButtonType, btnCancel AS ButtonType
	DIM txtPatternText AS STRING, txtDriveText AS STRING

	DIM Path AS STRING, Pattern AS STRING, Drive AS STRING
	DIM Key$
	DIM MaxVisibleItems, FileListStartPos, FolderListStartPos
	DIM FileListSelection, FolderListSelection, Counter, I

	'Start out with contents of current directory
	Path = CURDIR$
	Drive = LEFT$(Path, 1)
	Pattern = DefaultPattern
	txtDriveText = Drive
	txtPatternText = DefaultPattern
	
	Obj.SetSize winFileSelect.Pos, 25, 25, 436, 285
	winFileSelect.Pos.Width = 436
	winFileSelect.Pos.Height = 285
	winFileSelect.Pos.Left = (640 - winFileSelect.Pos.Width) / 2
	winFileSelect.Pos.Top = (scrHeight - winFileSelect.Pos.Height) / 2
	winFileSelect.Caption = "Select File"

	Obj.SetSize txtPattern.Pos, winFileSelect.Pos.Left + 15, winFileSelect.Pos.Top + 47, 150, -1
	Obj.SetSize txtDrive.Pos, winFileSelect.Pos.Left + 170, winFileSelect.Pos.Top + 47, 150, -1
	Obj.SetSize txtFileList.Pos, winFileSelect.Pos.Left + 15, winFileSelect.Pos.Top + 90, 150, 180
	Obj.SetSize txtFolderList.Pos, winFileSelect.Pos.Left + 170, winFileSelect.Pos.Top + 90, 150, txtFileList.Pos.Height
	Obj.SetSize btnSelect.Pos, winFileSelect.Pos.Left + 330, winFileSelect.Pos.Top + 47, -1, -1
	Obj.SetSize btnCancel.Pos, winFileSelect.Pos.Left + 330, winFileSelect.Pos.Top + 77, -1, -1

	btnSelect.Caption = "Select"
	btnSelect.HotKey = 1
	btnCancel.Caption = "Cancel"
	btnCancel.HotKey = 1

	Obj.DrawWin winFileSelect
	Obj.DrawTxt txtPattern, txtPatternText, False
	Obj.DrawTxt txtDrive, txtDriveText, False
	Obj.DrawBtn btnSelect, False
	Obj.DrawBtn btnCancel, False
	Font.Print "Pattern:", winFileSelect.Pos.Left + 15, winFileSelect.Pos.Top + 33, SystemTheme.WindowText, fontNormal
	Font.Print "Drive:", winFileSelect.Pos.Left + 170, winFileSelect.Pos.Top + 33, SystemTheme.WindowText, fontNormal
	Font.Print "Files:", winFileSelect.Pos.Left + 15, winFileSelect.Pos.Top + 76, SystemTheme.WindowText, fontNormal
	Font.Print "Folders:", winFileSelect.Pos.Left + 170, winFileSelect.Pos.Top + 76, SystemTheme.WindowText, fontNormal
	Mouse.Hide
	LINE (winFileSelect.Pos.Left + 14, winFileSelect.Pos.Top + 43)-(winFileSelect.Pos.Left + 20, winFileSelect.Pos.Top + 43), SystemTheme.WindowText
	LINE (winFileSelect.Pos.Left + 169, winFileSelect.Pos.Top + 43)-(winFileSelect.Pos.Left + 175, winFileSelect.Pos.Top + 43), SystemTheme.WindowText
	LINE (winFileSelect.Pos.Left + 14, winFileSelect.Pos.Top + 86)-(winFileSelect.Pos.Left + 20, winFileSelect.Pos.Top + 86), SystemTheme.WindowText
	LINE (winFileSelect.Pos.Left + 176, winFileSelect.Pos.Top + 86)-(winFileSelect.Pos.Left + 182, winFileSelect.Pos.Top + 86), SystemTheme.WindowText
	Mouse.Show
	
	File.GetChildFiles Path, Pattern
	File.GetChildFolders Path

	MaxVisibleItems = (txtFileList.Pos.Height - 24) / 12

	GOSUB DrawFileList
	GOSUB DrawFolderList

	DO
		Key$ = LCASE$(INKEY$)

		IF Obj.BtnClick(btnSelect) OR Key$ = "s" THEN
			'DEBUG - return a filename
			EXIT FUNCTION
		END IF

		IF Obj.BtnClick(btnCancel) OR Key$ = "c" OR Key$ = CHR$(27) THEN
			File.Select = ""
			EXIT FUNCTION
		END IF

		IF Key$ = "f" THEN
			FileListSelection = FileListSelection + 1
			IF FileListSelection > UBOUND(SubFiles) THEN
				FileListSelection = 0
				FileListStartPos = 0
			END IF
			IF FileListSelection > FileListStartPos + MaxVisibleItems THEN
				FileListStartPos = FileListSelection
			END IF
			GOSUB DrawFileList
		END IF

		IF Key$ = "o" THEN
			FolderListSelection = FolderListSelection + 1
			IF FolderListSelection > UBOUND(SubFolders) THEN
				FolderListSelection = 0
				FolderListStartPos = 0
			END IF
			IF FolderListSelection > FolderListStartPos + MaxVisibleItems THEN
				FolderListStartPos = FolderListSelection
			END IF
			GOSUB DrawFolderList
		END IF

		IF Obj.TxtClick(txtPattern) OR Key$ = "p" THEN
			Obj.EditTxt txtPattern, txtPatternText
			txtPatternText = LTRIM$(RTRIM$(txtPatternText))
			IF LEN(txtPatternText) > 12 THEN txtPatternText = LEFT$(txtPatternText, 12)

			IF NOT txtPatternText = Pattern THEN
				'Validate input

				Pattern = RTRIM$(txtPatternText)
				PRINT "Changed"
				File.GetChildFiles Path, Pattern
				GOSUB DrawFileList
			END IF
		END IF


		IF Obj.TxtClick(txtDrive) OR Key$ = "d" THEN
			Obj.EditTxt txtDrive, txtDriveText

			IF NOT txtDriveText = Drive THEN
				'Change drive. Validate drive beforehand.
				'Go to root of drive.
				'Reload files and folders.
			END IF

		END IF



	LOOP

	EXIT FUNCTION

DrawFileList:
		Obj.DrawTxt txtFileList, "", False
		Counter = 0
		FOR I = FileListStartPos TO FileListStartPos + MaxVisibleItems
			IF I <= UBOUND(SubFiles) THEN

				IF I = FileListSelection THEN
					Mouse.Hide
					LINE (txtFileList.Pos.Left + 2, txtFileList.Pos.Top + 3 + (Counter * 12))-(txtFileList.Pos.Left + txtFileList.Pos.Width - 2, txtFileList.Pos.Top + 15 + (Counter * 12)), SystemTheme.Select, BF
					Mouse.Show
					Font.Print SubFiles(I), txtFileList.Pos.Left + 5, txtFileList.Pos.Top + 5 + (Counter * 12), SystemTheme.SelectText, fontSystem
				ELSE
					Font.Print SubFiles(I), txtFileList.Pos.Left + 5, txtFileList.Pos.Top + 5 + (Counter * 12), SystemTheme.TextboxText, fontSystem
				END IF

				Counter = Counter + 1
			END IF
		NEXT
	RETURN

DrawFolderList:
		Obj.DrawTxt txtFolderList, "", False
		Counter = 0
		FOR I = FolderListStartPos TO FolderListStartPos + MaxVisibleItems
			IF I <= UBOUND(SubFolders) THEN

				IF I = FolderListSelection THEN
					Mouse.Hide
					LINE (txtFolderList.Pos.Left + 2, txtFolderList.Pos.Top + 3 + (Counter * 12))-(txtFolderList.Pos.Left + txtFolderList.Pos.Width - 2, txtFolderList.Pos.Top + 15 + (Counter * 12)), SystemTheme.Select, BF
					Mouse.Show
					Font.Print SubFolders(I), txtFolderList.Pos.Left + 5, txtFolderList.Pos.Top + 5 + (Counter * 12), SystemTheme.SelectText, fontSystem
				ELSE
					Font.Print SubFolders(I), txtFolderList.Pos.Left + 5, txtFolderList.Pos.Top + 5 + (Counter * 12), SystemTheme.TextboxText, fontSystem
				END IF

				Counter = Counter + 1
			END IF
		NEXT
	RETURN

END FUNCTION

