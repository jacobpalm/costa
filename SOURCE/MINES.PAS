program Minesweeper;

uses
	CostaLib, Graph, Crt;

const
	AppName           = 'Minesweeper';
	AppVersion        = '2.0';
	AppAuthor         = 'Jacob Palm';
	AppIcon           = 'MINE';

	CellSize          = 16; {Size of each clickable field}

	CAP_NEW_GAME      = #127 + 'New game';
	CAP_PAUSE         = #127 + 'Pause';
	CAP_SIZE          = 'Si' + #127 + 'ze...';
	CAP_SOUND         = #127 + 'Sound';
	CAP_ABOUT         = #127 + 'About...';
	CAP_EXIT          = 'E' + #127 + 'xit';
	CAP_RESUME        = #127 + 'Resume';
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
type
	TSound     = (SoundNew, SoundIllegalMove, SoundWin, SoundLoose, SoundClear, SoundFlag);
	TDirection = (DirHide, DirShow, DirUp, DirDown, DirLeft, DirRight);
	TFlag      = (Mined, Flagged, Cleared, Exploded, Selected);
	TFlagSet   = set of TFlag;

var
	Field: array[0..17, 0..38] of TFlagSet;
	FieldW, FieldH: byte; {Actual field size, within limits of Field array}
	MineCount, ClearedCount, FlaggedCount: integer;
	StartTime: real;
	EnableSound: boolean;
	GameOver: boolean;
	IndicatorRow, IndicatorCol: byte; {Keyboard indicator position}
	IndicatorOn: boolean;

	AreaField: TArea;
	BtnNew, BtnSize, BtnSound, BtnPause, BtnAbout, BtnExit: TButton;
	MouseButton: TMouseButton;

function  GetNeighborCount(Row, Col: byte): byte; forward;
function  SetFieldSize: boolean; forward;
procedure ClearCell(Row, Col: byte); forward;
procedure ClickCell(Row, Col: byte; MouseButton: TMouseButton); forward;
procedure DrawCell(Row, Col: byte); forward;
procedure DrawField; forward;
procedure HelpFirstMove(Row, Col: byte); forward;
procedure NewGame; forward;
procedure Pause; forward;
procedure PlaySound(SoundType: TSound); forward;
procedure PrintStatus(MineCountOnly: Boolean; StatusMessage: string); forward;
procedure PrintTime; forward;
procedure RevealMines; forward;
procedure WinGame; forward;

procedure ClearCell(Row, Col: byte);
type
	PNode = ^TNode;
	TNode = record
		Row, Col: byte;
		Next: PNode;
	end;
var
	Stack: PNode;
	NeighborRow, NeighborCol: byte;

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
		if Stack = nil then
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
		{Skip already cleared, or flagged, fields}
		if (Cleared in Field[Row, Col]) or (Flagged in Field[Row, Col]) then
			continue;

		{Add cleared flag, redraw cell and increment cleared cells count}
		Include(Field[Row, Col], Cleared);
		DrawCell(Row, Col);
		Inc(ClearedCount);
		
		{If current field has no mines around it, add its neighbors to the stack
		 for checking if they should be cleared as well}
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
					if (NeighborRow < 0) or (NeighborRow >= FieldH) or
					   (NeighborCol < 0) or (NeighborCol >= FieldW) then
						continue;
					
					if Field[NeighborRow, NeighborCol] = [] then
						Push(NeighborRow, NeighborCol);
				end;
			end;
		end;
	end;
end;

