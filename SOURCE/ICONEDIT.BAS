DECLARE SUB IconEdit.Preview ()
DECLARE FUNCTION IconEdit.SaveIcon% ()
DECLARE FUNCTION IconEdit.LoadIcon% ()

DEFINT A-Z
OPTION EXPLICIT

DECLARE SUB IconEdit.Main ()

TYPE IconDataType
    Pixel(31, 31) AS INTEGER
END TYPE

DIM SHARED IconData AS IconDataType
DIM SHARED IconFileName AS STRING

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

STACK 5120

IF File.Exists(Sys.Path + "DATA\TEMP\RUNSTAT.TMP") = False THEN
    'DEBUG - not for final releases
    'IF NOT COMMAND$ = "/DEV" THEN 'Debug - ikke for final release
        CLS
        PRINT "This program is a part of The Costa Graphical Shell and should not be executed"
        PRINT "directly from the command prompt."
        PRINT
        PRINT "To start Costa, run COSTA.BAT. If that file doesn't exist, run SETUP.EXE."
        PRINT
        END
    'END IF
END IF

IF Sys.Path = "" OR File.Exists(Sys.Path + "COSTA100.EXE") = False THEN
    CLS
    PRINT "The environment variable COSTA100, which contains the path to Costa, is either"
    PRINT "not set or contains an invalid path."
    PRINT
    PRINT "Run SETUP.EXE to fix this issue."
    PRINT
    END
END IF

                                                      'DEBUG - not for final releases
IF NOT COMMAND$ = "/?" AND NOT COMMAND$ = "/VER" THEN 'AND NOT COMMAND$ = "/DEV" THEN
    IconFileName = COMMAND$
END IF

Sys.Load

IconEdit.Main

SUB Calc.Main ()
END SUB

SUB Conf.Main ()
END SUB

FUNCTION IconEdit.LoadIcon ()
    DIM LoadFile AS STRING, FileHandle
    DIM Header AS STRING * 9
    DIM IconFiles() AS STRING
    DIM IconIndex
    DIM Key$

    DIM winSelect AS WindowType
    DIM imgPreview AS ImageType
    DIM btnNext AS ButtonType, btnPrev AS ButtonType, BtnCancel AS ButtonType
    DIM btnLoad AS ButtonType
                                     
    REDIM IconFiles(0) AS STRING
    IconFiles(0) = DIR$(Sys.Path + "DATA\IMAGES\*.BIF")

    IF IconFiles(0) = "" THEN
        FileHandle = Sys.MsgBox("No icons found", "It appears that no icons exist - create a new one" + CHR$(13) + "by clicking the ""New"" button in the main window.", msgInfo)
        EXIT FUNCTION
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

    Font.Print IconFiles(IconIndex), (winSelect.Pos.Left + (winSelect.Pos.Width / 2)) - (Font.GetWidth(IconFiles(IconIndex), FontHeading) / 2), winSelect.Pos.Top + 37, clrWindowText, FontHeading

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

        IF Key$ = CHR$(27) OR Key$ = "c" OR Obj.BtnClick(BtnCancel) THEN
            Sys.VGALoad "LoadIcon"
            EXIT FUNCTION
        END IF

        IF Key$ = CHR$(0) + "k" OR Obj.BtnClick(btnPrev) THEN 'Left arrow
            IconIndex = IconIndex - 1
            IF IconIndex = -1 THEN IconIndex = UBOUND(IconFiles)
            imgPreview.ImageFile = IconFiles(IconIndex)
            Mouse.Hide
            LINE (btnLoad.Pos.Left + 11, btnLoad.Pos.Top + 11)-(btnLoad.Pos.Left + 42, btnLoad.Pos.Top + 42), clrButton, BF
            LINE (winSelect.Pos.Left + 10, winSelect.Pos.Top + 33)-(winSelect.Pos.Left + 146, winSelect.Pos.Top + 50), clrWindow, BF
            Mouse.Show
            Obj.DrawImg imgPreview
            Font.Print IconFiles(IconIndex), (winSelect.Pos.Left + (winSelect.Pos.Width / 2)) - (Font.GetWidth(IconFiles(IconIndex), FontHeading) / 2), winSelect.Pos.Top + 37, clrWindowText, FontHeading
        END IF

        IF Key$ = CHR$(0) + "m" OR Obj.BtnClick(btnNext) THEN 'Right arrow
            IconIndex = IconIndex + 1
            IF IconIndex > UBOUND(IconFiles) THEN IconIndex = 0
            imgPreview.ImageFile = IconFiles(IconIndex)
            Mouse.Hide
            LINE (btnLoad.Pos.Left + 11, btnLoad.Pos.Top + 11)-(btnLoad.Pos.Left + 42, btnLoad.Pos.Top + 42), clrButton, BF
            LINE (winSelect.Pos.Left + 10, winSelect.Pos.Top + 33)-(winSelect.Pos.Left + 146, winSelect.Pos.Top + 50), clrWindow, BF
            Mouse.Show
            Obj.DrawImg imgPreview
            Font.Print IconFiles(IconIndex), (winSelect.Pos.Left + (winSelect.Pos.Width / 2)) - (Font.GetWidth(IconFiles(IconIndex), FontHeading) / 2), winSelect.Pos.Top + 37, clrWindowText, FontHeading
        END IF

        IF Key$ = CHR$(13) OR Obj.BtnClick(btnLoad) THEN
            EXIT DO
        END IF

    LOOP
    
    
    LoadFile = IconFiles(IconIndex)
    IF LoadFile = IconFileName THEN
        IF Sys.MsgBox("File already open", "The icon you selected is already opened." + CHR$(13) + "Do you want to discard all changes and reload" + CHR$(13) + "the icon as it was last saved?", msgQuest) = False THEN Sys.VGALoad "LoadIcon": EXIT  _
