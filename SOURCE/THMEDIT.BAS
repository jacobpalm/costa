OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Theme.SelectObject (BYVAL CurrentSelection%) AS INTEGER
DECLARE FUNCTION Theme.Select () AS STRING
DECLARE SUB Theme.DrawIndicator (ActiveColor%)
DECLARE SUB Theme.Main ()
DECLARE SUB Theme.Load (BYVAL ThmFile AS STRING)
DECLARE SUB Theme.Edit (BYVAL ThmFile AS STRING)

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

STACK 5120

DIM SHARED ThemeFile$, ThemeName$, ThemeAuthor$
DIM SHARED OriginalTheme$
DIM SHARED ThemeList() AS STRING

'Shared because it is used in Theme.DrawIndicator
DIM SHARED btnColor(0 TO 15) AS ButtonType

IF NOT COMMAND$ = "/?" AND NOT COMMAND$ = "/VER" AND NOT COMMAND$ = "/DEV" THEN
    ThemeFile$ = COMMAND$
END IF

Sys.Load

Theme.Main

SUB Theme.DrawIndicator (ActiveColor)

  DIM DrawColor
  
  Mouse.Hide
  FOR DrawColor = 0 TO 15
    IF DrawColor = ActiveColor THEN
      LINE (btnColor(DrawColor).Pos.Left + 4, btnColor(DrawColor).Pos.Top + 4)-(btnColor(DrawColor).Pos.Left + btnColor(DrawColor).Pos.Width - 4, btnColor(DrawColor).Pos.Top + btnColor(DrawColor).Pos.Height - 4), 8, B
      LINE (btnColor(DrawColor).Pos.Left + 5, btnColor(DrawColor).Pos.Top + 5)-(btnColor(DrawColor).Pos.Left + btnColor(DrawColor).Pos.Width - 5, btnColor(DrawColor).Pos.Top + btnColor(DrawColor).Pos.Height - 5), 15, B
    ELSE
      LINE (btnColor(DrawColor).Pos.Left + 4, btnColor(DrawColor).Pos.Top + 4)-(btnColor(DrawColor).Pos.Left + btnColor(DrawColor).Pos.Width - 4, btnColor(DrawColor).Pos.Top + btnColor(DrawColor).Pos.Height - 4), DrawColor, BF
    END IF
  NEXT
  Mouse.Show

  DO: LOOP WHILE Mouse.Clicked

