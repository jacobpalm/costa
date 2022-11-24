OPTION EXPLICIT
DEFINT A-Z

DECLARE SUB Conf.ConfAssoc ()
DECLARE SUB Conf.ConfMisc ()
DECLARE SUB Conf.ConfTheme ()
DECLARE SUB Desk.DrawDesktop ()
DECLARE SUB Conf.Main ()
DECLARE SUB Conf.RestoreAssoc ()
DECLARE SUB Conf.SaveAssoc (FileType AS STRING, Command AS STRING)

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

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
SUB Conf.ConfAssoc ()

    IF UserSettings.AssignFileTypes = False THEN
        IF Sys.MsgBox("File associations disabled", "File associations are currently disabled." + CHR$(13) + "Do you want to enable this feature?", msgQuest) = True THEN
            UserSettings.AssignFileTypes = True
            Sys.SaveProfile ProfileID
        ELSE
            EXIT SUB
        END IF
    END IF

    IF NOT File.Exists(Sys.Path + "\DATA\CONFIG\FILETYPE.DAT") THEN
      Conf.RestoreAssoc
    END IF

    DIM winAssoc AS WindowType
    DIM imgIcon AS ImageType
    DIM txtFileType AS TextboxType, txtFileTypeText AS STRING
    DIM txtOpenWith AS TextboxType, txtOpenWithText AS STRING
    DIM btnSave AS ButtonType, btnClose AS ButtonType, btnDisable AS ButtonType
    DIM OldFileType AS STRING, SaveVar
    DIM Key$
    
    Obj.SetSize winAssoc.Pos, 92, (scrHeight - 280) / 2, 455, 280
    Obj.SetSize imgIcon.Pos, 105, winAssoc.Pos.Top + 38, -1, -1
    Obj.SetSize txtFileType.Pos, 105, winAssoc.Pos.Top + 210, 50, -1
    Obj.SetSize txtOpenWith.Pos, 182, winAssoc.Pos.Top + 210, 353, -1
    Obj.SetSize btnClose.Pos, 451, winAssoc.Pos.Top + 246, 84, 23
    Obj.SetSize btnSave.Pos, 351, winAssoc.Pos.Top + 246, 84, 23
    Obj.SetSize btnDisable.Pos, 105, winAssoc.Pos.Top + 246, 84, 23

    winAssoc.Caption = "File association editor"
    btnClose.Caption = "õClose"
    btnSave.Caption = "õSave"
    btnDisable.Caption = "õDisable"

    imgIcon.ImageFile = "UNKNOWN"
    txtFileType.MaxLen = 3

    Obj.DrawWin winAssoc
    Obj.DrawTxt txtFileType, txtFileTypeText, False
    Obj.DrawTxt txtOpenWith, txtOpenWithText, False
    Obj.DrawBtn btnClose, False
    Obj.DrawBtn btnSave, False
    Obj.DrawBtn btnDisable, False
    
    Font.Print "Edit file associations", 148, winAssoc.Pos.Top + 33, SystemTheme.WindowText, 1
    Font.Print "Using this editor you can associate files with programs, meaning", 148, winAssoc.Pos.Top + 50, SystemTheme.WindowText, 2
    Font.Print "that if you for example run README.TXT, and TXT is associated", 148, winAssoc.Pos.Top + 66, SystemTheme.WindowText, 2
    Font.Print "with EDIT.COM, EDIT.COM will run and open README.TXT for you.", 105, winAssoc.Pos.Top + 82, SystemTheme.WindowText, 2
    Font.Print "To associate a filetype with a program, type the filetype below. If a", 105, winAssoc.Pos.Top + 114, SystemTheme.WindowText, 2
    Font.Print "program is already assigned with this filetype, it will automatically", 105, winAssoc.Pos.Top + 130, SystemTheme.WindowText, 2
    Font.Print "show up in the ""Open with"" field. To remove an association, leave the", 105, winAssoc.Pos.Top + 146, SystemTheme.WindowText, 2
    Font.Print """Open with"" field blank.", 105, winAssoc.Pos.Top + 162, SystemTheme.WindowText, 2

    Font.Print "õFiletype", 105, winAssoc.Pos.Top + 194, SystemTheme.WindowText, 1
    Font.Print "õOpen with", 182, winAssoc.Pos.Top + 194, SystemTheme.WindowText, 1

    Obj.DrawImg imgIcon

    DO

        Key$ = LCASE$(INKEY$)

        IF Obj.TxtClick(txtFileType) OR Key$ = "f" THEN
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

        IF Obj.TxtClick(txtOpenWith) OR Key$ = "o" THEN
            Obj.EditTxt txtOpenWith, txtOpenWithText
            txtOpenWithText = UCASE$(txtOpenWithText)
            Obj.DrawTxt txtOpenWith, txtOpenWithText, False
        END IF

        IF Obj.BtnClick(btnClose) OR Key$ = "c" OR Key$ = CHR$(27) THEN
            EXIT DO
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
                UserSettings.AssignFileTypes = False
                Sys.SaveProfile ProfileID
                EXIT SUB
            END IF
        END IF


    LOOP

END SUB

' =========================================================================
'          NAME: Conf.ConfMisc()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: CONFIG.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: UI and logic for misc. options editor
' =========================================================================
SUB Conf.ConfMisc ()

    DIM winMisc AS WindowType
    DIM frmDesktop AS FrameType, frmVarious AS FrameType
    DIM btnSave AS ButtonType, btnCancel AS ButtonType
    DIM chkShowLinkDesc AS CheckBoxType, chkShowLinkTarget AS CheckBoxType
    DIM chkUseVGAMode AS CheckBoxType, chkConfLinkDel AS CheckBoxType
    DIM chkConfExit AS CheckBoxType, chkGreyOutMsgBox AS CheckBoxType
    DIM chkAnimUI AS CheckBoxType, chkDailyTip AS CheckBoxType
    DIM chkUseLastProfile AS CheckBoxType
    
    DIM ShowTargetChk, CurrentScreenMode
    DIM Key$

    CurrentScreenMode = UserSettings.ScreenMode

    winMisc.Pos.Width = 390
    winMisc.Pos.Height = 340
    winMisc.Pos.Left = (640 - winMisc.Pos.Width) / 2
    winMisc.Pos.Top = (scrHeight - winMisc.Pos.Height) / 2
    Obj.SetSize frmDesktop.Pos, winMisc.Pos.Left + 12, winMisc.Pos.Top + 34, winMisc.Pos.Width - 24, 118
    Obj.SetSize frmVarious.Pos, winMisc.Pos.Left + 12, frmDesktop.Pos.Top + frmDesktop.Pos.Height + 12, frmDesktop.Pos.Width, 129
    Obj.SetSize chkShowLinkDesc.Pos, frmDesktop.Pos.Left + 12, frmDesktop.Pos.Top + 16, -1, -1
    Obj.SetSize chkShowLinkTarget.Pos, frmDesktop.Pos.Left + 34, frmDesktop.Pos.Top + 38, -1, -1
    Obj.SetSize chkUseVGAMode.Pos, frmDesktop.Pos.Left + 12, frmDesktop.Pos.Top + 70, -1, -1
    Obj.SetSize chkConfLinkDel.Pos, frmDesktop.Pos.Left + 12, frmDesktop.Pos.Top + 92, -1, -1
    Obj.SetSize chkAnimUI.Pos, frmVarious.Pos.Left + 12, frmVarious.Pos.Top + 16, -1, -1
    Obj.SetSize chkConfExit.Pos, frmVarious.Pos.Left + 12, frmVarious.Pos.Top + 38, -1, -1
    Obj.SetSize chkGreyOutMsgBox.Pos, frmVarious.Pos.Left + 12, frmVarious.Pos.Top + 60, -1, -1
    Obj.SetSize chkDailyTip.Pos, frmVarious.Pos.Left + 12, frmVarious.Pos.Top + 82, -1, -1
    Obj.SetSize chkUseLastProfile.Pos, frmVarious.Pos.Left + 12, frmVarious.Pos.Top + 104, -1, -1
    Obj.SetSize btnCancel.Pos, winMisc.Pos.Left + winMisc.Pos.Width - 104, winMisc.Pos.Top + winMisc.Pos.Height - 34, -1, -1
    Obj.SetSize btnSave.Pos, winMisc.Pos.Left + winMisc.Pos.Width - 208, winMisc.Pos.Top + winMisc.Pos.Height - 34, -1, -1

    winMisc.Caption = "Other settings"
    btnCancel.Caption = "õCancel"
    btnSave.Caption = "õSave"
    chkShowLinkDesc.Checked = UserSettings.ShowLinkDescriptions
    chkShowLinkTarget.Checked = UserSettings.ShowLinkTargetFiles
    IF UserSettings.ScreenMode = scrVGA THEN
      chkUseVGAMode.Checked = True
    END IF
    chkConfLinkDel.Checked = UserSettings.ConfirmLinkDelete
    chkAnimUI.Checked = UserSettings.Animations
    chkConfExit.Checked = UserSettings.ConfirmExit
    chkGreyOutMsgBox.Checked = UserSettings.GreyoutOnMsgBox
    chkDailyTip.Checked = UserSettings.TipOfTheDay
    chkUseLastProfile.Checked = SystemSettings.UseLastProfile


    Obj.DrawWin winMisc
    Obj.DrawFrm frmDesktop, 15, SystemTheme.Shadow
    Obj.DrawFrm frmVarious, 15, SystemTheme.Shadow
    Mouse.Hide
    LINE (frmDesktop.Pos.Left + 7, frmDesktop.Pos.Top)-(frmDesktop.Pos.Left + 64, frmDesktop.Pos.Top + 1), SystemTheme.Window, B
    LINE (frmVarious.Pos.Left + 7, frmVarious.Pos.Top)-(frmVarious.Pos.Left + 116, frmVarious.Pos.Top + 1), SystemTheme.Window, B
    Mouse.Show
    Font.Print "Desktop", frmDesktop.Pos.Left + 10, frmDesktop.Pos.Top - 3, SystemTheme.WindowText, 1
    Font.Print "Various settings", frmVarious.Pos.Left + 10, frmVarious.Pos.Top - 3, SystemTheme.WindowText, 1
    Obj.DrawChk chkShowLinkDesc
    Obj.DrawChk chkShowLinkTarget
    Obj.DrawChk chkUseVGAMode
    Obj.DrawChk chkConfLinkDel
    Obj.DrawChk chkAnimUI
    Obj.DrawChk chkConfExit
    Obj.DrawChk chkGreyOutMsgBox
    Obj.DrawChk chkDailyTip
    Obj.DrawChk chkUseLastProfile
    Obj.DrawBtn btnSave, False
    Obj.DrawBtn btnCancel, False

    Font.Print "Show link õdescriptions", chkShowLinkDesc.Pos.Left + 20, chkShowLinkDesc.Pos.Top + 3, SystemTheme.WindowText, 2
    IF chkShowLinkDesc.Checked = True THEN
        Font.Print "Show link õtargets", chkShowLinkTarget.Pos.Left + 20, chkShowLinkTarget.Pos.Top + 3, SystemTheme.WindowText, 2
    ELSE
        Font.Print "Show link õtargets", chkShowLinkTarget.Pos.Left + 20, chkShowLinkTarget.Pos.Top + 3, SystemTheme.Shadow, 2
    END IF
    Font.Print "Use õVGA mode (higher resolution, but slower)", chkUseVGAMode.Pos.Left + 20, chkUseVGAMode.Pos.Top + 3, SystemTheme.WindowText, 2
    Font.Print "Confirm link õremoval", chkConfLinkDel.Pos.Left + 20, chkConfLinkDel.Pos.Top + 3, SystemTheme.WindowText, 2
    Font.Print "õAnimate user interface (sliding menus)", chkAnimUI.Pos.Left + 20, chkAnimUI.Pos.Top + 3, SystemTheme.WindowText, 2
    Font.Print "Confirm when trying to eõxit Costa", chkConfExit.Pos.Left + 20, chkConfExit.Pos.Top + 3, SystemTheme.WindowText, 2
    Font.Print "õGrey out screen while showing a messagebox", chkGreyOutMsgBox.Pos.Left + 20, chkGreyOutMsgBox.Pos.Top + 3, SystemTheme.WindowText, 2
    Font.Print "Shoõw start-up ""Tip of the Day"" messages", chkDailyTip.Pos.Left + 20, chkDailyTip.Pos.Top + 3, SystemTheme.WindowText, 2
    Font.Print "õUse last profile on start-up without asking", chkUseLastProfile.Pos.Left + 20, chkUseLastProfile.Pos.Top + 3, SystemTheme.WindowText, 2
    
    DO
        Key$ = LCASE$(INKEY$)
        
        Obj.ChkClick chkShowLinkDesc
        IF NOT ShowTargetChk = chkShowLinkDesc.Checked THEN
            ShowTargetChk = chkShowLinkDesc.Checked
            chkShowLinkDesc.Checked = NOT chkShowLinkDesc.Checked
            Key$ = "d"
        END IF

        IF ShowTargetChk = True THEN Obj.ChkClick chkShowLinkTarget
        Obj.ChkClick chkUseVGAMode
        Obj.ChkClick chkConfLinkDel
        Obj.ChkClick chkConfExit
        Obj.ChkClick chkGreyOutMsgBox
        Obj.ChkClick chkAnimUI
        Obj.ChkClick chkDailyTip
        Obj.ChkClick chkUseLastProfile

        IF Obj.BtnClick(btnCancel) OR Key$ = "c" OR Key$ = CHR$(27) THEN EXIT SUB

        IF Obj.BtnClick(btnSave) OR Key$ = "s" THEN
            
            SystemSettings.UseLastProfile = chkUseLastProfile.Checked
            
            UserSettings.Animations = chkAnimUI.Checked
            UserSettings.ShowLinkDescriptions = chkShowLinkDesc.Checked
            UserSettings.ShowLinkTargetFiles = chkShowLinkTarget.Checked
            IF chkUseVGAMode.Checked THEN
              UserSettings.ScreenMode = scrVGA
            ELSE
              UserSettings.ScreenMode = scrEGA
            END IF
            UserSettings.ConfirmLinkDelete = chkConfLinkDel.Checked
            UserSettings.ConfirmExit = chkConfExit.Checked
            UserSettings.TipOfTheDay = chkDailyTip.Checked
            UserSettings.GreyoutOnMsgBox = chkGreyOutMsgBox.Checked
            
            Sys.SaveSettings
            Sys.SaveProfile ProfileID

            IF NOT UserSettings.ScreenMode = CurrentScreenMode THEN
              Mouse.Hide
              IF UserSettings.ScreenMode = scrVGA THEN
                scrHeight = 480
                SCREEN 12
              ELSE
                scrHeight = 350
                SCREEN 9
              END IF
              Mouse.Show
            END IF
                           
            EXIT SUB
        END IF

        IF Key$ = "d" THEN
            chkShowLinkDesc.Checked = NOT chkShowLinkDesc.Checked: Obj.DrawChk chkShowLinkDesc
            IF chkShowLinkDesc.Checked = True THEN
                Font.Print "Show link õtargets", chkShowLinkTarget.Pos.Left + 20, chkShowLinkTarget.Pos.Top + 3, SystemTheme.WindowText, 2
            ELSE
                Font.Print "Show link õtargets", chkShowLinkTarget.Pos.Left + 20, chkShowLinkTarget.Pos.Top + 3, SystemTheme.Shadow, 2
            END IF
        END IF

        IF Key$ = "t" AND chkShowLinkDesc.Checked = True THEN chkShowLinkTarget.Checked = NOT chkShowLinkTarget.Checked: Obj.DrawChk chkShowLinkTarget
        IF Key$ = "v" THEN chkUseVGAMode.Checked = NOT chkUseVGAMode.Checked: Obj.DrawChk chkUseVGAMode
        IF Key$ = "r" THEN chkConfLinkDel.Checked = NOT chkConfLinkDel.Checked: Obj.DrawChk chkConfLinkDel
        IF Key$ = "a" THEN chkAnimUI.Checked = NOT chkAnimUI.Checked: Obj.DrawChk chkAnimUI
        IF Key$ = "x" THEN chkConfExit.Checked = NOT chkConfExit.Checked: Obj.DrawChk chkConfExit
        IF Key$ = "g" THEN chkGreyOutMsgBox.Checked = NOT chkGreyOutMsgBox.Checked: Obj.DrawChk chkGreyOutMsgBox
        IF Key$ = "w" THEN chkDailyTip.Checked = NOT chkDailyTip.Checked: Obj.DrawChk chkDailyTip
        IF Key$ = "u" THEN chkUseLastProfile.Checked = NOT chkUseLastProfile.Checked: Obj.DrawChk chkUseLastProfile
        


    LOOP

END SUB

' =========================================================================
'          NAME: Conf.ConfTheme()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: CONFIG.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: UI and logic for theme selector
' =========================================================================
SUB Conf.ConfTheme ()

    DIM winTheme AS WindowType
    DIM frmPreview AS FrameType
    DIM btnBack AS ButtonType, btnNext AS ButtonType
    DIM btnSave AS ButtonType, btnCancel AS ButtonType
    DIM AnimationsEnabled

    DIM OriginalTheme AS STRING
    DIM ThemeList() AS STRING

    Sys.ShowLoading

    AnimationsEnabled = UserSettings.Animations
    UserSettings.Animations = False

    'Load theme filenames into array
    DIM TmpName$, TmpCount, ActiveTheme
    REDIM ThemeList(0 TO 0) AS STRING
    TmpName$ = DIR$(Sys.Path + "DATA\THEMES\*.DAT")
    TmpCount = 0
    DO WHILE NOT TmpName$ = ""
        TmpName$ = LEFT$(TmpName$, LEN(TmpName$) - 4)
        REDIM PRESERVE ThemeList(0 TO TmpCount) AS STRING
        ThemeList(UBOUND(ThemeList)) = TmpName$
        IF UCASE$(TmpName$) = UCASE$(RTRIM$(UserSettings.ThemeFile)) THEN ActiveTheme = TmpCount
        TmpName$ = DIR$
        TmpCount = TmpCount + 1
    LOOP

    IF TmpCount = 0 THEN
        TmpCount = Sys.MsgBox("No theme files found.", "Costa could not find any theme files. Make sure that the" + CHR$(13) + "themes are in DATA\THEMES, and try again.", msgError)
        EXIT SUB
    END IF


    winTheme.Pos.Width = 324
    winTheme.Pos.Height = 347
    winTheme.Pos.Left = (640 - winTheme.Pos.Width) / 2
    winTheme.Pos.Top = (scrHeight - winTheme.Pos.Height) / 2
    winTheme.Caption = "Theme selector"
      
    frmPreview.Pos.Left = winTheme.Pos.Left + 12
    frmPreview.Pos.Top = winTheme.Pos.Top + 64
    frmPreview.Pos.Width = 300
    frmPreview.Pos.Height = 240

    Obj.SetSize btnBack.Pos, winTheme.Pos.Left + 12, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 45, 22
    btnBack.Caption = "<-"

    Obj.SetSize btnSave.Pos, winTheme.Pos.Left + 89, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 69, 22
    btnSave.Caption = "õSelect"

    Obj.SetSize btnCancel.Pos, winTheme.Pos.Left + 166, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 69, 22
    btnCancel.Caption = "õCancel"

    Obj.SetSize btnNext.Pos, winTheme.Pos.Left + 267, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 45, 22
    btnNext.Caption = "->"

    Obj.DrawWin winTheme
    Obj.DrawBtn btnBack, False
    Obj.DrawBtn btnSave, False
    Obj.DrawBtn btnCancel, False
    Obj.DrawBtn btnNext, False
    Obj.DrawFrm frmPreview, 15, SystemTheme.Shadow
    Mouse.Hide
    Font.Print "Theme name:", winTheme.Pos.Left + 12, winTheme.Pos.Top + 32, SystemTheme.WindowText, 1
    Font.Print "Theme author:", winTheme.Pos.Left + 12, winTheme.Pos.Top + 47, SystemTheme.WindowText, 1
    Mouse.Show

    'The rest of the controls are used in the preview
    DIM winPreview AS WindowType
    DIM txtPreview AS TextboxType, txtPreviewText AS STRING
    DIM btnPreview1 AS ButtonType, btnPreview2 AS ButtonType
    DIM imgPreview AS ImageType
    DIM txtListPreview AS TextboxType

    winPreview.Pos.Left = frmPreview.Pos.Left + 20
    winPreview.Pos.Top = frmPreview.Pos.Top + 20
    winPreview.Pos.Width = 260
    winPreview.Pos.Height = 145
    winPreview.Caption = appName

    txtPreview.Pos.Left = winPreview.Pos.Left + 12
    txtPreview.Pos.Top = winPreview.Pos.Top + 74
    txtPreview.Pos.Width = 236
    txtPreview.Pos.Height = 19
    txtPreviewText = "Textbox contents"
    
    Obj.SetSize btnPreview1.Pos, winPreview.Pos.Left + 14, winPreview.Pos.Top + 111, 111, 22
    btnPreview1.Caption = "Button up"

    Obj.SetSize btnPreview2.Pos, winPreview.Pos.Left + 133, winPreview.Pos.Top + 111, 111, 22
    btnPreview2.Caption = "Button down"

    imgPreview.Pos.Left = frmPreview.Pos.Left + 32
    imgPreview.Pos.Top = frmPreview.Pos.Top + 190
    imgPreview.ImageFile = "LOGO"

    Obj.SetSize txtListPreview.Pos, imgPreview.Pos.Left + 140, imgPreview.Pos.Top - 4, 116, 41

    OriginalTheme = RTRIM$(UserSettings.ThemeFile)
    UserSettings.ThemeFile = ThemeList(ActiveTheme)
    Sys.LoadTheme
                       
    DIM Key$
UpdatePreview:
    Mouse.Hide
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + frmPreview.Pos.Height - 2), SystemTheme.Desktop, BF
    LINE (winTheme.Pos.Left + 110, winTheme.Pos.Top + 29)-(winTheme.Pos.Left + 312, winTheme.Pos.Top + 59), POINT(168, frmPreview.Pos.Top + 50), BF
    Font.Print RTRIM$(SystemTheme.Name), winTheme.Pos.Left + 115, winTheme.Pos.Top + 32, POINT(winTheme.Pos.Left + 12, winTheme.Pos.Top + 32), FontNormal
    Font.Print RTRIM$(SystemTheme.Author), winTheme.Pos.Left + 115, winTheme.Pos.Top + 47, POINT(winTheme.Pos.Left + 12, winTheme.Pos.Top + 32), FontNormal
    Mouse.Show
    Obj.DrawWin winPreview
    Obj.DrawTxt txtPreview, txtPreviewText, True
    Obj.DrawBtn btnPreview1, False
    Obj.DrawBtn btnPreview2, True
    
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 32, SystemTheme.WindowText, FontHeading
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 48, SystemTheme.WindowText, FontNormal
    Font.Print "Preview link", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 4, SystemTheme.DesktopText, FontHeading
    Font.Print "preview.exe", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 18, SystemTheme.DesktopText, FontNormal

    Obj.DrawImg imgPreview
    
    Obj.DrawTxt txtListPreview, "", False
    LINE (txtListPreview.Pos.Left + 2, txtListPreview.Pos.Top + 3)-(txtListPreview.Pos.Left + txtListPreview.Pos.Width - 2, txtListPreview.Pos.Top + 15), SystemTheme.Select, BF
    Font.Print "Selected item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5, SystemTheme.SelectText, FontSystem
    Font.Print "List item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 12, SystemTheme.TextboxText, FontSystem
    Font.Print "List item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 24, SystemTheme.TextboxText, FontSystem

    UserSettings.ThemeFile = OriginalTheme
    Sys.LoadTheme


    DO
        Key$ = LCASE$(INKEY$)

        IF Obj.BtnClick(btnSave) OR Key$ = "s" OR Key$ = CHR$(13) THEN
            UserSettings.ThemeFile = ThemeList(ActiveTheme)
            Sys.SaveProfile ProfileID
            Sys.LoadTheme
            UserSettings.Animations = AnimationsEnabled
            EXIT SUB
        END IF

        IF Obj.BtnClick(btnCancel) OR Key$ = "c" OR Key$ = CHR$(27) THEN
            UserSettings.ThemeFile = OriginalTheme
            Sys.LoadTheme
            UserSettings.Animations = AnimationsEnabled
            EXIT SUB
        END IF


        IF Obj.BtnClick(btnNext) OR Key$ = CHR$(0) + "m" THEN
            ActiveTheme = ActiveTheme + 1
            IF ActiveTheme > UBOUND(ThemeList) THEN ActiveTheme = 0
            UserSettings.ThemeFile = ThemeList(ActiveTheme)
            Sys.LoadTheme
            GOTO UpdatePreview
        END IF

        IF Obj.BtnClick(btnBack) OR Key$ = CHR$(0) + "k" THEN
            ActiveTheme = ActiveTheme - 1
            IF ActiveTheme < 0 THEN ActiveTheme = UBOUND(ThemeList)
            UserSettings.ThemeFile = ThemeList(ActiveTheme)
            Sys.LoadTheme
            GOTO UpdatePreview
        END IF

    LOOP

END SUB

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

  DIM winConfig AS WindowType
  DIM btnThemes AS ButtonType, btnFileAssoc AS ButtonType, btnMisc AS ButtonType
  DIM imgThemes AS ImageType, imgFileAssoc AS ImageType, imgMisc AS ImageType
  DIM btnClose AS ButtonType

TopOfConf:

  winConfig.Pos.Width = 410
  winConfig.Pos.Height = 245
  winConfig.Pos.Left = (640 - winConfig.Pos.Width) / 2
  winConfig.Pos.Top = (scrHeight - winConfig.Pos.Height) / 2
  winConfig.Caption = "Configuration"

  Obj.SetSize btnThemes.Pos, winConfig.Pos.Left + 14, winConfig.Pos.Top + 36, 46, 46
  btnThemes.Transparent = True
  imgThemes.Pos.Left = btnThemes.Pos.Left + 7
  imgThemes.Pos.Top = btnThemes.Pos.Top + 7
  imgThemes.ImageFile = "THEMES"

  Obj.SetSize btnFileAssoc.Pos, winConfig.Pos.Left + 14, winConfig.Pos.Top + 96, 46, 46
  btnFileAssoc.Transparent = True
  imgFileAssoc.Pos.Left = btnFileAssoc.Pos.Left + 7
  imgFileAssoc.Pos.Top = btnFileAssoc.Pos.Top + 7
  imgFileAssoc.ImageFile = "DOCUMENT"

  Obj.SetSize btnMisc.Pos, winConfig.Pos.Left + 14, winConfig.Pos.Top + 156, 46, 46
  btnMisc.Transparent = True
  imgMisc.Pos.Left = btnMisc.Pos.Left + 7
  imgMisc.Pos.Top = btnMisc.Pos.Top + 7
  imgMisc.ImageFile = "CONFIG"

  Obj.SetSize btnClose.Pos, winConfig.Pos.Left + winConfig.Pos.Width - 105, winConfig.Pos.Top + winConfig.Pos.Height - 35, 92, 22
  btnClose.Caption = "õClose"

  Obj.DrawWin winConfig
  Obj.DrawBtn btnThemes, False
  Obj.DrawBtn btnFileAssoc, False
  Obj.DrawBtn btnMisc, False
  Obj.DrawBtn btnClose, False

  Font.Print "õTheme selector", btnThemes.Pos.Left + 60, btnThemes.Pos.Top, SystemTheme.WindowText, 1
  Font.Print "Change the colors of the user interface. Costa comes", btnThemes.Pos.Left + 60, btnThemes.Pos.Top + 15, SystemTheme.WindowText, 2
  Font.Print "with a collection of themes for you to choose from.", btnThemes.Pos.Left + 60, btnThemes.Pos.Top + 29, SystemTheme.WindowText, 2

  Font.Print "õFile associations", btnFileAssoc.Pos.Left + 60, btnFileAssoc.Pos.Top, SystemTheme.WindowText, 1
  Font.Print "Enable or disable file associations, and define which", btnFileAssoc.Pos.Left + 60, btnFileAssoc.Pos.Top + 15, SystemTheme.WindowText, 2
  Font.Print "programs should open different file types.", btnFileAssoc.Pos.Left + 60, btnFileAssoc.Pos.Top + 29, SystemTheme.WindowText, 2

  Font.Print "õOther settings", btnMisc.Pos.Left + 60, btnMisc.Pos.Top, SystemTheme.WindowText, 1
  Font.Print "Tweak various aspects of Costa, like how the desktop", btnMisc.Pos.Left + 60, btnMisc.Pos.Top + 15, SystemTheme.WindowText, 2
  Font.Print "acts and if certain things require confirmation.", btnMisc.Pos.Left + 60, btnMisc.Pos.Top + 29, SystemTheme.WindowText, 2

  Obj.DrawImg imgThemes
  Obj.DrawImg imgFileAssoc
  Obj.DrawImg imgMisc


  DIM Key$
  DO
    Key$ = LCASE$(INKEY$)

    IF Obj.BtnClick(btnThemes) THEN Key$ = "t"
    IF Obj.BtnClick(btnFileAssoc) THEN Key$ = "f"
    IF Obj.BtnClick(btnMisc) THEN Key$ = "o"
    IF Obj.BtnClick(btnClose) THEN Key$ = "c"

    IF Key$ = CHR$(27) OR Key$ = "c" THEN
      EXIT SUB
    END IF

    IF Key$ = "t" THEN
      Conf.ConfTheme
      Desk.DrawDesktop
      GOTO TopOfConf
    END IF

    IF Key$ = "f" THEN
      Conf.ConfAssoc
      Desk.DrawDesktop
      GOTO TopOfConf
    END IF

    IF Key$ = "o" THEN
      Conf.ConfMisc
      Desk.DrawDesktop
      GOTO TopOfConf
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

    DIM DefaultAssoc(0 TO 6) AS FileAssociationType
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

