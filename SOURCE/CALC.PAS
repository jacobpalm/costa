program Calc;

uses
  CostaLib, Crt, Strings, Graph;

const
  AppName = 'Calculator';
  AppVersion = '2.0';
  AppAuthor = 'Jacob Palm';

var
  LogLinesWritten: Integer;
  frmCalc: FrameType;
  txtCalc, txtResults: TextboxType;
  btnNumb: array[0..9] of ButtonType;
  btnC, btnCE, btnDivide, btnMulti, btnMinus, btnPlus, btnEquals, btnDot, btnExit, btnAbout: ButtonType;
  btnCount: Integer;
  MathFunc: string[1];
  TotalSum, Op1: Integer;
  NumOps: Integer;
  KeyStr, txtCalcText, LastClick: string;
  ch: Char;
  CalcErr: Boolean;
  TempGraphMode, TempMax: Integer;
  TempDriver: String;

function Calc_FormatNum(TargetStr: string): string;
var
  BeforeDot, AfterDot, TempStr: string;
  i: Integer;
begin
  AfterDot := '';
  i := Pos('.', TargetStr);
  if i > 0 then
  begin
    BeforeDot := Copy(TargetStr, 1, i-1);
    AfterDot := Copy(TargetStr, i+1, Length(TargetStr)-i);
  end
  else
    BeforeDot := TargetStr;
  TempStr := '';
  while Length(BeforeDot) > 3 do
  begin
    TempStr := ',' + Copy(BeforeDot, Length(BeforeDot)-2, 3) + TempStr;
    BeforeDot := Copy(BeforeDot, 1, Length(BeforeDot)-3);
  end;
  BeforeDot := BeforeDot + TempStr;
  if AfterDot = '' then
    Calc_FormatNum := BeforeDot
  else
    Calc_FormatNum := BeforeDot + '.' + AfterDot;
end;

procedure Calc_LogLine(Text: string; var TargetTxt: TextboxType);
const
  MaxLogLines = 18;
  TopOffset = 52;
begin
  Inc(LogLinesWritten);
  if LogLinesWritten > MaxLogLines then
  begin
    LogLinesWritten := 0;
    ObjDrawTxt(TargetTxt, '', False);
  end;
  FontPrint(Text, 624 - Length(Text) * 8, TopOffset + (LogLinesWritten * 15), Theme.WindowText, FontHeading);
end;

