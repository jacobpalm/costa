OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Conf.ConfAssoc ()
DECLARE FUNCTION Conf.ConfMisc ()
DECLARE FUNCTION Conf.ConfTheme ()
DECLARE SUB Conf.Main ()
DECLARE SUB Conf.RestoreAssoc ()
DECLARE SUB Conf.SaveAssoc (FileType AS STRING, Command AS STRING)

CONST LaunchMenu = -2
CONST LaunchNoMore = -1
CONST LaunchAssoc = 1
CONST LaunchMisc = 2
CONST LaunchTheme = 3

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

STACK 5120

Sys.Load

Conf.Main

' =========================================================================
'          NAME: Conf.ConfAssoc()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: CONFIG.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: UI and logic for file association editor
' =========================================================================
FUNCTION Conf.ConfAssoc ()

    IF Setting.AssignFileTypes = False THEN
        IF Sys.MsgBox("File associations disabled", "File associations are currently disabled." + CHR$(13) + "Do you want to enable this feature?", msgQuest) = True THEN
            Setting.AssignFileTypes = True
            Sys.SaveSettings
        ELSE
            Conf.ConfAssoc = LaunchMenu
            EXIT FUNCTION
        END IF
    END IF

    IF NOT File.Exists(Sys.Path + "\DATA\CONFIG\FILETYPE.DAT") THEN
      Conf.RestoreAssoc
    END IF

    DIM txtFileType AS TextboxType, txtFileTypeText AS STRING
    DIM txtOpenWith AS TextboxType, txtOpenWithText AS STRING
    DIM btnSave AS ButtonType, btnClose AS ButtonType, btnDisable AS ButtonType
    DIM btnThemes AS ButtonType, btnFileAssoc AS ButtonType, btnMisc AS ButtonType

    DIM OldFileType AS STRING, SaveVar
    DIM Key$
    
    Obj.SetSize txtFileType.Pos, 79, 300, 50, sizeRetain
    Obj.SetSize txtOpenWith.Pos, 156, 300, 464, sizeRetain

    Obj.SetSize btnSave.Pos, 2, 2, 92, 22
    Obj.SetSize btnDisable.Pos, 101, 2, 92, 22
    Obj.SetSize btnClose.Pos, 545, 2, 92, 22
    
    btnClose.Caption = "õClose"
    btnSave.Caption = "õSave"
    btnDisable.Caption = "õDisable"

    txtFileType.MaxLen = 3

    Obj.SetSize btnThemes.Pos, 14, 29 + 14, 46, 46
    Obj.SetSize btnFileAssoc.Pos, 14, 103, 46, 46
    Obj.SetSize btnMisc.Pos, 14, 29 + 134, 46, 46
    btnThemes.Transparent = True
    btnFileAssoc.Transparent = True
    btnMisc.Transparent = True

    Mouse.Hide
    LINE (74, 29)-(639, 349), Theme.Window, BF
    Mouse.Show
    Obj.DrawMenu
    Obj.DrawBtn btnDisable, False
    Obj.DrawBtn btnSave, False
    Obj.DrawBtn btnClose, False

    Obj.DrawTxt txtFileType, txtFileTypeText, False
    Obj.DrawTxt txtOpenWith, txtOpenWithText, False
    
    Font.Print "Edit file associations", 79, 43, Theme.WindowText, 1
    Font.Print "Using this editor you can associate file types with programs. What this means, is that", 79, 60, Theme.WindowText, 2
    Font.Print "whenever you open a file of that type directly, Costa will automatically open the", 79, 76, Theme.WindowText, 2
    Font.Print "associated program, and have it load the file for you.", 79, 92, Theme.WindowText, 2

    Font.Print "As an example, let's say you associate the TXT file extension with C:\DOS\EDIT.COM. Now,", 79, 124, Theme.WindowText, 2
    Font.Print "whenever you open a TXT file, Costa will launch EDIT.COM and have it open the file for you.", 79, 140, Theme.WindowText, 2

    Font.Print "To associate a filetype with a program, type the filetype below. If a program is already", 79, 172, Theme.WindowText, 2
    Font.Print "associated with this filetype, it will automatically show up in the ""Open with"" field.", 79, 188, Theme.WindowText, 2

    Font.Print "To remove an association, leave the ""Open with"" field blank.", 79, 220, Theme.WindowText, 2

    Font.Print "Remember to click the ""Save"" button after each modification.", 79, 252, Theme.WindowText, 2

    Font.Print "Fõiletype", txtFileType.Pos.Left, txtFileType.Pos.Top - 18, Theme.WindowText, 1
    Font.Print "Open õwith", txtOpenWith.Pos.Left, txtOpenWith.Pos.Top - 18, Theme.WindowText, 1

    DO

        Key$ = LCASE$(INKEY$)

        IF Obj.TxtClick(txtFileType) OR Key$ = "i" THEN
            OldFileType = txtFileTypeText
            Obj.EditTxt txtFileType, txtFileTypeText
            IF LEFT$(txtFileTypeText, 1) = "." THEN txtFileTypeText = RIGHT$(txtFileTypeText, LEN(txtFileTypeText) - 1)
            txtFileTypeText = UCASE$(txtFileTypeText)
            Obj.DrawTxt txtFileType, txtFileTypeText, False
            IF txtFileTypeText = "" THEN
                txtOpenWithText = ""
                Obj.DrawTxt txtOpenWith, txtOpenWithText, False
            ELSE
                IF NOT txtFileTypeText = OldFileType THEN
                    txtOpenWithText = File.GetAssociation(txtFileTypeText)
                    Obj.DrawTxt txtOpenWith, txtOpenWithText, False
                END IF
            END IF
        END IF

        IF Obj.TxtClick(txtOpenWith) OR Key$ = "w" THEN
            Obj.EditTxt txtOpenWith, txtOpenWithText
            txtOpenWithText = UCASE$(txtOpenWithText)
            Obj.DrawTxt txtOpenWith, txtOpenWithText, False
        END IF

        IF Obj.BtnClick(btnClose) OR Key$ = "c" OR Key$ = CHR$(27) THEN
            Conf.ConfAssoc = LaunchNoMore
            EXIT FUNCTION
        END IF

        IF Obj.BtnClick(btnSave) OR Key$ = "s" THEN
            IF txtFileTypeText = "" THEN
                SaveVar = Sys.MsgBox("No filetype specified", "You must specify a filetype before pressing" + CHR$(13) + "save.", msgError)
            ELSE
                Conf.SaveAssoc txtFileTypeText, txtOpenWithText
                IF txtOpenWithText = "" THEN
                    SaveVar = Sys.MsgBox("Association was removed", "Your file association has been removed and" + CHR$(13) + "will take effect immediately.", msgInfo)
                ELSE
                    SaveVar = Sys.MsgBox("Association was saved", "Your file association has been saved and" + CHR$(13) + "will take effect immediately.", msgInfo)
                END IF
            END IF
        END IF

        IF Obj.BtnClick(btnDisable) OR Key$ = "d" THEN
            IF Sys.MsgBox("Disable file associations", "This will disable file associations in Costa" + CHR$(13) + "and all of its acessories. Are you sure?", msgQuest) = True THEN
                Setting.AssignFileTypes = False
                Sys.SaveSettings
                Conf.ConfAssoc = LaunchMenu
                EXIT FUNCTION
            END IF
        END IF

        IF Obj.BtnClick(btnThemes) OR Key$ = "t" THEN
          Conf.ConfAssoc = LaunchTheme
          EXIT FUNCTION
        END IF

        IF Obj.BtnClick(btnFileAssoc) THEN
        END IF

        IF Obj.BtnClick(btnMisc) OR Key$ = "o" THEN
          Conf.ConfAssoc = LaunchMisc
          EXIT FUNCTION
        END IF
                                                 
    LOOP

