OPTION EXPLICIT

DECLARE SUB App.Main ()

'$INCLUDE: 'SOURCE\COSTALIB.BI'

SCREEN 12

Sys.Load

App.Main

SUB App.Main ()

    DIM winSample AS WindowType
    winSample.Caption = "Sample Application"
    winSample.Pos.Width = 244
    winSample.Pos.Height = 200
    winSample.Pos.Left = (640 - winSample.Pos.Width) / 2
    winSample.Pos.Top = (480 - winSample.Pos.Height) / 2

    DIM btnExit AS ButtonType
    btnExit.Pos.Left = winSample.Pos.Left + 12
    btnExit.Pos.Top = winSample.Pos.Top + 34
    btnExit.Caption = "Exit"
    btnExit.HotKey = 2

    DIM imgSample AS ImageType
    imgSample.Pos.Top = winSample.Pos.Top + 34
    imgSample.Pos.Left = winSample.Pos.Left + 200
    imgSample.ImageFile = "CONFIG"


    Obj.DrawWin winSample
    Obj.DrawBtn btnExit, False
    Font.Print "Sample text, header font", winSample.Pos.Left + 12, winSample.Pos.Top + 70, ClrWindowText, FontHeading
    Font.Print "Sample text, normal font", winSample.Pos.Left + 12, winSample.Pos.Top + 85, ClrWindowText, FontNormal
    Font.Print "Sample text, system font", winSample.Pos.Left + 12, winSample.Pos.Top + 100, ClrWindowText, FontSystem
    Obj.DrawImg imgSample

    DIM Key$

    DO

        Key$ = LCASE$(INKEY$)

        IF Obj.BtnClick(btnExit) OR Key$ = "x" THEN

            IF Sys.MsgBox("Exit sample application", "Are you sure you want to exit the sample" + CHR$(13) + "application?", msgQuest) = True THEN
                END
            END IF


        END IF
        

    LOOP

END SUB

