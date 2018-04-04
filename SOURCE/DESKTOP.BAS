OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Desk.GetDailyTip () AS STRING
DECLARE SUB Calc.Main ()
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
DECLARE SUB Desk.RunDialog ()
DECLARE SUB Tic.Main ()
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

REDIM SHARED DeskLink(0 TO 0) AS DeskLinkType

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
    
    SCREEN 0
    COLOR 7, 0
    CLS
    PRINT
    PRINT "  " + appName
    PRINT "  Coded in 2004-" + appYear + " by Jacob Palm"
    PRINT
    PRINT "  Released under the MIT License"
    PRINT
    Sys.Delay 1.9
END IF

STACK 5120

CALL Sys.Load

Desk.Main

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
  Font.Print "thanks to those people who where part of the QB", 168, 307, 0, 2
  Font.Print "GUI community - every one of you.", 168, 321, 0, 2


  DO: LOOP WHILE Mouse.Clicked
  DO

    Key$ = LCASE$(INKEY$)
    IF Obj.BtnClick(btnClose) OR Key$ = CHR$(13) OR Key$ = CHR$(27) OR Key$ = "c" THEN EXIT SUB

  LOOP
  
END SUB

SUB Desk.DrawDesktop ()
   
  'All desklinks will always have an imagefile. Use this to check if any
  'desklinks exist
  IF RTRIM$(DeskLink(0).ImageFile) = "" OR DeskLink(0).Caption = STRING$(25, 0) THEN EXIT SUB

  DIM ShowDesc, ShowTarget
  DIM imgDeskLinkIcon AS ImageType
  DIM TargetLink

  'Draw desklinks one by one, using imgDeskLinkIcon to draw the imagefile of
  'each desklink
  FOR TargetLink = 0 TO UBOUND(DeskLink)

    imgDeskLinkIcon.ImageFile = DeskLink(TargetLink).ImageFile
    imgDeskLinkIcon.Pos.Left = DeskLink(TargetLink).Left
    imgDeskLinkIcon.Pos.Top = DeskLink(TargetLink).Top

    Obj.DrawImg imgDeskLinkIcon

    ShowDesc = VAL(File.CfgRead("DATA\CONFIG\DESKTOP.CFG", "ShowLinkDescriptions", "1"))
    ShowTarget = VAL(File.CfgRead("DATA\CONFIG\DESKTOP.CFG", "ShowLinkTargetFiles", "1"))

    'Description (caption) and target file
    IF ShowDesc = 1 THEN
    
        IF ShowTarget = 1 THEN
            Font.Print DeskLink(TargetLink).Caption, DeskLink(TargetLink).Left + 38, DeskLink(TargetLink).Top + 4, ClrDesktopText, 1
            IF NOT LEFT$(DeskLink(TargetLink).Path, 1) = CHR$(13) THEN
                Font.Print LCASE$(DeskLink(TargetLink).Filename), DeskLink(TargetLink).Left + 38, DeskLink(TargetLink).Top + 18, ClrDesktopText, 2
            ELSE
                Font.Print "Built-in", DeskLink(TargetLink).Left + 38, DeskLink(TargetLink).Top + 18, ClrDesktopText, 2
            END IF
        ELSE
            Font.Print DeskLink(TargetLink).Caption, DeskLink(TargetLink).Left + 16 - (Font.GetWidth(RTRIM$(DeskLink(TargetLink).Caption), FontNormal) / 2), DeskLink(TargetLink).Top + 38, ClrDesktopText, FontNormal
        END IF

    END IF
                 
  NEXT
  
END SUB

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