END FUNCTION

' =========================================================================
'          NAME: Conf.ConfMisc()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: CONFIG.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: UI and logic for misc. options editor
' =========================================================================
FUNCTION Conf.ConfMisc ()

    DIM frmDesktop AS FrameType, frmVarious AS FrameType
    DIM btnSave AS ButtonType, btnClose AS ButtonType
    DIM chkShowLinkDesc AS CheckBoxType, chkShowLinkTarget AS CheckBoxType
    DIM chkUseVGAMode AS CheckBoxType, chkConfLinkDel AS CheckBoxType
    DIM chkConfExit AS CheckBoxType, chkGreyOutMsgBox AS CheckBoxType
    DIM chkAnimUI AS CheckBoxType, chkDailyTip AS CheckBoxType
    DIM chkUseLastProfile AS CheckBoxType

    DIM btnThemes AS ButtonType, btnFileAssoc AS ButtonType, btnMisc AS ButtonType
    DIM imgThemes AS ImageType, imgFileAssoc AS ImageType, imgMisc AS ImageType

    DIM ShowTargetChk
    DIM Key$

    Obj.SetSize frmDesktop.Pos, 74, 43, 552, 118
    Obj.SetSize frmVarious.Pos, 74, frmDesktop.Pos.Top + frmDesktop.Pos.Height + 12, frmDesktop.Pos.Width, 129

    Obj.SetSize chkShowLinkDesc.Pos, frmDesktop.Pos.Left + 12, frmDesktop.Pos.Top + 16, sizeRetain, sizeRetain
    Obj.SetSize chkShowLinkTarget.Pos, frmDesktop.Pos.Left + 34, frmDesktop.Pos.Top + 38, sizeRetain, sizeRetain
    Obj.SetSize chkUseVGAMode.Pos, frmDesktop.Pos.Left + 12, frmDesktop.Pos.Top + 70, sizeRetain, sizeRetain
    Obj.SetSize chkConfLinkDel.Pos, frmDesktop.Pos.Left + 12, frmDesktop.Pos.Top + 92, sizeRetain, sizeRetain
    Obj.SetSize chkAnimUI.Pos, frmVarious.Pos.Left + 12, frmVarious.Pos.Top + 16, sizeRetain, sizeRetain
    Obj.SetSize chkConfExit.Pos, frmVarious.Pos.Left + 12, frmVarious.Pos.Top + 38, sizeRetain, sizeRetain
    Obj.SetSize chkGreyOutMsgBox.Pos, frmVarious.Pos.Left + 12, frmVarious.Pos.Top + 60, sizeRetain, sizeRetain
    Obj.SetSize chkDailyTip.Pos, frmVarious.Pos.Left + 12, frmVarious.Pos.Top + 82, sizeRetain, sizeRetain
    Obj.SetSize chkUseLastProfile.Pos, frmVarious.Pos.Left + 12, frmVarious.Pos.Top + 104, sizeRetain, sizeRetain
    Obj.SetSize btnSave.Pos, 2, 2, 92, 22
    Obj.SetSize btnClose.Pos, 545, 2, 92, 22
    
    Obj.SetSize btnThemes.Pos, 14, 29 + 14, 46, 46
    btnThemes.Transparent = True
    imgThemes.Pos.Left = btnThemes.Pos.Left + 7
    imgThemes.Pos.Top = btnThemes.Pos.Top + 7
    imgThemes.ImageFile = "THEMES"

    Obj.SetSize btnFileAssoc.Pos, 14, 29 + 74, 46, 46
    btnFileAssoc.Transparent = True
    imgFileAssoc.Pos.Left = btnFileAssoc.Pos.Left + 7
    imgFileAssoc.Pos.Top = btnFileAssoc.Pos.Top + 7
    imgFileAssoc.ImageFile = "UNKNOWN"

    Obj.SetSize btnMisc.Pos, 14, 29 + 134, 46, 46
    btnMisc.Transparent = True
    imgMisc.Pos.Left = btnMisc.Pos.Left + 7
    imgMisc.Pos.Top = btnMisc.Pos.Top + 7
    imgMisc.ImageFile = "CONFIG"


    btnThemes.Transparent = True
    btnFileAssoc.Transparent = True
    btnMisc.Transparent = True
    
    btnClose.Caption = "õClose"
    btnSave.Caption = "õSave"
    chkShowLinkDesc.Checked = Setting.ShowLinkDescriptions
    chkShowLinkTarget.Checked = Setting.ShowLinkTargetFiles
    'IF Setting.ScreenMode = scrVGA THEN
    '  chkUseVGAMode.Checked = True
    'END IF
    chkUseVGAMode.Checked = False
    chkConfLinkDel.Checked = Setting.ConfirmLinkDelete
    'chkAnimUI.Checked = Setting.Animations
    chkAnimUI.Checked = False
    chkConfExit.Checked = Setting.ConfirmExit
    'chkGreyOutMsgBox.Checked = Setting.GreyoutOnMsgBox
    'chkDailyTip.Checked = Setting.TipOfTheDay
    'chkUseLastProfile.Checked = SystemSettings.UseLastProfile

