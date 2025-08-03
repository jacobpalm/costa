program TicTacToe;

uses
	CostaLib, Crt, Strings, Graph;

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

	MSG_WIN_TEXT: array[0..5] of string = (
		'%s has brought honor to the family!',
		'%s has emerged victoriously from the battle!',
		'Nothing could stop %s from achieving victory!',
		'The crowd is gasping, amazed at the incredible play by %s!',
		'%s has brought down utter destruction on the opponent!',
		'%s is unbeatable on the playing field!'	);
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
		'First move is yours %s, use it wisely!'
	);

type
	TPlayer  = (PlayerNone, PlayerX, PlayerO);
	TSound   = (SndX, SndO, SndIllegal, SndWin, SndLoose, SndDraw, SndNew);
	TGameMsg = (MsgWin, MsgDraw, MsgPcTurn, MsgPlayerTurn, MsgNewGame);

var
	PlayField: array[1..3, 1..3] of TPlayer;
	AreaPlayField: array[1..3, 1..3] of TArea;
	PlayerStart, PlayerTurn: TPlayer;
	TotalTurns: integer;
	VersusPC, SoundOn: boolean;

{Forward declarations}
procedure DrawXO(Row, Col: integer; Player: TPlayer); forward;
procedure PlaySound(SoundType: TSound); forward;
procedure PrintMsg(MessageType: TGameMsg); forward;
procedure PrintStatus; forward;
function  CanWin(Player: TPlayer; var Row, Col: integer): boolean; forward;
function  DidWin: boolean; forward;

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
		PlayField[Row, Col] := PlayerO;
		DrawXO(Row, Col, PlayerO);
		FoundMove := true;
	end
	{Check if player can win, block if so}
	else if CanWin(PlayerX, Row, Col) then
	begin
		PlayField[Row, Col] := PlayerO;
		DrawXO(Row, Col, PlayerO);
		FoundMove := true;
	end;

	{If AI can't win, and player can't either, just pick a random spot}
	if not FoundMove then
	begin
		repeat
		Col := Random(3) + 1;
		Row := Random(3) + 1;

		if PlayField[Row, Col] = PlayerNone then
		begin
			PlayField[Row, Col] := PlayerO;
			DrawXO(Row, Col, PlayerO);
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
		if (PlayField[Row, 1] = PlayField[Row, 2]) and
			(PlayField[Row, 2] = PlayField[Row, 3]) and
			(PlayField[Row, 1] <> PlayerNone) then
		begin
			DidWin := true;
			exit;
		end;
	end;

	{Check columns}
	for Col := 1 to 3 do
	begin
		if (PlayField[1, Col] = PlayField[2, Col]) and
			(PlayField[2, Col] = PlayField[3, Col]) and
			(PlayField[1, Col] <> PlayerNone) then
		begin
			DidWin := true;
			exit;
		end;
	end;

	{Check diagonal \}
	if (PlayField[1, 1] = PlayField[2, 2]) and
		(PlayField[2, 2] = PlayField[3, 3]) and
		(PlayField[1, 1] <> PlayerNone) then
	begin
		DidWin := true;
		exit;
	end;

	{Check reverse diagonal /}
	if (PlayField[1, 3] = PlayField[2, 2]) and
		(PlayField[2, 2] = PlayField[3, 1]) and
		(PlayField[1, 3] <> PlayerNone) then
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
        if PlayField[r, c] = Player then
          Inc(Sum)
        else if PlayField[r, c] = PlayerNone then
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
        if PlayField[r, c] = Player then
          Inc(Sum)
        else if PlayField[r, c] = PlayerNone then
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
      if PlayField[r, r] = Player then
        Inc(Sum)
      else if PlayField[r, r] = PlayerNone then
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
		if PlayField[r, c] = Player then
			Inc(Sum)
		else if PlayField[r, c] = PlayerNone then
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

procedure DrawBg;
var
	X: integer;
begin
	SetFillStyle(SolidFill, Green);
	Bar(0, 29, 639, 349);

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
end;

procedure DrawBoard;
var
	Row, Col: integer;
	X1, Y1, X2, Y2: integer;
