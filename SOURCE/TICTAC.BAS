OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Tic.CheckWin% ()
DECLARE SUB Tic.AIMove ()
DECLARE SUB Tic.DrawXO (FieldRow%, FieldCol%)
DECLARE SUB Tic.Main ()

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

DIM SHARED PlayerStart AS INTEGER
DIM SHARED PlayerTurn AS INTEGER
DIM SHARED TotalTurns AS INTEGER
DIM SHARED EnableAI AS INTEGER
DIM SHARED PlayField(1 TO 3, 1 TO 3) AS INTEGER
DIM SHARED txtPlayField(1 TO 3, 1 TO 3) AS TextboxType

SUB Tic.AIMove ()

    RANDOMIZE TIMER
    Sys.Delay (INT(RND * 550) + 550) / 1000

    'Check if AI can win
      'Horizontal
      IF PlayField(1, 1) = 2 AND PlayField(1, 2) = 2 AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = 2: Tic.DrawXO 1, 3: EXIT SUB
      IF PlayField(1, 1) = 2 AND PlayField(1, 3) = 2 AND PlayField(1, 2) = 0 THEN PlayField(1, 2) = 2: Tic.DrawXO 1, 2: EXIT SUB
      IF PlayField(1, 2) = 2 AND PlayField(1, 3) = 2 AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = 2: Tic.DrawXO 1, 1: EXIT SUB

      IF PlayField(2, 1) = 2 AND PlayField(2, 2) = 2 AND PlayField(2, 3) = 0 THEN PlayField(2, 3) = 2: Tic.DrawXO 2, 3: EXIT SUB
      IF PlayField(2, 1) = 2 AND PlayField(2, 3) = 2 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2: EXIT SUB
      IF PlayField(2, 2) = 2 AND PlayField(2, 3) = 2 AND PlayField(2, 1) = 0 THEN PlayField(2, 1) = 2: Tic.DrawXO 2, 1: EXIT SUB

      IF PlayField(3, 1) = 2 AND PlayField(3, 2) = 2 AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = 2: Tic.DrawXO 3, 3: EXIT SUB
      IF PlayField(3, 1) = 2 AND PlayField(3, 3) = 2 AND PlayField(3, 2) = 0 THEN PlayField(3, 2) = 2: Tic.DrawXO 3, 2: EXIT SUB
      IF PlayField(3, 2) = 2 AND PlayField(3, 3) = 2 AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = 2: Tic.DrawXO 3, 1: EXIT SUB

      'Vertical
      IF PlayField(1, 1) = 2 AND PlayField(2, 1) = 2 AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = 2: Tic.DrawXO 3, 1: EXIT SUB
      IF PlayField(1, 1) = 2 AND PlayField(3, 1) = 2 AND PlayField(2, 1) = 0 THEN PlayField(2, 1) = 2: Tic.DrawXO 2, 1: EXIT SUB
      IF PlayField(2, 1) = 2 AND PlayField(3, 1) = 2 AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = 2: Tic.DrawXO 1, 1: EXIT SUB

      IF PlayField(1, 2) = 2 AND PlayField(2, 2) = 2 AND PlayField(3, 2) = 0 THEN PlayField(3, 2) = 2: Tic.DrawXO 3, 2: EXIT SUB
      IF PlayField(1, 2) = 2 AND PlayField(3, 2) = 2 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2: EXIT SUB
      IF PlayField(2, 2) = 2 AND PlayField(3, 2) = 2 AND PlayField(1, 2) = 0 THEN PlayField(1, 2) = 2: Tic.DrawXO 1, 2: EXIT SUB

      IF PlayField(1, 3) = 2 AND PlayField(2, 3) = 2 AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = 2: Tic.DrawXO 3, 3: EXIT SUB
      IF PlayField(1, 3) = 2 AND PlayField(3, 3) = 2 AND PlayField(2, 3) = 0 THEN PlayField(2, 3) = 2: Tic.DrawXO 2, 3: EXIT SUB
      IF PlayField(2, 3) = 2 AND PlayField(3, 3) = 2 AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = 2: Tic.DrawXO 1, 3: EXIT SUB

      'Diagonal
      IF PlayField(1, 1) = 2 AND PlayField(2, 2) = 2 AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = 2: Tic.DrawXO 3, 3: EXIT SUB
      IF PlayField(1, 1) = 2 AND PlayField(3, 3) = 2 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2: EXIT SUB
      IF PlayField(2, 2) = 2 AND PlayField(3, 3) = 2 AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = 2: Tic.DrawXO 1, 1: EXIT SUB

      IF PlayField(1, 3) = 2 AND PlayField(2, 2) = 2 AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = 2: Tic.DrawXO 3, 1: EXIT SUB
      IF PlayField(1, 3) = 2 AND PlayField(3, 1) = 2 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2: EXIT SUB
      IF PlayField(2, 2) = 2 AND PlayField(3, 1) = 2 AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = 2: Tic.DrawXO 1, 3: EXIT SUB

    'If AI can't win, prevent X from doing so
      'Horizontal
      IF PlayField(1, 1) = 1 AND PlayField(1, 2) = 1 AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = 2: Tic.DrawXO 1, 3: EXIT SUB
      IF PlayField(1, 1) = 1 AND PlayField(1, 3) = 1 AND PlayField(1, 2) = 0 THEN PlayField(1, 2) = 2: Tic.DrawXO 1, 2: EXIT SUB
      IF PlayField(1, 2) = 1 AND PlayField(1, 3) = 1 AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = 2: Tic.DrawXO 1, 1: EXIT SUB

      IF PlayField(2, 1) = 1 AND PlayField(2, 2) = 1 AND PlayField(2, 3) = 0 THEN PlayField(2, 3) = 2: Tic.DrawXO 2, 3: EXIT SUB
      IF PlayField(2, 1) = 1 AND PlayField(2, 3) = 1 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2: EXIT SUB
      IF PlayField(2, 2) = 1 AND PlayField(2, 3) = 1 AND PlayField(2, 1) = 0 THEN PlayField(2, 1) = 2: Tic.DrawXO 2, 1: EXIT SUB

      IF PlayField(3, 1) = 1 AND PlayField(3, 2) = 1 AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = 2: Tic.DrawXO 3, 3: EXIT SUB
      IF PlayField(3, 1) = 1 AND PlayField(3, 3) = 1 AND PlayField(3, 2) = 0 THEN PlayField(3, 2) = 2: Tic.DrawXO 3, 2: EXIT SUB
      IF PlayField(3, 2) = 1 AND PlayField(3, 3) = 1 AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = 2: Tic.DrawXO 3, 1: EXIT SUB

      'Vertical
      IF PlayField(1, 1) = 1 AND PlayField(2, 1) = 1 AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = 2: Tic.DrawXO 3, 1: EXIT SUB
      IF PlayField(1, 1) = 1 AND PlayField(3, 1) = 1 AND PlayField(2, 1) = 0 THEN PlayField(2, 1) = 2: Tic.DrawXO 2, 1: EXIT SUB
      IF PlayField(2, 1) = 1 AND PlayField(3, 1) = 1 AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = 2: Tic.DrawXO 1, 1: EXIT SUB

      IF PlayField(1, 2) = 1 AND PlayField(2, 2) = 1 AND PlayField(3, 2) = 0 THEN PlayField(3, 2) = 2: Tic.DrawXO 3, 2: EXIT SUB
      IF PlayField(1, 2) = 1 AND PlayField(3, 2) = 1 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2: EXIT SUB
      IF PlayField(2, 2) = 1 AND PlayField(3, 2) = 1 AND PlayField(1, 2) = 0 THEN PlayField(1, 2) = 2: Tic.DrawXO 1, 2: EXIT SUB

      IF PlayField(1, 3) = 1 AND PlayField(2, 3) = 1 AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = 2: Tic.DrawXO 3, 3: EXIT SUB
      IF PlayField(1, 3) = 1 AND PlayField(3, 3) = 1 AND PlayField(2, 3) = 0 THEN PlayField(2, 3) = 2: Tic.DrawXO 2, 3: EXIT SUB
      IF PlayField(2, 3) = 1 AND PlayField(3, 3) = 1 AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = 2: Tic.DrawXO 1, 3: EXIT SUB

      'Diagonal
      IF PlayField(1, 1) = 1 AND PlayField(2, 2) = 1 AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = 2: Tic.DrawXO 3, 3: EXIT SUB
      IF PlayField(1, 1) = 1 AND PlayField(3, 3) = 1 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2: EXIT SUB
      IF PlayField(2, 2) = 1 AND PlayField(3, 3) = 1 AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = 2: Tic.DrawXO 1, 1: EXIT SUB

      IF PlayField(1, 3) = 1 AND PlayField(2, 2) = 1 AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = 2: Tic.DrawXO 3, 1: EXIT SUB
      IF PlayField(1, 3) = 1 AND PlayField(3, 1) = 1 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2: EXIT SUB
      IF PlayField(2, 2) = 1 AND PlayField(3, 1) = 1 AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = 2: Tic.DrawXO 1, 3: EXIT SUB

    'If AI can't win, and X doesn't have to in a row, just pick a random spot

      RANDOMIZE TIMER
      DIM SetCol, SetRow

      DO
          SetCol = INT(RND * 3) + 1
          SetRow = INT(RND * 3) + 1

          IF PlayField(SetRow, SetCol) = 0 THEN
              PlayField(SetRow, SetCol) = 2
              Tic.DrawXO SetRow, SetCol
              EXIT SUB
          END IF
      LOOP
