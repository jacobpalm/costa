DEFINT A-Z
OPTION EXPLICIT

DECLARE FUNCTION File.SetDrive% (Drive AS STRING)
DECLARE SUB File.GetChildFiles (Path$, FilePattern$)
DECLARE SUB File.GetChildFolders (Path$)

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
	DIM btnFilePrev AS ButtonType, btnFileNext AS ButtonType
	DIM btnFolderPrev AS ButtonType, btnFolderNext AS ButtonType

	DIM Path AS STRING, Pattern AS STRING, Drive AS STRING
	DIM OriginalPath AS STRING
	DIM Key$
	DIM MaxVisibleItems, FileListStartPos, FolderListStartPos
	DIM FileListSelection, FolderListSelection, Counter, I
	DIM ClickedX, ClickedY, ClickedItem, RedrawNeeded
	DIM ClickedDoubleTimer AS SINGLE

	DIM ActiveList
	CONST FileList = 0
	CONST FolderList = 1

	'Start out with contents of current directory
	OriginalPath = CURDIR$
	Path = OriginalPath
	Drive = LEFT$(Path, 1)
	Pattern = DefaultPattern
	txtDriveText = Drive
	txtPatternText = DefaultPattern
	
	winFileSelect.Pos.Width = 468
	winFileSelect.Pos.Height = 285
	winFileSelect.Pos.Left = (640 - winFileSelect.Pos.Width) / 2
	winFileSelect.Pos.Top = (scrHeight - winFileSelect.Pos.Height) / 2
	winFileSelect.Caption = "Select File"

	Obj.SetSize txtPattern.Pos, winFileSelect.Pos.Left + 15, winFileSelect.Pos.Top + 47, 150, -1
	Obj.SetSize txtDrive.Pos, winFileSelect.Pos.Left + 186, winFileSelect.Pos.Top + 47, 150, -1
	Obj.SetSize txtFileList.Pos, winFileSelect.Pos.Left + 15, winFileSelect.Pos.Top + 90, 150, 180
	Obj.SetSize txtFolderList.Pos, winFileSelect.Pos.Left + 186, winFileSelect.Pos.Top + 90, 150, txtFileList.Pos.Height
	Obj.SetSize btnSelect.Pos, winFileSelect.Pos.Left + 362, winFileSelect.Pos.Top + 47, -1, -1
	Obj.SetSize btnCancel.Pos, winFileSelect.Pos.Left + 362, winFileSelect.Pos.Top + 77, -1, -1

	Obj.SetSize btnFilePrev.Pos, txtFileList.Pos.Left + txtFileList.Pos.Width + 2, txtFileList.Pos.Top, 14, (txtFileList.Pos.Height / 2) - 1
	Obj.SetSize btnFileNext.Pos, txtFileList.Pos.Left + txtFileList.Pos.Width + 2, txtFileList.Pos.Top + (txtFileList.Pos.Height / 2) + 1, 14, (txtFileList.Pos.Height / 2) - 1
	Obj.SetSize btnFolderPrev.Pos, txtFolderList.Pos.Left + txtFolderList.Pos.Width + 2, txtFolderList.Pos.Top, 14, (txtFolderList.Pos.Height / 2) - 1
	Obj.SetSize btnFolderNext.Pos, txtFolderList.Pos.Left + txtFolderList.Pos.Width + 2, txtFolderList.Pos.Top + (txtFolderList.Pos.Height / 2) + 1, 14, (txtFolderList.Pos.Height / 2) - 1
	
	btnSelect.Caption = "Select"
	btnSelect.HotKey = 1
	btnCancel.Caption = "Cancel"
	btnCancel.HotKey = 1
	btnFilePrev.Caption = "<"
	btnFileNext.Caption = ">"
	btnFolderPrev.Caption = "<"
	btnFolderNext.Caption = ">"

	Obj.DrawWin winFileSelect
	Obj.DrawTxt txtPattern, txtPatternText, False
	Obj.DrawTxt txtDrive, txtDriveText, False
	Obj.DrawBtn btnSelect, False
	Obj.DrawBtn btnCancel, False
	Obj.DrawBtn btnFilePrev, False
	Obj.DrawBtn btnFileNext, False
	Obj.DrawBtn btnFolderPrev, False
	Obj.DrawBtn btnFolderNext, False
	Font.Print "Pattern:", winFileSelect.Pos.Left + 15, winFileSelect.Pos.Top + 33, SystemTheme.WindowText, FontNormal
	Font.Print "Drive:", winFileSelect.Pos.Left + 186, winFileSelect.Pos.Top + 33, SystemTheme.WindowText, FontNormal
	Font.Print "Files:", winFileSelect.Pos.Left + 15, winFileSelect.Pos.Top + 76, SystemTheme.WindowText, FontNormal
	Font.Print "Folders:", winFileSelect.Pos.Left + 186, winFileSelect.Pos.Top + 76, SystemTheme.WindowText, FontNormal
	Mouse.Hide
	LINE (winFileSelect.Pos.Left + 14, winFileSelect.Pos.Top + 43)-(winFileSelect.Pos.Left + 20, winFileSelect.Pos.Top + 43), SystemTheme.WindowText
	LINE (winFileSelect.Pos.Left + 185, winFileSelect.Pos.Top + 43)-(winFileSelect.Pos.Left + 191, winFileSelect.Pos.Top + 43), SystemTheme.WindowText
	LINE (winFileSelect.Pos.Left + 14, winFileSelect.Pos.Top + 86)-(winFileSelect.Pos.Left + 20, winFileSelect.Pos.Top + 86), SystemTheme.WindowText
	LINE (winFileSelect.Pos.Left + 192, winFileSelect.Pos.Top + 86)-(winFileSelect.Pos.Left + 198, winFileSelect.Pos.Top + 86), SystemTheme.WindowText
	Mouse.Show
	
	MaxVisibleItems = (txtFileList.Pos.Height - 24) / 12

	File.GetChildFiles Path, Pattern
	File.GetChildFolders Path
	GOSUB DrawFileList
	GOSUB DrawFolderList

	DO
		Key$ = LCASE$(INKEY$)

		IF Mouse.Clicked AND Mouse.InArea(txtFileList.Pos) THEN
			RedrawNeeded = False
			ClickedX = Mouse.X - txtFileList.Pos.Left
			ClickedY = Mouse.Y - txtFileList.Pos.Top
			'Validate click inside, not on border
			IF ClickedX > 1 AND ClickedX < txtFileList.Pos.Width - 2 THEN
				IF ClickedY > 2 AND ClickedY < txtFileList.Pos.Height - 1 THEN
					ClickedItem = -1
					ClickedItem = ((ClickedY + 4) / 12) - 1
					IF ClickedItem > MaxVisibleItems THEN ClickedItem = -1
					IF NOT ClickedItem + FileListStartPos > UBOUND(SubFiles) THEN
						IF ClickedItem + FileListStartPos = FileListSelection THEN
							'Already selected and clicked again, simulate "Enter" key
							IF TIMER < ClickedDoubleTimer + .3 THEN Key$ = CHR$(13)
						ELSE
							RedrawNeeded = True
							FileListSelection = ClickedItem + FileListStartPos
						END IF
					END IF
				END IF
			END IF

			IF NOT ActiveList = FileList THEN
				RedrawNeeded = True
				ActiveList = FileList
				GOSUB DrawFolderList
			END IF
			IF RedrawNeeded THEN GOSUB DrawFileList
			ClickedDoubleTimer = TIMER
			DO: LOOP WHILE Mouse.Clicked
		END IF

		IF Mouse.Clicked AND Mouse.InArea(txtFolderList.Pos) THEN
			RedrawNeeded = False
			ClickedX = Mouse.X - txtFolderList.Pos.Left
			ClickedY = Mouse.Y - txtFolderList.Pos.Top
			'Validate click inside, not on border
			IF ClickedX > 1 AND ClickedX < txtFolderList.Pos.Width - 2 THEN
				IF ClickedY > 2 AND ClickedY < txtFolderList.Pos.Height - 1 THEN
					ClickedItem = -1
					ClickedItem = ((ClickedY + 4) / 12) - 1
					IF ClickedItem > MaxVisibleItems THEN ClickedItem = -1

					IF NOT ClickedItem + FolderListStartPos > UBOUND(SubFolders) THEN
						IF ClickedItem + FolderListStartPos = FolderListSelection THEN
							'Already selected and clicked again, simulate "Enter" key
							IF TIMER < ClickedDoubleTimer + .3 THEN Key$ = CHR$(13)
						ELSE
							RedrawNeeded = True
							FolderListSelection = ClickedItem + FolderListStartPos
						END IF
					END IF
				END IF
			END IF

			IF NOT ActiveList = FolderList THEN
				RedrawNeeded = True
				ActiveList = FolderList
				GOSUB DrawFileList
			END IF
			IF RedrawNeeded THEN GOSUB DrawFolderList
			ClickedDoubleTimer = TIMER
			DO: LOOP WHILE Mouse.Clicked
		END IF


		IF Key$ = CHR$(13) THEN
			'Enter-key pressed

			IF ActiveList = FileList THEN
				'Simulate click of "Select" button if the file list is active
				Key$ = "s"
			ELSE
				'Navigate to the selected folder, if any
				IF FolderCount > 0 THEN
					CHDIR SubFolders(FolderListSelection)
					Path = CURDIR$
					File.GetChildFiles Path, Pattern
					File.GetChildFolders Path
					FileListSelection = 0
					FolderListSelection = 0
					GOSUB DrawFileList
					GOSUB DrawFolderList
				END IF
			END IF
		END IF

		IF Obj.BtnClick(btnSelect) OR Key$ = "s" THEN
			IF FileCount > 0 THEN
				'Only append backslash to path if not at root level
				IF NOT RIGHT$(CURDIR$, 1) = "\" THEN
					File.Select = CURDIR$ + "\" + SubFiles(FileListSelection)
				ELSE
					File.Select = CURDIR$ + SubFiles(FileListSelection)
				END IF
				CHDRIVE LEFT$(OriginalPath, 1)
				CHDIR OriginalPath
				REDIM FileList(0 TO 0)
				REDIM FolderList(0 TO 0)
				EXIT FUNCTION
			END IF
		END IF

		IF Obj.BtnClick(btnCancel) OR Key$ = "c" OR Key$ = CHR$(27) THEN
			File.Select = ""
			CHDRIVE LEFT$(OriginalPath, 1)
			CHDIR OriginalPath
			REDIM FileList(0 TO 0)
			REDIM FolderList(0 TO 0)
			EXIT FUNCTION
		END IF

		IF Key$ = "f" THEN
			IF NOT ActiveList = FileList THEN
				ActiveList = FileList
				GOSUB DrawFolderList
				GOSUB DrawFileList
			END IF
		END IF

		IF Key$ = "o" THEN
			IF NOT ActiveList = FolderList THEN
				ActiveList = FolderList
				GOSUB DrawFileList
				GOSUB DrawFolderList
			END IF
		END IF

		IF Obj.BtnClick(btnFilePrev) THEN
			IF NOT ActiveList = FileList THEN
				ActiveList = FileList
				GOSUB DrawFolderList
			END IF
			Key$ = CHR$(0) + "h" 'Simulate up arrow key
		END IF

		IF Obj.BtnClick(btnFileNext) THEN
			IF NOT ActiveList = FileList THEN
				ActiveList = FileList
				GOSUB DrawFolderList
			END IF
			Key$ = CHR$(0) + "p" 'Simulate up arrow key
		END IF

		IF Obj.BtnClick(btnFolderPrev) THEN
			IF NOT ActiveList = FolderList THEN
				ActiveList = FolderList
				GOSUB DrawFileList
			END IF
			Key$ = CHR$(0) + "h" 'Simulate up arrow key
		END IF

		IF Obj.BtnClick(btnFolderNext) THEN
			IF NOT ActiveList = FolderList THEN
				ActiveList = FolderList
				GOSUB DrawFileList
			END IF
			Key$ = CHR$(0) + "p" 'Simulate up arrow key
		END IF



		IF Key$ = CHR$(0) + "h" OR Key$ = CHR$(0) + "k" THEN
			'Up or left arrow key
			IF ActiveList = FileList THEN
				FileListSelection = FileListSelection - 1
				IF FileListSelection < 0 THEN
					FileListSelection = UBOUND(SubFiles)
					FileListStartPos = UBOUND(SubFiles) - MaxVisibleItems
				END IF
				IF FileListSelection < FileListStartPos THEN
					FileListStartPos = FileListSelection - MaxVisibleItems
				END IF
				IF FileListStartPos < 0 THEN FileListStartPos = 0
				GOSUB DrawFileList
			ELSE
				FolderListSelection = FolderListSelection - 1
				IF FolderListSelection < 0 THEN
					FolderListSelection = UBOUND(SubFolders)
					FolderListStartPos = UBOUND(SubFolders) - MaxVisibleItems
				END IF
				IF FolderListSelection < FolderListStartPos THEN
					FolderListStartPos = FolderListSelection - MaxVisibleItems
				END IF
				IF FolderListStartPos < 0 THEN FolderListStartPos = 0
				GOSUB DrawFolderList
			END IF

		END IF

		IF Key$ = CHR$(0) + "p" OR Key$ = CHR$(0) + "m" THEN
			'Down or right arrow key
			IF ActiveList = FileList THEN
				FileListSelection = FileListSelection + 1
				IF FileListSelection > UBOUND(SubFiles) THEN
					FileListSelection = 0
					FileListStartPos = 0
				END IF
				IF FileListSelection > FileListStartPos + MaxVisibleItems THEN
					FileListStartPos = FileListSelection
				END IF
				GOSUB DrawFileList
			ELSE
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
		END IF

		IF Obj.TxtClick(txtPattern) OR Key$ = "p" THEN
			Obj.EditTxt txtPattern, txtPatternText
			IF NOT txtPatternText = UCASE$(LTRIM$(RTRIM$(txtPatternText))) THEN
				txtPatternText = UCASE$(LTRIM$(RTRIM$(txtPatternText)))
				Obj.DrawTxt txtPattern, txtPatternText, False
			END IF

			'Input validation
			IF LEN(txtPatternText) > 12 THEN
				txtPatternText = LEFT$(txtPatternText, 12)
				Obj.DrawTxt txtPattern, txtPatternText, False
			END IF

			IF NOT txtPatternText = Pattern THEN
				'Validate input
				Pattern = RTRIM$(txtPatternText)
				File.GetChildFiles Path, Pattern
				GOSUB DrawFileList
			END IF
		END IF

		IF Obj.TxtClick(txtDrive) OR Key$ = "d" THEN
			Obj.EditTxt txtDrive, txtDriveText

			IF NOT txtDriveText = UCASE$(LTRIM$(RTRIM$(txtDriveText))) THEN
				txtDriveText = UCASE$(LTRIM$(RTRIM$(txtDriveText)))
				Obj.DrawTxt txtDrive, txtDriveText, False
			END IF
			
			IF txtDriveText = "" THEN txtDriveText = Drive

			IF NOT txtDriveText = Drive THEN
				'Input validation
				IF LEN(txtDriveText) > 1 THEN
					txtDriveText = LEFT$(txtDriveText, 1)
					Obj.DrawTxt txtDrive, txtDriveText, False
				END IF
				
				IF File.SetDrive(txtDriveText) THEN
					Path = CURDIR$
					Drive = LEFT$(Path, 1)
					File.GetChildFiles Path, Pattern
					File.GetChildFolders Path
					FileListSelection = 0
					FolderListSelection = 0
					GOSUB DrawFileList
					GOSUB DrawFolderList
				ELSE
					txtDriveText = Drive
					Obj.DrawTxt txtDrive, txtDriveText, False
				END IF
			END IF
		END IF
						
	LOOP

	EXIT FUNCTION

