program Minesweeper;

{Minesweeper for Costa by Jacob Palm}

uses
	CostaLib, UIMineFl, UIButton, UILabel, UITimer, AboutDlg, Graph, Crt;

const
	AppName           = 'Minesweeper';
	AppVersion        = '2.0';
	AppAuthor         = 'Jacob Palm';
	AppIcon           = 'MINE';

	CAP_NEW_GAME      = #127 + 'New game';
	CAP_PAUSE         = #127 + 'Pause';
	CAP_RESUME        = #127 + 'Resume';
	CAP_SIZE          = 'Si' + #127 + 'ze...';
	CAP_SOUND         = #127 + 'Sound';
	CAP_ABOUT         = #127 + 'About...';
	CAP_EXIT          = 'E' + #127 + 'xit';
	CAP_CANCEL        = #127 + 'Cancel';
	CAP_SMALL         = #127 + '9x9';
	CAP_MEDIUM        = #127 + '16x16';
	CAP_LARGE         = #127 + '22x18';
	CAP_ULTRA         = #127 + '39x18';

	MSG_GAME_OVER     = 'Kaboom! Game over.';
	MSG_FLAGGED_COUNT = 'Flagged mines:';
	MSG_WIN           = 'Minefield cleared, good job!';
	MSG_SOUND         = 'Sound:';
	MSG_ON            = 'On';
	MSG_OFF           = 'Off';

var
	App: PApplication;

	{Main window}
	WinMain:     PWindow;
	MineField:   PMinefield;
	BtnNew,
	BtnSetSize,
	BtnSound,
	BtnPause,
	BtnAbout,
	BtnExit:     PButton;
	HkCheat:     PHotkey;
	TiStatus:    PTimer;
	LblStatus,
	LblTime,
	LblSound:    PLabel;
	CFieldAlign: PContainer;

	{Size dialog window}
	WinSetSize:  PWindow;
	BtnSize:     array[0..3] of PButton;
	BtnCancel:   PButton;

	Flagged:     integer;
	SizeChanged: boolean; {Size dialog changed field size}


procedure UpdateStatus(Msg: string);
var
	MessageText: String;
	FlaggedStr, MineCountStr: string;
