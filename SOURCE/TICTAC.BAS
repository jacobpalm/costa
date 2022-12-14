DECLARE SUB Tic.DrawBackground ()
DECLARE SUB Tic.PrintMessage (MessageType AS INTEGER)
OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Tic.CheckWin% ()
DECLARE FUNCTION Tic.LoadState% ()
DECLARE SUB Tic.AIMove ()
DECLARE SUB Tic.DrawBoard ()
DECLARE SUB Tic.DrawXO (FieldRow%, FieldCol%, FieldValue%)
DECLARE SUB Tic.NewGame ()
DECLARE SUB Tic.Main ()
DECLARE SUB Tic.PlaySound (SoundType AS INTEGER)
DECLARE SUB Tic.SaveState ()

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

CONST SoundX = 1
CONST SoundY = 2
CONST SoundIllegalMove = 3
CONST SoundWin = 4
CONST SoundLoose = 5
CONST SoundDraw = 6
CONST SoundNew = 7

CONST msgWin = 1
CONST msgDraw = 2
CONST msgAITurn = 3
CONST msgPlayerTurn = 4

DIM SHARED PlayerStart AS INTEGER
DIM SHARED PlayerTurn AS INTEGER
DIM SHARED TotalTurns AS INTEGER
DIM SHARED EnableAI AS INTEGER
DIM SHARED EnableAudio AS INTEGER
DIM SHARED CircleAspect AS INTEGER
DIM SHARED FieldClicked AS INTEGER
DIM SHARED PlayField(1 TO 3, 1 TO 3) AS INTEGER
DIM SHARED txtPlayField(1 TO 3, 1 TO 3) AS TextboxType

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

		'Simulate some random "thinking" time
		RANDOMIZE TIMER
		Sys.Delay (INT(RND * 550) + 550) / 500

		'Check if AI can win
			'Horizontal
			IF PlayField(1, 1) = 2 AND PlayField(1, 2) = 2 AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = 2: Tic.DrawXO 1, 3, PlayerTurn: EXIT SUB
			IF PlayField(1, 1) = 2 AND PlayField(1, 3) = 2 AND PlayField(1, 2) = 0 THEN PlayField(1, 2) = 2: Tic.DrawXO 1, 2, PlayerTurn: EXIT SUB
			IF PlayField(1, 2) = 2 AND PlayField(1, 3) = 2 AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = 2: Tic.DrawXO 1, 1, PlayerTurn: EXIT SUB

			IF PlayField(2, 1) = 2 AND PlayField(2, 2) = 2 AND PlayField(2, 3) = 0 THEN PlayField(2, 3) = 2: Tic.DrawXO 2, 3, PlayerTurn: EXIT SUB
			IF PlayField(2, 1) = 2 AND PlayField(2, 3) = 2 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2, PlayerTurn: EXIT SUB
			IF PlayField(2, 2) = 2 AND PlayField(2, 3) = 2 AND PlayField(2, 1) = 0 THEN PlayField(2, 1) = 2: Tic.DrawXO 2, 1, PlayerTurn: EXIT SUB

			IF PlayField(3, 1) = 2 AND PlayField(3, 2) = 2 AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = 2: Tic.DrawXO 3, 3, PlayerTurn: EXIT SUB
			IF PlayField(3, 1) = 2 AND PlayField(3, 3) = 2 AND PlayField(3, 2) = 0 THEN PlayField(3, 2) = 2: Tic.DrawXO 3, 2, PlayerTurn: EXIT SUB
			IF PlayField(3, 2) = 2 AND PlayField(3, 3) = 2 AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = 2: Tic.DrawXO 3, 1, PlayerTurn: EXIT SUB

			'Vertical
			IF PlayField(1, 1) = 2 AND PlayField(2, 1) = 2 AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = 2: Tic.DrawXO 3, 1, PlayerTurn: EXIT SUB
			IF PlayField(1, 1) = 2 AND PlayField(3, 1) = 2 AND PlayField(2, 1) = 0 THEN PlayField(2, 1) = 2: Tic.DrawXO 2, 1, PlayerTurn: EXIT SUB
			IF PlayField(2, 1) = 2 AND PlayField(3, 1) = 2 AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = 2: Tic.DrawXO 1, 1, PlayerTurn: EXIT SUB

			IF PlayField(1, 2) = 2 AND PlayField(2, 2) = 2 AND PlayField(3, 2) = 0 THEN PlayField(3, 2) = 2: Tic.DrawXO 3, 2, PlayerTurn: EXIT SUB
			IF PlayField(1, 2) = 2 AND PlayField(3, 2) = 2 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2, PlayerTurn: EXIT SUB
			IF PlayField(2, 2) = 2 AND PlayField(3, 2) = 2 AND PlayField(1, 2) = 0 THEN PlayField(1, 2) = 2: Tic.DrawXO 1, 2, PlayerTurn: EXIT SUB

			IF PlayField(1, 3) = 2 AND PlayField(2, 3) = 2 AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = 2: Tic.DrawXO 3, 3, PlayerTurn: EXIT SUB
			IF PlayField(1, 3) = 2 AND PlayField(3, 3) = 2 AND PlayField(2, 3) = 0 THEN PlayField(2, 3) = 2: Tic.DrawXO 2, 3, PlayerTurn: EXIT SUB
			IF PlayField(2, 3) = 2 AND PlayField(3, 3) = 2 AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = 2: Tic.DrawXO 1, 3, PlayerTurn: EXIT SUB

			'Diagonal
			IF PlayField(1, 1) = 2 AND PlayField(2, 2) = 2 AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = 2: Tic.DrawXO 3, 3, PlayerTurn: EXIT SUB
			IF PlayField(1, 1) = 2 AND PlayField(3, 3) = 2 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2, PlayerTurn: EXIT SUB
			IF PlayField(2, 2) = 2 AND PlayField(3, 3) = 2 AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = 2: Tic.DrawXO 1, 1, PlayerTurn: EXIT SUB

			IF PlayField(1, 3) = 2 AND PlayField(2, 2) = 2 AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = 2: Tic.DrawXO 3, 1, PlayerTurn: EXIT SUB
			IF PlayField(1, 3) = 2 AND PlayField(3, 1) = 2 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2, PlayerTurn: EXIT SUB
			IF PlayField(2, 2) = 2 AND PlayField(3, 1) = 2 AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = 2: Tic.DrawXO 1, 3, PlayerTurn: EXIT SUB

		'If AI can't win, prevent X from doing so
			'Horizontal
			IF PlayField(1, 1) = 1 AND PlayField(1, 2) = 1 AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = 2: Tic.DrawXO 1, 3, PlayerTurn: EXIT SUB
			IF PlayField(1, 1) = 1 AND PlayField(1, 3) = 1 AND PlayField(1, 2) = 0 THEN PlayField(1, 2) = 2: Tic.DrawXO 1, 2, PlayerTurn: EXIT SUB
			IF PlayField(1, 2) = 1 AND PlayField(1, 3) = 1 AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = 2: Tic.DrawXO 1, 1, PlayerTurn: EXIT SUB

			IF PlayField(2, 1) = 1 AND PlayField(2, 2) = 1 AND PlayField(2, 3) = 0 THEN PlayField(2, 3) = 2: Tic.DrawXO 2, 3, PlayerTurn: EXIT SUB
			IF PlayField(2, 1) = 1 AND PlayField(2, 3) = 1 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2, PlayerTurn: EXIT SUB
			IF PlayField(2, 2) = 1 AND PlayField(2, 3) = 1 AND PlayField(2, 1) = 0 THEN PlayField(2, 1) = 2: Tic.DrawXO 2, 1, PlayerTurn: EXIT SUB

			IF PlayField(3, 1) = 1 AND PlayField(3, 2) = 1 AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = 2: Tic.DrawXO 3, 3, PlayerTurn: EXIT SUB
			IF PlayField(3, 1) = 1 AND PlayField(3, 3) = 1 AND PlayField(3, 2) = 0 THEN PlayField(3, 2) = 2: Tic.DrawXO 3, 2, PlayerTurn: EXIT SUB
			IF PlayField(3, 2) = 1 AND PlayField(3, 3) = 1 AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = 2: Tic.DrawXO 3, 1, PlayerTurn: EXIT SUB

			'Vertical
			IF PlayField(1, 1) = 1 AND PlayField(2, 1) = 1 AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = 2: Tic.DrawXO 3, 1, PlayerTurn: EXIT SUB
			IF PlayField(1, 1) = 1 AND PlayField(3, 1) = 1 AND PlayField(2, 1) = 0 THEN PlayField(2, 1) = 2: Tic.DrawXO 2, 1, PlayerTurn: EXIT SUB
			IF PlayField(2, 1) = 1 AND PlayField(3, 1) = 1 AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = 2: Tic.DrawXO 1, 1, PlayerTurn: EXIT SUB

			IF PlayField(1, 2) = 1 AND PlayField(2, 2) = 1 AND PlayField(3, 2) = 0 THEN PlayField(3, 2) = 2: Tic.DrawXO 3, 2, PlayerTurn: EXIT SUB
			IF PlayField(1, 2) = 1 AND PlayField(3, 2) = 1 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2, PlayerTurn: EXIT SUB
			IF PlayField(2, 2) = 1 AND PlayField(3, 2) = 1 AND PlayField(1, 2) = 0 THEN PlayField(1, 2) = 2: Tic.DrawXO 1, 2, PlayerTurn: EXIT SUB
					 
			IF PlayField(1, 3) = 1 AND PlayField(2, 3) = 1 AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = 2: Tic.DrawXO 3, 3, PlayerTurn: EXIT SUB
			IF PlayField(1, 3) = 1 AND PlayField(3, 3) = 1 AND PlayField(2, 3) = 0 THEN PlayField(2, 3) = 2: Tic.DrawXO 2, 3, PlayerTurn: EXIT SUB
			IF PlayField(2, 3) = 1 AND PlayField(3, 3) = 1 AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = 2: Tic.DrawXO 1, 3, PlayerTurn: EXIT SUB

			'Diagonal
			IF PlayField(1, 1) = 1 AND PlayField(2, 2) = 1 AND PlayField(3, 3) = 0 THEN PlayField(3, 3) = 2: Tic.DrawXO 3, 3, PlayerTurn: EXIT SUB
			IF PlayField(1, 1) = 1 AND PlayField(3, 3) = 1 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2, PlayerTurn: EXIT SUB
			IF PlayField(2, 2) = 1 AND PlayField(3, 3) = 1 AND PlayField(1, 1) = 0 THEN PlayField(1, 1) = 2: Tic.DrawXO 1, 1, PlayerTurn: EXIT SUB

			IF PlayField(1, 3) = 1 AND PlayField(2, 2) = 1 AND PlayField(3, 1) = 0 THEN PlayField(3, 1) = 2: Tic.DrawXO 3, 1, PlayerTurn: EXIT SUB
			IF PlayField(1, 3) = 1 AND PlayField(3, 1) = 1 AND PlayField(2, 2) = 0 THEN PlayField(2, 2) = 2: Tic.DrawXO 2, 2, PlayerTurn: EXIT SUB
			IF PlayField(2, 2) = 1 AND PlayField(3, 1) = 1 AND PlayField(1, 3) = 0 THEN PlayField(1, 3) = 2: Tic.DrawXO 1, 3, PlayerTurn: EXIT SUB

		'If AI can't win, and X doesn't have two in a row, just pick a random
		'spot

			RANDOMIZE TIMER
			DIM SetCol, SetRow

			DO
				SetCol = INT(RND * 3) + 1
				SetRow = INT(RND * 3) + 1

				IF PlayField(SetRow, SetCol) = 0 THEN
					PlayField(SetRow, SetCol) = 2
					Tic.DrawXO SetRow, SetCol, PlayerTurn
					EXIT SUB
				END IF
		 LOOP
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
	
	DIM LX, LY
	LY = 29
	Mouse.Hide
	
	LINE (0, 29)-(639, scrHeight - 1), 2, BF

	FOR LX = 0 TO 639 STEP 6
		LINE (LX, 29)-(LX, scrHeight - 1), 10, , &H1111
	NEXT

	FOR LX = 3 TO 639 STEP 6
		LINE (LX, 31)-(LX, scrHeight - 1), 10, , &H1111
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

	FOR FieldRow = 1 TO 3
		FOR FieldCol = 1 TO 3
			Obj.DrawTxt txtPlayField(FieldRow, FieldCol), "", False
			Tic.DrawXO FieldRow, FieldCol, PlayField(FieldRow, FieldCol)
		NEXT
	NEXT

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
			CASE 1
				Mouse.Hide
				LINE (XCoord + 11, YCoord + 12)-(XCoord + 48, YCoord + 49), SystemTheme.TextboxText
				LINE (XCoord + 11, YCoord + 13)-(XCoord + 47, YCoord + 49), SystemTheme.TextboxText
				LINE (XCoord + 12, YCoord + 12)-(XCoord + 49, YCoord + 49), SystemTheme.TextboxText
				LINE (XCoord + 13, YCoord + 12)-(XCoord + 49, YCoord + 48), SystemTheme.TextboxText
				LINE (XCoord + 11, YCoord + 48)-(XCoord + 47, YCoord + 12), SystemTheme.TextboxText
				LINE (XCoord + 11, YCoord + 49)-(XCoord + 48, YCoord + 12), SystemTheme.TextboxText
				LINE (XCoord + 12, YCoord + 49)-(XCoord + 49, YCoord + 12), SystemTheme.TextboxText
				LINE (XCoord + 13, YCoord + 49)-(XCoord + 49, YCoord + 13), SystemTheme.TextboxText
				Mouse.Show
			CASE 2
				Mouse.Hide
				CIRCLE (XCoord + 30, YCoord + 30), 19, SystemTheme.TextboxText, , , CircleAspect
				CIRCLE (XCoord + 30, YCoord + 30), 18, SystemTheme.TextboxText, , , CircleAspect
				CIRCLE (XCoord + 30, YCoord + 30), 17, SystemTheme.TextboxText, , , CircleAspect
				PSET (XCoord + 14, YCoord + 23), SystemTheme.TextboxText
				PSET (XCoord + 15, YCoord + 21), SystemTheme.TextboxText
				PSET (XCoord + 21, YCoord + 15), SystemTheme.TextboxText
				PSET (XCoord + 23, YCoord + 14), SystemTheme.TextboxText
				PSET (XCoord + 14, YCoord + 37), SystemTheme.TextboxText
				PSET (XCoord + 15, YCoord + 39), SystemTheme.TextboxText
				PSET (XCoord + 21, YCoord + 45), SystemTheme.TextboxText
				PSET (XCoord + 23, YCoord + 46), SystemTheme.TextboxText
				PSET (XCoord + 37, YCoord + 46), SystemTheme.TextboxText
				PSET (XCoord + 39, YCoord + 45), SystemTheme.TextboxText
				PSET (XCoord + 45, YCoord + 39), SystemTheme.TextboxText
				PSET (XCoord + 46, YCoord + 37), SystemTheme.TextboxText
				PSET (XCoord + 46, YCoord + 23), SystemTheme.TextboxText
				PSET (XCoord + 45, YCoord + 21), SystemTheme.TextboxText
				PSET (XCoord + 39, YCoord + 15), SystemTheme.TextboxText
				PSET (XCoord + 37, YCoord + 14), SystemTheme.TextboxText
				LINE (XCoord + 16, YCoord + 18)-(XCoord + 18, YCoord + 16), SystemTheme.TextboxText
				LINE (XCoord + 42, YCoord + 16)-(XCoord + 44, YCoord + 18), SystemTheme.TextboxText
				LINE (XCoord + 44, YCoord + 42)-(XCoord + 42, YCoord + 44), SystemTheme.TextboxText
				LINE (XCoord + 16, YCoord + 42)-(XCoord + 18, YCoord + 44), SystemTheme.TextboxText
				Mouse.Show
		END SELECT

