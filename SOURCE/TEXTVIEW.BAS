OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION TView.LoadFile% (TargetFile AS STRING)
DECLARE SUB TView.DrawText (StartLine%)
DECLARE SUB TView.Main (FileToView AS STRING)

CONST MaxLinesShown = 19

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

COMMON SHARED FileData() AS STRING

STACK 6144

Sys.Load

TView.Main COMMAND$

' =========================================================================
'          NAME: TView.DrawText()
'    PARAMETERS: StartLine - the array position of the first line to print
'       RETURNS: Nothing
'       ASSUMES: That the array position exists
'   CALLED FROM: TEXTVIEW.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Writes file content to the main textbox
' =========================================================================
SUB TView.DrawText (StartLine)

    DIM LineCount

    Mouse.Hide
    FOR LineCount = StartLine TO StartLine + MaxLinesShown
        IF NOT LineCount > UBOUND(FileData) THEN
            LINE (7, (15 * (LineCount - StartLine + 1)) + 22)-(633, 15 * (LineCount - StartLine + 1) + 36), Theme.Textbox, BF
            Font.Print FileData(LineCount), 9, (15 * (LineCount - StartLine + 1)) + 24, Theme.TextboxText, FontNormal
        END IF
    NEXT
    Mouse.Show

END SUB

' =========================================================================
'          NAME: TView.LoadFile()
'    PARAMETERS: TargetFile - filename of the file to load
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: TEXTVIEW.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Loads the file into memory, in an array of strings
' =========================================================================
FUNCTION TView.LoadFile (TargetFile AS STRING)

    DIM FileHandle, TrimLine

    IF NOT File.Exists(TargetFile) THEN
        FileHandle = Sys.MsgBox("File not found", "Textviewer could not find the file you are trying to load.", msgError)
        TView.LoadFile = False
        EXIT FUNCTION
    END IF

    Sys.ShowLoading

    FileHandle = FREEFILE
    OPEN TargetFile FOR INPUT AS #FileHandle

    REDIM FileData(1 TO 1) AS STRING
    ON LOCAL ERROR GOTO TViewLoadErr
    DO WHILE NOT EOF(FileHandle)
        LINE INPUT #FileHandle, FileData(UBOUND(FileData))

        DO WHILE Font.GetWidth(FileData(UBOUND(FileData)), FontNormal) > 622
            FOR TrimLine = LEN(FileData(UBOUND(FileData))) TO 1 STEP -1
                IF Font.GetWidth(LEFT$(FileData(UBOUND(FileData)), TrimLine), FontNormal) < 622 THEN
                    REDIM PRESERVE FileData(1 TO UBOUND(FileData) + 1) AS STRING
                    FileData(UBOUND(FileData)) = RIGHT$(FileData(UBOUND(FileData) - 1), LEN(FileData(UBOUND(FileData) - 1)) - TrimLine)
                    FileData(UBOUND(FileData) - 1) = LEFT$(FileData(UBOUND(FileData) - 1), TrimLine)
                    EXIT FOR
                END IF
            NEXT
        LOOP

        IF NOT EOF(FileHandle) THEN REDIM PRESERVE FileData(1 TO UBOUND(FileData) + 1) AS STRING
    LOOP
    REDIM PRESERVE FileData(1 TO UBOUND(FileData) + 2) AS STRING
    FileData(UBOUND(FileData)) = "* end of file *"
    ON LOCAL ERROR GOTO 0

    CLOSE #FileHandle

    TView.LoadFile = True
    EXIT FUNCTION

TViewLoadErr:
    REDIM FileData(1) AS STRING
    DIM ErrMsg AS STRING, Dummy
    IF ERR = 6 OR ERR = 7 OR ERR = 9 OR ERR = 14 THEN
        ErrMsg = "Your computer does not have enough free memory" + CHR$(13) + "to load this file."
    ELSE
        ErrMsg = "An unknown error occurred while trying" + CHR$(13) + "to load the file."
    END IF
    Dummy = Sys.MsgBox("Could not load file", ErrMsg, msgError)
    Mouse.Hide
    LINE (265, 223)-(375, 257), Theme.Textbox, BF
    Mouse.Show
    TView.LoadFile = False
    EXIT FUNCTION
    RESUME NEXT
END FUNCTION

' =========================================================================
'          NAME: TView.Main()
'    PARAMETERS: FileToView - filename of file to view, if any
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Main UI + logic of the TextViewer accessory
' =========================================================================
SUB TView.Main (FileToView AS STRING)

    DIM btnOpen AS ButtonType, btnAbout AS ButtonType, btnExit AS ButtonType
    DIM btnPageUp AS ButtonType, btnPageDown AS ButtonType
    DIM txtEditor AS TextboxType

    DIM Filename AS STRING, OldFileName AS STRING
    DIM StartLine, OldStartLine, FileOpened, OldFileOpened
    DIM LineMove, LineData(2371)

    Obj.SetSize btnOpen.Pos, 3, 2, 92, 22
    Obj.SetSize btnPageUp.Pos, 102, 2, 92, 22
    Obj.SetSize btnPageDown.Pos, 201, 2, 92, 22
    Obj.SetSize btnAbout.Pos, 446, 2, 92, 22
    Obj.SetSize btnExit.Pos, 545, 2, 92, 22
    Obj.SetSize txtEditor.Pos, 2, 32, 635, 314

    btnOpen.Caption = HotkeySymbol + "Open file..."
    btnPageUp.Caption = "Page " + HotkeySymbol + "up"
    btnPageDown.Caption = "Page " + HotkeySymbol + "down"
    btnAbout.Caption = HotkeySymbol + "About..."
    btnExit.Caption = "E" + HotkeySymbol + "xit"

    IF LEN(LTRIM$(RTRIM$(FileToView))) THEN
      Filename = LTRIM$(RTRIM$(FileToView))
      IF NOT File.Exists(Filename) THEN
        FileOpened = Sys.MsgBox("File not found", FileToView + CHR$(13) + "Textviewer could not find the file you are trying to load.", msgError)
        EXIT SUB
      ELSE
        FileOpened = TView.LoadFile(Filename)
      END IF
    ELSE
      REDIM FileData(0) AS STRING
    END IF

    Mouse.Hide
    Obj.DrawMenu
    LINE (0, 29)-(639, 349), Theme.Window, BF
    Obj.DrawBtn btnOpen, False

    Obj.DrawBtn btnAbout, False
    Obj.DrawBtn btnExit, False
    Obj.DrawTxt txtEditor, "", False
    Mouse.Show

