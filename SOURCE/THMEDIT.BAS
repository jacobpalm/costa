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
DIM SHARED ThemeList() AS STRING

IF File.Exists(Sys.Path + "DATA\TEMP\RUNSTAT.TMP") = FALSE THEN
    IF NOT COMMAND$ = "/DEV" THEN
        CLS
        PRINT "This program is a part of " + appName + " and should not be executed"
        PRINT "directly from the command prompt."
        PRINT
        PRINT "To start Costa, run COSTA.BAT. If that file doesn't exist, run SETUP.EXE."
        PRINT
        END
    END IF
END IF

IF Sys.Path = "" OR File.Exists(Sys.Path + appExeName + ".EXE") = FALSE THEN
    CLS
    PRINT "The environment variable " + appExeName + ", which contains the path to Costa, is either"
    PRINT "not set or contains an invalid path."
    PRINT
    PRINT "Run SETUP.EXE to fix this issue."
    PRINT
    END
END IF

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
    Obj.SetSize txtThemeAuthor.Pos, frmPreview.Pos.Left + frmPreview.Pos.Width + 12, winThemeEdit.Pos.Top + 98, 194, 0
    Obj.SetSize btnObject.Pos, frmPreview.Pos.Left + frmPreview.Pos.Width + 12, winThemeEdit.Pos.Top + 144, 194, 0
    btnObject.Caption = "Desktop"
    SelectedObject = 1

    YPos = 0
    XPos = 0
    FOR I = 0 TO 15
        IF I = 8 THEN
            YPos = 25
            XPos = 0
        END IF
        Obj.SetSize btnColor(I).Pos, txtThemeAuthor.Pos.Left + XPos, txtThemeAuthor.Pos.Top + 82 + YPos, 19, 19
        btnColor(I).Transparent = True
        XPos = XPos + 25
    NEXT

    ThemeName$ = File.CfgRead(Sys.Path + "DATA\THEMES\" + ThmFile + ".THM", "ThemeName", "Untitled theme")
    ThemeAuthor$ = File.CfgRead(Sys.Path + "DATA\THEMES\" + ThmFile + ".THM", "ThemeAuthor", "Unknown author")

RedrawAll:
    Obj.DrawWin winThemeEdit
    Obj.DrawBtn btnSaveAs, FALSE
    Obj.DrawBtn btnSave, FALSE
    Obj.DrawBtn btnExit, FALSE
    Obj.DrawTxt txtThemeName, ThemeName$, FALSE
    Obj.DrawTxt txtThemeAuthor, ThemeAuthor$, FALSE
    Obj.DrawBtn btnObject, FALSE
    Obj.DrawFrm frmPreview, 15, Clr3DShadow
    FOR I = 0 TO 15
        Obj.DrawBtn btnColor(I), True
        Mouse.Hide
        LINE (btnColor(I).Pos.Left + 2, btnColor(I).Pos.Top + 2)-(btnColor(I).Pos.Left + btnColor(I).Pos.Width - 2, btnColor(I).Pos.Top + btnColor(I).Pos.Height - 2), I, BF
        Mouse.Show
    NEXT
    Mouse.Hide
    Font.Print "Theme name:", frmPreview.Pos.Left + frmPreview.Pos.Width + 12, winThemeEdit.Pos.Top + 34, clrWindowText, 1
    LINE (433, 174)-(440, 174), clrWindowText
    Font.Print "Theme author:", frmPreview.Pos.Left + frmPreview.Pos.Width + 12, winThemeEdit.Pos.Top + 82, clrWindowText, 1
    LINE (425, 126)-(432, 126), clrWindowText
    Font.Print "Object selected:", frmPreview.Pos.Left + frmPreview.Pos.Width + 12, winThemeEdit.Pos.Top + 130, clrWindowText, 1
    LINE (379, 222)-(386, 222), clrWindowText
    Mouse.Show

    'The rest of the controls are used in the preview
    DIM winPreview AS WindowType
    DIM txtPreview AS TextboxType, txtPreviewText AS STRING
    DIM btnPreview1 AS ButtonType, btnPreview2 AS ButtonType
    DIM imgPreview AS ImageType

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

    imgPreview.Pos.Left = frmPreview.Pos.Left + 100
    imgPreview.Pos.Top = frmPreview.Pos.Top + 190
    imgPreview.ImageFile = "LOGO"

    Theme.Load ThemeFile$

    thmClrDesktop = ClrDesktop
    thmClrDesktopText = ClrDesktopText
    thmClrWindow = ClrWindow
    thmClrButton = ClrButton
    thmClrTextbox = ClrTextbox
    thmClrTextboxText = ClrTextboxText
    thmClrWindowText = clrWindowText
    thmClrTitleBar = ClrTitleBar
    thmClrTitleBarText = ClrTitleBarText
    thmClr3DLight = Clr3DLight
    thmClr3DShadow = Clr3DShadow
    thmClrSelect = ClrSelect
    thmClrSelectText = ClrSelectText


    DIM Key$
UpdateEditPreview:
    ClrDesktop = thmClrDesktop
    ClrDesktopText = thmClrDesktopText
    ClrWindow = thmClrWindow
    ClrButton = thmClrButton
    ClrTextbox = thmClrTextbox
    ClrTextboxText = thmClrTextboxText
    clrWindowText = thmClrWindowText
    ClrTitleBar = thmClrTitleBar
    ClrTitleBarText = thmClrTitleBarText
    Clr3DLight = thmClr3DLight
    Clr3DShadow = thmClr3DShadow
    ClrSelect = thmClrSelect
    ClrSelectText = thmClrSelectText

    Mouse.Hide
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + frmPreview.Pos.Height - 2), ClrDesktop, BF
    Mouse.Show
    Obj.DrawWin winPreview
    Obj.DrawTxt txtPreview, txtPreviewText, True
    Obj.DrawBtn btnPreview1, FALSE
    Obj.DrawBtn btnPreview2, True
    Obj.DrawImg imgPreview

    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 32, clrWindowText, 1
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 48, clrWindowText, 2
    Font.Print "Preview link", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 4, ClrDesktopText, 1
    Font.Print "preview.exe", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 18, ClrDesktopText, 2

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
                    btnObject.Caption = "Titlebar"
                CASE 11
                    btnObject.Caption = "Titlebar text"
                CASE 12
                    btnObject.Caption = "Selection"
                CASE 13
                    btnObject.Caption = "Selection text"
            END SELECT
            Obj.DrawBtn btnObject, FALSE
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

            IF File.Exists(Sys.Path + "DATA\THEMES\" + TargetFile$ + ".THM") THEN
                IF NOT UCASE$(TargetFile$) = ThemeFile$ THEN
                    DIM DoSave
                    DoSave = Sys.MsgBox("File already exists", "The specified theme file already exists. Do you want" + CHR$(13) + "to owerwrite it with this theme?", msgQuest)
                    IF DoSave = FALSE THEN GOTO TopOfLoop
                END IF

                'Make sure we start with a clean file
                KILL Sys.Path + "DATA\THEMES\" + TargetFile$ + ".THM"
            END IF

            'Output to file
            ThemeFile$ = UCASE$(TargetFile$)
            winThemeEdit.Caption = "Theme editor - " + TargetFile$
            Key$ = "s" 'Triggers save button
        END IF


        IF Obj.BtnClick(btnSave) OR Key$ = "s" THEN
            TargetFile$ = "DATA\THEMES\" + ThemeFile$ + ".THM"

            File.CfgWrite TargetFile$, "ThemeName", ThemeName$
            File.CfgWrite TargetFile$, "ThemeAuthor", ThemeAuthor$

            File.CfgWrite TargetFile$, "ClrDesktop", LTRIM$(STR$(thmClrDesktop))
            File.CfgWrite TargetFile$, "ClrDesktopText", LTRIM$(STR$(thmClrDesktopText))
            File.CfgWrite TargetFile$, "ClrWindow", LTRIM$(STR$(thmClrWindow))
            File.CfgWrite TargetFile$, "ClrButton", LTRIM$(STR$(thmClrButton))
            File.CfgWrite TargetFile$, "ClrTextbox", LTRIM$(STR$(thmClrTextbox))
            File.CfgWrite TargetFile$, "ClrTextboxText", LTRIM$(STR$(thmClrTextboxText))
            File.CfgWrite TargetFile$, "ClrWindowText", LTRIM$(STR$(thmClrWindowText))
            File.CfgWrite TargetFile$, "ClrTitlebar", LTRIM$(STR$(thmClrTitleBar))
            File.CfgWrite TargetFile$, "ClrTitlebarText", LTRIM$(STR$(thmClrTitleBarText))
            File.CfgWrite TargetFile$, "Clr3DLight", LTRIM$(STR$(thmClr3DLight))
            File.CfgWrite TargetFile$, "Clr3DShadow", LTRIM$(STR$(thmClr3DShadow))
            File.CfgWrite TargetFile$, "ClrSelect", LTRIM$(STR$(thmClrSelect))
            File.CfgWrite TargetFile$, "ClrSelectText", LTRIM$(STR$(thmClrSelectText))

            ThemeChanged = FALSE

            GOTO RedrawAll
        END IF

        IF Obj.BtnClick(btnExit) OR Key$ = "x" OR Key$ = CHR$(27) THEN
            IF ThemeChanged = FALSE THEN END
            IF Sys.MsgBox("Theme has been modified", "This theme contains unsaved changes. Do you" + CHR$(13) + "want to exit and loose your changes?", msgQuest) = True THEN
                END
            END IF
        END IF
            
    LOOP

END SUB

' =========================================================================
'          NAME: Theme.Load()
'    PARAMETERS: ThmFile - string containing filename of theme to load
'       RETURNS: Nothing
'       ASSUMES: That ThmFile exists - will use default colors if not
'   CALLED FROM: THMEDIT.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Loads any theme. Sys.LoadTheme cannot be used, as it will
'                only load the theme selected in the current user profile.
' =========================================================================
SUB Theme.Load (BYVAL ThmFile AS STRING)

    IF NOT UCASE$(RIGHT$(ThmFile, 4)) = ".THM" THEN ThmFile = ThmFile + ".THM"
    ThmFile = "DATA\THEMES\" + ThmFile

    ThemeName$ = File.CfgRead(ThmFile, "ThemeName", "Untitled theme")
    ThemeAuthor$ = File.CfgRead(ThmFile, "ThemeAuthor", "Unknown author")

    ClrDesktop = VAL(File.CfgRead(ThmFile, "ClrDesktop", "3"))
    ClrDesktopText = VAL(File.CfgRead(ThmFile, "ClrDesktopText", "0"))
    ClrWindow = VAL(File.CfgRead(ThmFile, "ClrWindow", "7"))
    ClrButton = VAL(File.CfgRead(ThmFile, "ClrButton", "7"))
    ClrTextbox = VAL(File.CfgRead(ThmFile, "ClrTextbox", "15"))
    ClrTextboxText = VAL(File.CfgRead(ThmFile, "ClrTextboxText", "0"))
    clrWindowText = VAL(File.CfgRead(ThmFile, "ClrWindowText", "0"))
    ClrTitleBar = VAL(File.CfgRead(ThmFile, "ClrTitlebar", "1"))
    ClrTitleBarText = VAL(File.CfgRead(ThmFile, "ClrTitlebarText", "15"))
    Clr3DLight = VAL(File.CfgRead(ThmFile, "Clr3DLight", "7"))
    Clr3DShadow = VAL(File.CfgRead(ThmFile, "Clr3DShadow", "8"))
    ClrSelect = VAL(File.CfgRead(ThmFile, "ClrSelect", "1"))
    ClrSelectText = VAL(File.CfgRead(ThmFile, "ClrSelectText", "1"))

    
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

    IF NOT ThemeFile$ = "" THEN
        'A theme was specified as parameter

        IF LEN(ThemeFile$) > 4 THEN
            IF RIGHT$(ThemeFile$, 4) = ".THM" THEN
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

        IF File.Exists(Sys.Path + "DATA\THEMES\" + ThemeFile$ + ".THM") = FALSE THEN
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
    Obj.DrawBtn btnBack, FALSE
    Obj.DrawBtn btnEdit, FALSE
    Obj.DrawBtn btnCancel, FALSE
    Obj.DrawBtn btnNext, FALSE
    Obj.DrawFrm frmPreview, 15, Clr3DShadow
    Mouse.Hide
    Font.Print "Theme name:", winTheme.Pos.Left + 12, winTheme.Pos.Top + 32, clrWindowText, 1
    Font.Print "Theme author:", winTheme.Pos.Left + 12, winTheme.Pos.Top + 47, clrWindowText, 1
    Mouse.Show

    'The rest of the controls are used in the preview
    DIM winPreview AS WindowType
    DIM txtPreview AS TextboxType, txtPreviewText AS STRING
    DIM btnPreview1 AS ButtonType, btnPreview2 AS ButtonType
    DIM imgPreview AS ImageType

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

    imgPreview.Pos.Left = frmPreview.Pos.Left + 100
    imgPreview.Pos.Top = frmPreview.Pos.Top + 190
    imgPreview.ImageFile = "LOGO"


    'Load theme filenames into array
    DIM TmpName$, TmpCount, ActiveTheme
    REDIM ThemeList(0 TO 0) AS STRING
    TmpName$ = DIR$(Sys.Path + "DATA\THEMES\*.THM")
    TmpCount = 0
    DO WHILE NOT TmpName$ = ""
        TmpName$ = LEFT$(TmpName$, LEN(TmpName$) - 4)
        REDIM PRESERVE ThemeList(0 TO TmpCount) AS STRING
        ThemeList(UBOUND(ThemeList)) = TmpName$
        IF UCASE$(TmpName$) = UCASE$(File.CfgRead("DATA\CONFIG\COSTA.CFG", "ThemeFile", "DEFAULT")) THEN ActiveTheme = TmpCount
        TmpName$ = DIR$
        TmpCount = TmpCount + 1
    LOOP

    IF TmpCount = 0 THEN
        TmpCount = Sys.MsgBox("No theme files found.", "Costa could not find any theme files. Make sure that the" + CHR$(13) + "themes are in DATA\THEMES, and try again.", msgError)
        EXIT FUNCTION
    END IF
    
    Theme.Load ThemeList(ActiveTheme)
                       
    DIM Key$
UpdatePreview:
    Mouse.Hide
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + frmPreview.Pos.Height - 2), ClrDesktop, BF
    Mouse.Show
    Obj.DrawWin winPreview
    Obj.DrawTxt txtPreview, txtPreviewText, True
    Obj.DrawBtn btnPreview1, FALSE
    Obj.DrawBtn btnPreview2, True
    Obj.DrawImg imgPreview
                                  
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 32, clrWindowText, 1
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 48, clrWindowText, 2
    Font.Print "Preview link", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 4, ClrDesktopText, 1
    Font.Print "preview.exe", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 18, ClrDesktopText, 2

    Mouse.Hide
    LINE (winTheme.Pos.Left + 110, winTheme.Pos.Top + 29)-(winTheme.Pos.Left + 312, winTheme.Pos.Top + 59), POINT(164, 150), BF
    Mouse.Show
    Font.Print ThemeName$, winTheme.Pos.Left + 115, winTheme.Pos.Top + 32, POINT(178, 100), 2
    Font.Print ThemeAuthor$, winTheme.Pos.Left + 115, winTheme.Pos.Top + 47, POINT(178, 100), 2

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
            Theme.Load ThemeList(ActiveTheme)
            GOTO UpdatePreview
        END IF

        IF Obj.BtnClick(btnBack) OR Key$ = CHR$(0) + "k" THEN
            ActiveTheme = ActiveTheme - 1
            IF ActiveTheme < 0 THEN ActiveTheme = UBOUND(ThemeList)
            Theme.Load ThemeList(ActiveTheme)
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
    btnObject(10).Caption = "Titlebar"
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
            Obj.DrawBtn btnObject(I), FALSE
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
                IF Mouse.InArea(btnObject(I).Pos) THEN
                    Obj.DrawBtn btnObject(I), True
                    DO: LOOP WHILE Mouse.Clicked
                    IF Mouse.InArea(btnObject(I).Pos) THEN
                        Theme.SelectObject = I
                        Sys.VGALoad "THMOBJ"
                        EXIT FUNCTION
                    ELSE
                        IF NOT I = ActiveSelection THEN Obj.DrawBtn btnObject(I), FALSE
                    END IF
                END IF
            NEXT
        END IF

        IF Key$ = CHR$(0) + "h" THEN
            IF ActiveSelection > 1 THEN
                Obj.DrawBtn btnObject(ActiveSelection), FALSE
                ActiveSelection = ActiveSelection - 1
                Obj.DrawBtn btnObject(ActiveSelection), True
            END IF
        END IF

        IF Key$ = CHR$(0) + "p" THEN
            IF ActiveSelection < 13 THEN
                Obj.DrawBtn btnObject(ActiveSelection), FALSE
                ActiveSelection = ActiveSelection + 1
                Obj.DrawBtn btnObject(ActiveSelection), True
            END IF
        END IF



    LOOP


END FUNCTION