END SUB

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

    DIM frmPreview AS FrameType
    DIM btnSave AS ButtonType, btnSaveAs AS ButtonType
    DIM btnExit AS ButtonType, btnObject AS ButtonType
    DIM txtThemeName AS TextboxType, txtThemeAuthor AS TextboxType

    DIM thmClrDesktop, thmClrDesktopText, thmClrWindow
    DIM thmClrButton, thmClrTextbox, thmClrTextboxText
    DIM thmClrWindowText, thmClrTitlebar, thmClrTitlebarText
    DIM thmClr3DLight, thmClr3DShadow, thmClrSelect, thmClrSelectText
    DIM I, YPos, XPos, SelectedObject, ThemeChanged
    DIM TargetFile$, OriginalText$

    DIM OrigWindowColor, OrigWindowTextColor

    Mouse.Hide
    LINE (0, 29)-(639, 349), SystemTheme.Window, BF
    Mouse.Show

    ThemeFile$ = ThmFile

    frmPreview.Pos.Left = 12
    frmPreview.Pos.Top = 42
    frmPreview.Pos.Width = 410
    frmPreview.Pos.Height = 293

    Obj.SetSize btnSave.Pos, 2, 2, 92, 22
    btnSave.Caption = "õSave"

    Obj.SetSize btnSaveAs.Pos, 101, 2, 92, 22
    btnSaveAs.Caption = "Save õas"

    Obj.SetSize btnExit.Pos, 545, 2, 92, 22
    btnExit.Caption = "Eõxit"

    Obj.SetSize txtThemeName.Pos, frmPreview.Pos.Left + frmPreview.Pos.Width + 12, frmPreview.Pos.Top + 17, 194, 0
    txtThemeName.MaxLen = 25
    Obj.SetSize txtThemeAuthor.Pos, frmPreview.Pos.Left + frmPreview.Pos.Width + 12, txtThemeName.Pos.Top + 48, 194, 0
    txtThemeAuthor.MaxLen = 25
    Obj.SetSize btnObject.Pos, frmPreview.Pos.Left + frmPreview.Pos.Width + 12, txtThemeAuthor.Pos.Top + 48, 194, 0
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

    OrigWindowColor = SystemTheme.Window
    OrigWindowTextColor = SystemTheme.WindowText
    
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
    thmClrTitlebar = SystemTheme.TitleBar
    thmClrTitlebarText = SystemTheme.TitleBarText
    thmClr3DLight = SystemTheme.Light
    thmClr3DShadow = SystemTheme.Shadow
    thmClrSelect = SystemTheme.Select
    thmClrSelectText = SystemTheme.SelectText

    UserSettings.ThemeFile = OriginalTheme$
    Sys.LoadTheme

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
    Font.Print "Theme õname:", txtThemeName.Pos.Left, txtThemeName.Pos.Top - 16, SystemTheme.WindowText, 1
    Font.Print "Theme aõuthor:", txtThemeAuthor.Pos.Left, txtThemeAuthor.Pos.Top - 16, SystemTheme.WindowText, 1
    Font.Print "õObject selected:", frmPreview.Pos.Left + frmPreview.Pos.Width + 12, btnObject.Pos.Top - 16, SystemTheme.WindowText, 1
    Font.Print "õColor for object:", frmPreview.Pos.Left + frmPreview.Pos.Width + 12, btnColor(0).Pos.Top - 16, SystemTheme.WindowText, 1

    'Color indicator
    Mouse.Hide
    LINE (btnColor(thmClrDesktop).Pos.Left + 4, btnColor(thmClrDesktop).Pos.Top + 4)-(btnColor(thmClrDesktop).Pos.Left + btnColor(thmClrDesktop).Pos.Width - 4, btnColor(thmClrDesktop).Pos.Top + btnColor(thmClrDesktop).Pos.Height - 4), 8, B
    LINE (btnColor(thmClrDesktop).Pos.Left + 5, btnColor(thmClrDesktop).Pos.Top + 5)-(btnColor(thmClrDesktop).Pos.Left + btnColor(thmClrDesktop).Pos.Width - 5, btnColor(thmClrDesktop).Pos.Top + btnColor(thmClrDesktop).Pos.Height - 5), 15, B
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

    DIM Key$
