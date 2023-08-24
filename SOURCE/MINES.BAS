OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Mine.GetNeighbors% (Row%, Col%)
DECLARE FUNCTION Mine.SetSize% ()
DECLARE SUB Mine.ClearNeighbors (FieldRow%, FieldCol%)
DECLARE SUB Mine.ClickCell (FieldRow%, FieldCol%, MouseButton%)
DECLARE SUB Mine.DrawCell (Row%, Col%)
DECLARE SUB Mine.DrawField ()
DECLARE SUB Mine.HelpFirstMove (Row%, Col%)
DECLARE SUB Mine.Main ()
DECLARE SUB Mine.NewGame ()
DECLARE SUB Mine.Pause ()
DECLARE SUB Mine.PlaySound (SoundType AS INTEGER)
DECLARE SUB Mine.PrintStatus (MineCountOnly, StatusMessage AS STRING)
DECLARE SUB Mine.PrintTime ()
DECLARE SUB Mine.Reveal ()

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

CONST FieldMined = 1
CONST FieldFlagged = 2
CONST FieldCleared = 4
CONST FieldNumbered = 8
CONST FieldExploded = 16
CONST FieldMasked = 32
CONST FieldKBSelected = 64

CONST SoundNew = 0
CONST SoundIllegalMove = 1
CONST SoundWin = 2
CONST SoundLoose = 3
CONST SoundClear = 4
CONST SoundFlag = 5

'Size of each clickable field
CONST CellSize = 16

DIM SHARED EnableAudio AS INTEGER
DIM SHARED GameOver AS INTEGER
DIM SHARED MineCount AS INTEGER
DIM SHARED FieldWidth AS INTEGER
DIM SHARED FieldHeight AS INTEGER
DIM SHARED posField AS PosType
DIM SHARED StartTime AS LONG
DIM SHARED CellsCleared AS INTEGER
DIM SHARED CellsFlagged AS INTEGER
DIM SHARED DebugMode AS INTEGER
DIM SHARED KeyRow AS INTEGER
DIM SHARED KeyCol AS INTEGER
REDIM SHARED MineField(16, 16) AS INTEGER

Sys.Load

Mine.Main

SUB Mine.ClearNeighbors (FieldRow, FieldCol)

	DIM CheckRow, CheckCol, NeighborsCleared
	DIM CheckNeighborRow, CheckNeighborCol

	'If the cell has neighbors, an empty space was not clicked and thus nothing
	'should be cleared around it
	IF Mine.GetNeighbors(FieldRow, FieldCol) THEN EXIT SUB

	Mouse.Hide
	'Set the current pos in the mask as cleared, then start a loop that checks
	'all neighbors to cleared cells Empty cells are cleared as well and marked
	'in the mask, to be checked on next loop. Repeat until no cells are cleared
	MineField(FieldRow, FieldCol) = MineField(FieldRow, FieldCol) XOR FieldMasked
	DO
		NeighborsCleared = False

		FOR CheckRow = 0 TO FieldHeight - 1
			FOR CheckCol = 0 TO FieldWidth - 1

				IF MineField(CheckRow, CheckCol) AND FieldMasked THEN
					'Remove from mask to avoid redundant checks
					MineField(CheckRow, CheckCol) = MineField(CheckRow, CheckCol) AND NOT FieldMasked

					'Clear only if has no neighbors
					IF Mine.GetNeighbors(CheckRow, CheckCol) = 0 THEN

						'Check all neighbors
						FOR CheckNeighborRow = CheckRow - 1 TO CheckRow + 1
							FOR CheckNeighborCol = CheckCol - 1 TO CheckCol + 1

								'Prevent "out of bounds" errors
								IF CheckNeighborRow >= 0 AND CheckNeighborCol >= 0 THEN
									IF CheckNeighborRow < FieldHeight AND CheckNeighborCol < FieldWidth THEN
									
										IF MineField(CheckNeighborRow, CheckNeighborCol) = 0 THEN
											'If neighbor is empty, clear it
											MineField(CheckNeighborRow, CheckNeighborCol) = MineField(CheckNeighborRow, CheckNeighborCol) XOR FieldCleared
											Mine.DrawCell CheckNeighborRow, CheckNeighborCol
											NeighborsCleared = True
											CellsCleared = CellsCleared + 1

											'If cleared field has no neighbours, add it to the mask
											IF NOT Mine.GetNeighbors(CheckNeighborRow, CheckNeighborCol) THEN
												MineField(CheckNeighborRow, CheckNeighborCol) = MineField(CheckNeighborRow, CheckNeighborCol) XOR FieldMasked
											END IF
										END IF
								
									END IF
								END IF

							NEXT
						NEXT

					END IF
					
				END IF

			NEXT
		NEXT

	LOOP UNTIL NeighborsCleared = False
	Mouse.Show
		
