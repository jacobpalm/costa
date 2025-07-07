OPTION EXPLICIT
DEFINT A-Z

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'
'$INCLUDE: 'C:\VBDOS\VBDOS.BI'

'This is dimmed here, and not in LIBRARY.BI, because only this module uses
'it
TYPE IconDataType
	Pixel(31, 31) AS INTEGER
END TYPE

DIM SHARED FontData(1 TO 2, 32 TO 127) AS STRING * 54
DIM SHARED FontWidth(1 TO 2, 32 TO 127) AS INTEGER

DIM SHARED MouseHidden AS INTEGER

FUNCTION File.Exists (TargetFile AS STRING)

	DIM InRegsX AS RegTypeX, OutRegsX AS RegTypeX
	DIM DTAfile AS DTAtype
	DIM ASCIIZ AS STRING * 260
	DIM Current.DTA.SEG AS INTEGER, Current.DTA.OFF AS INTEGER
	
	ASCIIZ = TargetFile + CHR$(0)

	'Retrieve current DTA, so it can be reset later
	InRegsX.ax = &H2F00
	CALL INTERRUPTX(&H21, InRegsX, OutRegsX)
	Current.DTA.SEG = OutRegsX.es
	Current.DTA.OFF = OutRegsX.bx

	'Store function DTA
	InRegsX.ax = &H1A00
	InRegsX.ds = VARSEG(DTAfile)
	InRegsX.dx = VARPTR(DTAfile)
	CALL INTERRUPTX(&H21, InRegsX, OutRegsX)

	'Find first file
	InRegsX.ax = &H4E00
	InRegsX.cx = &H37
	InRegsX.ds = VARSEG(ASCIIZ)
	InRegsX.dx = VARPTR(ASCIIZ)
	CALL INTERRUPTX(&H21, InRegsX, OutRegsX)

	IF (OutRegsX.flags AND &H1) = &H0 THEN
		File.Exists = True
	ELSE
		File.Exists = False
	END IF
	
	'Restore previous DTA
	InRegsX.ax = &H1A00
	InRegsX.ds = Current.DTA.SEG
	InRegsX.dx = Current.DTA.OFF
	CALL INTERRUPTX(&H21, InRegsX, OutRegsX)
	
END FUNCTION

FUNCTION File.GetAssociation (FileType AS STRING) AS STRING

	DIM OpenWith AS STRING, AssociationFile AS STRING
	DIM FileAssociation AS FileAssociationType
	DIM FileHandle

	FileType = UCASE$(FileType)

	'Do not allow executables to be associated with anything
	IF FileType = "EXE" OR FileType = "COM" THEN
		File.GetAssociation = ""
		EXIT FUNCTION
	END IF

	IF FileType = "BAT" THEN
		File.GetAssociation = ENVIRON$("COMSPEC")
		EXIT FUNCTION
	END IF

	AssociationFile = "DATA\CONFIG\FILETYPE.DAT"

	'If association data file does not exist, fall back to default association
	'file. If that doesn't exist either, exit function and return nothing
	IF NOT File.Exists(AssociationFile) THEN
		IF File.Exists("DATA\CONFIG\FILETYPE.DEF") THEN
			AssociationFile = "DATA\CONFIG\FILETYPE.DEF"
		ELSE
			File.GetAssociation = ""
			EXIT FUNCTION
		END IF
	END IF

	FileHandle = FREEFILE
	OPEN AssociationFile FOR BINARY AS #FileHandle

	ON LOCAL ERROR RESUME NEXT
	DO WHILE NOT EOF(FileHandle)

		GET #FileHandle, , FileAssociation

		IF FileType = RTRIM$(FileAssociation.FileType) THEN
			OpenWith = RTRIM$(FileAssociation.Command)
			EXIT DO
		END IF

	LOOP
	CLOSE #FileHandle
	ON LOCAL ERROR GOTO 0

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

	DIM Char, Ascii, HotKey
	DIM FilteredText AS STRING

	'If there's a hotkey in the text, save its position and remove the char
	HotKey = INSTR(Text, HotkeySymbol)
	IF HotKey AND LEN(Text) > 1 THEN
		IF HotKey = 1 THEN
			FilteredText = RIGHT$(Text, LEN(Text) - 1)
		ELSE
			FilteredText = LEFT$(Text, HotKey - 1) + RIGHT$(Text, LEN(Text) - HotKey)
		END IF
	ELSE
		FilteredText = Text
	END IF

	FilteredText = RTRIM$(FilteredText)
	IF LEN(FilteredText) = 0 OR FontID < 1 OR FontID > 2 THEN EXIT SUB

	'Set color using C, move cursor without drawing using BM to x,y
	DRAW "C" + LTRIM$(STR$(Col)) + "BM" + LTRIM$(STR$(X)) + "," + LTRIM$(STR$(Y + 11))

	'Print the text, char by char
	FOR Char = 1 TO LEN(FilteredText)
		Ascii = ASC(MID$(FilteredText, Char, 1))
		IF Ascii >= 32 AND Ascii <= 126 THEN
			DRAW FontData(FontID, Ascii)
		ELSE
			'An unsupported character - print a space instead
			DRAW FontData(FontID, 32)
		END IF
	NEXT
	
	'Underline hotkey, if any
	IF HotKey THEN
		LINE (X + Font.GetWidth(LEFT$(FilteredText, HotKey - 1), FontID), Y + 11)-(X + Font.GetWidth(LEFT$(FilteredText, HotKey), FontID), Y + 11), Col
	END IF

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

	IF NOT MouseSupport THEN
		Mouse.Clicked = 0
		EXIT FUNCTION
	END IF

	DIM regs AS RegType

	regs.ax = 3
	INTERRUPT 51, regs, regs
	Mouse.Clicked = regs.bx

