OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Tic.CheckWin% ()
DECLARE SUB Tic.AIMove ()
DECLARE SUB Tic.DrawBoard ()
DECLARE SUB Tic.DrawXO (FieldRow%, FieldCol%, FieldValue%)
DECLARE SUB Tic.DrawBackground ()
DECLARE SUB Tic.NewGame ()
DECLARE SUB Tic.Main ()
DECLARE SUB Tic.PlaySound (SoundType AS INTEGER)
DECLARE SUB Tic.PrintMessage (MessageType AS INTEGER)
DECLARE SUB Tic.PrintStatus ()

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

CONST PlayerX = 10
CONST PlayerO = NOT PlayerX

CONST SoundX = PlayerX
CONST SoundO = PlayerO
CONST SoundIllegalMove = 3
CONST SoundWin = 4
CONST SoundLoose = 5
CONST SoundDraw = 6
CONST SoundNew = 7

CONST msgWin = 1
CONST msgDraw = 2
CONST msgAITurn = 3
CONST msgPlayerTurn = 4
CONST msgNewGame = 5

TYPE FieldType
	Pos AS PosType
END TYPE

DIM SHARED PlayerStart AS INTEGER
DIM SHARED PlayerTurn AS INTEGER
DIM SHARED TotalTurns AS INTEGER
DIM SHARED EnableAI AS INTEGER
DIM SHARED EnableAudio AS INTEGER
DIM SHARED FieldClicked AS INTEGER
DIM SHARED PlayField(1 TO 3, 1 TO 3) AS INTEGER
DIM SHARED txtPlayField(1 TO 3, 1 TO 3) AS FieldType

Sys.Load

Tic.Main

