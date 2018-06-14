OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Calc.FormatNum (TargetStr AS STRING) AS STRING
DECLARE SUB Calc.Main ()

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

Sys.Load

Calc.Main

' =========================================================================
'          NAME: Calc.FormatNum()
'    PARAMETERS: TargetStr - string containing a number to format nicely
'       RETURNS: A string with a well-formatted number to show the user
'       ASSUMES: Nothing
'   CALLED FROM: CALC.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: Returns a number formatted as a string, with thousands
'                seperators, for visual representation
' =========================================================================
FUNCTION Calc.FormatNum (TargetStr AS STRING) AS STRING

    DIM BeforeDot AS STRING, AfterDot AS STRING
    AfterDot = ""
    IF INSTR(TargetStr, ".") THEN
        BeforeDot = LEFT$(TargetStr, INSTR(TargetStr, ".") - 1)
        AfterDot = RIGHT$(TargetStr, LEN(TargetStr) - INSTR(TargetStr, "."))
    ELSE
        BeforeDot = TargetStr
    END IF

    DIM TempStr AS STRING
    DO WHILE LEN(BeforeDot) > 3
        TempStr = "," + RIGHT$(BeforeDot, 3) + TempStr
        BeforeDot = LEFT$(BeforeDot, LEN(BeforeDot) - 3)
    LOOP
    BeforeDot = BeforeDot + TempStr

    IF AfterDot = "" THEN
        Calc.FormatNum = BeforeDot
    ELSE
        Calc.FormatNum = BeforeDot + "." + AfterDot
    END IF
    
    
END FUNCTION

' =========================================================================
'          NAME: Calc.Main()
'    PARAMETERS: TargetLink - the position in the DeskLink array
'                             containing the link to launch
'       RETURNS: Nothing
'       ASSUMES: That the array position in the DeskLink array exists
'   CALLED FROM: DESKTOP.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: The calculator accessory. Draws the UI and handles main
'                logic
' =========================================================================
SUB Calc.Main ()

    DIM winCalc AS WindowType
    DIM txtCalc AS TextboxType
    DIM btnNumb(0 TO 9) AS ButtonType
    DIM btnC AS ButtonType, btnCE AS ButtonType, btnDivide AS ButtonType
    DIM btnMulti AS ButtonType, btnMinus AS ButtonType, btnPlus AS ButtonType
    DIM btnEquals AS ButtonType, btnDot AS ButtonType, btnClose AS ButtonType
    DIM btnCount
    DIM MathFunc AS STRING * 1
    DIM TotalSum AS CURRENCY, Op1 AS CURRENCY, Op2 AS CURRENCY, NumOps
    DIM Key$, txtCalcText AS STRING, LastClick AS STRING
                                     
    Obj.SetSize winCalc.Pos, 213, 125, 214, 233
    Obj.SetSize txtCalc.Pos, 225, 160, 190, -1
    Obj.SetSize btnNumb(7).Pos, 226, 226, 40, -1
    Obj.SetSize btnNumb(0).Pos, 226, 325, 40, -1
    Obj.SetSize btnNumb(1).Pos, 226, 292, 40, -1
    Obj.SetSize btnNumb(2).Pos, 276, 292, 40, -1
    Obj.SetSize btnNumb(3).Pos, 326, 292, 40, -1
    Obj.SetSize btnNumb(4).Pos, 226, 259, 40, -1
    Obj.SetSize btnNumb(5).Pos, 276, 259, 40, -1
    Obj.SetSize btnNumb(6).Pos, 326, 259, 40, -1
    Obj.SetSize btnNumb(8).Pos, 276, 226, 40, -1
    Obj.SetSize btnNumb(9).Pos, 326, 226, 40, -1
    Obj.SetSize btnC.Pos, 226, 193, 40, -1
    Obj.SetSize btnCE.Pos, 276, 193, 40, -1
    Obj.SetSize btnDivide.Pos, 326, 193, 40, -1
    Obj.SetSize btnDot.Pos, 276, 325, 40, -1
    Obj.SetSize btnMulti.Pos, 376, 193, 40, -1
    Obj.SetSize btnMinus.Pos, 376, 226, 40, -1
    Obj.SetSize btnPlus.Pos, 376, 259, 40, -1
    Obj.SetSize btnEquals.Pos, 376, 292, 40, -1
    Obj.SetSize btnClose.Pos, 326, 325, 90, -1
    
    winCalc.Caption = "Calculator"
    btnNumb(0).Caption = "0"
    btnNumb(1).Caption = "1"
    btnNumb(2).Caption = "2"
    btnNumb(3).Caption = "3"
    btnNumb(4).Caption = "4"
    btnNumb(5).Caption = "5"
    btnNumb(6).Caption = "6"
    btnNumb(7).Caption = "7"
    btnNumb(8).Caption = "8"
    btnNumb(9).Caption = "9"
    btnC.Caption = "C": btnC.HotKey = 1
    btnCE.Caption = "CE": btnCE.HotKey = 2
    btnDivide.Caption = "/"
    btnDot.Caption = "."
    btnMulti.Caption = "*"
    btnMinus.Caption = "-"
    btnPlus.Caption = "+"
    btnEquals.Caption = "="
    btnClose.Caption = "Close": btnClose.HotKey = 2
    txtCalc.MaxLen = 25

    Obj.DrawWin winCalc
    Obj.DrawTxt txtCalc, "", False
    Obj.DrawBtn btnNumb(7), False
    Obj.DrawBtn btnNumb(8), False
    FOR btnCount = 0 TO 9
        Obj.DrawBtn btnNumb(btnCount), False
    NEXT
    Obj.DrawBtn btnC, False: Obj.DrawBtn btnCE, False: Obj.DrawBtn btnDivide, False
    Obj.DrawBtn btnMulti, False: Obj.DrawBtn btnMinus, False: Obj.DrawBtn btnPlus, False
    Obj.DrawBtn btnEquals, False: Obj.DrawBtn btnDot, False: Obj.DrawBtn btnClose, False

    Mouse.Show

    ON LOCAL ERROR GOTO CalcErr

