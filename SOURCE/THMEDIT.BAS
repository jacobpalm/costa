OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Theme.SelectObject (BYVAL CurrentSelection%) AS INTEGER
DECLARE FUNCTION Theme.Select () AS STRING
DECLARE SUB Theme.Main ()
DECLARE SUB Theme.Load (BYVAL ThmFile AS STRING)
DECLARE SUB Theme.Edit (BYVAL ThmFile AS STRING)

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

STACK 5120

DIM SHARED ThemeFile$, ThemeName$, ThemeAuthor$
DIM SHARED OriginalTheme$
DIM SHARED ThemeList() AS STRING


IF NOT COMMAND$ = "/?" AND NOT COMMAND$ = "/VER" AND NOT COMMAND$ = "/DEV" THEN
    ThemeFile$ = COMMAND$
END IF

Sys.Load

Theme.Main

' =========================================================================
'          NAME: Theme.Edit()
'    PARAMETERS: ThmFile - string containing filename of theme to edit,
'                          sans extension
'       RETURNS: Nothing
'       ASSUMES: That the file ThmFile exists
'   CALLED FROM: THMEDIT.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: The main dialog for editing a theme and saving it
' =========================================================================
SUB Theme.Edit (BYVAL ThmFile AS STRING)

    DIM winThemeEdit AS WindowType
    DIM frmPreview AS FrameType
    DIM btnSave AS ButtonType, btnSaveAs AS ButtonType
    DIM btnExit AS ButtonType, btnObject AS ButtonType
    DIM txtThemeName AS TextboxType, txtThemeAuthor AS TextboxType

    DIM btnColor(0 TO 15) AS ButtonType

    DIM thmClrDesktop, thmClrDesktopText, thmClrWindow
    DIM thmClrButton, thmClrTextbox, thmClrTextboxText
    DIM thmClrWindowText, thmClrTitleBar, thmClrTitleBarText
    DIM thmClr3DLight, thmClr3DShadow, thmClrSelect, thmClrSelectText
    DIM I, YPos, XPos, SelectedObject, ThemeChanged
    DIM TargetFile$, OriginalText$


    ThemeFile$ = ThmFile
    
    winThemeEdit.Pos.Width = 528
    winThemeEdit.Pos.Height = 315
    winThemeEdit.Pos.Left = (640 - winThemeEdit.Pos.Width) / 2
    winThemeEdit.Pos.Top = (480 - winThemeEdit.Pos.Height) / 2
    winThemeEdit.Caption = "Theme editor - " + ThmFile

    frmPreview.Pos.Left = winThemeEdit.Pos.Left + 12
    frmPreview.Pos.Top = winThemeEdit.Pos.Top + 34
    frmPreview.Pos.Width = 300
    frmPreview.Pos.Height = 240


    Obj.SetSize btnSave.Pos, winThemeEdit.Pos.Left + 12, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 69, 22
    btnSave.Caption = "Save": btnSave.HotKey = 1

    Obj.SetSize btnSaveAs.Pos, winThemeEdit.Pos.Left + 89, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 69, 22
    btnSaveAs.Caption = "Save as": btnSaveAs.HotKey = 6

    Obj.SetSize btnExit.Pos, winThemeEdit.Pos.Left + 450, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 69, 22
    btnExit.Caption = "Exit": btnExit.HotKey = 2

    Obj.SetSize txtThemeName.Pos, frmPreview.Pos.Left + frmPreview.Pos.Width + 12, winThemeEdit.Pos.Top + 50, 194, 0
    txtThemeName.MaxLen = 25
    Obj.SetSize txtThemeAuthor.Pos, frmPreview.Pos.Left + frmPreview.Pos.Width + 12, winThemeEdit.Pos.Top + 98, 194, 0
    txtThemeAuthor.MaxLen = 25
    Obj.SetSize btnObject.Pos, frmPreview.Pos.Left + frmPreview.Pos.Width + 12, winThemeEdit.Pos.Top + 146, 194, 0
    btnObject.Caption = "Desktop"
    SelectedObject = 1

    YPos = 0
    XPos = 0
    FOR I = 0 TO 15
      IF I = 8 THEN
        YPos = 25
        XPos = 0
      END IF
      Obj.SetSize btnColor(I).Pos, txtThemeAuthor.Pos.Left + XPos, txtThemeAuthor.Pos.Top + 98 + YPos, 19, 19
      btnColor(I).Transparent = True
      XPos = XPos + 25
    NEXT

    'Load data about theme to edit
    UserSettings.ThemeFile = ThemeFile$
    Sys.LoadTheme

    ThemeName$ = RTRIM$(SystemTheme.Name)
    ThemeAuthor$ = RTRIM$(SystemTheme.Author)
    thmClrDesktop = SystemTheme.Desktop
    thmClrDesktopText = SystemTheme.DesktopText
    thmClrWindow = SystemTheme.Window
    thmClrButton = SystemTheme.Button
    thmClrTextbox = SystemTheme.Textbox
    thmClrTextboxText = SystemTheme.TextboxText
    thmClrWindowText = SystemTheme.WindowText
    thmClrTitleBar = SystemTheme.TitleBar
    thmClrTitleBarText = SystemTheme.TitleBarText
    thmClr3DLight = SystemTheme.Light
    thmClr3DShadow = SystemTheme.Shadow
    thmClrSelect = SystemTheme.Select
    thmClrSelectText = SystemTheme.SelectText

    UserSettings.ThemeFile = OriginalTheme$
    Sys.LoadTheme


