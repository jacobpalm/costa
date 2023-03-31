OPTION EXPLICIT
DEFINT A-Z

DECLARE SUB Conf.GetThemes ()
DECLARE SUB Conf.Main ()
DECLARE SUB Conf.RestoreAssoc ()
DECLARE SUB Conf.SaveAssoc (FileType AS STRING, Command AS STRING)
DECLARE SUB Conf.UpdatePreview (Area AS ANY, ThemeId%)

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

DIM SHARED ThemeList() AS STRING
DIM SHARED ThemesFound AS INTEGER
DIM SHARED ThemeActive AS INTEGER

Sys.Load

Conf.Main

SUB Conf.GetThemes ()

    'Load theme filenames into array
    DIM TmpName$, Void

    REDIM ThemeList(0 TO 0) AS STRING
    TmpName$ = DIR$(Sys.Path + "DATA\THEMES\*.DAT")
    ThemesFound = 0
    DO WHILE NOT TmpName$ = ""
        TmpName$ = LEFT$(TmpName$, LEN(TmpName$) - 4)
        REDIM PRESERVE ThemeList(0 TO ThemesFound) AS STRING
        ThemeList(UBOUND(ThemeList)) = TmpName$
        IF UCASE$(TmpName$) = UCASE$(RTRIM$(Setting.ThemeFile)) THEN ThemeActive = ThemesFound
        TmpName$ = DIR$
        ThemesFound = ThemesFound + 1
    LOOP
    
    IF ThemesFound = 0 THEN
        Void = Sys.MsgBox("No theme files found.", "Costa could not find any theme files. Make sure that the" + CHR$(13) + "themes are in DATA\THEMES, and try again.", msgError)
        EXIT SUB
    END IF

END SUB

