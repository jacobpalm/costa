OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Mine.CheckWin% ()
DECLARE FUNCTION Mine.GetNeighbors% (Row%, Col%)
DECLARE FUNCTION Mine.SetSize% ()
DECLARE SUB Mine.DrawBox (Row%, Col%)
DECLARE SUB Mine.DrawField ()
DECLARE SUB Mine.Main ()
DECLARE SUB Mine.NewGame ()
DECLARE SUB Mine.PlaySound (SoundType AS INTEGER)
DECLARE SUB Mine.PrintStatus (PrintTimeOnly%)

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

CONST FieldMined = 1
CONST FieldFlagged = 2
CONST FieldCleared = 4
CONST FieldNumbered = 8
CONST FieldExploded = 16

CONST SoundNew = 0
CONST SoundIllegalMove = 1
CONST SoundWin = 2
CONST SoundLoose = 3
CONST SoundClear = 4
CONST SoundFlag = 5

'Size of each clickable field
CONST BoxSize = 16

DIM SHARED EnableAudio AS INTEGER
DIM SHARED GameOver AS INTEGER
DIM SHARED MineCOunt AS INTEGER
DIM SHARED FieldWidth AS INTEGER
DIM SHARED FieldHeight AS INTEGER
DIM SHARED posField AS PosType
DIM SHARED StartTime AS LONG
REDIM SHARED MineField(16, 16) AS INTEGER

Sys.Load

Mine.Main

FUNCTION Mine.CheckWin ()

END FUNCTION

SUB Mine.DrawBox (Row, Col)

	DIM x1, y1, x2, y2
	DIM TextColor, Neighbors

	x1 = posField.Left + 1 + Col * BoxSize
	y1 = posField.Top + 1 + Row * BoxSize
	x2 = x1 + BoxSize - 2
	y2 = y1 + BoxSize - 2

	Mouse.Hide


	'Note - all of these graphics will be moved to BSV files, this is just
	'for generating the graphics - DEBUG


	'Clear button, leave empty field - for all others than flagged
	'DEBUG - if not field and fieldFlagged
		LINE (x1, y1)-(x2, y2), 7, BF



	'Exploded background
		'LINE (x1, y1)-(x2, y2), 7, BF
	

	'Mine
		LINE (x1 + 5, y1 + 3)-(x1 + 9, y1 + 11), 0, BF
		LINE (x1 + 3, y1 + 5)-(x1 + 11, y1 + 9), 0, BF
		PSET (x1 + 3, y1 + 3), 0
		PSET (x1 + 3, y1 + 11), 0
		PSET (x1 + 4, y1 + 4), 0
		PSET (x1 + 4, y1 + 10), 0
		PSET (x1 + 10, y1 + 10), 0
		PSET (x1 + 11, y1 + 11), 0
		PSET (x1 + 10, y1 + 4), 0
		PSET (x1 + 11, y1 + 3), 0
		LINE (x1 + 1, y1 + 7)-(x2 - 1, y1 + 7), 0
		LINE (x1 + 7, y1 + 1)-(x1 + 7, y2 - 1), 0
		LINE (x1 + 5, y1 + 5)-(x1 + 6, y1 + 6), 15, B
	

	Mouse.Show
	EXIT SUB



	'Flagged
		'Flag pole
		LINE (x1 + 6, y1 + 2)-(x1 + 6, y1 + 10), 0
		LINE (x1 + 4, y1 + 11)-(x1 + 8, y1 + 11), 0
		LINE (x1 + 3, y1 + 12)-(x1 + 9, y1 + 12), 0
		'Flag
		LINE (x1 + 7, y1 + 2)-(x1 + 7, y1 + 8), 12
		LINE (x1 + 8, y1 + 3)-(x1 + 8, y1 + 7), 12
		LINE (x1 + 9, y1 + 4)-(x1 + 9, y1 + 6), 12
		PSET (x1 + 10, y1 + 5), 12



	'Text
	Neighbors = Mine.GetNeighbors(Row, Col)
	SELECT CASE Neighbors
		CASE 1
			TextColor = 9
		CASE 2
			TextColor = 2
		CASE 3
			TextColor = 12
		CASE 4
			TextColor = 1
		CASE 5
			TextColor = 4
		CASE 6
			TextColor = 3
		CASE 7
			TextColor = 0
		CASE 8
			TextColor = 8
	END SELECT
	Font.Print LTRIM$(STR$(Neighbors)), x1 + ((BoxSize - Font.GetWidth(LTRIM$(STR$(Neighbors)), fontHeading)) / 2), y1 + 3, TextColor, fontHeading

	Mouse.Show

END SUB

