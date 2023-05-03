OPTION EXPLICIT
DEFINT A-Z

DECLARE FUNCTION Calc.FormatNum (TargetStr AS STRING) AS STRING
DECLARE SUB Calc.LogLine (Text AS STRING, TargetTxt AS ANY)
DECLARE SUB Calc.Main ()

'$INCLUDE: 'C:\COSTA\SOURCE\COSTALIB.BI'

DIM SHARED LogLinesWritten

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

SUB Calc.LogLine (Text AS STRING, TargetTxt AS TextboxType)

  CONST MaxLogLines = 18
  CONST TopOffset = 52
  
  LogLinesWritten = LogLinesWritten + 1

  IF LogLinesWritten > MaxLogLines THEN
    LogLinesWritten = 0
    Obj.DrawTxt TargetTxt, "", False
  END IF

  Mouse.Hide
  Font.Print Text, 624 - LEN(Text) * 8, TopOffset + (LogLinesWritten * 15), Theme.WindowText, FontSystem
  Mouse.Show
  
END SUB

' =========================================================================
'          NAME: Calc.Main()
'    PARAMETERS: TargetLink - the position in the DeskLink array
'                             containing the link to launch
'       RETURNS: Nothing
'       ASSUMES: That the array position in the DeskLink array exists
'   CALLED FROM: CALC.BAS
' -------------------------------------------------------------------------
'   DESCRIPTION: The calculator accessory. Draws the UI and handles main
'                logic
' =========================================================================
SUB Calc.Main ()

    DIM frmCalc AS FrameType
    DIM txtCalc AS TextboxType, txtResults AS TextboxType
    DIM btnNumb(0 TO 9) AS ButtonType
    DIM btnC AS ButtonType, btnCE AS ButtonType, btnDivide AS ButtonType
    DIM btnMulti AS ButtonType, btnMinus AS ButtonType, btnPlus AS ButtonType
    DIM btnEquals AS ButtonType, btnDot AS ButtonType, btnExit AS ButtonType
    DIM btnCount
    DIM MathFunc AS STRING * 1
    DIM TotalSum AS CURRENCY, Op1 AS CURRENCY, Op2 AS CURRENCY, NumOps
    DIM Key$, txtCalcText AS STRING, LastClick AS STRING
    
    Obj.SetSize frmCalc.Pos, 12, 42, 218, 208
    Obj.SetSize txtCalc.Pos, 25, frmCalc.Pos.Top + 12, 191, 22
    Obj.SetSize btnNumb(0).Pos, 26, frmCalc.Pos.Top + 172, 90, 22
    Obj.SetSize btnNumb(1).Pos, 26, frmCalc.Pos.Top + 139, 40, 22
    Obj.SetSize btnNumb(2).Pos, 76, frmCalc.Pos.Top + 139, 40, 22
    Obj.SetSize btnNumb(3).Pos, 126, frmCalc.Pos.Top + 139, 40, 22
    Obj.SetSize btnNumb(4).Pos, 26, frmCalc.Pos.Top + 106, 40, 22
    Obj.SetSize btnNumb(5).Pos, 76, frmCalc.Pos.Top + 106, 40, 22
    Obj.SetSize btnNumb(6).Pos, 126, frmCalc.Pos.Top + 106, 40, 22
    Obj.SetSize btnNumb(7).Pos, 26, frmCalc.Pos.Top + 73, 40, 22
    Obj.SetSize btnNumb(8).Pos, 76, frmCalc.Pos.Top + 73, 40, 22
    Obj.SetSize btnNumb(9).Pos, 126, frmCalc.Pos.Top + 73, 40, 22
    Obj.SetSize btnC.Pos, 26, frmCalc.Pos.Top + 40, 40, 22
    Obj.SetSize btnCE.Pos, 76, frmCalc.Pos.Top + 40, 40, 22
    Obj.SetSize btnDivide.Pos, 126, frmCalc.Pos.Top + 40, 40, 22
    Obj.SetSize btnDot.Pos, 126, frmCalc.Pos.Top + 172, 40, 22
    Obj.SetSize btnMulti.Pos, 176, frmCalc.Pos.Top + 40, 40, 22
    Obj.SetSize btnMinus.Pos, 176, frmCalc.Pos.Top + 73, 40, 22
    Obj.SetSize btnPlus.Pos, 176, frmCalc.Pos.Top + 106, 40, 22
    Obj.SetSize btnEquals.Pos, 176, frmCalc.Pos.Top + 139, 40, 55

    Obj.SetSize txtResults.Pos, frmCalc.Pos.Left + frmCalc.Pos.Width + 12, frmCalc.Pos.Top, 385, 295

    Obj.SetSize btnExit.Pos, 545, 2, 92, 22
    
    btnC.Caption = "õC"
    btnCE.Caption = "CõE"
    btnDivide.Caption = "/"
    btnDot.Caption = "."
    btnMulti.Caption = "*"
    btnMinus.Caption = "-"
    btnPlus.Caption = "+"
    btnEquals.Caption = "="
    btnExit.Caption = "Eõxit"
    txtCalc.MaxLen = 25

    Mouse.Hide
    LINE (0, 29)-(639, 349), Theme.Window, BF
    Mouse.Show
    Obj.DrawMenu

    Obj.DrawFrm frmCalc, 15, Theme.Shadow
    Obj.DrawTxt txtCalc, "", False
    FOR btnCount = 0 TO 9
        btnNumb(btnCount).Caption = LTRIM$(STR$(btnCount))
        Obj.DrawBtn btnNumb(btnCount), False
    NEXT
    Obj.DrawBtn btnC, False: Obj.DrawBtn btnCE, False: Obj.DrawBtn btnDivide, False
    Obj.DrawBtn btnMulti, False: Obj.DrawBtn btnMinus, False: Obj.DrawBtn btnPlus, False
    Obj.DrawBtn btnEquals, False: Obj.DrawBtn btnDot, False: Obj.DrawBtn btnExit, False

    Obj.DrawTxt txtResults, "", False
    Mouse.Show

    LogLinesWritten = -1

    ON LOCAL ERROR GOTO CalcErr