begin
  LogLinesWritten := 0;
  ObjSetSize(frmCalc.Pos, 12, 42, 218, 208);
  ObjSetSize(txtCalc.Pos, 25, frmCalc.Pos.Top + 12, 191, 22);
  ObjSetSize(btnNumb[0].Pos, 26, frmCalc.Pos.Top + 172, 90, 22);
  ObjSetSize(btnNumb[1].Pos, 26, frmCalc.Pos.Top + 139, 40, 22);
  ObjSetSize(btnNumb[2].Pos, 76, frmCalc.Pos.Top + 139, 40, 22);
  ObjSetSize(btnNumb[3].Pos, 126, frmCalc.Pos.Top + 139, 40, 22);
  ObjSetSize(btnNumb[4].Pos, 26, frmCalc.Pos.Top + 106, 40, 22);
  ObjSetSize(btnNumb[5].Pos, 76, frmCalc.Pos.Top + 106, 40, 22);
  ObjSetSize(btnNumb[6].Pos, 126, frmCalc.Pos.Top + 106, 40, 22);
  ObjSetSize(btnNumb[7].Pos, 26, frmCalc.Pos.Top + 73, 40, 22);
  ObjSetSize(btnNumb[8].Pos, 76, frmCalc.Pos.Top + 73, 40, 22);
  ObjSetSize(btnNumb[9].Pos, 126, frmCalc.Pos.Top + 73, 40, 22);
  ObjSetSize(btnC.Pos, 26, frmCalc.Pos.Top + 40, 40, 22);
  ObjSetSize(btnCE.Pos, 76, frmCalc.Pos.Top + 40, 40, 22);
  ObjSetSize(btnDivide.Pos, 126, frmCalc.Pos.Top + 40, 40, 22);
  ObjSetSize(btnDot.Pos, 126, frmCalc.Pos.Top + 172, 40, 22);
  ObjSetSize(btnMulti.Pos, 176, frmCalc.Pos.Top + 40, 40, 22);
  ObjSetSize(btnMinus.Pos, 176, frmCalc.Pos.Top + 73, 40, 22);
  ObjSetSize(btnPlus.Pos, 176, frmCalc.Pos.Top + 106, 40, 22);
  ObjSetSize(btnEquals.Pos, 176, frmCalc.Pos.Top + 139, 40, 55);

  ObjSetSize(txtResults.Pos, frmCalc.Pos.Left + frmCalc.Pos.Width + 12, frmCalc.Pos.Top, 385, 295);

  ObjSetSize(btnAbout.Pos, 446, 2, 92, 22);
  ObjSetSize(btnExit.Pos, 545, 2, 92, 22);

  btnC.Caption := 'C';
  btnCE.Caption := 'CE';
  btnDivide.Caption := '/';
  btnDot.Caption := '.';
  btnMulti.Caption := '*';
  btnMinus.Caption := '-';
  btnPlus.Caption := '+';
  btnEquals.Caption := '=';
  btnAbout.Caption := 'About...';
  btnExit.Caption := 'Exit';
  txtCalc.MaxLen := 25;

  MouseHide;
  ObjDrawMenu;
  SetColor(Theme.Window); Bar(0, 29, 639, 349);

  ObjDrawFrm(frmCalc, 15, Theme.Shadow);
  ObjDrawTxt(txtCalc, '', False);
  for btnCount := 0 to 9 do
  begin
    Str(btnCount, btnNumb[btnCount].Caption);
    ObjDrawBtn(btnNumb[btnCount], False);
  end;
  ObjDrawBtn(btnC, False); ObjDrawBtn(btnCE, False); ObjDrawBtn(btnDivide, False);
  ObjDrawBtn(btnMulti, False); ObjDrawBtn(btnMinus, False); ObjDrawBtn(btnPlus, False);
  ObjDrawBtn(btnEquals, False); ObjDrawBtn(btnDot, False); ObjDrawBtn(btnExit, False);
  ObjDrawBtn(btnAbout, False);

  ObjDrawTxt(txtResults, '', False);
  MouseShow;

  LogLinesWritten := -1;

  { Main calculator loop }
  repeat
    KeyStr := '';
    if KeyPressed then
    begin
      ch := ReadKey;
      KeyStr := LowerCase(ch);
    end;

    if ObjBtnClick(btnExit) or (KeyStr = 'x') or (KeyStr = #27) then
    begin
      MouseHide;
      CloseGraph;
      Halt;
    end;

    if ObjBtnClick(btnAbout) or (KeyStr = 'a') then
      SysAboutBox(AppName, AppVersion, AppAuthor, 'CALC');

    for btnCount := 0 to 9 do
    begin
      if ObjBtnClick(btnNumb[btnCount]) then {or (KeyStr = IntToStr(btnCount)) then}
      begin
        
      end;
    end;

    if ObjBtnClick(btnC) or (KeyStr = 'c') then
    begin
      txtCalcText := '';
      MouseHide;
      ObjDrawTxt(txtCalc, '', False);
      MouseShow;
      SysMsgBox('Calculator', 'Cleared the calculator input.' + #13 + 'It was hard but I did it.', msgError);
       {Just debug stuff, remove later}
    end;

    if ObjBtnClick(btnCE) or (KeyStr = 'e') then
    begin
      txtCalcText := '';
      MouseHide;
      ObjDrawTxt(txtCalc, '', False);
      Calc_LogLine('', txtResults);
      MouseShow;
      MathFunc := '';
      NumOps := 0;
      Op1 := 0;
      LastClick := '';
    end;

    if ObjBtnClick(btnDot) or ((KeyStr = '.') or (KeyStr = ',')) then
    begin
      if (Length(txtCalcText) < 22) and (Pos('.', txtCalcText) = 0) then
      begin
        if LastClick = 'EQUAL' then
        begin
          NumOps := 0;
          Op1 := 0;
        end;
        LastClick := 'NUMB';
        if txtCalcText = '' then txtCalcText := '0';
        txtCalcText := txtCalcText + '.';
        MouseHide;
        ObjDrawTxt(txtCalc, Calc_FormatNum(txtCalcText), False);
        MouseShow;
      end;
    end;

    if ObjBtnClick(btnEquals) or (KeyStr = '=') or (KeyStr = #13) then
    begin
      
    end;

    if ObjBtnClick(btnMulti) then KeyStr := '*';
    if ObjBtnClick(btnDivide) then KeyStr := '/';
    if ObjBtnClick(btnPlus) then KeyStr := '+';
    if ObjBtnClick(btnMinus) then KeyStr := '-';

    

  until False;

end.