SUB Mine.DrawField ()

	DIM FieldRow, FieldCol
	
	Obj.SetSize posField, SizeCenter, SizeRetain, FieldWidth * BoxSize, FieldHeight * BoxSize
	posField.Top = 180 - (posField.Height / 2)
	posField.Left = posField.Left
	posField.Top = posField.Top

	Mouse.Hide
	LINE (0, 29)-(639, 349), Theme.Window, BF
	Mouse.Show

	Mouse.Hide
	'Button color
	LINE (posField.Left, posField.Top)-(posField.Left + posField.Width, posField.Top + posField.Height), 7, BF

	'Button light and shadows for first row/column
	LINE (posField.Left + 1, posField.Top + 1)-(posField.Left + posField.Width, posField.Top + 1), 15
	LINE (posField.Left + 1, posField.Top + 1)-(posField.Left + 1, posField.Top + posField.Height), 15
	LINE (posField.Left + 2, posField.Top + posField.Height - 1)-(posField.Left + posField.Width - 1, posField.Top + posField.Height - 1), 8
	LINE (posField.Left + posField.Width - 1, posField.Top + 2)-(posField.Left + posField.Width - 1, posField.Top + posField.Height - 1), 8

	'Button light and shadows
	FOR FieldCol = 1 TO FieldWidth - 1
		LINE (posField.Left + FieldCol * BoxSize + 1, posField.Top)-(posField.Left + FieldCol * BoxSize + 1, posField.Top + FieldHeight * BoxSize), 15
		LINE (posField.Left + FieldCol * BoxSize - 1, posField.Top + 1)-(posField.Left + FieldCol * BoxSize - 1, posField.Top + FieldHeight * BoxSize), 8
	NEXT
	FOR FieldRow = 1 TO FieldHeight - 1
		LINE (posField.Left, posField.Top + FieldRow * BoxSize + 1)-(posField.Left + FieldWidth * BoxSize, posField.Top + FieldRow * BoxSize + 1), 15
		LINE (posField.Left + 1, posField.Top + FieldRow * BoxSize - 1)-(posField.Left + FieldWidth * BoxSize, posField.Top + FieldRow * BoxSize - 1), 8
	NEXT

	'Button borders
	FOR FieldCol = 1 TO FieldWidth - 1
		LINE (posField.Left + FieldCol * BoxSize, posField.Top)-(posField.Left + FieldCol * BoxSize, posField.Top + FieldHeight * BoxSize), 0
	NEXT
	FOR FieldRow = 1 TO FieldHeight - 1
		LINE (posField.Left, posField.Top + FieldRow * BoxSize)-(posField.Left + FieldWidth * BoxSize, posField.Top + FieldRow * BoxSize), 0
	NEXT

	'Borders around playfield
	LINE (posField.Left, posField.Top)-(posField.Left + posField.Width, posField.Top + posField.Height), 0, B
	

	Mouse.Show

END SUB

FUNCTION Mine.GetNeighbors (Row, Col)

	'DEBUG - check all eight neighbors, mind that some may be out of bounds

	RANDOMIZE TIMER
	Mine.GetNeighbors = INT(RND * 8) + 1

END FUNCTION

SUB Mine.Main ()

	DIM btnNew AS ButtonType, btnSize AS ButtonType
	DIM btnAudio AS ButtonType, btnExit AS ButtonType
	DIM FieldRow, FieldCol, MouseButton
	DIM TimeCompare AS LONG
	DIM Key$

	Obj.SetSize btnNew.Pos, 3, 2, 92, 22
	Obj.SetSize btnSize.Pos, 102, 2, 92, 22
	Obj.SetSize btnAudio.Pos, 201, 2, 92, 22
	Obj.SetSize btnExit.Pos, 545, 2, 92, 22
	btnNew.Caption = "�New game"
	btnSize.Caption = "Si�ze"
	btnAudio.Caption = "�Sound"
	btnExit.Caption = "E�xit"
	
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
		
		IF Mouse.Clicked AND Mouse.InArea(posField) THEN
			MouseButton = Mouse.Clicked
			Mouse.Poll
			
			FieldCol = INT((MouseX - posField.Left) / BoxSize)
			FieldRow = INT((MouseY - posField.Top) / BoxSize)

			'Play field is one pixel too wide for calculation above, dirty fix
			'for this to prevent out of bounds clicks
			IF FieldCol = FieldWidth THEN FieldCol = FieldCol - 1
			IF FieldRow = FieldHeight THEN FieldRow = FieldRow - 1
			
			'if MouseButton = mbLeft Then
			'if MouseButton = mbRight Then

			Mine.DrawBox FieldRow, FieldCol
			'IF MineField(FieldRow, FieldCol) = 0 THEN
			'
			'ELSE
			'  Mine.PlaySound SoundIllegalMove
			'END IF

			'Prevent audio from running wild if mouse/key is held down
			DO: LOOP WHILE LEN(INKEY$) OR Mouse.Clicked

		END IF

	LOOP
	
END SUB