END SUB

SUB Mine.ClickCell (FieldRow, FieldCol, MouseButton)

	IF MineField(FieldRow, FieldCol) AND FieldCleared THEN
		Mine.PlaySound SoundIllegalMove
		EXIT SUB
	END IF

	IF CellsCleared = 0 THEN
		StartTime = INT(TIMER)

		'If first move, make sure there are no mines where there was clicked
		Mine.HelpFirstMove FieldRow, FieldCol
	END IF

	SELECT CASE MouseButton
		CASE mbLeft
			IF MineField(FieldRow, FieldCol) AND FieldFlagged THEN
				Mine.PlaySound SoundIllegalMove
				EXIT SUB
			END IF

			IF MineField(FieldRow, FieldCol) AND FieldMined THEN
				Mouse.Hide
				FOR FieldRow = 0 TO FieldHeight - 1
					FOR FieldCol = 0 TO FieldWidth - 1
						IF MineField(FieldRow, FieldCol) AND FieldMined THEN
							MineField(FieldRow, FieldCol) = MineField(FieldRow, FieldCol) OR FieldExploded
							Mine.DrawCell FieldRow, FieldCol
						END IF
					NEXT
				NEXT
				Mouse.Show
				Mine.PrintStatus False, "Kaboom! Game over."
				Mine.PlaySound SoundLoose
				GameOver = True
				EXIT SUB
			END IF

			'If we reach this point, clear the field and adjacent empty fields
			Mouse.Hide
			MineField(FieldRow, FieldCol) = MineField(FieldRow, FieldCol) OR FieldCleared
			CellsCleared = CellsCleared + 1
			IF CellsCleared = (FieldHeight * FieldWidth) - MineCount THEN
				Mine.DrawCell FieldRow, FieldCol

				FOR FieldRow = 0 TO FieldHeight - 1
					FOR FieldCol = 0 TO FieldWidth - 1
						IF MineField(FieldRow, FieldCol) AND FieldMined THEN
							IF NOT MineField(FieldRow, FieldCol) AND FieldFlagged THEN
								MineField(FieldRow, FieldCol) = MineField(FieldRow, FieldCol) XOR FieldFlagged
								Mine.DrawCell FieldRow, FieldCol
							END IF
						END IF
					NEXT
				NEXT
				Mouse.Show
				Mine.PrintStatus False, "Minefield cleared, good job!"
				Mine.PlaySound SoundWin
				GameOver = True
			ELSE
				Mine.PlaySound SoundClear
				Mouse.Hide
				Mine.DrawCell FieldRow, FieldCol
				Mine.ClearNeighbors FieldRow, FieldCol
				Mouse.Show
			END IF
			
		CASE mbRight

			IF MineField(FieldRow, FieldCol) AND FieldFlagged THEN
				CellsFlagged = CellsFlagged - 1
				MineField(FieldRow, FieldCol) = MineField(FieldRow, FieldCol) AND NOT FieldFlagged
			ELSE
				CellsFlagged = CellsFlagged + 1
				MineField(FieldRow, FieldCol) = MineField(FieldRow, FieldCol) XOR FieldFlagged
			END IF
			Mouse.Hide
			Mine.DrawCell FieldRow, FieldCol
			Mine.PrintStatus True, ""
			Mouse.Show
			Mine.PlaySound SoundFlag

	END SELECT
																			