' =========================================================================
'          NAME: Tic.AIMove()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: TICTAC.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Performs a move for the computer player.
' =========================================================================
SUB Tic.AIMove ()

		Tic.PrintMessage msgAITurn

		'Simulate some random "thinking" time
		RANDOMIZE TIMER
		Sys.Delay (INT(RND * 550) + 550) / 500

		'Check if AI can win
			'Horizontal
			IF PlayField(1, 1) = PlayerO AND PlayField(1, 2) = PlayerO AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = PlayerO: Tic.DrawXO 1, 3, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(1, 1) = PlayerO AND PlayField(1, 3) = PlayerO AND PlayField(1, 2) = 0 THEN PlayField(1, 2) = PlayerO: Tic.DrawXO 1, 2, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(1, 2) = PlayerO AND PlayField(1, 3) = PlayerO AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = PlayerO: Tic.DrawXO 1, 1, PlayerTurn: GOTO AIMoveEnd

			IF PlayField(2, 1) = PlayerO AND PlayField(2, 2) = PlayerO AND PlayField(2, 3) = 0 THEN PlayField(2, 3) = PlayerO: Tic.DrawXO 2, 3, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(2, 1) = PlayerO AND PlayField(2, 3) = PlayerO AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = PlayerO: Tic.DrawXO 2, 2, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(2, 2) = PlayerO AND PlayField(2, 3) = PlayerO AND PlayField(2, 1) = 0 THEN PlayField(2, 1) = PlayerO: Tic.DrawXO 2, 1, PlayerTurn: GOTO AIMoveEnd

			IF PlayField(3, 1) = PlayerO AND PlayField(3, 2) = PlayerO AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = PlayerO: Tic.DrawXO 3, 3, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(3, 1) = PlayerO AND PlayField(3, 3) = PlayerO AND PlayField(3, 2) = 0 THEN PlayField(3, 2) = PlayerO: Tic.DrawXO 3, 2, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(3, 2) = PlayerO AND PlayField(3, 3) = PlayerO AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = PlayerO: Tic.DrawXO 3, 1, PlayerTurn: GOTO AIMoveEnd

			'Vertical
			IF PlayField(1, 1) = PlayerO AND PlayField(2, 1) = PlayerO AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = PlayerO: Tic.DrawXO 3, 1, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(1, 1) = PlayerO AND PlayField(3, 1) = PlayerO AND PlayField(2, 1) = 0 THEN PlayField(2, 1) = PlayerO: Tic.DrawXO 2, 1, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(2, 1) = PlayerO AND PlayField(3, 1) = PlayerO AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = PlayerO: Tic.DrawXO 1, 1, PlayerTurn: GOTO AIMoveEnd

			IF PlayField(1, 2) = PlayerO AND PlayField(2, 2) = PlayerO AND PlayField(3, 2) = 0 THEN PlayField(3, 2) = PlayerO: Tic.DrawXO 3, 2, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(1, 2) = PlayerO AND PlayField(3, 2) = PlayerO AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = PlayerO: Tic.DrawXO 2, 2, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(2, 2) = PlayerO AND PlayField(3, 2) = PlayerO AND PlayField(1, 2) = 0 THEN PlayField(1, 2) = PlayerO: Tic.DrawXO 1, 2, PlayerTurn: GOTO AIMoveEnd

			IF PlayField(1, 3) = PlayerO AND PlayField(2, 3) = PlayerO AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = PlayerO: Tic.DrawXO 3, 3, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(1, 3) = PlayerO AND PlayField(3, 3) = PlayerO AND PlayField(2, 3) = 0 THEN PlayField(2, 3) = PlayerO: Tic.DrawXO 2, 3, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(2, 3) = PlayerO AND PlayField(3, 3) = PlayerO AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = PlayerO: Tic.DrawXO 1, 3, PlayerTurn: GOTO AIMoveEnd

			'Diagonal
			IF PlayField(1, 1) = PlayerO AND PlayField(2, 2) = PlayerO AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = PlayerO: Tic.DrawXO 3, 3, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(1, 1) = PlayerO AND PlayField(3, 3) = PlayerO AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = PlayerO: Tic.DrawXO 2, 2, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(2, 2) = PlayerO AND PlayField(3, 3) = PlayerO AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = PlayerO: Tic.DrawXO 1, 1, PlayerTurn: GOTO AIMoveEnd

			IF PlayField(1, 3) = PlayerO AND PlayField(2, 2) = PlayerO AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = PlayerO: Tic.DrawXO 3, 1, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(1, 3) = PlayerO AND PlayField(3, 1) = PlayerO AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = PlayerO: Tic.DrawXO 2, 2, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(2, 2) = PlayerO AND PlayField(3, 1) = PlayerO AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = PlayerO: Tic.DrawXO 1, 3, PlayerTurn: GOTO AIMoveEnd

		'If AI can't win, prevent X from doing so
			'Horizontal
			IF PlayField(1, 1) = PlayerX AND PlayField(1, 2) = PlayerX AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = PlayerO: Tic.DrawXO 1, 3, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(1, 1) = PlayerX AND PlayField(1, 3) = PlayerX AND PlayField(1, 2) = 0 THEN PlayField(1, 2) = PlayerO: Tic.DrawXO 1, 2, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(1, 2) = PlayerX AND PlayField(1, 3) = PlayerX AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = PlayerO: Tic.DrawXO 1, 1, PlayerTurn: GOTO AIMoveEnd

			IF PlayField(2, 1) = PlayerX AND PlayField(2, 2) = PlayerX AND PlayField(2, 3) = 0 THEN PlayField(2, 3) = PlayerO: Tic.DrawXO 2, 3, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(2, 1) = PlayerX AND PlayField(2, 3) = PlayerX AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = PlayerO: Tic.DrawXO 2, 2, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(2, 2) = PlayerX AND PlayField(2, 3) = PlayerX AND PlayField(2, 1) = 0 THEN PlayField(2, 1) = PlayerO: Tic.DrawXO 2, 1, PlayerTurn: GOTO AIMoveEnd

			IF PlayField(3, 1) = PlayerX AND PlayField(3, 2) = PlayerX AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = PlayerO: Tic.DrawXO 3, 3, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(3, 1) = PlayerX AND PlayField(3, 3) = PlayerX AND PlayField(3, 2) = 0 THEN PlayField(3, 2) = PlayerO: Tic.DrawXO 3, 2, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(3, 2) = PlayerX AND PlayField(3, 3) = PlayerX AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = PlayerO: Tic.DrawXO 3, 1, PlayerTurn: GOTO AIMoveEnd

			'Vertical
			IF PlayField(1, 1) = PlayerX AND PlayField(2, 1) = PlayerX AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = PlayerO: Tic.DrawXO 3, 1, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(1, 1) = PlayerX AND PlayField(3, 1) = PlayerX AND PlayField(2, 1) = 0 THEN PlayField(2, 1) = PlayerO: Tic.DrawXO 2, 1, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(2, 1) = PlayerX AND PlayField(3, 1) = PlayerX AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = PlayerO: Tic.DrawXO 1, 1, PlayerTurn: GOTO AIMoveEnd

			IF PlayField(1, 2) = PlayerX AND PlayField(2, 2) = PlayerX AND PlayField(3, 2) = 0 THEN PlayField(3, 2) = PlayerO: Tic.DrawXO 3, 2, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(1, 2) = PlayerX AND PlayField(3, 2) = PlayerX AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = PlayerO: Tic.DrawXO 2, 2, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(2, 2) = PlayerX AND PlayField(3, 2) = PlayerX AND PlayField(1, 2) = 0 THEN PlayField(1, 2) = PlayerO: Tic.DrawXO 1, 2, PlayerTurn: GOTO AIMoveEnd
					 
			IF PlayField(1, 3) = PlayerX AND PlayField(2, 3) = PlayerX AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = PlayerO: Tic.DrawXO 3, 3, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(1, 3) = PlayerX AND PlayField(3, 3) = PlayerX AND PlayField(2, 3) = 0 THEN PlayField(2, 3) = PlayerO: Tic.DrawXO 2, 3, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(2, 3) = PlayerX AND PlayField(3, 3) = PlayerX AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = PlayerO: Tic.DrawXO 1, 3, PlayerTurn: GOTO AIMoveEnd

			'Diagonal
			IF PlayField(1, 1) = PlayerX AND PlayField(2, 2) = PlayerX AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = PlayerO: Tic.DrawXO 3, 3, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(1, 1) = PlayerX AND PlayField(3, 3) = PlayerX AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = PlayerO: Tic.DrawXO 2, 2, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(2, 2) = PlayerX AND PlayField(3, 3) = PlayerX AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = PlayerO: Tic.DrawXO 1, 1, PlayerTurn: GOTO AIMoveEnd

			IF PlayField(1, 3) = PlayerX AND PlayField(2, 2) = PlayerX AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = PlayerO: Tic.DrawXO 3, 1, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(1, 3) = PlayerX AND PlayField(3, 1) = PlayerX AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = PlayerO: Tic.DrawXO 2, 2, PlayerTurn: GOTO AIMoveEnd
			IF PlayField(2, 2) = PlayerX AND PlayField(3, 1) = PlayerX AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = PlayerO: Tic.DrawXO 1, 3, PlayerTurn: GOTO AIMoveEnd

		'If AI can't win, and X doesn't have two in a row, just pick a random
		'spot

			RANDOMIZE TIMER
			DIM SetCol, SetRow

			DO
				SetCol = INT(RND * 3) + 1
				SetRow = INT(RND * 3) + 1

				IF PlayField(SetRow, SetCol) = 0 THEN
					PlayField(SetRow, SetCol) = PlayerO
					Tic.DrawXO SetRow, SetCol, PlayerO
					GOTO AIMoveEnd
				END IF
			LOOP

