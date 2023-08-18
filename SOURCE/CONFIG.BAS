OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Conf.Truncate (Text AS STRING, Font%, MaxWidth%) AS STRING
DECLARE SUB Conf.GetThemes ()
DECLARE SUB Conf.Main ()
DECLARE SUB Conf.RestoreAssoc ()
DECLARE SUB Conf.SaveAssoc (FileType AS STRING, Command AS STRING)
DECLARE SUB Conf.UpdatePreview (Area AS ANY, ThemeId%)

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

CONST LinkDesc = 0
CONST LinkTarget = 1
CONST LinkDelete = 2
CONST ConfExit = 3
CONST FileType = 4

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

    DIM btnExit AS ButtonType, btnBrowse AS ButtonType, btnAbout AS ButtonType
    DIM btnPrevious AS ButtonType, btnNext AS ButtonType
    DIM frmSettings AS FrameType, frmAssoc AS FrameType, frmTheme AS FrameType
    DIM frmThemePreview AS FrameType
    DIM imgSetting AS ImageType, imgAssoc AS ImageType, imgTheme AS ImageType
    DIM chkSetting(FileType) AS CheckboxType
    DIM txtFileType AS TextboxType, txtOpenWith AS TextboxType
    
    DIM txtFileTypeText AS STRING, txtOpenWithText AS STRING
    DIM strValidate AS STRING
    DIM ThemePreviewId
    DIM Key$
    
    Mouse.Hide
    Obj.DrawMenu
    LINE (0, 29)-(639, 349), Theme.Window, BF
    Mouse.Show
    Sys.ShowLoading

    Conf.GetThemes
    Obj.SetSize btnExit.Pos, 545, 2, 92, 22
    Obj.SetSize btnAbout.Pos, 446, 2, 92, 22
    Obj.SetSize frmSettings.Pos, 14, 43, 330, 170
    Obj.SetSize frmTheme.Pos, 358, 43, 268, 293
    Obj.SetSize frmAssoc.Pos, 14, 43 + 170 + 14, 330, 108
    Obj.SetSize imgSetting.Pos, frmSettings.Pos.Left + 14, frmSettings.Pos.Top + 14, sizeRetain, sizeRetain
    Obj.SetSize imgAssoc.Pos, frmAssoc.Pos.Left + 14, frmAssoc.Pos.Top + 14, sizeRetain, sizeRetain
    Obj.SetSize imgTheme.Pos, frmTheme.Pos.Left + 14, frmTheme.Pos.Top + 14, sizeRetain, sizeRetain

    Obj.SetSize chkSetting(LinkDesc).Pos, frmSettings.Pos.Left + 14, frmSettings.Pos.Top + 14 + 32 + 10, sizeRetain, sizeRetain
    Obj.SetSize chkSetting(LinkTarget).Pos, chkSetting(LinkDesc).Pos.Left, chkSetting(LinkDesc).Pos.Top + 22, sizeRetain, sizeRetain
    Obj.SetSize chkSetting(LinkDelete).Pos, chkSetting(LinkDesc).Pos.Left, chkSetting(LinkTarget).Pos.Top + 22, sizeRetain, sizeRetain
    Obj.SetSize chkSetting(ConfExit).Pos, chkSetting(LinkDesc).Pos.Left, chkSetting(LinkDelete).Pos.Top + 22, sizeRetain, sizeRetain
    Obj.SetSize chkSetting(FileType).Pos, chkSetting(LinkDesc).Pos.Left, chkSetting(ConfExit).Pos.Top + 22, sizeRetain, sizeRetain

    Obj.SetSize txtFileType.Pos, frmAssoc.Pos.Left + 13, frmAssoc.Pos.Top + 78, 50, sizeRetain
    Obj.SetSize txtOpenWith.Pos, txtFileType.Pos.Left + txtFileType.Pos.Width + 14, txtFileType.Pos.Top, 213, sizeRetain
    Obj.SetSize btnBrowse.Pos, txtOpenWith.Pos.Left + txtOpenWith.Pos.Width + 2, txtFileType.Pos.Top, 22, 19

    Obj.SetSize frmThemePreview.Pos, frmTheme.Pos.Left + 14, frmTheme.Pos.Top + 55, frmTheme.Pos.Width - 28, 192
    Obj.SetSize btnPrevious.Pos, frmTheme.Pos.Left + 14, frmTheme.Pos.Top + frmTheme.Pos.Height - 34, 92, 22
    Obj.SetSize btnNext.Pos, frmTheme.Pos.Left + frmTheme.Pos.Width - 92 - 14, btnPrevious.Pos.Top, 92, 22

    btnExit.Caption = "Eõxit"
    btnAbout.Caption = "õAbout..."
    btnBrowse.Caption = "..."
    btnPrevious.Caption = "< õPrevious"
    btnNext.Caption = "õNext >"
    imgSetting.ImageFile = "CONFIG"
    imgAssoc.ImageFile = "UNKNOWN"
    imgTheme.ImageFile = "THEMES"

    chkSetting(LinkDesc).Checked = Setting.ShowLinkDescriptions
    chkSetting(LinkTarget).Checked = Setting.ShowLinkTargetFiles
    chkSetting(LinkDelete).Checked = Setting.ConfirmLinkDelete
    chkSetting(ConfExit).Checked = Setting.ConfirmExit
    chkSetting(FileType).Checked = Setting.AssignFileTypes
    
    txtFileType.MaxLen = 3
    txtOpenWith.MaxLen = 50
    ThemePreviewId = ThemeActive

