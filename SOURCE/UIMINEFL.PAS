unit UIMINEFL;

interface

uses
	Costalib, UILabel, Graph;

type
	TSound         = (SNew, SInvalid, SWin, SLoose, SClear, SFlag);
	TDirection     = (DUp, DDown, DLeft, DRight, DShow, DHide);

	TMinefieldSize = (SSmall, SMedium, SLarge, SUltra);
	TMineGameState = (GNew, GPlaying, GPaused, GWon, GLost);

	TMineFlag      = (FMined, FFlagged, FCleared, FExploded, FSelected);
	TMineFlagSet   = set of TMineFlag;

	PMineField = ^TMineField;
	TMineField = object(TUIObject)
		public
			constructor   Init(Parent: PContainer);
			procedure     Draw; virtual;
			procedure     CheckEvent; virtual;

			procedure     NewGame;
			procedure     PauseGame;
			procedure     ResumeGame;
			procedure     Cheat;

			procedure     SetFieldSize(Size: TMinefieldSize);
			procedure     SetSound(On: boolean);
			function      GetSound: boolean;
			function      GetGameState: TMineGameState;

			function      GetFlagged: integer;
			function      GetMineCount: integer;

			function      GetElapsedTime: real;
		private
			Cell:         array[0..17, 0..38] of TMineFlagSet; {Array of cell flags (row, cols)}

			Rows,
			Cols:         byte;    {Width and height in number of cells}
			
			Mines:        byte;    {Number of mines in the field}

			Cleared,
			Flagged:      integer; {Number of Cleared and Flagged cells}

			IndicatorRow,
			IndicatorCol: byte;    {Keyboard indicator position}

			StartTime:    real;    {Time when game was started}
			PauseTime:    real;    {Time when game was paused}
			SoundOn:      boolean; {Is sound enabled?}
			GameState:    TMineGameState;
			
			function      GetNeighborCount(Row, Col: byte): byte;
			procedure     ClearCell(Row, Col: byte);
			procedure     ClickCell(Row, Col: byte; MouseButton: TMouseButton);
			procedure     MoveIndicator(Direction: TDirection);
			procedure     DrawCell(Row, Col: byte);
			procedure     HelpFirstMove(Row, Col: byte);
			procedure     PlaySound(SoundType: TSound);
			procedure     WinGame;
	end;

implementation

const
	MSG_PAUSE  = 'Game paused';

	CellSize   = 16; {Size of each clickable field in pixels}

constructor TMineField.Init(Parent: PContainer);
begin
	TUIObject.Init;
	SetFieldSize(SMedium);
	SetParent(Parent);
	Cleared   := 0;
	Flagged   := 0;
	SoundOn   := true;
	GameState := GNew;
	StartTime := 0;
	PauseTime := 0;

	FillChar(Cell, SizeOf(Cell), 0);
	
	{Center keyboard indicator and turn it off by default}
	IndicatorRow := Rows div 2;
	IndicatorCol := Cols div 2;
end;

procedure TMineField.Draw;
var
	R, C: byte;
	X1, Y1, X2, Y2: integer;
begin
	if GetState(SHidden) then
		exit;
	
	{Get absolute position and size of the object}
	GetPos(X1, Y1, True);
	GetSize(X2, Y2);	
	Inc(X2, X1);
	Inc(Y2, Y1);

	Mouse.Hide;

	{Button color}
	SetFillStyle(SolidFill, LightGray);
	Bar(X1, Y1, X2, Y2);

	{Button light and shadows for first row/column}
	SetColor(White);
	Line(X1 + 1, Y1 + 1, X2, Y1 + 1);
	Line(X1 + 1, Y1 + 1, X1 + 1, Y2);
	SetColor(DarkGray);
	Line(X1 + 2, Y2 - 1, X2 - 1, Y2 - 1);
	Line(X2 - 1, Y1 + 2, X2 - 1, Y2 - 1);

	{Button light and shadows}
	for C := 1 to Cols - 1 do
	begin
		SetColor(White);
		Line(X1 + C * CellSize + 1, Y1, X1 + C * CellSize + 1, Y1 + Rows * CellSize);
		SetColor(DarkGray);
		Line(X1 + C * CellSize - 1, Y1 + 1, X1 + C * CellSize - 1, Y1 + Rows * CellSize);
	end;
	for R := 1 to Rows - 1 do
	begin
		SetColor(White);
		Line(X1, Y1 + R * CellSize + 1, X1 + Cols * CellSize, Y1 + R * CellSize + 1);
		SetColor(DarkGray);
		Line(X1 + 1, Y1 + R * CellSize - 1, X1 + Cols * CellSize, Y1 + R * CellSize - 1);
	end;

	{Button borders}
	SetColor(Black);
	for C := 1 to Cols - 1 do
		Line(X1 + C * CellSize, Y1, X1 + C * CellSize, Y1 + Rows * CellSize);
	for R := 1 to Rows - 1 do
		Line(X1, Y1 + R * CellSize, X1 + Cols * CellSize, Y1 + R * CellSize);

	{Borders around playfield}
	Rectangle(X1, Y1, X2, Y2);
	
	Mouse.Show;
