DEFINT A-Z
OPTION EXPLICIT

DECLARE FUNCTION File.MouseSelection% (TargetList AS ANY)
DECLARE FUNCTION File.SetDrive% (Drive AS STRING)
DECLARE SUB File.DrawList (TargetList AS ANY, HighLightActive%, FullRedraw%)
DECLARE SUB File.GetChildFiles (Path$, FilePattern$)
DECLARE SUB File.GetChildFolders (Path$)
DECLARE SUB File.MoveSelection (TargetList AS ANY, Direction%)
DECLARE SUB File.SetFolder (BYVAL TargetPath AS STRING)

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

CONST FileList = 0
CONST FolderList = 1

'Used for moving selection - added to current selection, -1 makes selection go up
CONST DirectionUp = -1
CONST DirectionDown = 1

DIM SHARED txtFileList AS TextboxType, txtFolderList AS TextboxType
DIM SHARED ClickedDoubleTimer AS SINGLE

DIM SHARED FolderCount AS INTEGER, FileCount AS INTEGER
DIM SHARED SubFolders() AS STRING
DIM SHARED SubFiles() AS STRING

DIM SHARED MaxVisibleItems, FileListStartPos, FolderListStartPos
DIM SHARED FileListSelection, FolderListSelection, ActiveList

DIM SHARED Path AS STRING, Pattern AS STRING

' =========================================================================
'          NAME: File.DrawList
'    PARAMETERS: TargetList      - a textbox object to redraw
'                HighLightActive - bool, higlight active item or not
'                FullRedraw      - bool, redraw entire list
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: FILESEL.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Used internally in File.Select to redraw file/folder list
'                as needed
' =========================================================================
SUB File.DrawList (TargetList AS TextboxType, HighLightActive, FullRedraw)

	DIM I, Counter, TotalItems, ListStartPos, ListSelection, FGColor, BGColor
	DIM ItemText AS STRING

	IF TargetList.MaxLen = FileList THEN
		TotalItems = FileCount - 1
		ListStartPos = FileListStartPos
		ListSelection = FileListSelection
	ELSE
		TotalItems = FolderCount - 1
		ListStartPos = FolderListStartPos
		ListSelection = FolderListSelection
	END IF

	IF FullRedraw = True THEN

		'Full redraw, draw list first and then all visible items within
		Obj.DrawTxt TargetList, "", False

		Counter = 0
		FOR I = ListStartPos TO ListStartPos + MaxVisibleItems
			IF I <= TotalItems THEN
				IF TargetList.MaxLen = FileList THEN
					ItemText = SubFiles(I)
				ELSE
					ItemText = SubFolders(I)
				END IF

				'Highlight active selected item, if encountered
				IF I = ListSelection AND ActiveList = TargetList.MaxLen THEN
					Mouse.Hide
					LINE (TargetList.Pos.Left + 2, TargetList.Pos.Top + 3 + (Counter * 12))-(TargetList.Pos.Left + TargetList.Pos.Width - 2, TargetList.Pos.Top + 15 + (Counter * 12)), SystemTheme.Select, BF
					Mouse.Show
					Font.Print ItemText, TargetList.Pos.Left + 5, TargetList.Pos.Top + 5 + (Counter * 12), SystemTheme.SelectText, FontSystem
				ELSE
					Font.Print ItemText, TargetList.Pos.Left + 5, TargetList.Pos.Top + 5 + (Counter * 12), SystemTheme.TextboxText, FontSystem
				END IF

				Counter = Counter + 1
			END IF
		NEXT
																 
	ELSE

		'Not a full redraw, only draw the selected item

		IF HighLightActive AND ActiveList = TargetList.MaxLen THEN
			FGColor = SystemTheme.SelectText
			BGColor = SystemTheme.Select
		ELSE
			FGColor = SystemTheme.TextboxText
			BGColor = SystemTheme.Textbox
		END IF

		IF TargetList.MaxLen = FileList THEN
			ItemText = SubFiles(ListSelection)
		ELSE
			ItemText = SubFolders(ListSelection)
		END IF
		I = ListSelection - ListStartPos

		IF NOT ItemText = "" THEN
			Mouse.Hide
			LINE (TargetList.Pos.Left + 2, TargetList.Pos.Top + 3 + (I * 12))-(TargetList.Pos.Left + TargetList.Pos.Width - 2, TargetList.Pos.Top + 15 + (I * 12)), BGColor, BF
			Mouse.Show
			Font.Print ItemText, TargetList.Pos.Left + 5, TargetList.Pos.Top + 5 + (I * 12), FGColor, FontSystem
		END IF

	END IF

