DECLARE SUB Mine.PrintStatus (PrintTimeOnly%)
OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Mine.CheckWin% ()
DECLARE SUB Mine.AIMove ()
DECLARE SUB Mine.DrawField ()
DECLARE SUB Mine.DrawXO (FieldRow%, FieldCol%, FieldValue%)
DECLARE SUB Mine.DrawBackground ()
DECLARE SUB Mine.NewGame ()
DECLARE SUB Mine.Main ()
DECLARE FUNCTION Mine.SetSize% ()
DECLARE SUB Mine.PlaySound (SoundType AS INTEGER)
DECLARE SUB Mine.PrintMessage (MessageType AS INTEGER)


'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

CONST FieldMined = 1
CONST FieldFlagged = 2
CONST FieldCleared = 4
CONST FieldNumbered = 8

CONST SoundNew = 0
CONST SoundIllegalMove = 1
CONST SoundWin = 2
CONST SoundLoose = 3
CONST SoundClear = 4
CONST SoundFlag = 5

DIM SHARED EnableAudio AS INTEGER
DIM SHARED GameOver AS INTEGER
DIM SHARED MineCount AS INTEGER
DIM SHARED FieldWidth AS INTEGER
DIM SHARED FieldHeight AS INTEGER
DIM SHARED StartTime AS LONG
REDIM SHARED MineField(16, 16) AS INTEGER

Sys.Load

Mine.Main

FUNCTION Mine.CheckWin ()

END FUNCTION

SUB Mine.DrawBackground ()
	
	DIM LX
	Mouse.Hide
	
	

	FOR LX = 0 TO 639 STEP 6
		LINE (LX, 29)-(LX, 349), 14, , &H1111
	NEXT

	FOR LX = 3 TO 639 STEP 6
		LINE (LX, 31)-(LX, 349), 14, , &H1111
	NEXT

	Mouse.Show
	
END SUB

SUB Mine.DrawField ()

	DIM btnField AS ButtonType
	DIM FieldRow, FieldCol
	
	Obj.SetSize btnField.Pos, SizeRetain, SizeRetain, 16, 16

	Mouse.Hide
	LINE (0, 29)-(639, 349), Theme.Window, BF

	'DEBUG - calculate board offset from size...

	FOR FieldRow = 0 TO 17
		btnField.Pos.Top = FieldRow * btnField.Pos.Height + 37

		FOR FieldCol = 0 TO 38
			btnField.Pos.Left = FieldCol * btnField.Pos.Width + 7
			'Obj.DrawBtn btnField, False
		NEXT

	NEXT

	Mouse.Show

END SUB

' =========================================================================
'          NAME: Mine.Main()
'    PARAMETERS: None
'       RETURNS: Nothing
'       ASSUMES: Nothing
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Main UI and logic for the Tic Tac Toe accessory
' =========================================================================
SUB Mine.Main ()

	DIM btnNew AS ButtonType, btnSize AS ButtonType
	DIM btnAudio AS ButtonType, btnExit AS ButtonType
	DIM FieldRow, FieldCol
	DIM TimeCompare AS LONG
	DIM Key$

	Obj.SetSize btnNew.Pos, 3, 2, 92, 22
	Obj.SetSize btnSize.Pos, 102, 2, 92, 22
	Obj.SetSize btnAudio.Pos, 201, 2, 92, 22
	Obj.SetSize btnExit.Pos, 545, 2, 92, 22
	btnNew.Caption = "õNew game"
	btnSize.Caption = "Siõze"
	btnAudio.Caption = "õSound"
	btnExit.Caption = "Eõxit"
	
	Obj.DrawMenu
	
	Obj.DrawBtn btnNew, False
	Obj.DrawBtn btnSize, False
	Obj.DrawBtn btnAudio, False
	Obj.DrawBtn btnExit, False
	
	FieldWidth = 16
	FieldHeight = 16
	Mine.NewGame
	
	TimeCompare = TIMER + 1
	DO
		Key$ = LCASE$(INKEY$)
		
		IF Obj.BtnClick(btnNew) OR Key$ = "n" THEN
			Mine.NewGame
		END IF

		IF Obj.BtnClick(btnAudio) OR Key$ = "s" THEN
			EnableAudio = NOT EnableAudio
			Mine.PrintStatus False
		END IF

		IF Obj.BtnClick(btnSize) OR Key$ = "z" THEN
			IF Mine.SetSize THEN
				Mine.DrawBackground
				Mine.NewGame
			END IF
		END IF

		IF Obj.BtnClick(btnExit) OR Key$ = "x" THEN
			EXIT SUB
		END IF

		IF NOT GameOver AND TimeCompare < TIMER THEN
			Mine.PrintStatus True
			TimeCompare = TIMER + 1
		END IF
		
		IF False = True THEN
			'Prevent audio from running wild if mouse/key is held down
			DO: LOOP WHILE LEN(INKEY$) OR Mouse.Clicked
			
			IF MineField(FieldRow, FieldCol) = 0 THEN

			ELSE
				Mine.PlaySound SoundIllegalMove
			END IF

		END IF

	LOOP
	
END SUB