end;

procedure TMinefield.DrawCell(Row, Col: byte);
var
	X1, Y1, X2, Y2: integer;
	TextColor, Neighbors: byte;
	NeighborStr: string;
begin
	{Calculate absolute position of cell within area}
	GetPos(X1, Y1, True);
	X1 := X1 + 1 + Col * CellSize;
	Y1 := Y1 + 1 + Row * CellSize;
	X2 := X1 + CellSize - 2;
	Y2 := Y1 + CellSize - 2;

	if FExploded in Cell[Row, Col] then
	begin
		{FExploded field. Kaboom!}
		SetFillStyle(SolidFill,  Red);
		Bar(X1, Y1, X2, Y2);

		{Mine}
		SetFillStyle(SolidFill,  Black);
		Bar(X1 + 5, Y1 + 3, X1 + 9, Y1 + 11);
		Bar(X1 + 3, Y1 + 5, X1 + 11, Y1 + 9);
		PutPixel(X1 + 3, Y1 + 3, Black);
		PutPixel(X1 + 3, Y1 + 11, Black);
		PutPixel(X1 + 4, Y1 + 4, Black);
		PutPixel(X1 + 4, Y1 + 10, Black);
		PutPixel(X1 + 10, Y1 + 10, Black);
		PutPixel(X1 + 11, Y1 + 11, Black);
		PutPixel(X1 + 10, Y1 + 4, Black);
		PutPixel(X1 + 11, Y1 + 3, Black);
		SetColor(0);
		Line(X1 + 1, Y1 + 7, X2 - 1, Y1 + 7);
		Line(X1 + 7, Y1 + 1, X1 + 7, Y2 - 1);
		SetColor(White);
		Rectangle(X1 + 5, Y1 + 5, X1 + 6, Y1 + 6);
	end
	else if FFlagged in Cell[Row, Col] then
	begin
		{FFlagged field}
		{Background}
		if FSelected in Cell[Row, Col] then
		begin
			SetFillStyle(SolidFill, White);
			Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
		end
		else
		begin
			SetFillStyle(SolidFill, LightGray);
			Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
		end;

		{Flag pole}
		SetColor(Black);
		Line(X1 + 6, Y1 + 2, X1 + 6, Y1 + 10);
		Line(X1 + 4, Y1 + 11, X1 + 8, Y1 + 11);
		Line(X1 + 3, Y1 + 12, X1 + 9, Y1 + 12);
		{Flag}
		SetColor(LightRed);
		Line(X1 + 7, Y1 + 2, X1 + 7, Y1 + 8);
		Line(X1 + 8, Y1 + 3, X1 + 8, Y1 + 7);
		Line(X1 + 9, Y1 + 4, X1 + 9, Y1 + 6);
		PutPixel(X1 + 10, Y1 + 5, LightRed);
	end
	else if FCleared in Cell[Row, Col] then
	begin
		{FCleared field}
		SetFillStyle(SolidFill, LightGray);
		Bar(X1, Y1, X2, Y2);

		{Draw keyboard indicator if FSelected}
		if FSelected in Cell[Row, Col] then
		begin
			SetFillStyle(SolidFill, White);
			Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
		end;

		{Draw neighbor count, if any}
		Neighbors := GetNeighborCount(Row, Col);
		if Neighbors > 0 then
		begin
			case Neighbors of
				1: TextColor := 9;
				2: TextColor := 2;
				3: TextColor := 12;
				4: TextColor := 1;
				5: TextColor := 4;
				6: TextColor := 3;
				7: TextColor := 0;
				8: TextColor := 8;
			end;
			Str(Neighbors, NeighborStr);
			Print(NeighborStr, X1 + ((CellSize - PrintW(NeighborStr)) div 2), Y1 + 3, TextColor);
		end;
	end
	else if FSelected in Cell[Row, Col] then
	begin
		{Uncleared, not FFlagged, not FExploded, but FSelected with keyboard}
		SetFillStyle(SolidFill, White);
		Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
	end
	else
	begin
		{Not FCleared, FFlagged, FExploded or FSelected - meaning flag must have been
		 removed.}

		{Clear button face}
		SetFillStyle(SolidFill, LightGray);
		Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
	end;