END SUB

DEFSNG A-Z
' =========================================================================
'          NAME: File.GetChildFiles
'    PARAMETERS: Path$        - a valid MS-DOS path
'                FilePattern$ - a valid MS-DOS file pattern (eg, *.txt)
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: FILESEL.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Used internally in File.Select to retrieve a list of all
'                files matching pattern, in a specified folder, from the
'                MS-DOS API
' =========================================================================
SUB File.GetChildFiles (Path$, FilePattern$)

	DIM InRegsX AS RegTypeX, OutRegsX AS RegTypeX
	DIM DTAfile AS DTAtype
	DIM ASCIIZ AS STRING * 260
	DIM Current.DTA.SEG AS INTEGER, Current.DTA.OFF AS INTEGER
	DIM CurrentPath AS STRING, FileName AS STRING
	
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
			FileName = LEFT$(DTAfile.ASCIIZfilename, INSTR(DTAfile.ASCIIZfilename, CHR$(0)) - 1)

			IF NOT (ASC(DTAfile.FileBits) AND &H10) = &H10 THEN

				'Folder bit not set.
				'We're dealing with a file, add to SubFile array
				FileCount = FileCount + 1
				REDIM PRESERVE SubFiles(0 TO FileCount - 1) AS STRING
				SubFiles(FileCount - 1) = FileName

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
' =========================================================================
'          NAME: File.GetChildFolders
'    PARAMETERS: TargetPath$ - a valid MS-DOS path
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: FILESEL.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Used internally in File.Select to retrieve a list of all
'                folders in the given path, from the MS-DOS API
' =========================================================================
SUB File.GetChildFolders (TargetPath$)
	DIM InRegsX AS RegTypeX, OutRegsX AS RegTypeX
	DIM DTAfile AS DTAtype
	DIM ASCIIZ AS STRING * 260
	DIM Current.DTA.SEG AS INTEGER, Current.DTA.OFF AS INTEGER
	DIM CurrentPath AS STRING, FileName AS STRING

	'Save current dir, and switch to target dir
	CurrentPath$ = CURDIR$
	CHDIR TargetPath$

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
	IF LEN(TargetPath$) > 3 THEN
		FolderCount = 1
		SubFolders(0) = ".."
	END IF

	DO
		
		IF (OutRegsX.flags AND &H1) = &H0 THEN

			'Result found, isolate filename
			FileName = LEFT$(DTAfile.ASCIIZfilename, INSTR(DTAfile.ASCIIZfilename, CHR$(0)) - 1)

			IF (ASC(DTAfile.FileBits) AND &H10) = &H10 THEN

				'Directory bit was set, add to SubFolder array if it's a real folder
				IF (NOT FileName = ".") AND (NOT FileName = "..") THEN
					FolderCount = FolderCount + 1
					REDIM PRESERVE SubFolders(0 TO FolderCount - 1) AS STRING
					SubFolders(FolderCount - 1) = FileName
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

