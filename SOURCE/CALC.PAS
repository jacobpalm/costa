program Calculator;

uses
	CostaLib, Crt, Strings, Graph;

const
	AppName    = 'Calculator';
	AppVersion = '2.0';
	AppAuthor  = 'Jacob Palm';

var
	LogLinesWritten: Integer;
	frmCalc: FrameType;
	txtCalc, txtResults: TextboxType;
	btnNumb: array[0..9] of ButtonType;
	btnC, btnCE, btnDivide, btnMulti, btnMinus, btnPlus: ButtonType;
	btnEquals, btnDot, btnExit, btnAbout: ButtonType;
	i: Integer;
	MathFunc: string[1];
	TotalSum, Op1: Integer;
	NumOps: Integer;
	Key, txtCalcText, LastClick: string;
	ch: string[1];
	CalcErr: Boolean;

function Calc_FormatNum(TargetStr: string): string;
var
	IntPart, DecPart, TempStr, SignStr: string;
	i, Len, Count: integer;
	DotPos: integer;
begin
	SignStr := '';
	TempStr := '';
	
	{Remove decimals if any, and add again later}
	DotPos := Pos('.', TargetStr);
	if DotPos > 0 then
	begin
		IntPart := Copy(TargetStr, 1, DotPos - 1);
		DecPart := Copy(TargetStr, DotPos, Length(TargetStr) - DotPos + 1);
	end
	else
	begin
		IntPart := TargetStr;
		DecPart := '';
	end;

	{If first sign is a minus, remove it and add again later}
	if (Length(IntPart) > 0) and (IntPart[1] = '-') then
	begin
		SignStr := IntPart[1];
		Delete(IntPart, 1, 1);
	end;

	{Insert commas every three digits in the integer part}
	Len := Length(IntPart);
	Count := 0;
	for i := Length(IntPart) downto 1 do
	begin
		TempStr := IntPart[i] + TempStr;
		Inc(Count);
		if (Count mod 3 = 0) and (i > 1) then
			TempStr := ',' + TempStr;
	end;

	Calc_FormatNum := SignStr + TempStr + DecPart;
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
	FontPrint(Text, 624 - Length(Text) * 8, TopOffset + (LogLinesWritten * 15), Theme.WindowText);
end;

begin
	LogLinesWritten := 0;
	
	frmCalc.Init(12, 42, 218, 208);
	txtCalc.Init(25, frmCalc.Pos.Top + 12, 191, sizeDefault);
	btnNumb[0].Init(26, frmCalc.Pos.Top + 172, 90, sizeDefault, '0');
	btnNumb[1].Init(26, frmCalc.Pos.Top + 139, 40, sizeDefault, '1');
	btnNumb[2].Init(76, frmCalc.Pos.Top + 139, 40, sizeDefault, '2');
	btnNumb[3].Init(126, frmCalc.Pos.Top + 139, 40, sizeDefault, '3');
	btnNumb[4].Init(26, frmCalc.Pos.Top + 106, 40, sizeDefault, '4');
	btnNumb[5].Init(76, frmCalc.Pos.Top + 106, 40, sizeDefault, '5');
	btnNumb[6].Init(126, frmCalc.Pos.Top + 106, 40, sizeDefault, '6');
	btnNumb[7].Init(26, frmCalc.Pos.Top + 73, 40, sizeDefault, '7');
	btnNumb[8].Init(76, frmCalc.Pos.Top + 73, 40, sizeDefault, '8');
	btnNumb[9].Init(126, frmCalc.Pos.Top + 73, 40, sizeDefault, '9');
	btnC.Init(26, frmCalc.Pos.Top + 40, 40, sizeDefault, HotkeySymbol + 'C');
	btnCE.Init(76, frmCalc.Pos.Top + 40, 40, sizeDefault, 'C' + HotkeySymbol + 'E');
	btnDivide.Init(126, frmCalc.Pos.Top + 40, 40, sizeDefault, '/');
	btnDot.Init(126, frmCalc.Pos.Top + 172, 40, sizeDefault, '.');
	btnMulti.Init(176, frmCalc.Pos.Top + 40, 40, sizeDefault, '*');
	btnMinus.Init(176, frmCalc.Pos.Top + 73, 40, sizeDefault, '-');
	btnPlus.Init(176, frmCalc.Pos.Top + 106, 40, sizeDefault, '+');
	btnEquals.Init(176, frmCalc.Pos.Top + 139, 40, 55, '=');

	txtResults.Init(frmCalc.Pos.Left + frmCalc.Pos.Width + 12, frmCalc.Pos.Top, 385, 295);

	btnAbout.Init(446, 2, sizeDefault, sizeDefault, HotkeySymbol + 'About...');
	btnExit.Init(545, 2, sizeDefault, sizeDefault, 'E' + HotkeySymbol + 'xit');

	txtCalc.MaxLen := 25;

	MouseHide;
	ObjDrawMenu;
	SetColor(Theme.Window); Bar(0, 29, 639, 349);

	ObjDrawFrm(frmCalc, 15, Theme.Shadow);
	ObjDrawTxt(txtCalc, '', False);
	for i := 0 to 9 do
		btnNumb[i].Draw;
	btnC.Draw; btnCE.Draw; btnDivide.Draw;
	btnMulti.Draw; btnMinus.Draw; btnPlus.Draw;
	btnEquals.Draw; btnDot.Draw; btnExit.Draw;
	btnAbout.Draw;

	ObjDrawTxt(txtResults, '', False);
	MouseShow;

	LogLinesWritten := -1;

	{ Main calculator loop }
	repeat
		Key := GetKey;

		if ObjBtnClick(btnExit) or (Key = KeyAltX) or (Key = KeyAltF4) then
		begin
			MouseHide;
			CloseGraph;
			Halt;
		end;

		if ObjBtnClick(btnAbout) or (Key = KeyAltA) then
			SysAboutBox(AppName, AppVersion, AppAuthor, 'CALC');

		for i := 0 to 9 do
		begin
			Str(i, ch);
			if ObjBtnClick(btnNumb[i]) or (Key = ch) then
			begin
				txtCalcText := txtCalcText + ch;
				MouseHide;
				ObjDrawTxt(txtCalc, Calc_FormatNum(txtCalcText), False);
				MouseShow;
			end;
		end;

		if ObjBtnClick(btnC) or (Key = 'c') then
		begin
			txtCalcText := '';
			MouseHide;
			ObjDrawTxt(txtCalc, '', False);
			MouseShow;
		end;

		if ObjBtnClick(btnCE) or (Key = 'e') then
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

		if ObjBtnClick(btnDot) or ((Key = '.') or (Key = ',')) then
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

		if ObjBtnClick(btnEquals) or (Key = '=') or (Key = KeyEnter) then
		begin
			
		end;

		if ObjBtnClick(btnMulti) then Key := '*';
		if ObjBtnClick(btnDivide) then Key := '/';
		if ObjBtnClick(btnPlus) then Key := '+';
		if ObjBtnClick(btnMinus) then Key := '-';

	until False;

end.