AIMoveEnd:
		 Tic.PlaySound SoundO
		 TotalTurns = TotalTurns + 1
		 IF Tic.CheckWin = True THEN
			 Tic.PrintMessage msgWin
			 Tic.PlaySound SoundLoose
			 TotalTurns = 9
		 ELSE
			 IF TotalTurns = 9 THEN
				 Tic.PrintMessage msgDraw
				 Tic.PlaySound SoundDraw
			 ELSE
				 PlayerTurn = PlayerX
				 Tic.PrintMessage msgPlayerTurn
			 END IF
		 END IF

END SUB

' =========================================================================
'          NAME: Tic.CheckWin()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: TICTAC.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Returns true if the current player has won the game.
'                Should be called after every turn.
' =========================================================================
FUNCTION Tic.CheckWin ()

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

SUB Tic.DrawBackground ()
	
	DIM LX
	Mouse.Hide
	
	LINE (0, 29)-(639, 349), 2, BF

	FOR LX = 0 TO 639 STEP 6
		LINE (LX, 29)-(LX, 349), 10, , &H1111
	NEXT

	FOR LX = 3 TO 639 STEP 6
		LINE (LX, 31)-(LX, 349), 10, , &H1111
	NEXT

	Mouse.Show
	
END SUB

' =========================================================================
'          NAME: Tic.DrawBoard()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: TICTAC.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Redraw the game board.
' =========================================================================
SUB Tic.DrawBoard ()

	DIM FieldRow, FieldCol
	DIM x1, y1, x2, y2

	Mouse.Hide
	FOR FieldRow = 1 TO 3
		FOR FieldCol = 1 TO 3
			x1 = txtPlayField(FieldRow, FieldCol).Pos.Left
			y1 = txtPlayField(FieldRow, FieldCol).Pos.Top
			x2 = txtPlayField(FieldRow, FieldCol).Pos.Left + txtPlayField(FieldRow, FieldCol).Pos.Width
			y2 = txtPlayField(FieldRow, FieldCol).Pos.Top + txtPlayField(FieldRow, FieldCol).Pos.Height
			LINE (x1 + 2, y1 + 2)-(x2 - 2, y2 - 2), 15, BF
			LINE (x1, y1)-(x2 - 1, y2 - 1), 10, B
			LINE (x1 + 1, y1 + 1)-(x2, y2), 8, B
			
			Tic.DrawXO FieldRow, FieldCol, PlayField(FieldRow, FieldCol)
		NEXT
	NEXT
	Mouse.Show