END SUB

' =========================================================================
'          NAME: Tic.LoadState()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: TICTAC.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Loads game state from config file. Default values are used
'                to create a new game, if one or more settings are missing.
' =========================================================================
FUNCTION Tic.LoadState ()

	IF NOT File.Exists("DATA\CONFIG\TICTAC" + LTRIM$(STR$(ProfileID)) + ".DAT") THEN
		Tic.LoadState = False
		GOTO SanityChecks
	END IF

	ON LOCAL ERROR RESUME NEXT

	DIM StateFile, X, Y, SoundEnabled
	StateFile = FREEFILE
	OPEN "DATA\CONFIG\TICTAC" + LTRIM$(STR$(ProfileID)) + ".DAT" FOR BINARY AS #StateFile
	
	GET #StateFile, , TotalTurns
	GET #StateFile, , EnableAI
	GET #StateFile, , PlayerTurn
	GET #StateFile, , PlayerStart
	GET #StateFile, , EnableAudio

	IF TotalTurns > 0 THEN
		FOR X = 1 TO 3
			FOR Y = 1 TO 3
				GET #StateFile, , PlayField(X, Y)
			NEXT
		NEXT
	END IF
	
	'If state was saved after a player won, start a new game
	IF TotalTurns > 8 THEN Tic.NewGame

	CLOSE #StateFile

	ON LOCAL ERROR RESUME NEXT

	Tic.LoadState = True