StartOfCalc:

    DO
        Key$ = LCASE$(INKEY$)

        IF Obj.BtnClick(btnClose) OR Key$ = "l" OR Key$ = CHR$(27) THEN
            EXIT DO
        END IF

        FOR btnCount = 0 TO 9
            IF Obj.BtnClick(btnNumb(btnCount)) OR Key$ = LTRIM$(STR$(btnCount)) THEN
                IF LEN(txtCalcText) < 22 THEN
                    Key$ = LTRIM$(STR$(btnCount))
                    IF NOT (Key$ = "0" AND txtCalcText = "0") THEN
                        IF LastClick = "EQUAL" THEN Obj.DrawTxt txtCalc, "", False: txtCalcText = "": NumOps = 0: Op1 = 0
                        IF LastClick = "OP" THEN Obj.DrawTxt txtCalc, "", False
                        LastClick = "NUMB"
                        txtCalcText = txtCalcText + Key$
                        Obj.DrawTxt txtCalc, Calc.FormatNum(txtCalcText), False
                    END IF
                END IF
            END IF
        NEXT


        IF Obj.BtnClick(btnC) OR Key$ = "c" THEN
            txtCalcText = ""
            Obj.DrawTxt txtCalc, "", False
        END IF

        IF Obj.BtnClick(btnCE) OR Key$ = "e" THEN
            txtCalcText = ""
            Obj.DrawTxt txtCalc, "", False
            TotalSum = 0: MathFunc = "": NumOps = 0: Op1 = 0: LastClick = ""
        END IF

        IF Obj.BtnClick(btnDot) OR (Key$ = "." OR Key$ = ",") THEN
            IF LEN(txtCalcText) < 22 AND (INSTR(txtCalcText$, ".") = 0) THEN
                IF LastClick = "EQUAL" THEN Obj.DrawTxt txtCalc, "", False: txtCalcText = "": NumOps = 0: Op1 = 0
                IF LastClick = "OP" THEN Obj.DrawTxt txtCalc, "", False
                LastClick = "NUMB"
                IF txtCalcText = "" THEN txtCalcText = "0"
                txtCalcText = txtCalcText + "."
                Obj.DrawTxt txtCalc, Calc.FormatNum(txtCalcText), False
            END IF
        END IF

        IF Obj.BtnClick(btnEquals) OR Key$ = "=" OR Key$ = CHR$(13) THEN
            IF NumOps = 1 AND LastClick = "NUMB" THEN
                Op1 = VAL(txtCalcText)
                IF MathFunc = "+" THEN TotalSum = TotalSum + Op1
                IF MathFunc = "-" THEN TotalSum = TotalSum - Op1
                IF MathFunc = "*" THEN TotalSum = TotalSum * Op1
                IF MathFunc = "/" THEN
                    IF NOT Op1 = 0 THEN
                        TotalSum = TotalSum / Op1
                    ELSE
                        txtCalcText = "": Obj.DrawTxt txtCalc, "Division by zero", False: TotalSum = 0: MathFunc = "": NumOps = 0: Op1 = 0: LastClick = ""
                        GOTO StartOfCalc
                    END IF
                END IF
                Obj.DrawTxt txtCalc, Calc.FormatNum(LTRIM$(STR$(TotalSum))), False
            END IF

            IF NOT MathFunc = CHR$(0) AND NOT MathFunc = "" AND NOT MathFunc = " " THEN
                Obj.DrawTxt txtCalc, Calc.FormatNum(LTRIM$(STR$(TotalSum))), False
                Op1 = TotalSum: txtCalcText = "": NumOps = 1: MathFunc = "": LastClick = "EQUAL"
            END IF
        END IF

        IF Obj.BtnClick(btnMulti) THEN Key$ = "*"
        IF Obj.BtnClick(btnDivide) THEN Key$ = "/"
        IF Obj.BtnClick(btnPlus) THEN Key$ = "+"
        IF Obj.BtnClick(btnMinus) THEN Key$ = "-"
        
        IF LEN(Key$) THEN
            
            IF Key$ = "+" OR Key$ = "-" OR Key$ = "*" OR Key$ = "/" THEN
                IF NumOps = 1 AND LastClick = "NUMB" THEN
                    Op1 = VAL(txtCalcText)
                    IF MathFunc = "+" THEN TotalSum = TotalSum + Op1
                    IF MathFunc = "-" THEN TotalSum = TotalSum - Op1
                    IF MathFunc = "*" THEN TotalSum = TotalSum * Op1
                    IF MathFunc = "/" THEN
                        IF NOT Op1 = 0 THEN
                            TotalSum = TotalSum / Op1
                        ELSE
                            txtCalcText = "": Obj.DrawTxt txtCalc, "Division by zero", False: TotalSum = 0: MathFunc = "": NumOps = 0: Op1 = 0: LastClick = ""
                            GOTO StartOfCalc
                        END IF
                    END IF
                    Obj.DrawTxt txtCalc, Calc.FormatNum(LTRIM$(STR$(TotalSum))), False
                END IF

                IF Key$ = "+" THEN MathFunc = "+"
                IF Key$ = "-" THEN MathFunc = "-"
                IF Key$ = "*" THEN MathFunc = "*"
                IF Key$ = "/" THEN MathFunc = "/"
                IF NumOps = 0 THEN
                    TotalSum = VAL(txtCalcText)
                END IF
                IF LastClick = "NUMB" THEN txtCalcText = ""

                NumOps = 1
                LastClick = "OP"
            END IF

            IF Key$ = CHR$(8) THEN
                IF LEN(txtCalcText) = 1 THEN
                    txtCalcText = ""
                    Obj.DrawTxt txtCalc, Calc.FormatNum(txtCalcText), False
                ELSEIF LEN(txtCalcText) > 1 THEN
                    txtCalcText = LEFT$(txtCalcText, LEN(txtCalcText) - 1)
                    Obj.DrawTxt txtCalc, Calc.FormatNum(txtCalcText), False
                END IF
            END IF

        END IF

    LOOP

    Sys.VGALoad "DESKTOP"

    Mouse.Show
    EXIT SUB

CalcErr:
    txtCalcText = "": Obj.DrawTxt txtCalc, "Overflow error", False
    TotalSum = 0: MathFunc = "": NumOps = 0: Op1 = 0: LastClick = ""
    GOTO StartOfCalc
END SUB