begin
	MouseHide;
	for Row := 1 to 3 do
	begin
		for Col := 1 to 3 do
		begin
			AreaPlayField[Row, Col].Draw;
			X1 := AreaPlayField[Row, Col].Left;
			Y1 := AreaPlayField[Row, Col].Top;
			X2 := AreaPlayField[Row, Col].Left + AreaPlayField[Row, Col].Width;
			Y2 := AreaPlayField[Row, Col].Top + AreaPlayField[Row, Col].Height;
			{Draw light green border around each cell instead of
			 default color, to match app theme}
			SetColor(LightGreen);
			Rectangle(X1, Y1, X2 - 1, Y2 - 1);
			SetColor(DarkGray);
			Rectangle(X1 + 1, Y1 + 1, X2, Y2);
		end;
	end;
	MouseShow;
end;

procedure DrawXO(Row, Col: integer; Player: TPlayer);
var
	X, Y: integer;
begin
	X := AreaPlayField[Row, Col].Left;
	Y := AreaPlayField[Row, Col].Top;

	MouseHide;
	SetColor(Black);
	if Player = PlayerX then
	begin
		Line(X + 11, Y + 12, X + 48, Y + 49);
		Line(X + 11, Y + 13, X + 47, Y + 49);
		Line(X + 12, Y + 12, X + 49, Y + 49);
		Line(X + 13, Y + 12, X + 49, Y + 48);
		Line(X + 11, Y + 48, X + 47, Y + 12);
		Line(X + 11, Y + 49, X + 48, Y + 12);
		Line(X + 12, Y + 49, X + 49, Y + 12);
		Line(X + 13, Y + 49, X + 49, Y + 13);
	end
	else
	begin
		{DEBUG - circle is not really round, and PutPixel/Line needs rework}
		Circle(X + 30, Y + 30, 19);
		Circle(X + 30, Y + 30, 18);
		Circle(X + 30, Y + 30, 17);
		PutPixel(X + 14, Y + 23, Black);
		PutPixel(X + 15, Y + 21, Black);
		PutPixel(X + 21, Y + 15, Black);
		PutPixel(X + 23, Y + 14, Black);
		PutPixel(X + 14, Y + 37, Black);
		PutPixel(X + 15, Y + 39, Black);
		PutPixel(X + 21, Y + 45, Black);
		PutPixel(X + 23, Y + 46, Black);
		PutPixel(X + 37, Y + 46, Black);
		PutPixel(X + 39, Y + 45, Black);
		PutPixel(X + 45, Y + 39, Black);
		PutPixel(X + 46, Y + 37, Black);
		PutPixel(X + 46, Y + 23, Black);
		PutPixel(X + 45, Y + 21, Black);
		PutPixel(X + 39, Y + 15, Black);
		PutPixel(X + 37, Y + 14, Black);
		Line(X + 16, Y + 18, X + 18, Y + 16);
		Line(X + 42, Y + 16, X + 44, Y + 18);
		Line(X + 44, Y + 42, X + 42, Y + 44);
		Line(X + 16, Y + 42, X + 18, Y + 44);
	end;
	MouseShow;

end;

procedure NewGame;
var
	Row, Col: integer;
begin
	for Row := 1 to 3 do
		for Col := 1 to 3 do
			PlayField[Row, Col] := PlayerNone;
	DrawBoard;

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
		SndX:       SoundNote(400, 70);
		SndO:       SoundNote(800, 70);
		SndIllegal: SoundNote(100, 70);
		{DEBUG}
		{SndWin:     PLAY 'O2 T100 C D T200 G T400 E'
		SndLoose:   PLAY 'O1 T400 E3 G3 D6 T100 C9 C9'
		SndDraw:    PLAY 'O1 T400 C9 T100 E9 G9 D C9'
		SndNew:     PLAY 'O2 T180 C8 C8 E3'}
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
	
	Message := ReplaceMsg(Message, CurrentTurn);

	MouseHide;
	SetFillStyle(SolidFill, Green);
	Bar(12, 49, 627, 65);
	Print(Message, (640 - PrintW(Message)) div 2, 53, Black);
	MouseShow;
end;

procedure PrintStatus;
var
	ModeMsg, SoundMsg: string;
