'
' This module contains the inputbox routine. It requires COSTALIB.BAS to be
' added as well.
'
' A separate module is used, since not all apps require the inputbox.
'

DEFINT A-Z
OPTION EXPLICIT

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

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
    Obj.SetSize winInputBox.Pos, sizeCenter, sizeCenter, sizeRetain, msgLineCount * 15 + 120
    
    DIM txtInput AS TextboxType, txtInputText AS STRING
    Obj.SetSize txtInput.Pos, winInputBox.Pos.Left + 12, winInputBox.Pos.Top + 56 + (15 * msgLineCount), winInputBox.Pos.Width - 24, sizeRetain
    txtInputText = msgDefault

    DIM btnOK AS ButtonType
    Obj.SetSize btnOK.Pos, winInputBox.Pos.Left + winInputBox.Pos.Width - 182, txtInput.Pos.Top + 30, 80, 22
    btnOK.Caption = "õOK"
    
    DIM btnCancel AS ButtonType
    Obj.SetSize btnCancel.Pos, winInputBox.Pos.Left + winInputBox.Pos.Width - 92, btnOK.Pos.Top, 80, 22
    btnCancel.Caption = "õCancel"

    DIM imgIcon AS ImageType
    IF LEN(msgIcon) THEN
        imgIcon.Pos.Left = winInputBox.Pos.Left + 12
        imgIcon.Pos.Top = winInputBox.Pos.Top + 15
        imgIcon.ImageFile = msgIcon
        IF msgLineCount > 1 THEN imgIcon.Pos.Top = imgIcon.Pos.Top + 5
    END IF

    Mouse.Hide
    PCOPY 0, 1
    Mouse.Show

    IF UserSettings.GreyoutOnMsgBox THEN
        DIM LX, LY
        LY = 0
        Mouse.Hide
        FOR LX = 0 TO 639
            LINE (LX, LY)-(LX, 349), SystemTheme.Shadow, , &HAAAA
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
        Font.Print msgTitle, winInputBox.Pos.Left + 53, winInputBox.Pos.Top + 15, SystemTheme.WindowText, 1
    ELSE
        Font.Print msgTitle, winInputBox.Pos.Left + 12, winInputBox.Pos.Top + 15, SystemTheme.WindowText, 1
    END IF

    DIM PrintLine
    FOR PrintLine = 1 TO msgLineCount
        IF PrintLine < 3 AND LEN(msgIcon) THEN
            Font.Print msgLines(PrintLine), winInputBox.Pos.Left + 53, winInputBox.Pos.Top + 17 + (15 * PrintLine), SystemTheme.WindowText, 2
        ELSE
            Font.Print msgLines(PrintLine), winInputBox.Pos.Left + 12, winInputBox.Pos.Top + 17 + (15 * PrintLine), SystemTheme.WindowText, 2
        END IF
    NEXT

    Font.Print "Iõnput:", txtInput.Pos.Left, txtInput.Pos.Top - 16, SystemTheme.WindowText, FontHeading
    
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

    Mouse.Hide
    PCOPY 1, 0
    Mouse.Show

END FUNCTION

