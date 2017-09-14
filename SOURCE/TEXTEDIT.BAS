DECLARE SUB App.MoveCursor (NewX%, NewY%)
DECLARE FUNCTION App.LoadFile% (TargetFile AS STRING)
DECLARE SUB App.DrawText (StartLine%)
DECLARE SUB App.Main ()

OPTION EXPLICIT
DEFINT A-Z

'$INCLUDE: 'SOURCE\COSTALIB.BI'

COMMON SHARED FileData() AS STRING
COMMON SHARED CursorX, CursorY

SCREEN 12
Sys.Load
App.Main

SUB App.DrawText (StartLine)

    DIM LineCount

    Mouse.Hide
    FOR LineCount = StartLine TO StartLine + 26
        IF NOT LineCount > UBOUND(FileData) THEN
            LINE (7, (15 * (LineCount - StartLine + 1)) + 55)-(633, 15 * (LineCount - StartLine + 1) + 68), clrTextbox, BF
            Font.Print FileData(LineCount), 9, (15 * (LineCount - StartLine + 1)) + 56, clrTextboxText, FontSystem
        END IF
    NEXT
    Mouse.Show

END SUB

FUNCTION App.LoadFile (TargetFile AS STRING)

    DIM FileHandle, LineCount

    IF NOT File.Exists(TargetFile) THEN
        FileHandle = Sys.MsgBox("File not found", "Text Editor could not find the file you are trying to load.", msgError)
        App.LoadFile = False
        EXIT FUNCTION
    END IF

    FileHandle = FREEFILE
    OPEN TargetFile FOR INPUT AS #FileHandle

    REDIM FileData(1 TO 1) AS STRING
    DO WHILE NOT EOF(FileHandle)
        LineCount = LineCount + 1
        REDIM PRESERVE FileData(1 TO LineCount) AS STRING
        LINE INPUT #FileHandle, FileData(LineCount)
    LOOP
    
    CLOSE #FileHandle

    App.LoadFile = True

END FUNCTION

SUB App.Main ()

    DIM FileWin AS WindowType
    DIM btnOpen AS ButtonType, btnExit AS ButtonType
    DIM btnPageUp AS ButtonType, btnPageDown AS ButtonType
    DIM txtEditor AS TextboxType
    
    DIM FileName AS STRING, CaptionName AS STRING
    DIM StartLine, OldStartLine, FileOpened

    Obj.SetSize FileWin.Pos, 0, 3, 639, 476
    FileWin.Caption = "Text Editor"

    Obj.SetSize btnOpen.Pos, 11, 35, -1, -1
    btnOpen.Caption = "Open file...": btnOpen.HotKey = 1

    Obj.SetSize btnPageUp.Pos, 113, 35, -1, -1
    btnPageUp.Caption = "Page up": btnPageUp.HotKey = 6

    Obj.SetSize btnPageDown.Pos, 215, 35, -1, -1
    btnPageDown.Caption = "Page down": btnPageDown.HotKey = 6


    Obj.SetSize btnExit.Pos, 537, 35, -1, -1
    btnExit.Caption = "Exit": btnExit.HotKey = 1

    Obj.SetSize txtEditor.Pos, 5, 67, 630, 408
    
    IF NOT COMMAND$ = "/?" AND NOT COMMAND$ = "/DEV" AND LEN(COMMAND$) THEN
        FileName = LTRIM$(RTRIM$(COMMAND$))
        IF NOT File.Exists(FileName) THEN
            FileOpened = Sys.MsgBox("File not found", "Text Editor could not find the file you are trying to load.", msgError)
            EXIT SUB
        ELSE
            FileOpened = App.LoadFile(FileName)
        END IF
    END IF
    
    'DEUBG
    FileName = "D:\PROJEK~1\COSTA\DOCS\EDITTEST.TXT"
    FileOpened = App.LoadFile(FileName)
    IF FileOpened THEN GOTO StartOfAll