RedrawAll:
    Obj.DrawWin winThemeEdit
    Obj.DrawBtn btnSaveAs, False
    Obj.DrawBtn btnSave, False
    Obj.DrawBtn btnExit, False
    Obj.DrawTxt txtThemeName, ThemeName$, False
    Obj.DrawTxt txtThemeAuthor, ThemeAuthor$, False
    Obj.DrawBtn btnObject, False
    Obj.DrawFrm frmPreview, 15, SystemTheme.Shadow
    FOR I = 0 TO 15
      Obj.DrawBtn btnColor(I), True
      Mouse.Hide
      LINE (btnColor(I).Pos.Left + 2, btnColor(I).Pos.Top + 2)-(btnColor(I).Pos.Left + btnColor(I).Pos.Width - 2, btnColor(I).Pos.Top + btnColor(I).Pos.Height - 2), I, BF
      Mouse.Show
    NEXT
    Font.Print "Theme name:", frmPreview.Pos.Left + frmPreview.Pos.Width + 12, winThemeEdit.Pos.Top + 34, SystemTheme.WindowText, 1
    Font.Print "Theme author:", frmPreview.Pos.Left + frmPreview.Pos.Width + 12, winThemeEdit.Pos.Top + 82, SystemTheme.WindowText, 1
    Font.Print "Object selected:", frmPreview.Pos.Left + frmPreview.Pos.Width + 12, winThemeEdit.Pos.Top + 130, SystemTheme.WindowText, 1
    Font.Print "Color for object:", frmPreview.Pos.Left + frmPreview.Pos.Width + 12, winThemeEdit.Pos.Top + 180, SystemTheme.WindowText, 1

    Mouse.Hide
    LINE (433, 174)-(440, 174), SystemTheme.WindowText
    LINE (425, 126)-(432, 126), SystemTheme.WindowText
    LINE (379, 222)-(386, 222), SystemTheme.WindowText
    LINE (379, 272)-(386, 272), SystemTheme.WindowText
    Mouse.Show


    'The rest of the controls are used in the preview
    DIM winPreview AS WindowType
    DIM txtPreview AS TextboxType, txtPreviewText AS STRING
    DIM btnPreview1 AS ButtonType, btnPreview2 AS ButtonType
    DIM imgPreview AS ImageType
    DIM btnMenuPreview AS ButtonType

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

    Obj.SetSize btnMenuPreview.Pos, imgPreview.Pos.Left + 140, imgPreview.Pos.Top - 4, 98, 37
    btnMenuPreview.Transparent = True

    DIM Key$