END SUB

SUB Mine.DrawCell (Row, Col)
	
	DIM x1, y1, x2, y2
	DIM TextColor, Neighbors
	
	x1 = posField.Left + 1 + Col * CellSize
	y1 = posField.Top + 1 + Row * CellSize
	x2 = x1 + CellSize - 2
	y2 = y1 + CellSize - 2

	IF MineField(Row, Col) AND FieldExploded THEN

		'Kaboom!
		LINE (x1, y1)-(x2, y2), 4, BF

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
		
	ELSEIF MineField(Row, Col) AND FieldFlagged THEN

		'Background
		IF MineField(Row, Col) AND FieldKBSelected THEN
			LINE (x1 + 1, y1 + 1)-(x2 - 1, y2 - 1), 15, BF
		ELSE
			LINE (x1 + 1, y1 + 1)-(x2 - 1, y2 - 1), 7, BF
		END IF

		'Flag pole
		LINE (x1 + 6, y1 + 2)-(x1 + 6, y1 + 10), 0
		LINE (x1 + 4, y1 + 11)-(x1 + 8, y1 + 11), 0
		LINE (x1 + 3, y1 + 12)-(x1 + 9, y1 + 12), 0
		'Flag
		LINE (x1 + 7, y1 + 2)-(x1 + 7, y1 + 8), 12
		LINE (x1 + 8, y1 + 3)-(x1 + 8, y1 + 7), 12
		LINE (x1 + 9, y1 + 4)-(x1 + 9, y1 + 6), 12
		PSET (x1 + 10, y1 + 5), 12
		
	ELSEIF MineField(Row, Col) AND FieldCleared THEN

		'Field has been cleared, clear the cell
		LINE (x1, y1)-(x2, y2), 7, BF

		'Draw keyboard indicator if selected
		IF MineField(Row, Col) AND FieldKBSelected THEN
			LINE (x1 + 1, y1 + 1)-(x2 - 1, y2 - 1), 15, BF
		END IF

		'Draw neighbor count, if any
		Neighbors = Mine.GetNeighbors(Row, Col)
		IF Neighbors THEN
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
			Font.Print LTRIM$(STR$(Neighbors)), x1 + ((CellSize - Font.GetWidth(LTRIM$(STR$(Neighbors)), fontHeading)) / 2), y1 + 3, TextColor, fontHeading
		END IF
	
	ELSEIF MineField(Row, Col) AND FieldKBSelected THEN

		'Draw keyboard indicator if selected
		IF MineField(Row, Col) AND FieldKBSelected THEN
			LINE (x1 + 1, y1 + 1)-(x2 - 1, y2 - 1), 15, BF
		END IF

	ELSE

		'Not cleared, flagged, exploded or selected - meaning flag must have been
		'removed.

		'Clear button face
		LINE (x1 + 1, y1 + 1)-(x2 - 1, y2 - 1), 7, BF

	END IF


END SUB