StartOfAll:

    IF FileOpened THEN
        CaptionName = FileName
        DO WHILE INSTR(CaptionName, "\") OR INSTR(CaptionName, "/")
            IF INSTR(CaptionName, "\") THEN CaptionName = RIGHT$(CaptionName, LEN(CaptionName) - INSTR(CaptionName, "\"))
            IF INSTR(CaptionName, "/") THEN CaptionName = RIGHT$(CaptionName, LEN(CaptionName) - INSTR(CaptionName, "/"))
        LOOP
        FileWin.Caption = "Text Editor - " + CaptionName
    END IF

    Obj.DrawWin FileWin
    Obj.DrawBtn btnOpen, False
    Obj.DrawBtn btnPageUp, False
    Obj.DrawBtn btnPageDown, False
    Obj.DrawBtn btnExit, False
    Obj.DrawTxt txtEditor, "", False

    IF FileOpened THEN
        StartLine = 1
        App.DrawText StartLine
    END IF
    
    CursorX = 1: CursorY = 1
    App.MoveCursor 1, 1

    DIM Key$
    DO
        Key$ = LCASE$(INKEY$)

        'Key up
        IF Key$ = CHR$(0) + "h" AND FileOpened THEN
            IF CursorY - 1 < 1 THEN
                OldStartLine = StartLine
                StartLine = StartLine - 27
                IF StartLine < 1 THEN StartLine = 1
                IF NOT StartLine = OldStartLine THEN
                    App.DrawText StartLine
                    App.MoveCursor 1, 27
                END IF
            ELSE
                App.MoveCursor 1, CursorY - 1
            END IF
        END IF
        
        'Key down
        IF Key$ = CHR$(0) + "p" AND FileOpened THEN
            IF CursorY + 1 > 27 THEN
                OldStartLine = StartLine
                StartLine = StartLine + 27
                IF StartLine > UBOUND(FileData) - 26 THEN
                    StartLine = UBOUND(FileData) - 26
                    IF StartLine < 1 THEN StartLine = 1
                END IF
                IF NOT StartLine = OldStartLine THEN
                    App.DrawText StartLine
                    App.MoveCursor CursorX, 1
                END IF
            ELSE
                App.MoveCursor 1, CursorY + 1
            END IF
        END IF

        'Page up
        IF (Obj.BtnClick(btnPageUp) OR Key$ = "u" OR Key$ = CHR$(0) + "i") AND FileOpened THEN
            OldStartLine = StartLine
            StartLine = StartLine - 27
            IF StartLine < 1 THEN StartLine = 1
            IF NOT StartLine = OldStartLine THEN
                App.DrawText StartLine
                App.MoveCursor CursorX, CursorY
            END IF
        END IF

        'Page down
        IF (Obj.BtnClick(btnPageDown) OR Key$ = "d" OR Key$ = CHR$(0) + "q") AND FileOpened THEN
            OldStartLine = StartLine
            StartLine = StartLine + 27
            IF StartLine > UBOUND(FileData) - 26 THEN
                StartLine = UBOUND(FileData) - 26
                IF StartLine < 1 THEN StartLine = 1
            END IF
            IF NOT StartLine = OldStartLine THEN
                App.DrawText StartLine
                DIM LinesShown
                LinesShown = UBOUND(FileData) - StartLine
                IF CursorY > LinesShown THEN
                    App.MoveCursor CursorX, LinesShown
                ELSE
                    App.MoveCursor CursorX, CursorY
                END IF
            END IF
        END IF


        IF Obj.BtnClick(btnOpen) OR Key$ = "o" THEN
            FileName = UCASE$(Sys.InputBox("Open text file", "Type the path and filename of the file below," + CHR$(13) + "and click OK to open the file.", "35disk", FileName))
            IF NOT FileName = "" THEN
                FileOpened = App.LoadFile(FileName)
                IF FileOpened THEN GOTO StartOfAll
            END IF
        END IF

        IF Obj.BtnClick(btnExit) OR Key$ = "e" OR Key$ = CHR$(27) THEN
            EXIT SUB
        END IF

    LOOP



END SUB

SUB App.MoveCursor (NewX, NewY)

    LINE (8, (15 * CursorY) + 55)-(8, 15 * CursorY + 66), clrTextbox

    CursorX = NewX
    CursorY = NewY

    LINE (8, (15 * CursorY) + 55)-(8, 15 * CursorY + 66), clrTextboxText

END SUB

