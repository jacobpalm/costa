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
														 
DIM SHARED PlayerStart AS INTEGER
DIM SHARED PlayerTurn AS INTEGER
DIM SHARED TotalTurns AS INTEGER
DIM SHARED EnableAI AS INTEGER
DIM SHARED chkAudio AS CheckboxType
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
		Sys.Delay (INT(RND * 550) + 550) / 1000

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
				LINE (XCoord + 11, YCoord + 12)-(XCoord + 48, YCoord + 49), ClrTextboxText
				LINE (XCoord + 11, YCoord + 13)-(XCoord + 47, YCoord + 49), ClrTextboxText
				LINE (XCoord + 12, YCoord + 12)-(XCoord + 49, YCoord + 49), ClrTextboxText
				LINE (XCoord + 13, YCoord + 12)-(XCoord + 49, YCoord + 48), ClrTextboxText
				LINE (XCoord + 11, YCoord + 48)-(XCoord + 47, YCoord + 12), ClrTextboxText
				LINE (XCoord + 11, YCoord + 49)-(XCoord + 48, YCoord + 12), ClrTextboxText
				LINE (XCoord + 12, YCoord + 49)-(XCoord + 49, YCoord + 12), ClrTextboxText
				LINE (XCoord + 13, YCoord + 49)-(XCoord + 49, YCoord + 13), ClrTextboxText
				Mouse.Show
			CASE 2
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

	IF NOT File.Exists("DATA\CONFIG\" + ProfileID + "\TICTAC.CFG") THEN
		Tic.LoadState = False
		GOTO SanityChecks
	END IF

	ON LOCAL ERROR RESUME NEXT

	DIM StateFile, X, Y, SoundEnabled
	StateFile = FREEFILE
	OPEN "DATA\CONFIG\" + ProfileID + "\TICTAC.CFG" FOR BINARY AS #StateFile
	
	GET #StateFile, , TotalTurns
	GET #StateFile, , EnableAI
	GET #StateFile, , PlayerTurn
	GET #StateFile, , PlayerStart
	GET #StateFile, , chkAudio.Checked

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
	IF EnableAI < -1 OR EnableAI > 0 THEN EnableAI = -1
	IF PlayerTurn < 1 OR PlayerTurn > 2 THEN PlayerTurn = 1
	IF PlayerStart < 1 OR PlayerStart > 2 THEN PlayerStart = 1
	IF chkAudio.Checked < -1 OR chkAudio.Checked > 0 THEN chkAudio.Checked = -1
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

	DIM winTic AS WindowType
	DIM btnNew AS ButtonType, btnAIToggle AS ButtonType, btnExit AS ButtonType
	DIM FieldRow, FieldCol
	DIM DidLoadState

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
	btnExit.Caption = "Close": btnExit.HotKey = 1
	btnAIToggle.HotKey = 3

	Obj.SetSize chkAudio.Pos, 376, 336, -1, -1
	
	Obj.DrawWin winTic
	Obj.DrawBtn btnNew, False
	Obj.DrawBtn btnExit, False
	Font.Print "Enable audio", 396, 339, clrWindowText, fontNormal
	Mouse.Hide
	LINE (438, 350)-(444, 350), clrWindowText
	Mouse.Show

	DidLoadState = Tic.LoadState
	
	IF EnableAI = True THEN
		btnAIToggle.Caption = "2 players"
	ELSE
		btnAIToggle.Caption = "1 player"
	END IF
	Obj.DrawBtn btnAIToggle, False

	Obj.DrawChk chkAudio

	DIM key$

StartOfGame:
	Tic.DrawBoard

	Mouse.Hide
	LINE (376, 271)-(476, 282), ClrWindow, BF
	Mouse.Show
	IF PlayerTurn = 1 THEN
		Font.Print "X", 400, 271, clrWindowText, 3
	ELSE
		Font.Print "O", 400, 271, clrWindowText, 3
	END IF
	Font.Print "'s turn", 408, 271, clrWindowText, 2

	IF NOT DidLoadState THEN
		Tic.PlaySound SoundNew
		DidLoadState = True 'Just to make sure sound only plays once...
	END IF

	IF EnableAI = True AND PlayerTurn = 2 THEN GOTO PerformAIMove

	DO
		key$ = LCASE$(INKEY$)

		IF Obj.BtnClick(btnNew) OR key$ = "n" THEN
			Tic.NewGame
			GOTO StartOfGame
		END IF

		IF Obj.BtnClick(btnExit) OR key$ = "c" THEN
			Tic.SaveState
			EXIT SUB
		END IF

		IF Obj.BtnClick(btnAIToggle) OR key$ = "p" THEN
			EnableAI = NOT EnableAI
			IF EnableAI = True THEN
				btnAIToggle.Caption = "2 players"
			ELSE
				btnAIToggle.Caption = "1 player"
			END IF
			Obj.DrawBtn btnAIToggle, False
			Tic.NewGame
			GOTO StartOfGame
		END IF

		Obj.ChkClick chkAudio
		IF key$ = "a" THEN
			chkAudio.Checked = NOT chkAudio.Checked
			Obj.DrawChk chkAudio
		END IF

		IF TotalTurns < 9 THEN
			IF Obj.TxtClick(txtPlayField(1, 1)) OR key$ = "7" THEN FieldClicked = True: FieldRow = 1: FieldCol = 1
			IF Obj.TxtClick(txtPlayField(1, 2)) OR key$ = "8" THEN FieldClicked = True: FieldRow = 1: FieldCol = 2
			IF Obj.TxtClick(txtPlayField(1, 3)) OR key$ = "9" THEN FieldClicked = True: FieldRow = 1: FieldCol = 3
			IF Obj.TxtClick(txtPlayField(2, 1)) OR key$ = "4" THEN FieldClicked = True: FieldRow = 2: FieldCol = 1
			IF Obj.TxtClick(txtPlayField(2, 2)) OR key$ = "5" THEN FieldClicked = True: FieldRow = 2: FieldCol = 2
			IF Obj.TxtClick(txtPlayField(2, 3)) OR key$ = "6" THEN FieldClicked = True: FieldRow = 2: FieldCol = 3
			IF Obj.TxtClick(txtPlayField(3, 1)) OR key$ = "1" THEN FieldClicked = True: FieldRow = 3: FieldCol = 1
			IF Obj.TxtClick(txtPlayField(3, 2)) OR key$ = "2" THEN FieldClicked = True: FieldRow = 3: FieldCol = 2
			IF Obj.TxtClick(txtPlayField(3, 3)) OR key$ = "3" THEN FieldClicked = True: FieldRow = 3: FieldCol = 3

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
						Mouse.Hide
						LINE (376, 271)-(476, 279), ClrWindow, BF
						Mouse.Show

						IF PlayerTurn = 1 THEN
							Font.Print "X", 377, 271, clrWindowText, 3
						ELSE
							Font.Print "O", 377, 271, clrWindowText, 3
						END IF
						Font.Print "wins the game!", 388, 271, clrWindowText, 2
						TotalTurns = 9
						Tic.PlaySound SoundWin
					ELSE
						IF TotalTurns < 9 THEN
							Mouse.Hide
							LINE (400, 271)-(405, 279), ClrWindow, BF
							Mouse.Show

							IF PlayerTurn = 1 THEN
								PlayerTurn = 2
								Font.Print "O", 400, 271, clrWindowText, 3
							ELSE
								PlayerTurn = 1
								Font.Print "X", 400, 271, clrWindowText, 3
							END IF

							IF EnableAI = True AND TotalTurns < 9 AND PlayerTurn = 2 THEN
PerformAIMove:
								Tic.AIMove
								Tic.PlaySound SoundY
								TotalTurns = TotalTurns + 1
								IF Tic.CheckWin = True THEN
									Mouse.Hide
									LINE (376, 271)-(476, 279), ClrWindow, BF
									Mouse.Show
									Font.Print "O", 377, 271, clrWindowText, 3
									Font.Print "wins the game!", 388, 271, clrWindowText, 2
									Tic.PlaySound SoundLoose
									TotalTurns = 9
								ELSE
									IF TotalTurns = 9 THEN
										Mouse.Hide
										LINE (376, 271)-(476, 279), ClrWindow, BF
										Mouse.Show
										Font.Print "It's a draw!", 393, 271, clrWindowText, 2
										Tic.PlaySound SoundDraw
									ELSE
										PlayerTurn = 1
										Mouse.Hide
										LINE (400, 271)-(405, 279), ClrWindow, BF
										Mouse.Show
										Font.Print "X", 400, 271, clrWindowText, 3
									END IF
								END IF
							END IF

						ELSE
							Mouse.Hide
							LINE (376, 271)-(476, 279), ClrWindow, BF
							Mouse.Show
							Font.Print "It's a draw!", 393, 271, clrWindowText, 2
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

	IF NOT chkAudio.Checked THEN EXIT SUB

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
	OPEN "DATA\CONFIG\" + ProfileID + "\TICTAC.CFG" FOR BINARY AS #StateFile

	PUT #StateFile, , TotalTurns
	PUT #StateFile, , EnableAI
	PUT #StateFile, , PlayerTurn
	PUT #StateFile, , PlayerStart
	PUT #StateFile, , chkAudio.Checked
	FOR X = 1 TO 3
		FOR Y = 1 TO 3
			PUT #StateFile, , PlayField(X, Y)
		NEXT
	NEXT

	CLOSE #StateFile

END SUB

