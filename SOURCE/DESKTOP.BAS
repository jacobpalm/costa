OPTION EXPLICIT
DEFINT A-Z
			 
DECLARE SUB Conf.Main ()
DECLARE SUB Desk.AboutBox ()
DECLARE SUB Desk.DrawDesktop ()
DECLARE SUB Desk.ExitGUI ()
DECLARE SUB Desk.LinkDialog (TargetLink%, DidEdit%, NewLink%)
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
	Path AS STRING * 50
	Parameters AS STRING * 50
	ImageFile AS STRING * 8
	PauseOnExit AS INTEGER
	Left AS INTEGER
	Top AS INTEGER
END TYPE

REDIM SHARED DeskLink(0 TO 0) AS DeskLinkType

IF COMMAND$ = "/BOOT" THEN
	'Boot means that we need to initialize Costa, and make sure all paths are
	'valid. Will not run when returning to the desktop from external program.
	ON ERROR RESUME NEXT

	CHDRIVE LEFT$(Temp.Path, 1)
	MKDIR LEFT$(Temp.Path, LEN(Temp.Path) - 1)

	CHDRIVE LEFT$(Sys.Path, 1)
	CHDIR LEFT$(Sys.Path, LEN(Sys.Path) - 1)
	MKDIR "DATA"
	CHDIR "DATA"
	MKDIR "TEMP"
	MKDIR "CONFIG"
	MKDIR "IMAGES"
	MKDIR "THEMES"
	CHDIR ".."
	ON ERROR GOTO 0
END IF

STACK 5120

CALL Sys.Load

Desk.Main

' =========================================================================
'          NAME: Desk.AboutBox()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Shows a modal window with information about the software.
' =========================================================================
SUB Desk.AboutBox ()

	DIM winAboutBox AS WindowType
	DIM btnClose AS ButtonType
	DIM imgLogo AS ImageType
	DIM Key$

	Obj.SetSize winAboutBox.Pos, sizeCenter, sizeCenter, 328, 278
	Obj.SetSize imgLogo.Pos, 168, winAboutBox.Pos.Top + 11, sizeRetain, sizeRetain
	Obj.SetSize btnClose.Pos, 274, winAboutBox.Pos.Top + 243, 92, 22
	btnClose.Caption = "õClose"

	imgLogo.ImageFile = "LOGO"
	
	Mouse.Hide
	PCOPY 0, 1

	Obj.DrawWin winAboutBox
	Obj.DrawBtn btnClose, False
	
	Font.Print appName, 210, winAboutBox.Pos.Top + 17, 0, 1
	Font.Print "Version " + appVersion, 210, winAboutBox.Pos.Top + 31, 0, 2
	Obj.DrawImg imgLogo
	Font.Print "Made in 2004-" + appYear + " by Jacob Palm.", 168, winAboutBox.Pos.Top + 53, 0, 2
	Font.Print "Released under the MIT License.", 168, winAboutBox.Pos.Top + 67, 0, 2
	Font.Print "Font files made in 1998-1999 by Rush Soft.", 168, winAboutBox.Pos.Top + 95, 0, 2
	Font.Print "Costa is open source and may be freely distributed", 168, winAboutBox.Pos.Top + 123, 0, 2
	Font.Print "as long as the terms of the MIT License is upheld -", 168, winAboutBox.Pos.Top + 137, 0, 2
	Font.Print "more info can be found in the LICENSE file.", 168, winAboutBox.Pos.Top + 151, 0, 2
	Font.Print "Special thanks to Todd Suess, who helped during", 168, winAboutBox.Pos.Top + 179, 0, 2
	Font.Print "the development with useful tips and ideas. Also", 168, winAboutBox.Pos.Top + 193, 0, 2
	Font.Print "thanks to those people who were part of the QB", 168, winAboutBox.Pos.Top + 207, 0, 2
	Font.Print "GUI community - every one of you.", 168, winAboutBox.Pos.Top + 221, 0, 2
	Mouse.Show

	DO: LOOP WHILE Mouse.Clicked
	DO

	Key$ = LCASE$(INKEY$)
	IF Obj.BtnClick(btnClose) OR Key$ = CHR$(13) OR Key$ = CHR$(27) OR Key$ = "c" THEN EXIT DO

	LOOP

	Mouse.Hide
	PCOPY 1, 0
	Mouse.Show
	