DrawFileList:
		Obj.DrawTxt txtFileList, "", False
		IF FileCount > 0 THEN
			Counter = 0
			FOR I = FileListStartPos TO FileListStartPos + MaxVisibleItems
				IF I <= UBOUND(SubFiles) THEN

					IF I = FileListSelection AND ActiveList = FileList THEN
						Mouse.Hide
						LINE (txtFileList.Pos.Left + 2, txtFileList.Pos.Top + 3 + (Counter * 12))-(txtFileList.Pos.Left + txtFileList.Pos.Width - 2, txtFileList.Pos.Top + 15 + (Counter * 12)), SystemTheme.Select, BF
						Mouse.Show
						Font.Print SubFiles(I), txtFileList.Pos.Left + 5, txtFileList.Pos.Top + 5 + (Counter * 12), SystemTheme.SelectText, FontSystem
					ELSE
						Font.Print SubFiles(I), txtFileList.Pos.Left + 5, txtFileList.Pos.Top + 5 + (Counter * 12), SystemTheme.TextboxText, FontSystem
					END IF

					Counter = Counter + 1
				END IF
			NEXT
		END IF
	RETURN

DrawFolderList:
		Obj.DrawTxt txtFolderList, "", False
		IF FolderCount > 0 THEN
			Counter = 0
			FOR I = FolderListStartPos TO FolderListStartPos + MaxVisibleItems
				IF I <= UBOUND(SubFolders) THEN

					IF I = FolderListSelection AND ActiveList = FolderList THEN
						Mouse.Hide
						LINE (txtFolderList.Pos.Left + 2, txtFolderList.Pos.Top + 3 + (Counter * 12))-(txtFolderList.Pos.Left + txtFolderList.Pos.Width - 2, txtFolderList.Pos.Top + 15 + (Counter * 12)), SystemTheme.Select, BF
						Mouse.Show
						Font.Print SubFolders(I), txtFolderList.Pos.Left + 5, txtFolderList.Pos.Top + 5 + (Counter * 12), SystemTheme.SelectText, FontSystem
					ELSE
						Font.Print SubFolders(I), txtFolderList.Pos.Left + 5, txtFolderList.Pos.Top + 5 + (Counter * 12), SystemTheme.TextboxText, FontSystem
					END IF

					Counter = Counter + 1
				END IF
			NEXT
		END IF
	RETURN

END FUNCTION

FUNCTION File.SetDrive (Drive AS STRING)

	DIM CurrentDrive AS STRING * 1
	CurrentDrive = LEFT$(CURDIR$, 1)

	ON LOCAL ERROR GOTO DriveError
	CHDRIVE Drive
	CHDIR "\"
	File.SetDrive = True

	EXIT FUNCTION

DriveError:
	CHDRIVE CurrentDrive
	DIM Null
	Null = Sys.MsgBox("Drive not ready", "The drive " + Drive + ": was not ready, or does not exist." + CHR$(13) + "Verify and try again.", msgError)
	File.SetDrive = False
	EXIT FUNCTION
	RESUME

END FUNCTION

