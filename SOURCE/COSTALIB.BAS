DECLARE FUNCTION Temp.Path () AS STRING
OPTION EXPLICIT
DEFINT A-Z

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'
'$INCLUDE: 'C:\VBDOS\VBDOS.BI'

'This is dimmed here, and not in LIBRARY.BI, because only this module uses
'it
	TYPE IconDataType
		Pixel(31, 31) AS INTEGER
	END TYPE
	
	DIM SHARED FontData(1 TO 3, 32 TO 127) AS STRING * 54
	DIM SHARED FontWidth(1 TO 2, 32 TO 127) AS INTEGER

	DIM SHARED TempPathInternal AS STRING

FUNCTION File.Exists (TargetFile AS STRING)

	DIM FileHandle
	FileHandle = FREEFILE
	ON LOCAL ERROR RESUME NEXT
	OPEN TargetFile FOR BINARY AS #FileHandle

	IF LOF(FileHandle) = 0 THEN
		'File doesn't exist
		CLOSE #FileHandle
		KILL TargetFile
		File.Exists = False
		EXIT FUNCTION
	ELSE
		CLOSE #FileHandle
		File.Exists = True
		EXIT FUNCTION
	END IF

END FUNCTION

FUNCTION File.GetAssociation (FileType AS STRING) AS STRING

	DIM OpenWith AS STRING, FileAssociation AS FileAssociationType
	DIM FileHandle

	IF File.Exists(Sys.Path + "DATA\CONFIG\FILETYPE.DAT") THEN
		FileHandle = FREEFILE
		OPEN Sys.Path + "DATA\CONFIG\FILETYPE.DAT" FOR BINARY AS #FileHandle

		'ON LOCAL ERROR RESUME NEXT
		DO WHILE NOT EOF(FileHandle)

			GET #FileHandle, , FileAssociation
		
			IF UCASE$(FileType) = RTRIM$(FileAssociation.FileType) THEN
				OpenWith = RTRIM$(FileAssociation.Command)
				EXIT DO
			END IF

		LOOP
		CLOSE #FileHandle
		ON LOCAL ERROR GOTO 0

	END IF

	File.GetAssociation = OpenWith

END FUNCTION

FUNCTION Font.GetWidth (TargetText AS STRING, FontID AS INTEGER)

	IF TargetText = "" THEN EXIT FUNCTION
	IF FontID <> FontHeading AND FontID <> FontNormal THEN EXIT FUNCTION
																	 
	DIM TotalWidth, StrPos, Char
	IF LEN(TargetText) > 1 THEN
		FOR StrPos = 1 TO LEN(TargetText)
			Char = ASC(MID$(TargetText, StrPos, 1))
			IF Char >= 32 AND Char <= 126 THEN
				TotalWidth = TotalWidth + FontWidth(FontID, Char)
			END IF
		NEXT
	ELSE
		Char = ASC(TargetText)
		IF Char >= 32 AND Char <= 126 THEN
			TotalWidth = FontWidth(FontID, Char)
		END IF
	END IF

	'Substract 2 - because the 2 pixel spacing after the last char
	'shouldn't count
	Font.GetWidth = TotalWidth - 2

END FUNCTION

SUB Font.Print (BYVAL Text AS STRING, X, Y, Col, FontID)

	DIM Char, Ascii
	DIM ColStr AS STRING

	'Use PSET to set the drawing position
	PSET (X, Y + 11), POINT(X, Y + 11)
	DRAW "C" + LTRIM$(STR$(Col))

	Text = RTRIM$(Text)
	IF LEN(Text) = 0 OR FontID < 1 OR FontID > 3 THEN EXIT SUB

	'Print the text, char by char
	Mouse.Hide
	FOR Char = 1 TO LEN(Text)
		Ascii = ASC(MID$(Text, Char, 1))
		IF Ascii >= 32 AND Ascii <= 126 THEN
			DRAW FontData(FontID, Ascii)
		ELSE
			'An unsupported character - print a space instead
			DRAW FontData(FontID, 32)
		END IF
	NEXT
	Mouse.Show

END SUB

FUNCTION Mouse.Clicked ()
	'Purpose:
	'  Returns a value according to which mouse buttons are clicked.
	'
	'Returns:
	'          0 if no button is clicked
	'  mbLeft  1 if left button is clicked
	'  mbRight 2 if right button is clicked
	'  mbBoth  3 if both buttons are clicked

	DIM lButton, RButton, ButtonMouse
	DIM regs AS RegType

	regs.ax = 3
	INTERRUPT 51, regs, regs
	ButtonMouse = regs.bx

	Mouse.Clicked = ButtonMouse

END FUNCTION

SUB Mouse.Hide ()

	DIM regs AS RegType
	regs.ax = 2
	INTERRUPT 51, regs, regs

END SUB

FUNCTION Mouse.InArea (TargetArea AS PosType)

	'Returns True if the mouse cursor is within the area

	DIM XPos, YPos

	'Get mouse pos to variables, cuts interrupt calls in half
	XPos = Mouse.X
	YPos = Mouse.Y

	IF XPos >= TargetArea.Left AND XPos <= TargetArea.Left + TargetArea.Width THEN
		IF YPos >= TargetArea.Top AND YPos <= TargetArea.Top + TargetArea.Height THEN
			Mouse.InArea = True
		END IF
	END IF
	
END FUNCTION

SUB Mouse.SetPos (XPos, YPos)

	DIM regs AS RegType
	regs.ax = 4
	regs.cx = XPos
	regs.dx = YPos
	INTERRUPT 51, regs, regs

END SUB

SUB Mouse.Show ()

	DIM regs AS RegType
	regs.ax = 1
	INTERRUPT 51, regs, regs

END SUB

FUNCTION Mouse.X ()
	'Returns the X coordinate of the mouse.

	DIM regs AS RegType

	regs.ax = 3
	INTERRUPT 51, regs, regs
	Mouse.X = regs.cx

END FUNCTION

FUNCTION Mouse.Y ()
	'Returns the Y coordinate of the mouse.

	DIM regs AS RegType
	regs.ax = 3
	INTERRUPT 51, regs, regs
	Mouse.Y = regs.dx

END FUNCTION

