program TicTacToe;

uses
	CostaLib, UILabel, UIButton, UIFrame, AboutDlg, Crt, Strings, Graph;

const
	AppName             = 'Tic Tac Toe';
	AppVersion          = '2.0';
	AppAuthor           = 'Jacob Palm';
	AppIcon             = 'TICTAC';

	CAP_NEW_GAME        = #127 + 'New game';
	CAP_GAME_MODE       = #127 + 'Mode';
	CAP_SOUND           = #127 + 'Sound';
	CAP_ABOUT           = #127 + 'About...';
	CAP_EXIT            = 'E' + #127 + 'xit';

	MSG_GAMEMODE_PC     = 'Playing against computer';
	MSG_GAMEMODE_PLAYER = 'Playing two players';
	MSG_SOUND_ON        = 'Sound: On';
	MSG_SOUND_OFF       = 'Sound: Off';
	MSG_BY              = 'by';

	MSG_WIN_TEXT: array[0..5] of string = (
		'%s has brought honor to the family!',
		'%s has emerged victoriously from the battle!',
		'Nothing could stop %s from achieving victory!',
		'The crowd is gasping, amazed at the incredible play by %s!',
		'%s has brought down utter destruction on the opponent!',
		'%s is unbeatable on the playing field!');
	MSG_DRAW_TEXT: array[0..5] of string = (
		'It was a real nail-biter, but neither player could best the other.',
		'No winners means no losers, I guess.',
		'A high-stakes game that could have gone both ways.',
		'As eager as both players were, neither of them could achieve victory.',
		'No bragging rights for either player - try again!',
		'An otherwise intense game, which ended with disappointment for both sides.');
	MSG_PC_TURN_TEXT: array[0..5] of string = (
		'%s is contemplating the next move...',
		'%s is calculating all possible outcomes...',
		'The stakes are too high for %s not to think this through...',
		'%s is struggling to find enough CPU power to beat the opponent...',
		'%s is becoming sentient in the quest to beat the humans...',
		'%s is working hard to not loose to a feeble human...');
	MSG_PLAYER_TURN_TEXT: array[0..5] of string = (
		'Make your move, %s!',
		'How are you going to beat your opponent, %s?',
		'Uh oh, what a powerfull move! What will %s do now?',
		'Take your time %s - the stakes are too high to slip up now!',
		'How will you eliminate your opponent, %s?',
		'Now is the time to prove yourself, %s!');
	MSG_NEW_GAME_TEXT: array[0..5] of string = (
		'%s gets to make the first move!',
		'Looks like %s will be the one to strike first!',
		'How will %s begin the battle?',
		'%s is preparing the surprise attack carefully...',
		'%s is thinking about the optimal way to start the game...',
		'First move is yours %s, use it wisely!');

type
	TPlayer  = (PlayerNone, PlayerX, PlayerO);
	TSound   = (SndX, SndO, SndIllegal, SndWin, SndLoose, SndDraw, SndNew);
	TGameMsg = (MsgWin, MsgDraw, MsgPcTurn, MsgPlayerTurn, MsgNewGame);

	{Custom UI object for a field showing an X or an O}
	PField = ^TField;
	TField = object(TUIObject)
		public
			constructor  Init(X, Y: Integer; Parent: PContainer);
			procedure    Draw; virtual;

			procedure    SetValue(Val: TPlayer);
			function     GetValue: TPlayer;
		private
			Value:       TPlayer;
	end;


var
	App:           PApplication;
	WinMain:       PWindow;
	BtnNew,
	BtnGameMode,
	BtnSound,
	BtnAbout,
	BtnExit:       PButton;
	FrmTic:        PFrame;

	LblMessage,
	LblPlayers,
	LblSound:      PLabel;

	PlayField:     Array[1..3, 1..3] of PField;

	PlayerStart,
	PlayerTurn:    TPlayer;
	TotalTurns:    Integer;

	VersusPC,
	SoundOn:       Boolean;

{Forward declarations}
procedure PlaySound(SoundType: TSound); forward;
procedure PrintMsg(MessageType: TGameMsg); forward;
procedure PrintStatus; forward;
function  CanWin(Player: TPlayer; var Row, Col: integer): boolean; forward;
function  DidWin: boolean; forward;

constructor TField.Init(X, Y: Integer; Parent: PContainer);
const
	DefaultW = 60;
	DefaultH = 60;
begin
	TUIObject.Init;
	Value := PlayerNone;
	SetParent(Parent);
	SetPos(X, Y);
	SetBGColor(White);
	SetSize(DefaultW, DefaultH);