END SUB

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

	Mouse.Hide

	'Draw desklinks one by one, using imgDeskLinkIcon to draw the imagefile of
	'each desklink
	FOR TargetLink = 0 TO UBOUND(DeskLink)

	'For compatibility - old versions used higher vertical resolution, icons may be
	'out of view if old data file is carried over
	IF DeskLink(TargetLink).Top > 318 THEN DeskLink(TargetLink).Top = 318
	
	imgDeskLinkIcon.ImageFile = DeskLink(TargetLink).ImageFile
	imgDeskLinkIcon.Pos.Left = DeskLink(TargetLink).Left
	imgDeskLinkIcon.Pos.Top = DeskLink(TargetLink).Top
	
	Obj.DrawImg imgDeskLinkIcon

	'Description (caption) and target file
	IF Setting.ShowLinkDescriptions THEN
		Font.Print DeskLink(TargetLink).Caption, DeskLink(TargetLink).Left + 38, DeskLink(TargetLink).Top + 4, Theme.DesktopText, 1

		IF Setting.ShowLinkTargetFiles THEN
			LinkTargetText = LCASE$(DeskLink(TargetLink).Filename)

			'Remove path from string, if present
			DO WHILE INSTR(LinkTargetText, "\")
				LinkTargetText = RIGHT$(LinkTargetText, LEN(LinkTargetText) - INSTR(LinkTargetText, "\"))
			LOOP

			Font.Print LinkTargetText, DeskLink(TargetLink).Left + 38, DeskLink(TargetLink).Top + 18, Theme.DesktopText, 2
		END IF

	END IF
				 
	NEXT
	
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
SUB Desk.LinkDialog (TargetLink, DidEdit, NewLink)

	DIM AllIcons() AS STRING, SelectedFile AS STRING
	DIM ExtractPath AS STRING
	DIM IconCount AS INTEGER, CurrentIcon AS INTEGER, IconFile AS STRING

	Sys.ShowLoading

	IconFile = DIR$(Sys.Path + "DATA\IMAGES\*.BSV")
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
	txtPathText = RTRIM$(DeskLink(TargetLink).Path)
	txtLinkCaptText = RTRIM$(DeskLink(TargetLink).Caption)
	imgIcon.ImageFile = DeskLink(TargetLink).ImageFile
	chkPauseOnExit.Checked = DeskLink(TargetLink).PauseOnExit
	btnBrowse.Caption = "..."
	btnIconPrev.Caption = "<"
	btnIconNext.Caption = ">"
	IF NewLink = False THEN
	btnOK.Caption = "õSave"
	ELSE
	btnOK.Caption = "õAdd icon"
	END IF
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
	Font.Print "õProgram or DOS command:", 222, txtFilename.Pos.Top - 15, Theme.WindowText, 1
	Font.Print "Paõrameters:", 222, txtParams.Pos.Top - 15, Theme.WindowText, 1
	Font.Print "Paõth (including drive):", 222, txtPath.Pos.Top - 15, Theme.WindowText, 1
	Font.Print "Pause after eõxecution", 242, chkPauseOnExit.Pos.Top + 3, Theme.WindowText, 2
	LINE (frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2)-(frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2), Theme.Desktop, BF
	Obj.DrawImg imgIcon
	Mouse.Show
	

	DIM IconChanged
	DIM Key$

	DO
	Key$ = LCASE$(INKEY$)
	IF Key$ = "s" THEN IF NewLink = False THEN Key$ = CHR$(13)
	IF Key$ = "a" THEN IF NewLink = True THEN Key$ = CHR$(13)

	IF Obj.BtnClick(btnOK) OR Key$ = CHR$(13) THEN
		IF RTRIM$(txtLinkCaptText) = "" THEN txtLinkCaptText = "Unnamed link"
		DeskLink(TargetLink).Caption = RTRIM$(txtLinkCaptText)
		DeskLink(TargetLink).Filename = RTRIM$(txtFileNameText)
		DeskLink(TargetLink).Path = RTRIM$(txtPathText)
		DeskLink(TargetLink).Parameters = RTRIM$(txtParamsText)
		DeskLink(TargetLink).PauseOnExit = chkPauseOnExit.Checked

		IF IconChanged = True THEN
			DeskLink(TargetLink).ImageFile = AllIcons(CurrentIcon)
		END IF

		Desk.LinkSave
		DidEdit = -1

		EXIT SUB
	END IF

	IF Obj.BtnClick(btnCancel) OR Key$ = CHR$(27) OR Key$ = "c" THEN
		DidEdit = 0
		EXIT SUB
	END IF

	IF Obj.BtnClick(btnIconPrev) OR Key$ = CHR$(0) + "k" THEN
		IconChanged = True
		CurrentIcon = CurrentIcon - 1
		IF CurrentIcon < 0 THEN CurrentIcon = UBOUND(AllIcons)
		Mouse.Hide
		LINE (frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2)-(frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2), Theme.Desktop, BF
		Mouse.Show
		imgIcon.ImageFile = AllIcons(CurrentIcon)
		Obj.DrawImg imgIcon
	END IF

	IF Obj.BtnClick(btnIconNext) OR Key$ = CHR$(0) + "m" THEN
		IconChanged = True
		CurrentIcon = CurrentIcon + 1
		IF CurrentIcon > UBOUND(AllIcons) THEN CurrentIcon = 0
		Mouse.Hide
		LINE (frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2)-(frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2), Theme.Desktop, BF
		Mouse.Show
		imgIcon.ImageFile = AllIcons(CurrentIcon)
		Obj.DrawImg imgIcon
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
		IF LEN(txtPathText) AND NOT RIGHT$(txtPathText, 1) = "\" THEN txtPathText = txtPathText + "\": Obj.DrawTxt txtPath, txtPathText, False
	END IF

	Obj.ChkClick chkPauseOnExit
	IF Key$ = "x" THEN
		chkPauseOnExit.Checked = NOT chkPauseOnExit.Checked
		Obj.DrawChk chkPauseOnExit
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

	DeskLinkFile = Sys.Path + "DATA\CONFIG\DESKLNK" + LTRIM$(STR$(Setting.DesktopID)) + ".DAT"
	
	IF NOT File.Exists(DeskLinkFile) THEN
		EXIT SUB
	END IF

	FileHandle = FREEFILE
	OPEN Sys.Path + "DATA\CONFIG\DESKLNK" + LTRIM$(STR$(Setting.DesktopID)) + ".DAT" FOR BINARY AS #FileHandle
	IF NOT LOF(FileHandle) = 0 THEN GET #FileHandle, , LinkCount

	IF LinkCount <= 1 THEN
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
	IF LEN(RTRIM$(DeskLink(TargetLink).Path)) THEN
	Font.Print DeskLink(TargetLink).Path, winLinkMenu.Pos.Left + 92, winLinkMenu.Pos.Top + 59, Theme.WindowText, FontNormal
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
		Desk.Run RTRIM$(DeskLink(TargetLink).Filename), RTRIM$(DeskLink(TargetLink).Parameters), RTRIM$(DeskLink(TargetLink).Path), DeskLink(TargetLink).PauseOnExit
	END IF

	'Configure
	IF Obj.BtnClick(btnCustomize) OR Key$ = "u" THEN
		Desk.LinkDialog TargetLink, DidEdit, False
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

	DIM LinkIcon(257), Backdrop(257)

	DIM DrawX, DrawY
	DIM CurGridX, CurGridY, LastGridX, LastGridY
	
	DrawX = DeskLink(TargetLink).Left
	DrawY = DeskLink(TargetLink).Top
	Mouse.Hide
	GET (DrawX, DrawY)-(DrawX + 31, DrawY + 31), LinkIcon
	GET (DrawX, DrawY)-(DrawX + 31, DrawY + 31), Backdrop
	Mouse.Show

	'Center mouse on icon
	Mouse.SetPos DrawX + 16, DrawY + 16

	Mouse.Poll
	CurGridX = MouseX / GridSize
	CurGridY = MouseY / GridSize

	'Limit mouse movement to desktop area
	Mouse.SetBounds 16, 48, 624, 334

	DIM Key$
	DO
	Key$ = LCASE$(INKEY$)
	
	IF Key$ = CHR$(27) THEN
		Mouse.SetBounds 0, 0, 639, 349
		EXIT SUB
	END IF

	IF Key$ = CHR$(13) THEN EXIT DO

	Mouse.Poll

	IF Key$ = CHR$(0) + "k" THEN 'Left arrow
		MouseX = MouseX - GridSize
		IF MouseX < 0 THEN MouseX = 0
		Mouse.SetPos MouseX, MouseY
	END IF
	IF Key$ = CHR$(0) + "m" THEN 'Right arrow
		MouseX = MouseX + GridSize - 1
		IF MouseX > 624 THEN MouseX = 624
		Mouse.SetPos MouseX, MouseY
	END IF
	IF Key$ = CHR$(0) + "h" THEN 'Up arrow
		MouseY = MouseY - GridSize
		IF MouseY < 48 THEN MouseY = 48
		Mouse.SetPos MouseX, MouseY
	END IF
	IF Key$ = CHR$(0) + "p" THEN 'Down arrow
		MouseY = MouseY + GridSize - 1
		IF MouseY > 334 THEN MouseY = 334
		Mouse.SetPos MouseX, MouseY
	END IF

	CurGridX = (MouseX - 16) / GridSize
	IF CurGridX < 0 THEN CurGridX = 0
	CurGridY = (MouseY - 16) / GridSize

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

	LOOP UNTIL Mouse.Clicked

	DeskLink(TargetLink).Left = DrawX
	DeskLink(TargetLink).Top = DrawY
	Desk.LinkSave

	Mouse.SetBounds 0, 0, 639, 349
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

		LOOP UNTIL SortCount = UBOUND(DeskLink) + 1 OR INKEY$ = CHR$(27)

		FOR SortCount = 0 TO UBOUND(DeskLink)
			DeskLink(SortCount) = SortedLinks(SortCount)
		NEXT
	END IF

	'If there's only one link, and it has no caption or path, clear it as
	'that means that the last link has been removed from the desktop
	IF UBOUND(DeskLink) = 0 AND RTRIM$(DeskLink(0).Caption) = "" THEN
		DeskLink(0).Path = ""
		DeskLink(0).Filename = ""
		DeskLink(0).Path = ""
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
	IF File.Exists(Sys.Path + "DATA\CONFIG\DESKLNK" + LTRIM$(STR$(Setting.DesktopID)) + ".DAT") THEN KILL Sys.Path + "DATA\CONFIG\DESKLNK" + LTRIM$(STR$(Setting.DesktopID)) + ".DAT"
	OPEN Sys.Path + "DATA\CONFIG\DESKLNK" + LTRIM$(STR$(Setting.DesktopID)) + ".DAT" FOR BINARY AS #FileHandle
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
	btnAddLink.Caption = "Add õicon"
	Obj.SetSize btnRunCmd.Pos, 102, 2, 92, 22
	btnRunCmd.Caption = "õExecute"

	Obj.SetSize btnPrevious.Pos, 255, 2, 42, 22
	btnPrevious.Caption = "õ<"
	Obj.SetSize btnNext.Pos, 343, 2, 42, 22
	btnNext.Caption = "õ>"

	Obj.SetSize btnAboutCosta.Pos, 446, 2, 92, 22
	btnAboutCosta.Caption = "õAbout..."
	Obj.SetSize btnExitCosta.Pos, 545, 2, 92, 22
	btnExitCosta.Caption = "Eõxit"

	DIM DeskLinkCheck, ClickedX, ClickedY, ClickedB, DidEdit, Key$
	DIM TabCheck, btnTab AS ButtonType, imgTab AS ImageType
	
	Mouse.Show

	Desk.LinkLoad

Desk.RedrawAll:
	TabCheck = -1

	Mouse.Hide
	Obj.DrawMenu
	Obj.DrawBtn btnAddLink, False
	Obj.DrawBtn btnRunCmd, False
	Obj.DrawBtn btnPrevious, False
	Obj.DrawBtn btnNext, False
	Obj.DrawBtn btnAboutCosta, False
	Obj.DrawBtn btnExitCosta, False
	Font.Print LTRIM$(STR$(Setting.DesktopID)) + "/5", 310, 8, Theme.WindowText, FontHeading
	Desk.DrawDesktop
	Mouse.Show

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
			
			DeskLink(UBOUND(DeskLink)).Caption = "Unnamed link"
			DeskLink(UBOUND(DeskLink)).Filename = ""
			DeskLink(UBOUND(DeskLink)).Path = ""
			DeskLink(UBOUND(DeskLink)).Parameters = ""
			DeskLink(UBOUND(DeskLink)).ImageFile = "PROGRAM"
			DeskLink(UBOUND(DeskLink)).Left = 16
			DeskLink(UBOUND(DeskLink)).Top = 48

			Mouse.Hide
			PCOPY 0, 1
			Mouse.Show

			Desk.LinkDialog UBOUND(DeskLink), DidEdit, True

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
			DIM FileToRun AS STRING
			FileToRun = Sys.InputBox("Execute program or command", "You can also use this dialog to open any file" + CHR$(13) + "associated with a program (like README.TXT).", "RUNPROG", "")
			IF LEN(FileToRun) THEN
				DIM RunFile AS STRING
				Desk.Run FileToRun, "", "", True
			END IF
		END IF

		IF Key$ = "a" THEN
			Desk.AboutBox
		END IF

		IF Key$ = CHR$(0) + "k" OR Key$ = CHR$(0) + "m" THEN
			IF Key$ = CHR$(0) + "k" THEN
				Setting.DesktopID = Setting.DesktopID - 1
				IF Setting.DesktopID < 1 THEN Setting.DesktopID = 5
			ELSE
				Setting.DesktopID = Setting.DesktopID + 1
				IF Setting.DesktopID > 5 THEN Setting.DesktopID = 1
			END IF
			Mouse.Hide
			LINE (310, 7)-(330, 16), Theme.Window, BF
			Font.Print LTRIM$(STR$(Setting.DesktopID)) + "/5", 310, 8, Theme.WindowText, FontHeading
			Mouse.Show
			Desk.LinkLoad
			Desk.DrawDesktop
			TabCheck = -1
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
				'Errorcode 1 makes the COSTA.BAT file exit its loop
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
					Mouse.Hide
					imgTab.ImageFile = DeskLink(TabCheck).ImageFile
					imgTab.Pos.Left = DeskLink(TabCheck).Left: imgTab.Pos.Top = DeskLink(TabCheck).Top
					btnTab.Pos.Left = DeskLink(TabCheck).Left - 3: btnTab.Pos.Top = DeskLink(TabCheck).Top - 3
					btnTab.Pos.Width = 37: btnTab.Pos.Height = 37
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
'   DESCRIPTION: Saves information about what program to run to RUN.BAT,
'                then exits. COSTA.BAT will relaunch desktop after
'                external command is done.
' =========================================================================
SUB Desk.Run (BYVAL TargetFile AS STRING, BYVAL TargetParameters AS STRING, BYVAL TargetPath AS STRING, PauseOnExit AS INTEGER)

	DIM RunHandle, DotPos, I
	DIM TargetDrive AS STRING, SysDrive AS STRING, FileType AS STRING
	DIM OpenWith AS STRING
	
	TargetFile = LTRIM$(RTRIM$(TargetFile))
	TargetParameters = LTRIM$(RTRIM$(TargetParameters))

	'Get drive, if any, from path
	IF MID$(TargetPath, 2, 2) = ":\" THEN TargetDrive = LEFT$(TargetPath, 2)

	'Remove trailing \ from path
	IF LEN(TargetPath) THEN
	IF RIGHT$(TargetPath, 1) = "\" AND LEN(TargetPath) > 1 THEN TargetPath = LEFT$(TargetPath, LEN(TargetPath) - 1)
	END IF

	'Get the file extension, and see if it's associated with a program
	'Don't check if target is too short, or if it contains a space (if space is
	'found, then it's not a filename, but a command)
	IF LEN(TargetFile) > 1 AND NOT INSTR(TargetFile, " ") THEN
	FOR I = LEN(TargetFile) TO 1 STEP -1

		'If backslash is found before a dot, then any dot would be part of path
		'and should be ignored
		IF MID$(TargetFile, I, 1) = "\" THEN EXIT FOR

		IF MID$(TargetFile, I, 1) = "." THEN
		FileType = RIGHT$(TargetFile, LEN(TargetFile) - I)
		OpenWith = File.GetAssociation(FileType)

		IF NOT OpenWith = "" THEN
			IF LEN(TargetPath) THEN
			TargetFile = OpenWith + " " + TargetPath + "\" + TargetFile
			TargetPath = ""
			ELSE
			TargetFile = OpenWith + " " + TargetFile
			END IF
		END IF

		END IF
	NEXT
	END IF
	
	'Print the filename, parameters, path and wether to pause on exit to
	'RUN.BAT, and exit. COSTA.BAT will detect that file and run it, and then
	'relaunch the desktop
	RunHandle = FREEFILE

	OPEN Temp.Path + "RUN.BAT" FOR OUTPUT AS #RunHandle
	PRINT #RunHandle, "@ECHO OFF"
	IF LEN(TargetDrive) THEN PRINT #RunHandle, TargetDrive
	IF LEN(TargetPath) THEN
	PRINT #RunHandle, "CD\"
	PRINT #RunHandle, "CD " + TargetPath
	END IF
	PRINT #RunHandle, TargetFile + " " + TargetParameters
	IF PauseOnExit = True THEN
	PRINT #RunHandle, "ECHO."
	PRINT #RunHandle, "ECHO."
	PRINT #RunHandle, "PAUSE"
	END IF

	'Make the batch file return to the path of Costa, so that relative paths
	'within it work
	IF MID$(Sys.Path, 2, 2) = ":\" THEN SysDrive = LEFT$(Sys.Path, 2)
	IF LEN(SysDrive) THEN PRINT #RunHandle, SysDrive
	PRINT #RunHandle, "CD " + LEFT$(Sys.Path, LEN(Sys.Path) - 1)

	CLOSE #RunHandle

	Sys.SaveSettings

	DO: LOOP WHILE LEN(INKEY$)
	END 2

END SUB