end;

procedure TMineField.CheckEvent;
var
	R, C: byte;
	X1, Y1: integer;
	MouseButton: TMouseButton;
	KeyPressed: boolean;
begin
	{Don't check for events if object is disabled or hidden}
	if not GetState(SEnabled) or GetState(SHidden) then
		exit;
	
	{If the game has been paused, won or lost, ignore input events}
	if GameState in [GPaused, GWon, GLost] then
		exit;
	
	{Check for mouse click}
	if IsMouseOver and (Mouse.Clicked <> MbNone) then
	begin
		{Capture mouse state}
		MouseButton := Mouse.Clicked;
		Mouse.Poll;

		{Since mouse was clicked, hide the keyboard indicator if visible}
		MoveIndicator(DHide);

		{Calculate mouse position in field, then convert to cell coordinates}
		GetPos(X1, Y1, True);
		C := (Mouse.X - X1) div CellSize;
		R := (Mouse.Y - Y1) div CellSize;

		{Play field is one pixel too wide for calculation above, dirty fix
		for this to prevent out of bounds clicks}
		if C = Cols then
			Dec(C);
		if R = Rows then
			Dec(R);

		ClickCell(R, C, MouseButton);

		{Prevent sound from running wild if mouse is held down}
		repeat; until Mouse.Clicked = MbNone;

		{Trigger OnClick event, if assigned}
		Self.Click;
	end;

	{Check for keyboard input}
	if Length(HotkeyInput) = 0 then
		exit;

	KeyPressed := false;	
	if HotkeyInput = KeyUp then
	begin
		KeyPressed := true;
		MoveIndicator(DUp);
	end;
	if HotkeyInput = KeyDown then
	begin
		KeyPressed := true;
		MoveIndicator(DDown);
	end;
	if HotkeyInput = KeyLeft then
	begin
		KeyPressed := true;
		MoveIndicator(DLeft);
	end;
	if HotkeyInput = KeyRight then
	begin
		KeyPressed := true;
		MoveIndicator(DRight);
	end;
	
	{Enter to clear a cell, Space to toggle flag}
	if HotkeyInput = KeyEnter then
	begin
		KeyPressed := true;
		ClickCell(IndicatorRow, IndicatorCol, MbLeft);
		MoveIndicator(DShow);
	end;
	if HotkeyInput = KeySpace then
	begin
		KeyPressed := true;
		ClickCell(IndicatorRow, IndicatorCol, MbRight);
		MoveIndicator(DShow);
	end;
	
	if KeyPressed then
	begin
		{If a key was pressed, clear it so other objects won't catch it}
		HotkeyInput := '';

		{Trigger OnClick event, if assigned}
		Self.Click;
	end;
end;

procedure TMinefield.PauseGame;
var
	X1, Y1, X2, Y2, W, H: integer;
begin
	{If game not playing, ignore pause request}
	if GameState <> GPlaying then
		exit;

	PauseTime := Timer;

	GetPos(X1, Y1, True);
	GetSize(W, H);
	X2 := X1 + W;
	Y2 := Y1 + H;
	
	{Clear field - no peeking at field while timer is stopped!}
	Mouse.Hide;
	SetFillStyle(SolidFill, LightGray);
	Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);

	{Center pause text in field}
	X1 := X1 + ((W - PrintW(MSG_PAUSE)) div 2);
	Y1 := Y1 + ((H - PrintH(MSG_PAUSE)) div 2);
	Print(MSG_PAUSE, X1, Y1, Black);
	Mouse.Show;

	GameState := GPaused;
	exit;
end;

procedure TMineField.ResumeGame;
var
	R, C: byte;
	X1, Y1, X2, Y2: integer;
begin
	{Can't resume if not paused}
	if GameState <> GPaused then
		exit;

	{Redraw field, which was hidden on pause}
	Mouse.Hide;
	Draw;
	for R := 0 to Rows - 1 do
	begin
		for C := 0 to Cols - 1 do
		begin
			DrawCell(R, C);
		end;
	end;
	Mouse.Show;

	GameState := GPlaying;

	{Adjust start time to account for paused duration}
	StartTime := StartTime + (Timer - PauseTime);
end;

procedure TMinefield.SetSound(On: boolean);
begin
	SoundOn := On;
end;

function TMinefield.GetElapsedTime: real;
begin
	if GameState = GPlaying then
		GetElapsedTime := Timer - StartTime
	else
		GetElapsedTime := 0;
end;

function TMinefield.GetFlagged: integer;
begin
	GetFlagged := Flagged;
end;

function TMinefield.GetMineCount: integer;
begin
	GetMineCount := Mines;
end;

function TMinefield.GetSound: boolean;
begin
	GetSound := SoundOn;
end;

function TMinefield.GetGameState: TMineGameState;
begin
	GetGameState := GameState;
end;

procedure TMinefield.Cheat;
var
	X1, Y1, X2, Y2, OffX, OffY: integer;
	R, C: byte;
begin
	GetPos(OffX, OffY, True);

	SetColor(Red);
	Mouse.Hide;
	for R := 0 to Rows - 1 do
	begin
		for C := 0 to Cols - 1 do
		begin
			if FMined in Cell[R, C] then
			begin
				X1 := OffX + 1 + C * CellSize;
				Y1 := OffY + 1 + R * CellSize;
				X2 := X1 + CellSize - 2;
				Y2 := Y1 + CellSize - 2;
				Rectangle(X1, Y1, X2, Y2);
			end;
		end;
	end;
	Mouse.Show;
end;

procedure TMinefield.MoveIndicator(Direction: TDirection);
begin
	if not (GameState in [GNew, GPlaying]) then
		exit;

	{Hide current indicator}
	if FSelected in Cell[IndicatorRow, IndicatorCol] then
	begin
		Exclude(Cell[IndicatorRow, IndicatorCol], FSelected);
		Mouse.Hide;
		DrawCell(IndicatorRow, IndicatorCol);
		Mouse.Show;
	end;

	{If direction is DHide, just exit now as we've already hidden the indicator}
	if Direction = DHide then
		exit;

	case Direction of
		DUp:
			if IndicatorRow > 0 then
				Dec(IndicatorRow);
		DDown:
			if IndicatorRow < Rows - 1 then
				Inc(IndicatorRow);
		DLeft:
			if IndicatorCol > 0 then
				Dec(IndicatorCol);
		DRight:
			if IndicatorCol < Cols - 1 then
				Inc(IndicatorCol);
	end;

	{We don't need to handle DSHow, as the indicator position is already set}

	{Set new indicator and draw it}
	Include(Cell[IndicatorRow, IndicatorCol], FSelected);
	Mouse.Hide;
	DrawCell(IndicatorRow, IndicatorCol);
	Mouse.Show;
end;

procedure TMineField.NewGame;
var
	R, C, MinesPlaced: byte;
begin
	{Clear mine array}	
	FillChar(Cell, SizeOf(Cell), 0);
		
	{Randomly place mines}
	Randomize;
	MinesPlaced := 0;
	repeat
		R := Random(Rows);
		C := Random(Cols);
		if not (FMined in Cell[R, C]) then
		begin
			Include(Cell[R, C], FMined);
			Inc(MinesPlaced);
		end;
	until MinesPlaced = Mines;

	{Draw the field}
	Draw;

	{Don't play a new game sound if we were already in a new game, to avoid delay
	 while starting the first game on app launch}
	if GameState <> GNew then
		PlaySound(SNew);

	{Reset game state}
	GameState := GNew;
	Cleared := 0;
	Flagged := 0;
	StartTime := 0;
	
	{Center keyboard indicator and turn it off by default}
	IndicatorRow := Rows div 2;
	IndicatorCol := Cols div 2;
end;

procedure TMinefield.WinGame;
var
	R, C: byte;
begin
	{Victory! Reveal mines by flaggin them and end game}
	for R := 0 to Rows - 1 do
	begin
		for C := 0 to Cols - 1 do
		begin
			if FMined in Cell[R, C] then
			begin
				if not (FFlagged in Cell[R, C]) then
				begin
					Include(Cell[R, C], FFlagged);
					DrawCell(R, C);
					Inc(Flagged);
				end;
			end;
		end;
	end;
	PlaySound(SWin);
	GameState := GWon;
end;

function TMinefield.GetNeighborCount(Row, Col: byte): byte;
var
	Neighbors: byte;
	R, C: Integer;
begin
	Neighbors := 0;
	for R := Row - 1 to Row + 1 do
	begin
		for C := Col - 1 to Col + 1 do
		begin
			{Skip out of bounds cells}
			if (R < 0) or (R > Rows - 1) or
			   (C < 0) or (C > Cols - 1) then
				continue;

			if FMined in Cell[R, C] then
				Inc(Neighbors);
		end;
	end;

	GetNeighborCount := Neighbors;
end;

{Clears the clicked cell, and if it has no neighboring mines,
  recursively clears all adjacent empty cells as well.}
procedure TMinefield.ClearCell(Row, Col: byte);
type
	{Linked list node for flood-fill algorithm used to clear empty neighbor cells}
	PNode = ^TNode;
	TNode = record
		Row,
		Col:  byte;
		Next: PNode;
	end;

var
	Stack: PNode;
	NeighborRow, NeighborCol: integer;

	{Help functions for stack handling}
	procedure Push(Row, Col: byte);
	var
		NewNode: PNode;
	begin
		New(NewNode);
		NewNode^.Row := Row;
		NewNode^.Col := Col;
		NewNode^.Next := Stack;
		Stack := NewNode;
	end;

	function Pop(var Row, Col: byte): boolean;
	var
		Temp: PNode;
	begin
		Pop := false;
		if not Assigned(Stack) then
			exit;

		Temp := Stack;
		Row := Temp^.Row;
		Col := Temp^.Col;
		Stack := Temp^.Next;
		Dispose(Temp);
		Pop := true;
	end;

begin

	Stack := nil;
	Push(Row, Col);

	while Pop(Row, Col) do
	begin
		{Skip already FCleared, or FFlagged, fields}
		if (FCleared in Cell[Row, Col]) or (FFlagged in Cell[Row, Col]) then
			continue;

		{Add FCleared flag, redraw cell and increment FCleared cells count}
		Include(Cell[Row, Col], FCleared);
		DrawCell(Row, Col);
		Inc(Cleared);
		
		{If current field has no mines around it, add its neighbors to the stack
		 for checking if they should be FCleared as well}
		if GetNeighborCount(Row, Col) = 0 then
		begin
			for NeighborRow := Row - 1 to Row + 1 do
			begin
				for NeighborCol := Col - 1 to Col + 1 do
				begin
					{Don't add the same cell again}
					if (NeighborRow = Row) and (NeighborCol = Col) then
						continue;

					{Check bounds}
					if (NeighborRow < 0) or (NeighborRow >= Rows) or
					   (NeighborCol < 0) or (NeighborCol >= Cols) then
						continue;
					
					if Cell[NeighborRow, NeighborCol] = [] then
						Push(NeighborRow, NeighborCol);
				end;
			end;
		end;
	end;
end;

procedure TMinefield.ClickCell(Row, Col: byte; MouseButton: TMouseButton);
var
	IndicatorOn: boolean;
begin
	{Sanity check}
	if (Row < 0) or (Row >= Rows) or
	   (Col < 0) or (Col >= Cols) then
		exit;
	
	{Move keyboard indicator if needed}
	if (IndicatorRow <> Row) or (IndicatorCol <> Col) then
	begin
		IndicatorOn := FSelected in Cell[IndicatorRow, IndicatorCol];
		if IndicatorOn then
			MoveIndicator(DHide);
		IndicatorRow := Row;
		IndicatorCol := Col;

		if IndicatorOn then
			MoveIndicator(DShow);
	end;

	if FCleared in Cell[Row, Col] then
	begin
		PlaySound(SInvalid);
		exit;
	end;

	{If first move, make sure there isn't a mine under or immediately next to cursor
	 and start timer}
	if GameState = GNew then
	begin
		HelpFirstMove(Row, Col);

		GameState := GPlaying;
		StartTime := Timer;
	end;

	case MouseButton of
		MbLeft:
		begin
			{Clicked a FFlagged cell}
			if FFlagged in Cell[Row, Col]  then
			begin
				PlaySound(SInvalid);
				exit;
			end;

			{Clicked a FMined field}
			if FMined in Cell[Row, Col] then
			begin
				Mouse.Hide;
				for Row := 0 to Rows - 1 do
				begin
					for Col := 0 to Cols - 1 do
					begin
						if FMined in Cell[Row, Col] then
						begin
							Include(Cell[Row, Col], FExploded);
							DrawCell(Row, Col);
						end;
					end;
				end;
				Mouse.Show;
				PlaySound(SLoose);
				GameState := GLost;
				exit;
			end;

			{If we reach this point, clear the field and adjacent empty fields}
			Mouse.Hide;
			ClearCell(Row, Col);
			Mouse.Hide;

			{Check for win condition}
			if Cleared = (Rows * Cols) - Mines then
				WinGame
			else
				PlaySound(SClear);
			Mouse.Show;

		end;
			
		MbRight:
		begin
			{If right-clicked a cell, flag it if it isn't already}
			if not (FFlagged in Cell[Row, Col]) then
			begin
				Include(Cell[Row, Col], FFlagged);
				Inc(Flagged);
			end
			else
			begin
				{If already FFlagged, unflag it}
				Exclude(Cell[Row, Col], FFlagged);
				Dec(Flagged);
			end;
			Mouse.Hide;
			DrawCell(Row, Col);
			Mouse.Show;
			PlaySound(SFlag);
		end;
	end;
																			
end;

procedure TMinefield.HelpFirstMove(Row, Col: byte);
var
	R, C, MinesMoved, MinesPlaced: byte;
begin
	{Called on first click in field. Checks clicked and all adjacent cells, and
	 moves any mines away from them to prevent loosing right away.}
	MinesMoved := 0;
	MinesPlaced := 0;
	repeat
		if MinesMoved <> 0 then
		begin
			{Mines were moved, randomly place them elsewhere}
			Randomize;
			repeat
				R := Random(Rows);
				C := Random(Cols);
				if not (FMined in Cell[R, C]) then
				begin
					Include(Cell[R, C], FMined);
					Inc(MinesPlaced);
				end;
			until MinesPlaced = MinesMoved;
			MinesPlaced := 0;
			MinesMoved := 0;
		end;

		for R := Row - 1 to Row + 1 do
		begin
			for C := Col - 1 to Col + 1 do
			begin
				if (R >= 0) and (C >= 0) and
				   (R < Rows) and (C < Cols) then
				begin
					if FMined in Cell[R, C] then
					begin
						Exclude(Cell[R, C], FMined);
						Inc(MinesMoved);
					end;
				end;
			end;
		end;

	until MinesMoved = 0;
end;

procedure TMinefield.SetFieldSize(Size: TMinefieldSize);
var
	PixelW, PixelH: integer;
begin
	case Size of
		SSmall:
			begin
				Rows := 9;
				Cols := 9;
				Mines := 10;
			end;
		SMedium:
			begin
				Rows := 16;
				Cols := 16;
				Mines := 40;
			end;
		SLarge:
			begin
				Rows := 18;
				Cols := 22;
				Mines := 67;
			end;
		SUltra:
			begin
				Rows := 18;
				Cols := 39;
				Mines := 133;
			end;
	end;

	PixelW := Cols * CellSize;
	PixelH := Rows * CellSize;
	
	{Set size of minefield object on screen as well, and center it on parent}
	SetSize(PixelW, PixelH);
	Center(OrBoth);
end;

procedure TMinefield.PlaySound(SoundType: TSound);
var
	i: integer;
begin
	if not SoundOn then
		exit;

	case SoundType of
		SNew:
			begin
				SoundNote(65, 180);
				SoundNote(65, 180);
				SoundNote(82, 180);
			end;
		SWin:
			begin
				SoundNote(65, 600);
				SoundNote(73, 600);
				SoundNote(98, 300);
				SoundNote(82, 150);
			end;
		SFlag:
			begin
				SoundNote(800, 30);
				SoundNote(400, 30);
			end;
		SLoose:
			for i := 0 to 8 do
			begin
				SoundNote(37, 15);
				SoundNote(50, 15);
				SoundNote(37, 5);
				SoundNote(65, 10);
			end;
		SClear:
				SoundNote(400, 30);
		SInvalid:
				SoundNote(100, 70);
	end;

end;

end.