UpdateEditPreview:

    SystemTheme.Desktop = thmClrDesktop
    SystemTheme.DesktopText = thmClrDesktopText
    SystemTheme.Window = thmClrWindow
    SystemTheme.Button = thmClrButton
    SystemTheme.Textbox = thmClrTextbox
    SystemTheme.TextboxText = thmClrTextboxText
    SystemTheme.WindowText = thmClrWindowText
    SystemTheme.TitleBar = thmClrTitlebar
    SystemTheme.TitleBarText = thmClrTitlebarText
    SystemTheme.Light = thmClr3DLight
    SystemTheme.Shadow = thmClr3DShadow
    SystemTheme.Select = thmClrSelect
    SystemTheme.SelectText = thmClrSelectText

    Mouse.Hide
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + frmPreview.Pos.Height - 2), SystemTheme.Desktop, BF
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + 27), SystemTheme.Window, BF
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 28)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + 28), SystemTheme.Shadow
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 29)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + 29), 0
    Mouse.Show

    Obj.DrawWin winPreview
    Obj.DrawTxt txtPreview, txtPreviewText, True
    Obj.DrawBtn btnPreview1, False
    Obj.DrawBtn btnPreview2, True
    Obj.DrawBtn btnPreview3, False
    
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 14, SystemTheme.WindowText, FontHeading
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 30, SystemTheme.WindowText, FontNormal
    Font.Print "Preview link", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 4, SystemTheme.DesktopText, FontHeading
    Font.Print "preview.exe", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 18, SystemTheme.DesktopText, FontNormal

    Obj.DrawImg imgPreview
    
    Obj.DrawTxt txtListPreview, "", False
    Mouse.Hide
    LINE (txtListPreview.Pos.Left + 2, txtListPreview.Pos.Top + 15)-(txtListPreview.Pos.Left + txtListPreview.Pos.Width - 2, txtListPreview.Pos.Top + 27), SystemTheme.Select, BF
    Mouse.Show
    Font.Print "List item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5, SystemTheme.TextboxText, FontSystem
    Font.Print "Selected item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 12, SystemTheme.SelectText, FontSystem
    Font.Print "List item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 24, SystemTheme.TextboxText, FontSystem
    Font.Print "List item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 36, SystemTheme.TextboxText, FontSystem
    Font.Print "List item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 48, SystemTheme.TextboxText, FontSystem

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
                thmClrTitlebar = I
              CASE 5
                thmClrWindowText = I
              CASE 6
                thmClrButton = I
              CASE 7
                thmClrTextbox = I
              CASE 8
                thmClrTextboxText = I
              CASE 9
                thmClr3DLight = I
              CASE 10
                thmClr3DShadow = I
              CASE 11
                thmClrSelect = I
              CASE 12
                thmClrSelectText = I
              CASE 13
                thmClrTitlebarText = I
            END SELECT
            Theme.DrawIndicator I
            GOTO UpdateEditPreview
          END IF
        END IF
      NEXT

      IF Key$ = "c" THEN

        SELECT CASE SelectedObject
          CASE 1
            thmClrDesktop = thmClrDesktop + 1
            IF thmClrDesktop > 15 THEN thmClrDesktop = 0
            Theme.DrawIndicator thmClrDesktop
          CASE 2
            thmClrDesktopText = thmClrDesktopText + 1
            IF thmClrDesktopText > 15 THEN thmClrDesktopText = 0
            Theme.DrawIndicator thmClrDesktopText
          CASE 3
            thmClrWindow = thmClrWindow + 1
            IF thmClrWindow > 15 THEN thmClrWindow = 0
            Theme.DrawIndicator thmClrWindow
          CASE 4
            thmClrTitlebar = thmClrTitlebar + 1
            IF thmClrTitlebar > 15 THEN thmClrTitlebar = 0
            Theme.DrawIndicator thmClrTitlebar
          CASE 5
            thmClrWindowText = thmClrWindowText + 1
            IF thmClrWindowText > 15 THEN thmClrWindowText = 0
            Theme.DrawIndicator thmClrWindowText
          CASE 6
            thmClrButton = thmClrButton + 1
            IF thmClrButton > 15 THEN thmClrButton = 0
            Theme.DrawIndicator thmClrButton
          CASE 7
            thmClrTextbox = thmClrTextbox + 1
            IF thmClrTextbox > 15 THEN thmClrTextbox = 0
            Theme.DrawIndicator thmClrTextbox
          CASE 8
            thmClrTextboxText = thmClrTextboxText + 1
            IF thmClrTextboxText > 15 THEN thmClrTextboxText = 0
            Theme.DrawIndicator thmClrTextboxText
          CASE 9
            thmClr3DLight = thmClr3DLight + 1
            IF thmClr3DLight > 15 THEN thmClr3DLight = 0
            Theme.DrawIndicator thmClr3DLight
          CASE 10
            thmClr3DShadow = thmClr3DShadow + 1
            IF thmClr3DShadow > 15 THEN thmClr3DShadow = 0
            Theme.DrawIndicator thmClr3DShadow
          CASE 11
            thmClrSelect = thmClrSelect + 1
            IF thmClrSelect > 15 THEN thmClrSelect = 0
            Theme.DrawIndicator thmClrSelect
          CASE 12
            thmClrSelectText = thmClrSelectText + 1
            IF thmClrSelectText > 15 THEN thmClrSelectText = 0
            Theme.DrawIndicator thmClrSelectText
          CASE 13
            thmClrTitlebarText = thmClrTitlebarText + 1
            IF thmClrTitlebarText > 15 THEN thmClrTitlebarText = 0
            Theme.DrawIndicator thmClrTitlebarText
        END SELECT
        ThemeChanged = True
        GOTO UpdateEditPreview
      END IF

      IF Obj.BtnClick(btnObject) OR Key$ = "o" THEN

        SelectedObject = Theme.SelectObject(SelectedObject)
        SELECT CASE SelectedObject
          CASE 1
            btnObject.Caption = "Desktop"
            Theme.DrawIndicator thmClrDesktop
          CASE 2
            btnObject.Caption = "Desktop text"
            Theme.DrawIndicator thmClrDesktopText
          CASE 3
            btnObject.Caption = "Window"
            Theme.DrawIndicator thmClrWindow
          CASE 4
            btnObject.Caption = "Window border"
            Theme.DrawIndicator thmClrTitlebar
          CASE 5
            btnObject.Caption = "Window text"
            Theme.DrawIndicator thmClrWindowText
          CASE 6
            btnObject.Caption = "Button"
            Theme.DrawIndicator thmClrButton
          CASE 7
            btnObject.Caption = "Textbox"
            Theme.DrawIndicator thmClrTextbox
          CASE 8
            btnObject.Caption = "Textbox text"
            Theme.DrawIndicator thmClrTextboxText
          CASE 9
            btnObject.Caption = "3D light"
            Theme.DrawIndicator thmClr3DLight
          CASE 10
            btnObject.Caption = "3D Shadow"
            Theme.DrawIndicator thmClr3DShadow
          CASE 11
            btnObject.Caption = "Selection"
            Theme.DrawIndicator thmClrSelect
          CASE 12
            btnObject.Caption = "Selection text"
            Theme.DrawIndicator thmClrSelectText
          CASE 13
            btnObject.Caption = "Titlebar text"
            Theme.DrawIndicator thmClrTitlebarText
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
        ThemeToSave.TitleBar = thmClrTitlebar
        ThemeToSave.TitleBarText = thmClrTitlebarText
        ThemeToSave.Light = thmClr3DLight
        ThemeToSave.Shadow = thmClr3DShadow
        ThemeToSave.Select = thmClrSelect
        ThemeToSave.SelectText = thmClrSelectText

        ThemeToSaveHandle = FREEFILE
        OPEN TargetFile$ FOR BINARY AS #ThemeToSaveHandle
        PUT #ThemeToSaveHandle, , ThemeToSave
        CLOSE #ThemeToSaveHandle

        ThemeChanged = False
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

    'Disable animations while selecting and editing themes
    UserSettings.Animations = False

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

    DIM frmPreview AS FrameType
    DIM btnBack AS ButtonType, btnNext AS ButtonType
    DIM btnEdit AS ButtonType, btnCancel AS ButtonType

    DIM OrigWindowColor, OrigWindowTextColor

    Mouse.Hide
    LINE (0, 29)-(639, 349), SystemTheme.Window, BF
    Mouse.Show
    Obj.DrawMenu

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
      IF UCASE$(TmpName$) = UCASE$(RTRIM$(UserSettings.ThemeFile)) THEN ActiveTheme = TmpCount
      TmpName$ = DIR$
      TmpCount = TmpCount + 1
    LOOP

    IF TmpCount = 0 THEN
      TmpCount = Sys.MsgBox("No theme files found.", "Costa could not find any theme files. Make sure that the" + CHR$(13) + "themes are in DATA\THEMES, and try again.", msgError)
      EXIT FUNCTION
    END IF

    frmPreview.Pos.Left = 12
    frmPreview.Pos.Top = 73
    frmPreview.Pos.Width = 615
    frmPreview.Pos.Height = 233

    Obj.SetSize btnBack.Pos, frmPreview.Pos.Left, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 45, 22
    btnBack.Caption = "<-"

    Obj.SetSize btnNext.Pos, frmPreview.Pos.Left + frmPreview.Pos.Width - 45, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 45, 22
    btnNext.Caption = "->"

    Obj.SetSize btnEdit.Pos, 2, 2, 92, 22
    btnEdit.Caption = "õEdit"

    Obj.SetSize btnCancel.Pos, 545, 2, 92, 22
    btnCancel.Caption = "õClose"

    Obj.DrawBtn btnBack, False
    Obj.DrawBtn btnEdit, False
    Obj.DrawBtn btnCancel, False
    Obj.DrawBtn btnNext, False
    Obj.DrawFrm frmPreview, 15, SystemTheme.Shadow
    Font.Print "Theme name:", frmPreview.Pos.Left, 43, SystemTheme.WindowText, 1
    Font.Print "Theme author:", frmPreview.Pos.Left, 58, SystemTheme.WindowText, 1
    
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
    
    OrigWindowColor = SystemTheme.Window
    OrigWindowTextColor = SystemTheme.WindowText

    UserSettings.ThemeFile = ThemeList(ActiveTheme)
    Sys.LoadTheme
                       
    DIM Key$
