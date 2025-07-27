program TicTacToe;

uses
	CostaLib, Crt, Strings, Graph;

const
	AppName    = 'Tic Tac Toe';
	AppVersion = '2.0';
	AppAuthor  = 'Jacob Palm';
	AppIcon    = 'TICTAC';

type
	TPlayer  = (PlayerNone, PlayerX, PlayerO);
	TSound   = (SndX, SndO, SndIllegal, SndWin, SndLoose, SndDraw, SndNew);
	TGameMsg = (MsgWin, MsgDraw, MsgPcTurn, MsgPlayerTurn, MsgNewGame);

var
	PlayField: array[1..3, 1..3] of TPlayer;
	TxtPlayField: array[1..3, 1..3] of TTextbox;
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
			X1 := TxtPlayField[Row, Col].Left;
			Y1 := TxtPlayField[Row, Col].Top;
			X2 := TxtPlayField[Row, Col].Left + TxtPlayField[Row, Col].Width;
			Y2 := TxtPlayField[Row, Col].Top + TxtPlayField[Row, Col].Height;
			SetFillStyle(SolidFill, White);
			Bar(X1 + 2, Y1 + 2, X2 - 2, Y2 - 2);
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
	X := TxtPlayField[Row, Col].Left;
	Y := TxtPlayField[Row, Col].Top;

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
	Randomizer := Random(6) + 1;

	if PlayerTurn = PlayerX then
		CurrentTurn := 'X'
	else
		CurrentTurn := 'O';

	if MessageType = MsgWin then
	begin
		case Randomizer of
			1: Message := CurrentTurn + ' has brought honor to the family!';
			2: Message := CurrentTurn + ' has emerged victoriously from the battle!';
			3: Message := 'Nothing could stop ' + CurrentTurn + ' from achieving victory!';
			4: Message := 'The crowd is gasping, amazed at the incredible play by ' + CurrentTurn + '!';
			5: Message := CurrentTurn + ' has brought down utter destruction on the opponent!';
			6: Message := CurrentTurn + ' is unbeatable on the playing field!';
		end;
	end;

	if MessageType = MsgDraw then
	begin
		case Randomizer of
			1: Message := 'It was a real nail-biter, but neither player could best the other.';
			2: Message := 'No winners means no losers, I guess.';
			3: Message := 'A high-stakes game that could have gone both ways.';
			4: Message := 'As eager as both players were, neither of them could achieve victory.';
			5: Message := 'No bragging rights for either player - try again!';
			6: Message := 'An otherwise intense game, which ended with disappointment for both sides.';
		end;
	end;

	if MessageType = MsgPcTurn then
	begin
		case Randomizer of
			1: Message := CurrentTurn + ' is contemplating the next move...';
			2: Message := CurrentTurn + ' is calculating all possible outcomes...';
			3: Message := 'The stakes are too high for ' + CurrentTurn + ' not to think this through...';
			4: Message := CurrentTurn + ' is struggling to find enough CPU power to beat the opponent...';
			5: Message := CurrentTurn + ' is becoming sentient in the quest to beat the humans...';
			6: Message := CurrentTurn + ' is working hard to not loose to a feeble human...';
		end;
	end;

	if MessageType = MsgPlayerTurn then
	begin
		case Randomizer of
			1: Message := 'Make your move, ' + CurrentTurn + '!';
			2: Message := 'How are you going to beat your opponent, ' + CurrentTurn + '?';
			3: Message := 'Uh oh, what a powerfull move! What will ' + CurrentTurn + ' do now?';
			4: Message := 'Take your time ' + CurrentTurn + ' - the stakes are too high to slip up now!';
			5: Message := 'How will you eliminate your opponent, ' + CurrentTurn + '?';
			6: Message := 'Now is the time to prove yourself, ' + CurrentTurn + '!';
		end;
	end;

	if MessageType = MsgNewGame then
	begin
		case Randomizer of
			1: Message := CurrentTurn + ' gets to make the first move!';
			2: Message := 'Looks like ' + CurrentTurn + ' will be the one to strike first!';
			3: Message := 'How will ' + CurrentTurn + ' begin the battle?';
			4: Message := CurrentTurn + ' is preparing the surprise attack carefully...';
			5: Message := CurrentTurn + ' is thinking about the optimal way to start the game...';
			6: Message := 'First move is yours ' + CurrentTurn + ', use it wisely!';
		end;
	end;

	MouseHide;
	SetFillStyle(SolidFill, Green);
	Bar(12, 49, 627, 65);
	Print(Message, (640 - PrintW(Message)) div 2, 53, Black);
	MouseShow;
