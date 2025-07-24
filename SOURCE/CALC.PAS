program Calculator;

uses
	CostaLib, Crt, Strings, Graph;

const
	AppName    = 'Calculator';
	AppVersion = '2.0';
	AppAuthor  = 'Jacob Palm';

var
	LogLinesWritten: Integer;
	FrmCalc: TFrame;
	TxtCalc, TxtResults: TTextbox;
	BtnNumb: array[0..9] of TButton;
	BtnC, BtnCE, BtnDivide, BtnMulti, BtnMinus, BtnPlus: TButton;
	BtnEquals, BtnDot, BtnExit, BtnAbout: TButton;
	i: Integer;
	MathFunc: string[1];
	TotalSum, Op1: Integer;
	NumOps: Integer;
	Key, LastClick: string;
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

procedure Calc_LogLine(Text: string; var TargetTxt: TTextbox);
const
	MaxLogLines = 18;
	TopOffset = 52;
begin
	Inc(LogLinesWritten);
	if LogLinesWritten > MaxLogLines then
	begin
		LogLinesWritten := 0;
		TargetTxt.Draw;
	end;
	Print(Text, 624 - Length(Text) * 8, TopOffset + (LogLinesWritten * 15), Thm.WinText);
end;

begin
	LogLinesWritten := 0;
	
	FrmCalc.Init(12, 42, 218, 208);
	TxtCalc.Init(25, FrmCalc.Top + 12, 191, SizeDefault);
	BtnNumb[0].Init(26, FrmCalc.Top + 172, 90, SizeDefault, '0');
	BtnNumb[1].Init(26, FrmCalc.Top + 139, 40, SizeDefault, '1');
	BtnNumb[2].Init(76, FrmCalc.Top + 139, 40, SizeDefault, '2');
	BtnNumb[3].Init(126, FrmCalc.Top + 139, 40, SizeDefault, '3');
	BtnNumb[4].Init(26, FrmCalc.Top + 106, 40, SizeDefault, '4');
	BtnNumb[5].Init(76, FrmCalc.Top + 106, 40, SizeDefault, '5');
	BtnNumb[6].Init(126, FrmCalc.Top + 106, 40, SizeDefault, '6');
	BtnNumb[7].Init(26, FrmCalc.Top + 73, 40, SizeDefault, '7');
	BtnNumb[8].Init(76, FrmCalc.Top + 73, 40, SizeDefault, '8');
	BtnNumb[9].Init(126, FrmCalc.Top + 73, 40, SizeDefault, '9');
	BtnC.Init(26, FrmCalc.Top + 40, 40, SizeDefault, HotkeySymbol + 'C');
	BtnCE.Init(76, FrmCalc.Top + 40, 40, SizeDefault, 'C' + HotkeySymbol + 'E');
	BtnDivide.Init(126, FrmCalc.Top + 40, 40, SizeDefault, '/');
	BtnDot.Init(126, FrmCalc.Top + 172, 40, SizeDefault, '.');
	BtnMulti.Init(176, FrmCalc.Top + 40, 40, SizeDefault, '*');
	BtnMinus.Init(176, FrmCalc.Top + 73, 40, SizeDefault, '-');
	BtnPlus.Init(176, FrmCalc.Top + 106, 40, SizeDefault, '+');
	BtnEquals.Init(176, FrmCalc.Top + 139, 40, 55, '=');

	TxtResults.Init(FrmCalc.Left + FrmCalc.Width + 12, FrmCalc.Top, 385, 295);

	BtnAbout.Init(446, 2, SizeDefault, SizeDefault, HotkeySymbol + 'About...');
	BtnExit.Init(545, 2, SizeDefault, SizeDefault, 'E' + HotkeySymbol + 'xit');

	TxtCalc.MaxLen := 25;

	MouseHide;
	MenuBar.Draw;
	SetColor(Thm.Win); Bar(0, 29, 639, 349);

	FrmCalc.Draw;
	TxtCalc.Draw;
	for i := 0 to 9 do
		BtnNumb[i].Draw;
	BtnC.Draw; BtnCE.Draw; BtnDivide.Draw;
	BtnMulti.Draw; BtnMinus.Draw; BtnPlus.Draw;
	BtnEquals.Draw; BtnDot.Draw; BtnExit.Draw;
	BtnAbout.Draw;

	TxtResults.Draw;
	MouseShow;

	LogLinesWritten := -1;

	{ Main calculator loop }
	repeat
		Key := GetKey;

		if ObjBtnClick(BtnExit) or (Key = KeyAltX) or (Key = KeyAltF4) then
		begin
			MouseHide;
			CloseGraph;
			Halt;
		end;

		if ObjBtnClick(BtnAbout) or (Key = KeyAltA) then
			AboutBox(AppName, AppVersion, AppAuthor, 'CALC');

		for i := 0 to 9 do
		begin
			Str(i, ch);
			if ObjBtnClick(BtnNumb[i]) or (Key = ch) then
			begin
				TxtCalc.Text := TxtCalc.Text + ch;
				MouseHide;
				TxtCalc.Draw;
				MouseShow;
			end;
		end;

		if ObjBtnClick(BtnC) or (Key = 'c') then
		begin
			TxtCalc.Text := '';
			MouseHide;
			TxtCalc.Draw;
			MouseShow;
		end;

		if ObjBtnClick(BtnCE) or (Key = 'e') then
		begin
			TxtCalc.Text := '';
			MouseHide;
			TxtCalc.Draw;
			Calc_LogLine('', TxtResults);
			MouseShow;
			MathFunc := '';
			NumOps := 0;
			Op1 := 0;
			LastClick := '';
		end;

		if ObjBtnClick(BtnDot) or ((Key = '.') or (Key = ',')) then
		begin
			if (Length(TxtCalc.Text) < 22) and (Pos('.', TxtCalc.Text) = 0) then
			begin
				if LastClick = 'EQUAL' then
				begin
					NumOps := 0;
					Op1 := 0;
				end;
				LastClick := 'NUMB';
				if TxtCalc.Text = '' then TxtCalc.Text := '0';
				TxtCalc.Text := TxtCalc.Text + '.';
				MouseHide;
				TxtCalc.Text := Calc_FormatNum(TxtCalc.Text);
				TxtCalc.Draw;
				MouseShow;
			end;
		end;

		if ObjBtnClick(BtnEquals) or (Key = '=') or (Key = KeyEnter) then
		begin
			
		end;

		if ObjBtnClick(BtnMulti) then Key := '*';
		if ObjBtnClick(BtnDivide) then Key := '/';
		if ObjBtnClick(BtnPlus) then Key := '+';
		if ObjBtnClick(BtnMinus) then Key := '-';

	until False;

end.