begin	
	if VersusPC then
		ModeMsg := MSG_GAMEMODE_PC
	else
		ModeMsg := MSG_GAMEMODE_PLAYER;

	if SoundOn then
		SoundMsg := MSG_SOUND_ON
	else
		SoundMsg := MSG_SOUND_OFF;

	MouseHide;
	SetFillStyle(SolidFill, Green);
	Bar(162, 316, 477, 332);
	Print(ModeMsg, 166, 320, Black);
	Print(SoundMsg, 476 - PrintW(SoundMsg), 320, Black);
	MouseShow;
end;


var
	FieldClicked: boolean;
	FrmTic: TFrame;
	BtnNew, BtnGameMode, BtnSound, BtnAbout, BtnExit: TButton;
	Row, Col: integer;
	Key: string;
begin
	FieldClicked := false;

	FrmTic.Init(sizeCenter, sizeCenter, 221, 221);
	FrmTic.Transparent := false;
	FrmTic.BgColor := Green;
	Inc(FrmTic.Top, 16); {To accomodate menu bar}
	FrmTic.LightColor := LightGreen;

	for Row := 1 to 3 do
	begin
		for Col := 1 to 3 do
		begin
		if (Row = 1) and (Col = 1) then
			AreaPlayField[Row, Col].Init(FrmTic.Left + 10, FrmTic.Top + 10, 60, 60)
		else if Col = 1 then
			AreaPlayField[Row, Col].Init(AreaPlayField[Row - 1, Col].Left,
				AreaPlayField[Row - 1, Col].Top + 70, 60, 60)
		else
			AreaPlayField[Row, Col].Init(AreaPlayField[Row, Col - 1].Left + 70,
				AreaPlayField[Row, Col - 1].Top, 60, 60);
		AreaPlayField[Row, Col].BGColor := White;
		end;
	end;
	
	BtnNew.Init(3, 2, SizeDefault, SizeDefault, CAP_NEW_GAME);
	BtnGameMode.Init(102, 2, SizeDefault, SizeDefault, CAP_GAME_MODE);
	BtnSound.Init(201, 2, SizeDefault, SizeDefault, CAP_SOUND);
	BtnAbout.Init(446, 2, SizeDefault, SizeDefault, CAP_ABOUT);
	BtnExit.Init(545, 2, SizeDefault, SizeDefault, CAP_EXIT);
	
	MouseHide;
	MenuBar.Draw;
	DrawBg;

	FrmTic.Draw;
	BtnNew.Draw;
	BtnGameMode.Draw;
	BtnSound.Draw;
	BtnAbout.Draw;
	BtnExit.Draw;
	MouseShow;

	PlayerTurn := PlayerX;
	PlayerStart := PlayerX;
	DrawBoard;
	PlaySound(SndNew);
	PrintMsg(MsgNewGame);
	PrintStatus;

	repeat
		Key := GetKey;
		
		if BtnNew.Clicked or (Key = KeyAltN) then
		begin
			NewGame;
			if VersusPC and (PlayerTurn = PlayerO) then
				PcMove;
		end;

		if BtnAbout.Clicked or (Key = KeyAltA) then
			AboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if BtnExit.Clicked or (Key = KeyAltX) or (Key = KeyAltF4) then
			break;

		if BtnGameMode.Clicked or (Key = KeyAltM) then
		begin
			VersusPC := not VersusPC;
			NewGame;
			if VersusPC and (PlayerTurn = PlayerO) then
				PcMove;
		end;

		if BtnSound.Clicked or (Key = KeyAltS) then
		begin
			SoundOn := not SoundOn;
			PrintStatus;
		end;

		if TotalTurns < 9 then
		begin
			for Row := 1 to 3 do
			begin
				for Col := 1 to 3 do
				begin
					if AreaPlayField[Row, Col].Clicked then
					begin
						FieldClicked := true;
						break;
					end;
				end;
				if FieldClicked then
					break;
			end;

			if FieldClicked then
			begin
				{Prevent sound from running wild if mouse/key is held down}
				ClearInputBuffer;

				if PlayField[Row, Col] = PlayerNone then
				begin
					FieldClicked := false;
					PlayField[Row, Col] := PlayerTurn;
					DrawXO(Row, Col, PlayerTurn);
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
		end;

	until false;
	
	CloseGraph;
end.