SUB Mine.DrawField ()

	DIM FieldRow, FieldCol
	
	Obj.SetSize posField, SizeCenter, SizeRetain, FieldWidth * CellSize, FieldHeight * CellSize
	posField.Top = 180 - (posField.Height / 2)
	posField.Left = posField.Left
	posField.Top = posField.Top

	Mouse.Hide
	LINE (0, 29)-(639, 349), Theme.Window, BF

	'Button color
	LINE (posField.Left, posField.Top)-(posField.Left + posField.Width, posField.Top + posField.Height), 7, BF

	'Button light and shadows for first row/column
	LINE (posField.Left + 1, posField.Top + 1)-(posField.Left + posField.Width, posField.Top + 1), 15
	LINE (posField.Left + 1, posField.Top + 1)-(posField.Left + 1, posField.Top + posField.Height), 15
	LINE (posField.Left + 2, posField.Top + posField.Height - 1)-(posField.Left + posField.Width - 1, posField.Top + posField.Height - 1), 8
	LINE (posField.Left + posField.Width - 1, posField.Top + 2)-(posField.Left + posField.Width - 1, posField.Top + posField.Height - 1), 8

	'Button light and shadows
	FOR FieldCol = 1 TO FieldWidth - 1
		LINE (posField.Left + FieldCol * CellSize + 1, posField.Top)-(posField.Left + FieldCol * CellSize + 1, posField.Top + FieldHeight * CellSize), 15
		LINE (posField.Left + FieldCol * CellSize - 1, posField.Top + 1)-(posField.Left + FieldCol * CellSize - 1, posField.Top + FieldHeight * CellSize), 8
	NEXT
	FOR FieldRow = 1 TO FieldHeight - 1
		LINE (posField.Left, posField.Top + FieldRow * CellSize + 1)-(posField.Left + FieldWidth * CellSize, posField.Top + FieldRow * CellSize + 1), 15
		LINE (posField.Left + 1, posField.Top + FieldRow * CellSize - 1)-(posField.Left + FieldWidth * CellSize, posField.Top + FieldRow * CellSize - 1), 8
	NEXT

	'Button borders
	FOR FieldCol = 1 TO FieldWidth - 1
		LINE (posField.Left + FieldCol * CellSize, posField.Top)-(posField.Left + FieldCol * CellSize, posField.Top + FieldHeight * CellSize), 0
	NEXT
	FOR FieldRow = 1 TO FieldHeight - 1
		LINE (posField.Left, posField.Top + FieldRow * CellSize)-(posField.Left + FieldWidth * CellSize, posField.Top + FieldRow * CellSize), 0
	NEXT

	'Borders around playfield
	LINE (posField.Left, posField.Top)-(posField.Left + posField.Width, posField.Top + posField.Height), 0, B
	
	Mouse.Show

END SUB

FUNCTION Mine.GetNeighbors (Row, Col)

	DIM Neighbors
	DIM CheckRow, CheckCol

	FOR CheckRow = Row - 1 TO Row + 1
		FOR CheckCol = Col - 1 TO Col + 1

			IF CheckRow >= 0 AND CheckCol >= 0 THEN
				IF CheckRow < FieldHeight AND CheckCol < FieldWidth THEN
					IF MineField(CheckRow, CheckCol) AND FieldMined THEN Neighbors = Neighbors + 1
				END IF
			END IF

		NEXT
	NEXT

	Mine.GetNeighbors = Neighbors

END FUNCTION

SUB Mine.HelpFirstMove (Row, Col)
	'Called on first click in field. Checks clicked and all adjacent cells, and
	'moves any mines away from them to prevent loosing right away.

	DIM CheckRow, CheckCol, MinesMoved, MinePlace
	DO
		IF MinesMoved THEN
			'Mines were moved, randomly place them elsewhere
			RANDOMIZE TIMER
			DO
				CheckRow = INT(RND * FieldHeight)
				CheckCol = INT(RND * FieldWidth)
				IF NOT MineField(CheckRow, CheckCol) AND FieldMined THEN
					MineField(CheckRow, CheckCol) = FieldMined
					MinePlace = MinePlace + 1
				END IF
			LOOP UNTIL MinePlace = MinesMoved
			MinePlace = 0
			MinesMoved = 0
		END IF

		FOR CheckRow = Row - 1 TO Row + 1
			FOR CheckCol = Col - 1 TO Col + 1
				IF CheckRow >= 0 AND CheckCol >= 0 THEN
					IF CheckRow < FieldHeight AND CheckCol < FieldWidth THEN
						IF MineField(CheckRow, CheckCol) AND FieldMined THEN
							MineField(CheckRow, CheckCol) = 0
							MinesMoved = MinesMoved + 1
						END IF
					END IF
				END IF
			NEXT
		NEXT

	LOOP WHILE MinesMoved


END SUB

