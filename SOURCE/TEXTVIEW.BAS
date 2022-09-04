OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION TView.LoadFile% (TargetFile AS STRING)
DECLARE SUB TView.DrawText (StartLine%)
DECLARE SUB TView.Main (FileToView AS STRING)

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

COMMON SHARED FileData() AS STRING
COMMON SHARED MaxLinesShown

STACK 6144

Sys.Load

IF NOT COMMAND$ = "/DEV" THEN
    TView.Main COMMAND$
ELSE
    TView.Main ""
END IF

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
            LINE (7, (15 * (LineCount - StartLine + 1)) + 54)-(633, 15 * (LineCount - StartLine + 1) + 68), SystemTheme.Textbox, BF
            Font.Print FileData(LineCount), 9, (15 * (LineCount - StartLine + 1)) + 56, SystemTheme.TextboxText, FontSystem
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

    DIM FileHandle, LineCount

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
        LineCount = LineCount + 1
        REDIM PRESERVE FileData(1 TO LineCount) AS STRING
        LINE INPUT #FileHandle, FileData(LineCount)

        DO WHILE LEN(FileData(LineCount)) > 80
            LineCount = LineCount + 1
            REDIM PRESERVE FileData(1 TO LineCount) AS STRING

            FileData(LineCount) = RIGHT$(FileData(LineCount - 1), LEN(FileData(LineCount - 1)) - 78)
            FileData(LineCount - 1) = LEFT$(FileData(LineCount - 1), 78)
        LOOP

    LOOP
    REDIM PRESERVE FileData(1 TO UBOUND(FileData) + 2) AS STRING
    FileData(UBOUND(FileData)) = "* end of file *"
    ON LOCAL ERROR GOTO 0

    CLOSE #FileHandle

    TView.LoadFile = True
    EXIT FUNCTION

TViewLoadErr:
    PRINT UBOUND(FileData)
    REDIM FileData(1) AS STRING
    DIM ErrMsg AS STRING, Dummy
    IF ERR = 6 OR ERR = 7 OR ERR = 9 OR ERR = 14 THEN
        ErrMsg = "Your computer does not have enough free memory" + CHR$(13) + "to load this file."
    ELSE
        ErrMsg = "An unknown error occurred while trying" + CHR$(13) + "to load the file."
    END IF
    Dummy = Sys.MsgBox("Could not load file", ErrMsg, msgError)
    Mouse.Hide
    LINE (265, 223)-(375, 257), SystemTheme.Textbox, BF
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

    DIM FileWin AS WindowType
    DIM btnOpen AS ButtonType, btnExit AS ButtonType
    DIM btnPageUp AS ButtonType, btnPageDown AS ButtonType
    DIM txtEditor AS TextboxType

    DIM Filename AS STRING, OldFileName AS STRING
    DIM StartLine, OldStartLine, FileOpened, OldFileOpened
    DIM LineMove, LineData(2371)

    Obj.SetSize FileWin.Pos, 0, 3, 639, scrHeight - 4
    FileWin.Caption = "Textviewer"

    Obj.SetSize btnOpen.Pos, 11, 35, -1, -1
    btnOpen.Caption = "Open file...": btnOpen.HotKey = 1

    Obj.SetSize btnPageUp.Pos, 113, 35, -1, -1
    btnPageUp.Caption = "Page up": btnPageUp.HotKey = 6

    Obj.SetSize btnPageDown.Pos, 215, 35, -1, -1
    btnPageDown.Caption = "Page down": btnPageDown.HotKey = 6
    
    Obj.SetSize btnExit.Pos, 537, 35, -1, -1
    btnExit.Caption = "Close": btnExit.HotKey = 1

    Obj.SetSize txtEditor.Pos, 6, 67, 627, FileWin.Pos.Height - 69
    
    IF LEN(LTRIM$(RTRIM$(FileToView))) THEN
        Filename = LTRIM$(RTRIM$(FileToView))
        IF NOT File.Exists(Filename) THEN
            FileOpened = Sys.MsgBox("File not found", FileToView + CHR$(13) + "Textviewer could not find the file you are trying to load.", msgError)
            EXIT SUB
        ELSE
            FileOpened = TView.LoadFile(Filename)
        END IF
    END IF

    IF scrHeight = 480 THEN
      MaxLinesShown = 26
    ELSE
      MaxLinesShown = 17
    END IF

startofall:

    IF FileOpened THEN
        FileWin.Caption = "Textviewer - " + Filename
    END IF

    Obj.DrawWin FileWin
    Obj.DrawBtn btnOpen, False
    IF FileOpened = False THEN
        Obj.DrawBtn btnPageUp, False
        Obj.DrawBtn btnPageDown, False
    ELSE
        IF UBOUND(FileData) > 27 THEN
            Obj.DrawBtn btnPageUp, False
            Obj.DrawBtn btnPageDown, False
        END IF
    END IF
    Obj.DrawBtn btnExit, False
    Obj.DrawTxt txtEditor, "", False
    Mouse.Hide
    LINE (7, txtEditor.Pos.Top + 2)-(633, txtEditor.Pos.Top + txtEditor.Pos.Height - 2), SystemTheme.Textbox, BF
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
                    GET (7, (15 * (LineMove)) + 54)-(633, 15 * (LineMove) + 68), LineData
                    PUT (7, (15 * (LineMove + 1)) + 54), LineData, PSET
                    'SLEEP
                NEXT
                LINE (7, (15 * (1)) + 54)-(633, 15 * (1) + 68), SystemTheme.Textbox, BF
                Font.Print FileData(StartLine), 9, (15 * (1)) + 56, SystemTheme.TextboxText, FontSystem

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
                    GET (7, (15 * (LineMove + 1)) + 54)-(633, 15 * (LineMove + 1) + 68), LineData
                    PUT (7, (15 * (LineMove)) + 54), LineData, PSET
                    'SLEEP
                NEXT
                LINE (7, (15 * (MaxLinesShown + 1)) + 54)-(633, 15 * (MaxLinesShown + 1) + 68), SystemTheme.Textbox, BF
                Font.Print FileData(StartLine + MaxLinesShown), 9, (15 * (MaxLinesShown + 1)) + 56, SystemTheme.TextboxText, FontSystem
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
            'DEBUG
            'Filename = UCASE$(Sys.InputBox("Open text file", "Type the path and filename of the file below," + CHR$(13) + "and click OK to open the file.", "35disk", Filename))
            Filename = File.Select("*.TXT")
            IF NOT Filename = "" AND NOT Filename = OldFileName THEN
                FileOpened = TView.LoadFile(Filename)
            ELSE
                FileOpened = OldFileOpened
                Filename = OldFileName
            END IF
            GOTO startofall
        END IF

        IF Obj.BtnClick(btnExit) OR Key$ = "c" OR Key$ = CHR$(27) THEN
            REDIM FileData(1) AS STRING
            EXIT SUB
        END IF

    LOOP



END SUB