' =========================================================================
'          NAME: File.MouseSelection
'    PARAMETERS: TargetList - a textbox object
'       RETURNS: True if an item was double-clicked in the list
'       ASSUMES: Nothing
'   CALLED FROM: FILESEL.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Used internally in File.Select to handle clicking with
'                the mouse in a file list. Gives list focus if it hasn't
'                already got it, highlights clicked item, and checks for
'                double-click.
' =========================================================================
FUNCTION File.MouseSelection (TargetList AS TextboxType)

	DIM ClickedX, ClickedY, ClickedItem
	DIM TotalItems, ListStartPos, ListSelection

	Mouse.Poll
	ClickedX = MouseX - TargetList.Pos.Left
	ClickedY = MouseY - TargetList.Pos.Top

	'Retrieve values to temp variables - so both lists can be handled by same
	'code
	IF TargetList.MaxLen = FileList THEN
		TotalItems = FileCount - 1
		ListStartPos = FileListStartPos
		ListSelection = FileListSelection
	ELSE
		TotalItems = FolderCount - 1
		ListStartPos = FolderListStartPos
		ListSelection = FolderListSelection
	END IF

	'Validate click inside, not on border
	IF ClickedX > 1 AND ClickedX < TargetList.Pos.Width - 2 THEN
		IF ClickedY > 2 AND ClickedY < TargetList.Pos.Height - 1 THEN
			
			'Clicked inside

			IF NOT ActiveList = TargetList.MaxLen THEN
				'Clicked list is not active. Make it so, and remove selection
				'from other list
				IF ActiveList = FileList THEN
					ActiveList = FolderList
					File.DrawList txtFileList, False, False
				ELSE
					ActiveList = FileList
					File.DrawList txtFolderList, False, False
				END IF
			END IF

			'Row height is 12, and there is a 4 pixel border to first item.
			'Calculate clicked item, and substract one to account for lower bound
			'of 0
			ClickedItem = ((ClickedY + 4) / 12) - 1

			IF ClickedItem > MaxVisibleItems THEN
				'Clicked inside list area, but in the small gap after last item.
				'Draw current item with focus
				File.DrawList TargetList, True, False
				DO: LOOP WHILE Mouse.Clicked
				EXIT FUNCTION
			END IF
			
			ClickedItem = ClickedItem + ListStartPos
			IF NOT ClickedItem > TotalItems THEN
				
				IF ClickedItem = ListSelection THEN

					'Already selected and clicked again, check for doubleclick
					IF TIMER < ClickedDoubleTimer + .3 THEN
						File.MouseSelection = True
					ELSE
						File.DrawList TargetList, True, False
					END IF

				ELSE

					'Clicked item is not the current selection, move
					'selection
					File.DrawList TargetList, False, False
					IF TargetList.MaxLen = FileList THEN
						FileListSelection = ClickedItem
					ELSE
						FolderListSelection = ClickedItem
					END IF
					File.DrawList TargetList, True, False

				END IF

			ELSE
				'Clicked in list, but below any items. Give focus to
				'current selection
				File.DrawList TargetList, True, False
			END IF

		END IF
	END IF

	ClickedDoubleTimer = TIMER
	DO: LOOP WHILE Mouse.Clicked

END FUNCTION

' =========================================================================
'          NAME: File.MoveSelection
'    PARAMETERS: TargetList - a textbox object
'                Direction  - const DirectionUp or DirectionDown
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: FILESEL.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Used internally in File.Select to move selection in
'                lists up or down
' =========================================================================
SUB File.MoveSelection (TargetList AS TextboxType, Direction)

	DIM RedrawNeeded
	DIM TotalItems, ListStartPos, ListSelection

	'Retrieve values to temp variables - so both lists can be handled by same
	'code
	IF TargetList.MaxLen = FileList THEN
		TotalItems = FileCount - 1
		ListStartPos = FileListStartPos
		ListSelection = FileListSelection
	ELSE
		TotalItems = FolderCount - 1
		ListStartPos = FolderListStartPos
		ListSelection = FolderListSelection
	END IF
	
	'Move selection - Direction is -1 for up, 1 for down - using constants
	ListSelection = ListSelection + Direction
	
	'Validate if lists need to be scrolled in either direction

	IF ListSelection < 0 THEN
		'If selection is below zero, set to last item instead
		RedrawNeeded = True
		ListSelection = TotalItems
		ListStartPos = TotalItems - MaxVisibleItems
		IF ListStartPos < 0 THEN ListStartPos = 0
	END IF
	IF ListSelection < ListStartPos THEN
		'If selection is below visible items, scroll up one page
		RedrawNeeded = True
		ListStartPos = ListStartPos - MaxVisibleItems
		IF ListStartPos < 0 THEN ListStartPos = 0
	END IF
	IF ListSelection > TotalItems THEN
		'If selection is higher than item count, set to first item instead
		RedrawNeeded = True
		ListSelection = 0
		ListStartPos = 0
	END IF
	IF ListSelection > ListStartPos + MaxVisibleItems THEN
		'If selected item is below visible items, scroll to make it first visible
		'item
		RedrawNeeded = True
		ListStartPos = ListSelection
	END IF

	IF RedrawNeeded = False THEN
		'Entire list won't be redrawn, so remove current selection
		File.DrawList TargetList, False, False
	END IF

	'Put temporary values back in proper variables
	IF TargetList.MaxLen = FileList THEN
		FileListStartPos = ListStartPos
		FileListSelection = ListSelection
	ELSE
		FolderListStartPos = ListStartPos
		FolderListSelection = ListSelection
	END IF

	'Redraw is only needed if list has been scrolled, otherwise only active
	'item will be drawn
	IF RedrawNeeded THEN
		File.DrawList TargetList, True, True
	ELSE
		File.DrawList TargetList, True, False
	END IF