UpdateEditPreview:

    SystemTheme.Desktop = thmClrDesktop
    SystemTheme.DesktopText = thmClrDesktopText
    SystemTheme.Window = thmClrWindow
    SystemTheme.Button = thmClrButton
    SystemTheme.Textbox = thmClrTextbox
    SystemTheme.TextboxText = thmClrTextboxText
    SystemTheme.WindowText = thmClrWindowText
    SystemTheme.TitleBar = thmClrTitleBar
    SystemTheme.TitleBarText = thmClrTitleBarText
    SystemTheme.Light = thmClr3DLight
    SystemTheme.Shadow = thmClr3DShadow
    SystemTheme.Select = thmClrSelect
    SystemTheme.SelectText = thmClrSelectText

    Mouse.Hide
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + frmPreview.Pos.Height - 2), SystemTheme.Desktop, BF
    Mouse.Show
    Obj.DrawWin winPreview
    Obj.DrawTxt txtPreview, txtPreviewText, True
    Obj.DrawBtn btnPreview1, False
    Obj.DrawBtn btnPreview2, True
    
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 32, SystemTheme.WindowText, 1
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 48, SystemTheme.WindowText, 2
    Font.Print "Preview link", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 4, SystemTheme.DesktopText, 1
    Font.Print "preview.exe", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 18, SystemTheme.DesktopText, 2

    Obj.DrawImg imgPreview
    Obj.DrawBtn btnMenuPreview, False

    Mouse.Hide
    LINE (btnMenuPreview.Pos.Left + 2, btnMenuPreview.Pos.Top + 2)-(btnMenuPreview.Pos.Left + btnMenuPreview.Pos.Width - 2, btnMenuPreview.Pos.Top + btnMenuPreview.Pos.Height - 2), SystemTheme.Window, BF
    LINE (btnMenuPreview.Pos.Left + 2, btnMenuPreview.Pos.Top + 3)-(btnMenuPreview.Pos.Left + btnMenuPreview.Pos.Width - 2, btnMenuPreview.Pos.Top + 18), SystemTheme.Select, BF
    LINE (btnMenuPreview.Pos.Left + 5, btnMenuPreview.Pos.Top + 17)-(btnMenuPreview.Pos.Left + 12, btnMenuPreview.Pos.Top + 17), SystemTheme.SelectText
    LINE (btnMenuPreview.Pos.Left + 5, btnMenuPreview.Pos.Top + 33)-(btnMenuPreview.Pos.Left + 12, btnMenuPreview.Pos.Top + 33), SystemTheme.WindowText
    Mouse.Show
    Font.Print "Selected item", btnMenuPreview.Pos.Left + 6, btnMenuPreview.Pos.Top + 6, SystemTheme.SelectText, 1
    Font.Print "Unselected", btnMenuPreview.Pos.Left + 6, btnMenuPreview.Pos.Top + 22, SystemTheme.WindowText, 1

    Sys.LoadTheme