RedrawAllMisc:
    Mouse.Hide
    LINE (74, 29)-(639, 349), Theme.Window, BF
    Mouse.Show
    Obj.DrawMenu
    Obj.DrawBtn btnSave, False
    Obj.DrawBtn btnClose, False

    Obj.DrawFrm frmDesktop, 15, Theme.Shadow
    Obj.DrawFrm frmVarious, 15, Theme.Shadow
    Mouse.Hide
    LINE (frmDesktop.Pos.Left + 7, frmDesktop.Pos.Top)-(frmDesktop.Pos.Left + 64, frmDesktop.Pos.Top + 1), Theme.Window, B
    LINE (frmVarious.Pos.Left + 7, frmVarious.Pos.Top)-(frmVarious.Pos.Left + 116, frmVarious.Pos.Top + 1), Theme.Window, B
    Mouse.Show
    Font.Print "Desktop", frmDesktop.Pos.Left + 10, frmDesktop.Pos.Top - 3, Theme.WindowText, 1
    Font.Print "Various settings", frmVarious.Pos.Left + 10, frmVarious.Pos.Top - 3, Theme.WindowText, 1
    Obj.DrawChk chkShowLinkDesc
    Obj.DrawChk chkShowLinkTarget
    Obj.DrawChk chkUseVGAMode
    Obj.DrawChk chkConfLinkDel
    Obj.DrawChk chkAnimUI
    Obj.DrawChk chkConfExit
    Obj.DrawChk chkGreyOutMsgBox
    Obj.DrawChk chkDailyTip
    Obj.DrawChk chkUseLastProfile

    Font.Print "Show link õdescriptions", chkShowLinkDesc.Pos.Left + 20, chkShowLinkDesc.Pos.Top + 3, Theme.WindowText, 2
    IF chkShowLinkDesc.Checked = True THEN
        Font.Print "Show link targõets", chkShowLinkTarget.Pos.Left + 20, chkShowLinkTarget.Pos.Top + 3, Theme.WindowText, 2
    ELSE
        Font.Print "Show link targõets", chkShowLinkTarget.Pos.Left + 20, chkShowLinkTarget.Pos.Top + 3, Theme.Shadow, 2
    END IF
    Font.Print "Use õVGA mode (higher resolution, but slower)", chkUseVGAMode.Pos.Left + 20, chkUseVGAMode.Pos.Top + 3, Theme.Shadow, 2
    Font.Print "Confirm link õremoval", chkConfLinkDel.Pos.Left + 20, chkConfLinkDel.Pos.Top + 3, Theme.WindowText, 2
    Font.Print "õAnimate user interface (sliding menus)", chkAnimUI.Pos.Left + 20, chkAnimUI.Pos.Top + 3, Theme.Shadow, 2
    Font.Print "Confirm before eõxiting Costa", chkConfExit.Pos.Left + 20, chkConfExit.Pos.Top + 3, Theme.WindowText, 2
    Font.Print "õGrey out screen while showing a messagebox", chkGreyOutMsgBox.Pos.Left + 20, chkGreyOutMsgBox.Pos.Top + 3, Theme.WindowText, 2
    Font.Print "Shoõw start-up ""Tip of the Day"" messages", chkDailyTip.Pos.Left + 20, chkDailyTip.Pos.Top + 3, Theme.WindowText, 2
    Font.Print "õUse last profile on start-up without asking", chkUseLastProfile.Pos.Left + 20, chkUseLastProfile.Pos.Top + 3, Theme.WindowText, 2
    
    DO
        Key$ = LCASE$(INKEY$)
        
        Obj.ChkClick chkShowLinkDesc
        IF NOT ShowTargetChk = chkShowLinkDesc.Checked THEN
            ShowTargetChk = chkShowLinkDesc.Checked
            chkShowLinkDesc.Checked = NOT chkShowLinkDesc.Checked
            Key$ = "d"
        END IF

        IF ShowTargetChk = True THEN Obj.ChkClick chkShowLinkTarget
        'Obj.ChkClick chkUseVGAMode
        Obj.ChkClick chkConfLinkDel
        Obj.ChkClick chkConfExit
        Obj.ChkClick chkGreyOutMsgBox
        Obj.ChkClick chkAnimUI
        Obj.ChkClick chkDailyTip
        Obj.ChkClick chkUseLastProfile

        IF Obj.BtnClick(btnClose) OR Key$ = "c" OR Key$ = CHR$(27) THEN
          Conf.ConfMisc = LaunchNoMore
          EXIT FUNCTION
        END IF

        IF Obj.BtnClick(btnSave) OR Key$ = "s" THEN
            
            'SystemSettings.UseLastProfile = chkUseLastProfile.Checked
            
            'Setting.Animations = chkAnimUI.Checked
            Setting.ShowLinkDescriptions = chkShowLinkDesc.Checked
            Setting.ShowLinkTargetFiles = chkShowLinkTarget.Checked
            'IF chkUseVGAMode.Checked THEN
            '  Setting.ScreenMode = 12
            'ELSE
            '  Setting.ScreenMode = 9
            'END IF
            'Setting.ScreenMode = 9
            Setting.ConfirmLinkDelete = chkConfLinkDel.Checked
            Setting.ConfirmExit = chkConfExit.Checked
            'Setting.TipOfTheDay = chkDailyTip.Checked
            'Setting.GreyoutOnMsgBox = chkGreyOutMsgBox.Checked
            
            Sys.SaveSettings
            
        END IF

        IF Key$ = "d" THEN
            chkShowLinkDesc.Checked = NOT chkShowLinkDesc.Checked: Obj.DrawChk chkShowLinkDesc
            IF chkShowLinkDesc.Checked = True THEN
                Font.Print "Show link targõets", chkShowLinkTarget.Pos.Left + 20, chkShowLinkTarget.Pos.Top + 3, Theme.WindowText, 2
            ELSE
                Font.Print "Show link targõets", chkShowLinkTarget.Pos.Left + 20, chkShowLinkTarget.Pos.Top + 3, Theme.Shadow, 2
            END IF
        END IF

        IF Key$ = "e" AND chkShowLinkDesc.Checked = True THEN chkShowLinkTarget.Checked = NOT chkShowLinkTarget.Checked: Obj.DrawChk chkShowLinkTarget
        'IF Key$ = "v" THEN chkUseVGAMode.Checked = NOT chkUseVGAMode.Checked: Obj.DrawChk chkUseVGAMode
        IF Key$ = "r" THEN chkConfLinkDel.Checked = NOT chkConfLinkDel.Checked: Obj.DrawChk chkConfLinkDel
        'IF Key$ = "a" THEN chkAnimUI.Checked = NOT chkAnimUI.Checked: Obj.DrawChk chkAnimUI
        IF Key$ = "x" THEN chkConfExit.Checked = NOT chkConfExit.Checked: Obj.DrawChk chkConfExit
        IF Key$ = "g" THEN chkGreyOutMsgBox.Checked = NOT chkGreyOutMsgBox.Checked: Obj.DrawChk chkGreyOutMsgBox
        IF Key$ = "w" THEN chkDailyTip.Checked = NOT chkDailyTip.Checked: Obj.DrawChk chkDailyTip
        IF Key$ = "u" THEN chkUseLastProfile.Checked = NOT chkUseLastProfile.Checked: Obj.DrawChk chkUseLastProfile
    
        IF Obj.BtnClick(btnThemes) OR Key$ = "t" THEN
          Conf.ConfMisc = LaunchTheme
          EXIT FUNCTION
        END IF
        IF Obj.BtnClick(btnFileAssoc) OR Key$ = "f" THEN
          Conf.ConfMisc = LaunchAssoc
          EXIT FUNCTION
        END IF

        IF Obj.BtnClick(btnMisc) THEN
        END IF

    LOOP