FUNCTION
    END IF

    FileHandle = FREEFILE
    OPEN Sys.Path + "DATA\IMAGES\" + LoadFile + ".BIF" FOR BINARY AS #FileHandle

    IF LOF(FileHandle) = 2057 THEN
        GET #FileHandle, , Header
        IF Header = "JACOBPALM" THEN
            GET #FileHandle, , IconData
            CLOSE #FileHandle

            IconFileName = LoadFile
            IconEdit.LoadIcon = True
            EXIT FUNCTION
        END IF

        CLOSE #FileHandle
    END IF

    FileHandle = Sys.MsgBox("Invalid image file", "The icon you selected does not contain a valid icon. The" + CHR$(13) + "file might be damaged, or not an icon file at all.", msgError)
    IconEdit.LoadIcon = False

END FUNCTION

SUB IconEdit.Main ()

    DIM winMain AS WindowType, txtDrawArea AS TextboxType
    DIM btnPreview AS ButtonType
    DIM btnNew AS ButtonType, btnOpen AS ButtonType, btnSave AS ButtonType
    DIM btnExit AS ButtonType
    DIM txtColor(-1 TO 15) AS TextboxType

    DIM Key$, YPos, XPos, CursorX, CursorY, DrawColor, TransClick
    DIM IconChanged, ColChk

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

    Obj.SetSize txtColor(-1).Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 36, txtDrawArea.Pos.Top + 153, 37, 18
    
