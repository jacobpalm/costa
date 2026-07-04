program Calculator;

{$R-} {Disable range checking}

uses
	CostaLib, UIButton, UIArea, UITxtBox, UIFrame, UILog, AboutDlg;

const
	AppName              = 'Calculator';
	AppVersion           = '2.0';
	AppAuthor            = 'Jacob Palm';
	AppIcon	             = 'CALC';
	AppConfigFile        = 'CALC';

	CAP_ABOUT            = #127 + 'About...';
	CAP_EXIT             = 'E' + #127 + 'xit';
	CAP_CLEAR            = #127 + 'C';
	CAP_CLEAR_EVERYTHING = 'C' + #127 + 'E';

	CAP_HIDE_LOG         = 'Hide ' + #127 + 'log';
	CAP_SHOW_LOG         = 'Show ' + #127 + 'log';

	MSG_DIV_ZERO         = 'ERROR: Division by zero';
	MSG_OVERFLOW         = 'ERROR: Overflow';

	MaxSafe              = 1.0E37; {Max value to allow to prevent overflows}
	DecimalDigits        = 12;     {Amount of decimal digits to show in results - only affects display}
	MaxInputLength       = 25;     {Maximum number of digits to allow in input}


type
	TOperand             = (opNone, opAdd, opSubtract, opMultiply, opDivide);
	TCalcError           = (ceNone, ceOverflow, ceDivZero);

	TCalcSetting = record
		ShowLog: boolean;
	end;

var
	App:                 PApplication;
	WinMain:             PWindow;
	FrmCalc:             PFrame;
	TxtCalc:             PTextbox;
	BtnNumb:             Array[0..9] of PButton;
	BtnDecimal:          PButton;
	AreaLog:             PLogArea;
	BtnC,
	BtnCE,
	BtnAdd,
	BtnSubstract,
	BtnMultiply,
	BtnDivide,
	BtnEquals,
	BtnLog,
	BtnAbout,
	BtnExit:             PButton;
	FrmClientArea:       PFrame;

	HkBackspace,
	HkEscape:            PHotKey;

	CurrentInput:        String;     {Current value in calculator display}
	Op:	                 TOperand;   {Current operand selected}
	Num1,
	Num2:                Real;       {Numbers involved in calculation}

	LastOp:              TOperand;   {Operand and number from last calculation}
	LastNum:             Real;

	ResultValue:         Real;

	NewInput:            Boolean;    {Tracks if display needs to be cleared when entering a new number}

	CalcError:           TCalcError; {Error status}

	Settings:            TCalcSetting;

{Returns a pretty formated string representation of a Real number}
function RealPretty(RealValue: Real): String;
var
	IntPart, DecPart, RealStr, ResultStr: string;
	IsNegative: Boolean;
	i, Len, Count: integer;
	DotPos: integer;
begin
	IsNegative := False;
	ResultStr := '';
	Str(RealValue:0:DecimalDigits, RealStr);

	{Remove decimals if any, and add again later}
	DotPos := Pos(DecimalSign, RealStr);
	if DotPos > 0 then
	begin
		IntPart := Copy(RealStr, 1, DotPos - 1);
		DecPart := Copy(RealStr, DotPos, Length(RealStr) - DotPos + 1);

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
		IntPart := RealStr;
		DecPart := '';
	end;

	{If first sign is a minus, remove it and add again later so it doesn't affect formatting of
	 thousands}
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

	RealPretty := ResultStr;
end;

procedure ToggleLog(Shown: boolean);
begin
	if Shown then
	begin
		AreaLog^.RemoveState(SHidden);
		BtnLog^.SetCaption(CAP_HIDE_LOG);
		FrmCalc^.SetPos(12, 13);
	end
	else
	begin
		AreaLog^.AddState(SHidden);
		BtnLog^.SetCaption(CAP_SHOW_LOG);
		FrmCalc^.Center(OrBoth);
	end;

	Settings.ShowLog := Shown;
end;

procedure UpdateDisplay;
var
	RealValue: Real;
	Code: Integer;
begin
	Val(CurrentInput, RealValue, Code);
  if Code <> 0 then
    RealValue := 0;

	TxtCalc^.SetText(RealPretty(RealValue));
end;

