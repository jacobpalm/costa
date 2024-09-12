DEFINT A-Z
OPTION EXPLICIT

DECLARE FUNCTION IconEdit.SaveIcon% ()
DECLARE SUB IconEdit.DrawPixel (X%, Y%, DrawColor%, ForceDraw%)
DECLARE SUB IconEdit.FillArea (X%, Y%, BYVAL FillColor)
DECLARE SUB IconEdit.LoadIcon (IconFile AS STRING)
DECLARE SUB IconEdit.Main (IconToLoad AS STRING)
DECLARE SUB IconEdit.MoveIndicator (Direction%)
DECLARE SUB IconEdit.NewIcon ()
DECLARE SUB IconEdit.Preview ()
DECLARE SUB IconEdit.ShowLoadDialog ()

CONST toolPencil = 0
CONST toolFloodFill = 1

CONST dirLeft = 0
CONST dirRight = 1
CONST dirUp = 2
CONST dirDown = 3
CONST dirStay = 4
CONST dirHide = 5

CONST PixelSize = 9

CONST FilledNeedsCheck = 1
CONST FilledChecked = 2

TYPE IconDataType
    Pixel(31, 31) AS STRING * 1
END TYPE

TYPE IconEditDataType
    Pixel(31, 31) AS INTEGER
END TYPE

TYPE FillMaskType
    Pixel(31, 31) AS INTEGER
END TYPE

DIM SHARED IconData AS IconEditDataType
DIM SHARED IconFileName AS STRING
DIM SHARED KeyboardPosX, KeyboardPosY, KeyboardPosVisible
DIM SHARED IconChanged, PreviewOffsetX, PreviewOffsetY
DIM SHARED DrawAreaOffsetX, DrawAreaOffsetY

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

STACK 6144

Sys.Load

IconEdit.Main COMMAND$

SUB IconEdit.DrawPixel (X, Y, DrawColor, ForceDraw)

  DIM XPos, YPos

  IF X = -1 OR Y = -1 THEN EXIT SUB

  IF NOT IconData.Pixel(X, Y) = DrawColor OR ForceDraw = True THEN

    'DrawAreaOffSet variables are the coords for the top-left corner of
    'the drawing area, and each "pixel" in it is PixelSize times
    'PixelSize pixels in size
    XPos = DrawAreaOffsetX + (X * PixelSize)
    YPos = DrawAreaOffsetY + (Y * PixelSize)

    IconChanged = True
    IconData.Pixel(X, Y) = DrawColor

    LINE (XPos, YPos)-(XPos + PixelSize - 2, YPos + PixelSize - 2), DrawColor, BF
    PSET (PreviewOffsetX + X, PreviewOffsetY + Y), DrawColor

  END IF


END SUB

SUB IconEdit.FillArea (X, Y, BYVAL FillColor)

    'The fillmask holds only pixels changed by flood fill
    DIM FillMask AS FillMaskType

    'Used to koop through FillMask
    DIM CheckX, CheckY

    'Track if pixels are changed in an iteration, so we can exit sub when
    'none are
    DIM PixelsFilled

    'Used for redrawing - if true, draw white pixel with "T"
    DIM FillTransParent

    'If the pixel already has the current color, there's nothing to paint.
    'Wait mouse release and exit.
    IF IconData.Pixel(X, Y) = FillColor THEN
        DO: LOOP WHILE Mouse.Clicked
        EXIT SUB
    END IF
    
    'Color to replace
    DIM ReplaceColor
    ReplaceColor = IconData.Pixel(X, Y)

    'Fill the specified pixel
    IconEdit.DrawPixel X, Y, FillColor, False
    FillMask.Pixel(X, Y) = FilledNeedsCheck
    PixelsFilled = True
    
    'Loop through FillMask as long as pixels are changing in direct
    'neighbours
    DO WHILE PixelsFilled

        PixelsFilled = False

        FOR CheckX = 0 TO 31
            FOR CheckY = 0 TO 31

                IF FillMask.Pixel(CheckX, CheckY) = FilledNeedsCheck THEN

                    'Pixel was filled, check neighbours in all directions

                    'Check left
                    IF CheckX > 0 THEN
                        IF IconData.Pixel(CheckX - 1, CheckY) = ReplaceColor THEN
                            IconEdit.DrawPixel CheckX - 1, CheckY, FillColor, False
                            FillMask.Pixel(CheckX - 1, CheckY) = FilledNeedsCheck
                            PixelsFilled = True
                        END IF
                    END IF

                    'Check right
                    IF CheckX < 31 THEN
                        IF IconData.Pixel(CheckX + 1, CheckY) = ReplaceColor THEN
                            IconEdit.DrawPixel CheckX + 1, CheckY, FillColor, False
                            FillMask.Pixel(CheckX + 1, CheckY) = FilledNeedsCheck
                            PixelsFilled = True
                        END IF
                    END IF

                    'Check up
                    IF CheckY > 0 THEN
                        IF IconData.Pixel(CheckX, CheckY - 1) = ReplaceColor THEN
                            IconEdit.DrawPixel CheckX, CheckY - 1, FillColor, False
                            FillMask.Pixel(CheckX, CheckY - 1) = FilledNeedsCheck
                            PixelsFilled = True
                        END IF
                    END IF

                    'Check down
                    IF CheckY < 31 THEN
                        IF IconData.Pixel(CheckX, CheckY + 1) = ReplaceColor THEN
                            IconEdit.DrawPixel CheckX, CheckY + 1, FillColor, False
                            FillMask.Pixel(CheckX, CheckY + 1) = FilledNeedsCheck
                            PixelsFilled = True
                        END IF
                    END IF

                    'Now that neighbours have been checked, set fill mask to
                    'FilledChecked so that neighbours won't be checked again
                    FillMask.Pixel(CheckX, CheckY) = FilledChecked

                END IF

            NEXT
        NEXT

    LOOP

    'Stick around as long as the mouse is clicked - to avoid fill while mouse
    'is moved around. We only want one fill per click.
    DO: LOOP WHILE Mouse.Clicked