StartOfCalc:

    DO
        Key$ = LCASE$(INKEY$)

        IF Obj.BtnClick(btnExit) OR Key$ = "x" OR Key$ = CHR$(27) THEN
            EXIT DO
        END IF

        FOR btnCount = 0 TO 9
            IF Obj.BtnClick(btnNumb(btnCount)) OR Key$ = LTRIM$(STR$(btnCount)) THEN
                IF LEN(txtCalcText) < 22 THEN
                    Key$ = LTRIM$(STR$(btnCount))
                    IF NOT (Key$ = "0" AND txtCalcText = "0") THEN
                        IF LastClick = "EQUAL" THEN
                          NumOps = 0
                          Op1 = 0
                          Calc.LogLine "", txtResults
                        END IF
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
            Calc.LogLine "", txtResults
            TotalSum = 0: MathFunc = "": NumOps = 0: Op1 = 0: LastClick = ""
        END IF

        IF Obj.BtnClick(btnDot) OR (Key$ = "." OR Key$ = ",") THEN
            IF LEN(txtCalcText) < 22 AND (INSTR(txtCalcText$, ".") = 0) THEN
                IF LastClick = "EQUAL" THEN
                  NumOps = 0
                  Op1 = 0
                END IF
                LastClick = "NUMB"
                IF txtCalcText = "" THEN txtCalcText = "0"
                txtCalcText = txtCalcText + "."
                Obj.DrawTxt txtCalc, Calc.FormatNum(txtCalcText), False
            END IF
        END IF

        IF Obj.BtnClick(btnEquals) OR Key$ = "=" OR Key$ = CHR$(13) THEN
            IF NumOps = 1 AND LastClick = "NUMB" THEN
                Op1 = VAL(txtCalcText)
                Calc.LogLine MathFunc + " " + Calc.FormatNum(LTRIM$(STR$(Op1))), txtResults

                IF MathFunc = "+" THEN TotalSum = TotalSum + Op1
                IF MathFunc = "-" THEN TotalSum = TotalSum - Op1
                IF MathFunc = "*" THEN TotalSum = TotalSum * Op1
                IF MathFunc = "/" THEN
                    IF NOT Op1 = 0 THEN
                        TotalSum = TotalSum / Op1
                    ELSE
                        txtCalcText = ""
                        Obj.DrawTxt txtCalc, "Division by zero", False
                        TotalSum = 0
                        MathFunc = ""
                        NumOps = 0
                        Op1 = 0
                        LastClick = ""
                        Calc.LogLine "Division by zero", txtResults
                        Calc.LogLine "", txtResults
                        GOTO StartOfCalc
                    END IF
                END IF
                
                Calc.LogLine "= " + Calc.FormatNum(LTRIM$(STR$(TotalSum))), txtResults
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
                    Calc.LogLine MathFunc + " " + Calc.FormatNum(LTRIM$(STR$(Op1))), txtResults
                    IF MathFunc = "+" THEN TotalSum = TotalSum + Op1
                    IF MathFunc = "-" THEN TotalSum = TotalSum - Op1
                    IF MathFunc = "*" THEN TotalSum = TotalSum * Op1
                    IF MathFunc = "/" THEN
                        IF NOT Op1 = 0 THEN
                            TotalSum = TotalSum / Op1
                        ELSE
                            txtCalcText = ""
                            Obj.DrawTxt txtCalc, "Division by zero", False
                            TotalSum = 0
                            MathFunc = ""
                            NumOps = 0
                            Op1 = 0
                            LastClick = ""
                            Calc.LogLine "Division by zero", txtResults
                            Calc.LogLine "", txtResults
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
                    Calc.LogLine Calc.FormatNum(LTRIM$(STR$(TotalSum))), txtResults
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

    EXIT SUB

CalcErr:
    txtCalcText = "": Obj.DrawTxt txtCalc, "", False
    Calc.LogLine "Overflow error", txtResults
    TotalSum = 0: MathFunc = "": NumOps = 0: Op1 = 0: LastClick = ""
    RESUME NEXT
END SUB

