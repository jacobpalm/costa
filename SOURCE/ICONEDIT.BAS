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
DECLARE SUB IconEdit.SetTitle ()
DECLARE SUB IconEdit.ShowLoadDialog ()

CONST toolPencil = 0
CONST toolFloodFill = 1

CONST dirLeft = 0
CONST dirRight = 1
CONST dirUp = 2
CONST dirDown = 3
CONST dirStay = 4
CONST dirHide = 5

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
DIM SHARED IconChanged

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

STACK 5120

Sys.Load

IF NOT COMMAND$ = "/?" AND NOT COMMAND$ = "/VER" AND NOT COMMAND$ = "/DEV" THEN
    'Icon specified as param, pass along
    IconEdit.Main COMMAND$
ELSE
    IconEdit.Main ""
END IF

SUB IconEdit.DrawPixel (X, Y, DrawColor, ForceDraw)

    DIM XPos, YPos

    IF X = -1 OR Y = -1 THEN EXIT SUB

    IF NOT IconData.Pixel(X, Y) = DrawColor OR ForceDraw = True THEN

        '58 and 44 are the coords for the top-left corner of the drawing area
        'and each "pixel" in it is 13x13 pixels
        XPos = 58 + (X * 13)
        YPos = 44 + (Y * 13)

        IconChanged = True
        IconData.Pixel(X, Y) = DrawColor

        Mouse.Hide
        IF DrawColor > -1 THEN
            LINE (XPos, YPos)-(XPos + 11, YPos + 11), DrawColor, BF
            PSET (514 + X, 269 + Y), DrawColor
        ELSE
            LINE (XPos, YPos)-(XPos + 11, YPos + 11), 15, BF
            LINE (XPos, YPos + 11)-(XPos + 11, YPos), 7
            PSET (514 + X, 269 + Y), 15
        END IF
        Mouse.Show

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

    'Drawing routines hide mouse automatically, but we do it anyway since
    'there might be cursor flicker if filling many pixels
    Mouse.Hide

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

    Mouse.Show

    
    'Stick around as long as the mouse is clicked - to avoid fill while mouse
    'is moved around. We only want one fill per click.
    DO: LOOP WHILE Mouse.Clicked

END SUB