END FUNCTION

' =========================================================================
'          NAME: Conf.ConfTheme()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: CONFIG.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: UI and logic for theme selector
' =========================================================================
FUNCTION Conf.ConfTheme ()

    DIM frmPreview AS FrameType
    DIM btnBack AS ButtonType, btnNext AS ButtonType
    DIM btnSave AS ButtonType, btnClose AS ButtonType
    DIM btnThemes AS ButtonType, btnFileAssoc AS ButtonType, btnMisc AS ButtonType
    DIM imgThemes AS ImageType, imgFileAssoc AS ImageType, imgMisc AS ImageType

    DIM OrigWindowColor, OrigWindowTextColor
    
    DIM OriginalTheme AS STRING
    DIM ThemeList() AS STRING

    Sys.ShowLoading

    'Load theme filenames into array
    DIM TmpName$, TmpCount, ActiveTheme
    REDIM ThemeList(0 TO 0) AS STRING
    TmpName$ = DIR$(Sys.Path + "DATA\THEMES\*.DAT")
    TmpCount = 0
    DO WHILE NOT TmpName$ = ""
        TmpName$ = LEFT$(TmpName$, LEN(TmpName$) - 4)
        REDIM PRESERVE ThemeList(0 TO TmpCount) AS STRING
        ThemeList(UBOUND(ThemeList)) = TmpName$
        IF UCASE$(TmpName$) = UCASE$(RTRIM$(Setting.ThemeFile)) THEN ActiveTheme = TmpCount
        TmpName$ = DIR$
        TmpCount = TmpCount + 1
    LOOP

    IF TmpCount = 0 THEN
        TmpCount = Sys.MsgBox("No theme files found.", "Costa could not find any theme files. Make sure that the" + CHR$(13) + "themes are in DATA\THEMES, and try again.", msgError)
        EXIT FUNCTION
    END IF

    frmPreview.Pos.Left = 74
    frmPreview.Pos.Top = 73
    frmPreview.Pos.Width = 552
    frmPreview.Pos.Height = 234

    Obj.SetSize btnBack.Pos, frmPreview.Pos.Left, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 45, 22
    btnBack.Caption = "<-"

    Obj.SetSize btnNext.Pos, frmPreview.Pos.Left + frmPreview.Pos.Width - 45, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 45, 22
    btnNext.Caption = "->"

    Obj.SetSize btnSave.Pos, 2, 2, 92, 22
    btnSave.Caption = "õSave"

    Obj.SetSize btnClose.Pos, 545, 2, 92, 22
    btnClose.Caption = "õClose"

    Obj.SetSize btnThemes.Pos, 14, 29 + 14, 46, 46
    btnThemes.Transparent = True
    imgThemes.Pos.Left = btnThemes.Pos.Left + 7
    imgThemes.Pos.Top = btnThemes.Pos.Top + 7
    imgThemes.ImageFile = "THEMES"

    Obj.SetSize btnFileAssoc.Pos, 14, 29 + 74, 46, 46
    btnFileAssoc.Transparent = True
    imgFileAssoc.Pos.Left = btnFileAssoc.Pos.Left + 7
    imgFileAssoc.Pos.Top = btnFileAssoc.Pos.Top + 7
    imgFileAssoc.ImageFile = "UNKNOWN"

    Obj.SetSize btnMisc.Pos, 14, 29 + 134, 46, 46
    btnMisc.Transparent = True
    imgMisc.Pos.Left = btnMisc.Pos.Left + 7
    imgMisc.Pos.Top = btnMisc.Pos.Top + 7
    imgMisc.ImageFile = "CONFIG"


