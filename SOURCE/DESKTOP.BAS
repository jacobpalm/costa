OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Desk.GetDailyTip () AS STRING
DECLARE SUB Conf.Main ()
DECLARE SUB Desk.AboutBox ()
DECLARE SUB Desk.DrawDesktop ()
DECLARE SUB Desk.ExitGUI ()
DECLARE SUB Desk.LinkDialog (TargetLink%, DidEdit%, NewLink%)
DECLARE SUB Desk.LinkLaunch (TargetLink AS INTEGER)
DECLARE SUB Desk.LinkLoad ()
DECLARE SUB Desk.LinkMenu (TargetLink%)
DECLARE SUB Desk.LinkMove (TargetLink%)
DECLARE SUB Desk.LinkReset ()
DECLARE SUB Desk.LinkSave ()
DECLARE SUB Desk.Main ()
DECLARE SUB Desk.ProfileEdit (ProfileNum AS INTEGER)
DECLARE SUB Desk.ProfileSelect ()
DECLARE SUB Desk.RunDialog ()
DECLARE SUB Desk.Run (BYVAL TargetFile AS STRING, BYVAL TargetParameters AS STRING, BYVAL TargetPath AS STRING, PauseOnExit AS INTEGER)
DECLARE SUB Desk.TipOfTheDay ()

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

    'Make sure all directories are present and that no files from previous
    'sessions are present
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
    'Clean temp files of both current and default location, they might not
    'be the same
    KILL Temp.Path + "*.TMP"
    KILL Temp.Path + "*.INT"
    KILL Temp.Path + "*.BLU"
    KILL Temp.Path + "*.RED"
    KILL Temp.Path + "*.GRN"
    KILL Sys.Path + "DATA\TEMP\*.TMP"
    KILL Sys.Path + "DATA\TEMP\*.INT"
    KILL Sys.Path + "DATA\TEMP\*.BLU"
    KILL Sys.Path + "DATA\TEMP\*.RED"
    KILL Sys.Path + "DATA\TEMP\*.GRN"

    ON ERROR GOTO 0

    DIM FileHandle
    FileHandle = FREEFILE
    OPEN Temp.Path + "RUNSTAT.TMP" FOR OUTPUT AS #FileHandle
    PRINT #FileHandle, "1"
    CLOSE #FileHandle
END IF

STACK 5120

CALL Sys.Load

IF ProfileID < 1 OR ProfileID > 5 THEN

    'If ProfileID is not set, then we need to use the last used one, or show
    'profile selection dialog based on settings
    IF SystemSettings.UseLastProfile THEN

        IF SystemSettings.LastUsedProfile > 0 AND SystemSettings.LastUsedProfile < 5 THEN
            ProfileID = SystemSettings.LastUsedProfile
        ELSE
            'Invalid value, load default
            ProfileID = 1
            SystemSettings.LastUsedProfile = 1
            Sys.SaveSettings
        END IF
        Sys.LoadProfile SystemSettings.LastUsedProfile
        Sys.LoadTheme

    ELSE
        Desk.ProfileSelect
    END IF

    IF UserSettings.ScreenMode = scrVGA THEN
      scrHeight = 480
      SCREEN 12
    ELSE
      scrHeight = 350
      SCREEN 9
    END IF
    
END IF

ON ERROR RESUME NEXT
OPEN Temp.Path + "PROFILE.TMP" FOR OUTPUT AS #FileHandle
PRINT #FileHandle, ProfileID
CLOSE #FileHandle