SUB Mine.Main ()

	DIM btnNew AS ButtonType, btnSize AS ButtonType, btnAudio AS ButtonType
	DIM btnPause AS ButtonType, btnAbout AS ButtonType, btnExit AS ButtonType
	DIM FieldRow, FieldCol, MouseButton
	DIM KeyVisible
	DIM TimeCompare AS LONG
	DIM Key$

	Obj.SetSize btnNew.Pos, 3, 2, 92, 22
	Obj.SetSize btnPause.Pos, 102, 2, 92, 22
	Obj.SetSize btnSize.Pos, 201, 2, 92, 22
	Obj.SetSize btnAudio.Pos, 300, 2, 92, 22
	Obj.SetSize btnAbout.Pos, 446, 2, 92, 22
	Obj.SetSize btnExit.Pos, 545, 2, 92, 22
	btnNew.Caption = "õNew game"
	btnSize.Caption = "Siõze"
	btnAudio.Caption = "õSound"
	btnPause.Caption = "õPause"
	btnAbout.Caption = "õAbout..."
	btnExit.Caption = "Eõxit"
	
	Mouse.Hide
	Obj.DrawMenu
	
	Obj.DrawBtn btnNew, False
	Obj.DrawBtn btnSize, False
	Obj.DrawBtn btnAudio, False
	Obj.DrawBtn btnPause, False
	Obj.DrawBtn btnAbout, False
	Obj.DrawBtn btnExit, False
	Mouse.Show

	'Default settings
	EnableAudio = True
	FieldWidth = 16
	FieldHeight = 16

	Mine.NewGame
	
	TimeCompare = TIMER + 1
	DO
		Key$ = LCASE$(INKEY$)
		
		IF Obj.BtnClick(btnNew) OR Key$ = "n" THEN
			Mine.NewGame
			KeyVisible = False
		END IF

		IF Obj.BtnClick(btnAudio) OR Key$ = "s" THEN
			EnableAudio = NOT EnableAudio
			Mine.PrintStatus False, ""
		END IF

		IF Obj.BtnClick(btnPause) OR Key$ = "p" THEN
			Mine.Pause
		END IF

		IF Obj.BtnClick(btnSize) OR Key$ = "z" THEN
			IF Mine.SetSize THEN
				Mine.NewGame
			END IF
		END IF

		IF Obj.BtnClick(btnExit) OR Key$ = "x" THEN
			EXIT SUB
		END IF

		IF Obj.BtnClick(btnAbout) OR Key$ = "a" THEN
			Sys.AboutBox "Minesweeper", "Jacob Palm", "MINE"
		END IF

		IF NOT GameOver THEN
			IF Key$ = "?" THEN
				DebugMode = True
				Mine.Reveal
			END IF

			IF (Key$ = CHR$(32) OR Key$ = CHR$(13)) AND KeyVisible = False THEN
				KeyVisible = True
				MineField(KeyRow, KeyCol) = MineField(KeyRow, KeyCol) XOR FieldKBSelected
				Mouse.Hide
				Mine.DrawCell KeyRow, KeyCol
				Mouse.Show
				Key$ = ""
				DO: LOOP WHILE LEN(INKEY$)
			END IF

			IF Key$ = CHR$(13) AND KeyVisible THEN
				Mine.ClickCell KeyRow, KeyCol, mbLeft
			END IF

			IF Key$ = CHR$(32) AND KeyVisible THEN
				Mine.ClickCell KeyRow, KeyCol, mbRight
			END IF
		
			'Up
			IF Key$ = CHR$(0) + "h" AND KeyRow > 0 THEN
				KeyVisible = True
				MineField(KeyRow, KeyCol) = MineField(KeyRow, KeyCol) AND NOT FieldKBSelected
				Mouse.Hide
				Mine.DrawCell KeyRow, KeyCol
				KeyRow = KeyRow - 1
				MineField(KeyRow, KeyCol) = MineField(KeyRow, KeyCol) XOR FieldKBSelected
				Mine.DrawCell KeyRow, KeyCol
				Mouse.Show
			END IF

			'Down
			IF Key$ = CHR$(0) + "p" AND KeyRow < FieldHeight - 1 THEN
				KeyVisible = True
				MineField(KeyRow, KeyCol) = MineField(KeyRow, KeyCol) AND NOT FieldKBSelected
				Mouse.Hide
				Mine.DrawCell KeyRow, KeyCol
				KeyRow = KeyRow + 1
				MineField(KeyRow, KeyCol) = MineField(KeyRow, KeyCol) XOR FieldKBSelected
				Mine.DrawCell KeyRow, KeyCol
				Mouse.Show
			END IF

			'Left
			IF Key$ = CHR$(0) + "k" AND KeyCol > 0 THEN
				KeyVisible = True
				MineField(KeyRow, KeyCol) = MineField(KeyRow, KeyCol) AND NOT FieldKBSelected
				Mouse.Hide
				Mine.DrawCell KeyRow, KeyCol
				KeyCol = KeyCol - 1
				MineField(KeyRow, KeyCol) = MineField(KeyRow, KeyCol) XOR FieldKBSelected
				Mine.DrawCell KeyRow, KeyCol
				Mouse.Show
			END IF

			'Right
			IF Key$ = CHR$(0) + "m" AND KeyCol < FieldWidth - 1 THEN
				KeyVisible = True
				MineField(KeyRow, KeyCol) = MineField(KeyRow, KeyCol) AND NOT FieldKBSelected
				Mouse.Hide
				Mine.DrawCell KeyRow, KeyCol
				KeyCol = KeyCol + 1
				MineField(KeyRow, KeyCol) = MineField(KeyRow, KeyCol) XOR FieldKBSelected
				Mine.DrawCell KeyRow, KeyCol
				Mouse.Show
			END IF
			
			IF StartTime AND TimeCompare < TIMER THEN
				Mine.PrintTime
				TimeCompare = TIMER + 1
			END IF
		
			IF Mouse.Clicked AND Mouse.InArea(posField) THEN
				MouseButton = Mouse.Clicked
				Mouse.Poll
			
				'Calculate which cell was clicked
				FieldCol = INT((MouseX - posField.Left) / CellSize)
				FieldRow = INT((MouseY - posField.Top) / CellSize)

				'Play field is one pixel too wide for calculation above, dirty fix
				'for this to prevent out of bounds clicks
				IF FieldCol = FieldWidth THEN FieldCol = FieldCol - 1
				IF FieldRow = FieldHeight THEN FieldRow = FieldRow - 1
			
				IF KeyVisible THEN
					KeyVisible = False
					MineField(KeyRow, KeyCol) = MineField(KeyRow, KeyCol) AND NOT FieldKBSelected
					Mouse.Hide
					Mine.DrawCell KeyRow, KeyCol
					Mouse.Show
				END IF

				Mine.ClickCell FieldRow, FieldCol, MouseButton

				KeyRow = FieldRow
				KeyCol = FieldCol

				'Prevent audio from running wild if mouse/key is held down
				DO: LOOP WHILE LEN(INKEY$) OR Mouse.Clicked

			END IF

		END IF

	LOOP
	