end;

procedure PrintStatus;
var
	Message: string;
begin	
	Message := 'Playing ';
	if VersusPC then
		Message := Message + 'against computer'
	else
		Message := Message + 'two players     ';

	Message := Message + '     Sound: ';

	if SoundOn then
		Message := Message + 'On '
	else
		Message := Message + 'Off';

	MouseHide;
	SetFillStyle(SolidFill, Green);
	Bar(162, 316, 477, 332);
	Print(Message, (640 - PrintW(Message)) div 2, 320, Black);
	MouseShow;
end;


var
	FieldClicked: boolean;
	FrmTic: TFrame;
	BtnNew, BtnGameMode, BtnAudio, BtnAbout, BtnExit: TButton;
	Row, Col: integer;
	Key: string;
begin
	FieldClicked := false;

	FrmTic.Init(sizeCenter, sizeCenter, 221, 221);
	Inc(FrmTic.Top, 16); {To accomodate menu bar}
	FrmTic.LightColor := LightGreen;

	for Row := 1 to 3 do
	begin
		for Col := 1 to 3 do
		begin
		if (Row = 1) and (Col = 1) then
			TxtPlayField[Row, Col].Init(FrmTic.Left + 10, FrmTic.Top + 10, 60, 60)
		else if Col = 1 then
			TxtPlayField[Row, Col].Init(TxtPlayField[Row - 1, Col].Left,
				TxtPlayField[Row - 1, Col].Top + 70, 60, 60)
		else
			TxtPlayField[Row, Col].Init(TxtPlayField[Row, Col - 1].Left + 70,
				TxtPlayField[Row, Col - 1].Top, 60, 60);
		end;
	end;
	
	BtnNew.Init(3, 2, SizeDefault, SizeDefault, Hotkey + 'New game');
	BtnGameMode.Init(102, 2, SizeDefault, SizeDefault, Hotkey + 'Mode');
	BtnAudio.Init(201, 2, SizeDefault, SizeDefault, Hotkey + 'Sound');
	BtnAbout.Init(446, 2, SizeDefault, SizeDefault, Hotkey + 'About...');
	BtnExit.Init(545, 2, SizeDefault, SizeDefault, 'E' + Hotkey + 'xit');
	
	MouseHide;
	MenuBar.Draw;
	DrawBg;

	SetFillStyle(SolidFill, Green);
	Bar(FrmTic.Left + 2, FrmTic.Top + 2, FrmTic.Left + FrmTic.Width - 2,
		FrmTic.Top + FrmTic.Height - 2);
	FrmTic.Draw;
	BtnNew.Draw;
	BtnGameMode.Draw;
	BtnAudio.Draw;
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
		
		if BtnClick(BtnNew) or (Key = KeyAltN) then
		begin
			NewGame;
			if VersusPC and (PlayerTurn = PlayerO) then
				PcMove;
		end;

		if BtnClick(BtnAbout) or (Key = KeyAltA) then
			AboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if BtnClick(BtnExit) or (Key = KeyAltX) or (Key = KeyAltF4) then
			break;

		if BtnClick(BtnGameMode) or (Key = KeyAltM) then
		begin
			VersusPC := not VersusPC;
			NewGame;
			if VersusPC and (PlayerTurn = PlayerO) then
				PcMove;
		end;

		if BtnClick(BtnAudio) or (Key = KeyAltS) then
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
					if ObjClick(TxtPlayField[Row, Col]) then
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
				{Prevent audio from running wild if mouse/key is held down}
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