END SUB

SUB IconEdit.LoadIcon (IconToLoad AS STRING)

  DIM ErrMsg, XPos, YPos
  
  IF NOT File.Exists("DATA\IMAGES\" + IconToLoad + ".BSV") THEN
    ErrMsg = Sys.MsgBox("File not found", "Could not open the specified icon." + CHR$(13) + "Verify the filename and try again.", msgError)
    EXIT SUB
  END IF


  IF IconToLoad = IconFileName THEN

    'If nothing has changed and icon is already loaded, just return
    IF IconChanged = False THEN
      EXIT SUB
    END IF

    IF Sys.MsgBox("File already open", "The icon you selected is already opened." + CHR$(13) + "Do you want to discard all changes and reload" + CHR$(13) + "the icon as it was last saved?", msgQuest) = False THEN
      EXIT SUB
    ELSE
      IconChanged = False
    END IF

  END IF

  IF IconChanged = True THEN
    IF Sys.MsgBox("Icon has been modified", "This icon contains unsaved changes. Do you" + CHR$(13) + "want to save it before you load another?", msgQuest) = True THEN
      IF IconEdit.SaveIcon = False THEN
        'If the user said yes to saving, but didn't, exit here
        EXIT SUB
      END IF
    END IF
  END IF


  'We made it this far - load icon

  ON LOCAL ERROR GOTO LoadIconError
  DIM scrBuffer(260)
  DEF SEG = VARSEG(scrBuffer(0))
  BLOAD "DATA\IMAGES\" + IconToLoad + ".BSV", VARPTR(scrBuffer(0))
  DEF SEG
  Mouse.Hide
  PUT (PreviewOffsetX, PreviewOffsetY), scrBuffer, PSET
  ON LOCAL ERROR RESUME NEXT

  IconFileName = IconToLoad

  FOR XPos = 0 TO 31
    FOR YPos = 0 TO 31
      IconEdit.DrawPixel XPos, YPos, POINT(PreviewOffsetX + XPos, PreviewOffsetY + YPos), True
    NEXT
  NEXT
  Mouse.Show
  IconChanged = False

  EXIT SUB

LoadIconError:
  Mouse.Show
  ErrMsg = Sys.MsgBox("Invalid image file", "The icon you selected does not contain a valid icon. The" + CHR$(13) + "file might be damaged, or not an icon file at all.", msgError)
  IconEdit.NewIcon
  EXIT SUB
  RESUME NEXT
END SUB

SUB IconEdit.Main (IconToLoad AS STRING)

  DIM txtDrawArea AS TextboxType
  DIM btnPreview AS ButtonType, btnPencil AS ButtonType
  DIM btnFloodFill AS ButtonType
  DIM btnNew AS ButtonType, btnOpen AS ButtonType, btnSave AS ButtonType
  DIM btnExit AS ButtonType, btnAbout AS ButtonType
  DIM txtColor(0 TO 15) AS TextboxType

  DIM Key$, YPos, XPos, CursorX, CursorY, DrawColor, Void
  DIM ColChk, FillColor, CurrentTool

  Obj.SetSize txtDrawArea.Pos, 175, 44, 290, 290
  Obj.SetSize btnNew.Pos, 2, 2, 92, 22
  Obj.SetSize btnOpen.Pos, 101, 2, 92, 22
  Obj.SetSize btnSave.Pos, 200, 2, 92, 22
  Obj.SetSize btnAbout.Pos, 446, 2, 92, 22
  Obj.SetSize btnExit.Pos, 545, 2, 92, 22

  btnNew.Caption = "õNew"
  btnOpen.Caption = "õLoad"
  btnSave.Caption = "õSave"
  btnAbout.Caption = "õAbout..."
  btnExit.Caption = "Eõxit"

  Obj.SetSize btnPencil.Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 12, txtDrawArea.Pos.Top + 14, 52, 22
  btnPencil.Caption = "Põencil"

  Obj.SetSize btnFloodFill.Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 12, txtDrawArea.Pos.Top + 40, 52, 22
  btnFloodFill.Caption = "õFill"

  Obj.SetSize btnPreview.Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 12, btnFloodFill.Pos.Top + 51, 52, 52
  btnPreview.Transparent = True

  PreviewOffsetX = btnPreview.Pos.Left + 10
  PreviewOffsetY = btnPreview.Pos.Top + 10
  DrawAreaOffsetX = txtDrawArea.Pos.Left + 2
  DrawAreaOffsetY = txtDrawArea.Pos.Top + 2
  
  Mouse.Hide
  Obj.DrawMenu
  LINE (0, 29)-(639, 349), Theme.Window, BF
  Obj.DrawTxt txtDrawArea, "", False
  Obj.DrawBtn btnPencil, True
  Obj.DrawBtn btnFloodFill, False
  Obj.DrawBtn btnPreview, False
  Obj.DrawBtn btnNew, False
  Obj.DrawBtn btnOpen, False
  Obj.DrawBtn btnSave, False
  Obj.DrawBtn btnAbout, False
  Obj.DrawBtn btnExit, False

  FOR YPos = 0 TO 7
    Obj.SetSize txtColor(YPos).Pos, txtDrawArea.Pos.Left - 51, txtDrawArea.Pos.Top + (YPos * 21) + 14, 20, 20
    Obj.DrawTxt txtColor(YPos), "", False
    LINE (txtColor(YPos).Pos.Left + 2, txtColor(YPos).Pos.Top + 2)-(txtColor(YPos).Pos.Left + txtColor(YPos).Pos.Width - 2, txtColor(YPos).Pos.Top + txtColor(YPos).Pos.Height - 2), YPos, BF
  NEXT
  FOR YPos = 8 TO 15
    Obj.SetSize txtColor(YPos).Pos, txtDrawArea.Pos.Left - 30, txtDrawArea.Pos.Top + ((YPos - 8) * 21) + 14, 20, 20
    Obj.DrawTxt txtColor(YPos), "", False
    LINE (txtColor(YPos).Pos.Left + 2, txtColor(YPos).Pos.Top + 2)-(txtColor(YPos).Pos.Left + txtColor(YPos).Pos.Width - 2, txtColor(YPos).Pos.Top + txtColor(YPos).Pos.Height - 2), YPos, BF
  NEXT
  
  'Selection marker in color 0
  LINE (txtColor(DrawColor).Pos.Left + 4, txtColor(DrawColor).Pos.Top + 4)-(txtColor(DrawColor).Pos.Left + txtColor(DrawColor).Pos.Width - 4, txtColor(DrawColor).Pos.Top + txtColor(DrawColor).Pos.Height - 4), 8, B
  LINE (txtColor(DrawColor).Pos.Left + 5, txtColor(DrawColor).Pos.Top + 5)-(txtColor(DrawColor).Pos.Left + txtColor(DrawColor).Pos.Width - 5, txtColor(DrawColor).Pos.Top + txtColor(DrawColor).Pos.Height - 5), 15, B

  LINE (btnPreview.Pos.Left + 2, btnPreview.Pos.Top + 2)-(btnPreview.Pos.Left + btnPreview.Pos.Width - 2, btnPreview.Pos.Top + btnPreview.Pos.Height - 2), 15, BF
  LINE (PreviewOffsetX - 1, PreviewOffsetY - 1)-(PreviewOffsetX + 32, PreviewOffsetY - 1), Theme.Light
  LINE (PreviewOffsetX - 1, PreviewOffsetY)-(PreviewOffsetX - 1, PreviewOffsetY + 32), Theme.Light
  LINE (PreviewOffsetX, PreviewOffsetY + 32)-(PreviewOffsetX + 32, PreviewOffsetY + 32), Theme.Shadow
  LINE (PreviewOffsetX + 32, PreviewOffsetY)-(PreviewOffsetX + 32, PreviewOffsetY + 31), Theme.Shadow

  'Draw grid in drawing area
  FOR YPos = 0 TO 31
    LINE (txtDrawArea.Pos.Left + 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize))-(txtDrawArea.Pos.Left + txtDrawArea.Pos.Width - 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize)), 8
    LINE (txtDrawArea.Pos.Left + 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize))-(txtDrawArea.Pos.Left + txtDrawArea.Pos.Width - 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize)), 0, , &HAAAA
  NEXT
  FOR XPos = 0 TO 31
    LINE (txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + 2)-(txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + txtDrawArea.Pos.Height - 2), 8
    LINE (txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + 2)-(txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + txtDrawArea.Pos.Height - 2), 0, , &HAAAA
  NEXT

  Font.Print "õPreview", btnPreview.Pos.Left, btnPreview.Pos.Top - 15, Theme.WindowText, FontHeading
  Font.Print "õColor", txtColor(0).Pos.Left, txtDrawArea.Pos.Top, Theme.WindowText, FontHeading
  Font.Print "Tools", txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 12, txtDrawArea.Pos.Top, Theme.WindowText, FontHeading
  Mouse.Show

  KeyboardPosX = 16
  KeyboardPosY = 16

  IF IconToLoad = "" THEN
    IconEdit.NewIcon
  ELSE
    IconEdit.LoadIcon IconToLoad
  END IF

  'Main "event" loop
  DO
    Key$ = LCASE$(INKEY$)

    IF Mouse.InArea(txtDrawArea.Pos) THEN
      Mouse.Poll
      CursorX = (MouseX - (txtDrawArea.Pos.Left + 7)) / PixelSize
      CursorY = (MouseY - (txtDrawArea.Pos.Top + 7)) / PixelSize
      IF CursorX < 0 THEN CursorX = 0
      IF CursorY < 0 THEN CursorY = 0
      IF CursorX > 31 THEN CursorX = 31
      IF CursorY > 31 THEN CursorY = 31
    ELSE
      CursorX = -1
      CursorY = -1
    END IF

    IF Obj.BtnClick(btnNew) OR Key$ = "n" THEN
      IF IconChanged = True THEN
        IF Sys.MsgBox("Icon has been modified", "This icon contains unsaved changes. Do you" + CHR$(13) + "want to save it before you make a new?", msgQuest) = True THEN
          IF IconEdit.SaveIcon THEN
            IconEdit.NewIcon
          END IF
        ELSE
          IconEdit.NewIcon
        END IF
      ELSE
        IconEdit.NewIcon
      END IF
    END IF

    IF Obj.BtnClick(btnSave) OR Key$ = "s" THEN
      Void = IconEdit.SaveIcon
    END IF

    IF Obj.BtnClick(btnOpen) OR Key$ = "l" THEN
      IconEdit.ShowLoadDialog
    END IF

    IF Obj.BtnClick(btnAbout) OR Key$ = "a" THEN
      Sys.AboutBox "Icon Editor", "Jacob Palm", "PAINT"
    END IF

    IF Obj.BtnClick(btnExit) OR Key$ = "x" THEN
      IF IconChanged = True THEN
        IF Sys.MsgBox("Icon has been modified", "This icon contains unsaved changes. Do you" + CHR$(13) + "want to save it before you exit?", msgQuest) = True THEN
          IF IconEdit.SaveIcon = True THEN END
        ELSE
          END
        END IF
      ELSE
        END
      END IF
    END IF

    IF Obj.BtnClick(btnPreview) OR Key$ = "p" THEN
      IconEdit.Preview
    END IF

    IF (Mouse.Clicked AND Mouse.InArea(btnPencil.Pos)) OR Key$ = "e" THEN
      IF NOT CurrentTool = toolPencil THEN
        Mouse.Hide
        Obj.DrawBtn btnPencil, True
        Obj.DrawBtn btnFloodFill, False
        CurrentTool = toolPencil
        Mouse.Show
        DO: LOOP WHILE Mouse.Clicked
      END IF
    END IF

    IF (Mouse.Clicked AND Mouse.InArea(btnFloodFill.Pos)) OR Key$ = "f" THEN
      IF NOT CurrentTool = toolFloodFill THEN
        Mouse.Hide
        Obj.DrawBtn btnPencil, False
        Obj.DrawBtn btnFloodFill, True
        CurrentTool = toolFloodFill
        Mouse.Show
        DO: LOOP WHILE Mouse.Clicked
      END IF
    END IF

    IF Key$ = "c" THEN
      Mouse.Hide
      'Remove selection marker from current color
      LINE (txtColor(DrawColor).Pos.Left + 4, txtColor(DrawColor).Pos.Top + 4)-(txtColor(DrawColor).Pos.Left + txtColor(DrawColor).Pos.Width - 4, txtColor(DrawColor).Pos.Top + txtColor(DrawColor).Pos.Height - 4), DrawColor, BF

      'Change color according to key pressed
      DrawColor = DrawColor + 1
      IF DrawColor > 15 THEN DrawColor = 0

      'Draw new selection marker
      LINE (txtColor(DrawColor).Pos.Left + 4, txtColor(DrawColor).Pos.Top + 4)-(txtColor(DrawColor).Pos.Left + txtColor(DrawColor).Pos.Width - 4, txtColor(DrawColor).Pos.Top + txtColor(DrawColor).Pos.Height - 4), 8, B
      LINE (txtColor(DrawColor).Pos.Left + 5, txtColor(DrawColor).Pos.Top + 5)-(txtColor(DrawColor).Pos.Left + txtColor(DrawColor).Pos.Width - 5, txtColor(DrawColor).Pos.Top + txtColor(DrawColor).Pos.Height - 5), 15, B
      Mouse.Show
    END IF

    IF Key$ = CHR$(0) + "h" THEN
      KeyboardPosVisible = True
      IconEdit.MoveIndicator dirUp
    END IF

    'Down arrow
    IF Key$ = CHR$(0) + "p" THEN
      KeyboardPosVisible = True
      IconEdit.MoveIndicator dirDown
    END IF

    'Left arrow
    IF Key$ = CHR$(0) + "k" THEN
      KeyboardPosVisible = True
      IconEdit.MoveIndicator dirLeft
    END IF

    'Right arrow
    IF Key$ = CHR$(0) + "m" THEN
      KeyboardPosVisible = True
      IconEdit.MoveIndicator dirRight
    END IF

    'Enter or space
    IF Key$ = CHR$(13) OR Key$ = CHR$(32) THEN
      IF KeyboardPosVisible THEN
        SELECT CASE CurrentTool
          CASE toolPencil
            Mouse.Hide
            IconEdit.DrawPixel KeyboardPosX, KeyboardPosY, DrawColor, False
            Mouse.Show
          CASE toolFloodFill
            Mouse.Hide
            IconEdit.FillArea KeyboardPosX, KeyboardPosY, DrawColor
            'After flood fill, switch back to the pencil tools
            Obj.DrawBtn btnPencil, True
            Obj.DrawBtn btnFloodFill, False
            CurrentTool = toolPencil
            Mouse.Show
        END SELECT
        IconEdit.MoveIndicator dirStay
      ELSE
        KeyboardPosVisible = True
        IconEdit.MoveIndicator dirStay
      END IF
    END IF

    FOR ColChk = 0 TO 15
      IF Obj.TxtClick(txtColor(ColChk)) THEN
        IF NOT DrawColor = ColChk THEN
          Mouse.Hide
          'Remove selection marker
          LINE (txtColor(DrawColor).Pos.Left + 4, txtColor(DrawColor).Pos.Top + 4)-(txtColor(DrawColor).Pos.Left + txtColor(DrawColor).Pos.Width - 4, txtColor(DrawColor).Pos.Top + txtColor(DrawColor).Pos.Height - 4), DrawColor, BF

          DrawColor = ColChk
          'Draw new selection marker
          LINE (txtColor(DrawColor).Pos.Left + 4, txtColor(DrawColor).Pos.Top + 4)-(txtColor(DrawColor).Pos.Left + txtColor(DrawColor).Pos.Width - 4, txtColor(DrawColor).Pos.Top + txtColor(DrawColor).Pos.Height - 4), 8, B
          LINE (txtColor(DrawColor).Pos.Left + 5, txtColor(DrawColor).Pos.Top + 5)-(txtColor(DrawColor).Pos.Left + txtColor(DrawColor).Pos.Width - 5, txtColor(DrawColor).Pos.Top + txtColor(DrawColor).Pos.Height - 5), 15, B
          Mouse.Show
        END IF
      END IF
    NEXT



    IF Mouse.Clicked AND CursorX > -1 AND CursorY > -1 THEN

      'Mouse clicked in drawing area

      IF NOT KeyboardPosX = CursorX OR NOT KeyboardPosY = CursorY THEN
        IconEdit.MoveIndicator dirHide
      END IF

      SELECT CASE CurrentTool
        CASE toolPencil
          DO
            IF NOT IconData.Pixel(CursorX, CursorY) = DrawColor THEN
              Mouse.Hide
              IconEdit.DrawPixel CursorX, CursorY, DrawColor, False
              Mouse.Show
            END IF

            IF Mouse.InArea(txtDrawArea.Pos) THEN
                Mouse.Poll
                CursorX = (MouseX - (txtDrawArea.Pos.Left + 7)) / PixelSize
                CursorY = (MouseY - (txtDrawArea.Pos.Top + 7)) / PixelSize
                IF CursorX < 0 THEN CursorX = 0
                IF CursorY < 0 THEN CursorY = 0
                IF CursorX > 31 THEN CursorX = 31
                IF CursorY > 31 THEN CursorY = 31
            ELSE
                CursorX = -1
                CursorY = -1
            END IF
          LOOP WHILE Mouse.Clicked

          'Make sure indicator will appear where mouse was lifted
          KeyboardPosX = CursorX
          KeyboardPosY = CursorY

        CASE toolFloodFill
          Mouse.Hide
          IconEdit.FillArea CursorX, CursorY, DrawColor
          'After flood fill, switch back to the pencil tools
          Obj.DrawBtn btnPencil, True
          Obj.DrawBtn btnFloodFill, False
          CurrentTool = toolPencil
          Mouse.Show

      END SELECT

    END IF

  LOOP