StartOfMain:

    DrawColor = 0
    CursorX = 0
    CursorY = 0
    IconChanged = False
    
    winMain.Caption = "Icon Editor for Costa -"
    IF IconFileName = "" THEN
        winMain.Caption = RTRIM$(winMain.Caption) + " Untitled"
    ELSE
        winMain.Caption = RTRIM$(winMain.Caption) + " " + UCASE$(IconFileName)
    END IF

    Obj.DrawWin winMain
    Obj.DrawTxt txtDrawArea, "", False
    Obj.DrawBtn btnPreview, False
    Obj.DrawBtn btnNew, False
    Obj.DrawBtn btnOpen, False
    Obj.DrawBtn btnSave, False
    Obj.DrawBtn btnExit, False
    Obj.DrawTxt txtColor(-1), "", False

    Mouse.Hide
    LINE (txtDrawArea.Pos.Left + 2, txtDrawArea.Pos.Top + 2)-(txtDrawArea.Pos.Left + txtDrawArea.Pos.Width - 2, txtDrawArea.Pos.Top + txtDrawArea.Pos.Width - 2), 15, BF
    FOR YPos = 0 TO 31
        LINE (txtDrawArea.Pos.Left + 2, txtDrawArea.Pos.Top + (YPos * 13) + 1)-(txtDrawArea.Pos.Left + txtDrawArea.Pos.Width - 2, txtDrawArea.Pos.Top + (YPos * 13) + 1), 8
        LINE (txtDrawArea.Pos.Left + 2, txtDrawArea.Pos.Top + (YPos * 13) + 1)-(txtDrawArea.Pos.Left + txtDrawArea.Pos.Width - 2, txtDrawArea.Pos.Top + (YPos * 13) + 1), 0, , &HAAAA
    NEXT
    FOR XPos = 0 TO 31
        LINE (txtDrawArea.Pos.Left + (XPos * 13) + 1, txtDrawArea.Pos.Top + 2)-(txtDrawArea.Pos.Left + (XPos * 13) + 1, txtDrawArea.Pos.Top + txtDrawArea.Pos.Height - 2), 8
        LINE (txtDrawArea.Pos.Left + (XPos * 13) + 1, txtDrawArea.Pos.Top + 2)-(txtDrawArea.Pos.Left + (XPos * 13) + 1, txtDrawArea.Pos.Top + txtDrawArea.Pos.Height - 2), 0, , &HAAAA
    NEXT

    FOR YPos = 0 TO 7
        Obj.SetSize txtColor(YPos).Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 36, txtDrawArea.Pos.Top + (YPos * 19), 18, 18
        Obj.DrawTxt txtColor(YPos), "", False
        LINE (txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 38, txtDrawArea.Pos.Top + (YPos * 19) + 2)-(txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 52, txtDrawArea.Pos.Top + (YPos * 19) + 16), YPos, BF
    NEXT
    FOR YPos = 8 TO 15
        Obj.SetSize txtColor(YPos).Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 55, txtDrawArea.Pos.Top + ((YPos - 8) * 19), 18, 18
        Obj.DrawTxt txtColor(YPos), "", False
        LINE (txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 57, txtDrawArea.Pos.Top + ((YPos - 8) * 19) + 2)-(txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 71, txtDrawArea.Pos.Top + ((YPos - 8) * 19) + 16), YPos, BF
    NEXT

    Font.Print "Preview", btnPreview.Pos.Left, btnPreview.Pos.Top - 15, clrWindowText, FontHeading
    LINE (btnPreview.Pos.Left - 1, btnPreview.Pos.Top - 4)-(btnPreview.Pos.Left + 5, btnPreview.Pos.Top - 4), clrWindowText
    

    FOR XPos = 0 TO 31
        FOR YPos = 0 TO 31
            IF IconFileName = "" THEN
                Font.Print "T", txtDrawArea.Pos.Left + (XPos * 13) + 5, txtDrawArea.Pos.Top + (YPos * 13) + 4, 0, FontHeading
                IconData.Pixel(XPos, YPos) = -1
            ELSE
                IF IconData.Pixel(XPos, YPos) > -1 THEN
                    LINE (txtDrawArea.Pos.Left + 2 + (XPos * 13), txtDrawArea.Pos.Top + 2 + (YPos * 13))-(txtDrawArea.Pos.Left + 2 + (XPos * 13) + 11, txtDrawArea.Pos.Top + 2 + (YPos * 13) + 11), IconData.Pixel(XPos, YPos), BF
                    PSET (btnPreview.Pos.Left + 10 + XPos, btnPreview.Pos.Top + 10 + YPos), IconData.Pixel(XPos, YPos)
                ELSE
                    Font.Print "T", txtDrawArea.Pos.Left + (XPos * 13) + 5, txtDrawArea.Pos.Top + (YPos * 13) + 4, 0, FontHeading
                END IF
            END IF
        NEXT
    NEXT
    LINE (txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 38, txtDrawArea.Pos.Top + 155)-(txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 71, txtDrawArea.Pos.Top + 169), 15, BF
    Mouse.Show
                                                                                                                             
    Font.Print "T", txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 52, txtDrawArea.Pos.Top + 158, 0, FontHeading


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
                        FOR XPos = 0 TO 31
                            FOR YPos = 0 TO 31
                                IconData.Pixel(XPos, YPos) = 0
                            NEXT
                        NEXT
                        IconFileName = ""
                        IconChanged = 0
                        DrawColor = 0
                        GOTO StartOfMain
                    END IF
                ELSE
                    FOR XPos = 0 TO 31
                        FOR YPos = 0 TO 31
                            IconData.Pixel(XPos, YPos) = 0
                        NEXT
                    NEXT
                    IconFileName = ""
                    IconChanged = 0
                    DrawColor = 0
                    GOTO StartOfMain
                END IF
            ELSE
                FOR XPos = 0 TO 31
                    FOR YPos = 0 TO 31
                        IconData.Pixel(XPos, YPos) = 0
                    NEXT
                NEXT
                IconFileName = ""
                IconChanged = 0
                DrawColor = 0
                GOTO StartOfMain
            END IF
        END IF

        IF Obj.BtnClick(btnSave) OR Key$ = "s" THEN
            IF IconEdit.SaveIcon THEN GOTO StartOfMain
        END IF

        IF Obj.BtnClick(btnOpen) OR Key$ = "l" THEN
            IF IconChanged = True THEN
                IF Sys.MsgBox("Icon has been modified", "This icon contains unsaved changes. Do you" + CHR$(13) + "want to save it before you load another?", msgQuest) = True THEN
                    IF IconEdit.SaveIcon = True THEN
                        IF IconEdit.LoadIcon THEN GOTO StartOfMain
                    END IF
                ELSE
                    IF IconEdit.LoadIcon THEN GOTO StartOfMain
                END IF
            ELSE
                IF IconEdit.LoadIcon THEN GOTO StartOfMain
            END IF
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

        FOR ColChk = -1 TO 15
            IF Obj.TxtClick(txtColor(ColChk)) THEN
                IF NOT DrawColor = ColChk THEN
                    DrawColor = ColChk
                END IF
            END IF
        NEXT

        IF Mouse.Clicked AND CursorX > -1 AND CursorY > -1 THEN
            XPos = txtDrawArea.Pos.Left + 2 + (CursorX * 13)
            YPos = txtDrawArea.Pos.Top + 2 + (CursorY * 13)

            IF Mouse.Clicked = mbLeft THEN
                IF NOT IconData.Pixel(CursorX, CursorY) = DrawColor THEN
                    IconChanged = True
                    IconData.Pixel(CursorX, CursorY) = DrawColor
                    Mouse.Hide
                    IF DrawColor > -1 THEN
                        TransClick = False
                        LINE (XPos, YPos)-(XPos + 11, YPos + 11), DrawColor, BF
                    ELSE
                        TransClick = True
                        LINE (XPos, YPos)-(XPos + 11, YPos + 11), 15, BF
                        Font.Print "T", XPos + 3, YPos + 2, 0, FontHeading
                    END IF
                    Mouse.Show
                    GOSUB UpdatePreview
                END IF
            ELSE
                IF NOT IconData.Pixel(CursorX, CursorY) = -1 THEN
                    IconChanged = True
                    TransClick = True
                    IconData.Pixel(CursorX, CursorY) = -1
                    Mouse.Hide
                    LINE (XPos, YPos)-(XPos + 11, YPos + 11), 15, BF
                    Mouse.Show
                    Font.Print "T", XPos + 3, YPos + 2, 0, FontHeading
                    GOSUB UpdatePreview
                END IF
            END IF


        END IF
        
    LOOP UNTIL Key$ = CHR$(27)

    EXIT SUB