end;

procedure TField.Draw;
var
	X1, X2, Y1, Y2: Integer;
begin
	if SHidden in State then
		exit;

	{Get absolute position and size of the object}
	Self.GetPos(X1, Y1, True);
	X2 := X1 + Width;
	Y2 := Y1 + Height;

	{Custom drawing, not using UI primitives since this is a game with a bit of a custom UI look}
	{Interior}
	SetFillStyle(SolidFill, White);
	Bar(X1 + 2, Y1 + 2, X2 - 2, Y2 - 2);

	{Borders}
	SetColor(LightGreen);
	Rectangle(X1, Y1, X2 - 1, Y2 - 1);
	SetColor(DarkGray);
	Rectangle(X1 + 1, Y1 + 1, X2, Y2);

	if Value = PlayerX then
	begin
		SetColor(Black);
		Line(X1 + 11, Y1 + 12, X1 + 48, Y1 + 49);
		Line(X1 + 11, Y1 + 13, X1 + 47, Y1 + 49);
		Line(X1 + 12, Y1 + 12, X1 + 49, Y1 + 49);
		Line(X1 + 13, Y1 + 12, X1 + 49, Y1 + 48);
		Line(X1 + 11, Y1 + 48, X1 + 47, Y1 + 12);
		Line(X1 + 11, Y1 + 49, X1 + 48, Y1 + 12);
		Line(X1 + 12, Y1 + 49, X1 + 49, Y1 + 12);
		Line(X1 + 13, Y1 + 49, X1 + 49, Y1 + 13);
	end;

	if Value = PlayerO then
	begin
		{Default aspect ration is 7750:10000}
		SetAspectRatio(10000, 10000);
		SetColor(Black);
		Circle(X1 + 30, Y1 + 30, 19);
		Circle(X1 + 30, Y1 + 30, 18);
		Circle(X1 + 30, Y1 + 30, 17);

		{Circles aren't perfect, fill in gaps}
		PutPixel(X1 + 14, Y1 + 23, Black);
		PutPixel(X1 + 15, Y1 + 21, Black);
		PutPixel(X1 + 21, Y1 + 15, Black);
		PutPixel(X1 + 23, Y1 + 14, Black);
		PutPixel(X1 + 14, Y1 + 37, Black);
		PutPixel(X1 + 15, Y1 + 39, Black);
		PutPixel(X1 + 21, Y1 + 45, Black);
		PutPixel(X1 + 23, Y1 + 46, Black);
		PutPixel(X1 + 37, Y1 + 46, Black);
		PutPixel(X1 + 39, Y1 + 45, Black);
		PutPixel(X1 + 45, Y1 + 39, Black);
		PutPixel(X1 + 46, Y1 + 37, Black);
		PutPixel(X1 + 46, Y1 + 23, Black);
		PutPixel(X1 + 45, Y1 + 21, Black);
		PutPixel(X1 + 39, Y1 + 15, Black);
		PutPixel(X1 + 37, Y1 + 14, Black);
		Line(X1 + 16, Y1 + 18, X1 + 18, Y1 + 16);
		Line(X1 + 42, Y1 + 16, X1 + 44, Y1 + 18);
		Line(X1 + 44, Y1 + 42, X1 + 42, Y1 + 44);
		Line(X1 + 16, Y1 + 42, X1 + 18, Y1 + 44);
	end;

	TUIObject.Draw;
end;

procedure TField.SetValue(Val: TPlayer);
begin
	if Val <> Value then
	begin
		Value := Val;
		AddState(SDirty);
	end;
end;

function TField.GetValue: TPlayer;
begin
	GetValue := Value;
end;

procedure PcMove;
var
	Row, Col: integer;
	FoundMove: boolean;
begin
	PrintMsg(MsgPcTurn);
	FoundMove := false;

	{Simulate some random "thinking" time}
	Randomize;
	Delay(Random(850) + 550);

	{Check if the computer can win}
	if CanWin(PlayerO, Row, Col) then
	begin
		PlayField[Row, Col]^.SetValue(PlayerO);
		FoundMove := true;
	end
	{Check if player can win, block if so}
	else if CanWin(PlayerX, Row, Col) then
	begin
		PlayField[Row, Col]^.SetValue(PlayerO);
		FoundMove := true;
	end;

	{If AI can't win, and player can't either, just pick a random spot}
	if not FoundMove then
	begin
		repeat
		Col := Random(3) + 1;
		Row := Random(3) + 1;

		if PlayField[Row, Col]^.GetValue = PlayerNone then
		begin
			PlayField[Row, Col]^.SetValue(PlayerO);
			break;
		end;
		until false;
	end;

	PlaySound(SndO);
	Inc(TotalTurns);
	if DidWin then
	begin
		PrintMsg(MsgWin);
		PlaySound(SndLoose); {Loose, because AI wins}
		TotalTurns := 9;
		exit;
	end;

	{If board is full with no winner, it's a draw}
	if TotalTurns = 9 then
	begin
		PrintMsg(MsgDraw);
		PlaySound(SndDraw);
	end
	else
	begin
		{Switch to player, game goes on}
		PlayerTurn := PlayerX;
		PrintMsg(MsgPlayerTurn);
	end;
end;

function DidWin: boolean;
var
  Row, Col: integer;
  Sum: integer;
begin
	DidWin := false;

	{Check rows}
	for Row := 1 to 3 do
	begin
		if (PlayField[Row, 1]^.GetValue = PlayField[Row, 2]^.GetValue) and
			 (PlayField[Row, 2]^.GetValue = PlayField[Row, 3]^.GetValue) and
			 (PlayField[Row, 1]^.GetValue <> PlayerNone) then
		begin
			DidWin := true;
			exit;
		end;
	end;

	{Check columns}
	for Col := 1 to 3 do
	begin
		if (PlayField[1, Col]^.GetValue = PlayField[2, Col]^.GetValue) and
			 (PlayField[2, Col]^.GetValue = PlayField[3, Col]^.GetValue) and
			 (PlayField[1, Col]^.GetValue <> PlayerNone) then
		begin
			DidWin := true;
			exit;
		end;
	end;

	{Check diagonal \}
	if (PlayField[1, 1]^.GetValue = PlayField[2, 2]^.GetValue) and
		 (PlayField[2, 2]^.GetValue = PlayField[3, 3]^.GetValue) and
		 (PlayField[1, 1]^.GetValue <> PlayerNone) then
	begin
		DidWin := true;
		exit;
	end;

	{Check diagonal /}
	if (PlayField[1, 3]^.GetValue = PlayField[2, 2]^.GetValue) and
		 (PlayField[2, 2]^.GetValue = PlayField[3, 1]^.GetValue) and
		 (PlayField[1, 3]^.GetValue <> PlayerNone) then
	begin
		DidWin := true;
		exit;
	end;
end;

function CanWin(Player: TPlayer; var Row, Col: integer): boolean;
var
	r, c: integer;
	Sum: integer;
begin
    CanWin := false;

    {Check rows}
    for r := 1 to 3 do
    begin
      Sum := 0;
      Col := 0;
      for c := 1 to 3 do
      begin
        if PlayField[r, c]^.GetValue = Player then
          Inc(Sum)
        else if PlayField[r, c]^.GetValue = PlayerNone then
          Col := c;
      end;
      if (Sum = 2) and (Col <> 0) then
      begin
        Row := r;
        CanWin := true;
        exit;
      end;
    end;

	{Check columns}
    for c := 1 to 3 do
    begin
      Sum := 0;
      Row := 0;
      for r := 1 to 3 do
      begin
        if PlayField[r, c]^.GetValue = Player then
          Inc(Sum)
        else if PlayField[r, c]^.GetValue = PlayerNone then
          Row := r;
      end;
      if (Sum = 2) and (Row <> 0) then
      begin
        Col := c;
        CanWin := true;
        exit;
      end;
    end;

    {Check diagonal - \}
    Sum := 0;
    Row := 0;
    Col := 0;
    for r := 1 to 3 do
    begin
      if PlayField[r, r]^.GetValue = Player then
        Inc(Sum)
      else if PlayField[r, r]^.GetValue = PlayerNone then
      begin
        Row := r;
        Col := r;
      end;
    end;
    if (Sum = 2) and (Row <> 0) then
    begin
      CanWin := true;
      exit;
    end;

	{Reverse diagonal}
	Sum := 0;
	Row := 0;
	Col := 0;
	for r := 1 to 3 do
	begin
		c := 4 - r; { Calculate the column for the reverse diagonal }
		if PlayField[r, c]^.GetValue = Player then
			Inc(Sum)
		else if PlayField[r, c]^.GetValue = PlayerNone then
		begin
			Row := r;
			Col := c;
		end;
	end;
	if (Sum = 2) and (Row <> 0) then
	begin
		CanWin := true;
		exit;
	end;
end;

procedure NewGame;
var
	Row, Col: integer;
begin
	for Row := 1 to 3 do
		for Col := 1 to 3 do
		begin
			PlayField[Row, Col]^.SetValue(PlayerNone);
		end;

	TotalTurns := 0;
	if PlayerStart = PlayerX then
		PlayerStart := PlayerO
	else
		PlayerStart := PlayerX;

	PlayerTurn := PlayerStart;

	PrintMsg(MsgNewGame);
	PrintStatus;
	PlaySound(SndNew);
end;

procedure PlaySound(SoundType: TSound);
begin
	if not SoundOn then
		exit;

	case SoundType of
		SndX:
			SoundNote(400, 70);
		SndO:
			SoundNote(800, 70);
		SndIllegal:
			SoundNote(100, 70);
		SndNew:
			begin
				SoundNote(65, 180);
				SoundNote(65, 180);
				SoundNote(82, 180);
			end;
		SndWin:
			begin
				SoundNote(65, 600);
				SoundNote(73, 600);
				SoundNote(98, 300);
				SoundNote(82, 150);
			end;
		SndLoose:
			begin
			  SoundNote(61, 180);
			  SoundNote(57, 180);
			  SoundNote(69, 180);
			  SoundNote(49, 500);
			end;
		SndDraw:
			begin
				SoundNote(70, 180);
				SoundNote(75, 180);
				SoundNote(90, 150);
				SoundNote(60, 500);
			end;
	end;
end;

procedure PrintMsg(MessageType: TGameMsg);
var
	Message: string;
	CurrentTurn: string[1];
	Randomizer: integer;
begin
	Randomize;
	Randomizer := Random(6);

	if PlayerTurn = PlayerX then
		CurrentTurn := 'X'
	else
		CurrentTurn := 'O';

	case MessageType of
		MsgWin:        Message := MSG_WIN_TEXT[Randomizer];
		MsgDraw:       Message := MSG_DRAW_TEXT[Randomizer];
		MsgPcTurn:     Message := MSG_PC_TURN_TEXT[Randomizer];
		MsgPlayerTurn: Message := MSG_PLAYER_TURN_TEXT[Randomizer];
		MsgNewGame:    Message := MSG_NEW_GAME_TEXT[Randomizer];
	end;

	Message := Replace(Message, Placeholder, CurrentTurn);
	LblMessage^.SetCaption(Message);
end;

procedure PrintStatus;
begin
	if VersusPC then
		LblPlayers^.SetCaption(MSG_GAMEMODE_PC)
	else
		LblPlayers^.SetCaption(MSG_GAMEMODE_PLAYER);

	if SoundOn then
		LblSound^.SetCaption(MSG_SOUND_ON)
	else
		LblSound^.SetCaption(MSG_SOUND_OFF);
end;

procedure BtnNewClick(Sender: PUIObject); far;
begin
	NewGame;
	if VersusPC and (PlayerTurn = PlayerO) then
		PcMove;
end;

procedure BtnGameModeClick(Sender: PUIObject); far;
begin
	VersusPC := not VersusPC;
	NewGame;
	if VersusPC and (PlayerTurn = PlayerO) then
		PcMove;
end;

procedure BtnSoundClick(Sender: PUIObject); far;
begin
	SoundOn := not SoundOn;
	PrintStatus;
end;

procedure BtnAboutClick(Sender: PUIObject); far;
begin
	AboutBox(App);
end;

procedure BtnExitClick(Sender: PUIObject); far;
begin
	App^.Terminate;
end;

procedure PlayFieldClick(Sender: PUIObject); far;
var
	FieldFound: Boolean;
	Row, Col: Integer;
begin
	{Can't do anything if board is full}
	if TotalTurns >= 9 then
	begin
		PlaySound(SndIllegal);
		exit;
	end;

	{Prevent sound from running wild if mouse/key is held down}
	ClearInputBuffer;

	{Find out which field was clicked}
	FieldFound := false;
	for Row := 1 to 3 do
	begin
		for Col := 1 to 3 do
			if PlayField[Row, Col] = PField(Sender) then
			begin
				FieldFound := true;
				break;
			end;

			if FieldFound then
				break;
	end;


	if PlayField[Row, Col]^.GetValue = PlayerNone then
	begin
		PlayField[Row, Col]^.SetValue(PlayerTurn);
		if PlayerTurn = PlayerX then
			PlaySound(SndX)
		else
			PlaySound(SndO);
		Inc(TotalTurns);

		if DidWin then
		begin
			PrintMsg(MsgWin);
			TotalTurns := 9;
			PlaySound(SndWin);
		end
		else
		begin
			if TotalTurns < 9 then
			begin
				if PlayerTurn = PlayerX then
					PlayerTurn := PlayerO
				else
					PlayerTurn := PlayerX;

				if (VersusPC) and (PlayerTurn = PlayerO) then
					PcMove
				else
					PrintMsg(MsgPlayerTurn);
			end
			else
			begin
				PrintMsg(MsgDraw);
				PlaySound(SndDraw);
			end;

		end;
	end
	else
		PlaySound(SndIllegal);
end;

procedure WinMainDraw(Sender: PUIObject); far;
var
	X: integer;
begin
	SetLineStyle(UserBitLn, $1111, 1);
	SetColor(LightGreen);
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
	SetFillStyle(SolidFill, Green);
	Bar(12, 49, 627, 65);    {Top bar for messages}
	Bar(162, 316, 477, 332); {Bottom bar for game mode / sound state}
end;

procedure WinMainRun(Sender: PUIObject); far;
begin
	PlayerTurn := PlayerX;
	PlayerStart := PlayerX;
	SoundOn := True;
end;

procedure InitUI;
var
	Row, Col: Integer;
begin
	New(WinMain, Init(0, 0, nil));
	With WinMain^ do
	begin
		SetSize(640, 350);
		RemoveState(SBordered);
		OnDraw := WinMainDraw;
		OnRun := WinMainRun;
		SetBgColor(Green);
	end;

	New(FrmTic, Init(209, 80, WinMain));
	With FrmTic^ do
	begin
		SetSize(221, 221);
		AddState(STransparent);
		SetBgColor(Green);
		SetLightColor(LightGreen);
		SetDarkColor(DarkGray);
	end;

	for Row := 1 to 3 do
	begin
		for Col := 1 to 3 do
		begin
			New(PlayField[Row, Col], Init(10 + ((Row - 1) * 70), 10 + ((Col - 1) * 70), FrmTic));
			PlayField[Row, Col]^.OnClick := PlayFieldClick;
		end;
	end;

	New(BtnNew, Init(2, 2, CAP_NEW_GAME, WinMain));
	With BtnNew^ do
	begin
		AddHotkey(KeyAltN);
		OnClick := BtnNewClick;
	end;
	New(BtnGameMode, Init(101, 2, CAP_GAME_MODE, WinMain));
	With BtnGameMode^ do
	begin
		AddHotkey(KeyAltM);
		OnClick := BtnGameModeClick;
	end;
	New(BtnSound, Init(200, 2, CAP_SOUND, WinMain));
	With BtnSound^ do
	begin
		AddHotkey(KeyAltS);
		OnClick := BtnSoundClick;
	end;

	New(BtnAbout, Init(446, 2, CAP_ABOUT, WinMain));
	With BtnAbout^ do
	begin
		AddHotkey(KeyAltA);
		OnClick := BtnAboutClick;
	end;
	New(BtnExit, Init(545, 2, CAP_EXIT, WinMain));
	With BtnExit^ do
	begin
		AddHotkey(KeyAltX);
		AddHotkey(KeyAltF4);
		OnClick := BtnExitClick;
	end;

	New(LblMessage, Init(12, 53, AppName + #32 + MSG_BY + #32 + AppAuthor, WinMain));
	with LblMessage^ do
	begin
		RemoveState(STransparent);
		SetSize(616, 8);
		SetFgColor(Black);
		SetBgColor(Green);
		SetAlign(AlCenter);
	end;

	New(LblPlayers, Init(166, 320, MSG_GAMEMODE_PLAYER, WinMain));
	with LblPlayers^ do
	begin
		RemoveState(STransparent);
		SetSize(192, 8);
		SetFgColor(Black);
		SetBgColor(Green);
	end;

	New(LblSound, Init(396, 320, MSG_SOUND_ON, WinMain));
	with LblSound^ do
	begin
		RemoveState(STransparent);
		SetSize(80, 8);
		SetFgColor(Black);
		SetBgColor(Green);
		SetAlign(AlRight);
	end;
end;

begin
	New(App, Init);
	With App^ do
	begin
		Name := AppName;
		Version := AppVersion;
		Author := AppAuthor;
		Icon := AppIcon;
	end;

	InitUI;

	App^.OpenWindow(WinMain);
	App^.Run;
	App^.Terminate;
end.