END SUB

SUB IconEdit.MoveIndicator (Direction)

    DIM XPos, YPos

    IF KeyboardPosVisible OR Direction = dirHide THEN
      'Remove indicator from previous pixel
      IF KeyboardPosX > -1 AND KeyboardPosY > -1 THEN
        XPos = DrawAreaOffsetX + (KeyboardPosX * PixelSize)
        YPos = DrawAreaOffsetY + (KeyboardPosY * PixelSize)
        Mouse.Hide
        LINE (XPos, YPos)-(XPos + PixelSize - 2, YPos + PixelSize - 2), IconData.Pixel(KeyboardPosX, KeyboardPosY), BF
        Mouse.Show
      END IF
    END IF

    IF KeyboardPosVisible = False OR Direction = dirHide THEN EXIT SUB

    SELECT CASE Direction
      CASE dirUp
        KeyboardPosY = KeyboardPosY - 1
      CASE dirDown
        KeyboardPosY = KeyboardPosY + 1
      CASE dirLeft
        KeyboardPosX = KeyboardPosX - 1
      CASE dirRight
        KeyboardPosX = KeyboardPosX + 1
    END SELECT
    
    IF KeyboardPosY < 0 THEN KeyboardPosY = 0
    IF KeyboardPosY > 31 THEN KeyboardPosY = 31
    IF KeyboardPosX < 0 THEN KeyboardPosX = 0
    IF KeyboardPosX > 31 THEN KeyboardPosX = 31

    XPos = DrawAreaOffsetX + (KeyboardPosX * PixelSize)
    YPos = DrawAreaOffsetY + (KeyboardPosY * PixelSize)
    Mouse.Hide
    LINE (XPos + 1, YPos + 1)-(XPos + 6, YPos + 6), 8, B
    LINE (XPos + 2, YPos + 2)-(XPos + 5, YPos + 5), 15, B
    Mouse.Show

