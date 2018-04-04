DECLARE SUB Theme.Main ()
OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Theme.Select () AS STRING
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

    DIM WinThemeEdit AS WindowType
    DIM frmPreview AS FrameType
    DIM btnSave AS ButtonType, btnSaveAs AS ButtonType
    DIM btnExit AS ButtonType

    DIM ThmClrDesktop, ThmClrDesktopText, ThmClrWindow
    DIM ThmClrButton, ThmClrTextbox, ThmClrTextboxText
    DIM ThmClrWindowText, ThmClrTitleBar, ThmClrTitleBarText
    DIM ThmClr3DLight, ThmClr3DShadow, ThmClrSelect, ThmClrSelectText
    
    WinThemeEdit.Pos.Width = 624
    WinThemeEdit.Pos.Height = 347
    WinThemeEdit.Pos.Left = (640 - WinThemeEdit.Pos.Width) / 2
    WinThemeEdit.Pos.Top = (480 - WinThemeEdit.Pos.Height) / 2
    WinThemeEdit.Caption = "Theme editor"

    frmPreview.Pos.Left = WinThemeEdit.Pos.Left + 12
    frmPreview.Pos.Top = WinThemeEdit.Pos.Top + 64
    frmPreview.Pos.Width = 300
    frmPreview.Pos.Height = 240


    Obj.SetSize btnSave.Pos, WinThemeEdit.Pos.Left + 12, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 69, 22
    btnSave.Caption = "Save": btnSave.HotKey = 1

    Obj.SetSize btnSaveAs.Pos, WinThemeEdit.Pos.Left + 89, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 69, 22
    btnSaveAs.Caption = "Save as": btnSaveAs.HotKey = 6

    Obj.SetSize btnExit.Pos, WinThemeEdit.Pos.Left + 267, frmPreview.Pos.Top + frmPreview.Pos.Height + 10, 69, 22
    btnExit.Caption = "Exit": btnExit.HotKey = 2

    Obj.DrawWin WinThemeEdit
    Obj.DrawBtn btnSaveAs, False
    Obj.DrawBtn btnSave, False
    Obj.DrawBtn btnExit, False
    Obj.DrawFrm frmPreview, 15, Clr3DShadow
    Mouse.Hide
    Font.Print "Theme name:", WinThemeEdit.Pos.Left + 12, WinThemeEdit.Pos.Top + 32, ClrWindowText, 1
    Font.Print "Theme author:", WinThemeEdit.Pos.Left + 12, WinThemeEdit.Pos.Top + 47, ClrWindowText, 1
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

    ThmClrDesktop = ClrDesktop
    ThmClrDesktopText = ClrDesktopText
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
    ClrDesktop = ThmClrDesktop
    ClrDesktopText = ThmClrDesktopText
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

    'DEBUG - color background of edit fields

    Theme.Load ClrThemeFile


    DO
        Key$ = LCASE$(INKEY$)

        IF Obj.BtnClick(btnSaveAs) OR Key$ = CHR$(0) + "a" THEN

            'DEBUG - ask for filename, check if file already exists, then save

        END IF


        IF Obj.BtnClick(btnSave) OR Key$ = "s" OR Key$ = CHR$(13) THEN
            
            'DEBUG - Save theme

            'EXIT SUB
        END IF

        IF Obj.BtnClick(btnExit) OR Key$ = "x" THEN

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
    winTheme.Caption = "Theme editor"
      
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
    Theme.Load ClrThemeFile


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