UpdatePreview:
    Mouse.Hide
    IF TransClick = True THEN
        PSET (btnPreview.Pos.Left + 10 + CursorX, btnPreview.Pos.Top + 10 + CursorY), clrButton
    ELSE
        PSET (btnPreview.Pos.Left + 10 + CursorX, btnPreview.Pos.Top + 10 + CursorY), DrawColor
    END IF

    Mouse.Show
    RETURN

END SUB

SUB IconEdit.Preview ()

    DIM winPreview AS WindowType, btnClose AS ButtonType
    DIM txtPreview AS TextboxType, imgPreview AS ImageType
    DIM Key$, XPos, YPos, FileHandle
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
    
    ON LOCAL ERROR RESUME NEXT
    FileHandle = FREEFILE
    OPEN Sys.Path + "DATA\IMAGES\PRW_JPC8.BIF" FOR BINARY AS #FileHandle
    PUT #FileHandle, , Header
    PUT #FileHandle, , IconData
    CLOSE #FileHandle
    ON LOCAL ERROR GOTO 0

    imgPreview.ImageFile = "PRW_JPC8.BIF"
    
    FOR XPos = 2 TO 185 STEP 61
        FOR YPos = 2 TO 185 STEP 61
            imgPreview.Pos.Left = txtPreview.Pos.Left + XPos + 16
            imgPreview.Pos.Top = txtPreview.Pos.Top + YPos + 16
            Obj.DrawImg imgPreview
        NEXT
    NEXT
    
    ON LOCAL ERROR RESUME NEXT
    KILL Sys.Path + "DATA\IMAGES\PRW_JPC8.BIF"
    ON LOCAL ERROR GOTO 0

    DO
        Key$ = INKEY$

        IF Obj.BtnClick(btnClose) OR Key$ = "c" OR Key$ = CHR$(27) THEN EXIT DO

    LOOP

    Sys.VGALoad "ICONPREW"