RedrawConf:
    Mouse.Hide
    LINE (0, 29)-(639, 349), Theme.Window, BF
    
    Obj.DrawBtn btnExit, False
    Obj.DrawBtn btnAbout, False
    Obj.DrawBtn btnBrowse, False
    Obj.DrawBtn btnPrevious, False
    Obj.DrawBtn btnNext, False

    Obj.DrawFrm frmSettings, 15, Theme.Shadow
    Obj.DrawFrm frmAssoc, 15, Theme.Shadow
    Obj.DrawFrm frmTheme, 15, Theme.Shadow
    Obj.DrawFrm frmThemePreview, 15, Theme.Shadow

    Obj.DrawChk chkSetting(LinkDesc)
    Obj.DrawChk chkSetting(LinkTarget)
    Obj.DrawChk chkSetting(LinkDelete)
    Obj.DrawChk chkSetting(ConfExit)
    Obj.DrawChk chkSetting(FileType)
    Obj.DrawImg imgSetting
    Obj.DrawImg imgAssoc
    Obj.DrawImg imgTheme

    Obj.DrawTxt txtFileType, txtFileTypeText, False
    Obj.DrawTxt txtOpenWith, txtOpenWithText, False

    Font.Print "Show icon õdescriptions", chkSetting(LinkDesc).Pos.Left + 20, chkSetting(LinkDesc).Pos.Top + 3, Theme.WindowText, fontNormal
    Font.Print "Show icon õtargets", chkSetting(LinkTarget).Pos.Left + 20, chkSetting(LinkTarget).Pos.Top + 3, Theme.WindowText, fontNormal
    Font.Print "Confirm icon õremoval", chkSetting(LinkDelete).Pos.Left + 20, chkSetting(LinkDelete).Pos.Top + 3, Theme.WindowText, fontNormal
    Font.Print "Confirm before õexiting Costa", chkSetting(ConfExit).Pos.Left + 20, chkSetting(ConfExit).Pos.Top + 3, Theme.WindowText, fontNormal
    Font.Print "Use file tõype associations", chkSetting(FileType).Pos.Left + 20, chkSetting(FileType).Pos.Top + 3, Theme.WindowText, fontNormal

    Font.Print "Settings", imgSetting.Pos.Left + 42, imgSetting.Pos.Top + 5, Theme.WindowText, fontHeading
    Font.Print "Tweak various aspects of Costa.", imgSetting.Pos.Left + 42, imgSetting.Pos.Top + 19, Theme.WindowText, fontNormal
    Font.Print "File associations", imgAssoc.Pos.Left + 42, imgAssoc.Pos.Top + 5, Theme.WindowText, fontHeading
    Font.Print "Assign file types to programs directly.", imgAssoc.Pos.Left + 42, imgAssoc.Pos.Top + 19, Theme.WindowText, fontNormal
    Font.Print "Theme", imgTheme.Pos.Left + 42, imgTheme.Pos.Top + 5, Theme.WindowText, fontHeading
    Font.Print "Choose colors for the interface.", imgTheme.Pos.Left + 42, imgTheme.Pos.Top + 19, Theme.WindowText, fontNormal

    Font.Print "õFile type", txtFileType.Pos.Left + 1, txtFileType.Pos.Top - 18, Theme.WindowText, fontHeading
    Font.Print "õOpen with", txtOpenWith.Pos.Left + 1, txtOpenWith.Pos.Top - 18, Theme.WindowText, fontHeading
    Mouse.Show

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

        Obj.ChkClick chkSetting(LinkDesc)
        Obj.ChkClick chkSetting(LinkTarget)
        Obj.ChkClick chkSetting(LinkDelete)
        Obj.ChkClick chkSetting(ConfExit)
        Obj.ChkClick chkSetting(FileType)

        IF Key$ = "d" THEN
            chkSetting(LinkDesc).Checked = NOT chkSetting(LinkDesc).Checked
            Mouse.Hide
            Obj.DrawChk chkSetting(LinkDesc)
            Mouse.Show
        END IF
        IF Key$ = "t" THEN
            chkSetting(LinkTarget).Checked = NOT chkSetting(LinkTarget).Checked
            Mouse.Hide
            Obj.DrawChk chkSetting(LinkTarget)
            Mouse.Show
        END IF
        IF Key$ = "r" THEN
            chkSetting(LinkDelete).Checked = NOT chkSetting(LinkDelete).Checked
            Mouse.Hide
            Obj.DrawChk chkSetting(LinkDelete)
            Mouse.Show
        END IF
        IF Key$ = "e" THEN
            chkSetting(ConfExit).Checked = NOT chkSetting(ConfExit).Checked
            Mouse.Hide
            Obj.DrawChk chkSetting(ConfExit)
            Mouse.Show
        END IF
        IF Key$ = "y" THEN
            chkSetting(FileType).Checked = NOT chkSetting(FileType).Checked
            Mouse.Hide
            Obj.DrawChk chkSetting(FileType)
            Mouse.Show
        END IF

        IF Obj.BtnClick(btnBrowse) OR Key$ = "." THEN
            IF LEN(txtFileTypeText) THEN
                strValidate = File.Select("*.EXE")
                IF LEN(strValidate) THEN
                    txtOpenWithText = strValidate
                    Conf.SaveAssoc txtFileTypeText, txtOpenWithText
                END IF
                GOTO RedrawConf
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
                    Mouse.Hide
                    Obj.DrawTxt txtOpenWith, txtOpenWithText, False
                    Mouse.Show
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
                Mouse.Hide
                Obj.DrawTxt txtFileType, txtFileTypeText, False
                Obj.DrawTxt txtOpenWith, txtOpenWithText, False
                Mouse.Show
            END IF
        END IF

        IF Obj.BtnClick(btnExit) OR Key$ = "x" THEN
            IF ThemesFound > 0 THEN
                Setting.ThemeFile = ThemeList(ThemePreviewId)
            END IF
            Setting.ShowLinkDescriptions = chkSetting(LinkDesc).Checked
            Setting.ShowLinkTargetFiles = chkSetting(LinkTarget).Checked
            Setting.ConfirmLinkDelete = chkSetting(LinkDelete).Checked
            Setting.ConfirmExit = chkSetting(ConfExit).Checked
            Setting.AssignFileTypes = chkSetting(FileType).Checked
            Sys.SaveSettings
            END
        END IF

        IF Obj.BtnClick(btnAbout) OR Key$ = "a" THEN
          Sys.AboutBox "Configuration Utility", "Jacob Palm", "CONFIG"
        END IF

    LOOP
    