END SUB

FUNCTION Tic.CheckWin ()
    'Returns True if the current player has won the game - should be called
    'after every turn

    'Horizontal
    IF PlayField(1, 1) = PlayerTurn AND PlayField(1, 2) = PlayerTurn AND PlayField(1, 3) = PlayerTurn THEN Tic.CheckWin = True: EXIT FUNCTION
    IF PlayField(2, 1) = PlayerTurn AND PlayField(2, 2) = PlayerTurn AND PlayField(2, 3) = PlayerTurn THEN Tic.CheckWin = -1: EXIT FUNCTION
    IF PlayField(3, 1) = PlayerTurn AND PlayField(3, 2) = PlayerTurn AND PlayField(3, 3) = PlayerTurn THEN Tic.CheckWin = -1: EXIT FUNCTION

    'Vertical
    IF PlayField(1, 1) = PlayerTurn AND PlayField(2, 1) = PlayerTurn AND PlayField(3, 1) = PlayerTurn THEN Tic.CheckWin = -1: EXIT FUNCTION
    IF PlayField(1, 2) = PlayerTurn AND PlayField(2, 2) = PlayerTurn AND PlayField(3, 2) = PlayerTurn THEN Tic.CheckWin = -1: EXIT FUNCTION
    IF PlayField(1, 3) = PlayerTurn AND PlayField(2, 3) = PlayerTurn AND PlayField(3, 3) = PlayerTurn THEN Tic.CheckWin = -1: EXIT FUNCTION

    'Diagonal
    IF PlayField(1, 1) = PlayerTurn AND PlayField(2, 2) = PlayerTurn AND PlayField(3, 3) = PlayerTurn THEN Tic.CheckWin = -1: EXIT FUNCTION
    IF PlayField(1, 3) = PlayerTurn AND PlayField(2, 2) = PlayerTurn AND PlayField(3, 1) = PlayerTurn THEN Tic.CheckWin = -1: EXIT FUNCTION