FUNCTION Obj.BtnClick (TargetBtn AS ButtonType)

	DIM IsUp

	IF Mouse.Clicked = mbLeft AND Mouse.InArea(TargetBtn.Pos) THEN

		
		'Draw the button pressed
		Obj.DrawBtn TargetBtn, True

		DO
			'Draw the button pressed when the mouse is over it, and unpressed
			'when the mouse leaves it
			IF Mouse.InArea(TargetBtn.Pos) THEN
				IF IsUp = 1 THEN IsUp = 0: Obj.DrawBtn TargetBtn, True
			ELSE
				IF IsUp = 0 THEN IsUp = 1: Obj.DrawBtn TargetBtn, False
			END IF

		LOOP WHILE Mouse.Clicked

		'Make sure the button looks released
		IF IsUp = 0 THEN Obj.DrawBtn TargetBtn, False

		IF Mouse.InArea(TargetBtn.Pos) THEN
			Obj.BtnClick = True
		ELSE
			Obj.BtnClick = False
		END IF

	END IF

END FUNCTION

SUB Obj.ChkClick (TargetChk AS CheckBoxType)

	IF Mouse.Clicked = mbLeft AND Mouse.InArea(TargetChk.Pos) THEN

		DO: LOOP WHILE Mouse.Clicked

		IF Mouse.InArea(TargetChk.Pos) THEN
			
			TargetChk.Checked = NOT TargetChk.Checked
			Obj.DrawChk TargetChk

		END IF

	END IF

END SUB

SUB Obj.DrawBtn (TargetBtn AS ButtonType, Pressed AS INTEGER)

	'Store the size and position in variables for easiser handling, and
	'set the default size of the control if no size is specified
	DIM x1, x2, y1, y2
	x1 = TargetBtn.Pos.Left
	y1 = TargetBtn.Pos.Top
	IF TargetBtn.Pos.Width = 0 THEN TargetBtn.Pos.Width = 92
	IF TargetBtn.Pos.Height = 0 THEN TargetBtn.Pos.Height = 22
	x2 = TargetBtn.Pos.Left + TargetBtn.Pos.Width
	y2 = TargetBtn.Pos.Top + TargetBtn.Pos.Height
	
	'Store colors too, for easier handling
	DIM Color1, Color2, Color3, Color4
	IF Pressed = False THEN
		Color1 = 15
		Color2 = SystemTheme.Button
		Color3 = SystemTheme.Shadow
		Color4 = SystemTheme.WindowText
	ELSE
		Color1 = 0
		Color2 = SystemTheme.Shadow
		Color3 = SystemTheme.Light
		Color4 = 15
	END IF

	Mouse.Hide
	IF TargetBtn.Transparent = False THEN
		IF Color1 = SystemTheme.Window THEN
			IF SystemTheme.Window >= 8 THEN
				Color1 = SystemTheme.Window - 8
			ELSE
				Color1 = SystemTheme.Window + 8
			END IF
		END IF
		IF Color3 = SystemTheme.Window THEN
			IF SystemTheme.Window >= 8 THEN
				Color3 = SystemTheme.Window - 8
			ELSE
				Color3 = SystemTheme.Window + 8
			END IF
		END IF
		IF Color4 = Color2 THEN
			IF Color2 >= 8 THEN
				Color4 = Color2 - 8
			ELSE
				Color4 = Color2 + 8
			END IF
		END IF
		LINE (x1, y1)-(x2 - 1, y2 - 1), Color2, BF
	ELSE
		LINE (x1, y1)-(x2 - 1, y2 - 1), Color2, B
	END IF

	LINE (x1 + 1, y1 + 1)-(x2 - 2, y1 + 1), Color1
	LINE (x1 + 1, y1 + 2)-(x1 + 1, y2 - 2), Color1

	LINE (x1, y2)-(x2, y2), Color3
	LINE (x2, y1)-(x2, y2 - 1), Color3

	IF NOT RTRIM$(TargetBtn.Caption) = "" THEN
		'Draw the caption centered on the button, and underline the hotkey
		x1 = ((x2 - x1) - Font.GetWidth(RTRIM$(TargetBtn.Caption), FontHeading)) / 2 + x1
		y1 = ((y2 - y1) - 9) / 2 + y1
		IF Pressed = True THEN x1 = x1 + 1: y1 = y1 + 1
		
		Font.Print TargetBtn.Caption, x1, y1, Color4, FontHeading

		
		IF TargetBtn.HotKey > 0 AND TargetBtn.HotKey <= LEN(RTRIM$(TargetBtn.Caption)) THEN
			DIM XStart, XEnd
			XStart = x1 + Font.GetWidth(LEFT$(TargetBtn.Caption, TargetBtn.HotKey - 1), FontHeading) - 1
			XEnd = x1 + Font.GetWidth(LEFT$(TargetBtn.Caption, TargetBtn.HotKey), FontHeading) + 1
			LINE (x1 + Font.GetWidth(LEFT$(TargetBtn.Caption, TargetBtn.HotKey - 1), FontHeading) - 1, y1 + 11)-(x1 + Font.GetWidth(LEFT$(TargetBtn.Caption, TargetBtn.HotKey), FontHeading), y1 + 11), Color4
		END IF
		
	END IF

	Mouse.Show

END SUB

SUB Obj.DrawChk (TargetChk AS CheckBoxType)

	DIM x1, x2, y1, y2
	x1 = TargetChk.Pos.Left
	y1 = TargetChk.Pos.Top
	x2 = TargetChk.Pos.Left + 15
	y2 = TargetChk.Pos.Top + 15

	'Set the clickable area, in case the width and height is 0. This doesn't
	'affect the checkbox visually.
	IF TargetChk.Pos.Width = 0 THEN TargetChk.Pos.Width = 14
	IF TargetChk.Pos.Height = 0 THEN TargetChk.Pos.Height = 14

	Mouse.Hide
	LINE (x1 + 2, y1 + 2)-(x2 - 2, y2 - 2), SystemTheme.Textbox, BF

	LINE (x1 + 1, y1 + 1)-(x2, y2), 0, B
	LINE (x2 - 1, y1 + 2)-(x2 - 1, y2 - 1), 0
	LINE (x1 + 2, y2 - 1)-(x2 - 2, y2 - 1), 0
	
	LINE (x1, y1)-(x1, y2), SystemTheme.Shadow
	LINE (x1 + 1, y1)-(x2, y1), SystemTheme.Shadow

	IF TargetChk.Checked = True THEN

		LINE (x1 + 5, y1 + 8)-(x1 + 7, y1 + 10), SystemTheme.TextboxText
		LINE (x1 + 5, y1 + 9)-(x1 + 7, y1 + 11), SystemTheme.TextboxText
		LINE (x1 + 8, y1 + 9)-(x1 + 11, y1 + 6), SystemTheme.TextboxText
		LINE (x1 + 8, y1 + 10)-(x1 + 11, y1 + 7), SystemTheme.TextboxText

		LINE (x1 + 5, y1 + 7)-(x1 + 7, y1 + 9), SystemTheme.Shadow
		LINE (x1 + 8, y1 + 8)-(x1 + 11, y1 + 5), SystemTheme.Shadow

		LINE (x1 + 5, y1 + 10)-(x1 + 6, y1 + 11), SystemTheme.Light
		LINE (x1 + 8, y1 + 11)-(x1 + 11, y1 + 8), SystemTheme.Light

	END IF

	Mouse.Show