RedrawAll:
    OrigWindowColor = Theme.Window
    OrigWindowTextColor = Theme.WindowText

    Mouse.Hide
    LINE (74, 29)-(639, 349), Theme.Window, BF
    Mouse.Show

    Obj.DrawMenu
    Obj.DrawBtn btnSave, False
    Obj.DrawBtn btnClose, False
    
    Obj.DrawBtn btnBack, False
    Obj.DrawBtn btnNext, False
    Obj.DrawFrm frmPreview, 15, Theme.Shadow
    Mouse.Hide
    Font.Print "Theme name:", frmPreview.Pos.Left, 43, Theme.WindowText, 1
    Font.Print "Theme author:", frmPreview.Pos.Left, 58, Theme.WindowText, 1
    Mouse.Show

    'The rest of the controls are used in the preview
    DIM winPreview AS WindowType
    DIM txtPreview AS TextboxType, txtPreviewText AS STRING
    DIM btnPreview1 AS ButtonType, btnPreview2 AS ButtonType
    DIM btnPreview3 AS ButtonType
    DIM imgPreview AS ImageType
    DIM txtListPreview AS TextboxType

    Obj.SetSize winPreview.Pos, frmPreview.Pos.Left + ((frmPreview.Pos.Width - 260) / 2), frmPreview.Pos.Top + 65, 260, 127
    
    txtPreview.Pos.Left = winPreview.Pos.Left + 12
    txtPreview.Pos.Top = winPreview.Pos.Top + 56
    txtPreview.Pos.Width = 236
    txtPreview.Pos.Height = 19
    txtPreviewText = "Textbox contents"
    
    Obj.SetSize btnPreview1.Pos, winPreview.Pos.Left + 14, winPreview.Pos.Top + 93, 111, 22
    btnPreview1.Caption = "Button up"

    Obj.SetSize btnPreview2.Pos, winPreview.Pos.Left + 133, winPreview.Pos.Top + 93, 111, 22
    btnPreview2.Caption = "Button down"

    Obj.SetSize btnPreview3.Pos, frmPreview.Pos.Left + frmPreview.Pos.Width - 96, frmPreview.Pos.Top + 3, 92, 22
    btnPreview3.Caption = "Menu button"

    imgPreview.Pos.Left = frmPreview.Pos.Left + 16
    imgPreview.Pos.Top = frmPreview.Pos.Top + frmPreview.Pos.Height - 48
    imgPreview.ImageFile = "LOGO"

    txtListPreview.Pos.Width = 116
    txtListPreview.Pos.Height = 66
    txtListPreview.Pos.Left = frmPreview.Pos.Left + frmPreview.Pos.Width - txtListPreview.Pos.Width - 16
    txtListPreview.Pos.Top = frmPreview.Pos.Top + frmPreview.Pos.Height - txtListPreview.Pos.Height - 16
    
    OriginalTheme = RTRIM$(Setting.ThemeFile)
    Setting.ThemeFile = ThemeList(ActiveTheme)
    Sys.LoadTheme
                       
    DIM Key$