END SUB

' =========================================================================
'          NAME: Tic.DrawXO()
'    PARAMETERS: FieldRow, FieldCol - the position where to draw an X or O
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: TICTAC.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Draws an X or O in the specified field.
'                FieldValue decides wether it will be an X or an O.
' =========================================================================
SUB Tic.DrawXO (FieldRow, FieldCol, FieldValue)

		DIM XCoord, YCoord
		XCoord = txtPlayField(FieldRow, FieldCol).Pos.Left
		YCoord = txtPlayField(FieldRow, FieldCol).Pos.Top
		
		SELECT CASE FieldValue
			CASE PlayerX
				Mouse.Hide
				LINE (XCoord + 11, YCoord + 12)-(XCoord + 48, YCoord + 49), 0
				LINE (XCoord + 11, YCoord + 13)-(XCoord + 47, YCoord + 49), 0
				LINE (XCoord + 12, YCoord + 12)-(XCoord + 49, YCoord + 49), 0
				LINE (XCoord + 13, YCoord + 12)-(XCoord + 49, YCoord + 48), 0
				LINE (XCoord + 11, YCoord + 48)-(XCoord + 47, YCoord + 12), 0
				LINE (XCoord + 11, YCoord + 49)-(XCoord + 48, YCoord + 12), 0
				LINE (XCoord + 12, YCoord + 49)-(XCoord + 49, YCoord + 12), 0
				LINE (XCoord + 13, YCoord + 49)-(XCoord + 49, YCoord + 13), 0
				Mouse.Show
			CASE PlayerO
				Mouse.Hide
				CIRCLE (XCoord + 30, YCoord + 30), 19, 0, , , 1
				CIRCLE (XCoord + 30, YCoord + 30), 18, 0, , , 1
				CIRCLE (XCoord + 30, YCoord + 30), 17, 0, , , 1
				PSET (XCoord + 14, YCoord + 23), 0
				PSET (XCoord + 15, YCoord + 21), 0
				PSET (XCoord + 21, YCoord + 15), 0
				PSET (XCoord + 23, YCoord + 14), 0
				PSET (XCoord + 14, YCoord + 37), 0
				PSET (XCoord + 15, YCoord + 39), 0
				PSET (XCoord + 21, YCoord + 45), 0
				PSET (XCoord + 23, YCoord + 46), 0
				PSET (XCoord + 37, YCoord + 46), 0
				PSET (XCoord + 39, YCoord + 45), 0
				PSET (XCoord + 45, YCoord + 39), 0
				PSET (XCoord + 46, YCoord + 37), 0
				PSET (XCoord + 46, YCoord + 23), 0
				PSET (XCoord + 45, YCoord + 21), 0
				PSET (XCoord + 39, YCoord + 15), 0
				PSET (XCoord + 37, YCoord + 14), 0
				LINE (XCoord + 16, YCoord + 18)-(XCoord + 18, YCoord + 16), 0
				LINE (XCoord + 42, YCoord + 16)-(XCoord + 44, YCoord + 18), 0
				LINE (XCoord + 44, YCoord + 42)-(XCoord + 42, YCoord + 44), 0
				LINE (XCoord + 16, YCoord + 42)-(XCoord + 18, YCoord + 44), 0
				Mouse.Show
		END SELECT

END SUB