END FUNCTION

SUB Mouse.Hide ()

	IF NOT MouseHidden AND MouseSupport THEN
		DIM regs AS RegType
		regs.ax = 2
		INTERRUPT 51, regs, regs
		MouseHidden = True
	END IF
	
END SUB

FUNCTION Mouse.InArea (TargetArea AS PosType)

	'Returns True if the mouse cursor is within the area
	'regs.cx = X, regs.dx = y

	IF NOT MouseSupport THEN
		Mouse.InArea = False
		EXIT FUNCTION
	END IF

	DIM regs AS RegType
	regs.ax = 3
	INTERRUPT 51, regs, regs

	IF regs.cx >= TargetArea.Left AND regs.cx <= TargetArea.Left + TargetArea.Width THEN
		IF regs.dx >= TargetArea.Top AND regs.dx <= TargetArea.Top + TargetArea.Height THEN
			Mouse.InArea = True
		END IF
	END IF
	
END FUNCTION

SUB Mouse.Poll ()
	'Stores mouse coordinates in shared variables MouseX and MouseY

	IF NOT MouseSupport THEN EXIT SUB

	DIM regs AS RegType
	regs.ax = 3
	INTERRUPT 51, regs, regs
	MouseX = regs.cx
	MouseY = regs.dx

END SUB

SUB Mouse.SetPos (XPos, YPos)

	DIM regs AS RegType

	IF NOT MouseSupport THEN EXIT SUB

	regs.ax = 4
	regs.cx = XPos
	regs.dx = YPos
	INTERRUPT 51, regs, regs

END SUB

SUB Mouse.Show ()

	IF MouseHidden AND MouseSupport THEN
		DIM regs AS RegType
		regs.ax = 1
		INTERRUPT 51, regs, regs
		MouseHidden = False
	END IF

END SUB