FUNCTION Desk.GetDailyTip () AS STRING

    ON LOCAL ERROR GOTO DailyTipError

    DIM TipHandle, TipCount
    DIM DailyTips() AS STRING
    DIM TipToShow AS STRING
    DIM PipePos

    TipCount = 0
    REDIM DailyTips(1 TO 1) AS STRING

    TipHandle = FREEFILE
    OPEN Sys.Path + "DATA\DAILYTIP.DAT" FOR INPUT AS #TipHandle
    DO WHILE NOT EOF(TipHandle)
        TipCount = TipCount + 1
        REDIM PRESERVE DailyTips(1 TO TipCount) AS STRING
        LINE INPUT #TipHandle, DailyTips(TipCount)
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
        
        IF AllIcons(IconCount) = RTRIM$(DeskLink(TargetLink).ImageFile) THEN CurrentIcon = IconCount

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
  txtFilenameText = RTRIM$(DeskLink(TargetLink).Filename)
  txtParamsText = RTRIM$(DeskLink(TargetLink).Parameters)
  txtPathText = RTRIM$(DeskLink(TargetLink).Path)
  txtLinkCaptText = RTRIM$(DeskLink(TargetLink).Caption)
  imgIcon.ImageFile = DeskLink(TargetLink).ImageFile
  chkPauseOnExit.Checked = DeskLink(TargetLink).PauseOnExit
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
      DeskLink(TargetLink).Caption = RTRIM$(txtLinkCaptText)
      DeskLink(TargetLink).Filename = RTRIM$(txtFilenameText)
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

' Launches a specific desktop link. It first checks if the link is internal,
' and launces the internal program if it is.
' Otherwise, it launches the external program.
SUB Desk.LinkLaunch (TargetLink AS INTEGER)

    DIM TargetPath AS STRING
    DIM FileToOpen AS STRING

    TargetPath = RTRIM$(DeskLink(TargetLink).Path)

    SELECT CASE TargetPath
        CASE CHR$(13) + "TICTAC"
            Tic.Main
        CASE CHR$(13) + "CONFIG"
            Conf.Main
        CASE CHR$(13) + "TEXTVIEW"
            TView.Main ""
        CASE CHR$(13) + "CALC"
            Calc.Main
        CASE ELSE
            FileToOpen = File.Run(RTRIM$(DeskLink(TargetLink).Filename), RTRIM$(DeskLink(TargetLink).Parameters), RTRIM$(DeskLink(TargetLink).Path), DeskLink(TargetLink).PauseOnExit)
            IF LEN(FileToOpen) > 0 THEN TView.Main FileToOpen
    END SELECT

END SUB

SUB Desk.LinkLoad ()
  
    DIM LinkCount, LinkLoad, FileHandle
    FileHandle = FREEFILE

    OPEN Sys.Path + "DATA\CONFIG\DESKLINK.DAT" FOR BINARY AS #FileHandle
    IF NOT LOF(FileHandle) = 0 THEN GET #FileHandle, , LinkCount

    IF LinkCount = 0 THEN
        CLOSE #FileHandle
        Desk.LinkReset
        EXIT SUB
    END IF
    
    REDIM DeskLink(0 TO LinkCount - 1) AS DeskLinkType

    FOR LinkLoad = 0 TO LinkCount - 1

        GET #FileHandle, , DeskLink(LinkLoad)

    NEXT
    
    CLOSE #FileHandle

END SUB

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
  
  DoAnimations = VAL(File.CfgRead("DATA\CONFIG\COSTA.CFG", "Animations", "1"))
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

            IF LEFT$(DeskLink(TargetLink).Path, 1) = CHR$(13) THEN
                DidEdit = Sys.MsgBox("This link cannot be customized", "This link points to a built-in program and" + CHR$(13) + "cannot be customized.", msgInfo)
                EXIT SUB
            END IF

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
            Mouse.Driver 7, 0, DeskLink(TargetLink).Left + 16, DeskLink(TargetLink).Left + 16
            Mouse.Driver 7, 0, 0, 640
            Mouse.Driver 8, 0, DeskLink(TargetLink).Top + 16, DeskLink(TargetLink).Top + 16
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

            IF LEFT$(DeskLink(TargetLink).Path, 1) = CHR$(13) THEN
                Mouse.Hide
                PUT (x1, y1), BehindMenu, PSET
                Mouse.Show
                DidEdit = Sys.MsgBox("This link cannot be removed", "This link points to a built-in program and" + CHR$(13) + "cannot be removed.", msgInfo)
                EXIT SUB
            END IF
            
            IF File.CfgRead("DATA\CONFIG\DESKTOP.CFG", "ConfirmLinkDelete", "1") = "1" THEN
                Mouse.Hide
                PUT (x1, y1), BehindMenu, PSET
                Mouse.Show
                DoDelete = Sys.MsgBox("Remove desktop link", "This will permanently delete this" + CHR$(13) + "desktop link. Are you sure?", msgQuest)
            ELSE
                DoDelete = True
            END IF

            IF DoDelete THEN
                DeskLink(TargetLink).Caption = ""
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

  DeskLink(TargetLink).Left = LastX - 16
  DeskLink(TargetLink).Top = LastY - 16

  Desk.LinkSave

  DO: LOOP WHILE Mouse.Clicked