END SUB

SUB Mine.NewGame ()

	DIM FieldRow, FieldCol, MinePlace
	
	REDIM MineField(0 TO FieldHeight - 1, 0 TO FieldWidth - 1) AS INTEGER

	IF FieldHeight = 9 AND FieldWidth = 9 THEN MineCount = 10    '0.12% of 81
	IF FieldHeight = 16 AND FieldWidth = 16 THEN MineCount = 40  '0.15% of 240
	IF FieldHeight = 18 AND FieldWidth = 22 THEN MineCount = 67  '0.17% of 396
	IF FieldHeight = 18 AND FieldWidth = 39 THEN MineCount = 133 '0.19% of 702

	RANDOMIZE TIMER
	DO
		FieldRow = INT(RND * FieldHeight)
		FieldCol = INT(RND * FieldWidth)
		IF NOT MineField(FieldRow, FieldCol) AND FieldMined THEN
			MineField(FieldRow, FieldCol) = FieldMined
			MinePlace = MinePlace + 1
		END IF
	LOOP UNTIL MinePlace = MineCount

	Mine.DrawField
	Mine.PlaySound SoundNew
	GameOver = False
	CellsCleared = 0
	CellsFlagged = 0
	StartTime = 0
	KeyRow = FieldHeight / 2
	KeyCol = FieldWidth / 2
	
	Mine.PrintStatus False, ""