procedure ClickCell(Row, Col: byte; MouseButton: TMouseButton);
begin

	if Cleared in Field[Row, Col] then
	begin
		PlaySound(SoundIllegalMove);
		exit;
	end;

	if ClearedCount = 0 then
	begin
		StartTime := Timer;

		{If first move, make sure there are no mines where there was clicked}
		HelpFirstMove(Row, Col);
	end;

	case MouseButton of
		MbLeft:
		begin
			{Clicked a flagged cell}
			if Flagged in Field[Row, Col]  then
			begin
				PlaySound(SoundIllegalMove);
				exit;
			end;

			{Clicked a mined field}
			if Mined in Field[Row, Col] then
			begin
				MouseHide;
				for Row := 0 to FieldH - 1 do
				begin
					for Col := 0 to FieldW - 1 do
					begin
						if Mined in Field[Row, Col] then
						begin
							Include(Field[Row, Col], Exploded);
							DrawCell(Row, Col);
						end;
					end;
				end;
				MouseShow;
				PrintStatus(False, MSG_GAME_OVER);
				PlaySound(SoundLoose);
				GameOver := true;
				exit;
			end;

			{If we reach this point, clear the field and adjacent empty fields}
			MouseHide;
			ClearCell(Row, Col);
			MouseHide;
			if ClearedCount = (FieldH * FieldW) - MineCount then
				WinGame
			else
				PlaySound(SoundClear);
			MouseShow;
		end;
			
		MbRight:
		begin

			{If right-clicked a cell, flag it}
			if not (Flagged in Field[Row, Col]) then
			begin
				Include(Field[Row, Col], Flagged);
				Inc(FlaggedCount);
			end
			else
			begin
				{If already flagged, unflag}
				Exclude(Field[Row, Col], Flagged);
				Dec(FlaggedCount);
			end;
			MouseHide;
			DrawCell(Row, Col);
			PrintStatus(true, '');
			MouseShow;
			PlaySound(SoundFlag);
		end;
	end;
																			
end;

procedure DrawCell(Row, Col: byte);
var
	X1, Y1, X2, Y2: integer;
	TextColor, Neighbors: byte;
	NeighborStr: string;
begin
	
	X1 := AreaField.Left + 1 + Col * CellSize;
	Y1 := AreaField.Top + 1 + Row * CellSize;
	X2 := X1 + CellSize - 2;
	Y2 := Y1 + CellSize - 2;

	if Exploded in Field[Row, Col] then
	begin
		{Exploded field. Kaboom!}
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
	else if Flagged in Field[Row, Col] then
	begin
		{Flagged field}
		{Background}
		if Selected in Field[Row, Col] then
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
	else if Cleared in Field[Row, Col] then
	begin
		{Cleared field}
		SetFillStyle(SolidFill, LightGray);
		Bar(X1, Y1, X2, Y2);

		{Draw keyboard indicator if selected}
		if Selected in Field[Row, Col] then
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
	else if Selected in Field[Row, Col] then
	begin
		{Uncleared, not flagged, not exploded, but selected with keyboard}
		SetFillStyle(SolidFill, White);
		Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
	end
	else
	begin
		{Not cleared, flagged, exploded or selected - meaning flag must have been
		 removed.}

		{Clear button face}
		SetFillStyle(SolidFill, LightGray);
		Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
	end;

end;

procedure DrawField;
var
	FieldRow, FieldCol: byte;
	X1, Y1, X2, Y2: integer;
begin
	AreaField.Init(SizeCenter, 0, FieldW * CellSize, FieldH * CellSize);
	AreaField.Top := 180 - (AreaField.Height div 2);

	X1 := AreaField.Left;
	Y1 := AreaField.Top;
	X2 := AreaField.Left + AreaField.Width;
	Y2 := AreaField.Top + AreaField.Height;

	MouseHide;
	SetFillStyle(SolidFill, Thm.Win);
	Bar(0, 29, 639, 349);

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
	for FieldCol := 1 to FieldW - 1 do
	begin
		SetColor(White);
		Line(X1 + FieldCol * CellSize + 1, Y1, X1 + FieldCol * CellSize + 1, Y1 + FieldH * CellSize);
		SetColor(DarkGray);
		Line(X1 + FieldCol * CellSize - 1, Y1 + 1, X1 + FieldCol * CellSize - 1, Y1 + FieldH * CellSize);
	end;
	for FieldRow := 1 to FieldH - 1 do
	begin
		SetColor(White);
		Line(X1, Y1 + FieldRow * CellSize + 1, X1 + FieldW * CellSize, Y1 + FieldRow * CellSize + 1);
		SetColor(DarkGray);
		Line(X1 + 1, Y1 + FieldRow * CellSize - 1, X1 + FieldW * CellSize, Y1 + FieldRow * CellSize - 1);
	end;

	{Button borders}
	SetColor(Black);
	for FieldCol := 1 to FieldW - 1 do
		Line(X1 + FieldCol * CellSize, Y1, X1 + FieldCol * CellSize, Y1 + FieldH * CellSize);
	for FieldRow := 1 to FieldH - 1 do
		Line(X1, Y1 + FieldRow * CellSize, X1 + FieldW * CellSize, Y1 + FieldRow * CellSize);

	{Borders around playfield}
	Rectangle(X1, Y1, X2, Y2);
	
	MouseShow;