procedure ExecuteOperation;
begin
	CalcError := ceNone;

  case Op of
    opAdd:
	   	if ((Num1 > 0) and (Num2 > 0) and (Num1 > MaxSafe - Num2)) or
	       ((Num1 < 0) and (Num2 < 0) and (Num1 < -MaxSafe - Num2)) then
				CalcError := ceOverflow
    	else
      	ResultValue := Num1 + Num2;

    opSubtract:
	    if ((Num1 > 0) and (Num2 < 0) and (Num1 > MaxSafe + Num2)) or
	       ((Num1 < 0) and (Num2 > 0) and (Num1 < -MaxSafe + Num2)) then
				CalcError := ceOverflow
		  else
				ResultValue := Num1 - Num2;

    opMultiply:
     	if (Num1 <> 0) and (Abs(Num2) > MaxSafe / Abs(Num1)) then
      	CalcError := ceOverflow
		  else
		  	ResultValue := Num1 * Num2;

    opDivide:
      if Num2 = 0 then
       	CalcError := ceDivZero
      else if (Abs(Num2) < 1.0) and (Abs(Num1) > MaxSafe * Abs(Num2)) then
      	CalcError := ceOverflow
      else
        ResultValue := Num1 / Num2;
  end;

  if CalcError <> ceNone then
  	ResultValue := 0;
end;

