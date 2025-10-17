program Minesweeper;

uses
	CostaLib, UIMineFl, UIButton, UILabel, AboutDlg, Graph, Crt;

const
	AppName           = 'Minesweeper';
	AppVersion        = '2.0';
	AppAuthor         = 'Jacob Palm';
	AppIcon           = 'MINE';

	CAP_NEW_GAME      = #127 + 'New game';
	CAP_PAUSE         = #127 + 'Pause';
	CAP_SIZE          = 'Si' + #127 + 'ze...';
	CAP_SOUND         = #127 + 'Sound';
	CAP_ABOUT         = #127 + 'About...';
	CAP_EXIT          = 'E' + #127 + 'xit';
	CAP_CANCEL        = #127 + 'Cancel';
	CAP_9X9           = #127 + '9x9';
	CAP_16X16         = #127 + '16x16';
	CAP_22X18         = #127 + '22x18';
	CAP_39X18         = #127 + '39x18';

	MSG_GAME_OVER     = 'Kaboom! Game over.';
	MSG_FLAGGED_COUNT = 'Flagged mines:';
	MSG_WIN           = 'Minefield cleared, good job!';
	MSG_SOUND         = 'Sound:';
	MSG_ON            = 'On';
	MSG_OFF           = 'Off';

var
	App: PApplication;

	{Main window}
	WinMain: PWindow;
	MineField: PMinefield;
	BtnNew, BtnSetSize, BtnSound, BtnPause, BtnAbout, BtnExit: PButton;
	HkCheat: PHotkey;

	{Size dialog window}
	WinSetSize: PWindow;
	BtnSize: array[0..3] of PButton;
	BtnCancel: PButton;


procedure PrintStatus(MineCountOnly: boolean; StatusMessage: string);
var
	MessageText: String;
	FlaggedStr, MineCountStr: string;