FUNCTION Obj.BtnClick (TargetBtn AS ButtonType)

	DIM IsUp

	IF Mouse.Clicked = mbLeft AND Mouse.InArea(TargetBtn.Pos) THEN

		
		'Draw the button pressed
		Mouse.Hide
		Obj.DrawBtn TargetBtn, True
		Mouse.Show

		DO
			'Draw the button pressed when the mouse is over it, and unpressed
			'when the mouse leaves it
			IF Mouse.InArea(TargetBtn.Pos) THEN
				IF IsUp = 1 THEN
					IsUp = 0
					Mouse.Hide
					Obj.DrawBtn TargetBtn, True
					Mouse.Show
				END IF
			ELSE
				IF IsUp = 0 THEN
					IsUp = 1
					Mouse.Hide
					Obj.DrawBtn TargetBtn, False
					Mouse.Show
				END IF
			END IF

		LOOP WHILE Mouse.Clicked

		'Make sure the button looks released
		IF IsUp = 0 THEN
			Mouse.Hide
			Obj.DrawBtn TargetBtn, False
			Mouse.Show
		END IF

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
			Mouse.Hide
			Obj.DrawChk TargetChk
			Mouse.Show

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
		Color2 = Theme.Button
		Color3 = Theme.Shadow
		Color4 = Theme.WindowText
	ELSE
		Color1 = 0
		Color2 = Theme.Shadow
		Color3 = Theme.Light
		Color4 = 15
	END IF

	IF Color1 = Theme.Window THEN
		IF Theme.Window >= 8 THEN
			Color1 = Theme.Window - 8
		ELSE
			Color1 = Theme.Window + 8
		END IF
	END IF
	IF Color3 = Theme.Window THEN
		IF Theme.Window >= 8 THEN
			Color3 = Theme.Window - 8
		ELSE
			Color3 = Theme.Window + 8
		END IF
	END IF
	IF Color4 = Color2 THEN
		IF Color2 >= 8 THEN
			Color4 = Color2 - 8
		ELSE
			Color4 = Color2 + 8
		END IF
	END IF
	 
	IF TargetBtn.Transparent = False THEN
		LINE (x1, y1)-(x2 - 1, y2 - 1), Color2, BF
	ELSE
		LINE (x1, y1)-(x2 - 1, y2 - 1), Color2, B
	END IF

	LINE (x1 + 1, y1 + 1)-(x2 - 2, y1 + 1), Color1
	LINE (x1 + 1, y1 + 2)-(x1 + 1, y2 - 2), Color1

	LINE (x1, y2)-(x2, y2), Color3
	LINE (x2, y1)-(x2, y2 - 1), Color3

	IF NOT RTRIM$(TargetBtn.Caption) = "" THEN
		'Draw the caption centered on the button
		x1 = ((x2 - x1) - Font.GetWidth(RTRIM$(TargetBtn.Caption), FontHeading)) / 2 + x1
		y1 = ((y2 - y1) - 9) / 2 + y1
		IF Pressed = True THEN x1 = x1 + 1: y1 = y1 + 1
		
		Font.Print TargetBtn.Caption, x1, y1, Color4, FontHeading
	END IF

END SUB

SUB Obj.DrawChk (TargetChk AS CheckBoxType)

	DIM x1, x2, y1, y2, chkColor
	x1 = TargetChk.Pos.Left
	y1 = TargetChk.Pos.Top
	x2 = TargetChk.Pos.Left + 15
	y2 = TargetChk.Pos.Top + 15

	'Set the clickable area, in case the width and height is 0. This doesn't
	'affect the checkbox visually.
	IF TargetChk.Pos.Width = 0 THEN TargetChk.Pos.Width = 14
	IF TargetChk.Pos.Height = 0 THEN TargetChk.Pos.Height = 14

	LINE (x1 + 2, y1 + 2)-(x2 - 2, y2 - 2), Theme.Textbox, BF

	IF Theme.Window = 0 THEN
		chkColor = 15
	ELSE
		chkColor = 0
	END IF

	LINE (x1 + 1, y1 + 1)-(x2, y2), chkColor, B
	LINE (x2 - 1, y1 + 2)-(x2 - 1, y2 - 1), chkColor
	LINE (x1 + 2, y2 - 1)-(x2 - 2, y2 - 1), chkColor
	
	LINE (x1, y1)-(x1, y2), Theme.Shadow
	LINE (x1 + 1, y1)-(x2, y1), Theme.Shadow

	IF TargetChk.Checked = True THEN

		LINE (x1 + 5, y1 + 8)-(x1 + 7, y1 + 10), Theme.TextboxText
		LINE (x1 + 5, y1 + 9)-(x1 + 7, y1 + 11), Theme.TextboxText
		LINE (x1 + 8, y1 + 9)-(x1 + 11, y1 + 6), Theme.TextboxText
		LINE (x1 + 8, y1 + 10)-(x1 + 11, y1 + 7), Theme.TextboxText

		LINE (x1 + 5, y1 + 7)-(x1 + 7, y1 + 9), Theme.Shadow
		LINE (x1 + 8, y1 + 8)-(x1 + 11, y1 + 5), Theme.Shadow

		LINE (x1 + 5, y1 + 10)-(x1 + 6, y1 + 11), Theme.Light
		LINE (x1 + 8, y1 + 11)-(x1 + 11, y1 + 8), Theme.Light

	END IF

