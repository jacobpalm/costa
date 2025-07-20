program TicTacToe;

uses
	CostaLib, Crt, Strings, Graph;

const
	AppName          = 'Tic Tac Toe';
	AppVersion       = '2.0';
	AppAuthor        = 'Jacob Palm';
	AppIcon          = 'TICTAC';

type
	TField = record
		Pos: PosType;
	end;

	TPlayer = (PlayerNone, PlayerX, PlayerO);
	TSound = (sndX, sndO, sndIllegal, sndWin, sndLoose, sndDraw, sndNew);
	TGameMsg = (msgWin, msgDraw, msgAITurn, msgPlayerTurn, msgNewGame);

var
	PlayerStart, PlayerTurn: TPlayer;
	TotalTurns: integer;
	EnableAI, EnableAudio: boolean;
	PlayField: array[1..3, 1..3] of TPlayer;
	txtPlayField: array[1..3, 1..3] of TField;

{Forward declarations}
procedure TicDrawXO(Row, Col: integer; Player: TPlayer); forward;
procedure TicPlaySound(SoundType: TSound); forward;
procedure TicPrintMessage(MessageType: TGameMsg); forward;
procedure TicPrintStatus; forward;
function TicCanWin(Player: TPlayer; var Row, Col: integer): boolean; forward;
function TicCheckWin: boolean; forward;

procedure TicAIMove;
var
	Row, Col: integer;
	FoundMove: boolean;