END SUB

SUB Obj.DrawFrm (TargetFrm AS FrameType, LightColor, DarkColor)
	'Tip: Set TargetFrm.Pos.Height to 1 to draw a seperating line instead of
	'     a frame

	DIM x1, x2, y1, y2
	x1 = TargetFrm.Pos.Left
	y1 = TargetFrm.Pos.Top
	x2 = TargetFrm.Pos.Left + TargetFrm.Pos.Width
	y2 = TargetFrm.Pos.Top + TargetFrm.Pos.Height

	Mouse.Hide
	LINE (x1 + 1, y1 + 1)-(x2, y2), LightColor, B
	LINE (x1, y1)-(x2 - 1, y2 - 1), DarkColor, B
	Mouse.Show

END SUB

SUB Obj.DrawImg (TargetImg AS ImageType)

	DIM X, Y, XPos, YPos
	DIM Header AS STRING * 9
	X = TargetImg.Pos.Left
	Y = TargetImg.Pos.Top

	TargetImg.Pos.Width = 31
	TargetImg.Pos.Height = 31

	IF NOT File.Exists(Sys.Path + "DATA\IMAGES\" + TargetImg.ImageFile + ".BSV") THEN
		'Draw a red box with the text "IMG ERR" to indicate a missing file
		Mouse.Hide
		LINE (X + 1, Y + 1)-(X + 30, Y + 30), 4, BF
		LINE (X, Y)-(X + 31, Y + 31), 0, B
		Mouse.Show
		Font.Print "IMG", X + 6, Y + 4, 15, FontNormal
		Font.Print "ERR", X + 6, Y + 19, 15, FontNormal
		EXIT SUB
	END IF

	DIM IconData AS IconDataType

	'Load saved memory back to address of IconData.Pixel array
	ON LOCAL ERROR GOTO DrawImgError
	DEF SEG = VARSEG(IconData.Pixel(0, 0))
	BLOAD Sys.Path + "DATA\IMAGES\" + TargetImg.ImageFile + ".BSV", VARPTR(IconData.Pixel(0, 0))
	DEF SEG
	
	Mouse.Hide
	FOR XPos = 0 TO 31
		FOR YPos = 0 TO 31
			IF IconData.Pixel(XPos, YPos) > -1 THEN PSET (X + XPos, Y + YPos), IconData.Pixel(XPos, YPos)
		NEXT
	NEXT
	Mouse.Show
	EXIT SUB

DrawImgError:
	'Draw a red box with the text "IMG ERR" to indicate a missing file
	Mouse.Hide
	LINE (X + 1, Y + 1)-(X + 30, Y + 30), 4, BF
	LINE (X, Y)-(X + 31, Y + 31), 0, B
	Mouse.Show
	Font.Print "IMG", X + 6, Y + 4, 15, FontNormal
	Font.Print "ERR", X + 6, Y + 19, 15, FontNormal
	EXIT SUB
	RESUME NEXT
END SUB

SUB Obj.DrawTxt (TargetTxt AS TextboxType, BYVAL Text AS STRING, IsEditing AS INTEGER)

	DIM x1, x2, y1, y2, MaxShow
	
	x1 = TargetTxt.Pos.Left
	y1 = TargetTxt.Pos.Top
	IF TargetTxt.Pos.Top = 0 THEN TargetTxt.Pos.Top = 120
	IF TargetTxt.Pos.Height = 0 THEN TargetTxt.Pos.Height = 19
	x2 = TargetTxt.Pos.Left + TargetTxt.Pos.Width
	y2 = TargetTxt.Pos.Top + TargetTxt.Pos.Height

	Mouse.Hide
	LINE (x1 + 2, y1 + 2)-(x2 - 2, y2 - 2), SystemTheme.Textbox, BF

	LINE (x1, y1)-(x2 - 1, y2 - 1), SystemTheme.Light, B
	LINE (x1 + 1, y1 + 1)-(x2, y2), SystemTheme.Shadow, B


	Mouse.Show

	IF NOT Text = "" THEN
		'Only print the text that fits in the textbox

		MaxShow = (TargetTxt.Pos.Width - 10)
		
		DO UNTIL Font.GetWidth(Text, FontHeading) < MaxShow
			Text = RIGHT$(Text, LEN(Text) - 1)
		LOOP
		
		Font.Print Text, x1 + 5, y1 + 5, SystemTheme.TextboxText, FontHeading
	END IF

	IF IsEditing = True THEN
		Mouse.Hide
		x1 = x1 + 7 + Font.GetWidth(Text, FontHeading)
		LINE (x1, y1 + 4)-(x1, y1 + 15), SystemTheme.TextboxText
		Mouse.Show
	END IF

END SUB

SUB Obj.DrawWin (TargetWin AS WindowType)
	DIM x1, x2, y1, y2
	x1 = TargetWin.Pos.Left
	y1 = TargetWin.Pos.Top
	x2 = TargetWin.Pos.Left + TargetWin.Pos.Width
	y2 = TargetWin.Pos.Top + TargetWin.Pos.Height

	Mouse.Hide

	'Window titlebar and borders
	LINE (x1 + 2, y1 + 2)-(x2 - 2, y2 - 1), SystemTheme.TitleBar, BF
	
	'Outer border
	LINE (x1, y1)-(x2 - 1, y1), 15
	LINE (x1, y1 + 1)-(x1, y2 - 1), 15
	LINE (x2, y1)-(x2, y2), 0
	LINE (x1, y2)-(x2 - 1, y2), 0
	LINE (x2 - 1, y1 + 1)-(x2 - 1, y2 - 1), SystemTheme.Shadow
	LINE (x1 + 1, y2 - 1)-(x2 - 2, y2 - 1), SystemTheme.Shadow
	LINE (x1 + 1, y1 + 1)-(x2 - 2, y1 + 1), SystemTheme.Light
	LINE (x1 + 1, y1 + 2)-(x1 + 1, y2 - 2), SystemTheme.Light

	'Inner border
	LINE (x1 + 5, y1 + 23)-(x2 - 5, y2 - 5), SystemTheme.Shadow, B
	LINE (x1 + 6, y1 + 24)-(x2 - 6, y2 - 6), SystemTheme.Light, B

	'Titlebar
	LINE (x1 + 7, y1 + 25)-(x2 - 7, y2 - 7), SystemTheme.Window, BF

	IF NOT RTRIM$(TargetWin.Caption) = "" THEN
		'Draw caption centered on titlebar
		x1 = ((x2 - x1) - Font.GetWidth(RTRIM$(TargetWin.Caption), FontHeading)) / 2 + x1
		Font.Print TargetWin.Caption, x1, y1 + 9, SystemTheme.TitleBarText, FontHeading
	END IF

	Mouse.Show

END SUB

SUB Obj.EditTxt (TargetTxt AS TextboxType, Text AS STRING)

	DIM OrigTxt AS STRING, TempTxt AS STRING, Key$
	DIM x1, y1, LineX1, MaxLen, MaxShow

	x1 = TargetTxt.Pos.Left + 5
	y1 = TargetTxt.Pos.Top + 5

	'MaxLen is the maximum number of chars that can be entered
	MaxLen = TargetTxt.MaxLen
	IF MaxLen = 0 THEN MaxLen = 256

	'MaxShow is the maximum number of chars that will fit into the textbox
	MaxShow = TargetTxt.Pos.Width - 10
	
	OrigTxt = Text 'Stores the original text, in case the user presses ESC
	TempTxt = Text 'The string var used for editing

	'Clear keyboard buffer
	DO: LOOP WHILE LEN(INKEY$)

	IF Font.GetWidth(TempTxt + Key$, FontHeading) + 2 < MaxShow THEN
		LineX1 = x1 + Font.GetWidth(Text, FontHeading) + 2
		Mouse.Hide
		LINE (LineX1, y1 - 1)-(LineX1, y1 + 10), SystemTheme.TextboxText
		Mouse.Show
	ELSE
		Obj.DrawTxt TargetTxt, TempTxt, True
	END IF

	DO
		Key$ = INKEY$

		IF Mouse.Clicked AND Mouse.InArea(TargetTxt.Pos) = False THEN Key$ = CHR$(13)

		IF LEN(Key$) = 1 THEN
			SELECT CASE ASC(Key$)
				CASE 8 'Backspace
					IF LEN(TempTxt) > 0 THEN

						IF Font.GetWidth(TempTxt, FontHeading) + 2 < MaxShow THEN
							'Erase only the last char
							LineX1 = x1 + Font.GetWidth(TempTxt, FontHeading)
							Mouse.Hide
							LINE (LineX1 + 2, y1 - 2)-(LineX1 - Font.GetWidth(RIGHT$(TempTxt, 1), FontHeading), y1 + 11), SystemTheme.Textbox, BF
							Mouse.Show
							TempTxt = LEFT$(TempTxt, LEN(TempTxt) - 1)
							LineX1 = x1 + Font.GetWidth(TempTxt, FontHeading) + 2
							Mouse.Hide
							LINE (LineX1, y1 - 1)-(LineX1, y1 + 10), SystemTheme.TextboxText
							Mouse.Show
						ELSE
							'There's more text that's not shown, so we'll
							'have to redraw the entire textbox
							TempTxt = LEFT$(TempTxt, LEN(TempTxt) - 1)
							Obj.DrawTxt TargetTxt, TempTxt, True
						END IF

					END IF

				CASE 13 'Enter
					Text = TempTxt
					LineX1 = x1 + Font.GetWidth(Text, FontHeading) + 2
					Mouse.Hide
					LINE (LineX1, y1 - 1)-(LineX1, y1 + 10), SystemTheme.Textbox
					Mouse.Show
					EXIT SUB

				CASE 32 TO 126 'Any printable character
					IF NOT LEN(TempTxt) = MaxLen THEN
						IF Font.GetWidth(TempTxt + Key$, FontHeading) + 2 < MaxShow THEN
							LineX1 = x1 + Font.GetWidth(TempTxt, FontHeading) + 2
							Mouse.Hide
							LINE (LineX1, y1 - 1)-(LineX1, y1 + 10), SystemTheme.Textbox
							Mouse.Show
							TempTxt = TempTxt + Key$
							Font.Print TempTxt, x1, y1, SystemTheme.TextboxText, FontHeading
							LineX1 = x1 + Font.GetWidth(TempTxt, FontHeading) + 2
							Mouse.Hide
							LINE (LineX1, y1 - 1)-(LineX1, y1 + 10), SystemTheme.TextboxText
							Mouse.Show
						ELSE
							TempTxt = TempTxt + Key$
							Obj.DrawTxt TargetTxt, TempTxt, True
						END IF
					END IF

				CASE 27 'Escape
					Text = OrigTxt
					Obj.DrawTxt TargetTxt, Text, False
					EXIT SUB

			END SELECT
		END IF

		 
	LOOP
	
END SUB

SUB Obj.SetSize (TargetArea AS PosType, TargetLeft, TargetTop, TargetWidth, TargetHeight)

	IF NOT TargetLeft = -1 THEN TargetArea.Left = TargetLeft
	IF NOT TargetTop = -1 THEN TargetArea.Top = TargetTop
	IF NOT TargetWidth = -1 THEN TargetArea.Width = TargetWidth
	IF NOT TargetHeight = -1 THEN TargetArea.Height = TargetHeight

END SUB

FUNCTION Obj.TxtClick (TargetTxt AS TextboxType)

	IF Mouse.Clicked = mbLeft AND Mouse.InArea(TargetTxt.Pos) THEN
		
		DO: LOOP WHILE Mouse.Clicked

		IF Mouse.InArea(TargetTxt.Pos) THEN
			Obj.TxtClick = True
		ELSE
			Obj.TxtClick = False
		END IF

	END IF

END FUNCTION

DEFSNG A-Z
SUB Sys.Delay (Seconds AS SINGLE)

	DIM StartTime AS SINGLE, EndTime AS SINGLE
	StartTime = TIMER
	EndTime = StartTime + Seconds

	'Wait until the time has ellapsed. TIMER < StartTime is used to make
	'sure it works across midnight, where the time will less than StartTime.
	DO
	LOOP UNTIL TIMER > EndTime OR TIMER < StartTime
	
END SUB

DEFINT A-Z
FUNCTION Sys.InputBox (msgTitle AS STRING, BYVAL msgText AS STRING, msgIcon AS STRING, msgDefault AS STRING) AS STRING

	DIM msgLines() AS STRING, msgLineCount, msgTextWidth

	IF RIGHT$(msgText, 1) = CHR$(13) THEN msgText = LEFT$(msgText, LEN(msgText) - 1)
	IF INSTR(msgText, CHR$(13)) = 0 THEN
		msgLineCount = 1
		REDIM PRESERVE msgLines(1 TO 1) AS STRING
		msgLines(1) = msgText
		msgTextWidth = Font.GetWidth(msgText, FontNormal)
	ELSE
		DO WHILE INSTR(msgText, CHR$(13))
			msgLineCount = msgLineCount + 1
			REDIM PRESERVE msgLines(1 TO msgLineCount) AS STRING
			msgLines(msgLineCount) = LEFT$(msgText, INSTR(msgText, CHR$(13)) - 1)

			IF Font.GetWidth(msgLines(msgLineCount), FontNormal) > msgTextWidth THEN msgTextWidth = Font.GetWidth(msgLines(msgLineCount), FontNormal)

			msgText = RIGHT$(msgText, LEN(msgText) - INSTR(msgText, CHR$(13)))
		LOOP

		'Get the rest of the text into the array
		msgLineCount = msgLineCount + 1
		REDIM PRESERVE msgLines(1 TO msgLineCount) AS STRING
		msgLines(msgLineCount) = msgText
		IF Font.GetWidth(msgLines(msgLineCount), FontNormal) > msgTextWidth THEN msgTextWidth = Font.GetWidth(msgLines(msgLineCount), FontNormal)
	END IF


	DIM winInputBox AS WindowType
	winInputBox.Pos.Width = msgTextWidth + 76
	IF winInputBox.Pos.Width < 194 THEN winInputBox.Pos.Width = 194
	winInputBox.Pos.Height = msgLineCount * 15 + 138
	winInputBox.Pos.Left = (640 - winInputBox.Pos.Width) / 2
	winInputBox.Pos.Top = (scrHeight - winInputBox.Pos.Height) / 2
	winInputBox.Caption = "Input required"

	DIM txtInput AS TextboxType, txtInputText AS STRING
	Obj.SetSize txtInput.Pos, winInputBox.Pos.Left + 12, winInputBox.Pos.Top + 74 + (15 * msgLineCount), winInputBox.Pos.Width - 24, -1
	txtInputText = msgDefault

	DIM btnOK AS ButtonType
	Obj.SetSize btnOK.Pos, winInputBox.Pos.Left + winInputBox.Pos.Width - 182, txtInput.Pos.Top + 30, 80, 22
	btnOK.Caption = "OK": btnOK.HotKey = 1
	
	DIM btnCancel AS ButtonType
	Obj.SetSize btnCancel.Pos, winInputBox.Pos.Left + winInputBox.Pos.Width - 92, btnOK.Pos.Top, 80, 22
	btnCancel.Caption = "Cancel": btnCancel.HotKey = 1

	DIM imgIcon AS ImageType
	IF LEN(msgIcon) THEN
		imgIcon.Pos.Left = winInputBox.Pos.Left + 12
		imgIcon.Pos.Top = winInputBox.Pos.Top + 33
		imgIcon.ImageFile = msgIcon
		IF msgLineCount > 1 THEN imgIcon.Pos.Top = imgIcon.Pos.Top + 5
	END IF

	IF UserSettings.ScreenMode = scrEGA THEN
		Mouse.Hide
		PCOPY 0, 1
		Mouse.Show
	ELSE
		Sys.VGASave "INPUTBOX"
	END IF

	IF UserSettings.GreyoutOnMsgBox THEN
		DIM LX, LY
		LY = 0
		Mouse.Hide
		FOR LX = 0 TO 639
			LINE (LX, LY)-(LX, scrHeight - 1), SystemTheme.Shadow, , &HAAAA
			IF LY = 0 THEN
				LY = 1
			ELSE
				LY = 0
			END IF
		NEXT
		Mouse.Show
	END IF

	Obj.DrawWin winInputBox
	Obj.DrawBtn btnOK, False
	Obj.DrawBtn btnCancel, False
	Obj.DrawTxt txtInput, txtInputText, False

	IF LEN(msgIcon) THEN
		Font.Print msgTitle, winInputBox.Pos.Left + 53, winInputBox.Pos.Top + 33, SystemTheme.WindowText, 1
	ELSE
		Font.Print msgTitle, winInputBox.Pos.Left + 12, winInputBox.Pos.Top + 33, SystemTheme.WindowText, 1
	END IF

	DIM PrintLine
	FOR PrintLine = 1 TO msgLineCount
		IF PrintLine < 3 AND LEN(msgIcon) THEN
			Font.Print msgLines(PrintLine), winInputBox.Pos.Left + 53, winInputBox.Pos.Top + 35 + (15 * PrintLine), SystemTheme.WindowText, 2
		ELSE
			Font.Print msgLines(PrintLine), winInputBox.Pos.Left + 12, winInputBox.Pos.Top + 35 + (15 * PrintLine), SystemTheme.WindowText, 2
		END IF
	NEXT

	Font.Print "Input:", txtInput.Pos.Left, txtInput.Pos.Top - 16, SystemTheme.WindowText, FontHeading
	LINE (txtInput.Pos.Left + 5, txtInput.Pos.Top - 6)-(txtInput.Pos.Left + 12, txtInput.Pos.Top - 6), SystemTheme.WindowText

	IF LEN(msgIcon) THEN Obj.DrawImg imgIcon

	DIM Key$
	DO

		Key$ = LCASE$(INKEY$)

		IF Obj.BtnClick(btnOK) OR Key$ = "o" OR Key$ = CHR$(13) THEN
			Sys.InputBox = txtInputText
			EXIT DO
		END IF

		IF Obj.BtnClick(btnCancel) OR Key$ = "c" OR Key$ = CHR$(27) THEN
			Sys.InputBox = ""
			EXIT DO
		END IF
		
		IF Obj.TxtClick(txtInput) OR Key$ = "n" THEN Obj.EditTxt txtInput, txtInputText

	LOOP

	IF UserSettings.ScreenMode = scrEGA THEN
		Mouse.Hide
		PCOPY 1, 0
		Mouse.Show
	ELSE
		Sys.VGALoad "INPUTBOX"
	END IF


END FUNCTION

SUB Sys.Load ()

	DIM DontDrawDesktop

	'If the parameters /VER or /? are used, just show version info and exit
		IF INSTR(COMMAND$, "/VER") OR INSTR(COMMAND$, "/?") THEN
			PRINT
			PRINT appName
			PRINT "Made in 2004-" + appYear + " by Jacob Palm, released under the MIT license."
			PRINT
			PRINT "Version " + appVersion
			PRINT
			END
		END IF

	'Make sure Costa is running, by checking if RUNSTAT.TMP created by the
	'/BOOT parameter exists
		IF File.Exists(Temp.Path + "RUNSTAT.TMP") = False THEN
			IF INSTR(COMMAND$, "/DEV") = 0 THEN
				CLS
				PRINT "This program is a part of " + appName + " and should not be executed"
				PRINT "directly from the command prompt."
				PRINT
				PRINT "To start Costa, run COSTA.BAT. If that file doesn't exist, run SETUP.EXE."
				PRINT
				END
			END IF
		END IF
	
	'Load profile
		IF File.Exists(Temp.Path + "PROFILE.TMP") THEN
			DIM ProfileFileHandle
			ProfileFileHandle = FREEFILE
			OPEN Temp.Path + "PROFILE.TMP" FOR INPUT AS #ProfileFileHandle
			IF LOF(ProfileFileHandle) > 0 THEN INPUT #ProfileFileHandle, ProfileID
			CLOSE #ProfileFileHandle
		END IF

		'When running with /DEV parameter, always use profile 1 if none is
		'specified. Otherwise, config files from accessories will end up in the
		'wrong path
		IF (ProfileID < 1 OR ProfileID > 5) AND INSTR(COMMAND$, "/DEV") THEN
			ProfileID = 1
		END IF
		

	'Prepare fonts for use
		DIM FontErr
		IF NOT File.Exists(Sys.Path + "DATA\FONTDATA.BSV") THEN FontErr = True
		IF NOT File.Exists(Sys.Path + "DATA\FONTINFO.BSV") THEN FontErr = True
		
		IF FontErr THEN
			CLS
			PRINT "One or more font files were not found."
			PRINT "Make sure the font files are in " + Sys.Path + "DATA\FONTS."
			PRINT
			PRINT "Press any key to exit."
			DO: LOOP WHILE INKEY$ = ""
			END 1
		END IF

		DEF SEG = VARSEG(FontData(1, 32))
		'BSAVE Sys.Path + "DATA\FONTDATA.BSV", VARPTR(FontData(1, 32)), 15552
		BLOAD Sys.Path + "DATA\FONTDATA.BSV", VARPTR(FontData(1, 32))
		DEF SEG

		DEF SEG = VARSEG(FontWidth(1, 32))
		'BSAVE Sys.Path + "DATA\FONTINFO.BSV", VARPTR(FontWidth(1, 32)), 384
		BLOAD Sys.Path + "DATA\FONTINFO.BSV", VARPTR(FontWidth(1, 32))
		DEF SEG

		
	'Load settings
		Sys.LoadSettings
		
	'Load user profile - if profile has not yet been selected, load default
		IF ProfileID THEN
			Sys.LoadProfile ProfileID
		ELSE
			DontDrawDesktop = True 'If no profile loaded, don't draw desktop as
														 'that will cause flicker once theme is loaded
														 'and proper desktop color is drawn
			Sys.LoadProfile 0
		END IF

	'Load colors for the interface
		Sys.LoadTheme
	
	'Clear the keyboard buffer, DOSBox has some issues with leaving keys in it
		DO: LOOP WHILE LEN(INKEY$)
			

	'VGA 640x480, 16 colors
		IF UserSettings.ScreenMode = scrVGA THEN
			scrHeight = 480
			SCREEN 12
		ELSE
			scrHeight = 350
			SCREEN 9
		END IF

		IF NOT DontDrawDesktop THEN
			Mouse.Hide
			LINE (0, 0)-(639, scrHeight - 1), SystemTheme.Desktop, BF
			Mouse.Show
		END IF

	'Set the right colors for the palette
		OUT &H3C8, 6
		OUT &H3C9, 31
		OUT &H3C9, 31
		OUT &H3C9, 0

		OUT &H3C8, 10
		OUT &H3C9, 0
		OUT &H3C9, 255
		OUT &H3C9, 0

		OUT &H3C8, 12
		OUT &H3C9, 255
		OUT &H3C9, 0
		OUT &H3C9, 0

		OUT &H3C8, 14
		OUT &H3C9, 63
		OUT &H3C9, 63
		OUT &H3C9, 0

	Mouse.Show

END SUB

SUB Sys.LoadProfile (ProfileNum)

	DIM FileHandle

	IF ProfileNum > 0 AND ProfileNum < 6 THEN

		IF File.Exists(Sys.Path + "\DATA\CONFIG\PROFILE" + LTRIM$(STR$(ProfileNum)) + ".DAT") THEN
			FileHandle = FREEFILE
			ON LOCAL ERROR GOTO LoadDefaultProfile
			OPEN Sys.Path + "\DATA\CONFIG\PROFILE" + LTRIM$(STR$(ProfileNum)) + ".DAT" FOR BINARY AS #FileHandle
			GET #FileHandle, , UserSettings
			CLOSE #FileHandle
		ELSE
			GOTO LoadDefaultProfile
		END IF

	ELSE
		GOTO LoadDefaultProfile
	END IF

	IF RTRIM$(UserSettings.ProfileName) = "" THEN UserSettings.ProfileName = "Profile" + STR$(ProfileNum)
	IF RTRIM$(UserSettings.ProfileImage) = "" THEN UserSettings.ProfileImage = "USERS"
	IF RTRIM$(UserSettings.ThemeFile) = "" THEN UserSettings.ThemeFile = "DEFAULT"
	IF NOT UserSettings.ScreenMode = scrVGA AND NOT UserSettings.ScreenMode = scrEGA THEN UserSettings.ScreenMode = scrEGA

	EXIT SUB

LoadDefaultProfile:
	UserSettings.ProfileName = "Profile" + STR$(ProfileNum)
	UserSettings.ProfileImage = "USERS"
	UserSettings.ThemeFile = "DEFAULT"
	UserSettings.Animations = True
	UserSettings.ShowLinkDescriptions = True
	UserSettings.ShowLinkTargetFiles = True
	UserSettings.ScreenMode = scrEGA
	UserSettings.ConfirmLinkDelete = True
	UserSettings.ConfirmExit = True
	UserSettings.TipOfTheDay = True
	UserSettings.TipLastShown = 0
	UserSettings.AssignFileTypes = True
	UserSettings.GreyoutOnMsgBox = False
END SUB

SUB Sys.LoadSettings ()

	DIM FileHandle

	ON LOCAL ERROR GOTO LoadDefaultSettings
	FileHandle = FREEFILE
	OPEN Sys.Path + "\DATA\CONFIG\COSTA.DAT" FOR BINARY AS #FileHandle
	GET #FileHandle, , SystemSettings
	CLOSE #FileHandle

	EXIT SUB

LoadDefaultSettings:
	SystemSettings.LastUsedProfile = 0
	SystemSettings.UseLastProfile = True

END SUB

SUB Sys.LoadTheme ()

	DIM ThemeFile AS STRING
	ThemeFile = RTRIM$(UserSettings.ThemeFile)

	DIM FileHandle
	FileHandle = FREEFILE

	IF File.Exists(Sys.Path + "\DATA\THEMES\" + ThemeFile + ".DAT") THEN
		OPEN Sys.Path + "\DATA\THEMES\" + ThemeFile + ".DAT" FOR BINARY AS #FileHandle
		GET #FileHandle, , SystemTheme
		CLOSE #FileHandle
	ELSE
		SystemTheme.Desktop = 7
		SystemTheme.DesktopText = 0
		SystemTheme.Window = 15
		SystemTheme.Button = 7
		SystemTheme.Textbox = 15
		SystemTheme.TextboxText = 0
		SystemTheme.WindowText = 0
		SystemTheme.TitleBar = 3
		SystemTheme.TitleBarText = 0
		SystemTheme.Light = 7
		SystemTheme.Shadow = 8
		SystemTheme.Select = 8
		SystemTheme.SelectText = 15
	END IF

END SUB

FUNCTION Sys.MsgBox (msgTitle AS STRING, BYVAL msgText AS STRING, msgType)

	DIM msgLines() AS STRING, msgLineCount, msgTextWidth
	DIM btnFirst AS ButtonType, btnSecond AS ButtonType
	DIM imgIcon AS ImageType
	DIM winMsgBox AS WindowType
	
	IF RIGHT$(msgText, 1) = CHR$(13) THEN msgText = LEFT$(msgText, LEN(msgText) - 1)
	IF INSTR(msgText, CHR$(13)) = 0 THEN
		msgLineCount = 1
		REDIM PRESERVE msgLines(1 TO 1) AS STRING
		msgLines(1) = msgText
		msgTextWidth = Font.GetWidth(msgText, FontNormal)
	ELSE
		DO WHILE INSTR(msgText, CHR$(13))
			msgLineCount = msgLineCount + 1
			REDIM PRESERVE msgLines(1 TO msgLineCount) AS STRING
			msgLines(msgLineCount) = LEFT$(msgText, INSTR(msgText, CHR$(13)) - 1)

			IF Font.GetWidth(msgLines(msgLineCount), FontNormal) > msgTextWidth THEN msgTextWidth = Font.GetWidth(msgLines(msgLineCount), FontNormal)
			
			msgText = RIGHT$(msgText, LEN(msgText) - INSTR(msgText, CHR$(13)))
		LOOP

		'Get the rest of the text into the array
		msgLineCount = msgLineCount + 1
		REDIM PRESERVE msgLines(1 TO msgLineCount) AS STRING
		msgLines(msgLineCount) = msgText
		IF Font.GetWidth(msgLines(msgLineCount), FontNormal) > msgTextWidth THEN msgTextWidth = Font.GetWidth(msgLines(msgLineCount), FontNormal)
	END IF

	winMsgBox.Pos.Width = msgTextWidth + 68
	IF msgType = msgQuest THEN
		IF winMsgBox.Pos.Width < 194 THEN winMsgBox.Pos.Width = 194
	ELSE
		IF winMsgBox.Pos.Width < 102 THEN winMsgBox.Pos.Width = 102
	END IF
	winMsgBox.Pos.Height = msgLineCount * 15 + 96
	winMsgBox.Pos.Left = (640 - winMsgBox.Pos.Width) / 2
	winMsgBox.Pos.Top = (scrHeight - winMsgBox.Pos.Height) / 2
	IF msgType = msgInfo THEN winMsgBox.Caption = "Information"
	IF msgType = msgWarn THEN winMsgBox.Caption = "Warning"
	IF msgType = msgQuest THEN winMsgBox.Caption = "Question"
	IF msgType = msgError THEN winMsgBox.Caption = "Error"
	IF msgType = msgTip THEN winMsgBox.Caption = "Tip of the Day"

	Obj.SetSize imgIcon.Pos, winMsgBox.Pos.Left + 13, winMsgBox.Pos.Top + 33, -1, -1
	IF msgType = msgInfo THEN imgIcon.ImageFile = "MSGINFO"
	IF msgType = msgWarn THEN imgIcon.ImageFile = "MSGWARN"
	IF msgType = msgQuest THEN imgIcon.ImageFile = "MSGQUEST"
	IF msgType = msgError THEN imgIcon.ImageFile = "MSGERROR"
	IF msgType = msgTip THEN imgIcon.ImageFile = "TIPBULB"

	Obj.SetSize btnFirst.Pos, -1, winMsgBox.Pos.Top + 60 + (15 * msgLineCount), 80, 22
	btnFirst.HotKey = 1
	IF msgType = msgQuest THEN
		btnFirst.Caption = "Yes"
		btnFirst.Pos.Left = 320 - 86
	ELSEIF msgType = msgTip THEN
		btnFirst.Caption = "Continue"
		btnFirst.Pos.Left = (640 - btnFirst.Pos.Width) / 2
	ELSE
		btnFirst.Caption = "OK"
		btnFirst.Pos.Left = (640 - btnFirst.Pos.Width) / 2
	END IF
	
	Obj.SetSize btnSecond.Pos, 326, btnFirst.Pos.Top, 80, 22
	btnSecond.Caption = "No": btnSecond.HotKey = 1
	
	IF UserSettings.ScreenMode = scrEGA THEN
		Mouse.Hide
		PCOPY 0, 1
		Mouse.Show
	ELSE
		Sys.VGASave "MSGBOX"
	END IF

	IF UserSettings.GreyoutOnMsgBox THEN
		DIM LX, LY
		LY = 0
		Mouse.Hide
		FOR LX = 0 TO 639
			LINE (LX, LY)-(LX, scrHeight - 1), SystemTheme.Shadow, , &HAAAA
			IF LY = 0 THEN
				LY = 1
			ELSE
				LY = 0
			END IF
		NEXT
		Mouse.Show
	END IF

	Obj.DrawWin winMsgBox
	Obj.DrawBtn btnFirst, False
	IF msgType = msgQuest THEN Obj.DrawBtn btnSecond, False

	Font.Print msgTitle, winMsgBox.Pos.Left + 56, winMsgBox.Pos.Top + 33, SystemTheme.WindowText, 1
	
	DIM PrintLine
	FOR PrintLine = 1 TO msgLineCount
		Font.Print msgLines(PrintLine), winMsgBox.Pos.Left + 56, winMsgBox.Pos.Top + 35 + (15 * PrintLine), SystemTheme.WindowText, 2
	NEXT
	
	Obj.DrawImg imgIcon

	DIM Key$
	DO

		Key$ = LCASE$(INKEY$)
		
		IF Obj.BtnClick(btnFirst) THEN Key$ = CHR$(13)
		IF msgType = msgQuest THEN
			IF Obj.BtnClick(btnSecond) THEN Key$ = CHR$(27)
		END IF

		IF LEN(Key$) THEN
			IF msgType = msgQuest THEN
				IF Key$ = "y" OR Key$ = CHR$(13) THEN
					Sys.MsgBox = True
					EXIT DO
				ELSEIF Key$ = "n" OR Key$ = CHR$(27) THEN
					Sys.MsgBox = False
					EXIT DO
				END IF
			ELSEIF msgType = msgTip THEN
				IF Key$ = CHR$(13) OR Key$ = CHR$(27) OR Key$ = CHR$(32) OR Key$ = "c" THEN
					Sys.MsgBox = True
					EXIT DO
				END IF
			ELSE
				IF Key$ = CHR$(13) OR Key$ = CHR$(27) OR Key$ = CHR$(32) OR Key$ = "o" THEN
					Sys.MsgBox = True
					EXIT DO
				END IF
			END IF
		END IF
	
	LOOP

	IF UserSettings.ScreenMode = scrEGA THEN
		Mouse.Hide
		PCOPY 1, 0
		Mouse.Show
	ELSE
		Sys.VGALoad "MSGBOX"
	END IF

END FUNCTION

SUB Sys.SaveProfile (ProfileNum)

	DIM FileHandle

	ON LOCAL ERROR GOTO SaveProfileError
	FileHandle = FREEFILE
	OPEN Sys.Path + "\DATA\CONFIG\PROFILE" + LTRIM$(STR$(ProfileNum)) + ".DAT" FOR BINARY AS #FileHandle
	PUT #FileHandle, , UserSettings
	CLOSE #FileHandle

	EXIT SUB

SaveProfileError:
	FileHandle = Sys.MsgBox("Could not save settings", "An error occured while saving your settings, and they were not saved." + CHR$(13) + "Make sure the disk is not full or write-protected, and try again.", msgError)
	EXIT SUB
	RESUME NEXT
END SUB

SUB Sys.SaveSettings ()

	ON LOCAL ERROR GOTO SaveSettingsError
	DIM FileHandle
	FileHandle = FREEFILE
	OPEN Sys.Path + "\DATA\CONFIG\COSTA.DAT" FOR BINARY AS #FileHandle
	PUT #FileHandle, , SystemSettings
	CLOSE #FileHandle
	EXIT SUB

SaveSettingsError:
	FileHandle = Sys.MsgBox("Could not save settings", "An error occured while saving your settings, and they were not saved." + CHR$(13) + "Make sure the disk is not full or write-protected, and try again.", msgError)
	EXIT SUB
	RESUME NEXT
END SUB

SUB Sys.ShowLoading ()

		DIM btnLoading AS ButtonType
		btnLoading.Pos.Width = 110
		btnLoading.Pos.Height = 34
		btnLoading.Pos.Left = 265
		btnLoading.Pos.Top = (scrHeight - btnLoading.Pos.Height) / 2
		btnLoading.Caption = "Loading..."
		Obj.DrawBtn btnLoading, False

END SUB

STATIC SUB Sys.VGALoad (TargetFile AS STRING)
	'BLOADs a VGA screen saved by Sys.VGASave
	
	IF File.Exists(Temp.Path + TargetFile + ".BLU") = False THEN EXIT SUB
	IF File.Exists(Temp.Path + TargetFile + ".GRN") = False THEN EXIT SUB
	IF File.Exists(Temp.Path + TargetFile + ".RED") = False THEN EXIT SUB
	IF File.Exists(Temp.Path + TargetFile + ".INT") = False THEN EXIT SUB

	Mouse.Hide

	DEF SEG = &HA000

	OUT &H3C4, 2: OUT &H3C5, 1
	BLOAD Temp.Path + TargetFile + ".BLU", 0

	OUT &H3C4, 2: OUT &H3C5, 2
	BLOAD Temp.Path + TargetFile + ".GRN", 0

	OUT &H3C4, 2: OUT &H3C5, 4
	BLOAD Temp.Path + TargetFile + ".RED", 0

	OUT &H3C4, 2: OUT &H3C5, 8
	BLOAD Temp.Path + TargetFile + ".INT", 0

	OUT &H3C4, 2: OUT &H3C5, 15

	Mouse.Show
	
END SUB

STATIC SUB Sys.VGASave (TargetFile AS STRING)
	'Save a screenshot of SCREEN 12 in 4 parts in 4 files, which can be
	'loaded again using Sys.VGALoad

	DIM Size&

	Mouse.Hide

	DEF SEG = &HA000
	Size& = 38400

	OUT &H3CE, 4: OUT &H3CF, 0
	BSAVE Temp.Path + TargetFile + ".BLU", 0, Size&

	OUT &H3CE, 4: OUT &H3CF, 1
	BSAVE Temp.Path + TargetFile + ".GRN", 0, Size&

	OUT &H3CE, 4: OUT &H3CF, 2
	BSAVE Temp.Path + TargetFile + ".RED", 0, Size&

	OUT &H3CE, 4: OUT &H3CF, 3
	BSAVE Temp.Path + TargetFile + ".INT", 0, Size&

	OUT &H3CE, 4: OUT &H3CF, 0

	Mouse.Show

END SUB

FUNCTION Temp.Path () AS STRING

	IF NOT LEN(TempPathInternal) THEN

		TempPathInternal = environ$("TEMP")
		If TempPathInternal = "" Then
			TempPathInternal = Sys.Path + "DATA\TEMP\"
		ELSE
			if not right$(TempPathInternal, 1) = "\" then TempPathInternal = TempPathInternal + "\"
		END IF

	END IF

	Temp.Path = TempPathInternal
	
END FUNCTION

