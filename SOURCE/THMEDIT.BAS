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

IF File.Exists(Sys.Path + "DATA\TEMP\RUNSTAT.TMP") = False THEN
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

IF Sys.Path = "" OR File.Exists(Sys.Path + appExeName + ".EXE") = False THEN
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

SUB Theme.Edit (BYVAL ThmFile AS STRING)

    DIM winThemeEdit AS WindowType
    DIM frmPreview AS FrameType
    DIM btnSave AS ButtonType, btnSaveAs AS ButtonType
    DIM btnExit AS ButtonType, btnObject AS ButtonType
    DIM txtThemeName AS TextboxType, txtThemeAuthor AS TextboxType

    DIM btnColor(0 TO 15) AS ButtonType

    DIM thmClrDesktop, thmClrDesktopText, ThmClrWindow
    DIM ThmClrButton, ThmClrTextbox, ThmClrTextboxText
    DIM ThmClrWindowText, ThmClrTitleBar, ThmClrTitleBarText
    DIM ThmClr3DLight, ThmClr3DShadow, ThmClrSelect, ThmClrSelectText
    DIM I, YPos, XPos, SelectedObject
    
    winThemeEdit.Pos.Width = 528
    winThemeEdit.Pos.Height = 315
    winThemeEdit.Pos.Left = (640 - winThemeEdit.Pos.Width) / 2
    winThemeEdit.Pos.Top = (480 - winThemeEdit.Pos.Height) / 2
    winThemeEdit.Caption = "Theme editor"

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

    Obj.DrawWin winThemeEdit
    Obj.DrawBtn btnSaveAs, False
    Obj.DrawBtn btnSave, False
    Obj.DrawBtn btnExit, False
    Obj.DrawTxt txtThemeName, ThemeName$, False
    Obj.DrawTxt txtThemeAuthor, ThemeAuthor$, False
    Obj.DrawBtn btnObject, False
    Obj.DrawFrm frmPreview, 15, Clr3DShadow
    FOR I = 0 TO 15
        Obj.DrawBtn btnColor(I), True
        Mouse.Hide
        LINE (btnColor(I).Pos.Left + 2, btnColor(I).Pos.Top + 2)-(btnColor(I).Pos.Left + btnColor(I).Pos.Width - 2, btnColor(I).Pos.Top + btnColor(I).Pos.Height - 2), I, BF
        Mouse.Show
    NEXT
    Mouse.Hide
    Font.Print "Theme name:", frmPreview.Pos.Left + frmPreview.Pos.Width + 12, winThemeEdit.Pos.Top + 34, ClrWindowText, 1
    Font.Print "Theme author:", frmPreview.Pos.Left + frmPreview.Pos.Width + 12, winThemeEdit.Pos.Top + 82, ClrWindowText, 1
    Font.Print "Object selected:", frmPreview.Pos.Left + frmPreview.Pos.Width + 12, winThemeEdit.Pos.Top + 130, ClrWindowText, 1
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

    Theme.Load ThmFile

    thmClrDesktop = ClrDesktop
    thmClrDesktopText = ClrDesktopText
    ThmClrWindow = ClrWindow
    ThmClrButton = ClrButton
    ThmClrTextbox = ClrTextbox
    ThmClrTextboxText = ClrTextboxText
    ThmClrWindowText = ClrWindowText
    ThmClrTitleBar = ClrTitleBar
    ThmClrTitleBarText = ClrTitleBarText
    ThmClr3DLight = Clr3DLight
    ThmClr3DShadow = Clr3DShadow
    ThmClrSelect = ClrSelect
    ThmClrSelectText = ClrSelectText


    DIM Key$