END SUB

SUB Conf.SaveAssoc (FileType AS STRING, Command AS STRING)
    DIM FileAssociation AS FileAssociationType
    DIM FileHandle, FilePos, AssocSaved

    IF NOT File.Exists(Sys.Path + "DATA\CONFIG\FILETYPE.DAT") THEN
      'File association data not found, copy associations from default file
      'if it exists - using PUT/GET, not MS-DOS copy, as BASIC doesn't have
      'a built-in function to copy files
      IF File.Exists(Sys.Path + "DATA\CONFIG\FILETYPE.DEF") THEN
        DIM CopyHandle
        CopyHandle = FREEFILE
        OPEN Sys.Path + "DATA\CONFIG\FILETYPE.DEF" FOR BINARY AS #CopyHandle
        FileHandle = FREEFILE
        OPEN Sys.Path + "DATA\CONFIG\FILETYPE.DAT" FOR BINARY AS #FileHandle
        DO WHILE NOT EOF(CopyHandle)
          GET #CopyHandle, , FileAssociation
          PUT #FileHandle, , FileAssociation
        LOOP
        CLOSE #CopyHandle
        CLOSE #FileHandle
      END IF
    END IF

    FileHandle = FREEFILE
    OPEN Sys.Path + "DATA\CONFIG\FILETYPE.DAT" FOR BINARY AS #FileHandle

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