END SUB

SUB Mine.Pause ()

	DIM btnResume AS ButtonType, btnExit AS ButtonType
	DIM PauseTime AS SINGLE
	DIM Key$

	PauseTime = TIMER
	
	Obj.SetSize btnResume.Pos, 3, 2, 92, 22
	Obj.SetSize btnExit.Pos, 545, 2, 92, 22
	btnResume.Caption = "õResume"
	btnExit.Caption = "Eõxit"

	Mouse.Hide
	PCOPY 0, 1
	LINE (0, 29)-(639, 329), Theme.Window, BF
	Obj.DrawMenu
	Obj.DrawBtn btnResume, False
	Obj.DrawBtn btnExit, False
	Mouse.Show

	DO
		Key$ = LCASE$(INKEY$)

		IF Key$ = CHR$(32) OR Key$ = CHR$(13) OR Key$ = CHR$(27) THEN EXIT DO
		IF Obj.BtnClick(btnResume) OR Key$ = "r" THEN EXIT DO

		IF Obj.BtnClick(btnExit) THEN END
		
	LOOP

	Mouse.Hide
	PCOPY 1, 0
	Mouse.Show

	StartTime = StartTime + (TIMER - PauseTime)
	Mine.PrintTime

END SUB

SUB Mine.PlaySound (SoundType AS INTEGER)

	IF NOT EnableAudio THEN EXIT SUB

	SELECT CASE SoundType
		CASE SoundNew
			PLAY "O2 T180 C8 C8 E3"
		CASE SoundIllegalMove
			SOUND 100, .7
		CASE SoundWin
			PLAY "O2 T100 C D T200 G T400 E"
		CASE SoundLoose
			DIM I
			FOR I = 0 TO 8
				SOUND 37, .3
				SOUND 50, .3
				SOUND 37, .1
				SOUND 65, .2
			NEXT
		CASE SoundClear
			SOUND 400, .3
		CASE SoundFlag
			SOUND 800, .3
			SOUND 400, .3
	END SELECT

END SUB

SUB Mine.PrintStatus (MineCountOnly, StatusMessage AS STRING)
	DIM Message AS STRING
	
	'Only hide mouse if it's near the timer, to avoid cursor flicker on old PCs
	Mouse.Poll
	IF MouseY > 310 THEN Mouse.Hide

	IF MineCountOnly THEN
		LINE (106, 330)-(184, 343), Theme.Window, BF
		Message = LTRIM$(STR$(CellsFlagged)) + "/" + LTRIM$(STR$(MineCount))
		Font.Print Message, 110, 332, Theme.WindowText, fontHeading
		Mouse.Show
		EXIT SUB
	END IF

	'Clear both sides of timer
	LINE (6, 330)-(277, 343), Theme.Window, BF
	LINE (361, 330)-(632, 343), Theme.Window, BF

	IF LEN(StatusMessage) THEN
		Message = StatusMessage
	ELSE
		Message = "Flagged mines: " + STR$(CellsFlagged) + "/" + LTRIM$(STR$(MineCount))
	END IF
	Font.Print Message, 8, 332, Theme.WindowText, fontHeading

	IF EnableAudio THEN
		Message = "Sound: On"
	ELSE
		Message = "Sound: Off"
	END IF
	Font.Print Message, (630 - Font.GetWidth(Message, fontHeading)), 332, Theme.WindowText, fontHeading
	
	Mouse.Show

END SUB