procedure BtnNumbClick(Sender: PUIObject); far;
begin
	if NewInput then
  begin
    CurrentInput := '';
    NewInput := False;
    Op := opNone;
    {Log an empty line so there's space between calculations}
    AreaLog^.AddEntry('');
  end;

  if Length(CurrentInput) >= MaxInputLength then
  begin
  	SystemSound(sndError);
  	exit;
  end;

  CurrentInput := CurrentInput + PButton(Sender)^.Caption;
  UpdateDisplay;
end;

procedure BtnDecimalClick(Sender: PUIObject); far;
begin
	{Can't add decimal sign unless there's room for at least it plus one decimal}
 	if Length(CurrentInput) > (MaxInputLength - 2) then
  begin
 		SystemSound(sndError);
  	exit;
  end;

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
	Code: Integer;
	LogOutput: String;
begin
	ClickedBtn := PButton(Sender);

  if CurrentInput <> '' then
  begin

    if Op = opNone then
    begin
      Val(CurrentInput, Num1, Code);
      if Code <> 0 then
        Num1 := 0;
      AreaLog^.AddEntry(RealPretty(Num1));
    end
    else
    begin
      Val(CurrentInput, Num2, Code);
      if Code <> 0 then
        Num2 := 0;

      case Op of
      	opAdd: LogOutput := '+ ';
        opSubtract: LogOutput := '-';
        opMultiply: LogOutput := '* ';
        opDivide: LogOutput := '/ ';
      end;
      AreaLog^.AddEntry(LogOutput + RealPretty(Num2));

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
var
	Code: Integer;
	LogOutput: String;
begin
	{Can't do calculations if no operand is selected}
	if (Op = opNone) then
	begin
		SystemSound(sndError);
		exit;
	end;

	case Op of
  	opAdd: LogOutput := '+ ';
    opSubtract: LogOutput := '-';
    opMultiply: LogOutput := '* ';
    opDivide: LogOutput := '/ ';
  end;

	{ First equals press }
  if CurrentInput <> '' then
  begin
    Val(CurrentInput, Num2, Code);
    if Code <> 0 then
      Num2 := 0;

    LastNum := Num2;
    LastOp := Op;
  end
  else
  begin
    { Repeated equals }
    Num2 := LastNum;
    Op := LastOp;
  end;

  AreaLog^.AddEntry(LogOutput + RealPretty(Num2));
  ExecuteOperation;

  if CalcError <> ceNone then
  begin
  	if CalcError = ceOverflow then AreaLog^.AddEntry(MSG_OVERFLOW);
   	if CalcError = ceDivZero then AreaLog^.AddEntry(MSG_DIV_ZERO);
    SystemSound(sndError);
    BtnCEClick(nil);
  end
  else
  begin
	  {UpdateDisplay shows CurrentInput in display, so copy ResultValue to it temporarily to show it}
	  Str(ResultValue:0:DecimalDigits, CurrentInput);
	  UpdateDisplay;

  	AreaLog^.AddEntry('= ' + RealPretty(ResultValue));
	  CurrentInput := '';

	  Num1 := ResultValue;
  end;

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

procedure BtnLogClick(Sender: PUIObject); far;
begin
	{If hidden = true, log will be enabled}
	ToggleLog(SHidden in AreaLog^.State);
end;

procedure BtnAboutClick(Sender: PUIObject); far;
begin
	AboutBox(App);
end;

procedure BtnExitClick(Sender: PUIObject); far;
begin
	App^.SaveSettings;
	App^.Terminate;
end;

procedure AppRun(Sender: PUIObject); far;
begin
	if not App^.LoadSettings then
		Settings.ShowLog := true;

	ToggleLog(Settings.ShowLog);
end;

procedure InitUI;
var
	i: Integer;
begin
	New(WinMain, Init(0, 0, nil));
	with WinMain^ do
	begin
		Width := ScreenWidth;
		Height := ScreenHeight;
		RemoveState(SBordered);
	end;

	New(BtnLog, Init(2, 2, CAP_SHOW_LOG, WinMain));
	With BtnLog^ do
	begin
		AddHotkey(KeyAltL);
		OnClick := BtnLogClick;
	end;

	New(BtnAbout, Init(446, 2, CAP_ABOUT, WinMain));
	With BtnAbout^ do
	begin
		OnClick := BtnAboutClick;
		AddHotKey(KeyAltA);
	end;

	New(BtnExit, Init(545, 2, CAP_EXIT, WinMain));
	With BtnExit^ do
	begin
		OnClick := BtnExitClick;
		AddHotKey(KeyAltX);
		AddHotKey(KeyAltF4);
	end;

	{Non-visible frame used to center objects below menu bar and to make sure object MSG_OVERFLOW
	 only redraws part of the window}
	New(FrmClientArea, Init(0, 29, WinMain));
	With FrmClientArea^ do
	begin
		SetSize(639, 329);
		RemoveState(SBordered);
		RemoveState(STransParent);
	end;

	New(FrmCalc, Init(0, 0, FrmClientArea));
	with FrmCalc^ do
	begin
		SetSize(218, 208);
		Center(OrBoth);
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
		OnClick := BtnNumbClick;
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
		BtnNumb[i]^.OnClick := BtnNumbClick;
	end;
	New(BtnDecimal, Init(114, 172, '.', FrmCalc));
	With BtnDecimal^ do
	begin
		SetSize(40, SizeRetain);
		AddHotKey('.'); {Add both so it works with both decimal signs}
		AddHotKey(',');
		OnClick := BtnDecimalClick;
	end;

	{Clear and Clear Everything buttons}
	New(BtnC, Init(14, 40, CAP_CLEAR, FrmCalc));
	With BtnC^ do
	begin
		SetSize(40, SizeRetain);
		AddHotKey(KeyAltC);
		OnClick := BtnCClick;
	end;
	New(BtnCE, Init(64, 40, CAP_CLEAR_EVERYTHING, FrmCalc));
	With BtnCE^ do
	begin
		SetSize(40, SizeRetain);
		AddHotKey(KeyAltE);
		OnClick := BtnCEClick;
	end;

	{Operator buttons}
	New(BtnDivide, Init(114, 40, '/', FrmCalc));
	With BtnDivide^ do
	begin
		SetSize(40, SizeRetain);
		AddHotKey('/');
		OnClick := BtnOperatorClick;
	end;
	New(BtnMultiply, Init(164, 40, '*', FrmCalc));
	With BtnMultiply^ do
	begin
		SetSize(40, SizeRetain);
		AddHotKey('*');
		OnClick := BtnOperatorClick;
	end;
	New(BtnSubstract, Init(164, 73, '-', FrmCalc));
	With BtnSubstract^ do
	begin
		SetSize(40, SizeRetain);
		AddHotKey('-');
		OnClick := BtnOperatorClick;
	end;
	New(BtnAdd, Init(164, 106, '+', FrmCalc));
	With BtnAdd^ do
	begin
		SetSize(40, SizeRetain);
		AddHotKey('+');
		OnClick := BtnOperatorClick;
	end;

	New(BtnEquals, Init(164, 139, '=', FrmCalc));
	With BtnEquals^ do
	begin
		SetSize(40, 55);
		AddHotKey('=');
		AddHotKey(KeyEnter);
		OnClick := BtnEqualsClick;
	end;

	New(AreaLog, Init(242, 13, FrmClientArea));
	with AreaLog^ do
	begin
		SetSize(385, 295);
		SetAlign(AlRight);
		AddState(SHidden);
	end;

	New(HkBackspace, Init(KeyBackspace, WinMain));
	HkBackspace^.OnClick := HkBackSpaceClick;
	New(HkEscape, Init(KeyEscape, WinMain));
	HkEscape^.OnClick := HkEscapeClick;
end;

begin
	New(App, Init);
	With App^ do
	begin
		Name := AppName;
		Version := AppVersion;
		Author := AppAuthor;
		Icon := AppIcon;
		SetConfigFile(AppConfigFile, @Settings, SizeOf(TCalcSetting));
		OnRun := AppRun;
	end;

	InitUI;

	App^.OpenWindow(WinMain);
	App^.Run;
end.