END SUB

' =========================================================================
'          NAME: File.Select
'    PARAMETERS: DefaultPattern - a valid MS-DOS file pattern (eg, *.txt)
'       RETURNS: Filename with path, if file selected
'       ASSUMES: Nothing
'   CALLED FROM: Anywhere
' -------------------------------------------------------------------------
'   DESCRIPTION: Shows a file selection dialog, allowing the user to
'                browse for and select a file. Used as an "Open" dialog.
' =========================================================================
FUNCTION File.Select (DefaultPattern AS STRING) AS STRING

	DIM winFileSelect AS WindowType
	DIM txtDrive AS TextboxType, txtPattern AS TextboxType
	DIM btnSelect AS ButtonType, btnCancel AS ButtonType
	DIM txtPatternText AS STRING, txtDriveText AS STRING
	DIM btnFilePrev AS ButtonType, btnFileNext AS ButtonType
	DIM btnFolderPrev AS ButtonType, btnFolderNext AS ButtonType

	DIM Drive AS STRING
	DIM OriginalPath AS STRING
	DIM Counter, I, Key$
	DIM ClickedX, ClickedY, ClickedItem, RedrawNeeded

	'Start out with contents of current directory
	OriginalPath = CURDIR$
	Path = OriginalPath
	Drive = LEFT$(Path, 1)
	Pattern = DefaultPattern
	txtDriveText = Drive
	txtPatternText = DefaultPattern
	
	Obj.SetSize winFileSelect.Pos, sizeCenter, sizeCenter, 468, 285
	Obj.SetSize txtPattern.Pos, 101, winFileSelect.Pos.Top + 47, 150, sizeRetain
	Obj.SetSize txtDrive.Pos, 272, winFileSelect.Pos.Top + 47, 150, sizeRetain
	Obj.SetSize txtFileList.Pos, 101, winFileSelect.Pos.Top + 90, 150, 180
	Obj.SetSize txtFolderList.Pos, 272, winFileSelect.Pos.Top + 90, 150, 180
	Obj.SetSize btnSelect.Pos, 448, winFileSelect.Pos.Top + 47, sizeRetain, sizeRetain
	Obj.SetSize btnCancel.Pos, 448, winFileSelect.Pos.Top + 77, sizeRetain, sizeRetain
	Obj.SetSize btnFilePrev.Pos, 253, txtFileList.Pos.Top, 14, 89
	Obj.SetSize btnFileNext.Pos, 253, txtFileList.Pos.Top + 91, 14, 89
	Obj.SetSize btnFolderPrev.Pos, 424, txtFolderList.Pos.Top, 14, 89
	Obj.SetSize btnFolderNext.Pos, 424, txtFolderList.Pos.Top + 91, 14, 89
	
	'These are used in File.DrawList to differentiate lists... It's a dirty
	'hack, but works
	txtFileList.MaxLen = FileList
	txtFolderList.MaxLen = FolderList

	btnSelect.Caption = "õSelect"
	btnCancel.Caption = "õCancel"
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
	Font.Print "õPattern:", 101, winFileSelect.Pos.Top + 33, SystemTheme.WindowText, FontNormal
	Font.Print "õDrive:", 272, winFileSelect.Pos.Top + 33, SystemTheme.WindowText, FontNormal
	Font.Print "õFiles:", 101, winFileSelect.Pos.Top + 76, SystemTheme.WindowText, FontNormal
	Font.Print "Fõolders:", 272, winFileSelect.Pos.Top + 76, SystemTheme.WindowText, FontNormal
	
	MaxVisibleItems = 13

	'These are shared within module, and need to be reset to rid any values
	'from previous showing of the dialog
	FileListStartPos = 0
	FolderListStartPos = 0
	FileListSelection = 0
	FolderListSelection = 0
	ActiveList = FileList
	
	File.GetChildFiles Path, Pattern
	File.GetChildFolders Path
	File.DrawList txtFileList, True, True
	File.DrawList txtFolderList, False, True

	DO
		Key$ = LCASE$(INKEY$)

		IF Mouse.Clicked AND Mouse.InArea(txtFileList.Pos) THEN
			IF File.MouseSelection(txtFileList) THEN Key$ = CHR$(13)
		END IF

		IF Mouse.Clicked AND Mouse.InArea(txtFolderList.Pos) THEN
			IF File.MouseSelection(txtFolderList) THEN Key$ = CHR$(13)
		END IF


		IF Key$ = CHR$(13) THEN
			'Enter-key pressed
			IF ActiveList = FileList THEN
				'Simulate click of "Select" button if the file list is active
				Key$ = "s"
			ELSE
				DIM TestString AS STRING
				TestString = SubFolders(FolderListSelection)
				'REDIM SubFolders(0 TO 0) AS STRING
				File.SetFolder SubFolders(FolderListSelection)
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
				File.DrawList txtFolderList, False, False
				File.DrawList txtFileList, True, False
			END IF
		END IF

		IF Key$ = "o" THEN
			IF NOT ActiveList = FolderList THEN
				ActiveList = FolderList
				File.DrawList txtFileList, False, False
				File.DrawList txtFolderList, True, False
			END IF
		END IF

		IF Obj.BtnClick(btnFilePrev) THEN
			IF NOT ActiveList = FileList THEN
				ActiveList = FileList
				File.DrawList txtFolderList, False, False
			END IF
			Key$ = CHR$(0) + "h" 'Simulate up arrow key
		END IF

		IF Obj.BtnClick(btnFileNext) THEN
			IF NOT ActiveList = FileList THEN
				ActiveList = FileList
				File.DrawList txtFolderList, False, False
			END IF
			Key$ = CHR$(0) + "p" 'Simulate up arrow key
		END IF

		IF Obj.BtnClick(btnFolderPrev) THEN
			IF NOT ActiveList = FolderList THEN
				ActiveList = FolderList
				File.DrawList txtFileList, False, False
			END IF
			Key$ = CHR$(0) + "h" 'Simulate up arrow key
		END IF

		IF Obj.BtnClick(btnFolderNext) THEN
			IF NOT ActiveList = FolderList THEN
				ActiveList = FolderList
				File.DrawList txtFileList, False, False
			END IF
			Key$ = CHR$(0) + "p" 'Simulate up arrow key
		END IF



		IF Key$ = CHR$(0) + "h" OR Key$ = CHR$(0) + "k" THEN
			'Up or left arrow key
			IF ActiveList = FileList THEN
				File.MoveSelection txtFileList, DirectionUp
			ELSE
				File.MoveSelection txtFolderList, DirectionUp
			END IF
		END IF

		IF Key$ = CHR$(0) + "p" OR Key$ = CHR$(0) + "m" THEN
			'Down or right arrow key
			IF ActiveList = FileList THEN
				File.MoveSelection txtFileList, DirectionDown
			ELSE
				File.MoveSelection txtFolderList, DirectionDown
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
				FileListSelection = 0
				FileListStartPos = 0
				File.DrawList txtFileList, True, True
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
					File.DrawList txtFileList, True, True
					File.DrawList txtFileList, True, True
				ELSE
					txtDriveText = Drive
					Obj.DrawTxt txtDrive, txtDriveText, False
				END IF
			END IF
		END IF
						
	LOOP