CHDRIVE LEFT$(Sys.Path, 1)
CHDIR Sys.Path
ON ERROR GOTO 0

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

  Obj.SetSize winAboutBox.Pos, 156, (scrHeight - 278) / 2, 328, 278
  Obj.SetSize imgLogo.Pos, 168, winAboutBox.Pos.Top + 11, -1, -1
  Obj.SetSize btnClose.Pos, 274, winAboutBox.Pos.Top + 243, 92, 22
  btnClose.Caption = "õClose"

  imgLogo.ImageFile = "LOGO"
  
  IF UserSettings.ScreenMode = scrEGA THEN
    Mouse.Hide
    PCOPY 0, 1
    Mouse.Show
  END IF

  Obj.DrawWin winAboutBox
  Obj.DrawBtn btnClose, False
  
  Font.Print appName, 210, winAboutBox.Pos.Top + 17, 0, 1
  Font.Print "Version " + appVersion, 210, winAboutBox.Pos.Top + 31, 0, 2
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

  Obj.DrawImg imgLogo

  DO: LOOP WHILE Mouse.Clicked
  DO

    Key$ = LCASE$(INKEY$)
    IF Obj.BtnClick(btnClose) OR Key$ = CHR$(13) OR Key$ = CHR$(27) OR Key$ = "c" THEN EXIT DO

  LOOP

  IF UserSettings.ScreenMode = scrEGA THEN
    Mouse.Hide
    PCOPY 1, 0
    Mouse.Show
  ELSE
    Desk.DrawDesktop
  END IF
  
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
  LINE (0, 29)-(639, scrHeight), SystemTheme.Desktop, BF
  
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

    'If screen resolution has been reduced, make sure icons aren't out
    'of vertical view
    IF DeskLink(TargetLink).Top > scrHeight - 32 THEN
      DeskLink(TargetLink).Top = scrHeight - 32
    END IF

    imgDeskLinkIcon.ImageFile = DeskLink(TargetLink).ImageFile
    imgDeskLinkIcon.Pos.Left = DeskLink(TargetLink).Left
    imgDeskLinkIcon.Pos.Top = DeskLink(TargetLink).Top
    
    Obj.DrawImg imgDeskLinkIcon

    'Description (caption) and target file
    IF UserSettings.ShowLinkDescriptions THEN
    
        IF UserSettings.ShowLinkTargetFiles THEN
            Font.Print DeskLink(TargetLink).Caption, DeskLink(TargetLink).Left + 38, DeskLink(TargetLink).Top + 4, SystemTheme.DesktopText, 1
            
            LinkTargetText = LCASE$(DeskLink(TargetLink).Filename)

            'Remove path from string, if present
            DO WHILE INSTR(LinkTargetText, "\")
                LinkTargetText = RIGHT$(LinkTargetText, LEN(LinkTargetText) - INSTR(LinkTargetText, "\"))
            LOOP

            Font.Print LinkTargetText, DeskLink(TargetLink).Left + 38, DeskLink(TargetLink).Top + 18, SystemTheme.DesktopText, 2
        ELSE
            Font.Print DeskLink(TargetLink).Caption, DeskLink(TargetLink).Left + 16 - (Font.GetWidth(RTRIM$(DeskLink(TargetLink).Caption), fontNormal) / 2), DeskLink(TargetLink).Top + 38, SystemTheme.DesktopText, fontNormal
        END IF

    END IF
                 
  NEXT
  
  Mouse.Show

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

    KILL Temp.Path + "*.TMP"
    KILL Temp.Path + "*.INT"
    KILL Temp.Path + "*.BLU"
    KILL Temp.Path + "*.RED"
    KILL Temp.Path + "*.GRN"

    SCREEN 0
    COLOR 7, 0

    'Errorcode 1 makes the COSTA.BAT file exit its loop, thereby exiting
    'Costa
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

  Obj.SetSize ConfWin.Pos, 210, (scrHeight - 336) / 2, 220, 312
  IF UserSettings.ScreenMode = scrEGA THEN
    'Avoid menubar overlap on low resolution
    ConfWin.Pos.Top = (scrHeight - ConfWin.Pos.Height - 28) / 2 + 28
  END IF

  Obj.SetSize frmIconFrame.Pos, 296, ConfWin.Pos.Top + 12, 48, 48
  Obj.SetSize imgIcon.Pos, 304, frmIconFrame.Pos.Top + 8, 32, 32
  Obj.SetSize btnIconPrev.Pos, 262, frmIconFrame.Pos.Top + 13, 22, 22
  Obj.SetSize btnIconNext.Pos, 356, frmIconFrame.Pos.Top + 13, 22, 22

  Obj.SetSize txtLinkCapt.Pos, 222, frmIconFrame.Pos.Top + 73, 196, 19
  Obj.SetSize txtFilename.Pos, 222, txtLinkCapt.Pos.Top + 44, 173, 19
  Obj.SetSize btnBrowse.Pos, 399, txtFilename.Pos.Top, 19, 19
  Obj.SetSize txtParams.Pos, 222, txtFilename.Pos.Top + 44, 196, 19
  Obj.SetSize txtPath.Pos, 222, txtParams.Pos.Top + 44, 196, 19
  Obj.SetSize chkPauseOnExit.Pos, 222, txtPath.Pos.Top + 32, -1, -1
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
    btnOK.Caption = "õAdd link"
  END IF
  btnCancel.Caption = "õCancel"

LinkDialogDraw:
  Obj.DrawWin ConfWin
  Obj.DrawTxt txtLinkCapt, txtLinkCaptText, False
  Obj.DrawBtn btnIconPrev, False
  Obj.DrawFrm frmIconFrame, 15, SystemTheme.Shadow
  Obj.DrawBtn btnIconNext, False
  Obj.DrawTxt txtFilename, txtFileNameText, False
  Obj.DrawBtn btnBrowse, False
  Obj.DrawTxt txtParams, txtParamsText, False
  Obj.DrawTxt txtPath, txtPathText, False
  Obj.DrawChk chkPauseOnExit
  Obj.DrawBtn btnOK, False
  Obj.DrawBtn btnCancel, False
  Font.Print "õDescription (caption):", 222, txtLinkCapt.Pos.Top - 15, SystemTheme.WindowText, 1
  Font.Print "õProgram or DOS command:", 222, txtFilename.Pos.Top - 15, SystemTheme.WindowText, 1
  Font.Print "Paõrameters:", 222, txtParams.Pos.Top - 15, SystemTheme.WindowText, 1
  Font.Print "Paõth (including drive):", 222, txtPath.Pos.Top - 15, SystemTheme.WindowText, 1
  Font.Print "Pause after eõxecution", 242, chkPauseOnExit.Pos.Top + 3, SystemTheme.WindowText, 2
  Mouse.Hide
  LINE (frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2)-(frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2), SystemTheme.Desktop, BF
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
      LINE (frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2)-(frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2), SystemTheme.Desktop, BF
      Mouse.Show
      imgIcon.ImageFile = AllIcons(CurrentIcon)
      Obj.DrawImg imgIcon
    END IF

    IF Obj.BtnClick(btnIconNext) OR Key$ = CHR$(0) + "m" THEN
      IconChanged = True
      CurrentIcon = CurrentIcon + 1
      IF CurrentIcon > UBOUND(AllIcons) THEN CurrentIcon = 0
      Mouse.Hide
      LINE (frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2)-(frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2), SystemTheme.Desktop, BF
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

    TargetPath = RTRIM$(DeskLink(TargetLink).Path)

    Desk.Run RTRIM$(DeskLink(TargetLink).Filename), RTRIM$(DeskLink(TargetLink).Parameters), RTRIM$(DeskLink(TargetLink).Path), DeskLink(TargetLink).PauseOnExit


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
    DIM ResetMsg
    DIM DeskLinkFile AS STRING

    DeskLinkFile = Sys.Path + "DATA\CONFIG\DESKLNK" + LTRIM$(STR$(ProfileID)) + ".DAT"
    FileHandle = FREEFILE

    IF NOT File.Exists(DeskLinkFile) THEN
      Desk.LinkReset
      ResetMsg = Sys.MsgBox("Desktop links reset to default", "The file in which Costa stores the configuration for desktop links, DESKLNK" + LTRIM$(STR$(ProfileID)) + ".DAT," + CHR$(13) + "was not found in this profile." + CHR$(13) + CHR$(13) +  _
"A new file has been automatically created, but any custom links will need to be" + CHR$(13) + "created again manually.", msgError)
      EXIT SUB
    END IF

    OPEN Sys.Path + "DATA\CONFIG\DESKLNK" + LTRIM$(STR$(ProfileID)) + ".DAT" FOR BINARY AS #FileHandle
    IF NOT LOF(FileHandle) = 0 THEN GET #FileHandle, , LinkCount

    'A value of -1 means no icons exists by user choice, so do nothing
    IF LinkCount = -1 THEN
      CLOSE #FileHandle
      REDIM DeskLink(0 TO 0) AS DeskLinkType
      EXIT SUB
    END IF

    'If no links found in file, ask to recreate defaults
    IF LinkCount = 0 THEN
        IF Sys.MsgBox("No desktop links found", "No desktop links were found. Do you wish to recreate the default links?", msgQuest) THEN
          CLOSE #FileHandle
          Desk.LinkReset
        ELSE
          'Setting to -1 and saving will prevent Costa from asking again
          LinkCount = -1
          PUT #FileHandle, 1, LinkCount
          CLOSE #FileHandle
        END IF
        EXIT SUB
    END IF
    
    REDIM DeskLink(0 TO LinkCount - 1) AS DeskLinkType

    FOR LinkLoad = 0 TO LinkCount - 1

        GET #FileHandle, , DeskLink(LinkLoad)

        'If screen resolution has been reduced, make sure icons aren't out
        'of vertical view
        IF DeskLink(LinkLoad).Top > scrHeight - 32 THEN
          DeskLink(LinkLoad).Top = scrHeight - 32
        END IF

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

  Obj.SetSize winLinkMenu.Pos, (640 - 413) / 2, (scrHeight - 165) / 2, 413, 165
  Obj.SetSize btnOpen.Pos, winLinkMenu.Pos.Left + 12, winLinkMenu.Pos.Top + winLinkMenu.Pos.Height - 64, 389, 22
  Obj.SetSize btnCustomize.Pos, btnOpen.Pos.Left, btnOpen.Pos.Top + 30, 92, 22
  Obj.SetSize btnMove.Pos, btnCustomize.Pos.Left + 99, btnCustomize.Pos.Top, 92, 22
  Obj.SetSize btnRemove.Pos, btnMove.Pos.Left + 99, btnCustomize.Pos.Top, 92, 22
  Obj.SetSize btnCancel.Pos, btnRemove.Pos.Left + 99, btnCustomize.Pos.Top, 92, 22
  
  Obj.SetSize imgIcon.Pos, winLinkMenu.Pos.Left + 12, winLinkMenu.Pos.Top + 11, -1, -1
  imgIcon.ImageFile = DeskLink(TargetLink).ImageFile

  btnOpen.Caption = "õOpen"
  btnCustomize.Caption = "Cõustomize"
  btnMove.Caption = "õMove"
  btnRemove.Caption = "õRemove"
  btnCancel.Caption = "õCancel"
  
  IF UserSettings.ScreenMode = scrEGA THEN
    Mouse.Hide
    PCOPY 0, 1
    Mouse.Show
  END IF

  Obj.DrawWin winLinkMenu
  Obj.DrawBtn btnOpen, False
  Obj.DrawBtn btnCustomize, False
  Obj.DrawBtn btnMove, False
  Obj.DrawBtn btnRemove, False
  Obj.DrawBtn btnCancel, False
  Obj.DrawImg imgIcon

  Font.Print DeskLink(TargetLink).Caption, winLinkMenu.Pos.Left + 54, winLinkMenu.Pos.Top + 17, 0, fontHeading
  Font.Print DeskLink(TargetLink).Filename, winLinkMenu.Pos.Left + 54, winLinkMenu.Pos.Top + 31, 0, fontNormal
  Font.Print "Path:", winLinkMenu.Pos.Left + 12, winLinkMenu.Pos.Top + 59, 0, fontNormal
  Font.Print "Parameters:", winLinkMenu.Pos.Left + 12, winLinkMenu.Pos.Top + 76, 0, fontNormal
  
  VIEW SCREEN (winLinkMenu.Pos.Left + 90, winLinkMenu.Pos.Top + 55)-(winLinkMenu.Pos.Left + winLinkMenu.Pos.Width - 12, winLinkMenu.Pos.Top + 90)
  IF LEN(RTRIM$(DeskLink(TargetLink).Path)) THEN
    Font.Print DeskLink(TargetLink).Path, winLinkMenu.Pos.Left + 92, winLinkMenu.Pos.Top + 59, SystemTheme.WindowText, fontNormal
  ELSE
    Font.Print "Unspecified", winLinkMenu.Pos.Left + 92, winLinkMenu.Pos.Top + 59, SystemTheme.WindowText, fontNormal
  END IF
  IF LEN(RTRIM$(DeskLink(TargetLink).Parameters)) THEN
    Font.Print DeskLink(TargetLink).Parameters, winLinkMenu.Pos.Left + 92, winLinkMenu.Pos.Top + 76, SystemTheme.WindowText, fontNormal
  ELSE
    Font.Print "None", winLinkMenu.Pos.Left + 92, winLinkMenu.Pos.Top + 76, SystemTheme.WindowText, fontNormal
  END IF
  VIEW

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
      Desk.LinkLaunch TargetLink
      EXIT SUB
    END IF

    'Configure
    IF Obj.BtnClick(btnCustomize) OR Key$ = "u" THEN
      Desk.LinkDialog TargetLink, DidEdit, False
      IF DidEdit = True THEN RedrawNeeded = True
      EXIT DO
    END IF

    'Move
    IF Obj.BtnClick(btnMove) OR Key$ = "m" THEN

      IF UserSettings.ScreenMode = scrVGA OR RedrawNeeded THEN
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
      IF UserSettings.ConfirmLinkDelete THEN
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

  IF UserSettings.ScreenMode = scrVGA OR RedrawNeeded THEN
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

  DIM LinkIcon(257), LinkIconBack(257)
  DIM LastX, LastY, FlickerX, FlickerY
  DIM KeyX, KeyY
  LastX = DeskLink(TargetLink).Left + 16: LastY = DeskLink(TargetLink).Top + 16
  Mouse.Hide
  GET (LastX - 16, LastY - 16)-(LastX + 15, LastY + 15), LinkIcon
  GET (LastX - 16, LastY - 16)-(LastX + 15, LastY + 15), LinkIconBack

  Mouse.Show
  Mouse.SetPos DeskLink(TargetLink).Left + 16, DeskLink(TargetLink).Top + 16

  DIM Key$
  DO
    Key$ = LCASE$(INKEY$)
    
    IF Key$ = CHR$(27) THEN EXIT SUB
    IF Key$ = CHR$(13) THEN EXIT DO

    IF Key$ = CHR$(0) + "k" THEN
        KeyX = Mouse.X - 15
        KeyY = Mouse.Y
        IF KeyX < 16 THEN KeyX = 16
        IF KeyY < 48 THEN KeyY = 48
        Mouse.SetPos KeyX, KeyY
    END IF
    IF Key$ = CHR$(0) + "m" THEN
        KeyX = Mouse.X + 15
        KeyY = Mouse.Y
        IF KeyX > 624 THEN KeyX = 624
        IF KeyY > scrHeight - 16 THEN KeyY = scrHeight - 16
        Mouse.SetPos KeyX, KeyY
    END IF
    IF Key$ = CHR$(0) + "h" THEN
        KeyY = Mouse.Y - 15
        KeyX = Mouse.X
        IF KeyY < 46 THEN KeyY = 46
        IF KeyX < 16 THEN KeyX = 16
        Mouse.SetPos KeyX, KeyY
    END IF
    IF Key$ = CHR$(0) + "p" THEN
        KeyY = Mouse.Y + 15
        KeyX = Mouse.X
        IF KeyY > scrHeight - 16 THEN KeyY = scrHeight - 16
        IF KeyX > 624 THEN KeyX = 624
        Mouse.SetPos KeyX, KeyY
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
      IF LastY < 48 THEN LastY = 48
      IF LastX > 624 THEN LastX = 624
      IF LastY > scrHeight - 16 THEN LastY = scrHeight - 16
      GET (LastX - 16, LastY - 16)-(LastX + 15, LastY + 15), LinkIconBack
      PUT (LastX - 16, LastY - 16), LinkIcon, PSET
      Mouse.Show
    END IF
  LOOP UNTIL Mouse.Clicked

  DeskLink(TargetLink).Left = LastX - 16
  DeskLink(TargetLink).Top = LastY - 16

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

    REDIM DeskLink(0 TO 7) AS DeskLinkType

    DeskLink(0).Caption = "Tic Tac Toe"
    DeskLink(0).Filename = "TICTAC.EXE"
    DeskLink(0).Path = ""
    DeskLink(0).Parameters = ""
    DeskLink(0).ImageFile = "TICTAC"
    DeskLink(0).Left = 15
    DeskLink(0).Top = 45

    DeskLink(1).Caption = "Text Viewer"
    DeskLink(1).Filename = "TEXTVIEW.EXE"
    DeskLink(1).Path = ""
    DeskLink(1).Parameters = ""
    DeskLink(1).ImageFile = "DOCUMENT"
    DeskLink(1).Left = 15
    DeskLink(1).Top = 90

    DeskLink(2).Caption = "Calculator"
    DeskLink(2).Filename = "CALC.EXE"
    DeskLink(2).Path = ""
    DeskLink(2).Parameters = ""
    DeskLink(2).ImageFile = "CALC"
    DeskLink(2).Left = 15
    DeskLink(2).Top = 135

    DeskLink(3).Caption = "Theme Editor"
    DeskLink(3).Filename = "THMEDIT.EXE"
    DeskLink(3).Path = ""
    DeskLink(3).Parameters = ""
    DeskLink(3).ImageFile = "THEMES"
    DeskLink(3).Left = 15
    DeskLink(3).Top = 180

    DeskLink(4).Caption = "Icon Editor"
    DeskLink(4).Filename = "ICONEDIT.EXE"
    DeskLink(4).Path = ""
    DeskLink(4).Parameters = ""
    DeskLink(4).ImageFile = "PAINT"
    DeskLink(4).Left = 15
    DeskLink(4).Top = 225

    DeskLink(5).Caption = "DOS-prompt"
    DeskLink(5).Filename = "COMMAND.COM"
    DeskLink(5).Path = ""
    DeskLink(5).Parameters = ""
    DeskLink(5).ImageFile = "DOSPROG"
    DeskLink(5).PauseOnExit = True
    DeskLink(5).Left = 480
    DeskLink(5).Top = 45

    DeskLink(6).Caption = "What's new?"
    DeskLink(6).Filename = "DOCS\CHANGES.TXT"
    DeskLink(6).Path = ""
    DeskLink(6).Parameters = ""
    DeskLink(6).ImageFile = "NEWSPAPE"
    DeskLink(6).Left = 480
    DeskLink(6).Top = 90

    DeskLink(7).Caption = "User's guide"
    DeskLink(7).Filename = "DOCS\HELP.TXT"
    DeskLink(7).Path = ""
    DeskLink(7).Parameters = ""
    DeskLink(7).ImageFile = "HELP"
    DeskLink(7).Left = 480
    DeskLink(7).Top = 135

    Desk.LinkSave

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
    IF File.Exists(Sys.Path + "DATA\CONFIG\DESKLNK" + LTRIM$(STR$(ProfileID)) + ".DAT") THEN KILL Sys.Path + "DATA\CONFIG\DESKLNK" + LTRIM$(STR$(ProfileID)) + ".DAT"
    OPEN Sys.Path + "DATA\CONFIG\DESKLNK" + LTRIM$(STR$(ProfileID)) + ".DAT" FOR BINARY AS #FileHandle
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
  DIM btnProfile AS ButtonType, btnConfig AS ButtonType
  
  Obj.SetSize btnAddLink.Pos, 3, 2, 92, 22
  btnAddLink.Caption = "Add õlink"
  Obj.SetSize btnRunCmd.Pos, 102, 2, 92, 22
  btnRunCmd.Caption = "Eõxecute"

  Obj.SetSize btnProfile.Pos, 224, 2, 92, 22
  btnProfile.Caption = "õProfile..."
  Obj.SetSize btnConfig.Pos, 323, 2, 92, 22
  btnConfig.Caption = "õConfig..."

  Obj.SetSize btnAboutCosta.Pos, 446, 2, 92, 22
  btnAboutCosta.Caption = "õAbout..."
  Obj.SetSize btnExitCosta.Pos, 545, 2, 92, 22
  btnExitCosta.Caption = "õExit"

  DIM DeskLinkCheck, ClickedX, ClickedY, ClickedB, DidEdit, Key$
  DIM TabCheck, btnTab AS ButtonType, imgTab AS ImageType
  
  Mouse.Show

  Desk.LinkLoad
  Desk.TipOfTheDay

Desk.RedrawAll:
  TabCheck = -1

  Obj.DrawMenu
  Obj.DrawBtn btnAddLink, False
  Obj.DrawBtn btnRunCmd, False
  Obj.DrawBtn btnProfile, False
  Obj.DrawBtn btnConfig, False
  Obj.DrawBtn btnAboutCosta, False
  Obj.DrawBtn btnExitCosta, False
  Desk.DrawDesktop

  'Clear mouse and keyboard buffer, since DOSBox will sometimes leave data
  DO: LOOP WHILE Mouse.Clicked
  DO: LOOP WHILE LEN(INKEY$)

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

        IF Key$ = "l" THEN
            REDIM PRESERVE DeskLink(0 TO UBOUND(DeskLink) + 1) AS DeskLinkType
            
            DeskLink(UBOUND(DeskLink)).Caption = "Unnamed link"
            DeskLink(UBOUND(DeskLink)).Filename = ""
            DeskLink(UBOUND(DeskLink)).Path = ""
            DeskLink(UBOUND(DeskLink)).Parameters = ""
            DeskLink(UBOUND(DeskLink)).ImageFile = "PROGRAM"
            DeskLink(UBOUND(DeskLink)).Left = 15
            DeskLink(UBOUND(DeskLink)).Top = 45

            IF UserSettings.ScreenMode = scrEGA THEN
              Mouse.Hide
              PCOPY 0, 1
              Mouse.Show
            END IF
            Desk.LinkDialog UBOUND(DeskLink), DidEdit, True

            IF DidEdit OR (NOT UserSettings.ScreenMode AND UserSettings.ScreenMode = scrVGA) THEN
                TabCheck = -1
                Desk.LinkLoad
                Mouse.Hide
                LINE (0, 29)-(639, scrHeight - 1), SystemTheme.Desktop, BF
                Desk.DrawDesktop
                Mouse.Show
            ELSE
                REDIM PRESERVE DeskLink(0 TO UBOUND(DeskLink) - 1) AS DeskLinkType
                IF UserSettings.ScreenMode = scrEGA THEN
                  Mouse.Hide
                  PCOPY 1, 0
                  Mouse.Show
                ELSE
                  Desk.DrawDesktop
                END IF
            END IF

        END IF

        IF Key$ = "x" THEN
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

        IF Key$ = "p" THEN
            Desk.ProfileSelect
            Desk.LinkLoad
            Desk.TipOfTheDay
            GOTO Desk.RedrawAll
        END IF

        IF Key$ = "c" THEN
            Desk.Run "CONFIG.EXE", "", Sys.Path, False
        END IF


        IF Key$ = "e" OR Key$ = CHR$(27) THEN
            DIM DoExit
            IF UserSettings.ConfirmExit THEN
                DoExit = Sys.MsgBox("Exit " + appName, "This will exit Costa and return you to the DOS" + CHR$(13) + "prompt. Are you sure?", msgQuest)
            ELSE
                DoExit = True
            END IF

            IF DoExit = True THEN
                Mouse.Hide
                Desk.ExitGUI
            END IF
        END IF

        'TAB or Shift+TAB
        IF Key$ = CHR$(9) OR Key$ = CHR$(0) + CHR$(15) THEN
            'If there's only one item in the DESKLINK array, and it has no caption
            'then there are no desktop links to cycle
            IF NOT (UBOUND(DeskLink) = 0 AND RTRIM$(DeskLink(0).Caption) = "") THEN
                IF TabCheck > -1 THEN
                    Mouse.Hide
                    LINE (DeskLink(TabCheck).Left - 3, DeskLink(TabCheck).Top - 3)-(DeskLink(TabCheck).Left + 35, DeskLink(TabCheck).Top + 35), SystemTheme.Desktop, BF
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
            LINE (DeskLink(TabCheck).Left - 3, DeskLink(TabCheck).Top - 3)-(DeskLink(TabCheck).Left + 35, DeskLink(TabCheck).Top + 35), SystemTheme.Desktop, BF
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
'          NAME: Desk.ProfileEdit
'    PARAMETERS: ProfileNum - ID of profile to edit, 1-5
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Shows a window allowing user to select icon and name for
'                the user profile
' =========================================================================
SUB Desk.ProfileEdit (ProfileNum AS INTEGER)
    DIM AllIcons() AS STRING
    DIM IconCount AS INTEGER, CurrentIcon AS INTEGER, IconFile AS STRING
    DIM CurrentIconFilename AS STRING

    Sys.ShowLoading

    IconFile = DIR$(Sys.Path + "DATA\IMAGES\*.BSV")
    IconCount = 0
    CurrentIconFilename = RTRIM$(UserSettings.ProfileImage)

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
    winProfEdit.Pos.Top = (scrHeight - winProfEdit.Pos.Height) / 2
    
    Obj.SetSize frmIconFrame.Pos, 296, winProfEdit.Pos.Top + 46, 48, 48
    Obj.SetSize imgIcon.Pos, 304, frmIconFrame.Pos.Top + 8, 32, 32
    Obj.SetSize btnIconPrev.Pos, 262, frmIconFrame.Pos.Top + 14, 22, 22
    Obj.SetSize btnIconNext.Pos, 356, frmIconFrame.Pos.Top + 14, 22, 22
    Obj.SetSize txtProfileName.Pos, 222, winProfEdit.Pos.Top + 128, 196, 19
    Obj.SetSize btnSave.Pos, 229, winProfEdit.Pos.Top + 174, 84, 22
    Obj.SetSize btnCancel.Pos, 326, winProfEdit.Pos.Top + 174, 84, 22

    txtProfileName.MaxLen = 25
    txtProfileNameText = RTRIM$(UserSettings.ProfileName)
    btnIconPrev.Caption = "<"
    btnIconNext.Caption = ">"
    btnSave.Caption = "õSave"
    btnCancel.Caption = "õCancel"
    imgIcon.ImageFile = AllIcons(CurrentIcon)

    Obj.DrawWin winProfEdit
    Obj.DrawBtn btnIconPrev, False
    Obj.DrawFrm frmIconFrame, 15, SystemTheme.Shadow
    Obj.DrawBtn btnIconNext, False
    Obj.DrawTxt txtProfileName, txtProfileNameText, False
    Obj.DrawBtn btnSave, False
    Obj.DrawBtn btnCancel, False
    Font.Print "õName:", 222, winProfEdit.Pos.Top + 114, SystemTheme.WindowText, 1
    Obj.DrawImg imgIcon

    DIM Key$
    DO
        Key$ = LCASE$(INKEY$)

        IF Obj.BtnClick(btnIconPrev) OR Key$ = CHR$(0) + "k" THEN
          CurrentIcon = CurrentIcon - 1
          IF CurrentIcon < 0 THEN CurrentIcon = UBOUND(AllIcons)
          Mouse.Hide
          LINE (frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2)-(frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2), SystemTheme.Window, BF
          Mouse.Show
          imgIcon.ImageFile = AllIcons(CurrentIcon)
          Obj.DrawImg imgIcon
        END IF

        IF Obj.BtnClick(btnIconNext) OR Key$ = CHR$(0) + "m" THEN
          CurrentIcon = CurrentIcon + 1
          IF CurrentIcon > UBOUND(AllIcons) THEN CurrentIcon = 0
          Mouse.Hide
          LINE (frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2)-(frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2), SystemTheme.Window, BF
          Mouse.Show
          imgIcon.ImageFile = AllIcons(CurrentIcon)
          Obj.DrawImg imgIcon
        END IF

        IF Obj.TxtClick(txtProfileName) OR Key$ = "n" THEN Obj.EditTxt txtProfileName, txtProfileNameText

        IF Obj.BtnClick(btnSave) OR Key$ = CHR$(13) OR Key$ = "s" THEN
            UserSettings.ProfileName = LTRIM$(RTRIM$(txtProfileNameText))
            UserSettings.ProfileImage = AllIcons(CurrentIcon)
            Sys.SaveProfile ProfileNum
            EXIT DO
        END IF

        IF Obj.BtnClick(btnCancel) OR Key$ = CHR$(27) OR Key$ = "c" THEN
            EXIT DO
        END IF

    LOOP

END SUB

' =========================================================================
'          NAME: Desk.ProfileSelect()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Shows a window, allowing the user to choose between one
'                of the five user profiles Costa offers
' =========================================================================
SUB Desk.ProfileSelect ()
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

    UserSettings.ThemeFile = "DEFAULT"
    Sys.LoadTheme
    
    winProfiles.Pos.Width = 338
    winProfiles.Pos.Height = 196
    winProfiles.Pos.Left = (640 - winProfiles.Pos.Width) / 2
    winProfiles.Pos.Top = (scrHeight - winProfiles.Pos.Height) / 2
    
    Obj.SetSize btnProfile(1).Pos, winProfiles.Pos.Left + 18, winProfiles.Pos.Top + 66, 46, 46
    Obj.SetSize btnProfile(2).Pos, winProfiles.Pos.Left + 82, winProfiles.Pos.Top + 66, 46, 46
    Obj.SetSize btnProfile(3).Pos, winProfiles.Pos.Left + 146, winProfiles.Pos.Top + 66, 46, 46
    Obj.SetSize btnProfile(4).Pos, winProfiles.Pos.Left + 210, winProfiles.Pos.Top + 66, 46, 46
    Obj.SetSize btnProfile(5).Pos, winProfiles.Pos.Left + 274, winProfiles.Pos.Top + 66, 46, 46
    btnProfile(1).Transparent = True
    btnProfile(2).Transparent = True
    btnProfile(3).Transparent = True
    btnProfile(4).Transparent = True
    btnProfile(5).Transparent = True

    Obj.SetSize btnEdit.Pos, winProfiles.Pos.Left + 18, winProfiles.Pos.Top + winProfiles.Pos.Height - 39, 80, 22
    btnEdit.Caption = "õEdit..."

    Obj.SetSize btnContinue.Pos, winProfiles.Pos.Left + winProfiles.Pos.Width - 98, winProfiles.Pos.Top + winProfiles.Pos.Height - 39, 80, 22
    btnContinue.Caption = "õContinue"
    
    SelectedProfile = SystemSettings.LastUsedProfile
    IF SelectedProfile < 1 OR SelectedProfile > 5 THEN SelectedProfile = 1

TopOfProfile:
    FOR Counter = 1 TO 5
        Sys.LoadProfile Counter
        ProfileName(Counter) = RTRIM$(UserSettings.ProfileName)
        imgProfile(Counter).ImageFile = RTRIM$(UserSettings.ProfileImage)
    NEXT

    Mouse.Hide
    LINE (0, 0)-(639, scrHeight - 1), SystemTheme.Desktop, BF
    Mouse.Show
    
    Obj.DrawWin winProfiles
    Font.Print "Please select a profile from which your desktop,", winProfiles.Pos.Left + 14, winProfiles.Pos.Top + 18, SystemTheme.WindowText, fontNormal
    Font.Print "theme and other customizations will be loaded.", winProfiles.Pos.Left + 14, winProfiles.Pos.Top + 32, SystemTheme.WindowText, fontNormal

    IF SelectedProfile < 1 OR SelectedProfile > 5 THEN
        SelectedProfile = 1
    END IF

    ProfileNamePos = winProfiles.Pos.Left + (winProfiles.Pos.Width / 2) - (Font.GetWidth(ProfileName(SelectedProfile), fontHeading) / 2)
    Font.Print ProfileName(SelectedProfile), ProfileNamePos, winProfiles.Pos.Top + 136, SystemTheme.WindowText, fontHeading

    FOR Counter = 1 TO 5
        IF Counter = SelectedProfile THEN
            Obj.DrawBtn btnProfile(Counter), True
        ELSE
            Obj.DrawBtn btnProfile(Counter), False
        END IF
        imgProfile(Counter).Pos.Top = btnProfile(Counter).Pos.Top + 7
        imgProfile(Counter).Pos.Left = btnProfile(Counter).Pos.Left + 7
    NEXT

    Obj.DrawBtn btnContinue, False
    Obj.DrawBtn btnEdit, False

    FOR Counter = 1 TO 5
      Obj.DrawImg imgProfile(Counter)
    NEXT
             
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
                    ProfileNamePos = winProfiles.Pos.Left + (winProfiles.Pos.Width / 2) - (Font.GetWidth(ProfileName(SelectedProfile), fontHeading) / 2)
                    Mouse.Hide
                    LINE (winProfiles.Pos.Left + 7, winProfiles.Pos.Top + 132)-(winProfiles.Pos.Left + winProfiles.Pos.Width - 7, winProfiles.Pos.Top + 148), SystemTheme.Window, BF
                    Mouse.Show
                    Font.Print ProfileName(SelectedProfile), ProfileNamePos, winProfiles.Pos.Top + 136, SystemTheme.WindowText, fontHeading
                    DO WHILE Mouse.Clicked: LOOP
                END IF
            END IF
        NEXT

        IF Key$ = "c" OR Key$ = CHR$(13) OR Obj.BtnClick(btnContinue) THEN
            DIM FileHandle
            FileHandle = FREEFILE
            OPEN Temp.Path + "PROFILE.TMP" FOR OUTPUT AS #FileHandle
            PRINT #FileHandle, SelectedProfile
            CLOSE #FileHandle

            ProfileID = SelectedProfile
            SystemSettings.LastUsedProfile = SelectedProfile
            Sys.SaveSettings
            Sys.LoadProfile SelectedProfile
            Sys.LoadTheme

            Mouse.Hide
            IF UserSettings.ScreenMode = scrVGA THEN
              scrHeight = 480
              SCREEN 12
            ELSE
              scrHeight = 350
              SCREEN 9
            END IF
            Mouse.Show
            
            EXIT SUB
        END IF

        IF Key$ = "e" OR Obj.BtnClick(btnEdit) THEN
            Sys.LoadProfile SelectedProfile
            Desk.ProfileEdit SelectedProfile
            GOSUB TopOfProfile
        END IF

    LOOP

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

  DO: LOOP WHILE LEN(INKEY$)
  END 2

END SUB

SUB Desk.TipOfTheDay ()

  'Check if "Tip of the Day" should be shown
  IF UserSettings.TipOfTheDay THEN
    'Only show a tip if this is the first time Costa is started today
    IF NOT UserSettings.TipLastShown = DAY(NOW) THEN

        DIM showTip
        DIM TipOfTheDay AS STRING

        Mouse.Hide
        LINE (0, 0)-(639, scrHeight - 1), SystemTheme.Desktop, BF
        Mouse.Show

        TipOfTheDay = Desk.GetDailyTip
        
        IF LEN(TipOfTheDay) THEN
            showTip = Sys.MsgBox("Did you know?", TipOfTheDay, msgTip)
        ELSE
            showTip = Sys.MsgBox("Could not read daily tips", "Could not read daily tips from " + Sys.Path + "DATA\DAILYTIPS.DAT." + CHR$(13) + "Make sure this file exists, and isn't corrupted.", msgError)
        END IF

        UserSettings.TipLastShown = DAY(NOW)
        Sys.SaveProfile ProfileID
    END IF
  END IF

END SUB