TopOfLoop:
    DO
      Key$ = LCASE$(INKEY$)

      FOR I = 0 TO 15
        IF Mouse.Clicked AND Mouse.InArea(btnColor(I).Pos) THEN
          DO: LOOP WHILE Mouse.Clicked
          IF Mouse.InArea(btnColor(I).Pos) THEN
            ThemeChanged = True
            SELECT CASE SelectedObject
              CASE 1
                thmClrDesktop = I
              CASE 2
                thmClrDesktopText = I
              CASE 3
                thmClrWindow = I
              CASE 4
                thmClrWindowText = I
              CASE 5
                thmClrButton = I
              CASE 6
                thmClrTextbox = I
              CASE 7
                thmClrTextboxText = I
              CASE 8
                thmClr3DLight = I
              CASE 9
                thmClr3DShadow = I
              CASE 10
                thmClrTitleBar = I
              CASE 11
                thmClrTitleBarText = I
              CASE 12
                thmClrSelect = I
              CASE 13
                thmClrSelectText = I
            END SELECT

            GOTO UpdateEditPreview
          END IF
        END IF
      NEXT

      IF Key$ = "c" THEN

        SELECT CASE SelectedObject
          CASE 1
            thmClrDesktop = thmClrDesktop + 1
            IF thmClrDesktop > 15 THEN thmClrDesktop = 0
          CASE 2
            thmClrDesktopText = thmClrDesktopText + 1
            IF thmClrDesktopText > 15 THEN thmClrDesktopText = 0
          CASE 3
            thmClrWindow = thmClrWindow + 1
            IF thmClrWindow > 15 THEN thmClrWindow = 0
          CASE 4
            thmClrWindowText = thmClrWindowText + 1
            IF thmClrWindowText > 15 THEN thmClrWindowText = 0
          CASE 5
            thmClrButton = thmClrButton + 1
            IF thmClrButton > 15 THEN thmClrButton = 0
          CASE 6
            thmClrTextbox = thmClrTextbox + 1
            IF thmClrTextbox > 15 THEN thmClrTextbox = 0
          CASE 7
            thmClrTextboxText = thmClrTextboxText + 1
            IF thmClrTextboxText > 15 THEN thmClrTextboxText = 0
          CASE 8
            thmClr3DLight = thmClr3DLight + 1
            IF thmClr3DLight > 15 THEN thmClr3DLight = 0
          CASE 9
            thmClr3DShadow = thmClr3DShadow + 1
            IF thmClr3DShadow > 15 THEN thmClr3DShadow = 0
          CASE 10
            thmClrTitleBar = thmClrTitleBar + 1
            IF thmClrTitleBar > 15 THEN thmClrTitleBar = 0
          CASE 11
            thmClrTitleBarText = thmClrTitleBarText + 1
            IF thmClrTitleBarText > 15 THEN thmClrTitleBarText = 0
          CASE 12
            thmClrSelect = thmClrSelect + 1
            IF thmClrSelect > 15 THEN thmClrSelect = 0
          CASE 13
            thmClrSelectText = thmClrSelectText + 1
            IF thmClrSelectText > 15 THEN thmClrSelectText = 0
        END SELECT

        GOTO UpdateEditPreview
      END IF

      IF Obj.BtnClick(btnObject) OR Key$ = "o" THEN

        SelectedObject = Theme.SelectObject(SelectedObject)
        SELECT CASE SelectedObject
          CASE 1
            btnObject.Caption = "Desktop"
          CASE 2
            btnObject.Caption = "Desktop text"
          CASE 3
            btnObject.Caption = "Window"
          CASE 4
            btnObject.Caption = "Window text"
          CASE 5
            btnObject.Caption = "Button"
          CASE 6
            btnObject.Caption = "Textbox"
          CASE 7
            btnObject.Caption = "Textbox text"
          CASE 8
            btnObject.Caption = "3D light"
          CASE 9
            btnObject.Caption = "3D Shadow"
          CASE 10
            btnObject.Caption = "Titlebar and border"
          CASE 11
            btnObject.Caption = "Titlebar text"
          CASE 12
            btnObject.Caption = "Selection"
          CASE 13
            btnObject.Caption = "Selection text"
        END SELECT
        Obj.DrawBtn btnObject, False
      END IF

      IF Obj.TxtClick(txtThemeName) OR Key$ = "n" THEN
        OriginalText$ = ThemeName$
        Obj.EditTxt txtThemeName, ThemeName$
        IF NOT ThemeName$ = OriginalText$ THEN ThemeChanged = True
      END IF

      IF Obj.TxtClick(txtThemeAuthor) OR Key$ = "u" THEN
        OriginalText$ = ThemeAuthor$
        Obj.EditTxt txtThemeAuthor, ThemeAuthor$
        IF NOT ThemeAuthor$ = OriginalText$ THEN ThemeChanged = True
      END IF

      IF Obj.BtnClick(btnSaveAs) OR Key$ = "a" THEN
        TargetFile$ = Sys.InputBox("Save theme", "Type a name for the theme file below, without path or" + CHR$(13) + "extension (8 letters max, for example: MYTHEME).", "THEMES", ThemeFile$)
        IF TargetFile$ = "" THEN GOTO TopOfLoop

        IF LEN(TargetFile$) > 8 THEN
            I = Sys.MsgBox("Invalid file name", "The filename you specified was too long." + CHR$(13) + "Do not type a path or extension, only a filename" + CHR$(13) + "with a maximun lenght of 8 characters.", msgError)
            GOTO TopOfLoop
        END IF

        IF File.Exists(Sys.Path + "DATA\THEMES\" + TargetFile$ + ".DAT") THEN
            IF NOT UCASE$(TargetFile$) = ThemeFile$ THEN
                DIM DoSave
                DoSave = Sys.MsgBox("File already exists", "The specified theme file already exists. Do you want" + CHR$(13) + "to owerwrite it with this theme?", msgQuest)
                IF DoSave = False THEN GOTO TopOfLoop
            END IF

            'Make sure we start with a clean file
            KILL Sys.Path + "DATA\THEMES\" + TargetFile$ + ".DAT"
        END IF

        'Output to file
        ThemeFile$ = UCASE$(TargetFile$)
        winThemeEdit.Caption = "Theme editor - " + TargetFile$
        Key$ = "s" 'Triggers save button
      END IF


      IF Obj.BtnClick(btnSave) OR Key$ = "s" THEN
        TargetFile$ = Sys.Path + "\DATA\THEMES\" + ThemeFile$ + ".DAT"

        DIM ThemeToSave AS ThemeType
        DIM ThemeToSaveHandle
        ThemeToSave.Name = ThemeName$
        ThemeToSave.Author = ThemeAuthor$
        ThemeToSave.Desktop = thmClrDesktop
        ThemeToSave.DesktopText = thmClrDesktopText
        ThemeToSave.Window = thmClrWindow
        ThemeToSave.Button = thmClrButton
        ThemeToSave.Textbox = thmClrTextbox
        ThemeToSave.TextboxText = thmClrTextboxText
        ThemeToSave.WindowText = thmClrWindowText
        ThemeToSave.TitleBar = thmClrTitleBar
        ThemeToSave.TitleBarText = thmClrTitleBarText
        ThemeToSave.Light = thmClr3DLight
        ThemeToSave.Shadow = thmClr3DShadow
        ThemeToSave.Select = thmClrSelect
        ThemeToSave.SelectText = thmClrSelectText

        ThemeToSaveHandle = FREEFILE
        OPEN TargetFile$ FOR BINARY AS #ThemeToSaveHandle
        PUT #ThemeToSaveHandle, , ThemeToSave
        CLOSE #ThemeToSaveHandle

        ThemeChanged = False

        GOTO RedrawAll
      END IF

      IF Obj.BtnClick(btnExit) OR Key$ = "x" OR Key$ = CHR$(27) THEN
        IF ThemeChanged = False THEN END
        IF Sys.MsgBox("Theme has been modified", "This theme contains unsaved changes. Do you" + CHR$(13) + "want to exit and loose your changes?", msgQuest) = True THEN
          END
        END IF
      END IF
            
    LOOP

END SUB

' =========================================================================
'          NAME: Theme.Main()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: THMEDIT.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Main logic - shows the theme selector, and - if a theme is
'                chosen, calls the theme editor. If a parameter was passed
'                on the command line, that theme will be opened.
' ========================================================================='
SUB Theme.Main ()

    DIM ThemeToEdit AS STRING
    DIM I

    OriginalTheme$ = RTRIM$(UserSettings.ThemeFile)

    IF NOT ThemeFile$ = "" THEN
      'A theme was specified as parameter

      IF LEN(ThemeFile$) > 4 THEN
        IF RIGHT$(ThemeFile$, 4) = ".DAT" THEN
          ThemeFile$ = LEFT$(ThemeFile$, LEN(ThemeFile$) - 4)
        END IF
      END IF

      DO WHILE INSTR(ThemeFile$, "\")
        DIM SlashPos
        SlashPos = INSTR(ThemeFile$, "\")
        IF SlashPos >= LEN(ThemeFile$) THEN
          I = Sys.MsgBox("Invalid file name", "The filename you specified is invalid." + CHR$(13) + "Do not type a path or extension, only a filename" + CHR$(13) + "with a maximun lenght of 8 characters.", msgError)
          END
        END IF
        ThemeFile$ = RIGHT$(ThemeFile$, LEN(ThemeFile$) - SlashPos)
      LOOP

      IF LEN(ThemeFile$) > 8 THEN
        I = Sys.MsgBox("Invalid file name", "The filename you specified was too long." + CHR$(13) + "Do not type a path or extension, only a filename" + CHR$(13) + "with a maximun lenght of 8 characters.", msgError)
        END
      END IF

      IF File.Exists(Sys.Path + "DATA\THEMES\" + ThemeFile$ + ".DAT") = False THEN
        I = Sys.MsgBox("File not found", "The filename you specified was not found." + CHR$(13) + "Do not type a path or extension, only a filename" + CHR$(13) + "with a maximun lenght of 8 characters.", msgError)
        END
      END IF

      ThemeToEdit = ThemeFile$
    ELSE
      ThemeToEdit = Theme.Select()
    END IF

    IF LEN(ThemeToEdit) THEN
      Theme.Edit ThemeToEdit
    END IF

END SUB

' =========================================================================
'          NAME: Theme.Select()
'    PARAMETERS: None
'       RETURNS: A string with the filename of the selected theme, if any
'       ASSUMES: Nothing
'   CALLED FROM: THMEDIT.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Shows a window allowing the user to chose from among all
'                themes in DATA\THEMES directory
' =========================================================================
FUNCTION Theme.Select () AS STRING

    DIM winTheme AS WindowType
    DIM frmPreview AS FrameType
    DIM btnBack AS ButtonType, btnNext AS ButtonType
    DIM btnEdit AS ButtonType, btnCancel AS ButtonType
    
    winTheme.Pos.Width = 324
    winTheme.Pos.Height = 347
    winTheme.Pos.Left = (640 - winTheme.Pos.Width) / 2
    winTheme.Pos.Top = (480 - winTheme.Pos.Height) / 2
    winTheme.Caption = "Select theme to edit"
      
    frmPreview.Pos.Left = winTheme.Pos.Left + 12
    frmPreview.Pos.Top = winTheme.Pos.Top + 64
    frmPreview.Pos.Width = 300
    frmPreview.Pos.Height = 240

    Obj.SetSize btnBack.Pos, winTheme.Pos.Left + 12, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 45, 22
    btnBack.Caption = "<-"

    Obj.SetSize btnEdit.Pos, winTheme.Pos.Left + 89, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 69, 22
    btnEdit.Caption = "Edit": btnEdit.HotKey = 1

    Obj.SetSize btnCancel.Pos, winTheme.Pos.Left + 166, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 69, 22
    btnCancel.Caption = "Close": btnCancel.HotKey = 1

    Obj.SetSize btnNext.Pos, winTheme.Pos.Left + 267, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 45, 22
    btnNext.Caption = "->"

    Obj.DrawWin winTheme
    Obj.DrawBtn btnBack, False
    Obj.DrawBtn btnEdit, False
    Obj.DrawBtn btnCancel, False
    Obj.DrawBtn btnNext, False
    Obj.DrawFrm frmPreview, 15, SystemTheme.Shadow
    Font.Print "Theme name:", winTheme.Pos.Left + 12, winTheme.Pos.Top + 32, SystemTheme.WindowText, 1
    Font.Print "Theme author:", winTheme.Pos.Left + 12, winTheme.Pos.Top + 47, SystemTheme.WindowText, 1
    
    'The rest of the controls are used in the preview
    DIM winPreview AS WindowType
    DIM txtPreview AS TextboxType, txtPreviewText AS STRING
    DIM btnPreview1 AS ButtonType, btnPreview2 AS ButtonType
    DIM imgPreview AS ImageType
    DIM btnMenuPreview AS ButtonType

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

    Obj.SetSize btnMenuPreview.Pos, imgPreview.Pos.Left + 140, imgPreview.Pos.Top - 4, 98, 37
    btnMenuPreview.Transparent = True

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
      EXIT FUNCTION
    END IF
    
    UserSettings.ThemeFile = ThemeList(ActiveTheme)
    Sys.LoadTheme
                       
    DIM Key$
UpdatePreview:
    Mouse.Hide
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + frmPreview.Pos.Height - 2), SystemTheme.Desktop, BF
    LINE (winTheme.Pos.Left + 110, winTheme.Pos.Top + 29)-(winTheme.Pos.Left + 312, winTheme.Pos.Top + 59), POINT(170, 93), BF
    Mouse.Show
    Font.Print RTRIM$(SystemTheme.Name), winTheme.Pos.Left + 115, winTheme.Pos.Top + 32, POINT(178, 100), 2
    Font.Print RTRIM$(SystemTheme.Author), winTheme.Pos.Left + 115, winTheme.Pos.Top + 47, POINT(178, 100), 2

    Obj.DrawWin winPreview
    Obj.DrawTxt txtPreview, txtPreviewText, True
    Obj.DrawBtn btnPreview1, False
    Obj.DrawBtn btnPreview2, True
    
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 32, SystemTheme.WindowText, 1
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 48, SystemTheme.WindowText, 2
    Font.Print "Preview link", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 4, SystemTheme.DesktopText, 1
    Font.Print "preview.exe", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 18, SystemTheme.DesktopText, 2

    Obj.DrawImg imgPreview
    Obj.DrawBtn btnMenuPreview, False

    Mouse.Hide
    LINE (btnMenuPreview.Pos.Left + 2, btnMenuPreview.Pos.Top + 2)-(btnMenuPreview.Pos.Left + btnMenuPreview.Pos.Width - 2, btnMenuPreview.Pos.Top + btnMenuPreview.Pos.Height - 2), SystemTheme.Window, BF
    LINE (btnMenuPreview.Pos.Left + 2, btnMenuPreview.Pos.Top + 3)-(btnMenuPreview.Pos.Left + btnMenuPreview.Pos.Width - 2, btnMenuPreview.Pos.Top + 18), SystemTheme.Select, BF
    LINE (btnMenuPreview.Pos.Left + 5, btnMenuPreview.Pos.Top + 17)-(btnMenuPreview.Pos.Left + 12, btnMenuPreview.Pos.Top + 17), SystemTheme.SelectText
    LINE (btnMenuPreview.Pos.Left + 5, btnMenuPreview.Pos.Top + 33)-(btnMenuPreview.Pos.Left + 12, btnMenuPreview.Pos.Top + 33), SystemTheme.WindowText
    Mouse.Show
    Font.Print "Selected item", btnMenuPreview.Pos.Left + 6, btnMenuPreview.Pos.Top + 6, SystemTheme.SelectText, 1
    Font.Print "Unselected", btnMenuPreview.Pos.Left + 6, btnMenuPreview.Pos.Top + 22, SystemTheme.WindowText, 1

    UserSettings.ThemeFile = OriginalTheme$
    Sys.LoadTheme

    DO
      Key$ = LCASE$(INKEY$)

      IF Obj.BtnClick(btnEdit) OR Key$ = "e" OR Key$ = CHR$(13) THEN
        Theme.Select = ThemeList(ActiveTheme)
        EXIT FUNCTION
      END IF

      IF Obj.BtnClick(btnCancel) OR Key$ = "c" OR Key$ = CHR$(27) THEN
        Theme.Select = ""
        EXIT FUNCTION
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

END FUNCTION

' =========================================================================
'          NAME: Theme.SelectObject()
'    PARAMETERS: CurrentSelection - INT representing currently selected obj
'       RETURNS: Integer representing new selected object
'       ASSUMES: Nothing
'   CALLED FROM: THMEDIT.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Returns an integer representing a selected object, for
'                which the user can then select a color in the theme edit
'                dialog
' =========================================================================
FUNCTION Theme.SelectObject (BYVAL CurrentSelection) AS INTEGER

    DIM winSelectObject AS WindowType
    DIM btnObject(1 TO 13) AS ButtonType
    DIM Key$, I, ActiveSelection
    
    winSelectObject.Pos.Width = 224
    winSelectObject.Pos.Height = 343
    winSelectObject.Pos.Left = (640 - winSelectObject.Pos.Width) / 2
    winSelectObject.Pos.Top = (480 - winSelectObject.Pos.Height) / 2
    winSelectObject.Caption = "Select Object"

    FOR I = 1 TO 13
        Obj.SetSize btnObject(I).Pos, winSelectObject.Pos.Left + 12, winSelectObject.Pos.Top + (I * 23) + 10, 200, 22
    NEXT
    btnObject(1).Caption = "Desktop"
    btnObject(2).Caption = "Desktop text"
    btnObject(3).Caption = "Window"
    btnObject(4).Caption = "Window text"
    btnObject(5).Caption = "Button"
    btnObject(6).Caption = "Textbox"
    btnObject(7).Caption = "Textbox text"
    btnObject(8).Caption = "3D light"
    btnObject(9).Caption = "3D Shadow"
    btnObject(10).Caption = "Titlebar and border"
    btnObject(11).Caption = "Titlebar text"
    btnObject(12).Caption = "Selection"
    btnObject(13).Caption = "Selection text"

    ActiveSelection = CurrentSelection

    Sys.VGASave "THMOBJ"
    Obj.DrawWin winSelectObject
    FOR I = 1 TO 13
      IF I = CurrentSelection THEN
        Obj.DrawBtn btnObject(I), True
      ELSE
        Obj.DrawBtn btnObject(I), False
      END IF
    NEXT

    DO

      Key$ = LCASE$(INKEY$)

      IF Key$ = CHR$(13) THEN
        Theme.SelectObject = ActiveSelection
        Sys.VGALoad "THMOBJ"
        EXIT FUNCTION
      END IF

      IF Key$ = CHR$(27) THEN
        Theme.SelectObject = CurrentSelection
        Sys.VGALoad "THMOBJ"
        EXIT FUNCTION
      END IF


      IF Mouse.Clicked THEN
        FOR I = 1 TO 13
          IF Obj.BtnClick(btnObject(I)) THEN
            Theme.SelectObject = I
            Sys.VGALoad "THMOBJ"
            EXIT FUNCTION
          END IF
        NEXT
      END IF

      IF Key$ = CHR$(0) + "h" THEN
        IF ActiveSelection > 1 THEN
          Obj.DrawBtn btnObject(ActiveSelection), False
          ActiveSelection = ActiveSelection - 1
          Obj.DrawBtn btnObject(ActiveSelection), True
        END IF
      END IF

      IF Key$ = CHR$(0) + "p" THEN
        IF ActiveSelection < 13 THEN
          Obj.DrawBtn btnObject(ActiveSelection), False
          ActiveSelection = ActiveSelection + 1
          Obj.DrawBtn btnObject(ActiveSelection), True
        END IF
      END IF

    LOOP
    
END FUNCTION