UpdateEditPreview:
    ClrDesktop = thmClrDesktop
    ClrDesktopText = thmClrDesktopText
    ClrWindow = ThmClrWindow
    ClrButton = ThmClrButton
    ClrTextbox = ThmClrTextbox
    ClrTextboxText = ThmClrTextboxText
    ClrWindowText = ThmClrWindowText
    ClrTitleBar = ThmClrTitleBar
    ClrTitleBarText = ThmClrTitleBarText
    Clr3DLight = ThmClr3DLight
    Clr3DShadow = ThmClr3DShadow
    ClrSelect = ThmClrSelect
    ClrSelectText = ThmClrSelectText

    Mouse.Hide
    LINE (frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2)-(frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + frmPreview.Pos.Height - 2), ClrDesktop, BF
    Mouse.Show
    Obj.DrawWin winPreview
    Obj.DrawTxt txtPreview, txtPreviewText, True
    Obj.DrawBtn btnPreview1, False
    Obj.DrawBtn btnPreview2, True
    Obj.DrawImg imgPreview

    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 32, ClrWindowText, 1
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 48, ClrWindowText, 2
    Font.Print "Preview link", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 4, ClrDesktopText, 1
    Font.Print "preview.exe", imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 18, ClrDesktopText, 2

    Sys.LoadTheme

    
    DO
        LOCATE 1, 1
        PRINT STR$(Mouse.X) + "   "
        PRINT STR$(Mouse.Y) + "   "

        Key$ = LCASE$(INKEY$)

        FOR I = 0 TO 15
            IF Mouse.Clicked AND Mouse.InArea(btnColor(I).Pos) THEN
                DO: LOOP WHILE Mouse.Clicked
                IF Mouse.InArea(btnColor(I).Pos) THEN
                    SELECT CASE SelectedObject
                        CASE 1
                            thmClrDesktop = I
                        CASE 2
                            thmClrDesktopText = I
                        CASE 3
                            ThmClrWindow = I
                        CASE 4
                            ThmClrWindowText = I
                        CASE 5
                            ThmClrButton = I
                        CASE 6
                            ThmClrTextbox = I
                        CASE 7
                            ThmClrTextboxText = I
                        CASE 8
                            ThmClr3DLight = I
                        CASE 9
                            ThmClr3DShadow = I
                        CASE 10
                            ThmClrTitleBar = I
                        CASE 11
                            ThmClrTitleBarText = I
                        CASE 12
                            ThmClrSelect = I
                        CASE 13
                            ThmClrSelectText = I
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
            Obj.DrawBtn btnObject, False
        END IF

        IF Obj.BtnClick(btnSaveAs) OR Key$ = "a" THEN

            'DEBUG - ask for filename, check if file already exists, then save

        END IF


        IF Obj.BtnClick(btnSave) OR Key$ = "s" OR Key$ = CHR$(13) THEN
            
            'DEBUG - Save theme

            'EXIT SUB
        END IF

        IF Obj.BtnClick(btnExit) OR Key$ = "x" OR Key$ = CHR$(27) THEN

            'DEBUG - check if saved

            EXIT SUB

        END IF


    LOOP

END SUB

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
    ClrWindowText = VAL(File.CfgRead(ThmFile, "ClrWindowText", "0"))
    ClrTitleBar = VAL(File.CfgRead(ThmFile, "ClrTitlebar", "1"))
    ClrTitleBarText = VAL(File.CfgRead(ThmFile, "ClrTitlebarText", "15"))
    Clr3DLight = VAL(File.CfgRead(ThmFile, "Clr3DLight", "7"))
    Clr3DShadow = VAL(File.CfgRead(ThmFile, "Clr3DShadow", "8"))
    ClrSelect = VAL(File.CfgRead(ThmFile, "ClrSelect", "1"))
    ClrSelectText = VAL(File.CfgRead(ThmFile, "ClrSelectText", "1"))

    
END SUB

SUB Theme.Main ()

    DIM ThemeToEdit AS STRING

    ThemeToEdit = Theme.Select()

    IF LEN(ThemeToEdit) THEN
        Theme.Edit ThemeToEdit
    END IF

END SUB

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
    Obj.DrawFrm frmPreview, 15, Clr3DShadow
    Mouse.Hide
    Font.Print "Theme name:", winTheme.Pos.Left + 12, winTheme.Pos.Top + 32, ClrWindowText, 1
    Font.Print "Theme author:", winTheme.Pos.Left + 12, winTheme.Pos.Top + 47, ClrWindowText, 1
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
    Obj.DrawBtn btnPreview1, False
    Obj.DrawBtn btnPreview2, True
    Obj.DrawImg imgPreview
                                  
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 32, ClrWindowText, 1
    Font.Print "This is a preview of the theme.", winPreview.Pos.Left + 12, winPreview.Pos.Top + 48, ClrWindowText, 2
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
                IF Mouse.InArea(btnObject(I).Pos) THEN
                    Obj.DrawBtn btnObject(I), True
                    DO: LOOP WHILE Mouse.Clicked
                    IF Mouse.InArea(btnObject(I).Pos) THEN
                        Theme.SelectObject = I
                        Sys.VGALoad "THMOBJ"
                        EXIT FUNCTION
                    ELSE
                        IF NOT I = ActiveSelection THEN Obj.DrawBtn btnObject(I), False
                    END IF
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