end;

function GetNeighborCount(Row, Col: byte): byte;
var
	Neighbors: byte;
	CheckRow, CheckCol: byte;
begin
	Neighbors := 0;
	for CheckRow := Row - 1 to Row + 1 do
	begin
		for CheckCol := Col - 1 to Col + 1 do
		begin

			if (CheckRow >= 0) and (CheckCol >= 0) and
			   (CheckRow < FieldH) and (CheckCol < FieldW) then
			begin
				if Mined in Field[CheckRow, CheckCol] then
					Inc(Neighbors);
			end;

		end;
	end;

	GetNeighborCount := Neighbors;
end;

procedure HelpFirstMove(Row, Col: byte);
var
	CheckRow, CheckCol, MinesMoved, MinePlace: byte;
begin
	{Called on first click in field. Checks clicked and all adjacent cells, and
	 moves any mines away from them to prevent loosing right away.}
	MinesMoved := 0;
	MinePlace := 0;
	repeat
		if MinesMoved <> 0 then
		begin
			{Mines were moved, randomly place them elsewhere}
			Randomize;
			repeat
				CheckRow := Random(FieldH);
				CheckCol := Random(FieldW);
				if not (Mined in Field[CheckRow, CheckCol]) then
				begin
					Include(Field[CheckRow, CheckCol], Mined);
					Inc(MinePlace);
				end;
			until MinePlace = MinesMoved;
			MinePlace := 0;
			MinesMoved := 0;
		end;

		for CheckRow := Row - 1 to Row + 1 do
		begin
			for CheckCol := Col - 1 to Col + 1 do
			begin
				if (CheckRow >= 0) and (CheckCol >= 0) and
				   (CheckRow < FieldH) and (CheckCol < FieldW) then
				begin
					if Mined in Field[CheckRow, CheckCol] then
					begin
						Exclude(Field[CheckRow, CheckCol], Mined);
						Inc(MinesMoved);
					end;
				end;
			end;
		end;

	until MinesMoved = 0;

end;

procedure NewGame;
var
	FieldRow, FieldCol, MinePlace: byte;
begin
	{Clear mine array}	
	FillChar(Field, SizeOf(Field), 0);

	case FieldW of
		9: MineCount := 10;   {0.12% of 9x9,    81}
		16: MineCount := 40;  {0.15% of 16x16, 240}
		22: MineCount := 67;  {0.17% of 18x22, 396}
		39: MineCount := 133; {0.19% of 18x39, 702}
	end;

	Randomize;
	MinePlace := 0;
	repeat
		FieldRow := Random(FieldH);
		FieldCol := Random(FieldW);
		if not (Mined in Field[FieldRow, FieldCol]) then
		begin
			Include(Field[FieldRow, FieldCol], Mined);
			Inc(MinePlace);
		end;
	until MinePlace = MineCount;

	DrawField;
	PlaySound(SoundNew);
	GameOver := false;
	ClearedCount := 0;
	FlaggedCount := 0;
	StartTime := 0;
	IndicatorRow := FieldH div 2;
	IndicatorCol := FieldW div 2;
	
	PrintStatus(False, '');
end;

procedure Pause;
var
	BtnResume: TButton;
	Row, Col: byte;
	PauseTime: real;
	Key: string;
begin
	PauseTime := Timer;
	
	BtnResume.Init(3, 2, SizeDefault, SizeDefault, CAP_RESUME);

	MouseHide;
	SetFillStyle(SolidFill, Thm.Win);
	Bar(0, 29, 639, 329);
	MenuBar.Draw;
	BtnResume.Draw;
	BtnExit.Draw;
	MouseShow;

	repeat
		Key := GetKey;

		if (Key = KeySpace) or (Key = KeyEnter) or (Key = KeyEscape) then
			break;

		if BtnResume.Clicked or (Key = KeyAltR) then
			break;

		if BtnExit.Clicked then
		begin
			CloseGraph;
			Halt(0);
		end;
		
	until false;

	MouseHide;
	BtnNew.Draw;
	BtnSize.Draw;
	BtnSound.Draw;
	BtnPause.Draw;
	BtnAbout.Draw;
	DrawField;
	for Row := 0 to FieldH - 1 do
	begin
		for Col := 0 to FieldW - 1 do
		begin
			DrawCell(Row, Col);
		end;
	end;
	MouseShow;

	PrintStatus(False, '');
	if StartTime <> 0 then
		StartTime := StartTime + (Timer - PauseTime);
	PrintTime;