UpdatePreview:
    Mouse.Hide
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + frmPreview.Pos.Height - 2), Theme.Desktop, BF
    LINE (frmPreview.Pos.Left + 99, 42)-(frmPreview.Pos.Left + 350, 71), OrigWindowColor, BF
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + 27), Theme.Window, BF
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 28)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + 28), Theme.Shadow
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 29)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + 29), 0
    Mouse.Show

    Font.Print RTRIM$(Theme.Name), frmPreview.Pos.Left + 100, 43, OrigWindowTextColor, FontNormal
    Font.Print RTRIM$(Theme.Author), frmPreview.Pos.Left + 100, 58, OrigWindowTextColor, FontNormal
    
    Obj.DrawWin winPreview
    Obj.DrawTxt txtPreview, txtPreviewText, True
    Obj.DrawBtn btnPreview1, False
    Obj.DrawBtn btnPreview2, True
    Obj.DrawBtn btnPreview3, False
    
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 14, Theme.WindowText, FontHeading
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 30, Theme.WindowText, FontNormal
    Font.Print "Preview link", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 4, Theme.DesktopText, FontHeading
    Font.Print "preview.exe", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 18, Theme.DesktopText, FontNormal

    Obj.DrawImg imgPreview
    
    Obj.DrawTxt txtListPreview, "", False
    Mouse.Hide
    LINE (txtListPreview.Pos.Left + 2, txtListPreview.Pos.Top + 15)-(txtListPreview.Pos.Left + txtListPreview.Pos.Width - 2, txtListPreview.Pos.Top + 27), Theme.Select, BF
    Mouse.Show
    Font.Print "List item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5, Theme.TextboxText, FontSystem
    Font.Print "Selected item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 12, Theme.SelectText, FontSystem
    Font.Print "List item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 24, Theme.TextboxText, FontSystem
    Font.Print "List item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 36, Theme.TextboxText, FontSystem
    Font.Print "List item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 48, Theme.TextboxText, FontSystem

    Setting.ThemeFile = OriginalTheme
    Sys.LoadTheme

    DO
        Key$ = LCASE$(INKEY$)

        IF Obj.BtnClick(btnSave) OR Key$ = "s" OR Key$ = CHR$(13) THEN
            Setting.ThemeFile = ThemeList(ActiveTheme)
            Sys.SaveSettings
            Sys.LoadTheme
            OriginalTheme = RTRIM$(Setting.ThemeFile)
            Mouse.Hide
            LINE (0, 29)-(73, 349), Theme.Window, BF
            Mouse.Show
            Obj.DrawBtn btnThemes, False
            Obj.DrawBtn btnFileAssoc, False
            Obj.DrawBtn btnMisc, False
            Obj.DrawImg imgThemes
            Obj.DrawImg imgFileAssoc
            Obj.DrawImg imgMisc
            GOTO RedrawAll
        END IF

        IF Obj.BtnClick(btnClose) OR Key$ = "c" OR Key$ = CHR$(27) THEN
            Setting.ThemeFile = OriginalTheme
            Sys.LoadTheme
            Conf.ConfTheme = LaunchNoMore
            EXIT FUNCTION
        END IF
        
        IF Obj.BtnClick(btnNext) OR Key$ = CHR$(0) + "m" THEN
            ActiveTheme = ActiveTheme + 1
            IF ActiveTheme > UBOUND(ThemeList) THEN ActiveTheme = 0
            Setting.ThemeFile = ThemeList(ActiveTheme)
            Sys.LoadTheme
            GOTO UpdatePreview
        END IF

        IF Obj.BtnClick(btnBack) OR Key$ = CHR$(0) + "k" THEN
            ActiveTheme = ActiveTheme - 1
            IF ActiveTheme < 0 THEN ActiveTheme = UBOUND(ThemeList)
            Setting.ThemeFile = ThemeList(ActiveTheme)
            Sys.LoadTheme
            GOTO UpdatePreview
        END IF

        IF Obj.BtnClick(btnThemes) OR Key$ = "t" THEN
        END IF

        IF Obj.BtnClick(btnFileAssoc) OR Key$ = "f" THEN
          Conf.ConfTheme = LaunchAssoc
          EXIT FUNCTION
        END IF

        IF Obj.BtnClick(btnMisc) OR Key$ = "o" THEN
          Conf.ConfTheme = LaunchMisc
          EXIT FUNCTION
        END IF
          
    LOOP

