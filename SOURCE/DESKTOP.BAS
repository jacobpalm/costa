OPTION EXPLICIT
DEFINT A-Z
			 
DECLARE SUB Desk.AboutBox ()
DECLARE SUB Desk.DrawDesktop ()
DECLARE SUB Desk.ExecuteDialog ()
DECLARE SUB Desk.ExitGUI ()
DECLARE SUB Desk.LinkDialog (TargetLink%, DidEdit%)
DECLARE SUB Desk.LinkLoad ()
DECLARE SUB Desk.LinkMenu (TargetLink%)
DECLARE SUB Desk.LinkMove (TargetLink%)
DECLARE SUB Desk.LinkSave ()
DECLARE SUB Desk.Main ()
DECLARE SUB Desk.Run (BYVAL TargetFile AS STRING, BYVAL TargetParameters AS STRING, BYVAL TargetPath AS STRING, PauseOnExit AS INTEGER)

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

TYPE DeskLinkType
	Caption AS STRING * 25
	Filename AS STRING * 50
	path AS STRING * 50
	Parameters AS STRING * 50
	ImageFile AS STRING * 8
	PauseOnExit AS INTEGER
	Left AS INTEGER
	Top AS INTEGER
END TYPE

REDIM SHARED DeskLink(0 TO 0) AS DeskLinkType

STACK 5120

CALL Sys.Load

Desk.Main