SanityChecks:
	'Various sanity checks to make sure loaded data is valid
	'crash
	IF TotalTurns < 0 OR TotalTurns > 9 THEN TotalTurns = 0
	IF EnableAI < -1 OR EnableAI > 0 THEN EnableAI = True
	IF PlayerTurn < 1 OR PlayerTurn > 2 THEN PlayerTurn = 1
	IF PlayerStart < 1 OR PlayerStart > 2 THEN PlayerStart = 1
	IF EnableAudio < -1 OR EnableAudio > 0 THEN EnableAudio = True
	FOR X = 1 TO 3
		FOR Y = 1 TO 3
			IF PlayField(X, Y) < 0 OR PlayField(X, Y) > 2 THEN PlayField(X, Y) = 0
		NEXT
	NEXT
	
END FUNCTION

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
	DIM DidLoadState

	Obj.SetSize frmTic.Pos, (640 - 221) / 2, (scrHeight - 28 - 221) / 2 + 28, 221, 221
	
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
	btnExit.Caption = "õClose"
	
	Obj.DrawMenu
	Tic.DrawBackground

	Mouse.Hide
	LINE (frmTic.Pos.Left + 2, frmTic.Pos.Top + 2)-(frmTic.Pos.Left + frmTic.Pos.Width - 2, frmTic.Pos.Top + frmTic.Pos.Height - 2), 2, BF
	Mouse.Show
	Obj.DrawFrm frmTic, 10, 8
	Obj.DrawBtn btnNew, False
	Obj.DrawBtn btnExit, False
	
	CircleAspect = 1

	DidLoadState = Tic.LoadState
	
	IF EnableAI = True THEN
		btnAIToggle.Caption = "Singleõplayer"
	ELSE
		btnAIToggle.Caption = "Multiõplayer"
	END IF

	IF EnableAudio THEN
		btnAudio.Caption = "Disable õsound"
	ELSE
		btnAudio.Caption = "Enable õsound"
	END IF

	Obj.DrawBtn btnAIToggle, False
	Obj.DrawBtn btnAudio, False
	
	DIM Key$