' =========================================================================
'          NAME: Tic.Main()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Main UI and logic for the Tic Tac Toe accessory
' =========================================================================
SUB Tic.Main ()

	DIM frmTic AS FrameType
	DIM btnNew AS ButtonType, btnAIToggle AS ButtonType
	DIM btnAudio AS ButtonType, btnExit AS ButtonType
	DIM FieldRow, FieldCol
	DIM Key$

	Obj.SetSize frmTic.Pos, sizeCenter, sizeCenter, 221, 221
	
	Obj.SetSize txtPlayField(1, 1).Pos, frmTic.Pos.Left + 10, frmTic.Pos.Top + 10, 60, 60
	Obj.SetSize txtPlayField(1, 2).Pos, txtPlayField(1, 1).Pos.Left + 70, txtPlayField(1, 1).Pos.Top, 60, 60
	Obj.SetSize txtPlayField(1, 3).Pos, txtPlayField(1, 2).Pos.Left + 70, txtPlayField(1, 1).Pos.Top, 60, 60

	Obj.SetSize txtPlayField(2, 1).Pos, txtPlayField(1, 1).Pos.Left, txtPlayField(1, 1).Pos.Top + 70, 60, 60
	Obj.SetSize txtPlayField(2, 2).Pos, txtPlayField(2, 1).Pos.Left + 70, txtPlayField(2, 1).Pos.Top, 60, 60
	Obj.SetSize txtPlayField(2, 3).Pos, txtPlayField(2, 2).Pos.Left + 70, txtPlayField(2, 1).Pos.Top, 60, 60

	Obj.SetSize txtPlayField(3, 1).Pos, txtPlayField(2, 1).Pos.Left, txtPlayField(2, 1).Pos.Top + 70, 60, 60
	Obj.SetSize txtPlayField(3, 2).Pos, txtPlayField(3, 1).Pos.Left + 70, txtPlayField(3, 1).Pos.Top, 60, 60
	Obj.SetSize txtPlayField(3, 3).Pos, txtPlayField(3, 2).Pos.Left + 70, txtPlayField(3, 1).Pos.Top, 60, 60

	Obj.SetSize btnNew.Pos, 3, 2, 92, 22
	Obj.SetSize btnAIToggle.Pos, 102, 2, 92, 22
	Obj.SetSize btnAudio.Pos, 201, 2, 92, 22
	Obj.SetSize btnExit.Pos, 545, 2, 92, 22
	btnNew.Caption = "õNew game"
	btnAIToggle.Caption = "õMode"
	btnAudio.Caption = "õSound"
	btnExit.Caption = "Eõxit"
	
	Obj.DrawMenu
	Tic.DrawBackground

	Mouse.Hide
	LINE (frmTic.Pos.Left + 2, frmTic.Pos.Top + 2)-(frmTic.Pos.Left + frmTic.Pos.Width - 2, frmTic.Pos.Top + frmTic.Pos.Height - 2), 2, BF
	Mouse.Show
	Obj.DrawFrm frmTic, 10, 8
	Obj.DrawBtn btnNew, False
	Obj.DrawBtn btnAIToggle, False
	Obj.DrawBtn btnAudio, False
	Obj.DrawBtn btnExit, False
	
	PlayerTurn = PlayerX
	PlayerStart = PlayerX
	Tic.DrawBoard
	Tic.PlaySound SoundNew
	Tic.PrintMessage msgNewGame
	Tic.PrintStatus

	DO
		Key$ = LCASE$(INKEY$)
		
		IF Obj.BtnClick(btnNew) OR Key$ = "n" THEN
			Tic.NewGame
			IF EnableAI AND PlayerTurn = PlayerO THEN Tic.AIMove
		END IF

		IF Obj.BtnClick(btnExit) OR Key$ = "x" THEN
			EXIT SUB
		END IF

		IF Obj.BtnClick(btnAIToggle) OR Key$ = "m" THEN
			EnableAI = NOT EnableAI
			Tic.NewGame
			IF EnableAI AND PlayerTurn = PlayerO THEN Tic.AIMove
		END IF

		IF Obj.BtnClick(btnAudio) OR Key$ = "s" THEN
			EnableAudio = NOT EnableAudio
			Tic.PrintStatus
		END IF

		IF TotalTurns < 9 THEN
			IF (Mouse.Clicked AND Mouse.InArea(txtPlayField(1, 1).Pos)) OR Key$ = "7" THEN FieldClicked = True: FieldRow = 1: FieldCol = 1
			IF (Mouse.Clicked AND Mouse.InArea(txtPlayField(1, 2).Pos)) OR Key$ = "8" THEN FieldClicked = True: FieldRow = 1: FieldCol = 2
			IF (Mouse.Clicked AND Mouse.InArea(txtPlayField(1, 3).Pos)) OR Key$ = "9" THEN FieldClicked = True: FieldRow = 1: FieldCol = 3
			IF (Mouse.Clicked AND Mouse.InArea(txtPlayField(2, 1).Pos)) OR Key$ = "4" THEN FieldClicked = True: FieldRow = 2: FieldCol = 1
			IF (Mouse.Clicked AND Mouse.InArea(txtPlayField(2, 2).Pos)) OR Key$ = "5" THEN FieldClicked = True: FieldRow = 2: FieldCol = 2
			IF (Mouse.Clicked AND Mouse.InArea(txtPlayField(2, 3).Pos)) OR Key$ = "6" THEN FieldClicked = True: FieldRow = 2: FieldCol = 3
			IF (Mouse.Clicked AND Mouse.InArea(txtPlayField(3, 1).Pos)) OR Key$ = "1" THEN FieldClicked = True: FieldRow = 3: FieldCol = 1
			IF (Mouse.Clicked AND Mouse.InArea(txtPlayField(3, 2).Pos)) OR Key$ = "2" THEN FieldClicked = True: FieldRow = 3: FieldCol = 2
			IF (Mouse.Clicked AND Mouse.InArea(txtPlayField(3, 3).Pos)) OR Key$ = "3" THEN FieldClicked = True: FieldRow = 3: FieldCol = 3

			IF FieldClicked THEN
				'Prevent audio from running wild if mouse/key is held down
				DO: LOOP WHILE LEN(INKEY$) OR Mouse.Clicked

				IF PlayField(FieldRow, FieldCol) = 0 THEN
					FieldClicked = 0
					PlayField(FieldRow, FieldCol) = PlayerTurn
					Tic.DrawXO FieldRow, FieldCol, PlayerTurn
					Tic.PlaySound PlayerTurn
					TotalTurns = TotalTurns + 1

					IF Tic.CheckWin = True THEN
						Tic.PrintMessage msgWin
						TotalTurns = 9
						Tic.PlaySound SoundWin
					ELSE
						IF TotalTurns < 9 THEN

							PlayerTurn = NOT PlayerTurn

							IF EnableAI = True AND PlayerTurn = PlayerO THEN
								Tic.AIMove
							ELSE
								Tic.PrintMessage msgPlayerTurn
							END IF

						ELSE
							Tic.PrintMessage msgDraw
							Tic.PlaySound SoundDraw
						END IF

					END IF
				ELSE
					Tic.PlaySound SoundIllegalMove
				END IF
				FieldClicked = False
			END IF
		END IF

	LOOP
	