UpdatePreview:
    Mouse.Hide
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + frmPreview.Pos.Height - 2), SystemTheme.Desktop, BF
    LINE (frmPreview.Pos.Left + 99, 42)-(frmPreview.Pos.Left + 350, 71), OrigWindowColor, BF
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + 27), SystemTheme.Window, BF
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 28)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + 28), SystemTheme.Shadow
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 29)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + 29), 0
    Mouse.Show

    Font.Print RTRIM$(SystemTheme.Name), frmPreview.Pos.Left + 100, 43, OrigWindowTextColor, FontNormal
    Font.Print RTRIM$(SystemTheme.Author), frmPreview.Pos.Left + 100, 58, OrigWindowTextColor, FontNormal
    
    Obj.DrawWin winPreview
    Obj.DrawTxt txtPreview, txtPreviewText, True
    Obj.DrawBtn btnPreview1, False
    Obj.DrawBtn btnPreview2, True
    Obj.DrawBtn btnPreview3, False
    
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 14, SystemTheme.WindowText, FontHeading
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 30, SystemTheme.WindowText, FontNormal
    Font.Print "Preview link", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 4, SystemTheme.DesktopText, FontHeading
    Font.Print "preview.exe", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 18, SystemTheme.DesktopText, FontNormal

    Obj.DrawImg imgPreview
    
    Obj.DrawTxt txtListPreview, "", False
    Mouse.Hide
    LINE (txtListPreview.Pos.Left + 2, txtListPreview.Pos.Top + 15)-(txtListPreview.Pos.Left + txtListPreview.Pos.Width - 2, txtListPreview.Pos.Top + 27), SystemTheme.Select, BF
    Mouse.Show
    Font.Print "List item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5, SystemTheme.TextboxText, FontSystem
    Font.Print "Selected item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 12, SystemTheme.SelectText, FontSystem
    Font.Print "List item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 24, SystemTheme.TextboxText, FontSystem
    Font.Print "List item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 36, SystemTheme.TextboxText, FontSystem
    Font.Print "List item", txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 48, SystemTheme.TextboxText, FontSystem

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
    DIM btnObject(1 TO 12) AS ButtonType
    DIM Key$, I, ActiveSelection
    
    winSelectObject.Pos.Width = 226
    winSelectObject.Pos.Height = 304
    winSelectObject.Pos.Left = (640 - winSelectObject.Pos.Width) / 2
    winSelectObject.Pos.Top = (350 - winSelectObject.Pos.Height) / 2
    
    FOR I = 1 TO 12
        Obj.SetSize btnObject(I).Pos, winSelectObject.Pos.Left + 13, winSelectObject.Pos.Top + (I * 23) - 8, 200, 22
    NEXT
    btnObject(1).Caption = "Desktop"
    btnObject(2).Caption = "Desktop text"
    btnObject(3).Caption = "Window"
    btnObject(4).Caption = "Window border"
    btnObject(5).Caption = "Window text"
    btnObject(6).Caption = "Button"
    btnObject(7).Caption = "Textbox"
    btnObject(8).Caption = "Textbox text"
    btnObject(9).Caption = "3D light"
    btnObject(10).Caption = "3D Shadow"
    btnObject(11).Caption = "Selection"
    btnObject(12).Caption = "Selection text"
    'btnObject(13).Caption = "Titlebar text"

    ActiveSelection = CurrentSelection

    Mouse.Hide
    PCOPY 0, 1
    Mouse.Show

    Obj.DrawWin winSelectObject
    FOR I = 1 TO 12
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
        Mouse.Hide
        PCOPY 1, 0
        Mouse.Show
        EXIT FUNCTION
      END IF

      IF Key$ = CHR$(27) THEN
        Theme.SelectObject = CurrentSelection
        Mouse.Hide
        PCOPY 1, 0
        Mouse.Show
        EXIT FUNCTION
      END IF


      IF Mouse.Clicked THEN
        FOR I = 1 TO 12
          IF Obj.BtnClick(btnObject(I)) THEN
            Theme.SelectObject = I
            Mouse.Hide
            PCOPY 1, 0
            Mouse.Show
            EXIT FUNCTION
          END IF
        NEXT
      END IF

      IF Key$ = CHR$(0) + "h" THEN
        Obj.DrawBtn btnObject(ActiveSelection), False
        IF ActiveSelection > 1 THEN
          ActiveSelection = ActiveSelection - 1
        ELSE
          ActiveSelection = UBOUND(btnObject)
        END IF
        Obj.DrawBtn btnObject(ActiveSelection), True
      END IF

      IF Key$ = CHR$(0) + "p" THEN
        Obj.DrawBtn btnObject(ActiveSelection), False
        IF ActiveSelection < 12 THEN
          ActiveSelection = ActiveSelection + 1
        ELSE
          ActiveSelection = 1
        END IF
        Obj.DrawBtn btnObject(ActiveSelection), True
      END IF

    LOOP
    
END FUNCTION