END SUB

'Resets all desk icons, by recreating the array as default
SUB Desk.LinkReset ()

    REDIM DeskLink(0 TO 7) AS DeskLinkType

    DeskLink(0).Caption = "Tic Tac Toe"
    DeskLink(0).Filename = "(accessory)"
    DeskLink(0).Path = CHR$(13) + "TICTAC"
    DeskLink(0).ImageFile = "TICTAC"
    DeskLink(0).Left = 15
    DeskLink(0).Top = 298

    DeskLink(1).Caption = "Text Viewer"
    DeskLink(1).Filename = "(accessory)"
    DeskLink(1).Path = CHR$(13) + "TEXTVIEW"
    DeskLink(1).ImageFile = "DOCUMENT"
    DeskLink(1).Left = 15
    DeskLink(1).Top = 343

    DeskLink(2).Caption = "Calculator"
    DeskLink(2).Filename = "(accessory)"
    DeskLink(2).Path = CHR$(13) + "CALC"
    DeskLink(2).ImageFile = "CALC"
    DeskLink(2).Left = 15
    DeskLink(2).Top = 388

    DeskLink(3).Caption = "Icon Editor"
    DeskLink(3).Filename = "ICONEDIT.EXE"
    DeskLink(3).Path = appEnviron + "\"
    DeskLink(3).ImageFile = "PAINT"
    DeskLink(3).Left = 15
    DeskLink(3).Top = 433

    DeskLink(4).Caption = "DOS-prompt"
    DeskLink(4).Filename = "COMMAND.COM"
    DeskLink(4).ImageFile = "DOSPROG"
    DeskLink(4).PauseOnExit = True
    DeskLink(4).Left = 480
    DeskLink(4).Top = 45

    DeskLink(5).Caption = "What's new?"
    DeskLink(5).Filename = "DOCS\CHANGES.TXT"
    DeskLink(5).Path = appEnviron + "\"
    DeskLink(5).ImageFile = "NEWSPAPE"
    DeskLink(5).Left = 480
    DeskLink(5).Top = 342

    DeskLink(6).Caption = "User's guide"
    DeskLink(6).Filename = "DOCS\HELP.TXT"
    DeskLink(6).Path = appEnviron + "\"
    DeskLink(6).ImageFile = "HELP"
    DeskLink(6).Left = 480
    DeskLink(6).Top = 388

    DeskLink(7).Caption = "Configuration"
    DeskLink(7).Filename = "(accessory)"
    DeskLink(7).Path = CHR$(13) + "CONFIG"
    DeskLink(7).ImageFile = "CONFIG"
    DeskLink(7).Left = 480
    DeskLink(7).Top = 433

    Desk.LinkSave

    DIM ResetMsg
    ResetMsg = Sys.MsgBox("Desktop links reset to default", "The file in which Costa stores the configuration for desktop links, DESKLINK.DAT," + CHR$(13) + "was not found." + CHR$(13) + CHR$(13) +  _
"A new file has been automatically created, but any custom links will need to be" + CHR$(13) + "created again manually.", msgError)