SUB Mine.NewGame ()

	DIM FieldRow, FieldCol
	
	'DEBUG
	'REDIM MineField(MineFieldSize, MineFieldSize) AS INTEGER

	Mine.DrawField
	Mine.PlaySound SoundNew

	StartTime = INT(TIMER)
	Mine.PrintStatus False

END SUB

SUB Mine.PlaySound (SoundType AS INTEGER)

	IF NOT EnableAudio THEN EXIT SUB

	SELECT CASE SoundType
		CASE SoundIllegalMove
			SOUND 400, .7
		CASE SoundWin
			SOUND 800, .7
		CASE SoundLoose
			SOUND 100, .7
		CASE SoundClear
			PLAY "O2 T100 C D T200 G T400 E"
		CASE SoundFlag
			PLAY "O1 T400 E3 G3 D6 T100 C9 C9"
	END SELECT

END SUB

SUB Mine.PrintStatus (PrintTimeOnly)
	DIM Message AS STRING
	DIM TimeCompare AS LONG
	DIM Minutes, Seconds

	Mouse.Hide
	IF NOT PrintTimeOnly THEN
		LINE (6, 330)-(632, 342), Theme.Window, BF
		Message = "Field size:" + STR$(FieldWidth) + "x" + LTRIM$(STR$(FieldHeight))
		Font.Print Message, 8, 332, Theme.WindowText, fontHeading

		IF EnableAudio THEN
			Message = "Sound: On"
		ELSE
			Message = "Sound: Off"
		END IF
		Font.Print Message, (630 - Font.GetWidth(Message, fontHeading)), 332, Theme.WindowText, fontHeading
	ELSE
		'Clear timer only
		LINE (278, 330)-(360, 342), Theme.Window, BF
	END IF

	IF StartTime > INT(TIMER) THEN
		'If we cross midnight, start timer over to avoid weird times.
		'Ugly fix, might change later.
		'StartTime = INT(TIMER)
	END IF
	
	TimeCompare = TIMER - StartTime
	IF TimeCompare >= 60 THEN
		Minutes = TimeCompare / 60
	ELSE
		Minutes = 0
	END IF
	TimeCompare = TimeCompare - (Minutes * 60)
	Seconds = TimeCompare

	IF LEN(LTRIM$(STR$(Minutes))) = 1 THEN Message = "0"
	Message = Message + LTRIM$(STR$(Minutes)) + ":"
	IF LEN(LTRIM$(STR$(Seconds))) = 1 THEN Message = Message + "0"
	Message = Message + LTRIM$(STR$(Seconds))
	Font.Print Message, (640 - Font.GetWidth(Message, fontHeading)) / 2, 332, Theme.WindowText, fontHeading
	Mouse.Show
END SUB

FUNCTION Mine.SetSize ()

		DIM winSetSize AS WindowType
		DIM btnSize(0 TO 2) AS ButtonType
		DIM Key$, I, ActiveSelection

		Obj.SetSize winSetSize.Pos, sizeCenter, sizeCenter, 226, 304

		FOR I = 0 TO 2
				Obj.SetSize btnSize(I).Pos, winSetSize.Pos.Left + 13, winSetSize.Pos.Top + (I * 23) - 8, 200, 22
		NEXT
		btnSize(0).Caption = "16x16"
		btnSize(1).Caption = "24x24"
		btnSize(2).Caption = "18x39"

		ActiveSelection = 1

		Mouse.Hide
		PCOPY 0, 1
		Mouse.Show

		Obj.DrawWin winSetSize
		Obj.DrawBtn btnSize(0), True
		Obj.DrawBtn btnSize(1), False
		Obj.DrawBtn btnSize(2), False

		DO

			Key$ = LCASE$(INKEY$)

			IF Key$ = CHR$(13) THEN
				'DEBUG - set size
				Mine.SetSize = True
				Mouse.Hide
				PCOPY 1, 0
				Mouse.Show
				EXIT FUNCTION
			END IF

			IF Key$ = CHR$(27) THEN
				Mine.SetSize = False
				Mouse.Hide
				PCOPY 1, 0
				Mouse.Show
				EXIT FUNCTION
			END IF


			IF Mouse.Clicked THEN
				FOR I = 0 TO 2
					IF Obj.BtnClick(btnSize(I)) THEN
						Mine.SetSize = I
						Mouse.Hide
						PCOPY 1, 0
						Mouse.Show
						EXIT FUNCTION
					END IF
				NEXT
			END IF

			IF Key$ = CHR$(0) + "h" THEN
				Obj.DrawBtn btnSize(ActiveSelection), False
				IF ActiveSelection > 0 THEN
					ActiveSelection = ActiveSelection - 1
				ELSE
					ActiveSelection = UBOUND(btnSize)
				END IF
				Obj.DrawBtn btnSize(ActiveSelection), True
			END IF

			IF Key$ = CHR$(0) + "p" THEN
				Obj.DrawBtn btnSize(ActiveSelection), False
				IF ActiveSelection < 2 THEN
					ActiveSelection = ActiveSelection + 1
				ELSE
					ActiveSelection = 0
				END IF
				Obj.DrawBtn btnSize(ActiveSelection), True
			END IF

		LOOP



END FUNCTION