end;

procedure PlaySound(SoundType: TSound);
var
	i: integer;
begin

	if not EnableSound then
		exit;

	case SoundType of
		SoundNew:
			begin
				SoundNote(65, 180);
				SoundNote(65, 180);
				SoundNote(82, 180);
			end;
		SoundWin:
			begin
				SoundNote(65, 600);
				SoundNote(73, 600);
				SoundNote(98, 300);
				SoundNote(82, 150);
			end;
		SoundFlag:
			begin
				SoundNote(800, 30);
				SoundNote(400, 30);
			end;
		SoundLoose:
			for i := 0 to 8 do
			begin
				SoundNote(37, 15);
				SoundNote(50, 15);
				SoundNote(37, 5);
				SoundNote(65, 10);
			end;
		SoundClear:
				SoundNote(400, 30);
		SoundIllegalMove:
				SoundNote(100, 70);
	end;

end;

procedure PrintStatus(MineCountOnly: boolean; StatusMessage: string);
var
	MessageText: String;
	FlaggedStr, CountStr: string;
begin
	
	Str(FlaggedCount, FlaggedStr);
	Str(MineCount, CountStr);
	SetFillStyle(SolidFill, Thm.Win);

	{Only hide mouse if it's near the timer, to avoid cursor flicker on old PCs}
	MousePoll;
	if MouseY > 310 then
		MouseHide;
	
	if MineCountOnly then
	begin
		Bar(106, 330, 184, 343);
		MessageText := FlaggedStr + '/' + CountStr;
		Print(MessageText, 110, 332, Thm.WinText);
		MouseShow;
		exit;
	end;

	{Clear both sides of timer}
	Bar(6, 330, 277, 343);
	Bar(361, 330, 632, 343);

	if Length(StatusMessage) > 0 then
		MessageText := StatusMessage
	else
		MessageText := MSG_FLAGGED_COUNT + ' ' + FlaggedStr + '/' + CountStr;
	
	Print(MessageText, 8, 332, Thm.WinText);

	MessageText := MSG_SOUND + ' ';
	if EnableSound then
		MessageText := MessageText + MSG_ON
	else
		MessageText := MessageText + MSG_OFF;
	
	Print(MessageText, (630 - PrintW(MessageText)), 332, Thm.WinText);
	MouseShow;
end;

procedure PrintTime;
var
	MessageText: String;
	Hours, Minutes, Seconds: byte;
	TempStr: string;
begin
	{Only draw time if we are still playing}
	if GameOver or (StartTime = 0) then
		exit;

	{Only hide mouse if it's near the timer, to avoid cursor flicker on old PCs}
	MousePoll;
	if MouseY > 310 then
		MouseHide;

	{Clear timer only}
	SetFillStyle(SolidFill, Thm.Win);
	Bar(278, 330, 360, 343);

	if StartTime <> 0 then
	begin
		Seconds := Trunc(Timer - StartTime);
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
	end;

	MouseShow;
end;

procedure RevealMines;
var
	X1, Y1, X2, Y2: integer;
	Row, Col: byte;
begin

	SetColor(Red);
	MouseHide;
	for Row := 0 to FieldH - 1 do
	begin
		for Col := 0 to FieldW - 1 do
		begin
			if Mined in Field[Row, Col] then
			begin
				X1 := AreaField.Left + 1 + Col * CellSize;
				Y1 := AreaField.Top + 1 + Row * CellSize;
				X2 := X1 + CellSize - 2;
				Y2 := Y1 + CellSize - 2;
				Rectangle(X1, Y1, X2, Y2);
			end;
		end;
	end;
	MouseShow;
						
end;

function SetFieldSize: boolean;
var
	WinSetSize: TWindow;
	BtnSize: array[0..3] of TButton;
	BtnCancel: TButton;
	X, Y, TextOffset: integer;
	X1, Y1, X2, Y2: integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Key: string;
begin
	WinSetSize.Init(SizeCenter, SizeCenter, 236, 264);
	
	BtnSize[0].Init(WinSetSize.Left + 13, WinSetSize.Top + 11, 100, 100, '');
	BtnSize[1].Init(BtnSize[0].Left + 110, WinSetSize.Top + 11, 100, 100, '');
	BtnSize[2].Init(WinSetSize.Left + 13, BtnSize[0].Top + 110, 100, 100, '');
	BtnSize[3].Init(BtnSize[2].Left + 110, BtnSize[2].Top, 100, 100, '');
	BtnCancel.Init(WinSetSize.Left + 13, BtnSize[2].Top + 110, 210, SizeDefault, CAP_CANCEL);

	BtnSize[0].Transparent := True;
	BtnSize[1].Transparent := True;
	BtnSize[2].Transparent := True;
	BtnSize[3].Transparent := True;

	MouseHide;
	{Save background to restore when window is closed}
	X1 := WinSetSize.Left;
	Y1 := WinSetSize.Top;
	X2 := WinSetSize.Left + WinSetSize.Width;
	Y2 := WinSetSize.Top + WinSetSize.Height;
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);

	WinSetSize.Draw;
	BtnSize[0].Draw;
	BtnSize[1].Draw;
	BtnSize[2].Draw;
	BtnSize[3].Draw;
	BtnCancel.Draw;

	TextOffset := ((BtnSize[0].Width - PrintW(CAP_9X9)) div 2);
	Print(CAP_9X9, BtnSize[0].Left + TextOffset, BtnSize[0].Top + 79, Thm.WinText);

	TextOffset := ((BtnSize[1].Width - PrintW(CAP_16X16)) div 2);
	Print(CAP_16X16, BtnSize[1].Left + TextOffset, BtnSize[1].Top + 79, Thm.WinText);

	TextOffset := ((BtnSize[2].Width - PrintW(CAP_22X18)) div 2);
	Print(CAP_22X18, BtnSize[2].Left + TextOffset, BtnSize[2].Top + 79, Thm.WinText);

	TextOffset := ((BtnSize[3].Width - PrintW(CAP_39X18)) div 2);
	Print(CAP_39X18, BtnSize[3].Left + TextOffset, BtnSize[3].Top + 79, Thm.WinText);
	
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
	
	MouseShow;

	SetFieldSize := true; {Only cancel button will set this to false}

	repeat
		Key := GetKey;

		if BtnCancel.Clicked or (Key = KeyEscape) or (Key = KeyAltC) then
		begin
			SetFieldSize := False;
			break;
		end;

		if BtnSize[0].Clicked or (Key = KeyAlt9) then
		begin
			FieldH := 9;
			FieldW := 9;
			break;
		end;

		if BtnSize[1].Clicked or (Key = KeyAlt1) then
		begin
			FieldH := 16;
			FieldW := 16;
			break;
		end;

		if BtnSize[2].Clicked or (Key = KeyAlt2) then
		begin
			FieldH := 18;
			FieldW := 22;
			break;
		end;

		if BtnSize[3].Clicked or (Key = KeyAlt3) then
		begin
			FieldH := 18;
			FieldW := 39;
			break;
		end;

	until false;

	MouseHide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;		
end;

procedure MoveIndicator(Direction: TDirection);
begin
	IndicatorOn := true;

	{Hide current indicator before moving}
	Exclude(Field[IndicatorRow, IndicatorCol], Selected);
	MouseHide;
	DrawCell(IndicatorRow, IndicatorCol);
	case Direction of
		DirUp:
			if IndicatorRow > 0 then
				Dec(IndicatorRow);
		DirDown:
			if IndicatorRow < FieldH - 1 then
				Inc(IndicatorRow);
		DirLeft:
			if IndicatorCol > 0 then
				Dec(IndicatorCol);
		DirRight:
			if IndicatorCol < FieldW - 1 then
				Inc(IndicatorCol);
		DirHide:
			begin
				MouseShow;
				exit;
			end;
	end;

	{Add new indicator and draw it}
	Include(Field[IndicatorRow, IndicatorCol], Selected);
	DrawCell(IndicatorRow, IndicatorCol);
	MouseShow;
end;

procedure WinGame;
var
	FieldRow, FieldCol: byte;
begin
	{Victory! Reveal mines, show status and end game}
	for FieldRow := 0 to FieldH - 1 do
	begin
		for FieldCol := 0 to FieldW - 1 do
		begin
			if Mined in Field[FieldRow, FieldCol] then
			begin
				if not (Flagged in Field[FieldRow, FieldCol]) then
				begin
					Include(Field[FieldRow, FieldCol], Flagged);
					DrawCell(FieldRow, FieldCol);
					Inc(FlaggedCount);
				end;
			end;
		end;
	end;
	PrintStatus(False, MSG_WIN);
	PlaySound(SoundWin);
	GameOver := True;
end;

var
	FieldRow, FieldCol: byte;
	TimeCompare: real;
	Key: string;
begin
	BtnNew.Init(3, 2, SizeDefault, SizeDefault, CAP_NEW_GAME);
	BtnPause.Init(102, 2, SizeDefault, SizeDefault, CAP_PAUSE);
	BtnSize.Init(201, 2, SizeDefault, SizeDefault, CAP_SIZE);
	BtnSound.Init(300, 2, SizeDefault, SizeDefault, CAP_SOUND);
	BtnAbout.Init(446, 2, SizeDefault, SizeDefault, CAP_ABOUT);
	BtnExit.Init(545, 2, SizeDefault, SizeDefault, CAP_EXIT);
	
	MouseHide;
	MenuBar.Draw;
	BtnNew.Draw;
	BtnSize.Draw;
	BtnSound.Draw;
	BtnPause.Draw;
	BtnAbout.Draw;
	BtnExit.Draw;
	MouseShow;

	{Default settings}
	EnableSound := True;
	FieldW := 16;
	FieldH := 16;

	NewGame;
	
	TimeCompare := Timer + 1;
	repeat
		Key := GetKey;
		
		if BtnNew.Clicked or (Key = KeyAltN) then
		begin
			NewGame;
			IndicatorOn := False;
		end;

		if BtnSound.Clicked or (Key = KeyAltS) then
		begin
			EnableSound := not EnableSound;
			PrintStatus(False, '');
		end;

		if BtnPause.Clicked or (Key = KeyAltP) then
			Pause;

		if BtnSize.Clicked or (Key = KeyAltZ) then
		begin
			if SetFieldSize then
				NewGame;
		end;

		if BtnExit.Clicked or (Key = KeyAltX) then
			break;

		if BtnAbout.Clicked or (Key = KeyAltA) then
			AboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if not GameOver then
		begin
			if Key = '?' then
				RevealMines;

			if (Key = KeyEnter) and IndicatorOn then
				ClickCell(IndicatorRow, IndicatorCol, MbLeft);

			if (Key = KeySpace) and IndicatorOn then
				ClickCell(IndicatorRow, IndicatorCol, MbRight);

			if ((Key = KeySpace) or (Key = KeyEnter)) and (IndicatorOn = false) then
			begin
				MoveIndicator(DirShow);
				ClearInputBuffer;
			end;

			If Key = KeyUp then
				MoveIndicator(DirUp);
			If Key = KeyDown then
				MoveIndicator(DirDown);
			If Key = KeyLeft then
				MoveIndicator(DirLeft);
			If Key = KeyRight then
				MoveIndicator(DirRight);
			
			if (StartTime <> 0) and (TimeCompare < Timer) then
			begin
				{DEBUG - doesn't update correctly}
				PrintTime;
				TimeCompare := Timer + 1;
			end;
		
			if (MouseClicked <> MbNone) and AreaField.IsMouseOver then
			begin
				MouseButton := MouseClicked;
				MousePoll;
			
				{Calculate which cell was clicked}
				FieldCol := (MouseX - AreaField.Left) div CellSize;
				FieldRow := (MouseY - AreaField.Top) div CellSize;

				{Play field is one pixel too wide for calculation above, dirty fix
				 for this to prevent out of bounds clicks}
				if FieldCol = FieldW then
					Dec(FieldCol);
				if FieldRow = FieldH then
					Dec(FieldRow);
			
				if IndicatorOn then
					MoveIndicator(DirHide);
				
				ClickCell(FieldRow, FieldCol, MouseButton);

				IndicatorRow := FieldRow;
				IndicatorCol := FieldCol;
				{Prevent sound from running wild if mouse/key is held down}
				ClearInputBuffer;

			end;

		end;

	until false;
	CloseGraph;

end.