StartOfAll:

    Mouse.Hide
    IF FileOpened AND UBOUND(FileData) > 27 THEN
      'Only visible when file opened
      Obj.DrawBtn btnPageUp, False
      Obj.DrawBtn btnPageDown, False
    ELSEIF FileOpened THEN
      'Hide when file opened but not longer than what fits on screen
      LINE (102, 2)-(293, 24), Theme.Window, BF
    END IF
    Mouse.Show

    IF FileOpened THEN
      StartLine = 1
      TView.DrawText StartLine
    END IF
    
    DIM Key$
    DO
      Key$ = LCASE$(INKEY$)

      'Key up
      IF Key$ = CHR$(0) + "h" AND FileOpened THEN
        OldStartLine = StartLine
        StartLine = StartLine - 1
        IF StartLine = 0 THEN StartLine = 1
        IF NOT StartLine = OldStartLine THEN
          Mouse.Hide

          FOR LineMove = MaxLinesShown TO 1 STEP -1
            GET (7, (15 * (LineMove)) + 21)-(633, 15 * (LineMove) + 35), LineData
            PUT (7, (15 * (LineMove + 1)) + 21), LineData, PSET
          NEXT
          LINE (7, (15 * (1)) + 21)-(633, 15 * (1) + 35), Theme.Textbox, BF
          Font.Print FileData(StartLine), 9, (15 * (1)) + 22, Theme.TextboxText, FontNormal

          Mouse.Show
        END IF
      END IF

      'Key down
      IF Key$ = CHR$(0) + "p" AND FileOpened THEN
        OldStartLine = StartLine
        StartLine = StartLine + 1
        IF StartLine > UBOUND(FileData) - 26 THEN
          StartLine = UBOUND(FileData) - 26
          IF StartLine < 1 THEN StartLine = 1
        END IF
        IF NOT StartLine = OldStartLine THEN
          Mouse.Hide
          FOR LineMove = 1 TO MaxLinesShown
            GET (7, (15 * (LineMove + 1)) + 22)-(633, 15 * (LineMove + 1) + 36), LineData
            PUT (7, (15 * (LineMove)) + 22), LineData, PSET
          NEXT
          LINE (7, (15 * (MaxLinesShown + 1)) + 21)-(633, 15 * (MaxLinesShown + 1) + 35), Theme.Textbox, BF
          Font.Print FileData(StartLine + MaxLinesShown), 9, (15 * (MaxLinesShown + 1)) + 22, Theme.TextboxText, FontNormal
          Mouse.Show
        END IF
      END IF

      'Page up
      IF (Obj.BtnClick(btnPageUp) OR Key$ = "u" OR Key$ = CHR$(0) + "i") AND FileOpened THEN
        OldStartLine = StartLine
        StartLine = StartLine - (MaxLinesShown + 1)
        IF StartLine < 1 THEN StartLine = 1
        IF NOT StartLine = OldStartLine THEN TView.DrawText StartLine
      END IF

      'Page down
      IF (Obj.BtnClick(btnPageDown) OR Key$ = "d" OR Key$ = CHR$(0) + "q") AND FileOpened THEN
        OldStartLine = StartLine
        StartLine = StartLine + MaxLinesShown + 1
        IF StartLine > UBOUND(FileData) - MaxLinesShown THEN
          StartLine = UBOUND(FileData) - MaxLinesShown
          IF StartLine < 1 THEN StartLine = 1
        END IF
        IF NOT StartLine = OldStartLine THEN TView.DrawText StartLine
      END IF

      'Home
      IF Key$ = CHR$(0) + "g" THEN
        IF NOT StartLine = 1 THEN StartLine = 1: TView.DrawText StartLine
      END IF

      'End
      IF Key$ = CHR$(0) + "o" THEN
        OldStartLine = StartLine
        StartLine = UBOUND(FileData) - MaxLinesShown
        IF StartLine < 1 THEN StartLine = 1
        IF NOT StartLine = OldStartLine THEN TView.DrawText StartLine
      END IF

      IF Obj.BtnClick(btnOpen) OR Key$ = "o" THEN
        OldFileName = Filename
        OldFileOpened = FileOpened
        Filename = File.Select("*.TXT")
        IF NOT Filename = "" AND NOT Filename = OldFileName THEN
          FileOpened = TView.LoadFile(Filename)
        ELSE
          FileOpened = OldFileOpened
          Filename = OldFileName
        END IF
        Mouse.Hide
        Obj.DrawTxt txtEditor, "", False
        Mouse.Show
        GOTO StartOfAll
      END IF

      IF Obj.BtnClick(btnAbout) OR Key$ = "a" THEN
        Sys.AboutBox "Text Viewer", "Jacob Palm", "DOCUMENT"
      END IF

      IF Obj.BtnClick(btnExit) OR Key$ = "x" OR Key$ = CHR$(27) THEN
        REDIM FileData(1) AS STRING
        EXIT SUB
      END IF

    LOOP
            
END SUB