END FUNCTION

' =========================================================================
'          NAME: Conf.Main()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: UI and logic for the main window of the configuration
'                editor.
' =========================================================================
SUB Conf.Main ()

  DIM btnThemes AS ButtonType, btnFileAssoc AS ButtonType, btnMisc AS ButtonType
  DIM imgThemes AS ImageType, imgFileAssoc AS ImageType, imgMisc AS ImageType
  DIM btnClose AS ButtonType
  DIM LaunchNext

  Obj.SetSize btnThemes.Pos, 14, 29 + 14, 46, 46
  btnThemes.Transparent = True
  imgThemes.Pos.Left = btnThemes.Pos.Left + 7
  imgThemes.Pos.Top = btnThemes.Pos.Top + 7
  imgThemes.ImageFile = "THEMES"

  Obj.SetSize btnFileAssoc.Pos, 14, 29 + 74, 46, 46
  btnFileAssoc.Transparent = True
  imgFileAssoc.Pos.Left = btnFileAssoc.Pos.Left + 7
  imgFileAssoc.Pos.Top = btnFileAssoc.Pos.Top + 7
  imgFileAssoc.ImageFile = "UNKNOWN"

  Obj.SetSize btnMisc.Pos, 14, 29 + 134, 46, 46
  btnMisc.Transparent = True
  imgMisc.Pos.Left = btnMisc.Pos.Left + 7
  imgMisc.Pos.Top = btnMisc.Pos.Top + 7
  imgMisc.ImageFile = "CONFIG"

  Obj.SetSize btnClose.Pos, 545, 2, 92, 22
  btnClose.Caption = "õClose"

TopOfConf:
  Mouse.Hide
  LINE (0, 29)-(640, 349), Theme.Window, BF
  Mouse.Show

  Obj.DrawBtn btnThemes, False
  Obj.DrawBtn btnFileAssoc, False
  Obj.DrawBtn btnMisc, False

  Mouse.Hide
  LINE (74, 29)-(639, 349), Theme.Window, BF
  Mouse.Show
  Obj.DrawMenu
  Obj.DrawBtn btnClose, False

  Font.Print "õTheme selector", btnThemes.Pos.Left + 60, btnThemes.Pos.Top, Theme.WindowText, 1
  Font.Print "Change the colors of the user interface. Costa comes with a collection of themes for you to", btnThemes.Pos.Left + 60, btnThemes.Pos.Top + 15, Theme.WindowText, 2
  Font.Print "choose from. Use the Theme Editor to make your own, then select them here to use them.", btnThemes.Pos.Left + 60, btnThemes.Pos.Top + 29, Theme.WindowText, 2

  Font.Print "õFile associations", btnFileAssoc.Pos.Left + 60, btnFileAssoc.Pos.Top, Theme.WindowText, 1
  Font.Print "Enable or disable file associations, and define which programs should open different file", btnFileAssoc.Pos.Left + 60, btnFileAssoc.Pos.Top + 15, Theme.WindowText, 2
  Font.Print "types. For instance, make text files always open in your favorite editor automatically.", btnFileAssoc.Pos.Left + 60, btnFileAssoc.Pos.Top + 29, Theme.WindowText, 2

  Font.Print "õOther settings", btnMisc.Pos.Left + 60, btnMisc.Pos.Top, Theme.WindowText, 1
  Font.Print "Tweak various aspects of Costa, like how the desktop acts and looks, which screen", btnMisc.Pos.Left + 60, btnMisc.Pos.Top + 15, Theme.WindowText, 2
  Font.Print "resolution Costa should use, and which actions should require confirmation.", btnMisc.Pos.Left + 60, btnMisc.Pos.Top + 29, Theme.WindowText, 2

  Obj.DrawImg imgThemes
  Obj.DrawImg imgFileAssoc
  Obj.DrawImg imgMisc

  DIM Key$
  DO
    Key$ = LCASE$(INKEY$)

    IF Obj.BtnClick(btnThemes) OR Key$ = "t" THEN LaunchNext = LaunchTheme
    IF Obj.BtnClick(btnFileAssoc) OR Key$ = "f" THEN LaunchNext = LaunchAssoc
    IF Obj.BtnClick(btnMisc) OR Key$ = "o" THEN LaunchNext = LaunchMisc

    IF Obj.BtnClick(btnClose) OR Key$ = "c" OR Key$ = CHR$(27) THEN
      EXIT SUB
    END IF

    IF LaunchNext THEN
      DO
        SELECT CASE LaunchNext
          CASE LaunchMenu
            LaunchNext = 0
            GOTO TopOfConf
          CASE LaunchAssoc
            LaunchNext = Conf.ConfAssoc
          CASE LaunchMisc
            LaunchNext = Conf.ConfMisc
          CASE LaunchTheme
            LaunchNext = Conf.ConfTheme
          CASE ELSE
            LaunchNext = LaunchNoMore
        END SELECT
      LOOP UNTIL LaunchNext = LaunchNoMore
      EXIT SUB
    END IF

  LOOP