SUB Conf.Main ()

    DIM btnExit AS ButtonType, btnBrowse AS ButtonType
    DIM btnPrevious AS ButtonType, btnNext AS ButtonType
    DIM frmSettings AS FrameType, frmAssoc AS FrameType, frmTheme AS FrameType
    DIM frmThemePreview AS FrameType
    DIM imgSetting AS ImageType, imgAssoc AS ImageType, imgTheme AS ImageType
    DIM chkSetting(4) AS CheckboxType
    DIM txtFileType AS TextboxType, txtOpenWith AS TextboxType
    
    DIM txtFileTypeText AS STRING, txtOpenWithText AS STRING
    DIM strValidate AS STRING
    DIM ThemePreviewId
    DIM Key$
    
    Obj.DrawMenu

    Conf.GetThemes

    Mouse.Hide
    LINE (0, 29)-(639, 349), Theme.Window, BF
    Mouse.Show

    Obj.SetSize btnExit.Pos, 542, 2, 92, 22
    Obj.SetSize frmSettings.Pos, 14, 43, 330, 170
    Obj.SetSize frmTheme.Pos, 358, 43, 268, 293
    Obj.SetSize frmAssoc.Pos, 14, 43 + 170 + 14, 330, 108
    Obj.SetSize imgSetting.Pos, frmSettings.Pos.Left + 14, frmSettings.Pos.Top + 14, sizeRetain, sizeRetain
    Obj.SetSize imgAssoc.Pos, frmAssoc.Pos.Left + 14, frmAssoc.Pos.Top + 14, sizeRetain, sizeRetain
    Obj.SetSize imgTheme.Pos, frmTheme.Pos.Left + 14, frmTheme.Pos.Top + 14, sizeRetain, sizeRetain

    Obj.SetSize chkSetting(0).Pos, frmSettings.Pos.Left + 14, frmSettings.Pos.Top + 14 + 32 + 10, sizeRetain, sizeRetain
    Obj.SetSize chkSetting(1).Pos, chkSetting(0).Pos.Left, chkSetting(0).Pos.Top + 22, sizeRetain, sizeRetain
    Obj.SetSize chkSetting(2).Pos, chkSetting(0).Pos.Left, chkSetting(1).Pos.Top + 22, sizeRetain, sizeRetain
    Obj.SetSize chkSetting(3).Pos, chkSetting(0).Pos.Left, chkSetting(2).Pos.Top + 22, sizeRetain, sizeRetain
    Obj.SetSize chkSetting(4).Pos, chkSetting(0).Pos.Left, chkSetting(3).Pos.Top + 22, sizeRetain, sizeRetain

    Obj.SetSize txtFileType.Pos, frmAssoc.Pos.Left + 13, frmAssoc.Pos.Top + 78, 50, sizeRetain
    Obj.SetSize txtOpenWith.Pos, txtFileType.Pos.Left + txtFileType.Pos.Width + 14, txtFileType.Pos.Top, 213, sizeRetain
    Obj.SetSize btnBrowse.Pos, txtOpenWith.Pos.Left + txtOpenWith.Pos.Width + 2, txtFileType.Pos.Top, 22, 19

    Obj.SetSize frmThemePreview.Pos, frmTheme.Pos.Left + 14, frmTheme.Pos.Top + 55, frmTheme.Pos.Width - 28, 192
    Obj.SetSize btnPrevious.Pos, frmTheme.Pos.Left + 14, frmTheme.Pos.Top + frmTheme.Pos.Height - 34, 92, 22
    Obj.SetSize btnNext.Pos, frmTheme.Pos.Left + frmTheme.Pos.Width - 92 - 14, btnPrevious.Pos.Top, 92, 22

    btnExit.Caption = "Eõxit"
    btnBrowse.Caption = "..."
    btnPrevious.Caption = "< õPrevious"
    btnNext.Caption = "õNext >"
    imgSetting.ImageFile = "CONFIG"
    imgAssoc.ImageFile = "UNKNOWN"
    imgTheme.ImageFile = "THEMES"

    chkSetting(0).Checked = Setting.ShowLinkDescriptions
    chkSetting(1).Checked = Setting.ShowLinkTargetFiles
    chkSetting(2).Checked = Setting.ConfirmLinkDelete
    chkSetting(3).Checked = Setting.ConfirmExit
    chkSetting(4).Checked = Setting.AssignFileTypes
    
    txtFileType.MaxLen = 3
    txtOpenWith.MaxLen = 50

    Obj.DrawBtn btnExit, False
    Obj.DrawBtn btnBrowse, False
    Obj.DrawBtn btnPrevious, False
    Obj.DrawBtn btnNext, False

    Obj.DrawFrm frmSettings, 15, Theme.Shadow
    Obj.DrawFrm frmAssoc, 15, Theme.Shadow
    Obj.DrawFrm frmTheme, 15, Theme.Shadow
    Obj.DrawFrm frmThemePreview, 15, Theme.Shadow

    Obj.DrawChk chkSetting(0)
    Obj.DrawChk chkSetting(1)
    Obj.DrawChk chkSetting(2)
    Obj.DrawChk chkSetting(3)
    Obj.DrawChk chkSetting(4)
    Font.Print "Show link õdescriptions", chkSetting(0).Pos.Left + 20, chkSetting(0).Pos.Top + 3, Theme.WindowText, fontNormal
    Font.Print "Show link õtargets", chkSetting(1).Pos.Left + 20, chkSetting(1).Pos.Top + 3, Theme.WindowText, fontNormal
    Font.Print "Confirm link õremoval", chkSetting(2).Pos.Left + 20, chkSetting(2).Pos.Top + 3, Theme.WindowText, fontNormal
    Font.Print "Confirm õexit", chkSetting(3).Pos.Left + 20, chkSetting(3).Pos.Top + 3, Theme.WindowText, fontNormal
    Font.Print "Assign filetõypes", chkSetting(4).Pos.Left + 20, chkSetting(4).Pos.Top + 3, Theme.WindowText, fontNormal

    Obj.DrawImg imgSetting
    Obj.DrawImg imgAssoc
    Obj.DrawImg imgTheme
    Font.Print "Settings", imgSetting.Pos.Left + 42, imgSetting.Pos.Top + 5, Theme.WindowText, fontHeading
    Font.Print "Tweak various aspects of Costa.", imgSetting.Pos.Left + 42, imgSetting.Pos.Top + 19, Theme.WindowText, fontNormal
    Font.Print "File associations", imgAssoc.Pos.Left + 42, imgAssoc.Pos.Top + 5, Theme.WindowText, fontHeading
    Font.Print "Assign extensions to programs directly.", imgAssoc.Pos.Left + 42, imgAssoc.Pos.Top + 19, Theme.WindowText, fontNormal
    Font.Print "Theme", imgTheme.Pos.Left + 42, imgTheme.Pos.Top + 5, Theme.WindowText, fontHeading
    Font.Print "Choose colors for the interface.", imgTheme.Pos.Left + 42, imgTheme.Pos.Top + 19, Theme.WindowText, fontNormal

    Obj.DrawTxt txtFileType, txtFileTypeText, False
    Obj.DrawTxt txtOpenWith, txtOpenWithText, False

    Font.Print "õFiletype", txtFileType.Pos.Left + 1, txtFileType.Pos.Top - 18, Theme.WindowText, fontHeading
    Font.Print "õOpen with", txtOpenWith.Pos.Left + 1, txtOpenWith.Pos.Top - 18, Theme.WindowText, fontHeading

    ThemePreviewId = ThemeActive
    Conf.UpdatePreview frmThemePreview.Pos, ThemePreviewId
    DO
        Key$ = LCASE$(INKEY$)

        IF ThemesFound > 0 THEN
            IF Obj.BtnClick(btnPrevious) OR Key$ = "p" OR Key$ = CHR$(0) + "k" THEN
                ThemePreviewId = ThemePreviewId - 1
                IF ThemePreviewId < 0 THEN ThemePreviewId = UBOUND(ThemeList)
                Conf.UpdatePreview frmThemePreview.Pos, ThemePreviewId
            END IF

            IF Obj.BtnClick(btnNext) OR Key$ = "n" OR Key$ = CHR$(0) + "m" THEN
                ThemePreviewId = ThemePreviewId + 1
                IF ThemePreviewId > UBOUND(ThemeList) THEN ThemePreviewId = 0
                Conf.UpdatePreview frmThemePreview.Pos, ThemePreviewId
            END IF
        END IF

        IF chkSetting(4).Checked THEN
            'DEBUG - handle file association stuff...
        END IF

        Obj.ChkClick chkSetting(0)
        Obj.ChkClick chkSetting(1)
        Obj.ChkClick chkSetting(2)
        Obj.ChkClick chkSetting(3)
        Obj.ChkClick chkSetting(4)

        IF Key$ = "d" THEN
            chkSetting(0).Checked = NOT chkSetting(0).Checked
            Obj.DrawChk chkSetting(0)
        END IF
        IF Key$ = "t" THEN
            chkSetting(1).Checked = NOT chkSetting(1).Checked
            Obj.DrawChk chkSetting(1)
        END IF
        IF Key$ = "r" THEN
            chkSetting(2).Checked = NOT chkSetting(2).Checked
            Obj.DrawChk chkSetting(2)
        END IF
        IF Key$ = "e" THEN
            chkSetting(3).Checked = NOT chkSetting(3).Checked
            Obj.DrawChk chkSetting(3)
        END IF
        IF Key$ = "y" THEN
            chkSetting(4).Checked = NOT chkSetting(4).Checked
            Obj.DrawChk chkSetting(4)
        END IF

        IF Obj.BtnClick(btnBrowse) OR Key$ = "." THEN
            IF LEN(txtFileTypeText) THEN
                Mouse.Hide
                PCOPY 0, 1
                Mouse.Show
                strValidate = File.Select("*.EXE")
                Mouse.Hide
                PCOPY 1, 0
                Mouse.Show
                IF LEN(strValidate) THEN
                    txtOpenWithText = strValidate
                    Obj.DrawTxt txtOpenWith, txtOpenWithText, False
                    Conf.SaveAssoc txtFileTypeText, txtOpenWithText
                END IF
            ELSE
                Key$ = "f" 'Gives focus to edit file type
            END IF
        END IF

        IF Obj.TxtClick(txtOpenWith) OR Key$ = "o" THEN
            IF LEN(txtFileTypeText) THEN
                strValidate = LTRIM$(RTRIM$(txtOpenWithText))
                Obj.EditTxt txtOpenWith, txtOpenWithText
                txtOpenWithText = LTRIM$(RTRIM$(txtOpenWithText))
                IF NOT txtOpenWithText = strValidate THEN
                    txtOpenWithText = UCASE$(txtOpenWithText)
                    Conf.SaveAssoc txtFileTypeText, txtOpenWithText
                    Obj.DrawTxt txtOpenWith, txtOpenWithText, False
                END IF
            ELSE
                Key$ = "f" 'Gives focus to edit file type
            END IF
        END IF

        IF Obj.TxtClick(txtFileType) OR Key$ = "f" THEN
            strValidate = txtFileTypeText
            Obj.EditTxt txtFileType, txtFileTypeText
            txtFileTypeText = LTRIM$(RTRIM$(UCASE$(txtFileTypeText)))
            IF NOT txtFileTypeText = strValidate THEN
                txtOpenWithText = File.GetAssociation(txtFileTypeText)
                Obj.DrawTxt txtFileType, txtFileTypeText, False
                Obj.DrawTxt txtOpenWith, txtOpenWithText, False
            END IF
        END IF

        IF Obj.BtnClick(btnExit) OR Key$ = "x" THEN
            IF ThemesFound > 0 THEN
                Setting.ThemeFile = ThemeList(ThemePreviewId)
            END IF
            Setting.ShowLinkDescriptions = chkSetting(0).Checked
            Setting.ShowLinkTargetFiles = chkSetting(1).Checked
            Setting.ConfirmLinkDelete = chkSetting(2).Checked
            Setting.ConfirmExit = chkSetting(3).Checked
            Setting.AssignFileTypes = chkSetting(4).Checked
            Sys.SaveSettings
            END
        END IF

    LOOP
    