END FUNCTION

SUB Tic.DrawXO (FieldRow, FieldCol)

    DIM XCoord, YCoord
    XCoord = txtPlayField(FieldRow, FieldCol).Pos.Left
    YCoord = txtPlayField(FieldRow, FieldCol).Pos.Top

    IF PlayerTurn = 1 THEN
        Mouse.Hide
        LINE (XCoord + 11, YCoord + 12)-(XCoord + 48, YCoord + 49), ClrTextboxText
        LINE (XCoord + 11, YCoord + 13)-(XCoord + 47, YCoord + 49), ClrTextboxText
        LINE (XCoord + 12, YCoord + 12)-(XCoord + 49, YCoord + 49), ClrTextboxText
        LINE (XCoord + 13, YCoord + 12)-(XCoord + 49, YCoord + 48), ClrTextboxText
        LINE (XCoord + 11, YCoord + 48)-(XCoord + 47, YCoord + 12), ClrTextboxText
        LINE (XCoord + 11, YCoord + 49)-(XCoord + 48, YCoord + 12), ClrTextboxText
        LINE (XCoord + 12, YCoord + 49)-(XCoord + 49, YCoord + 12), ClrTextboxText
        LINE (XCoord + 13, YCoord + 49)-(XCoord + 49, YCoord + 13), ClrTextboxText
        Mouse.Show
    ELSE
        Mouse.Hide
        CIRCLE (XCoord + 30, YCoord + 30), 19, ClrTextboxText
        CIRCLE (XCoord + 30, YCoord + 30), 18, ClrTextboxText
        CIRCLE (XCoord + 30, YCoord + 30), 17, ClrTextboxText
        PSET (XCoord + 14, YCoord + 23), ClrTextboxText
        PSET (XCoord + 15, YCoord + 21), ClrTextboxText
        PSET (XCoord + 21, YCoord + 15), ClrTextboxText
        PSET (XCoord + 23, YCoord + 14), ClrTextboxText
        PSET (XCoord + 14, YCoord + 37), ClrTextboxText
        PSET (XCoord + 15, YCoord + 39), ClrTextboxText
        PSET (XCoord + 21, YCoord + 45), ClrTextboxText
        PSET (XCoord + 23, YCoord + 46), ClrTextboxText
        PSET (XCoord + 37, YCoord + 46), ClrTextboxText
        PSET (XCoord + 39, YCoord + 45), ClrTextboxText
        PSET (XCoord + 45, YCoord + 39), ClrTextboxText
        PSET (XCoord + 46, YCoord + 37), ClrTextboxText
        PSET (XCoord + 46, YCoord + 23), ClrTextboxText
        PSET (XCoord + 45, YCoord + 21), ClrTextboxText
        PSET (XCoord + 39, YCoord + 15), ClrTextboxText
        PSET (XCoord + 37, YCoord + 14), ClrTextboxText
        LINE (XCoord + 16, YCoord + 18)-(XCoord + 18, YCoord + 16), ClrTextboxText
        LINE (XCoord + 42, YCoord + 16)-(XCoord + 44, YCoord + 18), ClrTextboxText
        LINE (XCoord + 44, YCoord + 42)-(XCoord + 42, YCoord + 44), ClrTextboxText
        LINE (XCoord + 16, YCoord + 42)-(XCoord + 18, YCoord + 44), ClrTextboxText
        Mouse.Show
    END IF