begin
	{Only hide mouse if it's near the text, to avoid cursor flicker on old PCs}
	Mouse.Poll;
	if Mouse.Y > 310 then
		Mouse.Hide;

	if Length(Msg) = 0 then
	begin
		Str(Minefield^.GetFlagged, FlaggedStr);
		Str(Minefield^.GetMineCount, MineCountStr);
		Msg := MSG_FLAGGED_COUNT + ' ' + FlaggedStr + '/' + MineCountStr;
	end;

	LblStatus^.SetCaption(Msg);
	LblStatus^.Draw;

	Mouse.Show;
end;


procedure DrawBackground;
var
	X: integer;
begin
	{Background}
	SetFillStyle(SolidFill, DarkGray);
	Bar(0, 29, 639, 349);

	{Dot pattern}
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

	{Status area at bottom of screen}
	SetFillStyle(SolidFill, LightGray);
	Bar(7, 330, 631, 343);
	LblSound^.Draw;
end;

procedure TiStatusClick(Sender: PUIObject); far;
var
	MessageText, TempStr: string;
	ElapsedTime: real;
	Hours, Minutes, Seconds: byte;
begin
	if MineField^.GetGameState = GPaused then
		exit;

	{Triggered once per second while game is active to draw timer at bottom of screen}
	ElapsedTime := MineField^.GetElapsedTime;
	if ElapsedTime <> 0 then
	begin
		{Calculate hours, minutes, seconds from elapsed time}
		Seconds := Trunc(ElapsedTime);
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
	end
	else
		MessageText := '00:00:00';

	LblTime^.SetCaption(MessageText);
	{Hide mouse if it's near the timer, to avoid cursor flicker on old PCs}
	Mouse.Poll;
	if Mouse.Y > 310 then
		Mouse.Hide;
	LblTime^.Draw;
	Mouse.Show;
end;

procedure MineFieldClick(Sender: PUIObject); far;
begin
	{If flagged count changed, update status}
	if Flagged <> MineField^.GetFlagged then
	begin
		Flagged := MineField^.GetFlagged;
		UpdateStatus('');
	end;

	if (MineField^.GetGameState = GWon) then
	begin
		{Player saved the day, print win message and stop timer}
		UpdateStatus(MSG_WIN);
		TiStatus^.Stop;
	end
	else if (MineField^.GetGameState = GLost) then
	begin
		{Player blew up}
		UpdateStatus(MSG_GAME_OVER);
		TiStatus^.Stop;
	end
	else if (MineField^.GetGameState in [GNew, GPlaying]) and not TiStatus^.IsRunning then
	begin
		{Game is active but timer not running, start it}
		TiStatus^.Start;
		TiStatusClick(nil);  {Update time display immediately}
	end;
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

	SizeChanged := True;
	WinSetSize^.Close;
end;

{Size dialog - cancel button}
procedure BtnCancelClick(Sender: PUIObject); far;
begin
	WinSetSize^.Close;
end;

procedure BtnNewClick(Sender: PUIObject); far;
begin
	Mouse.Hide;
	MineField^.NewGame;
	Mouse.Show;
	UpdateStatus('');
	TiStatusClick(nil);
end;

procedure BtnPauseClick(Sender: PUIObject); far;
begin
	{Toggle pause/resume and update pause/resume button caption and hotkey
	 accordingly}
	if MineField^.GetGameState = GPlaying then
	begin
		MineField^.PauseGame;
		BtnPause^.SetCaption(CAP_RESUME);
		BtnPause^.RemoveHotKey(KeyAltP);
		BtnPause^.AddHotKey(KeyAltR);
	end
	else if MineField^.GetGameState = GPaused then
	begin
		MineField^.ResumeGame;
		BtnPause^.SetCaption(CAP_PAUSE);
		BtnPause^.RemoveHotKey(KeyAltR);
		BtnPause^.AddHotKey(KeyAltP);
	end;
	Mouse.Hide;
	BtnPause^.Draw;
	Mouse.Show;
end;

procedure BtnSetSizeClick(Sender: PUIObject); far;
begin
	MineField^.PauseGame;
	{Show size dialog}
	WinSetSize^.Run;

	{If size was changed, start new game with new size}
	if SizeChanged then
	begin
		SizeChanged := False;
		Mouse.Hide;
		DrawBackground;
		MineField^.NewGame;
		Mouse.Show;
		UpdateStatus('');
		TiStatusClick(nil); {Update time display immediately}
	end
	else
		MineField^.ResumeGame;
end;

procedure BtnSoundClick(Sender: PUIObject); far;
var
	MessageText: string;
begin
	{Toggle sound setting}
	MineField^.SetSound(not MineField^.GetSound);

	{Update status display}
	if MineField^.GetSound then
		MessageText := MSG_ON
	else
		MessageText := MSG_OFF;
	MessageText := MSG_SOUND + ' ' + MessageText;

	Mouse.Hide;
	LblSound^.SetCaption(MessageText);
	LblSound^.Draw;
	Mouse.Show;
end;

procedure BtnAboutClick(Sender: PUIObject); far;
begin
	MineField^.PauseGame;
	AboutBox(App);
	MineField^.ResumeGame;
end;

procedure BtnExitClick(Sender: PUIObject); far;
begin
	App^.Exit;
end;

procedure HkCheatClick(Sender: PUIObject); far;
begin
	MineField^.Cheat;
end;

procedure WinMainDraw(Sender: PUIObject); far;
begin
	DrawBackground;

	{Main window is only drawn on launch, so we'll use this to trigger a new game as well}
	MineField^.RemoveState(SHidden);
	MineField^.NewGame;

	{Draw status at bottom of screen}
	UpdateStatus('');
	TiStatusClick(nil);
end;

{Size dialog - custom icons on buttons with text below}
procedure WinSetSizeDraw(Sender: PUIObject); far;
var
	X, Y, W, H, TextOffset: integer;
begin
	Mouse.Hide;

	BtnSize[0]^.GetPos(X, Y, True);
	BtnSize[0]^.GetSize(W, H); {Only need to get once, all buttons are same size}
	TextOffset := ((W - PrintW(CAP_SMALL)) div 2);
	Print(CAP_SMALL, X + TextOffset, Y + 79, Thm.WinText);

	BtnSize[1]^.GetPos(X, Y, True);
	TextOffset := ((W - PrintW(CAP_MEDIUM)) div 2);
	Print(CAP_MEDIUM, X + TextOffset, Y + 79, Thm.WinText);

	BtnSize[2]^.GetPos(X, Y, True);
	TextOffset := ((W - PrintW(CAP_LARGE)) div 2);
	Print(CAP_LARGE, X + TextOffset, Y + 79, Thm.WinText);

	BtnSize[3]^.GetPos(X, Y, True);
	TextOffset := ((W- PrintW(CAP_ULTRA)) div 2);
	Print(CAP_ULTRA, X + TextOffset, Y + 79, Thm.WinText);

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

procedure InitUI;
begin
{Main window and controls}
	New(WinMain, Init(0, 0, nil));
	with WinMain^ do
	begin
		SetSize(GetMaxX, GetMaxY);
		SetOnDraw(WinMainDraw);
		RemoveState(SBordered);
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

	{Status labels at bottom of screen}
	New(LblStatus, Init(9, 333, '', WinMain));
	with LblStatus^ do
	begin
		RemoveState(STransparent);
		SetSize(200, 8);
		SetFgColor(Black);
		SetBgColor(LightGray);
	end;
	New(LblTime, Init(0, 333, '', WinMain));
	with LblTime^ do
	begin
		RemoveState(STransparent);
		SetSize(64, 8);
		Center(OrHorizontal);
		SetFgColor(Black);
		SetBgColor(LightGray);
	end;
	New(LblSound, Init(550, 333, '', WinMain));
	with LblSound^ do
	begin
		SetCaption(MSG_SOUND + ' ' + MSG_ON);
		RemoveState(STransparent);
		SetSize(80, 8);
		SetFgColor(Black);
		SetBgColor(LightGray);
	end;

	{CFieldAlign container is used solely to contaion minefield, so that minefield can be centered
	 on its parent when resized, while taking into account the menu and status bars}
	New(CFieldAlign, Init(0, 29, WinMain));
	With CFieldAlign^ do
	begin
		SetSize(639, 301);
	end;

	New(MineField, Init(CFieldAlign));
	With MineField^ do
	begin
		AddState(SHidden);
		SetOnClick(MineFieldClick);
	end;

	{Cheat hotkey (question mark) to reveal mines}
	New(HkCheat, Init('?', WinMain));
	HkCheat^.SetOnClick(HkCheatClick);

	{Timer for updating elapsed time display}
	New(TiStatus, Init(WinMain));
	With TiStatus^ do
	begin
		SetInterval(1.0);
		SetOnClick(TiStatusClick);
	end;

	{Size dialog window and controls therein}
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
end;

{Main program}
begin
	New(App, Init);
	App^.SetInfo(AppName, AppVersion, AppAuthor, AppIcon);

	InitUI;

	{Start application}
	App^.OpenWindow(WinMain);
	App^.Run;
	App^.Exit;
end.