END SUB

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

SUB Conf.SaveAssoc (FileType AS STRING, Command AS STRING)
    DIM FileAssociation AS FileAssociationType
    DIM FileHandle, FilePos, AssocSaved

    IF NOT File.Exists(Sys.Path + "\DATA\CONFIG\FILETYPE.DAT") THEN
        Conf.RestoreAssoc
    END IF

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

END SUB

SUB Conf.UpdatePreview (Area AS PosType, ThemeId)

    DIM winPreview AS WindowType
    DIM imgLogo AS ImageType, imgDeskLink AS ImageType
    DIM txtPreview AS TextboxType
    DIM btnPreview1 AS ButtonType, btnPreview2 AS ButtonType

    DIM CurrentTheme AS STRING
    DIM ViewWidth, ViewHeight

    CurrentTheme = Setting.ThemeFile
    Setting.ThemeFile = ThemeList(ThemeId)
    Sys.LoadTheme

    ViewWidth = Area.Width - 4
    ViewHeight = Area.Height - 4

    Obj.SetSize winPreview.Pos, 14, 12, ViewWidth - 28, 123
    Obj.SetSize imgLogo.Pos, winPreview.Pos.Top + 12, winPreview.Pos.Left + 12, sizeRetain, sizeRetain
    Obj.SetSize imgDeskLink.Pos, 14, ViewHeight - 42, sizeRetain, sizeRetain

    Obj.SetSize txtPreview.Pos, imgLogo.Pos.Left, imgLogo.Pos.Top + 45, winPreview.Pos.Width - 22, sizeRetain
    Obj.SetSize btnPreview1.Pos, winPreview.Pos.Left + 12, winPreview.Pos.Top + winPreview.Pos.Height - 34, 86, 22
    Obj.SetSize btnPreview2.Pos, winPreview.Pos.Left + winPreview.Pos.Width - 12 - btnPreview1.Pos.Width, btnPreview1.Pos.Top, btnPreview1.Pos.Width, 22

    btnPreview1.Caption = "Button"
    btnPreview2.Caption = "Button"
    imgLogo.ImageFile = "LOGO"
    imgDeskLink.ImageFile = "PAINT"

    Mouse.Hide

    'Use VIEW to limit drawing area to inside of frame
    VIEW (Area.Left + 2, Area.Top + 2)-(Area.Left + Area.Width - 2, Area.Top + Area.Height - 2)
    LINE (0, 0)-(ViewWidth, ViewHeight), Theme.Desktop, BF

    Obj.DrawWin winPreview
    Obj.DrawImg imgLogo
    Obj.DrawImg imgDeskLink

    Obj.DrawBtn btnPreview1, False
    Obj.DrawBtn btnPreview2, True

    Obj.DrawTxt txtPreview, "Example textbox", False
    
    Font.Print "Theme preview", imgLogo.Pos.Left + 42, imgLogo.Pos.Top + 5, Theme.WindowText, fontHeading
    Font.Print "This is an example.", imgLogo.Pos.Left + 42, imgLogo.Pos.Top + 19, Theme.WindowText, fontNormal

    Font.Print "Preview link", imgDeskLink.Pos.Left + 38, imgDeskLink.Pos.Top + 4, Theme.DesktopText, fontHeading
    Font.Print "preview.exe", imgDeskLink.Pos.Left + 38, imgDeskLink.Pos.Top + 18, Theme.DesktopText, fontNormal

    VIEW
    Mouse.Show
    Setting.ThemeFile = CurrentTheme
    Sys.LoadTheme

END SUB