END SUB

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


    'Save
    DIM LinkCount, LinkSave, FileHandle
    FOR LinkSave = 0 TO UBOUND(DeskLink)
        IF NOT RTRIM$(DeskLink(LinkSave).Caption) = "" AND NOT DeskLink(LinkSave).Caption = STRING$(25, 0) THEN
            LinkCount = LinkCount + 1
        END IF
    NEXT
    
    FileHandle = FREEFILE
    IF File.Exists(Sys.Path + "DATA\CONFIG\DESKLINK.DAT") THEN KILL Sys.Path + "DATA\CONFIG\DESKLINK.DAT"
    OPEN Sys.Path + "DATA\CONFIG\DESKLINK.DAT" FOR BINARY AS #FileHandle
    PUT #FileHandle, , LinkCount

    IF LinkCount = 0 THEN CLOSE #FileHandle: EXIT SUB

    FOR LinkSave = 0 TO UBOUND(DeskLink)

        IF NOT RTRIM$(DeskLink(LinkSave).Caption) = "" AND NOT DeskLink(LinkSave).Caption = STRING$(25, 0) THEN

            PUT #FileHandle, , DeskLink(LinkSave)

        END IF
    NEXT

    CLOSE #FileHandle

END SUB

SUB Desk.Main ()

  DIM btnAddLink AS ButtonType, btnRunCmd AS ButtonType
  DIM btnAboutCosta AS ButtonType, btnExitCosta AS ButtonType
  DIM SlidePos, DelayFixer, ShowLinkMenu, ShowAnimations

  Obj.SetSize btnAddLink.Pos, 3, 2, 92, 22
  btnAddLink.Caption = "Add link": btnAddLink.HotKey = 5
  Obj.SetSize btnRunCmd.Pos, 102, 2, 92, 22
  btnRunCmd.Caption = "Execute": btnRunCmd.HotKey = 2
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
  IF VAL(File.CfgRead("DATA\CONFIG\COSTA.CFG", "TipOfTheDay", "1")) = 1 THEN

    'Only show a tip if this is the first time Costa is started today
    IF NOT File.CfgRead("DATA\CONFIG\COSTA.CFG", "TipLastShown", "") = STR$(DAY(NOW)) + STR$(MONTH(NOW)) THEN

        DIM showTip, TipOfTheDay AS STRING
        TipOfTheDay = Desk.GetDailyTip
        Mouse.Show

        IF LEN(TipOfTheDay) THEN
            showTip = Sys.MsgBox("Did you know?", TipOfTheDay, msgTip)
        ELSE
            showTip = Sys.MsgBox("Could not read daily tips", "Could not read daily tips from " + Sys.Path + "DATA\DAILYTIPS.DAT." + CHR$(13) + "Make sure this file exists, and isn't corrupted.", msgError)
        END IF

        Mouse.Hide
        File.CfgWrite "DATA\CONFIG\COSTA.CFG", "TipLastShown", STR$(DAY(NOW)) + STR$(MONTH(NOW))
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
              GOSUB SlideUp
              IF ClickedB = mbRight THEN
                'If the right mouse button was clicked, show the menu
                IF NOT TabCheck = -1 THEN
                    Mouse.Hide
                    LINE (DeskLink(TabCheck).Left - 3, DeskLink(TabCheck).Top - 3)-(DeskLink(TabCheck).Left + 35, DeskLink(TabCheck).Top + 35), ClrDesktop, BF
                    Mouse.Show
                    Obj.DrawImg imgTab
                    TabCheck = -1
                END IF

                Desk.LinkMenu DeskLinkCheck, ClickedX, ClickedY
              ELSE
                'Depending on the configuration a left click on a link
                'will either open/run the targetfile or show the menu
                ShowLinkMenu = VAL(File.CfgRead("DATA\CONFIG\DESKTOP.CFG", "LinkMenuOnLeftClick", "1"))
                IF ShowLinkMenu = 1 THEN
                    IF NOT TabCheck = -1 THEN
                        Mouse.Hide
                        LINE (DeskLink(TabCheck).Left - 3, DeskLink(TabCheck).Top - 3)-(DeskLink(TabCheck).Left + 35, DeskLink(TabCheck).Top + 35), ClrDesktop, BF
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
            REDIM PRESERVE DeskLink(0 TO UBOUND(DeskLink) + 1) AS DeskLinkType
            
            DeskLink(UBOUND(DeskLink)).Caption = "Unnamed link"
            DeskLink(UBOUND(DeskLink)).Filename = ""
            DeskLink(UBOUND(DeskLink)).Path = ""
            DeskLink(UBOUND(DeskLink)).Parameters = ""
            DeskLink(UBOUND(DeskLink)).ImageFile = "PROGRAM"
            DeskLink(UBOUND(DeskLink)).Left = 25
            DeskLink(UBOUND(DeskLink)).Top = 53

            GOSUB SlideUp
            Sys.VGASave "DESKTOP"
            Desk.LinkDialog UBOUND(DeskLink), DidEdit, True

            IF DidEdit THEN
                TabCheck = -1
                Desk.LinkLoad
                Mouse.Hide
                LINE (0, 29)-(639, 479), ClrDesktop, BF
                Desk.DrawDesktop
                Mouse.Show
            ELSE
                REDIM PRESERVE DeskLink(0 TO UBOUND(DeskLink) - 1) AS DeskLinkType
                Sys.VGALoad "DESKTOP"
            END IF

            GOSUB SlideDown
        END IF

        IF Key$ = "x" THEN
            GOSUB SlideUp
            DIM FileToRun AS STRING
            FileToRun = Sys.InputBox("Execute program or command", "You can also use this dialog to open any file" + CHR$(13) + "associated with a program (like README.TXT).", "RUNPROG", "C:\")
            IF LEN(FileToRun) AND NOT FileToRun = "C:\" THEN
                DIM RunFile AS STRING
                RunFile = File.Run(FileToRun, "", "", True)
                IF LEN(RunFile) > 0 THEN TView.Main RunFile
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

        IF Key$ = "e" OR Key$ = CHR$(27) THEN
            GOSUB SlideUp

            DIM DoExit
            IF File.CfgRead("DATA\CONFIG\COSTA.CFG", "ConfirmExit", "1") = "1" THEN
                DoExit = Sys.MsgBox("Exit " + appName, "This will exit Costa and return you to the DOS" + CHR$(13) + "prompt. Are you sure?", msgQuest)
            ELSE
                DoExit = True
            END IF

            IF DoExit = True THEN
                Mouse.Hide
                Sys.Delay .8
                Desk.ExitGUI
            END IF

            GOSUB SlideDown
        END IF

        IF Key$ = CHR$(9) OR Key$ = CHR$(0) + CHR$(15) THEN
            IF TabCheck > -1 THEN
                Mouse.Hide
                LINE (DeskLink(TabCheck).Left - 3, DeskLink(TabCheck).Top - 3)-(DeskLink(TabCheck).Left + 35, DeskLink(TabCheck).Top + 35), ClrDesktop, BF
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
                btnTab.Pos.Width = 38: btnTab.Pos.Height = 38
                Obj.DrawBtn btnTab, False
                Obj.DrawImg imgTab
                Mouse.Show
            END IF
        END IF

        IF (Key$ = CHR$(13) OR Key$ = CHR$(32)) AND TabCheck > -1 THEN
            Mouse.Hide
            LINE (DeskLink(TabCheck).Left - 3, DeskLink(TabCheck).Top - 3)-(DeskLink(TabCheck).Left + 35, DeskLink(TabCheck).Top + 35), ClrDesktop, BF
            Obj.DrawImg imgTab
            Mouse.Show

            IF Key$ = CHR$(13) THEN GOSUB SlideUp: Desk.LinkMenu TabCheck, DeskLink(TabCheck).Left + 15, DeskLink(TabCheck).Top + 15: GOSUB SlideDown
            TabCheck = -1
        END IF

      END IF
    
  LOOP

EXIT SUB

SlideDown:
  Mouse.Hide
  ShowAnimations = VAL(File.CfgRead("DATA\CONFIG\COSTA.CFG", "Animations", "1"))
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
  Obj.DrawBtn btnExitCosta, False
RETURN

SlideUp:
  Mouse.Hide
  DelayFixer = 0
  ShowAnimations = VAL(File.CfgRead("DATA\CONFIG\COSTA.CFG", "Animations", "1"))
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