begin
	TicPrintMessage(msgAITurn);
	FoundMove := false;

	{Simulate some random "thinking" time}
	Randomize;
	Delay(Random(850) + 550);

	{Check if the computer can win}
	if TicCanWin(PlayerO, Row, Col) then
	begin
		PlayField[Row, Col] := PlayerO;
		TicDrawXO(Row, Col, PlayerO);
		FoundMove := true;
	end
	{Check if player can win, block if so}
	else if TicCanWin(PlayerX, Row, Col) then
	begin
		PlayField[Row, Col] := PlayerO;
		TicDrawXO(Row, Col, PlayerO);
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
			TicDrawXO(Row, Col, PlayerO);
			break;
		end;
		until false;
	end;

	TicPlaySound(sndO);
	Inc(TotalTurns);
	if TicCheckWin then
	begin
		TicPrintMessage(msgWin);
		TicPlaySound(sndLoose); {Loose, because AI wins}
		TotalTurns := 9;
		exit;
	end;
	
	{If board is full with no winner, it's a draw}
	if TotalTurns = 9 then
	begin
		TicPrintMessage(msgDraw);
		TicPlaySound(sndDraw);
	end
	else
	begin
		{Switch to player, game goes on}
		PlayerTurn := PlayerX;
		TicPrintMessage(msgPlayerTurn);
	end;
end;

function TicCheckWin: boolean;
var
  Row, Col: integer;
  Sum: integer;
begin
	TicCheckWin := false;

	{Check rows}
	for Row := 1 to 3 do
	begin
		if (PlayField[Row, 1] = PlayField[Row, 2]) and
			(PlayField[Row, 2] = PlayField[Row, 3]) and
			(PlayField[Row, 1] <> PlayerNone) then
		begin
			TicCheckWin := true;
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
			TicCheckWin := true;
			exit;
		end;
	end;

	{Check diagonal \}
	if (PlayField[1, 1] = PlayField[2, 2]) and
		(PlayField[2, 2] = PlayField[3, 3]) and
		(PlayField[1, 1] <> PlayerNone) then
	begin
		TicCheckWin := true;
		exit;
	end;

	{Check reverse diagonal /}
	if (PlayField[1, 3] = PlayField[2, 2]) and
		(PlayField[2, 2] = PlayField[3, 1]) and
		(PlayField[1, 3] <> PlayerNone) then
	begin
		TicCheckWin := true;
		exit;
	end;
end;

function TicCanWin(Player: TPlayer; var Row, Col: integer): boolean;
var
	r, c: integer;
	Sum: integer;
begin
    TicCanWin := false;

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
        TicCanWin := true;
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
        TicCanWin := true;
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
      TicCanWin := true;
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
		TicCanWin := true;
		exit;
	end;
end;

procedure TicDrawBackground;
var
	x: integer;
begin
	SetFillStyle(SolidFill, Green);
	Bar(0, 29, 639, 349);

	SetLineStyle(UserBitLn, $1111, 1);
	SetColor(LightGreen);
	for x := 0 to 639 do
	begin
		if x mod 6 = 0 then
			Line(x, 29, x, 349);
	end;

	for x := 3 to 639 do
	begin
		if (x - 3) mod 6 = 0 then
			Line(x, 31, x, 349);
	end;
	SetLineStyle(SolidLn, 0, 1);	
end;

procedure TicDrawBoard;
var
	Row, Col: integer;
	x1, y1, x2, y2: integer;
begin
	MouseHide;
	for Row := 1 to 3 do
	begin
		for Col := 1 to 3 do
		begin
			x1 := txtPlayField[Row, Col].Pos.Left;
			y1 := txtPlayField[Row, Col].Pos.Top;
			x2 := txtPlayField[Row, Col].Pos.Left + txtPlayField[Row, Col].Pos.Width;
			y2 := txtPlayField[Row, Col].Pos.Top + txtPlayField[Row, Col].Pos.Height;
			SetFillStyle(SolidFill, White);
			Bar(x1 + 2, y1 + 2, x2 - 2, y2 - 2);
			SetColor(LightGreen);
			Rectangle(x1, y1, x2 - 1, y2 - 1);
			SetColor(DarkGray);
			Rectangle(x1 + 1, y1 + 1, x2, y2);
		end;
	end;
	MouseShow;
end;

procedure TicDrawXO(Row, Col: integer; Player: TPlayer);
var
	x, y: integer;
begin
	x := txtPlayField[Row, Col].Pos.Left;
	y := txtPlayField[Row, Col].Pos.Top;

	MouseHide;
	SetColor(Black);
	if Player = PlayerX then
	begin
		Line(x + 11, y + 12, x + 48, y + 49);
		Line(x + 11, y + 13, x + 47, y + 49);
		Line(x + 12, y + 12, x + 49, y + 49);
		Line(x + 13, y + 12, x + 49, y + 48);
		Line(x + 11, y + 48, x + 47, y + 12);
		Line(x + 11, y + 49, x + 48, y + 12);
		Line(x + 12, y + 49, x + 49, y + 12);
		Line(x + 13, y + 49, x + 49, y + 13);
	end
	else
	begin
		{DEBUG - circle is not really round, and PutPixel/Line needs rework}
		Circle(x + 30, y + 30, 19);
		Circle(x + 30, y + 30, 18);
		Circle(x + 30, y + 30, 17);
		PutPixel(x + 14, y + 23, Black);
		PutPixel(x + 15, y + 21, Black);
		PutPixel(x + 21, y + 15, Black);
		PutPixel(x + 23, y + 14, Black);
		PutPixel(x + 14, y + 37, Black);
		PutPixel(x + 15, y + 39, Black);
		PutPixel(x + 21, y + 45, Black);
		PutPixel(x + 23, y + 46, Black);
		PutPixel(x + 37, y + 46, Black);
		PutPixel(x + 39, y + 45, Black);
		PutPixel(x + 45, y + 39, Black);
		PutPixel(x + 46, y + 37, Black);
		PutPixel(x + 46, y + 23, Black);
		PutPixel(x + 45, y + 21, Black);
		PutPixel(x + 39, y + 15, Black);
		PutPixel(x + 37, y + 14, Black);
		Line(x + 16, y + 18, x + 18, y + 16);
		Line(x + 42, y + 16, x + 44, y + 18);
		Line(x + 44, y + 42, x + 42, y + 44);
		Line(x + 16, y + 42, x + 18, y + 44);
	end;
	MouseShow;

end;

procedure TicNewGame;
var
	Row, Col: integer;
begin
	for Row := 1 to 3 do
		for Col := 1 to 3 do
			PlayField[Row, Col] := PlayerNone;
	TicDrawBoard;

	TotalTurns := 0;
	if PlayerStart = PlayerX then
		PlayerStart := PlayerO
	else
		PlayerStart := PlayerX;
	
	PlayerTurn := PlayerStart;

	TicPrintMessage(msgNewGame);
	TicPrintStatus;
	TicPlaySound(sndNew);
end;

procedure TicPlaySound(SoundType: TSound);
begin
	if not EnableAudio then
		exit;

	case SoundType of
		sndX:       SoundNote(400, 70);
		sndO:       SoundNote(800, 70);
		sndIllegal: SoundNote(100, 70);
		{sndWin:     PLAY 'O2 T100 C D T200 G T400 E'
		sndLoose:   PLAY 'O1 T400 E3 G3 D6 T100 C9 C9'
		sndDraw:    PLAY 'O1 T400 C9 T100 E9 G9 D C9'
		sndNew:     PLAY 'O2 T180 C8 C8 E3'}
	end;
end;

procedure TicPrintMessage(MessageType: TGameMsg);
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

	if MessageType = msgWin then
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

	if MessageType = msgDraw then
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

	if MessageType = msgAITurn then
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

	if MessageType = msgPlayerTurn then
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

	if MessageType = msgNewGame then
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
	FontPrint(Message, (640 - FontGetWidth(Message, fontHeading)) div 2, 53, Black, fontHeading);
	MouseShow;
end;

procedure TicPrintStatus;
var
	Message: string;
begin	
	Message := 'Playing ';
	if EnableAI then
		Message := Message + 'against computer'
	else
		Message := Message + 'two players     ';

	Message := Message + '     Sound: ';

	if EnableAudio then
		Message := Message + 'On '
	else
		Message := Message + 'Off';

	MouseHide;
	SetFillStyle(SolidFill, Green);
	Bar(162, 316, 477, 332);
	FontPrint(Message, (640 - FontGetWidth(Message, fontHeading)) div 2, 320, Black, fontHeading);
	MouseShow;
end;


var
	FieldClicked: boolean;
	frmTic: FrameType;
	btnNew, btnAIToggle, btnAudio, btnAbout, btnExit: ButtonType;
	Row, Col: integer;
	Key: string;
begin
	FieldClicked := false;

	ObjSetSize(frmTic.Pos, sizeCenter, sizeCenter, 221, 221);

	for Row := 1 to 3 do
	begin
		for Col := 1 to 3 do
		begin
		if (Row = 1) and (Col = 1) then
			ObjSetSize(txtPlayField[Row, Col].Pos, frmTic.Pos.Left + 10, frmTic.Pos.Top + 10, 60, 60)
		else if Col = 1 then
			ObjSetSize(txtPlayField[Row, Col].Pos, txtPlayField[Row - 1, Col].Pos.Left,
				txtPlayField[Row - 1, Col].Pos.Top + 70, 60, 60)
		else
			ObjSetSize(txtPlayField[Row, Col].Pos, txtPlayField[Row, Col - 1].Pos.Left + 70,
				txtPlayField[Row, Col - 1].Pos.Top, 60, 60);
		end;
	end;
	
	btnNew.Init(3, 2, 92, 22, HotkeySymbol + 'New game');
	btnAIToggle.Init(102, 2, 92, 22, HotkeySymbol + 'Mode');
	btnAudio.Init(201, 2, 92, 22, HotkeySymbol + 'Sound');
	btnAbout.Init(446, 2, 92, 22, HotkeySymbol + 'About...');
	btnExit.Init(545, 2, 92, 22, 'E' + HotkeySymbol + 'xit');
	
	MouseHide;
	ObjDrawMenu;
	TicDrawBackground;

	SetFillStyle(SolidFill, Green);
	Bar(frmTic.Pos.Left + 2, frmTic.Pos.Top + 2, frmTic.Pos.Left + frmTic.Pos.Width - 2,
		frmTic.Pos.Top + frmTic.Pos.Height - 2);
	ObjDrawFrm(frmTic, 10, 8);
	ObjDrawBtn(btnNew, false);
	ObjDrawBtn(btnAIToggle, false);
	ObjDrawBtn(btnAudio, false);
	ObjDrawBtn(btnAbout, false);
	ObjDrawBtn(btnExit, false);
	MouseShow;

	PlayerTurn := PlayerX;
	PlayerStart := PlayerX;
	TicDrawBoard;
	TicPlaySound(sndNew);
	TicPrintMessage(msgNewGame);
	TicPrintStatus;

	repeat
		Key := GetKey;
		
		if ObjBtnClick(btnNew) or (Key = KeyAltN) then
		begin
			TicNewGame;
			if EnableAI and (PlayerTurn = PlayerO) then
				TicAIMove;
		end;

		if ObjBtnClick(btnAbout) or (Key = KeyAltA) then
			SysAboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if ObjBtnClick(btnExit) or (Key = KeyAltX) or (Key = KeyAltF4) then
			break;

		if ObjBtnClick(btnAIToggle) or (Key = KeyAltM) then
		begin
			EnableAI := not EnableAI;
			TicNewGame;
			if EnableAI and (PlayerTurn = PlayerO) then
				TicAIMove;
		end;

		if ObjBtnClick(btnAudio) or (Key = KeyAltS) then
		begin
			EnableAudio := not EnableAudio;
			TicPrintStatus;
		end;

		if TotalTurns < 9 then
		begin
			for Row := 1 to 3 do
			begin
				for Col := 1 to 3 do
				begin
					if ObjClick(txtPlayField[Row, Col].Pos) then
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
				repeat until (Length(GetKey) = 0) and (MouseClicked = mbNone);

				if PlayField[Row, Col] = PlayerNone then
				begin
					FieldClicked := false;
					PlayField[Row, Col] := PlayerTurn;
					TicDrawXO(Row, Col, PlayerTurn);
					if PlayerTurn = PlayerX then
						TicPlaySound(sndX)
					else
						TicPlaySound(sndO);
					Inc(TotalTurns);

					if TicCheckWin = true then
					begin
						TicPrintMessage(msgWin);
						TotalTurns := 9;
						TicPlaySound(sndWin);
					end
					else
					begin
						if TotalTurns < 9 then
						begin
							if PlayerTurn = PlayerX then
								PlayerTurn := PlayerO
							else
								PlayerTurn := PlayerX;

							if (EnableAI = true) and (PlayerTurn = PlayerO) then
								TicAIMove
							else
								TicPrintMessage(msgPlayerTurn);
						end
						else
						begin
							TicPrintMessage(msgDraw);
							TicPlaySound(sndDraw);
						end;

					end;
				end
				else
					TicPlaySound(sndIllegal);
			end;
		end;

	until false;
	
	CloseGraph;
end.