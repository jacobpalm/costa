OPTION EXPLICIT
DEFINT A-Z

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'
'$INCLUDE: 'C:\VBDOS\VBDOS.BI'

'This is dimmed here, and not in LIBRARY.BI, because only this module uses
'it
	TYPE IconDataType
		Pixel(31, 31) AS INTEGER
	END TYPE
	
	DIM SHARED FontData(1 TO 3, 32 TO 127) AS STRING
	DIM SHARED FontWidth(1 TO 2, 32 TO 127) AS INTEGER

FUNCTION File.CfgRead (BYVAL CfgFile AS STRING, Setting AS STRING, DefaultValue AS STRING) AS STRING

	IF LEN(CfgFile) > LEN(Sys.Path) THEN
		IF LEFT$(CfgFile, LEN(Sys.Path)) = Sys.Path THEN CfgFile = RIGHT$(CfgFile, LEN(CfgFile) - LEN(Sys.Path))
	END IF

	IF NOT File.Exists(Sys.Path + CfgFile) THEN
		File.CfgRead = DefaultValue
		EXIT FUNCTION
	END IF

	DIM CfgHandle
	DIM TmpSetting AS STRING, TmpValue AS STRING
	CfgHandle = FREEFILE
	OPEN Sys.Path + CfgFile FOR INPUT AS #CfgHandle

	DO WHILE NOT EOF(CfgHandle)
		INPUT #CfgHandle, TmpSetting
		IF LEFT$(TmpSetting, 1) = "$" THEN
			INPUT #CfgHandle, TmpValue

			IF LCASE$(TmpSetting) = "$" + LCASE$(Setting) THEN
				File.CfgRead = TmpValue
				CLOSE #CfgHandle
				EXIT FUNCTION
			END IF
		END IF
	LOOP

	CLOSE #CfgHandle
	File.CfgRead = DefaultValue
	
END FUNCTION