begin
	
	Str(Minefield^.GetFlagged, FlaggedStr);
	Str(Minefield^.GetMineCount, MineCountStr);
	SetFillStyle(SolidFill, Thm.Win);

	{Only hide mouse if it's near the timer, to avoid cursor flicker on old PCs}
	Mouse.Poll;
	if Mouse.Y > 310 then
		Mouse.Hide;
	
	if MineCountOnly then
	begin
		Bar(106, 330, 184, 343);
		MessageText := FlaggedStr + '/' + MineCountStr;
		Print(MessageText, 110, 332, Thm.WinText);
		Mouse.Show;
		exit;
	end;

	{Clear both sides of timer}
	Bar(6, 330, 277, 343);
	Bar(361, 330, 632, 343);

	if Length(StatusMessage) > 0 then
		MessageText := StatusMessage
	else
		MessageText := MSG_FLAGGED_COUNT + ' ' + FlaggedStr + '/' + MineCountStr;
	
	Print(MessageText, 8, 332, Thm.WinText);

	MessageText := MSG_SOUND + ' ';
	if MineField^.GetSound then
		MessageText := MessageText + MSG_ON
	else
		MessageText := MessageText + MSG_OFF;
	
	Print(MessageText, (630 - PrintW(MessageText)), 332, Thm.WinText);
	Mouse.Show;
end;

procedure PrintTime;
var
	MessageText: String;
	Hours, Minutes, Seconds: byte;
	TempStr: string;
begin
	{Only draw time if we are still playing}
	{if GameOver or (MineField^.StartTime = 0) then
		exit;}

	{Only hide mouse if it's near the timer, to avoid cursor flicker on old PCs}
	{Mouse.Poll;
	if Mouse.Y > 310 then
		Mouse.Hide;}

	{Clear timer only}
	{SetFillStyle(SolidFill, Thm.Win);
	{Bar(278, 330, 360, 343);}

	{if MineField^.StartTime <> 0 then
	begin
		Seconds := Trunc(Timer - MineField^.StartTime);
		Hours := Seconds div 3600;
		Minutes := (Seconds - (3600 * Hours)) div 60;
		Seconds := (Seconds - (3600 * Hours)) - (Minutes * 60);
		MessageText := '';

		if Hours < 10 then
			MessageText := '0';
		Str(Hours, TempStr);
		MessageText := MessageText + TempStr + ':';

		if Minutes < 10 then
			MessageText := MessageText + '0';
		Str(Minutes, TempStr);
		MessageText := MessageText + TempStr + ':';

		if Seconds < 10 then
			MessageText := MessageText + '0';
		Str(Seconds, TempStr);
		MessageText := MessageText + TempStr;

		Print(MessageText, (640 - PrintW(MessageText)) div 2, 332, Thm.WinText);
	end;}

	Mouse.Show;
end;

procedure DrawBackground;
var
	X: integer;
begin
	SetFillStyle(SolidFill, DarkGray);
	Bar(0, 29, 639, 349);

	SetLineStyle(UserBitLn, $1111, 1);
	SetColor(LightGray);
	for X := 0 to 639 do
	begin
		if X mod 6 = 0 then
			Line(X, 29, X, 349);
	end;

	for X := 3 to 639 do
	begin
		if (X - 3) mod 6 = 0 then
			Line(X, 31, X, 349);
	end;
	SetLineStyle(SolidLn, 0, 1);	
end;

procedure MineFieldClick(Sender: PUIObject); far;
begin
	{Check if won or lost and update status}
	{DEBUG}
end;

{Size dialog - field size buttons}
procedure BtnSizeClick(Sender: PUIObject); far;
begin
	if PButton(Sender) = BtnSize[0] then
		MineField^.SetFieldSize(SSmall);
	if PButton(Sender) = BtnSize[1] then
		MineField^.SetFieldSize(SMedium);
	if PButton(Sender) = BtnSize[2] then
		MineField^.SetFieldSize(SLarge);
	if PButton(Sender) = BtnSize[3] then
		MineField^.SetFieldSize(SUltra);
	
	WinSetSize^.Close;
	DrawBackground;
	MineField^.NewGame;
end;

{Size dialog - cancel button}
procedure BtnCancelClick(Sender: PUIObject); far;
begin
	WinSetSize^.Close;
end;

procedure BtnNewClick(Sender: PUIObject); far;
begin
	DrawBackground;
	MineField^.NewGame;
	PrintStatus(False, '');
end;

procedure BtnPauseClick(Sender: PUIObject); far;
var
	Row, Col: byte;
	PauseTime: real;
begin
	MineField^.PauseGame;
	PrintStatus(False, '');
	PrintTime;
end;

procedure BtnSetSizeClick(Sender: PUIObject); far;
begin
	WinSetSize^.Run;
end;

procedure BtnSoundClick(Sender: PUIObject); far;
begin
	MineField^.SetSound(not MineField^.GetSound);
	PrintStatus(False, '');
end;

procedure BtnAboutClick(Sender: PUIObject); far;
begin
	AboutBox(App);
end;

procedure BtnExitClick(Sender: PUIObject); far;
begin
	App^.Exit;
end;

procedure HkCheatClick(Sender: PUIObject); far;
begin
	MineField^.Cheat;			
end;

procedure WinMainRun(Sender: PUIObject); far;
begin
	{Default settings}
	MineField^.NewGame;
	PrintStatus(False, '');
end;

procedure WinMainDraw(Sender: PUIObject); far;
begin
	DrawBackground;
end;

{Size dialog - custom icons on buttons with text below}
procedure WinSetSizeDraw(Sender: PUIObject); far;
var
	X, Y, W, H, TextOffset: integer;
begin
	Mouse.Hide;

	BtnSize[0]^.GetPos(X, Y, True);
	BtnSize[0]^.GetSize(W, H); {Only need to get once, all buttons are same size}
	TextOffset := ((W - PrintW(CAP_9X9)) div 2);
	Print(CAP_9X9, X + TextOffset, Y + 79, Thm.WinText);

	BtnSize[1]^.GetPos(X, Y, True);
	TextOffset := ((W - PrintW(CAP_16X16)) div 2);
	Print(CAP_16X16, X + TextOffset, Y + 79, Thm.WinText);

	BtnSize[2]^.GetPos(X, Y, True);
	TextOffset := ((W - PrintW(CAP_22X18)) div 2);
	Print(CAP_22X18, X + TextOffset, Y + 79, Thm.WinText);

	BtnSize[3]^.GetPos(X, Y, True);
	TextOffset := ((W- PrintW(CAP_39X18)) div 2);
	Print(CAP_39X18, X + TextOffset, Y + 79, Thm.WinText);
	
	SetColor(Thm.WinText);
	{9x9}
	for X := 0 to 3 do
		Line(252 + X * 9, 94, 252 + X * 9, 121);
	for Y := 0 to 3 do
		Line(252, 94 + Y * 9, 279, 94 + Y * 9);
	
	{16x16}
	for X := 0 to 4 do
		Line(357 + X * 9, 90, 357 + X * 9, 126);
	for Y := 0 to 4 do
		Line(357, 90 + Y * 9, 393, 90 + Y * 9);
	
	{22x18}
	for X := 0 to 6 do
		Line(238 + X * 9, 195, 238 + X * 9, 240);
	for Y := 0 to 5 do
		Line(238, 195 + Y * 9, 292, 195 + Y * 9);
	
	{39x18}
	for X := 0 to 8 do
		Line(339 + X * 9, 195, 339 + X * 9, 240);
	for Y := 0 to 5 do
		Line(339, 195 + Y * 9, 411, 195 + Y * 9);
	
	Mouse.Show;
end;

{Main program}
begin
	New(App, Init);
	With App^ do
	begin
		Name    := AppName;
		Version := AppVersion;
		Author  := AppAuthor;
		Icon    := AppIcon;
	end;

	{Main window and controls}
	New(WinMain, Init(0, 0, nil));
	with WinMain^ do
	begin
		SetSize(GetMaxX, GetMaxY);
		Border := False;
		OnRun := WinMainRun;
	end;

	New(BtnNew, Init(3, 2, CAP_NEW_GAME, WinMain));
	With BtnNew^ do
	begin
		SetOnClick(BtnNewClick);
		AddHotKey(KeyAltN);
	end;
	New(BtnPause, Init(102, 2, CAP_PAUSE, WinMain));
	With BtnPause^ do
	begin
		SetOnClick(BtnPauseClick);
		AddHotKey(KeyAltP);
	end;
	New(BtnSetSize, Init(201, 2, CAP_SIZE, WinMain));
	With BtnSetSize^ do
	begin
		SetOnClick(BtnSetSizeClick);
		AddHotKey(KeyAltZ);
	end;
	New(BtnSound, Init(300, 2, CAP_SOUND, WinMain));
	With BtnSound^ do
	begin
		SetOnClick(BtnSoundClick);
		AddHotKey(KeyAltS);
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
	
	New(MineField, Init(WinMain));
	With MineField^ do
	begin
		AddState(SHidden); {Hidden until new game starts}
		SetOnClick(MineFieldClick);
	end;
	
	New(HkCheat, Init('?', WinMain));
	HkCheat^.SetOnClick(HkCheatClick);

	{Size dialog window and controls}
	New(WinSetSize, Init(0, 0, nil));
	With WinSetSize^ do
	begin
		SetSize(236, 264);
		Center(OrBoth);
		SaveBackdrop;
		SetOnDraw(WinSetSizeDraw);
	end;
	
	New(BtnSize[0], Init(13, 11, '', WinSetSize));
	With BtnSize[0]^ do
	begin
		AddHotkey(KeyAlt9);
		SetSize(100, 100);
		AddState(STransparent);
		SetOnClick(BtnSizeClick);
	end;
	New(BtnSize[1], Init(123, 11, '', WinSetSize));
	With BtnSize[1]^ do
	begin
		AddHotkey(KeyAlt1);
		SetSize(100, 100);
		AddState(STransparent);
		SetOnClick(BtnSizeClick);
	end;
	New(BtnSize[2], Init(13, 121, '', WinSetSize));
	With BtnSize[2]^ do
	begin
		AddHotkey(KeyAlt2);
		SetSize(100, 100);
		AddState(STransparent);
		SetOnClick(BtnSizeClick);
	end;
	New(BtnSize[3], Init(123, 121, '', WinSetSize));
	With BtnSize[3]^ do
	begin
		AddHotkey(KeyAlt3);
		SetSize(100, 100);
		AddState(STransparent);
		SetOnClick(BtnSizeClick);
	end;
	New(BtnCancel, Init(13, 231, CAP_CANCEL, WinSetSize));
	With BtnCancel^ do
	Begin
		AddHotkey(KeyAltC);
		AddHotkey(KeyEscape);
		SetSize(210, SizeRetain);
		SetOnClick(BtnCancelClick)
	End;


	App^.OpenWindow(WinMain);
	App^.Run;
	App^.Exit;

	{DEBUG - need a timer object to handle this}
	{if (MineField^.StartTime <> 0) and (MineField^.TimeCompare < Timer) then
	begin
		PrintTime;
		MineField^.TimeCompare := Timer + 1;
	end;}

	{DEBUG - use timer to update status when game won/lost}
	{PrintStatus(False, MSG_WIN);
	PrintStatus(False, MSG_GAME_OVER);
	PrintStatus(true, '');}
end.