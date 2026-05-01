program Calculator;

uses
	CostaLib, UIButton, UIArea, UITxtBox, UIFrame, MsgDlg, AboutDlg, Crt, Strings, Graph;

const
	AppName              = 'Calculator';
	AppVersion           = '2.0';
	AppAuthor            = 'Jacob Palm';
	AppIcon	             = 'CALC';

	DecimalSign          = '.';

	CAP_ABOUT            = #127 + 'About...';
	CAP_EXIT             = 'E' + #127 + 'xit';
	CAP_CLEAR            = #127 + 'C';
	CAP_CLEAR_EVERYTHING = 'C' + #127 + 'E';
	MSG_DIV_ZERO         = 'Division by zero';

type
	TOperand             = (opNone, opAdd, opSubtract, opMultiply, opDivide);

var
	App:                 PApplication;
	WinMain:             PWindow;
	FrmCalc:             PFrame;
	TxtCalc:             PTextbox;
	BtnNumb:             array[0..9] of PButton;
	BtnDecimal:          PButton;
	AreaLog:             PArea;
	BtnC,
	BtnCE,
	BtnAdd,
	BtnSubstract,
	BtnMultiply,
	BtnDivide,
	BtnEquals,
	BtnExit,
	BtnAbout:            PButton;

	HkBackspace,
	HkEscape:            PHotKey;

	Operand:	           TOperand; {Current operand selected}
	FirstNumber,
	SecondNumber:        Real;    {Numbers involved in calculation}
	DoingCalculation:    Boolean; {True if calculation is in progress, false if first number hasn't been entered yet}

function FormatNumber(TargetStr: string): string;
var
	IntPart, DecPart, ResultStr: string;
	IsNegative: Boolean;
	i, Len, Count: integer;
	DotPos: integer;
begin
	IsNegative := False;
	ResultStr := '';

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
		IsNegative := True;
		Delete(IntPart, 1, 1);
	end;

	{Insert commas every three digits in the integer part}
	Len := Length(IntPart);
	Count := 0;
	for i := Length(IntPart) downto 1 do
	begin
		ResultStr := IntPart[i] + ResultStr;
		Inc(Count);
		if (Count mod 3 = 0) and (i > 1) then
			ResultStr := ',' + ResultStr;
	end;

	if IsNegative then
		ResultStr := '-' + ResultStr;

	FormatNumber := ResultStr + DecPart;
end;

procedure LogLine(Text: string);
const
	MaxLogLines = 18;
	TopOffset = 52;
begin
	{Inc(LogLinesWritten);
	if LogLinesWritten > MaxLogLines then
	begin
		LogLinesWritten := 0;
		AreaLog.Draw;
	end;
	Print(Text, 624 - Length(Text) * 8, TopOffset + (LogLinesWritten * 15), Thm.WinText);}
end;

procedure Calculate;
begin
	{DEBUG - perform calculation based on Operand and update TxtCalc}
end;

procedure BtnNumbClick(Sender: PUIObject); far;
var
	NewText: string;
begin
	{DEBUG - check length + format output}
	NewText := TxtCalc^.GetText + PButton(Sender)^.GetCaption;
	TxtCalc^.SetText(NewText);
	Mouse.Hide;
	TxtCalc^.Draw;
	Mouse.Show;
end;

procedure BtnDecimalClick(Sender: PUIObject); far;
var
	OldText, NewText: string;
begin
	{DEBUG - check length}
	OldText := TxtCalc^.GetText;
	{If there is not already a decimal sign, add one}
	if Pos(DecimalSign, OldText) = 0 then
	begin
		NewText := OldText + DecimalSign;
		{If the text is empty, add a leading zero}
		if Length(NewText) = 1 then
			NewText := '0' + NewText;
		TxtCalc^.SetText(NewText);
		Mouse.Hide;
		TxtCalc^.Draw;
		Mouse.Show;
	end;
end;

procedure BtnCClick(Sender: PUIObject); far;
begin
	if Length(TxtCalc^.GetText) > 0 then
	begin
		TxtCalc^.SetText('');
		Mouse.Hide;
		TxtCalc^.Draw;
		Mouse.Show;
	end;
end;

procedure BtnCEClick(Sender: PUIObject); far;
begin
	{BtnCClick clears the textbox, reuse that and then clear working variables}
	BtnCClick(Sender);

	FirstNumber := 0;
	SecondNumber := 0;
	Operand := opNone;
end;

procedure BtnOperatorClick(Sender: PUIObject); far;
var
	ClickedBtn: PButton;
	ValCode: Integer;
begin
	{DEBUG - handle already stored operand, if any, and perform that calculation first}
	ClickedBtn := PButton(Sender);
	{if DoingCalculation and (Operand <> opNone) then
		Calculate
	else
	begin
		ValCode := 0;
		Val(TxtCalc^.GetText, FirstNumber, ValCode);
		if ValCode <> 0 then
			FirstNumber := 0;
		BtnCClick(Sender);
		DoingCalculation := True;
	end;}

	if ClickedBtn = BtnAdd then
		Operand := opAdd
	else if ClickedBtn = BtnSubstract then
		Operand := opSubtract
	else if ClickedBtn = BtnMultiply then
		Operand := opMultiply
	else if ClickedBtn = BtnDivide then
		Operand := opDivide
	else
		Operand := opNone;
end;

procedure BtnEqualsClick(Sender: PUIObject); far;
begin
end;

procedure HkBackSpaceClick(Sender: PUIObject); far;
begin
	{Remove last character from the textbox}
	if Length(TxtCalc^.GetText) > 0 then
	begin
		TxtCalc^.SetText(Copy(TxtCalc^.GetText, 1, Length(TxtCalc^.GetText) - 1));
		Mouse.Hide;
		TxtCalc^.Draw;
		Mouse.Show;
	end;
end;

procedure HkEscapeClick(Sender: PUIObject); far;
begin
	{If escape is pressed, clear the number. If it already is cleared,
	 clear everything}
	if Length(TxtCalc^.GetText) > 0 then
		BtnC^.Click
	else
		BtnCE^.Click;
end;

procedure BtnAboutClick(Sender: PUIObject); far;
begin
	AboutBox(App);
end;

procedure BtnExitClick(Sender: PUIObject); far;
begin
	App^.Terminate;
end;

procedure InitUI;
var
	i: Integer;
begin
	New(WinMain, Init(0, 0, nil));
	with WinMain^ do
	begin
		SetSize(GetMaxX, GetMaxY);
		RemoveState(SBordered);
	end;

	New(FrmCalc, Init(12, 42, WinMain));
	with FrmCalc^ do
	begin
		SetSize(218, 208);
	end;

	New(TxtCalc, Init(13, 12, '', FrmCalc));
	with TxtCalc^ do
	begin
		SetSize(191, SizeRetain);
		SetMaxLength(25);
		RemoveState(SEnabled);
	end;

	New(BtnNumb[0], Init(14, 172, '0', FrmCalc));
	With BtnNumb[0]^ do
	begin
		SetSize(90, SizeRetain);
		AddHotKey('0');
		SetOnClick(BtnNumbClick);
	end;
	New(BtnNumb[1], Init(14, 139, '1', FrmCalc));
	New(BtnNumb[2], Init(64, 139, '2', FrmCalc));
	New(BtnNumb[3], Init(114, 139, '3', FrmCalc));
	New(BtnNumb[4], Init(14, 106, '4', FrmCalc));
	New(BtnNumb[5], Init(64, 106, '5', FrmCalc));
	New(BtnNumb[6], Init(114, 106, '6', FrmCalc));
	New(BtnNumb[7], Init(14, 73, '7', FrmCalc));
	New(BtnNumb[8], Init(64, 73, '8', FrmCalc));
	New(BtnNumb[9], Init(114, 73, '9', FrmCalc));
	for i := 1 to 9 do
	begin
		BtnNumb[i]^.AddHotKey(Char(Ord('0') + i));
		BtnNumb[i]^.SetSize(40, SizeRetain);
		BtnNumb[i]^.SetOnClick(BtnNumbClick);
	end;
	New(BtnDecimal, Init(114, 172, '.', FrmCalc));
	With BtnDecimal^ do
	begin
		SetSize(40, SizeRetain);
		AddHotKey('.'); {Add both so it works with both decimal signs}
		AddHotKey(',');
		SetOnClick(BtnDecimalClick);
	end;

	{Clear and Clear Everything buttons}
	New(BtnC, Init(14, 40, CAP_CLEAR, FrmCalc));
	With BtnC^ do
	begin
		SetSize(40, SizeRetain);
		AddHotKey(KeyAltC);
		SetOnClick(BtnCClick);
	end;
	New(BtnCE, Init(64, 40, CAP_CLEAR_EVERYTHING, FrmCalc));
	With BtnCE^ do
	begin
		SetSize(40, SizeRetain);
		AddHotKey(KeyAltE);
		SetOnClick(BtnCEClick);
	end;

	{Operator buttons}
	New(BtnDivide, Init(114, 40, '/', FrmCalc));
	With BtnDivide^ do
	begin
		SetSize(40, SizeRetain);
		AddHotKey('/');
		SetOnClick(BtnOperatorClick);
	end;
	New(BtnMultiply, Init(164, 40, '*', FrmCalc));
	With BtnMultiply^ do
	begin
		SetSize(40, SizeRetain);
		AddHotKey('*');
		SetOnClick(BtnOperatorClick);
	end;
	New(BtnSubstract, Init(164, 73, '-', FrmCalc));
	With BtnSubstract^ do
	begin
		SetSize(40, SizeRetain);
		AddHotKey('-');
		SetOnClick(BtnOperatorClick);
	end;
	New(BtnAdd, Init(164, 106, '+', FrmCalc));
	With BtnAdd^ do
	begin
		SetSize(40, SizeRetain);
		AddHotKey('+');
		SetOnClick(BtnOperatorClick);
	end;

	New(BtnEquals, Init(164, 139, '=', FrmCalc));
	With BtnEquals^ do
	begin
		SetSize(40, 55);
		AddHotKey('=');
		AddHotKey(KeyEnter);
		SetOnClick(BtnEqualsClick);
	end;

	New(AreaLog, Init(242, 42, WinMain));
	with AreaLog^ do
	begin
		SetSize(385, 295);
	end;

	New(BtnAbout, Init(446, 2, CAP_ABOUT, WinMain));
	With BtnAbout^ do
	begin
		SetOnClick(BtnAboutClick);
		AddHotKey(KeyAltA);
	end;
	New(BtnExit, Init(545, 2, CAP_EXIT, WinMain));
	With BtnExit^ do
	begin
		SetOnClick(BtnExitClick);
		AddHotKey(KeyAltX);
		AddHotKey(KeyAltF4);
	end;

	New(HkBackspace, Init(KeyBackspace, WinMain));
	HkBackspace^.SetOnClick(HkBackSpaceClick);
	New(HkEscape, Init(KeyEscape, WinMain));
	HkEscape^.SetOnClick(HkEscapeClick);
end;

begin
	New(App, Init);
	App^.SetInfo(AppName, AppVersion, AppAuthor, AppIcon);

	InitUI;

	App^.OpenWindow(WinMain);
	App^.Run;
end.