SUB IconEdit.LoadIcon (IconToLoad AS STRING)

    DIM ErrMsg, XPos, YPos
    DIM Header AS STRING * 9
    DIM WindowTitle AS STRING
    DIM IconLoadData AS IconEditDataType
    
    IF NOT File.Exists(Sys.Path + "DATA\IMAGES\" + IconToLoad + ".BSV") THEN
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
    DEF SEG = VARSEG(IconLoadData.Pixel(0, 0))
    BLOAD Sys.Path + "DATA\IMAGES\" + IconToLoad + ".BSV", VARPTR(IconLoadData.Pixel(0, 0))
    DEF SEG
    ON LOCAL ERROR RESUME NEXT

    IconFileName = IconToLoad
    IconEdit.SetTitle
    Mouse.Hide
    FOR XPos = 0 TO 31
        FOR YPos = 0 TO 31
            IconEdit.DrawPixel XPos, YPos, IconLoadData.Pixel(XPos, YPos), True
        NEXT
    NEXT
    Mouse.Show
    IconChanged = False

    EXIT SUB

LoadIconError:
    ErrMsg = Sys.MsgBox("Invalid image file", "The icon you selected does not contain a valid icon. The" + CHR$(13) + "file might be damaged, or not an icon file at all.", msgError)
    IconEdit.NewIcon
    EXIT SUB
    RESUME NEXT

END SUB

SUB IconEdit.Main (IconToLoad AS STRING)

    DIM winMain AS WindowType, txtDrawArea AS TextboxType
    DIM btnPreview AS ButtonType, btnPencil AS ButtonType
    DIM btnFloodFill AS ButtonType
    DIM btnNew AS ButtonType, btnOpen AS ButtonType, btnSave AS ButtonType
    DIM btnExit AS ButtonType
    DIM txtColor(-1 TO 15) AS TextboxType
    
    DIM Key$, YPos, XPos, CursorX, CursorY, DrawColor, void
    DIM ColChk, FillColor, CurrentTool

    Obj.SetSize winMain.Pos, 48, 11, 544, 458
    Obj.SetSize txtDrawArea.Pos, winMain.Pos.Left + 8, winMain.Pos.Top + 31, 418, 418

    Obj.SetSize btnPreview.Pos, winMain.Pos.Left + txtDrawArea.Pos.Width + 38, winMain.Pos.Top + 248, 52, 52
    btnPreview.Transparent = True

    Obj.SetSize btnNew.Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 10, winMain.Pos.Top + winMain.Pos.Height - 127, 100, 22
    btnNew.Caption = "New"
    btnNew.HotKey = 1
    
    Obj.SetSize btnOpen.Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 10, winMain.Pos.Top + winMain.Pos.Height - 95, 100, 22
    btnOpen.Caption = "Load"
    btnOpen.HotKey = 1

    Obj.SetSize btnSave.Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 10, winMain.Pos.Top + winMain.Pos.Height - 63, 100, 22
    btnSave.Caption = "Save"
    btnSave.HotKey = 1

    Obj.SetSize btnExit.Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 10, winMain.Pos.Top + winMain.Pos.Height - 31, 100, 22
    btnExit.Caption = "Exit"
    btnExit.HotKey = 2

    Obj.SetSize btnPencil.Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 60, txtDrawArea.Pos.Top + 14, 50, 22
    btnPencil.Caption = "Pencil"
    btnPencil.HotKey = 2

    Obj.SetSize btnFloodFill.Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 60, txtDrawArea.Pos.Top + 40, 50, 22
    btnFloodFill.Caption = "Fill"
    btnFloodFill.HotKey = 1

    Obj.SetSize txtColor(-1).Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 10, txtDrawArea.Pos.Top + 166, 37, 18
    
    Obj.DrawWin winMain
    Obj.DrawTxt txtDrawArea, "", False
    Obj.DrawBtn btnPencil, True
    Obj.DrawBtn btnFloodFill, False
    Obj.DrawBtn btnPreview, False
    Obj.DrawBtn btnNew, False
    Obj.DrawBtn btnOpen, False
    Obj.DrawBtn btnSave, False
    Obj.DrawBtn btnExit, False
    Obj.DrawTxt txtColor(-1), "", False

    Font.Print "Colors", txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 10, txtDrawArea.Pos.Top, SystemTheme.WindowText, fontHeading
    Font.Print "Tools", txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 60, txtDrawArea.Pos.Top, SystemTheme.WindowText, fontHeading
    Mouse.Hide
    LINE (txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 9, txtDrawArea.Pos.Top + 10)-(txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 16, txtDrawArea.Pos.Top + 10), SystemTheme.WindowText
    
    FOR YPos = 0 TO 7
        Obj.SetSize txtColor(YPos).Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 10, txtDrawArea.Pos.Top + (YPos * 19) + 14, 18, 18
        Obj.DrawTxt txtColor(YPos), "", False
        LINE (txtColor(YPos).Pos.Left + 2, txtColor(YPos).Pos.Top + 2)-(txtColor(YPos).Pos.Left + txtColor(YPos).Pos.Width - 2, txtColor(YPos).Pos.Top + txtColor(YPos).Pos.Height - 2), YPos, BF
    NEXT
    FOR YPos = 8 TO 15
        Obj.SetSize txtColor(YPos).Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 29, txtDrawArea.Pos.Top + ((YPos - 8) * 19) + 14, 18, 18
        Obj.DrawTxt txtColor(YPos), "", False
        LINE (txtColor(YPos).Pos.Left + 2, txtColor(YPos).Pos.Top + 2)-(txtColor(YPos).Pos.Left + txtColor(YPos).Pos.Width - 2, txtColor(YPos).Pos.Top + txtColor(YPos).Pos.Height - 2), YPos, BF
    NEXT

    'Selection marker in color 0
    LINE (txtColor(DrawColor).Pos.Left + 4, txtColor(DrawColor).Pos.Top + 4)-(txtColor(DrawColor).Pos.Left + txtColor(DrawColor).Pos.Width - 4, txtColor(DrawColor).Pos.Top + txtColor(DrawColor).Pos.Height - 4), 8, B
    LINE (txtColor(DrawColor).Pos.Left + 5, txtColor(DrawColor).Pos.Top + 5)-(txtColor(DrawColor).Pos.Left + txtColor(DrawColor).Pos.Width - 5, txtColor(DrawColor).Pos.Top + txtColor(DrawColor).Pos.Height - 5), 15, B
                                
    'Transparent color box
    Obj.SetSize txtColor(-1).Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 10, txtDrawArea.Pos.Top + 166, 37, 18
    LINE (txtColor(-1).Pos.Left + 2, txtColor(-1).Pos.Top + 2)-(txtColor(-1).Pos.Left + txtColor(-1).Pos.Width - 2, txtColor(-1).Pos.Top + txtColor(-1).Pos.Height - 2), 15, BF
    LINE (txtColor(-1).Pos.Left + 2, txtColor(-1).Pos.Top + txtColor(-1).Pos.Height - 2)-(txtColor(-1).Pos.Left + txtColor(-1).Pos.Width - 2, txtColor(-1).Pos.Top + 2), 7
    
    Font.Print "Preview", btnPreview.Pos.Left, btnPreview.Pos.Top - 15, SystemTheme.WindowText, fontHeading
    LINE (btnPreview.Pos.Left - 1, btnPreview.Pos.Top - 4)-(btnPreview.Pos.Left + 5, btnPreview.Pos.Top - 4), SystemTheme.WindowText
    LINE (btnPreview.Pos.Left + 2, btnPreview.Pos.Top + 2)-(btnPreview.Pos.Left + btnPreview.Pos.Width - 2, btnPreview.Pos.Top + btnPreview.Pos.Height - 2), 15, BF

    'Draw grid in drawing area
    FOR YPos = 0 TO 31
        LINE (txtDrawArea.Pos.Left + 2, txtDrawArea.Pos.Top + 1 + (YPos * 13))-(txtDrawArea.Pos.Left + txtDrawArea.Pos.Width - 2, 43 + (YPos * 13)), 8
        LINE (txtDrawArea.Pos.Left + 2, txtDrawArea.Pos.Top + 1 + (YPos * 13))-(txtDrawArea.Pos.Left + txtDrawArea.Pos.Width - 2, 43 + (YPos * 13)), 0, , &HAAAA
    NEXT
    FOR XPos = 0 TO 31
        LINE (txtDrawArea.Pos.Left + 1 + (XPos * 13), txtDrawArea.Pos.Top + 2)-(txtDrawArea.Pos.Left + 1 + (XPos * 13), txtDrawArea.Pos.Top + txtDrawArea.Pos.Height - 2), 8
        LINE (txtDrawArea.Pos.Left + 1 + (XPos * 13), txtDrawArea.Pos.Top + 2)-(txtDrawArea.Pos.Left + 1 + (XPos * 13), txtDrawArea.Pos.Top + txtDrawArea.Pos.Height - 2), 0, , &HAAAA
    NEXT
    
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
            CursorX = (Mouse.X - (txtDrawArea.Pos.Left + 7)) / 13
            CursorY = (Mouse.Y - (txtDrawArea.Pos.Top + 7)) / 13
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
            void = IconEdit.SaveIcon
        END IF

        IF Obj.BtnClick(btnOpen) OR Key$ = "l" THEN
            IconEdit.ShowLoadDialog
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
            Obj.DrawBtn btnPencil, True
            DO: LOOP WHILE Mouse.Clicked
            CurrentTool = toolPencil
            Obj.DrawBtn btnFloodFill, False
          END IF
        END IF

        IF (Mouse.Clicked AND Mouse.InArea(btnFloodFill.Pos)) OR Key$ = "f" THEN
          IF NOT CurrentTool = toolFloodFill THEN
            Obj.DrawBtn btnFloodFill, True
            DO: LOOP WHILE Mouse.Clicked
            CurrentTool = toolFloodFill
            Obj.DrawBtn btnPencil, False
          END IF
        END IF

        IF Key$ = "t" OR Key$ = "c" THEN
          Mouse.Hide
          'Remove selection marker from current color
          IF DrawColor = -1 THEN
            LINE (txtColor(-1).Pos.Left + 2, txtColor(-1).Pos.Top + 2)-(txtColor(-1).Pos.Left + txtColor(-1).Pos.Width - 2, txtColor(-1).Pos.Top + txtColor(-1).Pos.Height - 2), 15, BF
            LINE (txtColor(-1).Pos.Left + 2, txtColor(-1).Pos.Top + txtColor(-1).Pos.Height - 2)-(txtColor(-1).Pos.Left + txtColor(-1).Pos.Width - 2, txtColor(-1).Pos.Top + 2), 7
          ELSE
            LINE (txtColor(DrawColor).Pos.Left + 4, txtColor(DrawColor).Pos.Top + 4)-(txtColor(DrawColor).Pos.Left + 14, txtColor(DrawColor).Pos.Top + 14), DrawColor, BF
          END IF

          'Change color according to key pressed
          IF Key$ = "t" THEN
            DrawColor = -1
          ELSE
            DrawColor = DrawColor + 1
            IF DrawColor > 15 THEN DrawColor = -1
          END IF

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
                IconEdit.DrawPixel KeyboardPosX, KeyboardPosY, DrawColor, False
              CASE toolFloodFill
                IconEdit.FillArea KeyboardPosX, KeyboardPosY, DrawColor
            END SELECT
            IconEdit.MoveIndicator dirStay
          ELSE
            KeyboardPosVisible = True
            IconEdit.MoveIndicator dirStay
          END IF
        END IF

        FOR ColChk = -1 TO 15
            IF Obj.TxtClick(txtColor(ColChk)) THEN
                IF NOT DrawColor = ColChk THEN
                    Mouse.Hide
                    'Remove selection marker
                    IF DrawColor = -1 THEN
                      LINE (txtColor(-1).Pos.Left + 2, txtColor(-1).Pos.Top + 2)-(txtColor(-1).Pos.Left + txtColor(-1).Pos.Width - 2, txtColor(-1).Pos.Top + txtColor(-1).Pos.Height - 2), 15, BF
                      LINE (txtColor(-1).Pos.Left + 2, txtColor(-1).Pos.Top + txtColor(-1).Pos.Height - 2)-(txtColor(-1).Pos.Left + txtColor(-1).Pos.Width - 2, txtColor(-1).Pos.Top + 2), 7
                    ELSE
                      LINE (txtColor(DrawColor).Pos.Left + 4, txtColor(DrawColor).Pos.Top + 4)-(txtColor(DrawColor).Pos.Left + 14, txtColor(DrawColor).Pos.Top + 14), DrawColor, BF
                    END IF

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
                  IconEdit.DrawPixel CursorX, CursorY, DrawColor, False

                  IF Mouse.InArea(txtDrawArea.Pos) THEN
                      CursorX = (Mouse.X - (txtDrawArea.Pos.Left + 7)) / 13
                      CursorY = (Mouse.Y - (txtDrawArea.Pos.Top + 7)) / 13
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
                IconEdit.FillArea CursorX, CursorY, DrawColor

            END SELECT

        END IF
    
    LOOP


END SUB

SUB IconEdit.MoveIndicator (Direction)

    DIM XPos, YPos, PerformMove

    PerformMove = False
    SELECT CASE Direction
      CASE dirUp
        IF KeyboardPosY > 0 THEN PerformMove = True
      CASE dirDown
        IF KeyboardPosY < 31 THEN PerformMove = True
      CASE dirLeft
        IF KeyboardPosX > 0 THEN PerformMove = True
      CASE dirRight
        IF KeyboardPosX < 31 THEN PerformMove = True
    END SELECT


    IF (PerformMove AND KeyboardPosVisible) OR Direction = dirHide THEN

      IF KeyboardPosX > -1 AND KeyboardPosY > -1 THEN
        XPos = 58 + (KeyboardPosX * 13)
        YPos = 44 + (KeyboardPosY * 13)
        Mouse.Hide
        IF IconData.Pixel(KeyboardPosX, KeyboardPosY) > -1 THEN
          LINE (XPos, YPos)-(XPos + 11, YPos + 11), IconData.Pixel(KeyboardPosX, KeyboardPosY), BF
        ELSE
          LINE (XPos, YPos)-(XPos + 11, YPos + 11), 15, BF
          LINE (XPos, YPos + 11)-(XPos + 11, YPos), 7
        END IF
        Mouse.Show
      END IF
    END IF

    IF PerformMove THEN
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
    END IF

    IF KeyboardPosVisible THEN
      IF PerformMove OR Direction = dirStay THEN
        XPos = 58 + (KeyboardPosX * 13)
        YPos = 44 + (KeyboardPosY * 13)
        Mouse.Hide
        LINE (XPos + 3, YPos + 3)-(XPos + 9, YPos + 9), 8, B
        LINE (XPos + 4, YPos + 4)-(XPos + 8, YPos + 8), 15, B
        Mouse.Show
      END IF
    END IF

    
END SUB

SUB IconEdit.NewIcon ()

    DIM XPos, YPos
    DIM WindowTitle AS STRING
                    
    'Redraw window title
    IconFileName = ""
    IconEdit.SetTitle

    Mouse.Hide

    'Draw all pixels transparent
    FOR XPos = 0 TO 31
        FOR YPos = 0 TO 31
            IconEdit.DrawPixel XPos, YPos, -1, True
        NEXT
    NEXT

    Mouse.Show
    IconChanged = False

END SUB

SUB IconEdit.Preview ()

    DIM winPreview AS WindowType, btnClose AS ButtonType
    DIM txtPreview AS TextboxType, imgPreview AS ImageType
    DIM Key$, XPos, YPos, FileHandle
    DIM IconSaveData AS IconDataType
    DIM Header AS STRING * 9
    Header = "JACOBPALM"
    
    Obj.SetSize winPreview.Pos, 132, 90, 267, 321
    winPreview.Caption = "Preview Icon"

    Obj.SetSize btnClose.Pos, winPreview.Pos.Left + winPreview.Pos.Width - 110, winPreview.Pos.Top + winPreview.Pos.Height - 32, 100, 22
    btnClose.Caption = "Close"
    btnClose.HotKey = 1

    Obj.SetSize txtPreview.Pos, winPreview.Pos.Left + 10, winPreview.Pos.Top + 32, 247, 247

    
    Sys.VGASave "ICONPREW"

    Obj.DrawWin winPreview
    Obj.DrawBtn btnClose, False
    Obj.DrawTxt txtPreview, "", False

    Mouse.Hide
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
    Mouse.Show

    ON LOCAL ERROR GOTO PreviewError
    DEF SEG = VARSEG(IconData.Pixel(0, 0))
    BSAVE Sys.Path + "DATA\IMAGES\PRW_JPC8.BSV", VARPTR(IconData.Pixel(0, 0)), 2048
    DEF SEG
    ON LOCAL ERROR RESUME NEXT
    
    imgPreview.ImageFile = "PRW_JPC8.BSV"
    
    FOR XPos = 2 TO 185 STEP 61
        FOR YPos = 2 TO 185 STEP 61
            imgPreview.Pos.Left = txtPreview.Pos.Left + XPos + 16
            imgPreview.Pos.Top = txtPreview.Pos.Top + YPos + 16
            Obj.DrawImg imgPreview
        NEXT
    NEXT
    
    'Kill temp file, ignore errors
    ON LOCAL ERROR RESUME NEXT
    KILL Sys.Path + "DATA\IMAGES\PRW_JPC8.BSV"
    ON LOCAL ERROR GOTO 0

    DO
        Key$ = INKEY$

        IF Obj.BtnClick(btnClose) OR Key$ = "c" OR Key$ = CHR$(27) THEN
            EXIT DO
        END IF

    LOOP

    Sys.VGALoad "ICONPREW"
    EXIT SUB

PreviewError:
    FileHandle = Sys.MsgBox("Could not preview icon", "An error occured while previewing your icon, while saving a temporary copy." + CHR$(13) + "Make sure the disk is not full or write-protected, and try again.", msgError)
    Sys.VGALoad "ICONPREW"
    EXIT SUB
    RESUME NEXT

END SUB

FUNCTION IconEdit.SaveIcon ()

    DIM SaveAs AS STRING, FileHandle, XPos, YPos
    DIM Header AS STRING * 9, WindowTitle AS STRING

TopOfSave:

    SaveAs = Sys.InputBox("Save icon file", "Type a name for the icon file below, without path or" + CHR$(13) + "extension (8 letters max, for example: MYICON).", "PAINT", IconFileName)

    IF SaveAs = "" THEN EXIT FUNCTION

    IF LEN(SaveAs) > 8 THEN
        FileHandle = Sys.MsgBox("Invalid file name", "The filename you specified was too long." + CHR$(13) + "Do not type a path or extension, only a filename" + CHR$(13) + "with a maximun lenght of 8 characters.", msgError)
        EXIT FUNCTION
    END IF

    IF File.Exists(Sys.Path + "DATA\IMAGES\" + SaveAs + ".BSV") THEN
        IF NOT UCASE$(SaveAs) = IconFileName THEN
        
            DIM DoSave
            DoSave = Sys.MsgBox("File already exists", "The specified icon file already exists. Do you want" + CHR$(13) + "to owerwrite it with this icon?", msgQuest)

            IF DoSave = False THEN GOTO TopOfSave

        END IF

        KILL Sys.Path + "DATA\IMAGES\" + SaveAs + ".BSV"
    END IF

    ON LOCAL ERROR GOTO SaveIconError
    DEF SEG = VARSEG(IconData.Pixel(0, 0))
    BSAVE Sys.Path + "DATA\IMAGES\" + SaveAs + ".BSV", VARPTR(IconData.Pixel(0, 0)), 2048
    DEF SEG
    ON LOCAL ERROR GOTO 0

    IconFileName = UCASE$(SaveAs)

    'Redraw window title
    IconEdit.SetTitle

    IconEdit.SaveIcon = True
    IconChanged = False
    EXIT FUNCTION

SaveIconError:
    FileHandle = Sys.MsgBox("Could not save icon", "An error occured while saving your icon, and it was not saved." + CHR$(13) + "Make sure the disk is not full or write-protected, and try again.", msgError)
    IconEdit.SaveIcon = False
    EXIT FUNCTION
    RESUME NEXT
END FUNCTION

SUB IconEdit.SetTitle ()

    DIM XPos
    DIM WindowTitle AS STRING

    IF IconFileName = "" THEN
        WindowTitle = "Untitled"
    ELSE
        WindowTitle = UCASE$(IconFileName)
    END IF

    WindowTitle = "Icon Editor for Costa - " + WindowTitle

    Mouse.Hide
    LINE (53, 16)-(587, 32), SystemTheme.TitleBar, BF
    XPos = (640 - Font.GetWidth(WindowTitle, fontHeading)) / 2
    Font.Print WindowTitle, XPos, 20, SystemTheme.TitleBarText, fontHeading
    Mouse.Show

END SUB

SUB IconEdit.ShowLoadDialog ()
    DIM IconFiles() AS STRING
    DIM IconIndex
    DIM Key$

    DIM winSelect AS WindowType
    DIM imgPreview AS ImageType
    DIM btnNext AS ButtonType, btnPrev AS ButtonType, BtnCancel AS ButtonType
    DIM btnLoad AS ButtonType
                                     
    REDIM IconFiles(0) AS STRING
    IconFiles(0) = DIR$(Sys.Path + "DATA\IMAGES\*.BSV")

    IF IconFiles(0) = "" THEN
        DIM void
        void = Sys.MsgBox("No icons found", "It appears that no icons exist - create a new one" + CHR$(13) + "by clicking the ""New"" button in the main window.", msgInfo)
        EXIT SUB
    END IF
    IconFiles(0) = LEFT$(IconFiles(0), LEN(IconFiles(0)) - 4)
    IconIndex = 0

    Obj.SetSize winSelect.Pos, 243, 160, 153, 160
    Obj.SetSize btnLoad.Pos, winSelect.Pos.Left + 51, winSelect.Pos.Top + 58, 52, 52
    Obj.SetSize btnPrev.Pos, winSelect.Pos.Left + 15, winSelect.Pos.Top + 73, 22, 22
    Obj.SetSize btnNext.Pos, winSelect.Pos.Left + 117, winSelect.Pos.Top + 73, 22, 22
    Obj.SetSize BtnCancel.Pos, winSelect.Pos.Left + 15, winSelect.Pos.Top + 124, 124, 22
    Obj.SetSize imgPreview.Pos, btnLoad.Pos.Left + 11, btnLoad.Pos.Top + 11, -1, -1

    Sys.VGASave "LoadIcon"
    winSelect.Caption = "Load icon"
    btnPrev.Caption = "<"
    btnNext.Caption = ">"
    BtnCancel.Caption = "Cancel"
    BtnCancel.HotKey = 1
    btnLoad.Transparent = True
    imgPreview.ImageFile = IconFiles(0)
    
    Obj.DrawWin winSelect
    Obj.DrawBtn btnPrev, 0
    Obj.DrawBtn btnLoad, 0
    Obj.DrawBtn btnNext, 0
    Obj.DrawBtn BtnCancel, 0
    Obj.DrawImg imgPreview

    Font.Print IconFiles(IconIndex), (winSelect.Pos.Left + (winSelect.Pos.Width / 2)) - (Font.GetWidth(IconFiles(IconIndex), fontHeading) / 2), winSelect.Pos.Top + 37, SystemTheme.WindowText, fontHeading

    DO
        REDIM PRESERVE IconFiles(0 TO UBOUND(IconFiles) + 1) AS STRING
        IconFiles(UBOUND(IconFiles)) = DIR$
        IF IconFiles(UBOUND(IconFiles)) = "" THEN
            REDIM PRESERVE IconFiles(0 TO UBOUND(IconFiles) - 1) AS STRING
            EXIT DO
        END IF
        IconFiles(UBOUND(IconFiles)) = LEFT$(IconFiles(UBOUND(IconFiles)), LEN(IconFiles(UBOUND(IconFiles))) - 4)
    LOOP
    
    DO
        Key$ = LCASE$(INKEY$)

        IF Obj.BtnClick(BtnCancel) OR Key$ = CHR$(27) OR Key$ = "c" THEN
            Sys.VGALoad "LoadIcon"
            EXIT SUB
        END IF

        IF Obj.BtnClick(btnPrev) OR Key$ = CHR$(0) + "k" THEN 'Left arrow
            IconIndex = IconIndex - 1
            IF IconIndex = -1 THEN IconIndex = UBOUND(IconFiles)
            imgPreview.ImageFile = IconFiles(IconIndex)
            Mouse.Hide
            LINE (btnLoad.Pos.Left + 11, btnLoad.Pos.Top + 11)-(btnLoad.Pos.Left + 42, btnLoad.Pos.Top + 42), SystemTheme.Window, BF
            LINE (winSelect.Pos.Left + 10, winSelect.Pos.Top + 33)-(winSelect.Pos.Left + 146, winSelect.Pos.Top + 50), SystemTheme.Window, BF
            Mouse.Show
            Obj.DrawImg imgPreview
            Font.Print IconFiles(IconIndex), (winSelect.Pos.Left + (winSelect.Pos.Width / 2)) - (Font.GetWidth(IconFiles(IconIndex), fontHeading) / 2), winSelect.Pos.Top + 37, SystemTheme.WindowText, fontHeading
        END IF

        IF Obj.BtnClick(btnNext) OR Key$ = CHR$(0) + "m" THEN 'Right arrow
            IconIndex = IconIndex + 1
            IF IconIndex > UBOUND(IconFiles) THEN IconIndex = 0
            imgPreview.ImageFile = IconFiles(IconIndex)
            Mouse.Hide
            LINE (btnLoad.Pos.Left + 11, btnLoad.Pos.Top + 11)-(btnLoad.Pos.Left + 42, btnLoad.Pos.Top + 42), SystemTheme.Window, BF
            LINE (winSelect.Pos.Left + 10, winSelect.Pos.Top + 33)-(winSelect.Pos.Left + 146, winSelect.Pos.Top + 50), SystemTheme.Window, BF
            Mouse.Show
            Obj.DrawImg imgPreview
            Font.Print IconFiles(IconIndex), (winSelect.Pos.Left + (winSelect.Pos.Width / 2)) - (Font.GetWidth(IconFiles(IconIndex), fontHeading) / 2), winSelect.Pos.Top + 37, SystemTheme.WindowText, fontHeading
        END IF

        IF Obj.BtnClick(btnLoad) OR Key$ = CHR$(13) THEN
            Sys.VGALoad "LoadIcon"
            IconEdit.LoadIcon (IconFiles(IconIndex))
            EXIT SUB
        END IF

    LOOP


END SUB