END SUB

SUB Tic.Main ()

    DIM winTic AS WindowType
    DIM btnNew AS ButtonType, btnAIToggle AS ButtonType, btnExit AS ButtonType
    DIM FieldRow, FieldCol, FieldClicked
    
    Obj.SetSize winTic.Pos, 146, 119, 348, 242
    winTic.Caption = "Tic Tac Toe for Costa"

    Obj.SetSize txtPlayField(1, 1).Pos, 156, 151, 60, 60
    Obj.SetSize txtPlayField(1, 2).Pos, 226, 151, 60, 60
    Obj.SetSize txtPlayField(1, 3).Pos, 296, 151, 60, 60
    Obj.SetSize txtPlayField(2, 1).Pos, 156, 221, 60, 60
    Obj.SetSize txtPlayField(2, 2).Pos, 226, 221, 60, 60
    Obj.SetSize txtPlayField(2, 3).Pos, 296, 221, 60, 60
    Obj.SetSize txtPlayField(3, 1).Pos, 156, 291, 60, 60
    Obj.SetSize txtPlayField(3, 2).Pos, 226, 291, 60, 60
    Obj.SetSize txtPlayField(3, 3).Pos, 296, 291, 60, 60
    
    Obj.SetSize btnNew.Pos, 376, 151, 100, 25
    Obj.SetSize btnAIToggle.Pos, 376, 186, 100, 25
    Obj.SetSize btnExit.Pos, 376, 221, 100, 25
    btnNew.Caption = "New game": btnNew.HotKey = 1
    btnAIToggle.Caption = "2 players": btnAIToggle.HotKey = 3
    btnExit.Caption = "Close": btnExit.HotKey = 1
    
    Obj.DrawWin winTic
    Obj.DrawBtn btnNew, False
    Obj.DrawBtn btnAIToggle, False
    Obj.DrawBtn btnExit, False
    

    EnableAI = True: PlayerTurn = 1: PlayerStart = 2
    
    DIM Key$