StartOfGame:
	Tic.DrawBoard

	IF NOT DidLoadState THEN
		Tic.PlaySound SoundNew
		DidLoadState = True 'Just to make sure sound only plays once...
	END IF

	IF EnableAI = True AND PlayerTurn = 2 THEN GOTO PerformAIMove
	Tic.PrintMessage msgPlayerTurn

	DO
		Key$ = LCASE$(INKEY$)

		IF Obj.BtnClick(btnNew) OR Key$ = "n" THEN
			Tic.NewGame
			GOTO StartOfGame
		END IF

		IF Obj.BtnClick(btnExit) OR Key$ = "c" THEN
			Tic.SaveState
			EXIT SUB
		END IF

		IF Obj.BtnClick(btnAIToggle) OR Key$ = "p" THEN
			EnableAI = NOT EnableAI
			IF EnableAI = True THEN
				btnAIToggle.Caption = "Multiõplayer"
			ELSE
				btnAIToggle.Caption = "Singleõplayer"
			END IF
			Obj.DrawBtn btnAIToggle, False
			Tic.NewGame
			GOTO StartOfGame
		END IF

		IF Key$ = "s" THEN
			EnableAudio = NOT EnableAudio
			IF EnableAudio THEN
				btnAudio.Caption = "Disable õsound"
			ELSE
				btnAudio.Caption = "Enable õsound"
			END IF
			Obj.DrawBtn btnAudio, False
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

			'Prevent audio from running wild if a key is held down
			IF FieldClicked THEN
				DO: LOOP WHILE LEN(INKEY$)
			END IF

			IF FieldClicked THEN
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

							IF PlayerTurn = 1 THEN
								PlayerTurn = 2
							ELSE
								PlayerTurn = 1
							END IF

							IF EnableAI = True AND TotalTurns < 9 AND PlayerTurn = 2 THEN