DEFSNG A-Z
SUB File.CfgWrite (BYVAL CfgFile AS STRING, Setting AS STRING, Value AS STRING)

	DIM CfgOut, CfgIn, DidWrite
	DIM RenCfgFile AS STRING

	IF LEN(CfgFile) > LEN(Sys.Path) THEN
		IF LEFT$(CfgFile, LEN(Sys.Path)) = Sys.Path THEN CfgFile = RIGHT$(CfgFile, LEN(CfgFile) - LEN(Sys.Path))
	END IF
	
	IF NOT File.Exists(Sys.Path + CfgFile) THEN
		CfgOut = FREEFILE
		OPEN Sys.Path + CfgFile FOR OUTPUT AS #CfgOut
		PRINT #CfgOut, "$" + Setting + ",""" + Value + """"
		CLOSE #CfgOut
		EXIT SUB
	END IF

	DidWrite = False

	DIM TmpSetting AS STRING, TmpValue AS STRING
	CfgIn = FREEFILE
	OPEN Sys.Path + CfgFile FOR INPUT AS #CfgIn
	CfgOut = FREEFILE
	OPEN Sys.Path + LEFT$(CfgFile, LEN(CfgFile) - 3) + "TMP" FOR OUTPUT AS #CfgOut

	DO WHILE NOT EOF(CfgIn)
		INPUT #CfgIn, TmpSetting

		IF LEFT$(TmpSetting, 1) = "$" THEN
			INPUT #CfgIn, TmpValue

			IF LCASE$(TmpSetting) = "$" + LCASE$(Setting) THEN
				DidWrite = True
				'Only write the entry if Value is not empty. This will remove
				'the entry instead of leaving a blank entry in the file
				IF NOT Value = "" THEN PRINT #CfgOut, TmpSetting + ",""" + Value + """"
			ELSE
				PRINT #CfgOut, TmpSetting + ",""" + TmpValue + """"
			END IF
		ELSE
			PRINT #CfgOut, TmpSetting
		END IF
	LOOP

	IF DidWrite = False AND LEN(Value) THEN PRINT #CfgOut, "$" + Setting + ",""" + Value + """"

	CLOSE #CfgIn
	CLOSE #CfgOut

	ON LOCAL ERROR RESUME NEXT
	KILL Sys.Path + CfgFile
	RenCfgFile = CfgFile

	DO WHILE INSTR(RenCfgFile, "\")
		RenCfgFile = RIGHT$(RenCfgFile, LEN(RenCfgFile) - INSTR(RenCfgFile, "\"))
	LOOP

	SHELL "ren " + Sys.Path + LEFT$(CfgFile, LEN(CfgFile) - 3) + "TMP " + RenCfgFile
	SHELL "chdir " + Sys.Path
	ON LOCAL ERROR GOTO 0
	
END SUB

DEFINT A-Z
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

'Runs an external program.
'Also checks for a file association if passed a file, and passes the
'filename to the relevant program as a parameter.
'If this function returns any value, it should be passed to TView.Main as
'that means the file should be opened with Costa itself (only used in
'DESKTOP.MAK)
FUNCTION File.Run (BYVAL TargetFile AS STRING, BYVAL TargetParameters AS STRING, BYVAL TargetPath AS STRING, PauseOnExit AS INTEGER) AS STRING

	DIM RunHandle, DotPos, AssignFileTypes
	DIM TargetDrive AS STRING, SysDrive AS STRING

	TargetFile = LTRIM$(RTRIM$(TargetFile))
	TargetParameters = LTRIM$(RTRIM$(TargetParameters))
	IF MID$(TargetPath, 2, 2) = ":\" THEN TargetDrive = LEFT$(TargetPath, 2)

	IF LEN(TargetPath) THEN
		IF RIGHT$(TargetPath, 1) = "\" AND LEN(TargetPath) > 1 THEN TargetPath = LEFT$(TargetPath, LEN(TargetPath) - 1)
	END IF
	IF INSTR(UCASE$(TargetPath), appEnviron) THEN
		DIM TmpPath AS STRING
		IF INSTR(UCASE$(TargetPath), appEnviron) > 1 THEN
			TmpPath = LEFT$(TargetPath, INSTR(UCASE$(TargetPath), appEnviron) - 1)
		END IF
		TmpPath = TmpPath + Sys.Path
		IF LEN(TargetPath) > INSTR(UCASE$(TargetPath), appEnviron) + 9 THEN
			TmpPath = TmpPath + RIGHT$(TargetPath, LEN(TargetPath) - 9 - INSTR(UCASE$(TargetPath), appEnviron))
		END IF
		TargetPath = TmpPath
		IF LEN(TargetPath) THEN IF RIGHT$(TargetPath, 1) = "\" AND LEN(TargetPath) > 1 THEN TargetPath = LEFT$(TargetPath, LEN(TargetPath) - 1)
	END IF
	

	
	'Get the file extension, and see if it's associated with a program
	DotPos = INSTR(TargetFile, ".")
	AssignFileTypes = VAL(File.CfgRead("DATA\CONFIG\COSTA.CFG", "AssignFileTypes", "1"))
	IF DotPos > 0 AND AssignFileTypes = 1 THEN

		DIM FileType AS STRING, OpenWith AS STRING
		FileType = RIGHT$(TargetFile, LEN(TargetFile) - DotPos)

		OpenWith = File.CfgRead("DATA\CONFIG\FILETYPE.CFG", FileType, "")
		
		IF NOT OpenWith = "" AND NOT INSTR(TargetFile, " ") THEN
			IF UCASE$(OpenWith) = appExeName OR UCASE$(OpenWith) = appExeName + ".EXE" THEN

				IF LEN(TargetDrive) THEN CHDRIVE TargetDrive
				ON LOCAL ERROR RESUME NEXT
				IF LEN(TargetPath) THEN CHDIR "\": CHDIR TargetPath
				ON LOCAL ERROR GOTO 0
				IF LEN(TargetPath) > 0 THEN TargetPath = TargetPath + "\"
				File.Run = TargetPath + TargetFile
				EXIT FUNCTION
			ELSE
				TargetFile = OpenWith + " " + TargetFile
			END IF
		END IF

	END IF
	

	'Print the filename, parameters, path and wether to pause on exit to
	'RUN.DAT, and exit. COSTA.EXE will look at the file and run the program
	RunHandle = FREEFILE

	OPEN Sys.Path + "DATA\TEMP\RUN.BAT" FOR OUTPUT AS #RunHandle
	PRINT #RunHandle, "@ECHO OFF"
	IF LEN(TargetDrive) THEN PRINT #RunHandle, TargetDrive
	IF LEN(TargetPath) THEN
		IF LEN(TargetPath) > 1 THEN
			IF RIGHT$(TargetPath, 1) = "\" AND LEN(TargetPath) > 1 THEN TargetPath = LEFT$(TargetPath, LEN(TargetPath) - 1)
		END IF
		PRINT #RunHandle, "CD\"
		PRINT #RunHandle, "CD " + TargetPath
	END IF
	PRINT #RunHandle, TargetFile + TargetParameters
	IF PauseOnExit = True THEN PRINT #RunHandle, "PAUSE"

	IF MID$(Sys.Path, 2, 2) = ":\" THEN SysDrive = LEFT$(Sys.Path, 2)
	IF LEN(SysDrive) THEN PRINT #RunHandle, SysDrive
	PRINT #RunHandle, "CD " + LEFT$(Sys.Path, LEN(Sys.Path) - 1)

	CLOSE #RunHandle

	DO: LOOP WHILE LEN(INKEY$)
	END 2

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
	'  False    0 if no button is clicked
	'  mbLeft  -1 if left button is clicked
	'  mbRight -2 if right button is clicked
	'  mbBoth  -3 if both buttons are clicked

	DIM ButtonMouse, Col, Row
	Mouse.Driver 3, ButtonMouse, Col, Row

	DIM lButton, RButton
	IF ButtonMouse AND 1 THEN
		lButton = -1
	ELSE
		lButton = 0
	END IF

	IF ButtonMouse AND 2 THEN
		RButton = -1
	ELSE
		RButton = 0
	END IF

	IF lButton = -1 THEN
		IF RButton = -1 THEN
			Mouse.Clicked = mbBoth
		ELSE
			Mouse.Clicked = mbLeft
		END IF
	ELSEIF RButton = -1 THEN
		Mouse.Clicked = mbRight
	END IF
	IF lButton = 0 AND RButton = 0 THEN Mouse.Clicked = 0
END FUNCTION

STATIC SUB Mouse.Driver (M0, M1, M2, M3)
	'  To check if a mouse is present, use this call:
	'    MouseDriver MousePresent%, 0, 0, 0
	'
	'  If a mouse is present, MousePresent% will be True. Otherwise it will
	'  be False.
	'

	DIM regs AS RegType
	DIM MouseSegment&, MouseOffset&
	DIM MousePresent, MouseChecked

	IF MouseChecked = False THEN
		DEF SEG = 0

		MouseSegment& = 256& * PEEK(207) + PEEK(206)
		MouseOffset& = 256& * PEEK(205) + PEEK(204)

		DEF SEG = MouseSegment&

		IF (MouseSegment& = 0 AND MouseOffset& = 0) OR PEEK(MouseOffset&) = 207 THEN
			MousePresent = False
			MouseChecked = True
			DEF SEG
		END IF
	END IF

	IF MousePresent = False AND MouseChecked = True THEN
		EXIT SUB
	END IF

	' Calls interrupt 51 to invoke mouse functions in the MS Mouse Driver.
	
	regs.ax = M0
	regs.bx = M1
	regs.cx = M2
	regs.dx = M3

	INTERRUPT 51, regs, regs

	M0 = regs.ax
	M1 = regs.bx
	M2 = regs.cx
	M3 = regs.dx

	IF MouseChecked THEN EXIT SUB

	' Check for successful mouse initialization

	IF M0 AND NOT MouseChecked THEN
		MousePresent = True
		DEF SEG
	END IF

	MouseChecked = True
	
END SUB

SUB Mouse.Hide ()

	Mouse.Driver 2, 0, 0, 0

END SUB

FUNCTION Mouse.InArea (TargetArea AS PosType)

	'Returns True if the mouse cursor is within the area

	IF Mouse.X > TargetArea.Left AND Mouse.X < TargetArea.Left + TargetArea.Width THEN
		IF Mouse.Y > TargetArea.Top AND Mouse.Y < TargetArea.Top + TargetArea.Height THEN
			Mouse.InArea = True
		END IF
	END IF
	
END FUNCTION

SUB Mouse.Show ()

	Mouse.Driver 1, 0, 0, 0

END SUB

FUNCTION Mouse.X ()
	'Returns the X coordinate of the mouse.

	DIM ButtonMouse, Col, Row
	Mouse.Driver 3, ButtonMouse, Col, Row
	Mouse.X = Col

END FUNCTION

FUNCTION Mouse.Y ()
	'Returns the Y coordinate of the mouse.

	DIM ButtonMouse, Col, Row
	Mouse.Driver 3, ButtonMouse, Col, Row
	Mouse.Y = Row
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
		Color2 = Clr3DLight
		Color3 = Clr3DShadow
		Color4 = 0
	ELSE
		Color1 = 0
		Color2 = Clr3DShadow
		Color3 = Clr3DLight
		Color4 = 15
	END IF

	Mouse.Hide
	IF TargetBtn.Transparent = False THEN LINE (x1 + 2, y1 + 2)-(x2 - 2, y2 - 2), ClrButton, BF

	LINE (x1, y1)-(x1, y2), Color1
	LINE (x1 + 1, y1)-(x2, y1), Color1

	LINE (x1 + 1, y1 + 1)-(x1 + 1, y2 - 1), Color2
	LINE (x1 + 2, y1 + 1)-(x2 - 1, y1 + 1), Color2
	
	LINE (x1 + 2, y2 - 1)-(x2 - 1, y2 - 1), Color3
	LINE (x2 - 1, y1 + 2)-(x2 - 1, y2 - 2), Color3

	LINE (x1 + 1, y2)-(x2, y2), Color4
	LINE (x2, y1 + 1)-(x2, y2 - 1), Color4

	IF NOT RTRIM$(TargetBtn.Caption) = "" THEN
		'Draw the caption centered on the button, and underline the hotkey
		x1 = ((x2 - x1) - Font.GetWidth(RTRIM$(TargetBtn.Caption), FontHeading)) / 2 + x1
		y1 = ((y2 - y1) - 9) / 2 + y1
		IF Pressed = True THEN x1 = x1 + 1: y1 = y1 + 1
		
		Font.Print TargetBtn.Caption, x1, y1, ClrWindowText, FontHeading

		
		IF TargetBtn.HotKey > 0 AND TargetBtn.HotKey <= LEN(RTRIM$(TargetBtn.Caption)) THEN
			DIM XStart, XEnd
			XStart = x1 + Font.GetWidth(LEFT$(TargetBtn.Caption, TargetBtn.HotKey - 1), FontHeading) - 1
			XEnd = x1 + Font.GetWidth(LEFT$(TargetBtn.Caption, TargetBtn.HotKey), FontHeading) + 1
			LINE (x1 + Font.GetWidth(LEFT$(TargetBtn.Caption, TargetBtn.HotKey - 1), FontHeading) - 1, y1 + 11)-(x1 + Font.GetWidth(LEFT$(TargetBtn.Caption, TargetBtn.HotKey), FontHeading), y1 + 11), ClrWindowText
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
	LINE (x1 + 2, y1 + 2)-(x2 - 2, y2 - 2), ClrTextbox, BF

	LINE (x1, y1)-(x1, y2), 0
	LINE (x1 + 1, y1)-(x2, y1), 0

	LINE (x1 + 1, y1 + 1)-(x1 + 1, y2 - 1), Clr3DShadow
	LINE (x1 + 2, y1 + 1)-(x2 - 1, y1 + 1), Clr3DShadow

	LINE (x1 + 2, y2 - 1)-(x2 - 1, y2 - 1), Clr3DLight
	LINE (x2 - 1, y1 + 2)-(x2 - 1, y2 - 2), Clr3DLight

	LINE (x1 + 1, y2)-(x2, y2), 15
	LINE (x2, y1 + 1)-(x2, y2 - 1), 15

	IF TargetChk.Checked = True THEN
		LINE (x1 + 4, y1 + 7)-(x1 + 4, y1 + 9), ClrTextboxText
		LINE (x1 + 5, y1 + 8)-(x1 + 5, y1 + 10), ClrTextboxText
		LINE (x1 + 6, y1 + 9)-(x1 + 6, y1 + 11), ClrTextboxText

		LINE (x1 + 7, y1 + 8)-(x1 + 7, y1 + 10), ClrTextboxText
		LINE (x1 + 8, y1 + 7)-(x1 + 8, y1 + 9), ClrTextboxText
		LINE (x1 + 9, y1 + 6)-(x1 + 9, y1 + 8), ClrTextboxText
		LINE (x1 + 10, y1 + 5)-(x1 + 10, y1 + 7), ClrTextboxText
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


	IF NOT File.Exists(Sys.Path + "DATA\IMAGES\" + TargetImg.ImageFile + ".BIF") THEN
		'Draw a red box with the text "IMG ERR" to indicate a missing file
		Mouse.Hide
		LINE (X + 1, Y + 1)-(X + 30, Y + 30), 4, BF
		LINE (X, Y)-(X + 31, Y + 31), 0, B
		Mouse.Show
		Font.Print "IMG", X + 6, Y + 4, 15, FontNormal
		Font.Print "ERR", X + 6, Y + 19, 15, FontNormal
		EXIT SUB
	END IF



	DIM BifHandle
	DIM IconData AS IconDataType

	BifHandle = FREEFILE
	
	'DEBUG DEBUG
	'Check stoerrelse, kontroller header m.m.

	OPEN Sys.Path + "DATA\IMAGES\" + TargetImg.ImageFile + ".BIF" FOR BINARY AS #BifHandle
	GET #BifHandle, , Header
	GET #BifHandle, , IconData
	CLOSE #BifHandle
	
	Mouse.Hide
	FOR XPos = 0 TO 31
		FOR YPos = 0 TO 31
			IF IconData.Pixel(XPos, YPos) > -1 THEN
				PSET (X + XPos, Y + YPos), IconData.Pixel(XPos, YPos)
			END IF
		NEXT
	NEXT
	Mouse.Show

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
	LINE (x1 + 2, y1 + 2)-(x2 - 2, y2 - 2), ClrTextbox, BF

	LINE (x1, y1)-(x1, y2), 0
	LINE (x1 + 1, y1)-(x2, y1), 0

	LINE (x1 + 1, y1 + 1)-(x1 + 1, y2 - 1), Clr3DShadow
	LINE (x1 + 2, y1 + 1)-(x2 - 1, y1 + 1), Clr3DShadow

	LINE (x1 + 2, y2 - 1)-(x2 - 1, y2 - 1), Clr3DLight
	LINE (x2 - 1, y1 + 2)-(x2 - 1, y2 - 2), Clr3DLight

	LINE (x1 + 1, y2)-(x2, y2), 15
	LINE (x2, y1 + 1)-(x2, y2 - 1), 15

	Mouse.Show

	IF NOT Text = "" THEN
		'Only print the text that fits in the textbox

		MaxShow = (TargetTxt.Pos.Width - 10)
		
		DO UNTIL Font.GetWidth(Text, FontHeading) < MaxShow
			Text = RIGHT$(Text, LEN(Text) - 1)
		LOOP
		
		Font.Print Text, x1 + 5, y1 + 5, ClrTextboxText, FontHeading
	END IF

	IF IsEditing = True THEN
		Mouse.Hide
		x1 = x1 + 7 + Font.GetWidth(Text, FontHeading)
		LINE (x1, y1 + 4)-(x1, y1 + 15), ClrTextboxText
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

	'Window interior and borders
	LINE (x1 + 2, y1 + 2)-(x2 - 1, y2 - 1), ClrWindow, BF
	

	'Outer border
	LINE (x1 + 1, y1 + 1)-(x1 + 1, y2 - 1), 15
	LINE (x1 + 2, y1 + 1)-(x2 - 1, y1 + 1), 15
	LINE (x2 + 1, y1 + 2)-(x2 + 1, y2 + 1), 0
	LINE (x1 + 1, y2 + 1)-(x2, y2 + 1), 0

	'Inner border
	LINE (x1, y1)-(x2, y1), Clr3DLight
	LINE (x1, y1)-(x1, y2), Clr3DLight
	LINE (x1 + 1, y2)-(x2, y2), Clr3DShadow
	LINE (x2, y1 + 1)-(x2, y2 - 1), Clr3DShadow

	'Titlebar
	LINE (x1 + 4, y1 + 4)-(x2 - 4, y1 + 22), Clr3DShadow, B
	LINE (x1 + 5, y1 + 5)-(x2 - 5, y1 + 21), ClrTitleBar, BF
	LINE (x1 + 4, y1 + 23)-(x2 - 4, y1 + 23), 15
	LINE (x2 - 3, y1 + 4)-(x2 - 3, y1 + 22), 15

	IF NOT RTRIM$(TargetWin.Caption) = "" THEN
		'Draw caption centered on titlebar
		x1 = ((x2 - x1) - Font.GetWidth(RTRIM$(TargetWin.Caption), FontHeading)) / 2 + x1
		Font.Print TargetWin.Caption, x1, y1 + 9, ClrTitleBarText, FontHeading
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
		LINE (LineX1, y1 - 1)-(LineX1, y1 + 10), ClrTextboxText
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
							LINE (LineX1 + 2, y1 - 2)-(LineX1 - Font.GetWidth(RIGHT$(TempTxt, 1), FontHeading), y1 + 11), ClrTextbox, BF
							Mouse.Show
							TempTxt = LEFT$(TempTxt, LEN(TempTxt) - 1)
							LineX1 = x1 + Font.GetWidth(TempTxt, FontHeading) + 2
							Mouse.Hide
							LINE (LineX1, y1 - 1)-(LineX1, y1 + 10), ClrTextboxText
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
					LINE (LineX1, y1 - 1)-(LineX1, y1 + 10), ClrTextbox
					Mouse.Show
					EXIT SUB

				CASE 32 TO 126 'Any printable character
					IF NOT LEN(TempTxt) = MaxLen THEN
						IF Font.GetWidth(TempTxt + Key$, FontHeading) + 2 < MaxShow THEN
							LineX1 = x1 + Font.GetWidth(TempTxt, FontHeading) + 2
							Mouse.Hide
							LINE (LineX1, y1 - 1)-(LineX1, y1 + 10), ClrTextbox
							Mouse.Show
							TempTxt = TempTxt + Key$
							Font.Print TempTxt, x1, y1, ClrTextboxText, FontHeading
							LineX1 = x1 + Font.GetWidth(TempTxt, FontHeading) + 2
							Mouse.Hide
							LINE (LineX1, y1 - 1)-(LineX1, y1 + 10), ClrTextboxText
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
	DIM GreyoutScreen

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
	winInputBox.Pos.Height = msgLineCount * 15 + 134
	winInputBox.Pos.Left = (640 - winInputBox.Pos.Width) / 2
	winInputBox.Pos.Top = (480 - winInputBox.Pos.Height) / 2
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

	Sys.VGASave "INPUTBOX"

	GreyoutScreen = VAL(File.CfgRead("DATA\CONFIG\COSTA.CFG", "GreyOutOnMsgBox", "0"))
	IF GreyoutScreen = 1 THEN
		DIM LX, LY
		LY = 0
		Mouse.Hide
		FOR LX = 0 TO 639
			LINE (LX, LY)-(LX, 479), Clr3DShadow, , &HAAAA
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
		Obj.DrawImg imgIcon
		Font.Print msgTitle, winInputBox.Pos.Left + 53, winInputBox.Pos.Top + 33, ClrWindowText, 1
	ELSE
		Font.Print msgTitle, winInputBox.Pos.Left + 12, winInputBox.Pos.Top + 33, ClrWindowText, 1
	END IF

	DIM PrintLine
	FOR PrintLine = 1 TO msgLineCount
		IF PrintLine < 3 AND LEN(msgIcon) THEN
			Font.Print msgLines(PrintLine), winInputBox.Pos.Left + 53, winInputBox.Pos.Top + 35 + (15 * PrintLine), ClrWindowText, 2
		ELSE
			Font.Print msgLines(PrintLine), winInputBox.Pos.Left + 12, winInputBox.Pos.Top + 35 + (15 * PrintLine), ClrWindowText, 2
		END IF
	NEXT

	Font.Print "Input:", txtInput.Pos.Left, txtInput.Pos.Top - 16, ClrWindowText, FontHeading
	LINE (txtInput.Pos.Left + 5, txtInput.Pos.Top - 6)-(txtInput.Pos.Left + 12, txtInput.Pos.Top - 6), ClrWindowText

	DIM Key$
	DO

		Key$ = LCASE$(INKEY$)

		IF Obj.BtnClick(btnOK) OR Key$ = "o" OR Key$ = CHR$(13) THEN
			Sys.InputBox = txtInputText
			EXIT DO
		END IF

		IF Obj.BtnClick(btnCancel) OR Key$ = "c" OR Key$ = CHR$(27) THEN
			Sys.InputBox = "" 'DEBUG - changed - any effect?   msgDefault
			EXIT DO
		END IF
		
		IF Obj.TxtClick(txtInput) OR Key$ = "n" THEN Obj.EditTxt txtInput, txtInputText

	LOOP

	Sys.VGALoad "INPUTBOX"


END FUNCTION

SUB Sys.Load ()

	'If the parameters /VER or /? are used, just show version info and exit
		IF INSTR(COMMAND$, "/VER") OR INSTR(COMMAND$, "/?") THEN
			PRINT
			PRINT appName
			PRINT "Made in 2004-" + appYear + " Jacob Palm"
			PRINT
			PRINT "Version " + appVersion
			PRINT
			END
		END IF

	'Make sure Costa is running, by checking if RUNSTAT.TMP created by the
	'/BOOT parameter exists
		IF File.Exists(Sys.Path + "DATA\TEMP\RUNSTAT.TMP") = False THEN
			IF INSTR(COMMAND$, "/DEV") = 0 THEN 'DEBUG! Not for final release
				CLS
				PRINT "This program is a part of " + appName + " and should not be executed"
				PRINT "directly from the command prompt."
				PRINT
				PRINT "To start Costa, run COSTA.BAT. If that file doesn't exist, run SETUP.EXE."
				PRINT
				END
			END IF
		END IF
	
	'Prepare fonts for use
		DIM FontErr
		IF NOT File.Exists(Sys.Path + "DATA\FONTS\HEADING.FNT") THEN FontErr = True
		IF NOT File.Exists(Sys.Path + "DATA\FONTS\NORMAL.FNT") THEN FontErr = True
		IF NOT File.Exists(Sys.Path + "DATA\FONTS\SYSTEM.FNT") THEN FontErr = True

		IF FontErr THEN
			CLS
			PRINT "One or more font files were not found."
			PRINT "Make sure the font files are in " + Sys.Path + "DATA\FONTS."
			PRINT
			PRINT "Press any key to exit."
			DO: LOOP WHILE INKEY$ = ""
			END 1
		END IF

		DIM CharAscii, FontFileHandle
		'Chicago font
			FontFileHandle = FREEFILE
			OPEN Sys.Path + "DATA\FONTS\HEADING.FNT" FOR INPUT AS #FontFileHandle
			FOR CharAscii = 32 TO 126
				LINE INPUT #FontFileHandle, FontData(1, CharAscii)
				INPUT #FontFileHandle, FontWidth(1, CharAscii)
			NEXT
			CLOSE #FontFileHandle
		'Geneva font
			OPEN Sys.Path + "DATA\FONTS\NORMAL.FNT" FOR INPUT AS #FontFileHandle
			FOR CharAscii = 32 TO 126
				LINE INPUT #FontFileHandle, FontData(2, CharAscii)
				INPUT #FontFileHandle, FontWidth(2, CharAscii)
			NEXT
			CLOSE #FontFileHandle
		'System (monospaced) font
			OPEN Sys.Path + "DATA\FONTS\SYSTEM.FNT" FOR INPUT AS #FontFileHandle
			FOR CharAscii = 32 TO 126
				LINE INPUT #FontFileHandle, FontData(3, CharAscii)
			NEXT
			CLOSE #FontFileHandle


	'Load colors for the interface
		ClrThemeFile = File.CfgRead("DATA\CONFIG\COSTA.CFG", "ThemeFile", "Default")
		ClrDesktop = VAL(File.CfgRead("DATA\THEMES\" + ClrThemeFile + ".THM", "ClrDesktop", "3"))
		ClrDesktopText = VAL(File.CfgRead("DATA\THEMES\" + ClrThemeFile + ".THM", "ClrDesktopText", "0"))
		ClrWindow = VAL(File.CfgRead("DATA\THEMES\" + ClrThemeFile + ".THM", "ClrWindow", "7"))
		ClrButton = VAL(File.CfgRead("DATA\THEMES\" + ClrThemeFile + ".THM", "ClrButton", "7"))
		ClrTextbox = VAL(File.CfgRead("DATA\THEMES\" + ClrThemeFile + ".THM", "ClrTextbox", "15"))
		ClrTextboxText = VAL(File.CfgRead("DATA\THEMES\" + ClrThemeFile + ".THM", "ClrTextboxText", "0"))
		ClrWindowText = VAL(File.CfgRead("DATA\THEMES\" + ClrThemeFile + ".THM", "ClrWindowText", "0"))
		ClrTitleBar = VAL(File.CfgRead("DATA\THEMES\" + ClrThemeFile + ".THM", "ClrTitlebar", "0"))
		ClrTitleBarText = VAL(File.CfgRead("DATA\THEMES\" + ClrThemeFile + ".THM", "ClrTitlebarText", "15"))
		Clr3DLight = VAL(File.CfgRead("DATA\THEMES\" + ClrThemeFile + ".THM", "Clr3DLight", "7"))
		Clr3DShadow = VAL(File.CfgRead("DATA\THEMES\" + ClrThemeFile + ".THM", "Clr3DShadow", "8"))
		ClrSelect = VAL(File.CfgRead("DATA\THEMES\" + ClrThemeFile + ".THM", "ClrSelect", "1"))
		ClrSelectText = VAL(File.CfgRead("DATA\THEMES\" + ClrThemeFile + ".THM", "ClrSelectText", "15"))


	'Clear the keyboard buffer, DOSBox has some issues with leaving keys in it
			DO: LOOP WHILE LEN(INKEY$)
			
	'DEBUG
	'IF NOT COMMAND$ = "/DEV" THEN Sys.Delay 1.2

	'VGA 640x480, 16 colors
	SCREEN 12

	'If DESKTOP.INT exists we can load the desktop, and skip drawing it
	'manually
		IF File.Exists(Sys.Path + "DATA\TEMP\DESKTOP.INT") THEN
			Mouse.Hide
			Sys.VGALoad "DESKTOP"
			Mouse.Show
		ELSE
			Mouse.Hide
			PAINT (0, 0), ClrDesktop
			Mouse.Show
		END IF


	'Set the right colors for the palette
		OUT &H3C8, 6
		OUT &H3C9, 31
		OUT &H3C9, 31
		OUT &H3C9, 0

		OUT &H3C8, 9
		OUT &H3C9, 0
		OUT &H3C9, 0
		OUT &H3C9, 255

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

FUNCTION Sys.MsgBox (msgTitle AS STRING, BYVAL msgText AS STRING, msgType)

	DIM msgLines() AS STRING, msgLineCount, msgTextWidth
	DIM btnFirst AS ButtonType, btnSecond AS ButtonType
	DIM imgIcon AS ImageType
	DIM winMsgBox AS WindowType
	DIM GreyoutScreen

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
	winMsgBox.Pos.Height = msgLineCount * 15 + 92
	winMsgBox.Pos.Left = (640 - winMsgBox.Pos.Width) / 2
	winMsgBox.Pos.Top = (480 - winMsgBox.Pos.Height) / 2
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
	
	Sys.VGASave "MSGBOX"

	GreyoutScreen = VAL(File.CfgRead("DATA\CONFIG\COSTA.CFG", "GreyOutOnMsgBox", "0"))
	IF GreyoutScreen = 1 THEN
		DIM LX, LY
		LY = 0
		Mouse.Hide
		FOR LX = 0 TO 639
			LINE (LX, LY)-(LX, 479), Clr3DShadow, , &HAAAA
			IF LY = 0 THEN
				LY = 1
			ELSE
				LY = 0
			END IF
		NEXT
		Mouse.Show
	END IF

	Obj.DrawWin winMsgBox
	Obj.DrawImg imgIcon
	Obj.DrawBtn btnFirst, False
	IF msgType = msgQuest THEN Obj.DrawBtn btnSecond, False

	Font.Print msgTitle, winMsgBox.Pos.Left + 56, winMsgBox.Pos.Top + 33, ClrWindowText, 1
	
	DIM PrintLine
	FOR PrintLine = 1 TO msgLineCount
		Font.Print msgLines(PrintLine), winMsgBox.Pos.Left + 56, winMsgBox.Pos.Top + 35 + (15 * PrintLine), ClrWindowText, 2
	NEXT
	
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

	Sys.VGALoad "MSGBOX"

END FUNCTION

FUNCTION Sys.Path () AS STRING

	'DEBUG
	IF COMMAND$ = "/DEV" THEN
		Sys.Path = "C:\COSTA\"
		EXIT FUNCTION
	END IF

	DIM SysPath AS STRING

	SysPath = ENVIRON$(appExeName)

	IF LEN(SysPath) > 0 THEN
		IF NOT RIGHT$(SysPath, 1) = "\" THEN SysPath = SysPath + "\"
	END IF

	Sys.Path = SysPath

END FUNCTION

STATIC SUB Sys.VGALoad (TargetFile AS STRING)
	'BLOADs a VGA screen saved by Sys.VGASave
	'DEBUG - use File.Exists to avoid errors

	Mouse.Hide

	DEF SEG = &HA000

	OUT &H3C4, 2: OUT &H3C5, 1
	BLOAD Sys.Path + "DATA\TEMP\" + TargetFile + ".BLU", 0

	OUT &H3C4, 2: OUT &H3C5, 2
	BLOAD Sys.Path + "DATA\TEMP\" + TargetFile + ".GRN", 0

	OUT &H3C4, 2: OUT &H3C5, 4
	BLOAD Sys.Path + "DATA\TEMP\" + TargetFile + ".RED", 0

	OUT &H3C4, 2: OUT &H3C5, 8
	BLOAD Sys.Path + "DATA\TEMP\" + TargetFile + ".INT", 0

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
	BSAVE Sys.Path + "DATA\TEMP\" + TargetFile + ".BLU", 0, Size&

	OUT &H3CE, 4: OUT &H3CF, 1
	BSAVE Sys.Path + "DATA\TEMP\" + TargetFile + ".GRN", 0, Size&

	OUT &H3CE, 4: OUT &H3CF, 2
	BSAVE Sys.Path + "DATA\TEMP\" + TargetFile + ".RED", 0, Size&

	OUT &H3CE, 4: OUT &H3CF, 3
	BSAVE Sys.Path + "DATA\TEMP\" + TargetFile + ".INT", 0, Size&

	OUT &H3CE, 4: OUT &H3CF, 0

	Mouse.Show

END SUB