END SUB

SUB IconEdit.NewIcon ()

  DIM XPos, YPos
  DIM WindowTitle AS STRING

  'Redraw window title
  IconFileName = ""

  Mouse.Hide

  'Draw all pixels white
  FOR XPos = 0 TO 31
    FOR YPos = 0 TO 31
      IconEdit.DrawPixel XPos, YPos, 15, True
    NEXT
  NEXT

  Mouse.Show
  IconChanged = False

END SUB

SUB IconEdit.Preview ()

  DIM winPreview AS WindowType, btnClose AS ButtonType
  DIM txtPreview AS TextboxType
  DIM Key$, XPos, YPos, Void
  DIM scrBuffer(341)

  Obj.SetSize winPreview.Pos, sizeCenter, sizeCenter, 271, 303
  Obj.SetSize btnClose.Pos, winPreview.Pos.Left + winPreview.Pos.Width - 112, winPreview.Pos.Top + winPreview.Pos.Height - 34, 100, 22
  Obj.SetSize txtPreview.Pos, winPreview.Pos.Left + 12, winPreview.Pos.Top + 12, 247, 247

  btnClose.Caption = "õClose"

  Mouse.Hide
  PCOPY 0, 1
  GET (PreviewOffsetX - 1, PreviewOffsetY - 1)-(PreviewOffsetX + 32, PreviewOffsetY + 32), scrBuffer

  Obj.DrawWin winPreview
  Obj.DrawBtn btnClose, False
  Obj.DrawTxt txtPreview, "", False

  LINE (txtPreview.Pos.Left + 2, txtPreview.Pos.Top + 2)-(txtPreview.Pos.Left + 62, txtPreview.Pos.Top + 62), 0, BF
  LINE (txtPreview.Pos.Left + 63, txtPreview.Pos.Top + 2)-(txtPreview.Pos.Left + 123, txtPreview.Pos.Top + 62), 1, BF
  LINE (txtPreview.Pos.Left + 124, txtPreview.Pos.Top + 2)-(txtPreview.Pos.Left + 184, txtPreview.Pos.Top + 62), 2, BF
  LINE (txtPreview.Pos.Left + 185, txtPreview.Pos.Top + 2)-(txtPreview.Pos.Left + 245, txtPreview.Pos.Top + 62), 3, BF
  LINE (txtPreview.Pos.Left + 2, txtPreview.Pos.Top + 63)-(txtPreview.Pos.Left + 62, txtPreview.Pos.Top + 123), 8, BF
  LINE (txtPreview.Pos.Left + 63, txtPreview.Pos.Top + 63)-(txtPreview.Pos.Left + 123, txtPreview.Pos.Top + 123), 9, BF
  LINE (txtPreview.Pos.Left + 124, txtPreview.Pos.Top + 63)-(txtPreview.Pos.Left + 184, txtPreview.Pos.Top + 123), 10, BF
  LINE (txtPreview.Pos.Left + 185, txtPreview.Pos.Top + 63)-(txtPreview.Pos.Left + 245, txtPreview.Pos.Top + 123), 11, BF
  LINE (txtPreview.Pos.Left + 2, txtPreview.Pos.Top + 124)-(txtPreview.Pos.Left + 62, txtPreview.Pos.Top + 184), 4, BF
  LINE (txtPreview.Pos.Left + 63, txtPreview.Pos.Top + 124)-(txtPreview.Pos.Left + 123, txtPreview.Pos.Top + 184), 5, BF
  LINE (txtPreview.Pos.Left + 124, txtPreview.Pos.Top + 124)-(txtPreview.Pos.Left + 184, txtPreview.Pos.Top + 184), 6, BF
  LINE (txtPreview.Pos.Left + 185, txtPreview.Pos.Top + 124)-(txtPreview.Pos.Left + 245, txtPreview.Pos.Top + 184), 7, BF
  LINE (txtPreview.Pos.Left + 2, txtPreview.Pos.Top + 185)-(txtPreview.Pos.Left + 62, txtPreview.Pos.Top + 245), 12, BF
  LINE (txtPreview.Pos.Left + 63, txtPreview.Pos.Top + 185)-(txtPreview.Pos.Left + 123, txtPreview.Pos.Top + 245), 13, BF
  LINE (txtPreview.Pos.Left + 124, txtPreview.Pos.Top + 185)-(txtPreview.Pos.Left + 184, txtPreview.Pos.Top + 245), 14, BF
  LINE (txtPreview.Pos.Left + 185, txtPreview.Pos.Top + 185)-(txtPreview.Pos.Left + 245, txtPreview.Pos.Top + 245), 15, BF

  FOR XPos = 2 TO 185 STEP 61
    FOR YPos = 2 TO 185 STEP 61
      LINE (PreviewOffsetX - 1, PreviewOffsetY - 1)-(PreviewOffsetX + 32, PreviewOffsetY - 1), Theme.Light
      LINE (PreviewOffsetX - 1, PreviewOffsetY)-(PreviewOffsetX - 1, PreviewOffsetY + 32), Theme.Light
      LINE (PreviewOffsetX, PreviewOffsetY + 32)-(PreviewOffsetX + 32, PreviewOffsetY + 32), Theme.Shadow
      LINE (PreviewOffsetX + 32, PreviewOffsetY)-(PreviewOffsetX + 32, PreviewOffsetY + 31), Theme.Shadow
      PUT (txtPreview.Pos.Left + XPos + 16, txtPreview.Pos.Top + YPos + 16), scrBuffer, PSET
    NEXT
  NEXT
  Mouse.Show

  DO
    Key$ = INKEY$

    IF Obj.BtnClick(btnClose) OR Key$ = "c" OR Key$ = CHR$(27) THEN
      EXIT DO
    END IF
  LOOP

  Mouse.Hide
  PCOPY 1, 0
  Mouse.Show
  EXIT SUB