END SUB

' =========================================================================
'          NAME: Conf.RestoreAssoc()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Reset file associations to defaults, and save to filetype
'                config file.
' =========================================================================
SUB Conf.RestoreAssoc ()

    DIM DefaultAssoc(0 TO 7) AS FileAssociationType
    DIM AssocFile

    ON LOCAL ERROR RESUME NEXT
    KILL Sys.Path + "\DATA\CONFIG\FILETYPE.DAT"
    
    AssocFile = FREEFILE
    OPEN Sys.Path + "\DATA\CONFIG\FILETYPE.DAT" FOR BINARY AS #AssocFile

    DefaultAssoc(0).FileType = "TXT"
    DefaultAssoc(0).Command = "TEXTVIEW.EXE"
    PUT #AssocFile, , DefaultAssoc(0)

    DefaultAssoc(1).FileType = "INI"
    DefaultAssoc(1).Command = "TEXTVIEW.EXE"
    PUT #AssocFile, , DefaultAssoc(1)

    DefaultAssoc(2).FileType = "THM"
    DefaultAssoc(2).Command = "THMEDIT.EXE"
    PUT #AssocFile, , DefaultAssoc(2)

    DefaultAssoc(3).FileType = "DOC"
    DefaultAssoc(3).Command = "TEXTVIEW.EXE"
    PUT #AssocFile, , DefaultAssoc(3)

    DefaultAssoc(4).FileType = "ME"
    DefaultAssoc(4).Command = "TEXTVIEW.EXE"
    PUT #AssocFile, , DefaultAssoc(4)

    DefaultAssoc(5).FileType = "1ST"
    DefaultAssoc(5).Command = "TEXTVIEW.EXE"
    PUT #AssocFile, , DefaultAssoc(5)

    DefaultAssoc(6).FileType = "CFG"
    DefaultAssoc(6).Command = "TEXTVIEW.EXE"
    PUT #AssocFile, , DefaultAssoc(6)

    DefaultAssoc(7).FileType = "BAS"
    DefaultAssoc(7).Command = "QBASIC.EXE /RUN"
    PUT #AssocFile, , DefaultAssoc(7)
    
    CLOSE #AssocFile

END SUB

' =========================================================================
'          NAME: Conf.Main()
'    PARAMETERS: FileType - a 1-3 letter string containing extension of
'                           file type to associate
'                Command  - the program or command to pass the file to
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Saves a file association to the config file. Modifies
'                existing if found, otherwise saves new association.
' =========================================================================
SUB Conf.SaveAssoc (FileType AS STRING, Command AS STRING)

  DIM FileAssociation AS FileAssociationType
  DIM FileHandle, FilePos, AssocSaved

  IF File.Exists(Sys.Path + "\DATA\CONFIG\FILETYPE.DAT") THEN
    FileHandle = FREEFILE
    OPEN Sys.Path + "\DATA\CONFIG\FILETYPE.DAT" FOR BINARY AS #FileHandle

    ON LOCAL ERROR RESUME NEXT

    'See if extension is already known, update command if so
    DO WHILE NOT EOF(FileHandle)

      'Save position so we know where to write if this is the one
      FilePos = LOC(FileHandle)
      GET #FileHandle, , FileAssociation

      
      IF UCASE$(FileType) = RTRIM$(FileAssociation.FileType) THEN
        FileAssociation.Command = UCASE$(Command)
        PUT #FileHandle, FilePos + 1, FileAssociation
        AssocSaved = True
        EXIT DO
      END IF

    LOOP

    'Extension was not in file, add it
    IF NOT AssocSaved THEN
      FileAssociation.FileType = UCASE$(FileType)
      FileAssociation.Command = UCASE$(Command)
      PUT #FileHandle, , FileAssociation
    END IF

    CLOSE #FileHandle
    ON LOCAL ERROR GOTO 0

  END IF

END SUB

