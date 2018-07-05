OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Desk.GetDailyTip () AS STRING
DECLARE FUNCTION Desk.ProfileSelect () AS STRING
DECLARE SUB Conf.Main ()
DECLARE SUB Desk.AboutBox ()
DECLARE SUB Desk.DrawDesktop ()
DECLARE SUB Desk.ExitGUI ()
DECLARE SUB Desk.LinkDialog (TargetLink%, DidEdit%, NewLink%)
DECLARE SUB Desk.LinkLaunch (TargetLink AS INTEGER)
DECLARE SUB Desk.LinkLoad ()
DECLARE SUB Desk.LinkMenu (TargetLink%, MenuX%, MenuY%)
DECLARE SUB Desk.LinkMove (TargetLink%)
DECLARE SUB Desk.LinkReset ()
DECLARE SUB Desk.LinkSave ()
DECLARE SUB Desk.Main ()
DECLARE SUB Desk.ProfileEdit (ProfileNum AS INTEGER)
DECLARE SUB Desk.RunDialog ()
DECLARE SUB TView.Main (FileToView AS STRING)

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

REDIM SHARED DESKLINK(0 TO 0) AS DeskLinkType

IF COMMAND$ = "/BOOT" THEN

    IF Sys.Path = "" OR File.Exists(Sys.Path + appExeName + ".EXE") = False THEN
        CLS
        PRINT "The environment variable " + appExeName + ", which contains the path to Costa, is either"
        PRINT "not set or contains an invalid path."
        PRINT
        PRINT "Run SETUP.EXE to fix this issue."
        PRINT
        END 1
    END IF
    
    'Make sure all directories are present and that no files from previous
    'sessions are present
    ON ERROR RESUME NEXT

    CHDRIVE LEFT$(Sys.Path, 1)
    CHDIR LEFT$(Sys.Path, LEN(Sys.Path) - 1)
    MKDIR "DATA"
    CHDIR "DATA"
    MKDIR "TEMP"
    MKDIR "CONFIG"
    CHDIR "CONFIG"
    MKDIR "PROFILE1"
    MKDIR "PROFILE2"
    MKDIR "PROFILE3"
    MKDIR "PROFILE4"
    MKDIR "PROFILE5"
    CHDIR ".."
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

    DIM FileHandle
    FileHandle = FREEFILE
    OPEN Sys.Path + "DATA\TEMP\RUNSTAT.TMP" FOR OUTPUT AS #FileHandle
    PRINT #FileHandle, "1"
    CLOSE #FileHandle
    
END IF

STACK 5120

CALL Sys.Load

IF ProfileID = "" THEN
    IF File.CfgRead("DATA\CONFIG\COSTA.CFG", "UseLastProfile", "0") = "1" THEN
        DIM ProfileToUse
        ProfileToUse = VAL(File.CfgRead("DATA\CONFIG\COSTA.CFG", "LastUsedProfile", "1"))
        
        IF ProfileToUse > 0 AND ProfileToUse < 5 THEN
            ProfileID = "PROFILE" + LTRIM$(STR$(ProfileToUse))
        ELSE
            ProfileID = "PROFILE1"
        END IF

        Sys.LoadTheme
    ELSE
        ProfileID = Desk.ProfileSelect
        Sys.LoadTheme
    END IF