END SUB

' =========================================================================
'          NAME: Tic.NewGame()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: TICTAC.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Clears the current state of the game, and draws an empty
'                playing board. The player (human or AI) which didn't start
'                the last game, gets to start the new one.
' =========================================================================
SUB Tic.NewGame ()

	DIM FieldRow, FieldCol

	FOR FieldRow = 1 TO 3
		FOR FieldCol = 1 TO 3
			PlayField(FieldRow, FieldCol) = 0
		NEXT
	NEXT

	Tic.DrawBoard

	TotalTurns = 0
	PlayerStart = NOT PlayerStart
	PlayerTurn = PlayerStart

	Tic.PrintMessage msgNewGame
	Tic.PlaySound SoundNew

END SUB

' =========================================================================
'          NAME: Tic.PlaySound()
'    PARAMETERS: SoundType - integer with value corresponding to the sound
'                            to be played
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: TICTAC.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Plays a sound. Possible values for SoundType are defined
'                as constants starting with "Sound", eg. "SoundWin"
' =========================================================================
SUB Tic.PlaySound (SoundType AS INTEGER)

	IF NOT EnableAudio THEN EXIT SUB

	SELECT CASE SoundType
		CASE PlayerX
			SOUND 400, .7
		CASE PlayerO
			SOUND 800, .7
		CASE SoundIllegalMove
			SOUND 100, .7
		CASE SoundWin
			PLAY "O2 T100 C D T200 G T400 E"
		CASE SoundLoose
			PLAY "O1 T400 E3 G3 D6 T100 C9 C9"
		CASE SoundDraw
			PLAY "O1 T400 C9 T100 E9 G9 D C9"
		CASE SoundNew
			PLAY "O2 T180 C8 C8 E3"
	END SELECT

END SUB