END SUB

SUB Obj.DrawFrm (TargetFrm AS FrameType, LightColor, DarkColor)
	'Tip: Set TargetFrm.Pos.Height to 1 to draw a seperating line instead of
	'     a frame

	DIM x1, x2, y1, y2
	x1 = TargetFrm.Pos.Left
	y1 = TargetFrm.Pos.Top
	x2 = TargetFrm.Pos.Left + TargetFrm.Pos.Width
	y2 = TargetFrm.Pos.Top + TargetFrm.Pos.Height

	LINE (x1 + 1, y1 + 1)-(x2, y2), LightColor, B
	LINE (x1, y1)-(x2 - 1, y2 - 1), DarkColor, B
	
END SUB

SUB Obj.DrawImg (TargetImg AS ImageType)

	DIM X, Y, XPos, YPos
	X = TargetImg.Pos.Left
	Y = TargetImg.Pos.Top

	TargetImg.Pos.Width = 31
	TargetImg.Pos.Height = 31

	LINE (X - 1, Y - 1)-(X + 32, Y - 1), Theme.Light
	LINE (X - 1, Y)-(X - 1, Y + 32), Theme.Light
	LINE (X, Y + 32)-(X + 32, Y + 32), Theme.Shadow
	LINE (X + 32, Y)-(X + 32, Y + 31), Theme.Shadow

	IF NOT File.Exists("DATA\IMAGES\" + TargetImg.ImageFile + ".BSV") THEN GOTO DrawImgError

	DIM scrBuffer(260)
	DEF SEG = VARSEG(scrBuffer(0))
	BLOAD "DATA\IMAGES\" + TargetImg.ImageFile + ".BSV", VARPTR(scrBuffer(0))
	DEF SEG
	PUT (X, Y), scrBuffer, PSET

	EXIT SUB

DrawImgError:
	'Draw a red box with the text "IMG ERR" to indicate a missing file
	LINE (X, Y)-(X + 31, Y + 31), 4, BF
	Font.Print "IMG", X + 6, Y + 4, 15, FontNormal
	Font.Print "ERR", X + 6, Y + 19, 15, FontNormal
	EXIT SUB
	RESUME NEXT
END SUB

SUB Obj.DrawMenu ()
	LINE (0, 0)-(639, 26), Theme.Window, BF
	LINE (0, 27)-(639, 27), Theme.Shadow
	LINE (0, 28)-(639, 28), 0
END SUB

SUB Obj.DrawTxt (TargetTxt AS TextboxType, BYVAL Text AS STRING, IsEditing AS INTEGER)

	DIM x1, x2, y1, y2, MaxShow
	
	x1 = TargetTxt.Pos.Left
	y1 = TargetTxt.Pos.Top
	IF TargetTxt.Pos.Top = 0 THEN TargetTxt.Pos.Top = 120
	IF TargetTxt.Pos.Height = 0 THEN TargetTxt.Pos.Height = 19
	x2 = TargetTxt.Pos.Left + TargetTxt.Pos.Width
	y2 = TargetTxt.Pos.Top + TargetTxt.Pos.Height

	LINE (x1 + 2, y1 + 2)-(x2 - 2, y2 - 2), Theme.Textbox, BF

	LINE (x1, y1)-(x2 - 1, y2 - 1), Theme.Light, B
	LINE (x1 + 1, y1 + 1)-(x2, y2), Theme.Shadow, B

	IF NOT Text = "" THEN
		'Only print the text that fits in the textbox

		MaxShow = (TargetTxt.Pos.Width - 10)
		
		DO UNTIL Font.GetWidth(Text, FontHeading) < MaxShow
			Text = RIGHT$(Text, LEN(Text) - 1)
		LOOP
		
		Font.Print Text, x1 + 5, y1 + 5, Theme.TextboxText, FontHeading
	END IF

	IF IsEditing = True THEN
		x1 = x1 + 7 + Font.GetWidth(Text, FontHeading)
		LINE (x1, y1 + 4)-(x1, y1 + 15), Theme.TextboxText
	END IF

END SUB

SUB Obj.DrawWin (TargetWin AS WindowType)

	DIM x1, x2, y1, y2
	x1 = TargetWin.Pos.Left
	y1 = TargetWin.Pos.Top
	x2 = TargetWin.Pos.Left + TargetWin.Pos.Width
	y2 = TargetWin.Pos.Top + TargetWin.Pos.Height

	'Window border
	LINE (x1 + 2, y1 + 2)-(x2 - 2, y2 - 1), Theme.TitleBar, BF

	'Window content area
	LINE (x1 + 7, y1 + 7)-(x2 - 7, y2 - 7), Theme.Window, BF
	
	'Outer border
	LINE (x1, y1)-(x2 - 1, y1), 15
	LINE (x1, y1 + 1)-(x1, y2 - 1), 15
	LINE (x2, y1)-(x2, y2), 0
	LINE (x1, y2)-(x2 - 1, y2), 0
	LINE (x2 - 1, y1 + 1)-(x2 - 1, y2 - 1), Theme.Shadow
	LINE (x1 + 1, y2 - 1)-(x2 - 2, y2 - 1), Theme.Shadow
	LINE (x1 + 1, y1 + 1)-(x2 - 2, y1 + 1), Theme.Light
	LINE (x1 + 1, y1 + 2)-(x1 + 1, y2 - 2), Theme.Light

	'Inner border
	LINE (x1 + 5, y1 + 5)-(x2 - 5, y2 - 5), Theme.Shadow, B
	LINE (x1 + 6, y1 + 6)-(x2 - 6, y2 - 6), Theme.Light, B

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
		LINE (LineX1, y1 - 1)-(LineX1, y1 + 10), Theme.TextboxText
		Mouse.Show
	ELSE
		Mouse.Hide
		Obj.DrawTxt TargetTxt, TempTxt, True
		Mouse.Show
	END IF

	DO
		Key$ = INKEY$

		IF Mouse.Clicked AND Mouse.InArea(TargetTxt.Pos) = False THEN Key$ = CHR$(13)

		IF LEN(Key$) = 1 THEN
			SELECT CASE ASC(Key$)
				CASE 8 'Backspace
					IF LEN(TempTxt) > 0 THEN
						Mouse.Hide
						IF Font.GetWidth(TempTxt, FontHeading) + 2 < MaxShow THEN
							'Erase only the last char
							LineX1 = x1 + Font.GetWidth(TempTxt, FontHeading)
							LINE (LineX1 + 2, y1 - 2)-(LineX1 - Font.GetWidth(RIGHT$(TempTxt, 1), FontHeading), y1 + 11), Theme.Textbox, BF
							TempTxt = LEFT$(TempTxt, LEN(TempTxt) - 1)
							LineX1 = x1 + Font.GetWidth(TempTxt, FontHeading) + 2
							LINE (LineX1, y1 - 1)-(LineX1, y1 + 10), Theme.TextboxText
						ELSE
							'There's more text that's not shown, so we'll
							'have to redraw the entire textbox
							TempTxt = LEFT$(TempTxt, LEN(TempTxt) - 1)
							Obj.DrawTxt TargetTxt, TempTxt, True
						END IF
						Mouse.Show
					END IF

				CASE 13 'Enter
					Text = TempTxt
					LineX1 = x1 + Font.GetWidth(Text, FontHeading) + 2
					Mouse.Hide
					LINE (LineX1, y1 - 1)-(LineX1, y1 + 10), Theme.Textbox
					Mouse.Show
					EXIT SUB

				CASE 32 TO 126 'Any printable character
					IF NOT LEN(TempTxt) = MaxLen THEN
						Mouse.Hide
						IF Font.GetWidth(TempTxt + Key$, FontHeading) + 2 < MaxShow THEN
							LineX1 = x1 + Font.GetWidth(TempTxt, FontHeading) + 2
							LINE (LineX1, y1 - 1)-(LineX1, y1 + 10), Theme.Textbox
							TempTxt = TempTxt + Key$
							Font.Print TempTxt, x1, y1, Theme.TextboxText, FontHeading
							LineX1 = x1 + Font.GetWidth(TempTxt, FontHeading) + 2
							LINE (LineX1, y1 - 1)-(LineX1, y1 + 10), Theme.TextboxText
						ELSE
							TempTxt = TempTxt + Key$
							Obj.DrawTxt TargetTxt, TempTxt, True
						END IF
						Mouse.Show
					END IF

				CASE 27 'Escape
					Text = OrigTxt
					Mouse.Hide
					Obj.DrawTxt TargetTxt, Text, False
					Mouse.Show
					EXIT SUB

			END SELECT
		END IF
						
	LOOP
	
END SUB

SUB Obj.SetSize (TargetArea AS PosType, TargetLeft, TargetTop, TargetWidth, TargetHeight)
	'Set left, top, width and height of object in one go.
	'Use sizeRetain to retain one or more properties (leave them unchanged).
	'Use sizeCenter for TargetLeft or TargetTop to center on screen.

	IF NOT TargetWidth = sizeRetain THEN TargetArea.Width = TargetWidth
	IF NOT TargetHeight = sizeRetain THEN TargetArea.Height = TargetHeight

	IF NOT TargetLeft = sizeRetain THEN
		IF TargetLeft = sizeCenter THEN
			TargetArea.Left = (640 - TargetArea.Width) / 2
		ELSE
			TargetArea.Left = TargetLeft
		END IF
	END IF

	IF NOT TargetTop = sizeRetain THEN
		IF TargetTop = sizeCenter THEN
			TargetArea.Top = (322 - TargetArea.Height) / 2 + 28
		ELSE
			TargetArea.Top = TargetTop
		END IF
	END IF


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

SUB Sys.AboutBox (ProgramName AS STRING, ProgramAuthor AS STRING, IconFile AS STRING)

	DIM winAboutBox AS WindowType
	DIM btnClose AS ButtonType
	DIM imgLogo AS ImageType
	DIM Key$

	Obj.SetSize winAboutBox.Pos, sizeCenter, sizeCenter, 329, 216
	Obj.SetSize imgLogo.Pos, 168, winAboutBox.Pos.Top + 11, sizeRetain, sizeRetain
	Obj.SetSize btnClose.Pos, 274, winAboutBox.Pos.Top + winAboutBox.Pos.Height - 34, 92, 22
	btnClose.Caption = HotkeySymbol + "Close"
	imgLogo.ImageFile = IconFile

	Mouse.Hide
	PCOPY 0, 1
	
	Obj.DrawWin winAboutBox
	Obj.DrawBtn btnClose, False
	Obj.DrawImg imgLogo

	Font.Print ProgramName + " by " + ProgramAuthor, 210, winAboutBox.Pos.Top + 15, 0, 1
	Font.Print appName + " version " + appVersion, 210, winAboutBox.Pos.Top + 29, 0, 2
	Font.Print "Costa made in 2004-" + appYear + " by Jacob Palm.", 168, winAboutBox.Pos.Top + 53, 0, 2
	Font.Print "Fonts drawn in 1998-1999 by Rush Soft.", 168, winAboutBox.Pos.Top + 67, 0, 2
	Font.Print "Open sourced and may be freely distributed under", 168, winAboutBox.Pos.Top + 95, 0, 2
	Font.Print "the terms of the MIT License. More details can", 168, winAboutBox.Pos.Top + 109, 0, 2
	Font.Print "be found in the LICENSE file.", 168, winAboutBox.Pos.Top + 123, 0, 2
	Font.Print "More information and news can be found online at", 168, winAboutBox.Pos.Top + 151, 0, 2
	Font.Print "https://costa.jacobpalm.dk", 168, winAboutBox.Pos.Top + 165, 0, 2
	Mouse.Show

	DO: LOOP WHILE Mouse.Clicked
	DO

		Key$ = LCASE$(INKEY$)
		IF Obj.BtnClick(btnClose) OR Key$ = CHR$(13) OR Key$ = CHR$(27) OR Key$ = "c" THEN EXIT DO

	LOOP

	Mouse.Hide
	PCOPY 1, 0
	Mouse.Show

END SUB

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
SUB Sys.Load ()

	DIM FontErr
	DIM regs AS RegType

	'Prepare fonts for use
	IF NOT File.Exists("DATA\FONTDATA.BSV") THEN FontErr = True
	IF NOT File.Exists("DATA\FONTINFO.BSV") THEN FontErr = True

	IF FontErr THEN
		CLS
		PRINT "One or more font files were not found in " + "DATA."
		PRINT "Press any key to exit."
		DO: LOOP WHILE INKEY$ = ""
		END 1 'Error 1 makes COSTA.EXE terminate if current app is desktop
	END IF

	'EGA/VGA 640x350, 16 colors
	SCREEN 9
	
	DEF SEG = VARSEG(FontData(1, 32))
	BLOAD "DATA\FONTDATA.BSV", VARPTR(FontData(1, 32))
	DEF SEG

	DEF SEG = VARSEG(FontWidth(1, 32))
	BLOAD "DATA\FONTINFO.BSV", VARPTR(FontWidth(1, 32))
	DEF SEG

	'Set hotkey symbol
	HotkeySymbol = CHR$(21)

	'Load settings
	Sys.LoadSettings
	Sys.LoadTheme
	
	'Detect mouse
	INTERRUPT 51, regs, regs
	IF regs.ax THEN MouseSupport = True
	
	'Clear mouse/keyboard buffer, DOSBox has some issues with leaving data
	DO: LOOP WHILE Mouse.Clicked
	DO: LOOP WHILE LEN(INKEY$)

	MouseHidden = True 'Force mouse to show
	Mouse.Show

END SUB

SUB Sys.LoadSettings ()

	DIM FileHandle

	IF NOT File.Exists("DATA\CONFIG\SETTING.DAT") THEN
		GOTO LoadDefaultSettings
	END IF

	ON LOCAL ERROR GOTO LoadDefaultSettings
	FileHandle = FREEFILE
	OPEN "DATA\CONFIG\SETTING.DAT" FOR BINARY AS #FileHandle
	GET #FileHandle, , Setting
	CLOSE #FileHandle

	IF Setting.DesktopID < 1 OR Setting.DesktopID > 5 THEN
		Setting.DesktopID = 1
	END IF

	EXIT SUB

LoadDefaultSettings:
	Setting.DesktopID = 1
	Setting.ShowLinkDescriptions = True
	Setting.ShowLinkTargetFiles = False
	Setting.ConfirmLinkDelete = True
	Setting.ConfirmExit = True
	Setting.AssignFileTypes = True
	Setting.ThemeFile = "DEFAULT"
END SUB

SUB Sys.LoadTheme ()

	DIM ThemeFile AS STRING
	ThemeFile = RTRIM$(Setting.ThemeFile)

	DIM FileHandle
	FileHandle = FREEFILE

	IF File.Exists("DATA\THEMES\" + ThemeFile + ".DAT") THEN
		OPEN "DATA\THEMES\" + ThemeFile + ".DAT" FOR BINARY AS #FileHandle
		GET #FileHandle, , Theme
		CLOSE #FileHandle
	ELSE
		Theme.Desktop = 7
		Theme.DesktopText = 0
		Theme.Window = 15
		Theme.Button = 7
		Theme.Textbox = 15
		Theme.TextboxText = 0
		Theme.WindowText = 0
		Theme.TitleBar = 3
		Theme.TitleBarText = 0
		Theme.Light = 7
		Theme.Shadow = 8
		Theme.Select = 8
		Theme.SelectText = 15
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
	Obj.SetSize winMsgBox.Pos, sizeCenter, sizeCenter, sizeRetain, msgLineCount * 15 + 78

	Obj.SetSize imgIcon.Pos, winMsgBox.Pos.Left + 13, winMsgBox.Pos.Top + 15, sizeRetain, sizeRetain
	IF msgType = msgInfo THEN imgIcon.ImageFile = "MSGINFO"
	IF msgType = msgWarn THEN imgIcon.ImageFile = "MSGWARN"
	IF msgType = msgQuest THEN imgIcon.ImageFile = "MSGQUEST"
	IF msgType = msgError THEN imgIcon.ImageFile = "MSGERROR"
	IF msgType = msgTip THEN imgIcon.ImageFile = "TIPBULB"

	Obj.SetSize btnFirst.Pos, sizeRetain, winMsgBox.Pos.Top + 42 + (15 * msgLineCount), 80, 22
	IF msgType = msgQuest THEN
		btnFirst.Caption = HotkeySymbol + "Yes"
		btnFirst.Pos.Left = 320 - 86
	ELSE
		btnFirst.Caption = HotkeySymbol + "OK"
		btnFirst.Pos.Left = (640 - btnFirst.Pos.Width) / 2
	END IF
	
	Obj.SetSize btnSecond.Pos, 326, btnFirst.Pos.Top, 80, 22
	btnSecond.Caption = HotkeySymbol + "No"
	
	Mouse.Hide
	PCOPY 0, 1
	
	Obj.DrawWin winMsgBox
	Obj.DrawBtn btnFirst, False
	IF msgType = msgQuest THEN Obj.DrawBtn btnSecond, False
	Obj.DrawImg imgIcon

	Font.Print msgTitle, winMsgBox.Pos.Left + 56, winMsgBox.Pos.Top + 15, Theme.WindowText, 1
	
	DIM PrintLine
	FOR PrintLine = 1 TO msgLineCount
		Font.Print msgLines(PrintLine), winMsgBox.Pos.Left + 56, winMsgBox.Pos.Top + 17 + (15 * PrintLine), Theme.WindowText, 2
	NEXT
	Mouse.Show
	
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
			ELSE
				IF Key$ = CHR$(13) OR Key$ = CHR$(27) OR Key$ = CHR$(32) OR Key$ = "o" THEN
					Sys.MsgBox = True
					EXIT DO
				END IF
			END IF
		END IF
	
	LOOP

	Mouse.Hide
	PCOPY 1, 0
	Mouse.Show

END FUNCTION

SUB Sys.SaveSettings ()

	ON LOCAL ERROR GOTO SaveSettingsError
	DIM FileHandle
	FileHandle = FREEFILE
	OPEN "DATA\CONFIG\SETTING.DAT" FOR BINARY AS #FileHandle
	PUT #FileHandle, , Setting
	CLOSE #FileHandle
	EXIT SUB

SaveSettingsError:
	FileHandle = Sys.MsgBox("Could not save settings", "An error occured while saving your settings, and they were not saved." + CHR$(13) + "Make sure the disk is not full or write-protected, and try again.", msgError)
	EXIT SUB
	RESUME NEXT
END SUB

SUB Sys.ShowLoading ()

		DIM btnLoading AS ButtonType
		Obj.SetSize btnLoading.Pos, sizeCenter, sizeCenter, 110, 34
		btnLoading.Caption = "Loading..."
		Mouse.Hide
		Obj.DrawBtn btnLoading, False
		Mouse.Show

END SUB