SUB Mine.PrintTime ()

	DIM Message AS STRING
	DIM Hours, Minutes, Seconds

	'Only draw time if we are still playing
	IF GameOver THEN EXIT SUB

	'Only hide mouse if it's near the timer, to avoid cursor flicker on old PCs
	Mouse.Poll
	IF MouseY > 310 THEN Mouse.Hide

	'Clear timer only
	LINE (278, 330)-(360, 343), Theme.Window, BF

	IF StartTime > INT(TIMER) THEN
		'If we cross midnight, start timer over to avoid weird times.
		'Ugly fix, might change later.
		StartTime = INT(TIMER)
	END IF

	IF StartTime THEN
		Seconds = INT(TIMER - StartTime)
		Hours = Seconds \ 3600
		Minutes = (Seconds - (3600 * Hours)) \ 60
		Seconds = (Seconds - (3600 * Hours)) - (Minutes * 60)
		Message = ""

		IF Hours < 10 THEN Message = "0"
		Message = Message + LTRIM$(STR$(Hours)) + ":"
		IF Minutes < 10 THEN Message = Message + "0"
		Message = Message + LTRIM$(STR$(Minutes)) + ":"
		IF Seconds < 10 THEN Message = Message + "0"
		Message = Message + LTRIM$(STR$(Seconds))

		Font.Print Message, (640 - Font.GetWidth(Message, fontHeading)) / 2, 332, Theme.WindowText, fontHeading
	END IF

	Mouse.Show
END SUB

SUB Mine.Reveal ()
	DIM x1, y1, x2, y2, Row, Col

	Mouse.Hide
	FOR Row = 0 TO FieldHeight - 1
		FOR Col = 0 TO FieldWidth - 1
			IF MineField(Row, Col) AND FieldMined THEN
				x1 = posField.Left + 1 + Col * CellSize
				y1 = posField.Top + 1 + Row * CellSize
				x2 = x1 + CellSize - 2
				y2 = y1 + CellSize - 2
				LINE (x1, y1)-(x2, y2), 4, B
			END IF
		NEXT
	NEXT
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

		btnCancel.Caption = "õCancel"

		Mouse.Hide
		PCOPY 0, 1

		Obj.DrawWin winSetSize
		Obj.DrawBtn btnSize(0), False
		Obj.DrawBtn btnSize(1), False
		Obj.DrawBtn btnSize(2), False
		Obj.DrawBtn btnSize(3), False
		Obj.DrawBtn btnCancel, False

		Font.Print "9xõ9", btnSize(0).Pos.Left + ((btnSize(0).Pos.Width - Font.GetWidth("9x9", fontHeading)) / 2), btnSize(0).Pos.Top + 79, Theme.WindowText, fontHeading
		Font.Print "16x1õ6", btnSize(1).Pos.Left + ((btnSize(1).Pos.Width - Font.GetWidth("16x16", fontHeading)) / 2), btnSize(1).Pos.Top + 79, Theme.WindowText, fontHeading
		Font.Print "õ22x18", btnSize(2).Pos.Left + ((btnSize(2).Pos.Width - Font.GetWidth("22x18", fontHeading)) / 2), btnSize(2).Pos.Top + 79, Theme.WindowText, fontHeading
		Font.Print "õ39x18", btnSize(3).Pos.Left + ((btnSize(3).Pos.Width - Font.GetWidth("39x28", fontHeading)) / 2), btnSize(3).Pos.Top + 79, Theme.WindowText, fontHeading
		
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
				FieldHeight = 9
				FieldWidth = 9
				EXIT DO
			END IF

			IF Obj.BtnClick(btnSize(1)) OR Key$ = "6" THEN
				FieldHeight = 16
				FieldWidth = 16
				EXIT DO
			END IF

			IF Obj.BtnClick(btnSize(2)) OR Key$ = "2" THEN
				FieldHeight = 18
				FieldWidth = 22
				EXIT DO
			END IF

			IF Obj.BtnClick(btnSize(3)) OR Key$ = "3" THEN
				FieldHeight = 18
				FieldWidth = 39
				EXIT DO
			END IF

		LOOP

		Mine.SetSize = True
		
END FUNCTION