' =========================================================================
'          NAME: Desk.DrawDesktop()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: That Desk.LinkLoad has been called beforehand
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Redraws all of the links on the desktop - icon, caption,
'                target - according to the settings defined in the config
'                file
' =========================================================================
SUB Desk.DrawDesktop ()
	 
	Mouse.Hide
	LINE (0, 29)-(639, 349), Theme.Desktop, BF
	
	'All desklinks will always have an imagefile. Use this to check if any
	'desklinks exist
	IF RTRIM$(DeskLink(0).ImageFile) = "" OR DeskLink(0).Caption = STRING$(25, 0) THEN
		Mouse.Show
		EXIT SUB
	END IF

	DIM imgDeskLinkIcon AS ImageType
	DIM TargetLink
	DIM LinkTargetText AS STRING

	'Draw desklinks one by one, using imgDeskLinkIcon to draw the imagefile of
	'each desklink
	FOR TargetLink = 0 TO UBOUND(DeskLink)

		'For compatibility - old versions used higher vertical resolution, icons
		'may be out of view if old data file is carried over
		IF DeskLink(TargetLink).Top > 318 THEN DeskLink(TargetLink).Top = 318
	
		imgDeskLinkIcon.ImageFile = DeskLink(TargetLink).ImageFile
		imgDeskLinkIcon.Pos.Left = DeskLink(TargetLink).Left
		imgDeskLinkIcon.Pos.Top = DeskLink(TargetLink).Top
	
		Obj.DrawImg imgDeskLinkIcon
	NEXT

	IF NOT Setting.ShowLinkDescriptions THEN EXIT SUB

	'Next, draw icon captions
	FOR TargetLink = 0 TO UBOUND(DeskLink)
		'Description (caption) and target file
		
		Font.Print DeskLink(TargetLink).Caption, DeskLink(TargetLink).Left + 38, DeskLink(TargetLink).Top + 4, Theme.DesktopText, 1

		IF Setting.ShowLinkTargetFiles THEN
			LinkTargetText = LCASE$(DeskLink(TargetLink).Filename)

			'Remove path from string, if present
			DO WHILE INSTR(LinkTargetText, "\")
				LinkTargetText = RIGHT$(LinkTargetText, LEN(LinkTargetText) - INSTR(LinkTargetText, "\"))
			LOOP

			Font.Print LinkTargetText, DeskLink(TargetLink).Left + 38, DeskLink(TargetLink).Top + 18, Theme.DesktopText, 2
		END IF
		
	NEXT
	
	Mouse.Show

END SUB

SUB Desk.ExecuteDialog ()

	DIM winExecute AS WindowType
	DIM txtProgram AS TextboxType, txtProgramText AS STRING
	DIM txtParameters AS TextboxType, txtParametersText AS STRING
	DIM btnOK AS ButtonType, btnCancel AS ButtonType, btnBrowse AS ButtonType
	DIM imgIcon AS ImageType

	DIM SelectedFile AS STRING
	DIM path AS STRING

	Obj.SetSize winExecute.Pos, sizeCenter, sizeCenter, 342, 196
	Obj.SetSize txtProgram.Pos, winExecute.Pos.Left + 12, winExecute.Pos.Top + 86, winExecute.Pos.Width - 54, sizeRetain
	Obj.SetSize txtParameters.Pos, winExecute.Pos.Left + 12, txtProgram.Pos.Top + 46, winExecute.Pos.Width - 26, sizeRetain
	Obj.SetSize btnBrowse.Pos, txtProgram.Pos.Left + txtProgram.Pos.Width + 9, txtProgram.Pos.Top, 19, 19
	Obj.SetSize btnOK.Pos, winExecute.Pos.Left + winExecute.Pos.Width - 184, txtParameters.Pos.Top + 30, 80, 22
	Obj.SetSize btnCancel.Pos, winExecute.Pos.Left + winExecute.Pos.Width - 94, btnOK.Pos.Top, 80, 22
	Obj.SetSize imgIcon.Pos, winExecute.Pos.Left + 12, winExecute.Pos.Top + 20, sizeRetain, sizeRetain
	btnOK.Caption = "õOK"
	btnCancel.Caption = "õCancel"
	btnBrowse.Caption = "..."
	imgIcon.ImageFile = "RUNPROG"
	
	Mouse.Hide
	PCOPY 0, 1
	Mouse.Show

DrawExecuteDialog:
	Mouse.Hide
	Obj.DrawWin winExecute
	Obj.DrawBtn btnOK, False
	Obj.DrawBtn btnCancel, False
	Obj.DrawTxt txtProgram, txtProgramText, False
	Obj.DrawTxt txtParameters, txtParametersText, False
	Obj.DrawBtn btnBrowse, False
	
	Obj.DrawImg imgIcon

	Font.Print "Execute program", winExecute.Pos.Left + 53, winExecute.Pos.Top + 15, Theme.WindowText, FontHeading
	Font.Print "You can also use this dialog to open any file", winExecute.Pos.Left + 53, winExecute.Pos.Top + 17 + 15, Theme.WindowText, FontNormal
	Font.Print "associated with a program (like README.TXT).", winExecute.Pos.Left + 53, winExecute.Pos.Top + 17 + 30, Theme.WindowText, FontNormal
	Font.Print "õProgram:", txtProgram.Pos.Left, txtProgram.Pos.Top - 16, Theme.WindowText, FontHeading
	Font.Print "Paõrameters:", txtParameters.Pos.Left, txtParameters.Pos.Top - 16, Theme.WindowText, FontHeading
	Mouse.Show

	DIM Key$
	DO

		Key$ = LCASE$(INKEY$)

		IF Obj.BtnClick(btnOK) OR Key$ = "o" OR Key$ = CHR$(13) THEN
			IF LEN(txtProgramText) THEN
				DO WHILE INSTR(txtProgramText, "\")
					path = path + LEFT$(txtProgramText, INSTR(txtProgramText, "\"))
					txtProgramText = RIGHT$(txtProgramText, LEN(txtProgramText) - INSTR(txtProgramText, "\"))
				LOOP
				Desk.Run txtProgramText, txtParametersText, path, True
			END IF
			EXIT DO
		END IF

		IF Obj.BtnClick(btnCancel) OR Key$ = "c" OR Key$ = CHR$(27) THEN
			EXIT DO
		END IF

		IF Obj.BtnClick(btnBrowse) OR Obj.TxtClick(txtProgram) OR Key$ = "." OR Key$ = "p" THEN
			SelectedFile = File.Select("*.exe")
			IF LEN(SelectedFile) THEN txtProgramText = SelectedFile
			Desk.DrawDesktop
			GOTO DrawExecuteDialog
		END IF

		IF Obj.TxtClick(txtParameters) OR Key$ = "r" THEN
			Obj.EditTxt txtParameters, txtParametersText
		END IF

	LOOP

	Mouse.Hide
	PCOPY 1, 0
	Mouse.Show
	
END SUB

' =========================================================================
'          NAME: Desk.LinkDialog()
'    PARAMETERS: TargetLink - the ID of the icon to edit
'                DidEdit    - pass an empty variable, it will be modified
'                             by reference
'                NewLink    - True/False value indicating wether this is
'                             a new link being created
'       RETURNS: A value of True of False in the variable passed to the
'                DidEdit parameter
'       ASSUMES: That the DeskLink array contains a position matching the
'                one passed to TargetLink
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Shows a modal window allowing the user to edit a desktop
'                link, or create a new one.
' =========================================================================
SUB Desk.LinkDialog (TargetLink, DidEdit)

	DIM AllIcons() AS STRING, SelectedFile AS STRING
	DIM ExtractPath AS STRING
	DIM IconCount AS INTEGER, CurrentIcon AS INTEGER, IconFile AS STRING

	Sys.ShowLoading

	IconFile = DIR$("DATA\IMAGES\*.BSV")
	IconCount = 0

	REDIM PRESERVE AllIcons(0) AS STRING
	IF NOT IconFile = "" THEN
		DO
		REDIM PRESERVE AllIcons(0 TO IconCount) AS STRING
		AllIcons(IconCount) = LEFT$(IconFile, LEN(IconFile) - 4)
		
		IF AllIcons(IconCount) = RTRIM$(DeskLink(TargetLink).ImageFile) THEN CurrentIcon = IconCount

		IconCount = IconCount + 1
		IconFile = DIR$
		LOOP UNTIL IconFile = ""
	ELSE
	IconFile = "UNKNOWN"
	AllIcons(0) = "UNKNOWN"
	END IF
	
	DIM ConfWin AS WindowType
	DIM txtLinkCapt AS TextboxType, txtFilename AS TextboxType
	DIM txtParams AS TextboxType, txtPath AS TextboxType
	DIM txtLinkCaptText AS STRING, txtFileNameText AS STRING
	DIM txtParamsText AS STRING, txtPathText AS STRING
	DIM btnIconNext AS ButtonType, btnIconPrev AS ButtonType
	DIM btnOK AS ButtonType, btnCancel AS ButtonType, btnBrowse AS ButtonType
	DIM frmIconFrame AS FrameType
	DIM imgIcon AS ImageType
	DIM chkPauseOnExit AS CheckBoxType

	Obj.SetSize ConfWin.Pos, 210, 35, 220, 312

	Obj.SetSize frmIconFrame.Pos, 296, ConfWin.Pos.Top + 12, 48, 48
	Obj.SetSize imgIcon.Pos, 304, frmIconFrame.Pos.Top + 8, 32, 32
	Obj.SetSize btnIconPrev.Pos, 262, frmIconFrame.Pos.Top + 13, 22, 22
	Obj.SetSize btnIconNext.Pos, 356, frmIconFrame.Pos.Top + 13, 22, 22

	Obj.SetSize txtLinkCapt.Pos, 222, frmIconFrame.Pos.Top + 73, 196, 19
	Obj.SetSize txtFilename.Pos, 222, txtLinkCapt.Pos.Top + 44, 173, 19
	Obj.SetSize btnBrowse.Pos, 399, txtFilename.Pos.Top, 19, 19
	Obj.SetSize txtParams.Pos, 222, txtFilename.Pos.Top + 44, 196, 19
	Obj.SetSize txtPath.Pos, 222, txtParams.Pos.Top + 44, 196, 19
	Obj.SetSize chkPauseOnExit.Pos, 222, txtPath.Pos.Top + 32, sizeRetain, sizeRetain
	Obj.SetSize btnOK.Pos, 229, chkPauseOnExit.Pos.Top + 28, 84, 22
	Obj.SetSize btnCancel.Pos, 326, btnOK.Pos.Top, 84, 22

	txtLinkCapt.MaxLen = 25
	txtFilename.MaxLen = 50
	txtParams.MaxLen = 50
	txtPath.MaxLen = 50
	txtFileNameText = RTRIM$(DeskLink(TargetLink).Filename)
	txtParamsText = RTRIM$(DeskLink(TargetLink).Parameters)
	txtPathText = RTRIM$(DeskLink(TargetLink).path)
	txtLinkCaptText = RTRIM$(DeskLink(TargetLink).Caption)
	imgIcon.ImageFile = DeskLink(TargetLink).ImageFile
	chkPauseOnExit.Checked = DeskLink(TargetLink).PauseOnExit
	btnBrowse.Caption = "..."
	btnIconPrev.Caption = "<"
	btnIconNext.Caption = ">"
	btnOK.Caption = "õSave"
	btnCancel.Caption = "õCancel"

LinkDialogDraw:
	Mouse.Hide
	Obj.DrawWin ConfWin
	Obj.DrawTxt txtLinkCapt, txtLinkCaptText, False
	Obj.DrawBtn btnIconPrev, False
	Obj.DrawFrm frmIconFrame, 15, Theme.Shadow
	Obj.DrawBtn btnIconNext, False
	Obj.DrawTxt txtFilename, txtFileNameText, False
	Obj.DrawBtn btnBrowse, False
	Obj.DrawTxt txtParams, txtParamsText, False
	Obj.DrawTxt txtPath, txtPathText, False
	Obj.DrawChk chkPauseOnExit
	Obj.DrawBtn btnOK, False
	Obj.DrawBtn btnCancel, False
	Font.Print "õDescription (caption):", 222, txtLinkCapt.Pos.Top - 15, Theme.WindowText, 1
	Font.Print "õProgram:", 222, txtFilename.Pos.Top - 15, Theme.WindowText, 1
	Font.Print "Paõrameters:", 222, txtParams.Pos.Top - 15, Theme.WindowText, 1
	Font.Print "Paõth (including drive):", 222, txtPath.Pos.Top - 15, Theme.WindowText, 1
	Font.Print "Pause after eõxecution", 242, chkPauseOnExit.Pos.Top + 3, Theme.WindowText, 2
	LINE (frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2)-(frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2), Theme.Desktop, BF
	Obj.DrawImg imgIcon
	Mouse.Show

	DIM Key$

	DO
		Key$ = LCASE$(INKEY$)

		IF Obj.BtnClick(btnOK) OR Key$ = CHR$(13) OR Key$ = "s" THEN
			IF RTRIM$(txtLinkCaptText) = "" THEN txtLinkCaptText = "Unnamed"
			DeskLink(TargetLink).Caption = RTRIM$(txtLinkCaptText)
			DeskLink(TargetLink).Filename = RTRIM$(txtFileNameText)
			DeskLink(TargetLink).path = RTRIM$(txtPathText)
			DeskLink(TargetLink).Parameters = RTRIM$(txtParamsText)
			DeskLink(TargetLink).PauseOnExit = chkPauseOnExit.Checked
			DeskLink(TargetLink).ImageFile = AllIcons(CurrentIcon)
			
			Desk.LinkSave
			DidEdit = -1

			EXIT SUB
		END IF

		IF Obj.BtnClick(btnCancel) OR Key$ = CHR$(27) OR Key$ = "c" THEN
			DidEdit = 0
			EXIT SUB
		END IF

		IF Obj.BtnClick(btnIconPrev) OR Key$ = CHR$(0) + "k" THEN
			CurrentIcon = CurrentIcon - 1
			IF CurrentIcon < 0 THEN CurrentIcon = UBOUND(AllIcons)
			Mouse.Hide
			LINE (frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2)-(frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2), Theme.Desktop, BF
			imgIcon.ImageFile = AllIcons(CurrentIcon)
			Obj.DrawImg imgIcon
			Mouse.Show
		END IF

		IF Obj.BtnClick(btnIconNext) OR Key$ = CHR$(0) + "m" THEN
			CurrentIcon = CurrentIcon + 1
			IF CurrentIcon > UBOUND(AllIcons) THEN CurrentIcon = 0
			Mouse.Hide
			LINE (frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2)-(frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2), Theme.Desktop, BF
			imgIcon.ImageFile = AllIcons(CurrentIcon)
			Obj.DrawImg imgIcon
			Mouse.Show
		END IF

		IF Obj.BtnClick(btnBrowse) OR Key$ = "." THEN
			SelectedFile = File.Select("*.exe")
			IF NOT SelectedFile = "" THEN
				txtPathText = ""
				DO WHILE INSTR(SelectedFile, "\")
					txtPathText = txtPathText + LEFT$(SelectedFile, INSTR(SelectedFile, "\"))
					SelectedFile = RIGHT$(SelectedFile, LEN(SelectedFile) - INSTR(SelectedFile, "\"))
				LOOP
				txtFileNameText = SelectedFile
			END IF
			Desk.DrawDesktop
			GOTO LinkDialogDraw
		END IF
	
		IF Obj.TxtClick(txtLinkCapt) OR Key$ = "d" THEN Obj.EditTxt txtLinkCapt, txtLinkCaptText
		IF Obj.TxtClick(txtFilename) OR Key$ = "p" THEN Obj.EditTxt txtFilename, txtFileNameText
		IF Obj.TxtClick(txtParams) OR Key$ = "r" THEN Obj.EditTxt txtParams, txtParamsText
		IF Obj.TxtClick(txtPath) OR Key$ = "t" THEN
			Obj.EditTxt txtPath, txtPathText
			IF LEN(txtPathText) AND NOT RIGHT$(txtPathText, 1) = "\" THEN
				txtPathText = txtPathText + "\"
				Mouse.Hide
				Obj.DrawTxt txtPath, txtPathText, False
				Mouse.Show
			END IF
		END IF

		Obj.ChkClick chkPauseOnExit
		IF Key$ = "x" THEN
			chkPauseOnExit.Checked = NOT chkPauseOnExit.Checked
			Mouse.Hide
			Obj.DrawChk chkPauseOnExit
			Mouse.Show
		END IF
			
	LOOP

END SUB

' =========================================================================
'          NAME: Desk.LinkLoad()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Loads desktop link config from a configuration file, and
'                places it in the DeskLink array.
'                If no icons exist in the file, or the file itself does
'                not exist, Desk.LinkReset is called to re-create built-in
'                desktop links.
' =========================================================================
SUB Desk.LinkLoad ()
	
	DIM LinkCount, LinkLoad, FileHandle
	DIM DeskLinkFile AS STRING

	DeskLinkFile = "DATA\CONFIG\DESKLNK" + LTRIM$(STR$(Setting.DesktopID)) + ".DAT"
	
	IF NOT File.Exists(DeskLinkFile) THEN
		IF File.Exists("DATA\CONFIG\DESKLNK.DEF") AND Setting.DesktopID = 1 THEN
			'If we're on the first page and it doesn't exist, but the default file
			'does, load that instead
			DeskLinkFile = "DATA\CONFIG\DESKLNK.DEF"
		ELSE
			REDIM DeskLink(0 TO 0) AS DeskLinkType
			EXIT SUB
		END IF
	END IF

	FileHandle = FREEFILE
	OPEN DeskLinkFile FOR BINARY AS #FileHandle
	IF NOT LOF(FileHandle) = 0 THEN GET #FileHandle, , LinkCount

	IF LinkCount < 1 THEN
		CLOSE #FileHandle
		REDIM DeskLink(0 TO 0) AS DeskLinkType
		EXIT SUB
	END IF

	REDIM DeskLink(0 TO LinkCount - 1) AS DeskLinkType

	FOR LinkLoad = 0 TO LinkCount - 1
		GET #FileHandle, , DeskLink(LinkLoad)
	NEXT
	
	CLOSE #FileHandle

END SUB

' =========================================================================
'          NAME: Desk.LinkMenu
'    PARAMETERS: TargetLink   - the position in the DeskLink array
'                               containing the link to show menu for
'                MenuX, MenuY - the coordinates where menu should be shown
'       RETURNS: Nothing
'       ASSUMES: That the array position in the DeskLink array exists
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Shows the menu that allows the user to open, edit, move
'                or delete a desktop link
' =========================================================================
SUB Desk.LinkMenu (TargetLink)

	DIM winLinkMenu AS WindowType
	DIM btnOpen AS ButtonType, btnCustomize AS ButtonType
	DIM btnMove AS ButtonType, btnRemove AS ButtonType
	DIM btnCancel AS ButtonType
	DIM imgIcon AS ImageType
	
	DIM DidEdit, RedrawNeeded
	DIM Key$, CroppedText AS STRING
	Obj.SetSize winLinkMenu.Pos, sizeCenter, sizeCenter, 413, 165
	Obj.SetSize btnOpen.Pos, winLinkMenu.Pos.Left + 12, winLinkMenu.Pos.Top + winLinkMenu.Pos.Height - 64, 389, 22
	Obj.SetSize btnCustomize.Pos, btnOpen.Pos.Left, btnOpen.Pos.Top + 30, 92, 22
	Obj.SetSize btnMove.Pos, btnCustomize.Pos.Left + 99, btnCustomize.Pos.Top, 92, 22
	Obj.SetSize btnRemove.Pos, btnMove.Pos.Left + 99, btnCustomize.Pos.Top, 92, 22
	Obj.SetSize btnCancel.Pos, btnRemove.Pos.Left + 99, btnCustomize.Pos.Top, 92, 22
	
	Obj.SetSize imgIcon.Pos, winLinkMenu.Pos.Left + 12, winLinkMenu.Pos.Top + 11, sizeRetain, sizeRetain
	imgIcon.ImageFile = DeskLink(TargetLink).ImageFile

	btnOpen.Caption = "õOpen"
	btnCustomize.Caption = "Cõustomize"
	btnMove.Caption = "õMove"
	btnRemove.Caption = "õRemove"
	btnCancel.Caption = "õCancel"
	
	Mouse.Hide
	PCOPY 0, 1
	
	Obj.DrawWin winLinkMenu
	Obj.DrawBtn btnOpen, False
	Obj.DrawBtn btnCustomize, False
	Obj.DrawBtn btnMove, False
	Obj.DrawBtn btnRemove, False
	Obj.DrawBtn btnCancel, False
	Obj.DrawImg imgIcon

	Font.Print DeskLink(TargetLink).Caption, winLinkMenu.Pos.Left + 54, winLinkMenu.Pos.Top + 17, 0, FontHeading
	Font.Print DeskLink(TargetLink).Filename, winLinkMenu.Pos.Left + 54, winLinkMenu.Pos.Top + 31, 0, FontNormal
	Font.Print "Path:", winLinkMenu.Pos.Left + 12, winLinkMenu.Pos.Top + 59, 0, FontNormal
	Font.Print "Parameters:", winLinkMenu.Pos.Left + 12, winLinkMenu.Pos.Top + 76, 0, FontNormal
	
	VIEW SCREEN (winLinkMenu.Pos.Left + 90, winLinkMenu.Pos.Top + 55)-(winLinkMenu.Pos.Left + winLinkMenu.Pos.Width - 12, winLinkMenu.Pos.Top + 90)
	IF LEN(RTRIM$(DeskLink(TargetLink).path)) THEN
		Font.Print DeskLink(TargetLink).path, winLinkMenu.Pos.Left + 92, winLinkMenu.Pos.Top + 59, Theme.WindowText, FontNormal
	ELSE
		Font.Print "Unspecified", winLinkMenu.Pos.Left + 92, winLinkMenu.Pos.Top + 59, Theme.WindowText, FontNormal
	END IF
	IF LEN(RTRIM$(DeskLink(TargetLink).Parameters)) THEN
		Font.Print DeskLink(TargetLink).Parameters, winLinkMenu.Pos.Left + 92, winLinkMenu.Pos.Top + 76, Theme.WindowText, FontNormal
	ELSE
		Font.Print "None", winLinkMenu.Pos.Left + 92, winLinkMenu.Pos.Top + 76, Theme.WindowText, FontNormal
	END IF
	VIEW
	Mouse.Show

	'Clear buffers, sometimes needed on DOSBox
	DO: LOOP WHILE Mouse.Clicked
	DO: LOOP WHILE LEN(INKEY$)

	DO

		Key$ = LCASE$(INKEY$)
	
		'Cancel, or Escape key
		IF Obj.BtnClick(btnCancel) OR Key$ = "c" OR Key$ = CHR$(27) THEN
			EXIT DO
		END IF
	
		'Open/run, or Enter key
		IF Obj.BtnClick(btnOpen) OR Key$ = "o" OR Key$ = CHR$(13) THEN
			Desk.Run RTRIM$(DeskLink(TargetLink).Filename), RTRIM$(DeskLink(TargetLink).Parameters), RTRIM$(DeskLink(TargetLink).path), DeskLink(TargetLink).PauseOnExit
			RedrawNeeded = True
			EXIT DO
		END IF

		'Configure
		IF Obj.BtnClick(btnCustomize) OR Key$ = "u" THEN
			Desk.LinkDialog TargetLink, DidEdit
			IF DidEdit = True THEN RedrawNeeded = True
			EXIT DO
		END IF

		'Move
		IF Obj.BtnClick(btnMove) OR Key$ = "m" THEN

			IF RedrawNeeded THEN
				Desk.DrawDesktop
			ELSE
				Mouse.Hide
				PCOPY 1, 0
				Mouse.Show
			END IF

			Desk.LinkMove TargetLink
			Desk.DrawDesktop
			EXIT SUB
		END IF

		'Remove
		IF Obj.BtnClick(btnRemove) OR Key$ = "r" THEN
			DIM DoDelete

			RedrawNeeded = True
			IF Setting.ConfirmLinkDelete THEN
				DoDelete = Sys.MsgBox("Remove desktop link", "This will permanently delete this" + CHR$(13) + "desktop link. Are you sure?", msgQuest)
			ELSE
				DoDelete = True
			END IF

			IF DoDelete THEN
				DeskLink(TargetLink).Caption = ""
				Desk.LinkSave
				Desk.LinkLoad
				Desk.DrawDesktop
				DO: LOOP WHILE Mouse.Clicked
				EXIT SUB
			END IF
		END IF

	LOOP

	IF RedrawNeeded THEN
		Desk.DrawDesktop
	ELSE
		Mouse.Hide
		PCOPY 1, 0
		Mouse.Show
	END IF
			 
END SUB

' =========================================================================
'          NAME: Desk.LinkMove()
'    PARAMETERS: TargetLink - the position in the DeskLink array
'                             containing the link to move
'       RETURNS: Nothing
'       ASSUMES: That the array position in the DeskLink array exists
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Allows the user to move the specified link on the desktop
'                using mouse or keyboard
' =========================================================================
SUB Desk.LinkMove (TargetLink)

	DO: LOOP WHILE Mouse.Clicked

	CONST GridSize = 8

	DIM btnPrevious AS ButtonType, btnNext AS ButtonType

	DIM LinkIcon(257), Backdrop(257)

	DIM DrawX, DrawY
	DIM CurGridX, CurGridY, LastGridX, LastGridY
	DIM OriginalDesktop, NewDesktop, Desktops
	DIM IconToMove AS DeskLinkType
	
	OriginalDesktop = Setting.DesktopID
	NewDesktop = Setting.DesktopID
	DrawX = DeskLink(TargetLink).Left
	DrawY = DeskLink(TargetLink).Top
	IconToMove = DeskLink(TargetLink)

	'Delete current icon - it will be recreated after move to same or other
	'desktop
	DeskLink(TargetLink).Caption = ""
	Desk.LinkSave

	Obj.SetSize btnPrevious.Pos, 255, 2, 42, 22
	Obj.SetSize btnNext.Pos, 343, 2, 42, 22
	btnPrevious.Caption = "<"
	btnNext.Caption = ">"

	Obj.DrawMenu
	Obj.DrawBtn btnPrevious, False
	Obj.DrawBtn btnNext, False
	Mouse.Hide
	Font.Print LTRIM$(STR$(Setting.DesktopID)) + "/5", 310, 8, Theme.WindowText, FontHeading
	GET (DrawX, DrawY)-(DrawX + 31, DrawY + 31), LinkIcon
	GET (DrawX, DrawY)-(DrawX + 31, DrawY + 31), Backdrop
	Mouse.Show

	'Center mouse on icon
	Mouse.SetPos DrawX + 16, DrawY + 16

	IF NOT MouseSupport THEN
		'Set mouse pos variables manually to make the rest of the code work
		'if no mouse is present
		MouseX = DrawX + 16
		MouseY = DrawY + 16
	END IF

	Mouse.Poll
	CurGridX = MouseX / GridSize
	CurGridY = MouseY / GridSize

	DIM Key$
	DO
		Key$ = LCASE$(INKEY$)
		
		'Escape
		IF Key$ = CHR$(27) THEN EXIT SUB
		
		'Enter
		IF Key$ = CHR$(13) THEN EXIT DO

		Mouse.Poll

		'Arrow keys - move mouse cursor in direction pressed
		IF Key$ = CHR$(0) + "k" THEN 'Left arrow
			MouseX = MouseX - GridSize
		END IF
		IF Key$ = CHR$(0) + "m" THEN 'Right arrow
			MouseX = MouseX + GridSize - 1
		END IF
		IF Key$ = CHR$(0) + "h" THEN 'Up arrow
			MouseY = MouseY - GridSize
		END IF
		IF Key$ = CHR$(0) + "p" THEN 'Down arrow
			MouseY = MouseY + GridSize - 1
		END IF
		
		'Make sure we're within boundaries
		IF MouseX < 0 THEN MouseX = 0
		IF MouseX > 624 THEN MouseX = 624
		IF MouseY < 48 THEN MouseY = 48
		IF MouseY > 334 THEN MouseY = 334

		'If an arrow key was pressed earlier, move cursor accordingly
		IF LEFT$(Key$, 1) = CHR$(0) THEN
			Mouse.SetPos MouseX, MouseY
		END IF

		'Calculate grid position
		CurGridX = (MouseX - 16) / GridSize
		IF CurGridX < 0 THEN CurGridX = 0
		CurGridY = (MouseY - 16) / GridSize
		IF CurGridY < 4 THEN CurGridY = 4

		IF (NOT CurGridX = LastGridX) OR (NOT CurGridY = LastGridY) THEN
			Mouse.Hide
			'Restore backdrop
			PUT (DrawX, DrawY), Backdrop, PSET
			DrawX = CurGridX * GridSize
			DrawY = CurGridY * GridSize
			IF DrawY > 318 THEN DrawY = 318
		
			'Save backdrop, plot icon in its place
			GET (DrawX, DrawY)-(DrawX + 31, DrawY + 31), Backdrop
			PUT (DrawX, DrawY), LinkIcon, PSET
			Mouse.Show
			LastGridX = CurGridX
			LastGridY = CurGridY

			'Reduce flicker
			Sys.Delay .01
			WAIT &H3DA, 8
		END IF

		FOR Desktops = 1 TO 5
			IF Key$ = LTRIM$(STR$(Desktops)) THEN
				IF NOT Desktops = Setting.DesktopID THEN
					NewDesktop = Desktops
				END IF
			END IF
		NEXT

		IF Obj.BtnClick(btnPrevious) THEN
			NewDesktop = NewDesktop - 1
			IF NewDesktop = 0 THEN NewDesktop = 5
		END IF

		IF Obj.BtnClick(btnNext) THEN
			NewDesktop = NewDesktop + 1
			IF NewDesktop = 6 THEN NewDesktop = 1
		END IF

		IF NOT Setting.DesktopID = NewDesktop THEN
			Setting.DesktopID = NewDesktop
			Desk.LinkLoad
			Mouse.Hide
			LINE (310, 7)-(330, 16), Theme.Window, BF
			Font.Print LTRIM$(STR$(Setting.DesktopID)) + "/5", 310, 8, Theme.WindowText, FontHeading
			Desk.DrawDesktop
			Mouse.Hide
			GET (DrawX, DrawY)-(DrawX + 31, DrawY + 31), Backdrop
			PUT (DrawX, DrawY), LinkIcon, PSET
			Mouse.Show
		END IF

	LOOP UNTIL Mouse.Clicked AND MouseY > 28

	Setting.DesktopID = NewDesktop
	Desk.LinkLoad
	IF NOT DeskLink(UBOUND(DeskLink)).Caption = STRING$(25, 0) THEN
		'Only add a new item to DeskLink array if the last item isn't empty
		'or icon move will fail when there's no icons on target desktop
		REDIM PRESERVE DeskLink(0 TO UBOUND(DeskLink) + 1) AS DeskLinkType
	END IF
	DeskLink(UBOUND(DeskLink)) = IconToMove
	DeskLink(UBOUND(DeskLink)).Left = DrawX
	DeskLink(UBOUND(DeskLink)).Top = DrawY
	Desk.LinkSave
	
	DO: LOOP WHILE Mouse.Clicked

END SUB

' =========================================================================
'          NAME: Desk.LinkSave()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Writes the DeskLink array to the config file - providing
'                the array is not empty
' =========================================================================
SUB Desk.LinkSave ()

	'Sort before saving if array contains more than one item - this
	'enables TAB cycling from left to right, top to bottom
	IF UBOUND(DeskLink) > 0 THEN
		DIM SortCount, CheckLink, AddNext
		DIM SortedLinks(0 TO UBOUND(DeskLink)) AS DeskLinkType
		DO

			AddNext = LBOUND(DeskLink)
			FOR CheckLink = 0 TO UBOUND(DeskLink)
				IF DeskLink(CheckLink).Left <= DeskLink(AddNext).Left THEN
					IF DeskLink(CheckLink).Left = DeskLink(AddNext).Left THEN
						IF DeskLink(CheckLink).Top < DeskLink(AddNext).Top THEN
							AddNext = CheckLink
						END IF
					ELSE
						AddNext = CheckLink
					END IF
				END IF
			NEXT

			SortedLinks(SortCount) = DeskLink(AddNext)
			DeskLink(AddNext).Left = 999
			DeskLink(AddNext).Top = 999
			SortCount = SortCount + 1

		LOOP UNTIL SortCount = UBOUND(DeskLink) + 1

		FOR SortCount = 0 TO UBOUND(DeskLink)
			DeskLink(SortCount) = SortedLinks(SortCount)
		NEXT
	END IF

	'If there's only one link, and it has no caption or path, clear it as
	'that means that the last link has been removed from the desktop
	IF UBOUND(DeskLink) = 0 AND RTRIM$(DeskLink(0).Caption) = "" THEN
		DeskLink(0).path = ""
		DeskLink(0).Filename = ""
		DeskLink(0).path = ""
		DeskLink(0).Parameters = ""
		DeskLink(0).ImageFile = ""
		DeskLink(0).PauseOnExit = 0
		DeskLink(0).Left = 0
		DeskLink(0).Top = 0
	END IF

	'Save
	DIM LinkCount, LinkSave, FileHandle
	FOR LinkSave = 0 TO UBOUND(DeskLink)
		IF NOT RTRIM$(DeskLink(LinkSave).Caption) = "" AND NOT DeskLink(LinkSave).Caption = STRING$(25, 0) THEN
			LinkCount = LinkCount + 1
		END IF
	NEXT
	
	FileHandle = FREEFILE
	IF File.Exists("DATA\CONFIG\DESKLNK" + LTRIM$(STR$(Setting.DesktopID)) + ".DAT") THEN KILL "DATA\CONFIG\DESKLNK" + LTRIM$(STR$(Setting.DesktopID)) + ".DAT"
	OPEN "DATA\CONFIG\DESKLNK" + LTRIM$(STR$(Setting.DesktopID)) + ".DAT" FOR BINARY AS #FileHandle
	PUT #FileHandle, , LinkCount

	IF LinkCount = 0 THEN CLOSE #FileHandle: EXIT SUB

	FOR LinkSave = 0 TO UBOUND(DeskLink)

		IF NOT RTRIM$(DeskLink(LinkSave).Caption) = "" AND NOT DeskLink(LinkSave).Caption = STRING$(25, 0) THEN

			PUT #FileHandle, , DeskLink(LinkSave)

		END IF
	NEXT

	CLOSE #FileHandle

END SUB

' =========================================================================
'          NAME: Desk.Main()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Shows the main desktop, and loops through events.
'                This is the main logic for this program.
' =========================================================================
SUB Desk.Main ()

	DIM btnAddLink AS ButtonType, btnRunCmd AS ButtonType
	DIM btnAboutCosta AS ButtonType, btnExitCosta AS ButtonType
	DIM btnPrevious AS ButtonType, btnNext AS ButtonType
	
	Obj.SetSize btnAddLink.Pos, 3, 2, 92, 22
	Obj.SetSize btnRunCmd.Pos, 102, 2, 92, 22
	Obj.SetSize btnPrevious.Pos, 255, 2, 42, 22
	Obj.SetSize btnNext.Pos, 343, 2, 42, 22
	Obj.SetSize btnAboutCosta.Pos, 446, 2, 92, 22
	Obj.SetSize btnExitCosta.Pos, 545, 2, 92, 22

	btnAddLink.Caption = "Add õicon"
	btnRunCmd.Caption = "õExecute"
	btnPrevious.Caption = "õ<"
	btnNext.Caption = "õ>"
	btnAboutCosta.Caption = "õAbout..."
	btnExitCosta.Caption = "Eõxit"

	DIM DeskLinkCheck, ClickedX, ClickedY, ClickedB, DidEdit, Key$
	DIM CheckDesktopID
	DIM TabCheck, btnTab AS ButtonType, imgTab AS ImageType
	
	Desk.LinkLoad

Desk.RedrawAll:
	TabCheck = -1
	CheckDesktopID = Setting.DesktopID

	Mouse.Hide
	Obj.DrawMenu
	Obj.DrawBtn btnAddLink, False
	Obj.DrawBtn btnRunCmd, False
	Obj.DrawBtn btnPrevious, False
	Obj.DrawBtn btnNext, False
	Obj.DrawBtn btnAboutCosta, False
	Obj.DrawBtn btnExitCosta, False
	Font.Print LTRIM$(STR$(Setting.DesktopID)) + "/5", 310, 8, Theme.WindowText, FontHeading
	Mouse.Show

	Desk.DrawDesktop
	
	DO

		Key$ = LCASE$(INKEY$)

		IF Obj.BtnClick(btnAddLink) THEN Key$ = "i"
		IF Obj.BtnClick(btnRunCmd) THEN Key$ = "e"
		IF Obj.BtnClick(btnPrevious) THEN Key$ = CHR$(0) + "k"
		IF Obj.BtnClick(btnNext) THEN Key$ = CHR$(0) + "m"
		IF Obj.BtnClick(btnAboutCosta) THEN Key$ = "a"
		IF Obj.BtnClick(btnExitCosta) THEN Key$ = "x"

		Mouse.Poll
		IF Mouse.Clicked AND MouseY > 32 THEN
			ClickedB = Mouse.Clicked: ClickedX = MouseX: ClickedY = MouseY
		
			'The mouse was clicked. Before checking if a desktop link was clicked,
			'check to see if any desktop links are present
			IF NOT RTRIM$(DeskLink(0).Caption) = "" THEN
			FOR DeskLinkCheck = UBOUND(DeskLink) TO 0 STEP -1

				'Check if the mouse was within the coordinates of the link
				IF ClickedX >= DeskLink(DeskLinkCheck).Left AND ClickedX <= DeskLink(DeskLinkCheck).Left + 31 THEN
				IF ClickedY >= DeskLink(DeskLinkCheck).Top AND ClickedY <= DeskLink(DeskLinkCheck).Top + 31 THEN

					'If we reach this point, the link was clicked.
					Desk.LinkMenu DeskLinkCheck

					'After menu has been shown, buttons might be missing from
					'top bar due to Desk.LinkMove hiding them
					CheckDesktopID = Setting.DesktopID
					Mouse.Hide
					Obj.DrawBtn btnAddLink, False
					Obj.DrawBtn btnRunCmd, False
					Obj.DrawBtn btnPrevious, False
					Obj.DrawBtn btnNext, False
					Obj.DrawBtn btnAboutCosta, False
					Obj.DrawBtn btnExitCosta, False
					Mouse.Show

					'Exit FOR, otherwise overlapping icons will also be clicked
					EXIT FOR

				END IF
				END IF

			NEXT
			END IF
		END IF

		IF LEN(Key$) THEN

			IF Key$ = "i" THEN
				REDIM PRESERVE DeskLink(0 TO UBOUND(DeskLink) + 1) AS DeskLinkType
			
				DeskLink(UBOUND(DeskLink)).Caption = "Unnamed"
				DeskLink(UBOUND(DeskLink)).Filename = ""
				DeskLink(UBOUND(DeskLink)).path = ""
				DeskLink(UBOUND(DeskLink)).Parameters = ""
				DeskLink(UBOUND(DeskLink)).ImageFile = "PROGRAM"
				DeskLink(UBOUND(DeskLink)).Left = 16
				DeskLink(UBOUND(DeskLink)).Top = 40

				Mouse.Hide
				PCOPY 0, 1
				Mouse.Show

				Desk.LinkDialog UBOUND(DeskLink), DidEdit

				IF DidEdit THEN
					TabCheck = -1
					Desk.LinkLoad
					Mouse.Hide
					Desk.DrawDesktop
					Mouse.Show
				ELSE
					REDIM PRESERVE DeskLink(0 TO UBOUND(DeskLink) - 1) AS DeskLinkType
					Mouse.Hide
					PCOPY 1, 0
					Mouse.Show
				END IF

			END IF

			IF Key$ = "e" THEN
				Desk.ExecuteDialog
			END IF

			IF Key$ = "a" THEN
				Sys.AboutBox "Desktop", "Jacob Palm", "LOGO"
			END IF

			IF Key$ = CHR$(0) + "k" THEN
				Setting.DesktopID = Setting.DesktopID - 1
				IF Setting.DesktopID < 1 THEN Setting.DesktopID = 5
			END IF
			IF Key$ = CHR$(0) + "m" THEN
				Setting.DesktopID = Setting.DesktopID + 1
				IF Setting.DesktopID > 5 THEN Setting.DesktopID = 1
			END IF
			IF Key$ = "1" THEN Setting.DesktopID = 1
			IF Key$ = "2" THEN Setting.DesktopID = 2
			IF Key$ = "3" THEN Setting.DesktopID = 3
			IF Key$ = "4" THEN Setting.DesktopID = 4
			IF Key$ = "5" THEN Setting.DesktopID = 5

			IF NOT CheckDesktopID = Setting.DesktopID THEN
				Mouse.Hide
				LINE (310, 7)-(330, 16), Theme.Window, BF
				Font.Print LTRIM$(STR$(Setting.DesktopID)) + "/5", 310, 8, Theme.WindowText, FontHeading
				Mouse.Show
				Desk.LinkLoad
				Desk.DrawDesktop
				TabCheck = -1
				CheckDesktopID = Setting.DesktopID
			END IF
			
			IF Key$ = "x" OR Key$ = CHR$(27) THEN
				DIM DoExit
				IF Setting.ConfirmExit THEN
					DoExit = Sys.MsgBox("Exit " + appName, "This will exit Costa and return you to the DOS" + CHR$(13) + "prompt. Are you sure?", msgQuest)
				ELSE
					DoExit = True
				END IF

				IF DoExit = True THEN
					Mouse.Hide
					Sys.SaveSettings
					SCREEN 0
					COLOR 7, 0
					'Errorcode 1 makes the COSTA.EXE file exit its loop
					END 1
				END IF
			END IF

			'TAB or Shift+TAB
			IF Key$ = CHR$(9) OR Key$ = CHR$(0) + CHR$(15) THEN
				'If there's only one item in the DESKLINK array, and it has no caption
				'then there are no desktop links to cycle
				IF NOT (UBOUND(DeskLink) = 0 AND RTRIM$(DeskLink(0).Caption) = "") THEN
					IF TabCheck > -1 THEN
						Mouse.Hide
						LINE (DeskLink(TabCheck).Left - 3, DeskLink(TabCheck).Top - 3)-(DeskLink(TabCheck).Left + 35, DeskLink(TabCheck).Top + 35), Theme.Desktop, BF
						Obj.DrawImg imgTab
						Mouse.Show
					END IF

					IF Key$ = CHR$(9) THEN
						TabCheck = TabCheck + 1
						IF TabCheck > UBOUND(DeskLink) THEN TabCheck = 0
					ELSE
						TabCheck = TabCheck - 1
						IF TabCheck < 0 THEN TabCheck = UBOUND(DeskLink)
					END IF
			
					IF DeskLink(TabCheck).ImageFile = STRING$(8, 0) THEN
						TabCheck = -1
					ELSE
						imgTab.ImageFile = DeskLink(TabCheck).ImageFile
						imgTab.Pos.Left = DeskLink(TabCheck).Left: imgTab.Pos.Top = DeskLink(TabCheck).Top
						btnTab.Pos.Left = DeskLink(TabCheck).Left - 3: btnTab.Pos.Top = DeskLink(TabCheck).Top - 3
						btnTab.Pos.Width = 37: btnTab.Pos.Height = 37
						Mouse.Hide
						Obj.DrawBtn btnTab, False
						Obj.DrawImg imgTab
						Mouse.Show
					END IF
				END IF
			END IF

			IF (Key$ = CHR$(13) OR Key$ = CHR$(32)) AND TabCheck > -1 THEN
				Mouse.Hide
				LINE (DeskLink(TabCheck).Left - 3, DeskLink(TabCheck).Top - 3)-(DeskLink(TabCheck).Left + 35, DeskLink(TabCheck).Top + 35), Theme.Desktop, BF
				Obj.DrawImg imgTab
				Mouse.Show
				
				IF Key$ = CHR$(13) THEN
					Desk.LinkMenu TabCheck
					CheckDesktopID = Setting.DesktopID
					Mouse.Hide
					Obj.DrawBtn btnAddLink, False
					Obj.DrawBtn btnRunCmd, False
					Obj.DrawBtn btnPrevious, False
					Obj.DrawBtn btnNext, False
					Obj.DrawBtn btnAboutCosta, False
					Obj.DrawBtn btnExitCosta, False
					Mouse.Show
				END IF
				TabCheck = -1
			END IF

		END IF
	
	LOOP

EXIT SUB

END SUB

' =========================================================================
'          NAME: Desk.Run
'    PARAMETERS: TargetFile       - executable or command to run
'                TargetParameters - parameters to pass
'                TargetPath       - path to run from
'                PauseOnExit      - Bool, await keypress before showing
'                                   desktop after execution
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Saves information about what program to run to RUN.DAT,
'                then exits. COSTA.EXE will relaunch desktop after
'                external command is done.
' =========================================================================
SUB Desk.Run (BYVAL TargetFile AS STRING, BYVAL TargetParameters AS STRING, BYVAL TargetPath AS STRING, PauseOnExit AS INTEGER)

	DIM RunHandle, I, ShowErr
	DIM FileType AS STRING
	DIM OpenWith AS STRING
	
	TargetFile = LTRIM$(RTRIM$(TargetFile))
	TargetParameters = LTRIM$(RTRIM$(TargetParameters))

	'Remove trailing \ from path, if any
	IF LEN(TargetPath) > 1 THEN
		IF RIGHT$(TargetPath, 1) = "\" THEN TargetPath = LEFT$(TargetPath, LEN(TargetPath) - 1)
	END IF

	'Get the file extension for file association check
	IF LEN(TargetFile) > 1 THEN
		FOR I = LEN(TargetFile) TO 1 STEP -1

			'If backslash is found before a dot, then any dot would be part of
			'path and should be ignored
			IF MID$(TargetFile, I, 1) = "\" THEN EXIT FOR

			IF MID$(TargetFile, I, 1) = "." THEN
				FileType = UCASE$(RIGHT$(TargetFile, LEN(TargetFile) - I))
				EXIT FOR
			END IF
		NEXT
	END IF

	IF LEN(FileType) THEN
		OpenWith = File.GetAssociation(FileType)
		IF LEN(OpenWith) THEN
			IF LEN(TargetPath) THEN
				TargetParameters = TargetPath + "\" + TargetFile + " " + TargetParameters
				TargetPath = ""
			ELSE
				TargetParameters = TargetFile
			END IF
			IF FileType = "BAT" THEN TargetParameters = "/c " + TargetParameters
			TargetFile = OpenWith
		END IF
	END IF

	IF TargetPath = "" THEN
		IF NOT File.Exists(TargetFile) THEN ShowErr = True
	ELSE
		IF NOT File.Exists(TargetPath + "\" + TargetFile) THEN ShowErr = True
	END IF

	IF ShowErr = True THEN
		ShowErr = Sys.MsgBox("File not found", "The program you are trying to run (" + TargetFile + ") does not exist" + CHR$(13) + "in the specified path.", msgError)
		EXIT SUB
	END IF
	
	'Print the filename, parameters, path and wether to pause on exit to
	'RUN.DAT, and exit. COSTA.EXE will detect that file and run it, and then
	'relaunch the desktop
	RunHandle = FREEFILE

	OPEN "DATA\RUN.DAT" FOR OUTPUT AS #RunHandle
	PRINT #RunHandle, TargetFile
	PRINT #RunHandle, TargetParameters
	PRINT #RunHandle, TargetPath
	IF PauseOnExit = True THEN
		PRINT #RunHandle, "1"
	ELSE
		PRINT #RunHandle, "0"
	END IF
	CLOSE #RunHandle

	Sys.SaveSettings

	DO: LOOP WHILE LEN(INKEY$)
	END

END SUB

