program Calculator;

uses
	CostaLib, UIButton, UIArea, UITxtBox, UIFrame, AboutDlg, Crt, Strings, Graph;

const
	AppName              = 'Calculator';
	AppVersion           = '2.0';
	AppAuthor            = 'Jacob Palm';
	AppIcon	             = 'CALC';

	CAP_ABOUT            = #127 + 'About...';
	CAP_EXIT             = 'E' + #127 + 'xit';
	CAP_CLEAR            = #127 + 'C';
	CAP_CLEAR_EVERYTHING = 'C' + #127 + 'E';
	MSG_DIV_ZERO         = 'Division by zero';

	DecimalDigits        = 6;    {Amount of decimal digits to show in results - only affects display}

type
	TOperand             = (opNone, opAdd, opSubtract, opMultiply, opDivide);

var
	App:                 PApplication;
	WinMain:             PWindow;
	FrmCalc:             PFrame;
	TxtCalc:             PTextbox;
	BtnNumb:             Array[0..9] of PButton;
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

	CurrentInput:        String;   {Current value in calculator display}
	Op:	                 TOperand; {Current operand selected}
	Num1,
	Num2:                Real;     {Numbers involved in calculation}

	LastOp:              TOperand; {Operand and number from last calculation}
	LastNum:             Real;

	ResultValue:         Real;

	NewInput:            Boolean;  {Tracks if display needs to be cleared when entering a new number}

{Updates the text in the display, by formatting the number in CurrentInput with
 thousands seperators and setting textbox caption to the formatted string}
procedure UpdateDisplay;
var
	IntPart, DecPart, ResultStr: string;
	IsNegative: Boolean;
	i, Len, Count: integer;
	DotPos: integer;
begin
	IsNegative := False;
	ResultStr := '';

	{If first sign is a minus, remove it and add again later so it doesn't affect formatting of
	 thousands}
	if (Length(IntPart) > 0) and (IntPart[1] = '-') then
	begin
		IsNegative := True;
		Delete(IntPart, 1, 1);
	end;

	{Remove decimals if any, and add again later}
	DotPos := Pos(DecimalSign, CurrentInput);
	if DotPos > 0 then
	begin
		IntPart := Copy(CurrentInput, 1, DotPos - 1);
		DecPart := Copy(CurrentInput, DotPos, Length(CurrentInput) - DotPos + 1);

		{Remove trailing zeros from decimal part}
		while (Length(DecPart) > 0) and (DecPart[Length(DecPart)] = '0') do
      Delete(DecPart, Length(DecPart), 1);

		{If only decimal seperator remains, remove that too as we are dealing with an integer}
		if DecPart = DecimalSign then
			DecPart := '';
	end
	else
	begin
		{No decimals to deal with}
		IntPart := CurrentInput;
		DecPart := '';
	end;

	{Insert commas every three digits in the integer part}
	Len := Length(IntPart);
	Count := 0;
	for i := Length(IntPart) downto 1 do
	begin
		ResultStr := IntPart[i] + ResultStr;
		Inc(Count);
		if (Count mod 3 = 0) and (i > 1) then
			ResultStr := ThousandsSign + ResultStr;
	end;

	{Add back minus if it was removed earlier}
	if IsNegative then
		ResultStr := '-' + ResultStr;

	{Add back the decimal part, if any}
	ResultStr := ResultStr + DecPart;

	{If display is empty, show a zero}
	If ResultStr = '' then
		ResultStr := '0';

	TxtCalc^.SetText(ResultStr);
	Mouse.Hide;
	TxtCalc^.Draw;
	Mouse.Show;
end;

function StringToReal(S : string) : Real;
var
  R : Real;
  Code : Integer;
begin
  Val(S, R, Code);

  if Code <> 0 then
    R := 0;

  StringToReal := R;
end;