PreviewError:
  Mouse.Hide
  PCOPY 1, 0
  Mouse.Show
  Void = Sys.MsgBox("Could not preview icon", "An error occured while previewing your icon, while saving a temporary copy." + CHR$(13) + "Make sure the disk is not full or write-protected, and try again.", msgError)
  EXIT SUB
  RESUME NEXT

END SUB

FUNCTION IconEdit.SaveIcon ()

  DIM SaveAs AS STRING, WindowTitle AS STRING
  DIM FileHandle, XPos, YPos, DoSave

TopOfSave:

  SaveAs = Sys.InputBox("Save icon file", "Type a name for the icon file below, without path or" + CHR$(13) + "extension (8 letters max, for example: MYICON).", "PAINT", IconFileName)
  IF SaveAs = "" THEN EXIT FUNCTION

  IF LEN(SaveAs) > 8 THEN
    FileHandle = Sys.MsgBox("Invalid file name", "The filename you specified was too long." + CHR$(13) + "Do not type a path or extension, only a filename" + CHR$(13) + "with a maximun lenght of 8 characters.", msgError)
    EXIT FUNCTION
  END IF

  IF File.Exists("DATA\IMAGES\" + SaveAs + ".BSV") THEN
    IF NOT UCASE$(SaveAs) = IconFileName THEN
      DoSave = Sys.MsgBox("File already exists", "The specified icon file already exists. Do you want" + CHR$(13) + "to owerwrite it with this icon?", msgQuest)
      IF DoSave = False THEN GOTO TopOfSave
    END IF

    KILL "DATA\IMAGES\" + SaveAs + ".BSV"
  END IF

  ON LOCAL ERROR GOTO SaveIconError
  DIM scrBuffer(260)
  Mouse.Hide
  GET (PreviewOffsetX, PreviewOffsetY)-(PreviewOffsetX + 31, PreviewOffsetY + 31), scrBuffer
  Mouse.Show
  DEF SEG = VARSEG(scrBuffer(0))
  BSAVE "DATA\IMAGES\" + SaveAs + ".BSV", VARPTR(scrBuffer(0)), UBOUND(scrBuffer) * 2
  DEF SEG
  ON LOCAL ERROR GOTO 0

  IconFileName = UCASE$(SaveAs)

  IconEdit.SaveIcon = True
  IconChanged = False
  EXIT FUNCTION

SaveIconError:
  FileHandle = Sys.MsgBox("Could not save icon", "An error occured while saving your icon, and it was not saved." + CHR$(13) + "Make sure the disk is not full or write-protected, and try again.", msgError)
  IconEdit.SaveIcon = False
  EXIT FUNCTION
  RESUME NEXT
END FUNCTION

SUB IconEdit.ShowLoadDialog ()

  DIM winSelect AS WindowType
  DIM imgPreview AS ImageType
  DIM btnNext AS ButtonType, btnPrev AS ButtonType, btnCancel AS ButtonType
  DIM btnLoad AS ButtonType

  DIM IconFiles() AS STRING
  DIM IconIndex
  DIM Key$
  REDIM IconFiles(0) AS STRING

  Mouse.Hide
  PCOPY 0, 1
  Mouse.Show
  Sys.ShowLoading

  IconFiles(0) = DIR$("DATA\IMAGES\*.BSV")
  IF IconFiles(0) = "" THEN
    DIM Void
    Void = Sys.MsgBox("No icons found", "It appears that no icons exist - create a new one" + CHR$(13) + "by clicking the ""New"" button in the main window.", msgInfo)
    EXIT SUB
  END IF
  IconFiles(0) = LEFT$(IconFiles(0), LEN(IconFiles(0)) - 4)
  IconIndex = 0

  DO
    REDIM PRESERVE IconFiles(0 TO UBOUND(IconFiles) + 1) AS STRING
    IconFiles(UBOUND(IconFiles)) = DIR$
    IF IconFiles(UBOUND(IconFiles)) = "" THEN
      REDIM PRESERVE IconFiles(0 TO UBOUND(IconFiles) - 1) AS STRING
      EXIT DO
    END IF
    IconFiles(UBOUND(IconFiles)) = LEFT$(IconFiles(UBOUND(IconFiles)), LEN(IconFiles(UBOUND(IconFiles))) - 4)
  LOOP


  Obj.SetSize winSelect.Pos, sizeCenter, sizeCenter, 154, 132
  Obj.SetSize btnLoad.Pos, winSelect.Pos.Left + 51, winSelect.Pos.Top + 32, 52, 52
  Obj.SetSize btnPrev.Pos, winSelect.Pos.Left + 15, winSelect.Pos.Top + 48, 22, 22
  Obj.SetSize btnNext.Pos, winSelect.Pos.Left + 117, winSelect.Pos.Top + 48, 22, 22
  Obj.SetSize btnCancel.Pos, winSelect.Pos.Left + 15, winSelect.Pos.Top + 95, 124, 22
  Obj.SetSize imgPreview.Pos, btnLoad.Pos.Left + 11, btnLoad.Pos.Top + 11, -1, -1

  btnPrev.Caption = "<"
  btnNext.Caption = ">"
  btnCancel.Caption = "õCancel"
  btnLoad.Transparent = True
  imgPreview.ImageFile = IconFiles(0)

  Mouse.Hide
  Obj.DrawWin winSelect
  Obj.DrawBtn btnPrev, 0
  Obj.DrawBtn btnLoad, 0
  Obj.DrawBtn btnNext, 0
  Obj.DrawBtn btnCancel, 0
  Obj.DrawImg imgPreview

  Font.Print IconFiles(IconIndex), (winSelect.Pos.Left + (winSelect.Pos.Width / 2)) - (Font.GetWidth(IconFiles(IconIndex), FontHeading) / 2), winSelect.Pos.Top + 12, Theme.WindowText, FontHeading
  Mouse.Show

  DO
    Key$ = LCASE$(INKEY$)

    IF Obj.BtnClick(btnCancel) OR Key$ = CHR$(27) OR Key$ = "c" THEN
      Mouse.Hide
      PCOPY 1, 0
      Mouse.Show
      EXIT SUB
    END IF

    IF Obj.BtnClick(btnPrev) OR Key$ = CHR$(0) + "k" THEN 'Left arrow
      IconIndex = IconIndex - 1
      IF IconIndex = -1 THEN IconIndex = UBOUND(IconFiles)
      imgPreview.ImageFile = IconFiles(IconIndex)
      Mouse.Hide
      LINE (btnLoad.Pos.Left + 11, btnLoad.Pos.Top + 11)-(btnLoad.Pos.Left + 42, btnLoad.Pos.Top + 42), Theme.Window, BF
      LINE (winSelect.Pos.Left + 10, winSelect.Pos.Top + 12)-(winSelect.Pos.Left + winSelect.Pos.Width - 10, winSelect.Pos.Top + 21), Theme.Window, BF
      Font.Print IconFiles(IconIndex), (winSelect.Pos.Left + (winSelect.Pos.Width / 2)) - (Font.GetWidth(IconFiles(IconIndex), FontHeading) / 2), winSelect.Pos.Top + 12, Theme.WindowText, FontHeading
      Obj.DrawImg imgPreview
      Mouse.Show
    END IF

    IF Obj.BtnClick(btnNext) OR Key$ = CHR$(0) + "m" THEN 'Right arrow
      IconIndex = IconIndex + 1
      IF IconIndex > UBOUND(IconFiles) THEN IconIndex = 0
      imgPreview.ImageFile = IconFiles(IconIndex)
      Mouse.Hide
      LINE (btnLoad.Pos.Left + 11, btnLoad.Pos.Top + 11)-(btnLoad.Pos.Left + 42, btnLoad.Pos.Top + 42), Theme.Window, BF
      LINE (winSelect.Pos.Left + 10, winSelect.Pos.Top + 12)-(winSelect.Pos.Left + winSelect.Pos.Width - 10, winSelect.Pos.Top + 21), Theme.Window, BF
      Font.Print IconFiles(IconIndex), (winSelect.Pos.Left + (winSelect.Pos.Width / 2)) - (Font.GetWidth(IconFiles(IconIndex), FontHeading) / 2), winSelect.Pos.Top + 12, Theme.WindowText, FontHeading
      Obj.DrawImg imgPreview
      Mouse.Show
    END IF

    IF Obj.BtnClick(btnLoad) OR Key$ = CHR$(13) THEN
      Mouse.Hide
      PCOPY 1, 0
      Mouse.Show
      IconEdit.LoadIcon (IconFiles(IconIndex))
      EXIT SUB
    END IF

  LOOP


END SUB