PerformAIMove:
								Tic.PrintMessage msgAITurn
								Tic.AIMove
								Tic.PlaySound SoundY
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
										PlayerTurn = 1
										Tic.PrintMessage msgPlayerTurn
									END IF
								END IF
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
	IF PlayerStart = 1 THEN
		PlayerStart = 2
	ELSE
		PlayerStart = 1
	END IF
	PlayerTurn = PlayerStart

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
		CASE SoundX
			SOUND 400, .7
		CASE SoundY
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

	Randomizer = INT(5 * RND + 1)

	IF PlayerTurn = 1 THEN
		CurrentTurn = "X"
	ELSE
		CurrentTurn = "O"
	END IF

	RANDOMIZE TIMER
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
					Message = CurrentTurn + " is becomming sentient in the quest to beat the humans..."
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
			END SELECT


	END SELECT


	Mouse.Hide
	IF UserSettings.ScreenMode = scrVGA THEN
		LINE (12, 81)-(627, 97), 2, BF
		Font.Print Message, (640 - Font.GetWidth(Message, fontHeading)) / 2, 85, 0, fontHeading
	ELSE
		LINE (12, 49)-(627, 65), 2, BF
		Font.Print Message, (640 - Font.GetWidth(Message, fontHeading)) / 2, 53, 0, fontHeading
	END IF
	Mouse.Show
	
END SUB

' =========================================================================
'          NAME: Tic.SaveState()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: TICTAC.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Saves the current state of the game to a config file.
'                This exact session can then be loaded again with
'                Tic.LoadState
' =========================================================================
SUB Tic.SaveState ()

	DIM StateFile, X, Y
	StateFile = FREEFILE
	OPEN "DATA\CONFIG\TICTAC" + LTRIM$(STR$(ProfileID)) + ".DAT" FOR BINARY AS #StateFile

	PUT #StateFile, , TotalTurns
	PUT #StateFile, , EnableAI
	PUT #StateFile, , PlayerTurn
	PUT #StateFile, , PlayerStart
	PUT #StateFile, , EnableAudio
	FOR X = 1 TO 3
		FOR Y = 1 TO 3
			PUT #StateFile, , PlayField(X, Y)
		NEXT
	NEXT

	CLOSE #StateFile

END SUB