procedure ExecuteOperation;
begin
  case Op of

    opAdd:
      ResultValue := Num1 + Num2;

    opSubtract:
      ResultValue := Num1 - Num2;

    opMultiply:
      ResultValue := Num1 * Num2;

    opDivide:
      begin
        if Num2 <> 0 then
          ResultValue := Num1 / Num2
        else
        begin
          {DEBUG - handle division by zero}

        end;
      end;
  end;
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

procedure BtnNumbClick(Sender: PUIObject); far;
begin
	{DEBUG - check length + format output}
	if NewInput then
  begin
    CurrentInput := '';
    NewInput := False;
  end;

  CurrentInput := CurrentInput + PButton(Sender)^.GetCaption;
  UpdateDisplay;
end;

procedure BtnDecimalClick(Sender: PUIObject); far;
begin
	{If there is not already a decimal sign, add one}
	if Pos(DecimalSign, CurrentInput) = 0 then
	begin
		CurrentInput := CurrentInput + DecimalSign;
		{If the text is empty, add a leading zero}
		if Length(CurrentInput) = 1 then
			CurrentInput := '0' + CurrentInput;
		UpdateDisplay;
	end;
end;

procedure BtnCClick(Sender: PUIObject); far;
begin
	{Check length of text in textbox, rather than CurrentInput, because a result may
	 be displayed there}
	if Length(TxtCalc^.GetText) > 0 then
	begin
		CurrentInput := '';
		UpdateDisplay;
	end;
end;

procedure BtnCEClick(Sender: PUIObject); far;
begin
	CurrentInput := '';
	UpdateDisplay;

  Num1 := 0;
  Num2 := 0;

  LastNum := 0;

  Op := opNone;
  LastOp := opNone;

  ResultValue := 0;

  NewInput := True;
end;

procedure BtnOperatorClick(Sender: PUIObject); far;
var
	ClickedBtn: PButton;
begin
	ClickedBtn := PButton(Sender);

  if CurrentInput <> '' then
  begin

    if Op = opNone then
    begin
      Num1 := StringToReal(CurrentInput);
    end
    else
    begin
      Num2 := StringToReal(CurrentInput);

      ExecuteOperation;

      Num1 := ResultValue;

      UpdateDisplay;
    end;
  end;

	if ClickedBtn = BtnAdd then
		Op := opAdd
	else if ClickedBtn = BtnSubstract then
		Op := opSubtract
	else if ClickedBtn = BtnMultiply then
		Op := opMultiply
	else if ClickedBtn = BtnDivide then
		Op := opDivide
	else
		Op := opNone;

	CurrentInput := '';
  NewInput := False;

end;

procedure BtnEqualsClick(Sender: PUIObject); far;
begin
	{Can't do calculations if no operand is selected}
	if (Op = opNone) then
		exit;

	{ First equals press }
  if CurrentInput <> '' then
  begin
    Num2 := StringToReal(CurrentInput);

    LastNum := Num2;
    LastOp := Op;
  end
  else
  begin
    { Repeated equals }
    Num2 := LastNum;
    Op := LastOp;
  end;

  ExecuteOperation;

  {UpdateDisplay shows CurrentInput in display, so copy ResultValue to it temporarily to show it}
  Str(ResultValue:0:DecimalDigits, CurrentInput);
  UpdateDisplay;
  CurrentInput := '';

  Num1 := ResultValue;

  NewInput := True;
end;

procedure HkBackSpaceClick(Sender: PUIObject); far;
begin
	{Remove last character from the textbox}
	if Length(CurrentInput) > 0 then
	begin
		CurrentInput := Copy(CurrentInput, 1, Length(CurrentInput) - 1);
		UpdateDisplay;
	end;
end;

procedure HkEscapeClick(Sender: PUIObject); far;
begin
	{If escape is pressed, clear the number. If it already is cleared,
	 clear everything}
	if Length(TxtCalc^.GetText) > 0 then
		BtnC^.Click;

	if NewInput = True then
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
		SetText('0');
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