SUB Mine.NewGame ()

	DIM FieldRow, FieldCol
	
	REDIM MineField(0 TO FieldWidth - 1, 0 TO FieldHeight - 1) AS INTEGER

	IF FieldWidth = 9 AND FieldHeight = 9 THEN MineCOunt = 10
	IF FieldWidth = 16 AND FieldHeight = 16 THEN MineCOunt = 10
	IF FieldWidth = 18 AND FieldHeight = 22 THEN MineCOunt = 10
	IF FieldWidth = 18 AND FieldHeight = 39 THEN MineCOunt = 10

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
		Message = LTRIM$(STR$(FieldWidth)) + "x" + LTRIM$(STR$(FieldHeight))
		Message = Message + " with" + STR$(MineCOunt) + " mines"
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
		DIM btnSize(0 TO 3) AS ButtonType, btnCancel AS ButtonType
		DIM X, Y
		DIM Key$

		Obj.SetSize winSetSize.Pos, SizeCenter, SizeCenter, 236, 264

		Obj.SetSize btnSize(0).Pos, winSetSize.Pos.Left + 13, winSetSize.Pos.Top + 11, 100, 100
		Obj.SetSize btnSize(1).Pos, btnSize(0).Pos.Left + 110, winSetSize.Pos.Top + 11, 100, 100
		Obj.SetSize btnSize(2).Pos, winSetSize.Pos.Left + 13, btnSize(0).Pos.Top + 110, 100, 100
		Obj.SetSize btnSize(3).Pos, btnSize(2).Pos.Left + 110, btnSize(2).Pos.Top, 100, 100
		Obj.SetSize btnCancel.Pos, winSetSize.Pos.Left + 13, btnSize(2).Pos.Top + 110, 210, 22
		
		btnSize(0).Transparent = True
		btnSize(1).Transparent = True
		btnSize(2).Transparent = True
		btnSize(3).Transparent = True

		btnCancel.Caption = "�Cancel"

		Mouse.Hide
		PCOPY 0, 1
		Mouse.Show

		Obj.DrawWin winSetSize
		Obj.DrawBtn btnSize(0), False
		Obj.DrawBtn btnSize(1), False
		Obj.DrawBtn btnSize(2), False
		Obj.DrawBtn btnSize(3), False
		Obj.DrawBtn btnCancel, False

		Mouse.Hide
		Font.Print "9x�9", btnSize(0).Pos.Left + ((btnSize(0).Pos.Width - Font.GetWidth("9x9", fontHeading)) / 2), btnSize(0).Pos.Top + 79, Theme.WindowText, fontHeading
		Font.Print "16x1�6", btnSize(1).Pos.Left + ((btnSize(1).Pos.Width - Font.GetWidth("16x16", fontHeading)) / 2), btnSize(1).Pos.Top + 79, Theme.WindowText, fontHeading
		Font.Print "�22x18", btnSize(2).Pos.Left + ((btnSize(2).Pos.Width - Font.GetWidth("22x18", fontHeading)) / 2), btnSize(2).Pos.Top + 79, Theme.WindowText, fontHeading
		Font.Print "�39x18", btnSize(3).Pos.Left + ((btnSize(3).Pos.Width - Font.GetWidth("39x28", fontHeading)) / 2), btnSize(3).Pos.Top + 79, Theme.WindowText, fontHeading
		
		'9x9
		FOR X = 0 TO 3
			LINE (252 + X * 9, 94)-(252 + X * 9, 121), Theme.WindowText
		NEXT
		FOR Y = 0 TO 3
			LINE (252, 94 + Y * 9)-(279, 94 + Y * 9), Theme.WindowText
		NEXT

		'16x16
		FOR X = 0 TO 4
			LINE (357 + X * 9, 90)-(357 + X * 9, 126), Theme.WindowText
		NEXT
		FOR Y = 0 TO 4
			LINE (357, 90 + Y * 9)-(393, 90 + Y * 9), Theme.WindowText
		NEXT

		'22x18
		FOR X = 0 TO 6
			LINE (238 + X * 9, 195)-(238 + X * 9, 240), Theme.WindowText
		NEXT
		FOR Y = 0 TO 5
			LINE (238, 195 + Y * 9)-(292, 195 + Y * 9), Theme.WindowText
		NEXT

		'39x18
		FOR X = 0 TO 8
			LINE (339 + X * 9, 195)-(339 + X * 9, 240), Theme.WindowText
		NEXT
		FOR Y = 0 TO 5
			LINE (339, 195 + Y * 9)-(411, 195 + Y * 9), Theme.WindowText
		NEXT

		Mouse.Show

		DO

			Key$ = LCASE$(INKEY$)

			IF Obj.BtnClick(btnCancel) OR Key$ = CHR$(27) OR Key$ = "c" THEN
				Mine.SetSize = False
				Mouse.Hide
				PCOPY 1, 0
				Mouse.Show
				EXIT FUNCTION
			END IF


			IF Obj.BtnClick(btnSize(0)) OR Key$ = "9" THEN
				FieldWidth = 9
				FieldHeight = 9
				EXIT DO
			END IF

			IF Obj.BtnClick(btnSize(1)) OR Key$ = "6" THEN
				FieldWidth = 16
				FieldHeight = 16
				EXIT DO
			END IF

			IF Obj.BtnClick(btnSize(2)) OR Key$ = "2" THEN
				FieldWidth = 22
				FieldHeight = 18
				EXIT DO
			END IF

			IF Obj.BtnClick(btnSize(3)) OR Key$ = "3" THEN
				FieldWidth = 39
				FieldHeight = 18
				EXIT DO
			END IF

		LOOP

		Mine.SetSize = True
		
END FUNCTION