FUNCTION Conf.Truncate (Text AS STRING, MaxWidth, Font) AS STRING

    DIM TruncatedString AS STRING

    TruncatedString = Text
    WHILE Font.GetWidth(TruncatedString, Font) > MaxWidth AND LEN(TruncatedString) > 1
        TruncatedString = LEFT$(TruncatedString, LEN(TruncatedString) - 1)
    WEND

    Conf.Truncate = TruncatedString
    
END FUNCTION

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

    Obj.SetSize winPreview.Pos, Area.Left + 14, Area.Top + 12, ViewWidth - 28, 123
    Obj.SetSize imgLogo.Pos, winPreview.Pos.Left + 12, winPreview.Pos.Top + 12, sizeRetain, sizeRetain
    Obj.SetSize imgDeskLink.Pos, winPreview.Pos.Left, Area.Top + Area.Height - 42, sizeRetain, sizeRetain

    Obj.SetSize txtPreview.Pos, imgLogo.Pos.Left, imgLogo.Pos.Top + 45, winPreview.Pos.Width - 22, sizeRetain
    Obj.SetSize btnPreview1.Pos, winPreview.Pos.Left + 12, winPreview.Pos.Top + winPreview.Pos.Height - 34, 86, 22
    Obj.SetSize btnPreview2.Pos, winPreview.Pos.Left + winPreview.Pos.Width - 12 - btnPreview1.Pos.Width, btnPreview1.Pos.Top, btnPreview1.Pos.Width, 22

    btnPreview1.Caption = "Button"
    btnPreview2.Caption = "Button"
    imgLogo.ImageFile = "LOGO"
    imgDeskLink.ImageFile = "PAINT"

    Mouse.Hide
    LINE (Area.Left + 2, Area.Top + 2)-(Area.Left + Area.Width - 2, Area.Top + Area.Height - 2), Theme.Desktop, BF
    
    Obj.DrawWin winPreview
    Obj.DrawImg imgLogo
    Obj.DrawImg imgDeskLink

    Obj.DrawBtn btnPreview1, False
    Obj.DrawBtn btnPreview2, True

    Obj.DrawTxt txtPreview, "Example textbox", False
    
    Font.Print "Preview link", imgDeskLink.Pos.Left + 38, imgDeskLink.Pos.Top + 4, Theme.DesktopText, fontHeading
    Font.Print "preview.exe", imgDeskLink.Pos.Left + 38, imgDeskLink.Pos.Top + 18, Theme.DesktopText, fontNormal

    Font.Print Conf.Truncate(Theme.Name, 146, fontHeading), imgLogo.Pos.Left + 42, imgLogo.Pos.Top + 5, Theme.WindowText, fontHeading
    Font.Print Conf.Truncate(Theme.Author, 146, fontNormal), imgLogo.Pos.Left + 42, imgLogo.Pos.Top + 19, Theme.WindowText, fontNormal
    Mouse.Show

    Setting.ThemeFile = CurrentTheme
    Sys.LoadTheme

END SUB