SUB Tic.PrintMessage (MessageType AS INTEGER)

	DIM Message AS STRING
	DIM CurrentTurn AS STRING * 1
	DIM Randomizer

	RANDOMIZE TIMER
	Randomizer = INT(6 * RND + 1)

	IF PlayerTurn = PlayerX THEN
		CurrentTurn = "X"
	ELSE
		CurrentTurn = "O"
	END IF

	SELECT CASE MessageType
		CASE msgWin

			SELECT CASE Randomizer
				CASE 1
					Message = CurrentTurn + " has brought honor to the family!"
				CASE 2
					Message = CurrentTurn + " has emerged victoriously from the battle!"
				CASE 3
					Message = "Nothing could stop " + CurrentTurn + " from achieving victory!"
				CASE 4
					Message = "The crowd is gasping, amazed at the incredible play by " + CurrentTurn + "!"
				CASE 5
					Message = CurrentTurn + " has brought down utter destruction on the opponent!"
				CASE 6
					Message = CurrentTurn + " is unbeatable on the playing field!"
			END SELECT


		CASE msgDraw

			SELECT CASE Randomizer
				CASE 1
					Message = "It was a real nail-biter, but neither player could best the other."
				CASE 2
					Message = "No winners means no losers, I guess."
				CASE 3
					Message = "A high-stakes game that could have gone both ways."
				CASE 4
					Message = "As eager as both players were, neither of them could achieve victory."
				CASE 5
					Message = "No bragging rights for either player - try again!"
				CASE 6
					Message = "An otherwise intense game, which ended with disappointment for both sides."
			END SELECT


		CASE msgAITurn

			SELECT CASE Randomizer
				CASE 1
					Message = CurrentTurn + " is contemplating the next move..."
				CASE 2
					Message = CurrentTurn + " is calculating all possible outcomes..."
				CASE 3
					Message = "The stakes are too high for " + CurrentTurn + " not to think this through..."
				CASE 4
					Message = CurrentTurn + " is struggling to find enough CPU power to beat the opponent..."
				CASE 5
					Message = CurrentTurn + " is becoming sentient in the quest to beat the humans..."
				CASE 6
					Message = CurrentTurn + " is working hard to not loose to a feeble human..."
			END SELECT


		CASE msgPlayerTurn

			SELECT CASE Randomizer
				CASE 1
					Message = "Make your move, " + CurrentTurn + "!"
				CASE 2
					Message = "How are you going to beat your opponent, " + CurrentTurn + "?"
				CASE 3
					Message = "Uh oh, what a powerfull move! What will " + CurrentTurn + " do now?"
				CASE 4
					Message = "Take your time " + CurrentTurn + " - the stakes are too high to slip up now!"
				CASE 5
					Message = "How will you eliminate your opponent, " + CurrentTurn + "?"
				CASE 6
					Message = "Now is the time to prove yourself, " + CurrentTurn + "!"
			END SELECT


		CASE msgNewGame

			SELECT CASE Randomizer
				CASE 1
					Message = CurrentTurn + " gets to make the first move!"
				CASE 2
					Message = "Looks like " + CurrentTurn + " will be the one to strike first!"
				CASE 3
					Message = "How will " + CurrentTurn + " begin the battle?"
				CASE 4
					Message = CurrentTurn + " is preparing the surprise attack carefully..."
				CASE 5
					Message = CurrentTurn + " is thinking about the optimal way to start the game..."
				CASE 6
					Message = "First move is yours " + CurrentTurn + ", use it wisely!"
			END SELECT


	END SELECT


	Mouse.Hide
	LINE (12, 49)-(627, 65), 2, BF
	Font.Print Message, (640 - Font.GetWidth(Message, fontHeading)) / 2, 53, 0, fontHeading
	Mouse.Show
	
END SUB

SUB Tic.PrintStatus ()
	DIM Message AS STRING

	Message = "Playing "
	IF EnableAI THEN
		Message = Message + "against computer"
	ELSE
		Message = Message + "two players"
	END IF
	Message = Message + SPACE$(20) + "Sound: "
	IF EnableAudio THEN
		Message = Message + "On"
	ELSE
		Message = Message + "Off"
	END IF

	Mouse.Hide
	LINE (162, 316)-(477, 332), 2, BF
	Font.Print Message, (640 - Font.GetWidth(Message, fontHeading)) / 2, 320, 0, fontHeading
	Mouse.Show
END SUB