END FUNCTION

' =========================================================================
'          NAME: File.SetDrive
'    PARAMETERS: Drive - a 1-character string, drive letter
'       RETURNS: True on success, False on failure
'       ASSUMES: Nothing
'   CALLED FROM: FILESEL.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Used internally in File.Select to switch to another
'                drive
' =========================================================================
FUNCTION File.SetDrive (Drive AS STRING)

	IF RTRIM$(Drive) = "" THEN EXIT FUNCTION

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

' =========================================================================
'          NAME: File.SetFolder
'    PARAMETERS: Drive - a 1-character string, drive letter
'       RETURNS: True on success, False on failure
'       ASSUMES: Nothing
'   CALLED FROM: FILESEL.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Used internally in File.Select to switch to another
'                folder
' =========================================================================
SUB File.SetFolder (BYVAL TargetPath AS STRING)
	
	IF RTRIM$(TargetPath) = "" THEN EXIT SUB

	ON LOCAL ERROR GOTO FolderError

	CHDIR SubFolders(FolderListSelection)

	Path = CURDIR$
	File.GetChildFiles Path, Pattern
	File.GetChildFolders Path
	FileListSelection = 0
	FolderListSelection = 0
	File.DrawList txtFileList, True, True
	File.DrawList txtFolderList, True, True
	EXIT SUB

FolderError:
	DIM Null
	Null = Sys.MsgBox("Folder not accesible", "The folder " + TargetPath + " was not accesible." + CHR$(13) + "Verify access and try again.", msgError)
	EXIT SUB
	RETURN

END SUB