END IF

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
  DIM frmBack AS FrameType
  DIM Key$

  Obj.SetSize winAboutBox.Pos, 156, 100, 328, 278
  Obj.SetSize frmBack.Pos, 160, 104, 321, 236
  Obj.SetSize btnClose.Pos, 274, 348, 92, 22
  Obj.SetSize imgLogo.Pos, 168, 111, -1, -1
  btnClose.Caption = "Close"
  btnClose.HotKey = 1
  imgLogo.ImageFile = "LOGO"
  
  Obj.DrawWin winAboutBox
  Obj.DrawBtn btnClose, False
  Obj.DrawFrm frmBack, 15, 8
  Mouse.Hide
  LINE (162, 106)-(479, 338), 15, BF
  Mouse.Show
  Obj.DrawImg imgLogo
  
  Font.Print appName, 210, 117, 0, 1
  Font.Print "Version " + appVersion, 210, 131, 0, 2
  Font.Print "Made in 2004-" + appYear + " by Jacob Palm", 168, 153, 0, 2
  Font.Print "Released under the MIT License.", 168, 167, 0, 2
  Font.Print "Font files made in 1998-1999 by Rush Soft.", 168, 195, 0, 2
  Font.Print "Costa is open source and may be freely distributed", 168, 223, 0, 2
  Font.Print "as long as the terms of the MIT License is upheld -", 168, 237, 0, 2
  Font.Print "more info can be found in the LICENSE file.", 168, 251, 0, 2
  Font.Print "Special thanks to Todd Suess, who helped during", 168, 279, 0, 2
  Font.Print "the development with useful tips and ideas. Also", 168, 293, 0, 2
  Font.Print "thanks to those people who were part of the QB", 168, 307, 0, 2
  Font.Print "GUI community - every one of you.", 168, 321, 0, 2


  DO: LOOP WHILE Mouse.Clicked
  DO

    Key$ = LCASE$(INKEY$)
    IF Obj.BtnClick(btnClose) OR Key$ = CHR$(13) OR Key$ = CHR$(27) OR Key$ = "c" THEN EXIT SUB

  LOOP
  
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
   
  'All desklinks will always have an imagefile. Use this to check if any
  'desklinks exist
  IF RTRIM$(DESKLINK(0).ImageFile) = "" OR DESKLINK(0).Caption = STRING$(25, 0) THEN EXIT SUB

  DIM ShowDesc, ShowTarget
  DIM imgDeskLinkIcon AS ImageType
  DIM TargetLink
  DIM LinkTargetText AS STRING

  'Draw desklinks one by one, using imgDeskLinkIcon to draw the imagefile of
  'each desklink
  FOR TargetLink = 0 TO UBOUND(DESKLINK)

    imgDeskLinkIcon.ImageFile = DESKLINK(TargetLink).ImageFile
    imgDeskLinkIcon.Pos.Left = DESKLINK(TargetLink).Left
    imgDeskLinkIcon.Pos.Top = DESKLINK(TargetLink).Top

    Obj.DrawImg imgDeskLinkIcon

    ShowDesc = VAL(File.CfgRead("DATA\CONFIG\" + ProfileID + "\DESKTOP.CFG", "ShowLinkDescriptions", "1"))
    ShowTarget = VAL(File.CfgRead("DATA\CONFIG\" + ProfileID + "\DESKTOP.CFG", "ShowLinkTargetFiles", "1"))

    'Description (caption) and target file
    IF ShowDesc = 1 THEN
    
        IF ShowTarget = 1 THEN
            Font.Print DESKLINK(TargetLink).Caption, DESKLINK(TargetLink).Left + 38, DESKLINK(TargetLink).Top + 4, ClrDesktopText, 1
            
            LinkTargetText = LCASE$(DESKLINK(TargetLink).Filename)

            'Remove path from string, if present
            DO WHILE INSTR(LinkTargetText, "\")
                LinkTargetText = RIGHT$(LinkTargetText, LEN(LinkTargetText) - INSTR(LinkTargetText, "\"))
            LOOP

            Font.Print LinkTargetText, DESKLINK(TargetLink).Left + 38, DESKLINK(TargetLink).Top + 18, ClrDesktopText, 2
        ELSE
            Font.Print DESKLINK(TargetLink).Caption, DESKLINK(TargetLink).Left + 16 - (Font.GetWidth(RTRIM$(DESKLINK(TargetLink).Caption), FontNormal) / 2), DESKLINK(TargetLink).Top + 38, ClrDesktopText, FontNormal
        END IF

    END IF
                 
  NEXT
  
END SUB

' =========================================================================
'          NAME: Desk.ExitGUI()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Removes temporary files used in the current session, and
'                exits the program with an exitcode of 1, signalling to
'                the batch script that it should terminate itself
' =========================================================================
SUB Desk.ExitGUI ()
    ON LOCAL ERROR RESUME NEXT

    IF NOT COMMAND$ = "/DEV" THEN KILL Sys.Path + "DATA\TEMP\*.DAT"
    KILL Sys.Path + "DATA\TEMP\*.TMP"
    KILL Sys.Path + "DATA\TEMP\*.INT"
    KILL Sys.Path + "DATA\TEMP\*.BLU"
    KILL Sys.Path + "DATA\TEMP\*.RED"
    KILL Sys.Path + "DATA\TEMP\*.GRN"

    SCREEN 0
    COLOR 7, 0
    END 1
END SUB

' =========================================================================
'          NAME: Desk.GetDailyTip()
'    PARAMETERS: None
'       RETURNS: A string containing a tip of the day - or an empty string
'                if any error occurs
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Loads all "Tip of the Day" messages from a file, and
'                picks a random one to return
' =========================================================================
FUNCTION Desk.GetDailyTip () AS STRING

    ON LOCAL ERROR GOTO DailyTipError

    DIM TipHandle, TipCount
    DIM DailyTips() AS STRING
    DIM ReadTip AS STRING
    DIM TipToShow AS STRING
    DIM PipePos

    TipCount = 0
    REDIM DailyTips(1 TO 1) AS STRING

    TipHandle = FREEFILE
    OPEN Sys.Path + "DATA\DAILYTIP.DAT" FOR INPUT AS #TipHandle
    DO WHILE NOT EOF(TipHandle)
        LINE INPUT #TipHandle, ReadTip
        IF NOT ReadTip = "" THEN
            TipCount = TipCount + 1
            REDIM PRESERVE DailyTips(1 TO TipCount) AS STRING
            DailyTips(TipCount) = ReadTip
        END IF
    LOOP
    CLOSE #TipHandle

    'Get random tip
    RANDOMIZE TIMER
    TipToShow = DailyTips(INT(RND * TipCount) + 1)
    
    'Replace pipe with line break in tip
    WHILE INSTR(TipToShow, "|")
        PipePos = INSTR(TipToShow, "|")
        TipToShow = LEFT$(TipToShow, PipePos - 1) + CHR$(13) + RIGHT$(TipToShow, LEN(TipToShow) - PipePos)
    WEND

    Desk.GetDailyTip = TipToShow
    EXIT FUNCTION


DailyTipError:
    Desk.GetDailyTip = ""
    EXIT FUNCTION
    RESUME

END FUNCTION

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

  DIM AllIcons() AS STRING
  DIM IconCount AS INTEGER, CurrentIcon AS INTEGER, IconFile AS STRING

  IconFile = DIR$(Sys.Path + "DATA\IMAGES\*.BIF")
  IconCount = 0

  REDIM PRESERVE AllIcons(0) AS STRING
  IF NOT IconFile = "" THEN
      DO
        REDIM PRESERVE AllIcons(0 TO IconCount) AS STRING
        AllIcons(IconCount) = LEFT$(IconFile, LEN(IconFile) - 4)
        
        IF AllIcons(IconCount) = RTRIM$(DESKLINK(TargetLink).ImageFile) THEN CurrentIcon = IconCount

        IconCount = IconCount + 1
        IconFile = DIR$
      LOOP UNTIL IconFile = ""
  ELSE
    IconFile = "UNKNOWN"
    AllIcons(0) = "UNKNOWN"
  END IF
  
  DIM ConfWin AS WindowType
  DIM txtLinkCapt AS TextboxType, txtFileName AS TextboxType
  DIM txtParams AS TextboxType, txtPath AS TextboxType
  DIM txtLinkCaptText AS STRING, txtFilenameText AS STRING
  DIM txtParamsText AS STRING, txtPathText AS STRING
  DIM btnIconNext AS ButtonType, btnIconPrev AS ButtonType
  DIM btnOK AS ButtonType, btnCancel AS ButtonType
  DIM frmIconFrame AS FrameType
  DIM imgIcon AS ImageType
  DIM chkPauseOnExit AS CheckBoxType

  Obj.SetSize ConfWin.Pos, 210, 65, 220, 350

  IF NewLink = False THEN
    ConfWin.Caption = "Customize desktop link"
  ELSE
    ConfWin.Caption = "Add desktop link"
  END IF
  Obj.SetSize txtLinkCapt.Pos, 222, 111, 196, 19
  Obj.SetSize btnIconPrev.Pos, 262, 163, 22, 22
  Obj.SetSize frmIconFrame.Pos, 296, 150, 48, 48
  Obj.SetSize imgIcon.Pos, 304, 158, 32, 32
  Obj.SetSize btnIconNext.Pos, 356, 163, 22, 22
  Obj.SetSize txtFileName.Pos, 222, 230, 196, 19
  Obj.SetSize txtParams.Pos, 222, 276, 196, 19
  Obj.SetSize txtPath.Pos, 222, 325, 196, 19
  Obj.SetSize chkPauseOnExit.Pos, 222, 357, -1, -1
  Obj.SetSize btnOK.Pos, 229, 384, 84, 22
  Obj.SetSize btnCancel.Pos, 326, 384, 84, 22

  txtLinkCapt.MaxLen = 25
  txtFileName.MaxLen = 50
  txtParams.MaxLen = 50
  txtPath.MaxLen = 50
  txtFilenameText = RTRIM$(DESKLINK(TargetLink).Filename)
  txtParamsText = RTRIM$(DESKLINK(TargetLink).Parameters)
  txtPathText = RTRIM$(DESKLINK(TargetLink).Path)
  txtLinkCaptText = RTRIM$(DESKLINK(TargetLink).Caption)
  imgIcon.ImageFile = DESKLINK(TargetLink).ImageFile
  chkPauseOnExit.Checked = DESKLINK(TargetLink).PauseOnExit
  btnIconPrev.Caption = "<"
  btnIconNext.Caption = ">"
  IF NewLink = False THEN
    btnOK.Caption = "Save"
  ELSE
    btnOK.Caption = "Add link"
  END IF
  btnOK.HotKey = 1
  btnCancel.Caption = "Cancel": btnCancel.HotKey = 1


  Obj.DrawWin ConfWin
  Obj.DrawTxt txtLinkCapt, txtLinkCaptText, False
  Obj.DrawBtn btnIconPrev, False
  Obj.DrawFrm frmIconFrame, 15, Clr3DShadow
  Obj.DrawBtn btnIconNext, False
  Obj.DrawTxt txtFileName, txtFilenameText, False
  Obj.DrawTxt txtParams, txtParamsText, False
  Obj.DrawTxt txtPath, txtPathText, False
  Obj.DrawChk chkPauseOnExit
  Obj.DrawBtn btnOK, False
  Obj.DrawBtn btnCancel, False
  Font.Print "Description (caption):", 222, 97, ClrWindowText, 1
  Font.Print "Program or DOS command:", 222, 213, ClrWindowText, 1
  Font.Print "Parameters:", 222, 262, ClrWindowText, 1
  Font.Print "Path (including drive):", 222, 311, ClrWindowText, 1
  Font.Print "Pause after execution", 242, 360, ClrWindowText, 2
  Mouse.Hide
  LINE (221, 108)-(228, 108), ClrWindowText
  LINE (298, 152)-(342, 196), ClrDesktop, BF
  LINE (221, 224)-(228, 224), ClrWindowText
  LINE (237, 322)-(244, 322), ClrWindowText
  LINE (321, 371)-(327, 371), ClrWindowText
  LINE (236, 273)-(243, 273), ClrWindowText
  Mouse.Show
  Obj.DrawImg imgIcon



  DIM IconChanged
  DIM Key$

  DO
    Key$ = LCASE$(INKEY$)
    IF Key$ = "s" THEN IF NewLink = False THEN Key$ = CHR$(13)
    IF Key$ = "a" THEN IF NewLink = True THEN Key$ = CHR$(13)

    IF Obj.BtnClick(btnOK) OR Key$ = CHR$(13) THEN
      IF RTRIM$(txtLinkCaptText) = "" THEN txtLinkCaptText = "Unnamed link"
      DESKLINK(TargetLink).Caption = RTRIM$(txtLinkCaptText)
      DESKLINK(TargetLink).Filename = RTRIM$(txtFilenameText)
      DESKLINK(TargetLink).Path = RTRIM$(txtPathText)
      DESKLINK(TargetLink).Parameters = RTRIM$(txtParamsText)
      DESKLINK(TargetLink).PauseOnExit = chkPauseOnExit.Checked

      IF IconChanged = True THEN
          DESKLINK(TargetLink).ImageFile = AllIcons(CurrentIcon)
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
      LINE (frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2)-(frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2), ClrDesktop, BF
      Mouse.Show
      imgIcon.ImageFile = AllIcons(CurrentIcon)
      Obj.DrawImg imgIcon
    END IF

    IF Obj.BtnClick(btnIconNext) OR Key$ = CHR$(0) + "m" THEN
      IconChanged = True
      CurrentIcon = CurrentIcon + 1
      IF CurrentIcon > UBOUND(AllIcons) THEN CurrentIcon = 0
      Mouse.Hide
      LINE (frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2)-(frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2), ClrDesktop, BF
      Mouse.Show
      imgIcon.ImageFile = AllIcons(CurrentIcon)
      Obj.DrawImg imgIcon
    END IF
  
    IF Obj.TxtClick(txtLinkCapt) OR Key$ = "d" THEN Obj.EditTxt txtLinkCapt, txtLinkCaptText
    IF Obj.TxtClick(txtFileName) OR Key$ = "p" THEN Obj.EditTxt txtFileName, txtFilenameText
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
'          NAME: Desk.LinkLaunch()
'    PARAMETERS: TargetLink - the position in the DeskLink array
'                             containing the link to launch
'       RETURNS: Nothing
'       ASSUMES: That the array position in the DeskLink array exists
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Writes a file telling the batch script which program or
'                command to launch, and exits this program - unless the
'                command is an internal one, in which case the
'                corresponding SUB is called
' =========================================================================
SUB Desk.LinkLaunch (TargetLink AS INTEGER)

    DIM TargetPath AS STRING
    DIM FileToOpen AS STRING

    TargetPath = RTRIM$(DESKLINK(TargetLink).Path)

    'DEBUG
    File.Run RTRIM$(DESKLINK(TargetLink).Filename), RTRIM$(DESKLINK(TargetLink).Parameters), RTRIM$(DESKLINK(TargetLink).Path), DESKLINK(TargetLink).PauseOnExit


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
    FileHandle = FREEFILE

    OPEN Sys.Path + "DATA\CONFIG\" + ProfileID + "\DESKLINK.DAT" FOR BINARY AS #FileHandle
    IF NOT LOF(FileHandle) = 0 THEN GET #FileHandle, , LinkCount

    IF LinkCount = 0 THEN
        CLOSE #FileHandle
        Desk.LinkReset
        EXIT SUB
    END IF
    
    REDIM DESKLINK(0 TO LinkCount - 1) AS DeskLinkType

    FOR LinkLoad = 0 TO LinkCount - 1

        GET #FileHandle, , DESKLINK(LinkLoad)

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
SUB Desk.LinkMenu (TargetLink, MenuX, MenuY)

  DIM BehindMenu(1681), FrontOfMenu(1681)
  DIM DrawFromLeft, DrawFromTop, ActiveItem, FgColor, BgColor
  DIM MenuBack AS ButtonType
  DIM DoAnimations

  MenuBack.Pos.Width = 94
  MenuBack.Pos.Height = 69

  IF MenuX + MenuBack.Pos.Width > 639 THEN
    MenuBack.Pos.Left = MenuX - MenuBack.Pos.Width
    DrawFromLeft = False
  ELSE
    MenuBack.Pos.Left = MenuX
    DrawFromLeft = True
  END IF

  IF MenuY + MenuBack.Pos.Height > 479 THEN
    MenuBack.Pos.Top = MenuY - MenuBack.Pos.Height
    DrawFromTop = False
  ELSE
    MenuBack.Pos.Top = MenuY
    DrawFromTop = True
  END IF

  Mouse.Hide

  DIM x1, y1, X2, Y2
  x1 = MenuBack.Pos.Left
  X2 = MenuBack.Pos.Left + MenuBack.Pos.Width
  y1 = MenuBack.Pos.Top
  Y2 = MenuBack.Pos.Top + MenuBack.Pos.Height
  
  GET (x1, y1)-(X2, Y2), BehindMenu
  
  DoAnimations = VAL(File.CfgRead("DATA\CONFIG\" + ProfileID + "\PROFILE.CFG", "Animations", "1"))
  IF DoAnimations = 1 THEN
    DIM Sys.DelayWait

    IF DrawFromLeft = True THEN
      x1 = MenuBack.Pos.Left
    ELSE
      x1 = MenuBack.Pos.Left + MenuBack.Pos.Width
    END IF
    X2 = x1
    IF DrawFromTop = True THEN
      y1 = MenuBack.Pos.Top
    ELSE
      y1 = MenuBack.Pos.Top + MenuBack.Pos.Height
    END IF
    Y2 = y1

    DO
      LINE (x1, y1)-(X2, Y2), ClrWindow, B
      IF x1 > MenuBack.Pos.Left THEN x1 = x1 - 1
      IF y1 > MenuBack.Pos.Top THEN y1 = y1 - 1
      IF X2 < MenuBack.Pos.Left + MenuBack.Pos.Width THEN X2 = X2 + 1
      IF Y2 < MenuBack.Pos.Top + MenuBack.Pos.Height THEN Y2 = Y2 + 1
      Sys.DelayWait = Sys.DelayWait + 1
      IF Sys.DelayWait = 25 THEN Sys.DelayWait = 0: Sys.Delay .01
    LOOP UNTIL x1 = MenuBack.Pos.Left AND y1 = MenuBack.Pos.Top AND X2 = MenuBack.Pos.Left + MenuBack.Pos.Width AND Y2 = MenuBack.Pos.Top + MenuBack.Pos.Height
  END IF
  Mouse.Show

  FgColor = ClrWindowText
  Obj.DrawBtn MenuBack, False
  Mouse.Hide
  LINE (x1 + 2, y1 + 2)-(X2 - 2, Y2 - 2), ClrWindow, BF
  Mouse.Show
  Font.Print "Open/run", MenuBack.Pos.Left + 6, MenuBack.Pos.Top + 6, FgColor, 1
  Font.Print "Customize..", MenuBack.Pos.Left + 6, MenuBack.Pos.Top + 22, FgColor, 1
  Font.Print "Move", MenuBack.Pos.Left + 6, MenuBack.Pos.Top + 38, FgColor, 1
  Font.Print "Remove", MenuBack.Pos.Left + 6, MenuBack.Pos.Top + 54, FgColor, 1
  LINE (MenuBack.Pos.Left + 5, MenuBack.Pos.Top + 17)-(MenuBack.Pos.Left + 12, MenuBack.Pos.Top + 17), FgColor
  LINE (MenuBack.Pos.Left + 5, MenuBack.Pos.Top + 33)-(MenuBack.Pos.Left + 12, MenuBack.Pos.Top + 33), FgColor
  LINE (MenuBack.Pos.Left + 5, MenuBack.Pos.Top + 49)-(MenuBack.Pos.Left + 12, MenuBack.Pos.Top + 49), FgColor
  LINE (MenuBack.Pos.Left + 5, MenuBack.Pos.Top + 65)-(MenuBack.Pos.Left + 12, MenuBack.Pos.Top + 65), FgColor

  Mouse.Hide
  GET (x1, y1)-(X2, Y2), FrontOfMenu
  Mouse.Show

  DIM KeyWasPressed, DidEdit, Key$

LinkMenuRefresh:
  
  Mouse.Hide
  PUT (x1, y1), FrontOfMenu, PSET
  Mouse.Show

  IF ActiveItem = 1 THEN
    FgColor = ClrSelectText: BgColor = ClrSelect
    LINE (MenuBack.Pos.Left + 2, MenuBack.Pos.Top + 3)-(MenuBack.Pos.Left + MenuBack.Pos.Width - 2, MenuBack.Pos.Top + 18), BgColor, BF
    Font.Print "Open/run", MenuBack.Pos.Left + 6, MenuBack.Pos.Top + 6, FgColor, 1
    LINE (MenuBack.Pos.Left + 5, MenuBack.Pos.Top + 17)-(MenuBack.Pos.Left + 12, MenuBack.Pos.Top + 17), FgColor
  END IF

  IF ActiveItem = 2 THEN
    FgColor = ClrSelectText: BgColor = ClrSelect
    LINE (MenuBack.Pos.Left + 2, MenuBack.Pos.Top + 19)-(MenuBack.Pos.Left + MenuBack.Pos.Width - 2, MenuBack.Pos.Top + 34), BgColor, BF
    Font.Print "Customize..", MenuBack.Pos.Left + 6, MenuBack.Pos.Top + 22, FgColor, 1
    LINE (MenuBack.Pos.Left + 5, MenuBack.Pos.Top + 33)-(MenuBack.Pos.Left + 12, MenuBack.Pos.Top + 33), FgColor
  END IF

  IF ActiveItem = 3 THEN
    FgColor = ClrSelectText: BgColor = ClrSelect
    LINE (MenuBack.Pos.Left + 2, MenuBack.Pos.Top + 35)-(MenuBack.Pos.Left + MenuBack.Pos.Width - 2, MenuBack.Pos.Top + 51), BgColor, BF
    Font.Print "Move", MenuBack.Pos.Left + 6, MenuBack.Pos.Top + 38, FgColor, 1
    LINE (MenuBack.Pos.Left + 5, MenuBack.Pos.Top + 49)-(MenuBack.Pos.Left + 12, MenuBack.Pos.Top + 49), FgColor
  END IF

  IF ActiveItem = 4 THEN
    FgColor = ClrSelectText: BgColor = ClrSelect
    LINE (MenuBack.Pos.Left + 2, MenuBack.Pos.Top + 52)-(MenuBack.Pos.Left + MenuBack.Pos.Width - 2, MenuBack.Pos.Top + 66), BgColor, BF
    Font.Print "Remove", MenuBack.Pos.Left + 6, MenuBack.Pos.Top + 54, FgColor, 1
    LINE (MenuBack.Pos.Left + 5, MenuBack.Pos.Top + 65)-(MenuBack.Pos.Left + 12, MenuBack.Pos.Top + 65), FgColor
  END IF

  DIM LastMouseX, LastMouseY
  
  Mouse.Show
  DO: LOOP WHILE Mouse.Clicked
  DO

    Key$ = LCASE$(INKEY$)
    
    'Escape
    IF Key$ = CHR$(27) THEN
        Mouse.Hide
        PUT (x1, y1), BehindMenu, PSET
        Mouse.Show
        EXIT SUB
    END IF
    
    IF Mouse.X >= MenuBack.Pos.Left + 2 AND Mouse.X <= MenuBack.Pos.Left + MenuBack.Pos.Width - 2 THEN
      IF Mouse.Y >= MenuBack.Pos.Top + 3 AND Mouse.Y <= MenuBack.Pos.Top + 18 THEN
        IF NOT ActiveItem = 1 THEN ActiveItem = 1: Mouse.Hide: GOTO LinkMenuRefresh
      END IF
      IF Mouse.Y >= MenuBack.Pos.Top + 19 AND Mouse.Y <= MenuBack.Pos.Top + 34 THEN
        IF NOT ActiveItem = 2 THEN ActiveItem = 2: Mouse.Hide: GOTO LinkMenuRefresh
      END IF
      IF Mouse.Y >= MenuBack.Pos.Top + 35 AND Mouse.Y <= MenuBack.Pos.Top + 51 THEN
        IF NOT ActiveItem = 3 THEN ActiveItem = 3: Mouse.Hide: GOTO LinkMenuRefresh
      END IF
      IF Mouse.Y >= MenuBack.Pos.Top + 52 AND Mouse.Y <= MenuBack.Pos.Top + 66 THEN
        IF NOT ActiveItem = 4 THEN ActiveItem = 4: Mouse.Hide: GOTO LinkMenuRefresh
      END IF
    END IF

    IF Mouse.InArea(MenuBack.Pos) = False AND KeyWasPressed = False THEN
        IF NOT ActiveItem = 0 THEN
            ActiveItem = 0: Mouse.Hide: GOTO LinkMenuRefresh
        END IF
    END IF

    IF Mouse.Clicked = mbLeft OR LEN(Key$) THEN

      IF Mouse.InArea(MenuBack.Pos) = True OR LEN(Key$) THEN
          IF Mouse.Clicked AND ActiveItem = 1 THEN Key$ = "o"
          IF Mouse.Clicked AND ActiveItem = 2 THEN Key$ = "c"
          IF Mouse.Clicked AND ActiveItem = 3 THEN Key$ = "m"
          IF Mouse.Clicked AND ActiveItem = 4 THEN Key$ = "r"

          'Open/run
          IF Key$ = "o" THEN
            Mouse.Hide
            PUT (x1, y1), BehindMenu, PSET
            Mouse.Show
            Sys.VGASave "DESKTOP"
            Desk.LinkLaunch TargetLink
            EXIT SUB
          END IF

          'Configure
          IF Key$ = "c" THEN
            Mouse.Hide
            PUT (x1, y1), BehindMenu, PSET
            Mouse.Show
            DO: LOOP WHILE Mouse.Clicked

            Sys.VGASave "DESKTOP"
            Desk.LinkDialog TargetLink, DidEdit, False

            IF DidEdit THEN
                Mouse.Hide
                LINE (0, 29)-(639, 479), ClrDesktop, BF
                Desk.DrawDesktop
                Mouse.Show
            ELSE
                Sys.VGALoad "DESKTOP"
            END IF

            EXIT SUB
          END IF

          'Move
          IF Key$ = "m" THEN
            Mouse.Hide
            PUT (x1, y1), BehindMenu, PSET
            Mouse.Driver 7, 0, DESKLINK(TargetLink).Left + 16, DESKLINK(TargetLink).Left + 16
            Mouse.Driver 7, 0, 0, 640
            Mouse.Driver 8, 0, DESKLINK(TargetLink).Top + 16, DESKLINK(TargetLink).Top + 16
            Mouse.Driver 8, 0, 0, 479
            Mouse.Show
            Desk.LinkMove TargetLink
            Mouse.Hide
            LINE (0, 2)-(639, 479), ClrDesktop, BF
            Desk.DrawDesktop
            Mouse.Show
            EXIT SUB
          END IF

          'Remove
          IF Key$ = "r" THEN
            DIM DoDelete

            IF File.CfgRead("DATA\CONFIG\" + ProfileID + "\DESKTOP.CFG", "ConfirmLinkDelete", "1") = "1" THEN
                Mouse.Hide
                PUT (x1, y1), BehindMenu, PSET
                Mouse.Show
                DoDelete = Sys.MsgBox("Remove desktop link", "This will permanently delete this" + CHR$(13) + "desktop link. Are you sure?", msgQuest)
            ELSE
                DoDelete = True
            END IF

            IF DoDelete THEN
                DESKLINK(TargetLink).Caption = ""
                Desk.LinkSave
                Desk.LinkLoad
                Mouse.Hide
                LINE (0, 2)-(639, 479), ClrDesktop, BF
                Desk.DrawDesktop
                Mouse.Show
                DO: LOOP WHILE Mouse.Clicked
                EXIT SUB
            ELSE
                EXIT SUB
            END IF
          END IF

      END IF

        IF Mouse.InArea(MenuBack.Pos) = False THEN
          IF Mouse.Clicked THEN
            Mouse.Hide
            PUT (x1, y1), BehindMenu, PSET
            Mouse.Show
            DO: LOOP WHILE Mouse.Clicked
            EXIT SUB
          END IF
          IF NOT ActiveItem = 0 THEN
            IF KeyWasPressed = False THEN ActiveItem = 0: Mouse.Hide: GOTO LinkMenuRefresh
          END IF
        END IF

    END IF
  LOOP

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

  DIM LinkIcon(257), LinkIconBack(257)
  DIM LastX, LastY, FlickerX, FlickerY
  DIM KeyX, KeyY
  LastX = DESKLINK(TargetLink).Left + 16: LastY = DESKLINK(TargetLink).Top + 16
  Mouse.Hide
  GET (LastX - 16, LastY - 16)-(LastX + 15, LastY + 15), LinkIcon
  GET (LastX - 16, LastY - 16)-(LastX + 15, LastY + 15), LinkIconBack

  Mouse.Show
  DIM Key$
  DO
    Key$ = LCASE$(INKEY$)
    
    IF Key$ = CHR$(27) THEN EXIT SUB
    IF Key$ = CHR$(13) THEN EXIT DO

    IF Key$ = CHR$(0) + "k" THEN
        KeyX = Mouse.X - 15
        IF KeyX < 16 THEN KeyX = 16
        Mouse.Driver 7, 0, KeyX, KeyX
        Mouse.Driver 7, 0, 0, 639
    END IF
    IF Key$ = CHR$(0) + "m" THEN
        KeyX = Mouse.X + 15
        IF KeyX > 624 THEN KeyX = 624
        Mouse.Driver 7, 0, KeyX, KeyX
        Mouse.Driver 7, 0, 0, 639
    END IF
    IF Key$ = CHR$(0) + "h" THEN
        KeyY = Mouse.Y - 15
        IF KeyY < 46 THEN KeyY = 46
        Mouse.Driver 8, 0, KeyY, KeyY
        Mouse.Driver 8, 0, 0, 479
    END IF
    IF Key$ = CHR$(0) + "p" THEN
        KeyY = Mouse.Y + 15
        IF KeyY > 464 THEN KeyY = 464
        Mouse.Driver 8, 0, KeyY, KeyY
        Mouse.Driver 8, 0, 0, 479
    END IF

    Sys.Delay .01
    WAIT &H3DA, 8
    IF NOT FlickerX = Mouse.X OR NOT FlickerY = Mouse.Y THEN
      Mouse.Hide
      PUT (LastX - 16, LastY - 16), LinkIconBack, PSET
      LastX = Mouse.X
      LastY = Mouse.Y
      FlickerX = Mouse.X
      FlickerY = Mouse.Y

      IF LastX < 16 THEN LastX = 16
      IF LastY < 46 THEN LastY = 46
      IF LastX > 624 THEN LastX = 624
      IF LastY > 464 THEN LastY = 464
      GET (LastX - 16, LastY - 16)-(LastX + 15, LastY + 15), LinkIconBack
      PUT (LastX - 16, LastY - 16), LinkIcon, PSET
      Mouse.Show
    END IF
  LOOP UNTIL Mouse.Clicked

  DESKLINK(TargetLink).Left = LastX - 16
  DESKLINK(TargetLink).Top = LastY - 16

  Desk.LinkSave

  DO: LOOP WHILE Mouse.Clicked
END SUB

' =========================================================================
'          NAME: Desk.LinkReset()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Resets all desktop links, by recreating the default array
'                and calling Desk.LinkSave
' =========================================================================
'Resets all desk icons, by recreating the array as default
SUB Desk.LinkReset ()

    REDIM DESKLINK(0 TO 6) AS DeskLinkType

    DESKLINK(0).Caption = "Tic Tac Toe"
    DESKLINK(0).Filename = "TICTAC.EXE"
    DESKLINK(0).Path = appEnviron + "\"
    DESKLINK(0).ImageFile = "TICTAC"
    DESKLINK(0).Left = 15
    DESKLINK(0).Top = 298

    DESKLINK(1).Caption = "Text Viewer"
    DESKLINK(1).Filename = "TEXTVIEW.EXE"
    DESKLINK(1).Path = appEnviron + "\"
    DESKLINK(1).ImageFile = "DOCUMENT"
    DESKLINK(1).Left = 15
    DESKLINK(1).Top = 343

    DESKLINK(2).Caption = "Calculator"
    DESKLINK(2).Filename = "CALC.EXE"
    DESKLINK(2).Path = appEnviron + "\"
    DESKLINK(2).ImageFile = "CALC"
    DESKLINK(2).Left = 15
    DESKLINK(2).Top = 388

    DESKLINK(3).Caption = "Icon Editor"
    DESKLINK(3).Filename = "ICONEDIT.EXE"
    DESKLINK(3).Path = appEnviron + "\"
    DESKLINK(3).ImageFile = "PAINT"
    DESKLINK(3).Left = 15
    DESKLINK(3).Top = 433

    DESKLINK(4).Caption = "DOS-prompt"
    DESKLINK(4).Filename = "COMMAND.COM"
    DESKLINK(4).ImageFile = "DOSPROG"
    DESKLINK(4).PauseOnExit = True
    DESKLINK(4).Left = 480
    DESKLINK(4).Top = 45

    DESKLINK(5).Caption = "What's new?"
    DESKLINK(5).Filename = "DOCS\CHANGES.TXT"
    DESKLINK(5).Path = appEnviron + "\"
    DESKLINK(5).ImageFile = "NEWSPAPE"
    DESKLINK(5).Left = 480
    DESKLINK(5).Top = 388

    DESKLINK(6).Caption = "User's guide"
    DESKLINK(6).Filename = "DOCS\HELP.TXT"
    DESKLINK(6).Path = appEnviron + "\"
    DESKLINK(6).ImageFile = "HELP"
    DESKLINK(6).Left = 480
    DESKLINK(6).Top = 433

    Desk.LinkSave

    DIM ResetMsg
    ResetMsg = Sys.MsgBox("Desktop links reset to default", "The file in which Costa stores the configuration for desktop links, DESKLNK.DAT," + CHR$(13) + "was not found in this profile." + CHR$(13) + CHR$(13) +  _
"A new file has been automatically created, but any custom links will need to be" + CHR$(13) + "created again manually.", msgError)

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
    IF UBOUND(DESKLINK) > 0 THEN
        DIM SortCount, CheckLink, AddNext
        DIM SortedLinks(0 TO UBOUND(DESKLINK)) AS DeskLinkType
        DO

            AddNext = LBOUND(DESKLINK)
            FOR CheckLink = 0 TO UBOUND(DESKLINK)
                IF DESKLINK(CheckLink).Left <= DESKLINK(AddNext).Left THEN
                    IF DESKLINK(CheckLink).Left = DESKLINK(AddNext).Left THEN
                        IF DESKLINK(CheckLink).Top < DESKLINK(AddNext).Top THEN
                            AddNext = CheckLink
                        END IF
                    ELSE
                        AddNext = CheckLink
                    END IF
                END IF
            NEXT

            SortedLinks(SortCount) = DESKLINK(AddNext)
            DESKLINK(AddNext).Left = 999
            DESKLINK(AddNext).Top = 999
            SortCount = SortCount + 1

        LOOP UNTIL SortCount = UBOUND(DESKLINK) + 1 OR INKEY$ = CHR$(27)

        FOR SortCount = 0 TO UBOUND(DESKLINK)
            DESKLINK(SortCount) = SortedLinks(SortCount)
        NEXT
    END IF


    'Save
    DIM LinkCount, LinkSave, FileHandle
    FOR LinkSave = 0 TO UBOUND(DESKLINK)
        IF NOT RTRIM$(DESKLINK(LinkSave).Caption) = "" AND NOT DESKLINK(LinkSave).Caption = STRING$(25, 0) THEN
            LinkCount = LinkCount + 1
        END IF
    NEXT
    
    FileHandle = FREEFILE
    IF File.Exists(Sys.Path + "DATA\CONFIG\" + ProfileID + "\DESKLINK.DAT") THEN KILL Sys.Path + "DATA\CONFIG\" + ProfileID + "\DESKLINK.DAT"
    OPEN Sys.Path + "DATA\CONFIG\" + ProfileID + "\DESKLINK.DAT" FOR BINARY AS #FileHandle
    PUT #FileHandle, , LinkCount

    IF LinkCount = 0 THEN CLOSE #FileHandle: EXIT SUB

    FOR LinkSave = 0 TO UBOUND(DESKLINK)

        IF NOT RTRIM$(DESKLINK(LinkSave).Caption) = "" AND NOT DESKLINK(LinkSave).Caption = STRING$(25, 0) THEN

            PUT #FileHandle, , DESKLINK(LinkSave)

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
  DIM btnProfile AS ButtonType, btnConfig AS ButtonType
  DIM SlidePos, DelayFixer, ShowLinkMenu, ShowAnimations

  Obj.SetSize btnAddLink.Pos, 3, 2, 92, 22
  btnAddLink.Caption = "Add link": btnAddLink.HotKey = 5
  Obj.SetSize btnRunCmd.Pos, 102, 2, 92, 22
  btnRunCmd.Caption = "Execute": btnRunCmd.HotKey = 2

  Obj.SetSize btnProfile.Pos, 224, 2, 92, 22
  btnProfile.Caption = "Profile...": btnProfile.HotKey = 1
  Obj.SetSize btnConfig.Pos, 323, 2, 92, 22
  btnConfig.Caption = "Config...": btnConfig.HotKey = 1

  Obj.SetSize btnAboutCosta.Pos, 446, 2, 92, 22
  btnAboutCosta.Caption = "About...": btnAboutCosta.HotKey = 1
  Obj.SetSize btnExitCosta.Pos, 545, 2, 92, 22
  btnExitCosta.Caption = "Exit": btnExitCosta.HotKey = 1

  DIM DeskLinkCheck, ClickedX, ClickedY, ClickedB, DidEdit, Key$
  DIM TabCheck, btnTab AS ButtonType, imgTab AS ImageType
  DIM dateLastLaunch AS STRING
  
Desk.MainTop:
  Mouse.Hide
  LINE (0, 2)-(639, 479), ClrDesktop, BF
  Desk.LinkLoad
  Desk.DrawDesktop
  Mouse.Show
  TabCheck = -1

  'Clear mouse and keyboard buffer, since DOSBox will sometimes leave data
  DO: LOOP WHILE Mouse.Clicked
  DO: LOOP WHILE LEN(INKEY$)


  'Check if "Tip of the Day" should be shown
  IF VAL(File.CfgRead("DATA\CONFIG\" + ProfileID + "\PROFILE.CFG", "TipOfTheDay", "1")) <> 0 THEN
    'Only show a tip if this is the first time Costa is started today
    IF NOT File.CfgRead("DATA\CONFIG\" + ProfileID + "\PROFILE.CFG", "TipLastShown", "") = STR$(DAY(NOW)) + STR$(MONTH(NOW)) THEN

        DIM showTip, TipOfTheDay AS STRING
        TipOfTheDay = Desk.GetDailyTip
        Mouse.Show

        IF LEN(TipOfTheDay) THEN
            showTip = Sys.MsgBox("Did you know?", TipOfTheDay, msgTip)
        ELSE
            showTip = Sys.MsgBox("Could not read daily tips", "Could not read daily tips from " + Sys.Path + "DATA\DAILYTIPS.DAT." + CHR$(13) + "Make sure this file exists, and isn't corrupted.", msgError)
        END IF

        Mouse.Hide
        File.CfgWrite "DATA\CONFIG\" + ProfileID + "\PROFILE.CFG", "TipLastShown", STR$(DAY(NOW)) + STR$(MONTH(NOW))
    END IF
  END IF


  'The buttons on the menu is drawn at the label SlideDown
  GOSUB SlideDown

  Mouse.Show
  
MainLoopStart:
  DO

    Key$ = LCASE$(INKEY$)

    IF Obj.BtnClick(btnAddLink) THEN Key$ = "l"
    IF Obj.BtnClick(btnRunCmd) THEN Key$ = "x"
    IF Obj.BtnClick(btnProfile) THEN Key$ = "p"
    IF Obj.BtnClick(btnConfig) THEN Key$ = "c"
    IF Obj.BtnClick(btnAboutCosta) THEN Key$ = "a"
    IF Obj.BtnClick(btnExitCosta) THEN Key$ = "e"

    IF Mouse.Clicked AND Mouse.Y > 32 THEN
      ClickedB = Mouse.Clicked: ClickedX = Mouse.X: ClickedY = Mouse.Y
      
      'The mouse was clicked. Before checking if a desktop link was clicked,
      'check to see if any desktop links are present
      IF NOT RTRIM$(DESKLINK(0).Caption) = "" THEN
        FOR DeskLinkCheck = UBOUND(DESKLINK) TO 0 STEP -1

          'Check if the mouse was within the coordinates of the link
          IF ClickedX >= DESKLINK(DeskLinkCheck).Left AND ClickedX <= DESKLINK(DeskLinkCheck).Left + 31 THEN
            IF ClickedY >= DESKLINK(DeskLinkCheck).Top AND ClickedY <= DESKLINK(DeskLinkCheck).Top + 31 THEN

              'If we reach this point, the link was clicked.
              GOSUB SlideUp
              IF ClickedB = mbRight THEN
                'If the right mouse button was clicked, show the menu
                IF NOT TabCheck = -1 THEN
                    Mouse.Hide
                    LINE (DESKLINK(TabCheck).Left - 3, DESKLINK(TabCheck).Top - 3)-(DESKLINK(TabCheck).Left + 35, DESKLINK(TabCheck).Top + 35), ClrDesktop, BF
                    Mouse.Show
                    Obj.DrawImg imgTab
                    TabCheck = -1
                END IF

                Desk.LinkMenu DeskLinkCheck, ClickedX, ClickedY
              ELSE
                'Depending on the configuration a left click on a link
                'will either open/run the targetfile or show the menu
                ShowLinkMenu = VAL(File.CfgRead("DATA\CONFIG\" + ProfileID + "\DESKTOP.CFG", "LinkMenuOnLeftClick", "0"))
                IF ShowLinkMenu = 1 THEN
                    IF NOT TabCheck = -1 THEN
                        Mouse.Hide
                        LINE (DESKLINK(TabCheck).Left - 3, DESKLINK(TabCheck).Top - 3)-(DESKLINK(TabCheck).Left + 35, DESKLINK(TabCheck).Top + 35), ClrDesktop, BF
                        Mouse.Show
                        Obj.DrawImg imgTab
                        TabCheck = -1
                    END IF
                    
                    Desk.LinkMenu DeskLinkCheck, ClickedX, ClickedY
                ELSE
                    Sys.VGASave "DESKTOP"

                    Desk.LinkLaunch DeskLinkCheck
                END IF
              END IF

              GOSUB SlideDown
              GOTO MainLoopStart

            END IF
          END IF

        NEXT
      END IF
    END IF

    IF LEN(Key$) THEN

        IF Key$ = "l" THEN
            REDIM PRESERVE DESKLINK(0 TO UBOUND(DESKLINK) + 1) AS DeskLinkType
            
            DESKLINK(UBOUND(DESKLINK)).Caption = "Unnamed link"
            DESKLINK(UBOUND(DESKLINK)).Filename = ""
            DESKLINK(UBOUND(DESKLINK)).Path = ""
            DESKLINK(UBOUND(DESKLINK)).Parameters = ""
            DESKLINK(UBOUND(DESKLINK)).ImageFile = "PROGRAM"
            DESKLINK(UBOUND(DESKLINK)).Left = 25
            DESKLINK(UBOUND(DESKLINK)).Top = 53

            GOSUB SlideUp
            Sys.VGASave "DESKTOP"
            Desk.LinkDialog UBOUND(DESKLINK), DidEdit, True

            IF DidEdit THEN
                TabCheck = -1
                Desk.LinkLoad
                Mouse.Hide
                LINE (0, 29)-(639, 479), ClrDesktop, BF
                Desk.DrawDesktop
                Mouse.Show
            ELSE
                REDIM PRESERVE DESKLINK(0 TO UBOUND(DESKLINK) - 1) AS DeskLinkType
                Sys.VGALoad "DESKTOP"
            END IF

            GOSUB SlideDown
        END IF

        IF Key$ = "x" THEN
            GOSUB SlideUp
            DIM FileToRun AS STRING
            FileToRun = Sys.InputBox("Execute program or command", "You can also use this dialog to open any file" + CHR$(13) + "associated with a program (like README.TXT).", "RUNPROG", "C:\")
            IF LEN(FileToRun) AND NOT FileToRun = "C:\" THEN
                Sys.VGASave "DESKTOP"
                DIM RunFile AS STRING
                File.Run FileToRun, "", "", True
            END IF
            GOSUB SlideDown
            GOTO MainLoopStart
        END IF

        IF Key$ = "a" THEN
            GOSUB SlideUp
            Sys.VGASave "DESKTOP"
            Desk.AboutBox
            Sys.VGALoad "DESKTOP"
            GOSUB SlideDown
            GOTO MainLoopStart
        END IF

        IF Key$ = "p" THEN
            GOSUB SlideUp
            ProfileID = ""
            Sys.LoadTheme
            Mouse.Hide
            LINE (0, 0)-(639, 479), ClrDesktop, BF
            Mouse.Show
            ProfileID = Desk.ProfileSelect
            Sys.LoadTheme
            GOSUB Desk.MainTop
        END IF

        IF Key$ = "c" THEN
            GOSUB SlideUp
            Sys.VGASave "DESKTOP"
            Conf.Main
            GOSUB SlideDown
            GOTO MainLoopStart
        END IF


        IF Key$ = "e" OR Key$ = CHR$(27) THEN
            GOSUB SlideUp

            DIM DoExit
            IF File.CfgRead("DATA\CONFIG\" + ProfileID + "\PROFILE.CFG", "ConfirmExit", "1") = "1" THEN
                DoExit = Sys.MsgBox("Exit " + appName, "This will exit Costa and return you to the DOS" + CHR$(13) + "prompt. Are you sure?", msgQuest)
            ELSE
                DoExit = True
            END IF

            IF DoExit = True THEN
                Mouse.Hide
                Desk.ExitGUI
            END IF

            GOSUB SlideDown
        END IF

        IF Key$ = CHR$(9) OR Key$ = CHR$(0) + CHR$(15) THEN
            IF TabCheck > -1 THEN
                Mouse.Hide
                LINE (DESKLINK(TabCheck).Left - 3, DESKLINK(TabCheck).Top - 3)-(DESKLINK(TabCheck).Left + 35, DESKLINK(TabCheck).Top + 35), ClrDesktop, BF
                Obj.DrawImg imgTab
                Mouse.Show
            END IF

            IF Key$ = CHR$(9) THEN
                TabCheck = TabCheck + 1
                IF TabCheck > UBOUND(DESKLINK) THEN TabCheck = 0
            ELSE
                TabCheck = TabCheck - 1
                IF TabCheck < 0 THEN TabCheck = UBOUND(DESKLINK)
            END IF
            
            IF DESKLINK(TabCheck).ImageFile = STRING$(8, 0) THEN
                TabCheck = -1
            ELSE
                Mouse.Hide
                imgTab.ImageFile = DESKLINK(TabCheck).ImageFile
                imgTab.Pos.Left = DESKLINK(TabCheck).Left: imgTab.Pos.Top = DESKLINK(TabCheck).Top
                btnTab.Pos.Left = DESKLINK(TabCheck).Left - 3: btnTab.Pos.Top = DESKLINK(TabCheck).Top - 3
                btnTab.Pos.Width = 38: btnTab.Pos.Height = 38
                Obj.DrawBtn btnTab, False
                Obj.DrawImg imgTab
                Mouse.Show
            END IF
        END IF

        IF (Key$ = CHR$(13) OR Key$ = CHR$(32)) AND TabCheck > -1 THEN
            Mouse.Hide
            LINE (DESKLINK(TabCheck).Left - 3, DESKLINK(TabCheck).Top - 3)-(DESKLINK(TabCheck).Left + 35, DESKLINK(TabCheck).Top + 35), ClrDesktop, BF
            Obj.DrawImg imgTab
            Mouse.Show

            IF Key$ = CHR$(13) THEN GOSUB SlideUp: Desk.LinkMenu TabCheck, DESKLINK(TabCheck).Left + 15, DESKLINK(TabCheck).Top + 15: GOSUB SlideDown
            TabCheck = -1
        END IF

      END IF
    
  LOOP

EXIT SUB

SlideDown:
  Mouse.Hide
  ShowAnimations = VAL(File.CfgRead("DATA\CONFIG\" + ProfileID + "\PROFILE.CFG", "Animations", "1"))
  IF ShowAnimations = 1 THEN
    DelayFixer = 0
    FOR SlidePos = 0 TO 26 STEP 2
      LINE (0, 0)-(639, SlidePos), ClrWindow, BF
      LINE (0, SlidePos + 1)-(639, SlidePos + 1), Clr3DShadow
      LINE (0, SlidePos + 2)-(639, SlidePos + 2), 0
      DelayFixer = DelayFixer + 1
      IF DelayFixer = 4 THEN
        Sys.Delay .01
        DelayFixer = 0
      END IF
    NEXT
  ELSE
    LINE (0, 0)-(639, 26), ClrWindow, BF
    LINE (0, 27)-(639, 27), Clr3DShadow
    LINE (0, 28)-(639, 28), 0
  END IF
  Mouse.Show
  Obj.DrawBtn btnAddLink, False
  Obj.DrawBtn btnRunCmd, False
  Obj.DrawBtn btnAboutCosta, False
  Obj.DrawBtn btnConfig, False
  Obj.DrawBtn btnProfile, False
  Obj.DrawBtn btnExitCosta, False
RETURN

SlideUp:
  Mouse.Hide
  DelayFixer = 0
  ShowAnimations = VAL(File.CfgRead("DATA\CONFIG\" + ProfileID + "\PROFILE.CFG", "Animations", "1"))
  IF ShowAnimations = 1 THEN
    LINE (0, 0)-(639, 28), ClrWindow, BF
    FOR SlidePos = 25 TO 0 STEP -2
      LINE (0, SlidePos)-(639, SlidePos), Clr3DShadow
      LINE (0, SlidePos + 1)-(639, SlidePos + 1), 0
      LINE (0, SlidePos + 2)-(639, SlidePos + 3), ClrDesktop, BF
      DelayFixer = DelayFixer + 1
      IF DelayFixer = 4 THEN
        Sys.Delay .01
        DelayFixer = 0
      END IF
    NEXT
  ELSE
      LINE (0, 3)-(639, 28), ClrDesktop, BF
      LINE (0, 0)-(639, 0), ClrWindow
      LINE (0, 1)-(639, 1), Clr3DShadow
      LINE (0, 2)-(639, 2), 0
  END IF
  Mouse.Show
RETURN


END SUB

SUB Desk.ProfileEdit (ProfileNum AS INTEGER)
    DIM AllIcons() AS STRING
    DIM IconCount AS INTEGER, CurrentIcon AS INTEGER, IconFile AS STRING
    DIM CurrentIconFilename AS STRING

    IconFile = DIR$(Sys.Path + "DATA\IMAGES\*.BIF")
    IconCount = 0
    CurrentIconFilename = UCASE$(File.CfgRead("DATA\CONFIG\PROFILE" + LTRIM$(STR$(ProfileNum)) + "\PROFILE.CFG", "ProfileIcon", "USERS"))

    REDIM PRESERVE AllIcons(0) AS STRING
    IF NOT IconFile = "" THEN
        DO
          REDIM PRESERVE AllIcons(0 TO IconCount) AS STRING
          AllIcons(IconCount) = LEFT$(IconFile, LEN(IconFile) - 4)

          IF AllIcons(IconCount) = CurrentIconFilename THEN CurrentIcon = IconCount

          IconCount = IconCount + 1
          IconFile = DIR$
        LOOP UNTIL IconFile = ""
    ELSE
      IconFile = "UNKNOWN"
      AllIcons(0) = "UNKNOWN"
    END IF


    DIM winProfEdit AS WindowType
    DIM txtProfileName AS TextboxType
    DIM txtProfileNameText AS STRING
    DIM btnSave AS ButtonType, btnCancel AS ButtonType
    DIM btnIconPrev AS ButtonType, btnIconNext AS ButtonType
    DIM frmIconFrame AS FrameType
    DIM imgIcon AS ImageType
    
    winProfEdit.Pos.Width = 220
    winProfEdit.Pos.Height = 208
    winProfEdit.Pos.Left = (640 - winProfEdit.Pos.Width) / 2
    winProfEdit.Pos.Top = (480 - winProfEdit.Pos.Height) / 2
    winProfEdit.Caption = "Edit profile"

    Obj.SetSize frmIconFrame.Pos, 296, winProfEdit.Pos.Top + 46, 48, 48
    Obj.SetSize imgIcon.Pos, 304, frmIconFrame.Pos.Top + 8, 32, 32
    Obj.SetSize btnIconPrev.Pos, 262, frmIconFrame.Pos.Top + 14, 22, 22
    Obj.SetSize btnIconNext.Pos, 356, frmIconFrame.Pos.Top + 14, 22, 22
    Obj.SetSize txtProfileName.Pos, 222, winProfEdit.Pos.Top + 128, 196, 19
    Obj.SetSize btnSave.Pos, 229, winProfEdit.Pos.Top + 174, 84, 22
    Obj.SetSize btnCancel.Pos, 326, winProfEdit.Pos.Top + 174, 84, 22

    txtProfileName.MaxLen = 50
    txtProfileNameText = File.CfgRead("DATA\CONFIG\PROFILE" + LTRIM$(STR$(ProfileNum)) + "\PROFILE.CFG", "ProfileName", "Profile " + LTRIM$(STR$(ProfileNum)))
    btnIconPrev.Caption = "<"
    btnIconNext.Caption = ">"
    btnSave.Caption = "Save": btnSave.HotKey = 1
    btnCancel.Caption = "Cancel": btnCancel.HotKey = 1
    imgIcon.ImageFile = AllIcons(CurrentIcon)

    Obj.DrawWin winProfEdit
    Obj.DrawBtn btnIconPrev, False
    Obj.DrawFrm frmIconFrame, 15, Clr3DShadow
    Obj.DrawBtn btnIconNext, False
    Obj.DrawTxt txtProfileName, txtProfileNameText, False
    Obj.DrawBtn btnSave, False
    Obj.DrawBtn btnCancel, False
    Font.Print "Name:", 222, winProfEdit.Pos.Top + 114, ClrWindowText, 1
    Mouse.Hide
    LINE (221, winProfEdit.Pos.Top + 125)-(229, winProfEdit.Pos.Top + 125), ClrWindowText
    Mouse.Show
    Obj.DrawImg imgIcon

    DIM Key$
    DO
        Key$ = LCASE$(INKEY$)

        IF Obj.BtnClick(btnIconPrev) OR Key$ = CHR$(0) + "k" THEN
          CurrentIcon = CurrentIcon - 1
          IF CurrentIcon < 0 THEN CurrentIcon = UBOUND(AllIcons)
          Mouse.Hide
          LINE (frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2)-(frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2), ClrButton, BF
          Mouse.Show
          imgIcon.ImageFile = AllIcons(CurrentIcon)
          Obj.DrawImg imgIcon
        END IF

        IF Obj.BtnClick(btnIconNext) OR Key$ = CHR$(0) + "m" THEN
          CurrentIcon = CurrentIcon + 1
          IF CurrentIcon > UBOUND(AllIcons) THEN CurrentIcon = 0
          Mouse.Hide
          LINE (frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2)-(frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2), ClrButton, BF
          Mouse.Show
          imgIcon.ImageFile = AllIcons(CurrentIcon)
          Obj.DrawImg imgIcon
        END IF

        IF Obj.TxtClick(txtProfileName) OR Key$ = "n" THEN Obj.EditTxt txtProfileName, txtProfileNameText

        IF Obj.BtnClick(btnSave) OR Key$ = CHR$(13) OR Key$ = "s" THEN
            File.CfgWrite "DATA\CONFIG\PROFILE" + LTRIM$(STR$(ProfileNum)) + "\PROFILE.CFG", "ProfileName", txtProfileNameText
            File.CfgWrite "DATA\CONFIG\PROFILE" + LTRIM$(STR$(ProfileNum)) + "\PROFILE.CFG", "ProfileIcon", AllIcons(CurrentIcon)
            EXIT SUB
        END IF

        IF Obj.BtnClick(btnCancel) OR Key$ = CHR$(27) OR Key$ = "c" THEN
            EXIT SUB
        END IF

    LOOP

END SUB

FUNCTION Desk.ProfileSelect () AS STRING
    DIM ProfileEnabled(1 TO 5) AS INTEGER
    DIM ProfileName(1 TO 5) AS STRING
    DIM Counter, SelectedProfile
    DIM ProfileNamePos
    DIM Key$

    DIM winProfiles AS WindowType
    DIM btnProfile(1 TO 5) AS ButtonType
    DIM imgProfile(1 TO 5) AS ImageType
    DIM btnContinue AS ButtonType
    DIM btnEdit AS ButtonType

    winProfiles.Pos.Width = 338
    winProfiles.Pos.Height = 220
    winProfiles.Pos.Left = (640 - winProfiles.Pos.Width) / 2
    winProfiles.Pos.Top = (480 - winProfiles.Pos.Height) / 2
    winProfiles.Caption = "Profile selection"

    Obj.SetSize btnProfile(1).Pos, winProfiles.Pos.Left + 18, winProfiles.Pos.Top + 84, 46, 46
    Obj.SetSize btnProfile(2).Pos, winProfiles.Pos.Left + 82, winProfiles.Pos.Top + 84, 46, 46
    Obj.SetSize btnProfile(3).Pos, winProfiles.Pos.Left + 146, winProfiles.Pos.Top + 84, 46, 46
    Obj.SetSize btnProfile(4).Pos, winProfiles.Pos.Left + 210, winProfiles.Pos.Top + 84, 46, 46
    Obj.SetSize btnProfile(5).Pos, winProfiles.Pos.Left + 274, winProfiles.Pos.Top + 84, 46, 46
    btnProfile(1).Transparent = True
    btnProfile(2).Transparent = True
    btnProfile(3).Transparent = True
    btnProfile(4).Transparent = True
    btnProfile(5).Transparent = True

    Obj.SetSize btnContinue.Pos, winProfiles.Pos.Left + winProfiles.Pos.Width - 94, winProfiles.Pos.Top + winProfiles.Pos.Height - 34, 80, 22
    btnContinue.Caption = "Continue"
    btnContinue.HotKey = 1

    Obj.SetSize btnEdit.Pos, winProfiles.Pos.Left + 18, winProfiles.Pos.Top + winProfiles.Pos.Height - 34, 80, 22
    btnEdit.Caption = "Edit..."
    btnEdit.HotKey = 1

    SelectedProfile = VAL(File.CfgRead("DATA\CONFIG\COSTA.CFG", "LastUsedProfile", "1"))
    IF SelectedProfile < 1 OR SelectedProfile > 5 THEN SelectedProfile = 1


TopOfProfile:

    FOR Counter = 1 TO 5
        ProfileName(Counter) = File.CfgRead("DATA\CONFIG\PROFILE" + LTRIM$(STR$(Counter)) + "\PROFILE.CFG", "ProfileName", "Profile" + STR$(Counter))
        imgProfile(Counter).ImageFile = File.CfgRead("DATA\CONFIG\PROFILE" + LTRIM$(STR$(Counter)) + "\PROFILE.CFG", "ProfileIcon", "USERS")
        ProfileEnabled(Counter) = VAL(File.CfgRead("DATA\CONFIG\PROFILE" + LTRIM$(STR$(Counter)) + "\PROFILE.CFG", "ProfileEnabled", "0"))
    NEXT

    Obj.DrawWin winProfiles
    Font.Print "Please select a profile from which your desktop,", winProfiles.Pos.Left + 14, winProfiles.Pos.Top + 36, ClrWindowText, FontNormal
    Font.Print "theme and other customizations will be loaded.", winProfiles.Pos.Left + 14, winProfiles.Pos.Top + 50, ClrWindowText, FontNormal

    IF SelectedProfile < 1 OR SelectedProfile > 5 THEN
        SelectedProfile = 1
    END IF

    ProfileNamePos = winProfiles.Pos.Left + (winProfiles.Pos.Width / 2) - (Font.GetWidth(ProfileName(SelectedProfile), FontHeading) / 2)
    Font.Print ProfileName(SelectedProfile), ProfileNamePos, winProfiles.Pos.Top + 154, ClrWindowText, FontHeading

    FOR Counter = 1 TO 5
        IF Counter = SelectedProfile THEN
            Obj.DrawBtn btnProfile(Counter), True
        ELSE
            Obj.DrawBtn btnProfile(Counter), False
        END IF
        imgProfile(Counter).Pos.Top = btnProfile(Counter).Pos.Top + 7
        imgProfile(Counter).Pos.Left = btnProfile(Counter).Pos.Left + 7
        Obj.DrawImg imgProfile(Counter)
    NEXT

    Obj.DrawBtn btnContinue, False
    Obj.DrawBtn btnEdit, False

    DO
        Key$ = LCASE$(INKEY$)

        IF Key$ = CHR$(0) + "k" THEN Key$ = LTRIM$(STR$(SelectedProfile - 1))
        IF Key$ = CHR$(0) + "m" THEN Key$ = LTRIM$(STR$(SelectedProfile + 1))

        FOR Counter = 1 TO 5
            IF Mouse.Clicked AND Mouse.InArea(btnProfile(Counter).Pos) THEN
                Key$ = LTRIM$(STR$(Counter))
            END IF

            IF Key$ = LTRIM$(STR$(Counter)) THEN
                IF NOT Counter = SelectedProfile THEN
                    Obj.DrawBtn btnProfile(SelectedProfile), False
                    Obj.DrawBtn btnProfile(Counter), True
                    SelectedProfile = Counter
                    ProfileNamePos = winProfiles.Pos.Left + (winProfiles.Pos.Width / 2) - (Font.GetWidth(ProfileName(SelectedProfile), FontHeading) / 2)
                    Mouse.Hide
                    LINE (winProfiles.Pos.Left + 2, winProfiles.Pos.Top + 150)-(winProfiles.Pos.Left + winProfiles.Pos.Width - 2, winProfiles.Pos.Top + 166), ClrWindow, BF
                    Mouse.Show
                    Font.Print ProfileName(SelectedProfile), ProfileNamePos, winProfiles.Pos.Top + 154, ClrWindowText, FontHeading
                    DO WHILE Mouse.Clicked: LOOP
                END IF
            END IF
        NEXT

        IF Key$ = "c" OR Key$ = CHR$(13) OR Obj.BtnClick(btnContinue) THEN
            DIM FileHandle
            FileHandle = FREEFILE
            OPEN Sys.Path + "DATA\TEMP\PROFILE.TMP" FOR OUTPUT AS #FileHandle
            PRINT #FileHandle, "PROFILE" + LTRIM$(STR$(SelectedProfile))
            CLOSE #FileHandle

            File.CfgWrite "DATA\CONFIG\COSTA.CFG", "LastUsedProfile", LTRIM$(STR$(SelectedProfile))

            Desk.ProfileSelect = "PROFILE" + LTRIM$(STR$(SelectedProfile))
            EXIT FUNCTION
        END IF

        IF Key$ = "e" OR Obj.BtnClick(btnEdit) THEN
            Desk.ProfileEdit SelectedProfile
            GOSUB TopOfProfile
        END IF

    LOOP

END FUNCTION