StartOfGame:
    FieldClicked = 0
    FOR FieldRow = 1 TO 3
        FOR FieldCol = 1 TO 3
            PlayField(FieldRow, FieldCol) = 0
            Obj.DrawTxt txtPlayField(FieldRow, FieldCol), "", False
        NEXT
    NEXT

    TotalTurns = 0
    IF PlayerStart = 1 THEN
        PlayerStart = 2
    ELSE
        PlayerStart = 1
    END IF
    PlayerTurn = PlayerStart

    Mouse.Hide
    LINE (376, 271)-(476, 282), ClrWindow, BF
    Mouse.Show
    IF PlayerTurn = 1 THEN
        Font.Print "X", 400, 271, ClrWindowText, 3
    ELSE
        Font.Print "O", 400, 271, ClrWindowText, 3
    END IF
    Font.Print "'s turn", 408, 271, ClrWindowText, 2

    IF EnableAI = True AND PlayerTurn = 2 THEN GOTO PerformAIMove

    DO
        Key$ = LCASE$(INKEY$)

        IF Obj.BtnClick(btnNew) OR Key$ = "n" THEN GOTO StartOfGame
        IF Obj.BtnClick(btnExit) OR Key$ = "c" THEN Sys.VGALoad "DESKTOP": EXIT SUB

        IF Obj.BtnClick(btnAIToggle) OR Key$ = "p" THEN
            EnableAI = NOT EnableAI
            IF EnableAI = True THEN
                btnAIToggle.Caption = "2 players"
            ELSE
                btnAIToggle.Caption = "1 player"
            END IF
            Obj.DrawBtn btnAIToggle, False
            GOTO StartOfGame
        END IF
                       
        IF TotalTurns < 9 THEN
            IF Obj.TxtClick(txtPlayField(1, 1)) OR Key$ = "7" THEN FieldClicked = True: FieldRow = 1: FieldCol = 1
            IF Obj.TxtClick(txtPlayField(1, 2)) OR Key$ = "8" THEN FieldClicked = True: FieldRow = 1: FieldCol = 2
            IF Obj.TxtClick(txtPlayField(1, 3)) OR Key$ = "9" THEN FieldClicked = True: FieldRow = 1: FieldCol = 3
            IF Obj.TxtClick(txtPlayField(2, 1)) OR Key$ = "4" THEN FieldClicked = True: FieldRow = 2: FieldCol = 1
            IF Obj.TxtClick(txtPlayField(2, 2)) OR Key$ = "5" THEN FieldClicked = True: FieldRow = 2: FieldCol = 2
            IF Obj.TxtClick(txtPlayField(2, 3)) OR Key$ = "6" THEN FieldClicked = True: FieldRow = 2: FieldCol = 3
            IF Obj.TxtClick(txtPlayField(3, 1)) OR Key$ = "1" THEN FieldClicked = True: FieldRow = 3: FieldCol = 1
            IF Obj.TxtClick(txtPlayField(3, 2)) OR Key$ = "2" THEN FieldClicked = True: FieldRow = 3: FieldCol = 2
            IF Obj.TxtClick(txtPlayField(3, 3)) OR Key$ = "3" THEN FieldClicked = True: FieldRow = 3: FieldCol = 3
            
            IF FieldClicked THEN
                IF PlayField(FieldRow, FieldCol) = 0 THEN
                    FieldClicked = 0
                    PlayField(FieldRow, FieldCol) = PlayerTurn
                    Tic.DrawXO FieldRow, FieldCol
                    TotalTurns = TotalTurns + 1

                    IF Tic.CheckWin = True THEN
                        Mouse.Hide
                        LINE (376, 271)-(476, 279), ClrWindow, BF
                        Mouse.Show

                        IF PlayerTurn = 1 THEN
                            Font.Print "X", 377, 271, ClrWindowText, 3
                        ELSE
                            Font.Print "O", 377, 271, ClrWindowText, 3
                        END IF
                        Font.Print "wins the game!", 388, 271, ClrWindowText, 2
                        TotalTurns = 9
                    ELSE
                        IF TotalTurns < 9 THEN
                            Mouse.Hide
                            LINE (400, 271)-(405, 279), ClrWindow, BF
                            Mouse.Show

                            IF PlayerTurn = 1 THEN
                                PlayerTurn = 2
                                Font.Print "O", 400, 271, ClrWindowText, 3
                            ELSE
                                PlayerTurn = 1
                                Font.Print "X", 400, 271, ClrWindowText, 3
                            END IF

                            IF EnableAI = True AND TotalTurns < 9 AND PlayerTurn = 2 THEN
PerformAIMove:
                                Tic.AIMove
                                TotalTurns = TotalTurns + 1
                                IF Tic.CheckWin = True THEN
                                    Mouse.Hide
                                    LINE (376, 271)-(476, 279), ClrWindow, BF
                                    Mouse.Show
                                    Font.Print "O", 377, 271, ClrWindowText, 3
                                    Font.Print "wins the game!", 388, 271, ClrWindowText, 2
                                    TotalTurns = 9
                                ELSE
                                    IF TotalTurns = 9 THEN
                                        Mouse.Hide
                                        LINE (376, 271)-(476, 279), ClrWindow, BF
                                        Mouse.Show
                                        Font.Print "It's a draw!", 393, 271, ClrWindowText, 2
                                    ELSE
                                        PlayerTurn = 1
                                        Mouse.Hide
                                        LINE (400, 271)-(405, 279), ClrWindow, BF
                                        Mouse.Show
                                        Font.Print "X", 400, 271, ClrWindowText, 3
                                    END IF
                                END IF
                            END IF

                        ELSE
                            Mouse.Hide
                            LINE (376, 271)-(476, 279), ClrWindow, BF
                            Mouse.Show
                            Font.Print "It's a draw!", 393, 271, ClrWindowText, 2
                        END IF

                    END IF
                END IF
            END IF
        END IF
            
        

    LOOP


END SUB