END SUB

FUNCTION IconEdit.SaveIcon ()

    DIM SaveAs AS STRING, FileHandle
    DIM Header AS STRING * 9
    Header = "JACOBPALM"

TopOfSave:

    SaveAs = Sys.InputBox("Save icon file", "Type a name for the icon file below, without path or" + CHR$(13) + "extension (8 letters max, for example: MYICON).", "PAINT", IconFileName)

    IF SaveAs = "" THEN EXIT FUNCTION

    IF LEN(SaveAs) > 8 THEN
        'show error
        FileHandle = Sys.MsgBox("Invalid file name", "The filename you specified was too long." + CHR$(13) + "Do not type a path or extension, only a filename" + CHR$(13) + "with a maximun lenght of 8 characters.", msgError)
        EXIT FUNCTION
    END IF

    IF File.Exists(Sys.Path + "DATA\IMAGES\" + SaveAs + ".BIF") THEN
        IF NOT UCASE$(SaveAs) = IconFileName THEN
        
            DIM DoSave
            DoSave = Sys.MsgBox("File already exists", "The specified icon file already exists. Do you want" + CHR$(13) + "to owerwrite it with this icon?", msgQuest)

            IF DoSave = False THEN GOTO TopOfSave

        END IF

        KILL Sys.Path + "DATA\IMAGES\" + SaveAs + ".BIF"
    END IF
    
    FileHandle = FREEFILE

    OPEN Sys.Path + "DATA\IMAGES\" + SaveAs + ".BIF" FOR BINARY AS #FileHandle
    'User defined data type
    PUT #FileHandle, , Header
    PUT #FileHandle, , IconData
    CLOSE #FileHandle

    IconFileName = SaveAs
    IconEdit.SaveIcon = True
    
END FUNCTION

SUB Tic.Main ()
END SUB

SUB TView.Main (FileToView AS STRING)
END SUB

