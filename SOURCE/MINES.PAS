program Minesweeper;

uses
	CostaLib, Graph, Crt;

const
	AppName          = 'Minesweeper';
	AppVersion       = '2.0';
	AppAuthor        = 'Jacob Palm';
	AppIcon          = 'MINE';

	FieldMined       = 1;
	FieldFlagged     = 2;
	FieldCleared     = 4;
	FieldNumbered    = 8;
	FieldExploded    = 16;
	FieldMasked      = 32;
	FieldKBSelected  = 64;

	CellSize         = 16; {Size of each clickable field}

type
	TSound = (SoundNew, SoundIllegalMove, SoundWin, SoundLoose, SoundClear, SoundFlag);

var
	EnableAudio: boolean;
	GameOver: boolean;
	MineCount: integer;
	FieldWidth, FieldHeight: integer;
	posField: PosType;
	StartTime, TimeCompare: real;
	CellsCleared, CellsFlagged: integer;
	DebugMode: boolean;
	KeyRow, KeyCol: integer;
	MineField: array[0..17, 0..38] of integer;

	btnNew, btnSize, btnAudio, btnPause, btnAbout, btnExit: ButtonType;
	FieldRow, FieldCol: integer;
	MouseButton: TMouseButton;
	KeyVisible: boolean;
	Key: string;

function MineGetNeighbors(Row, Col: integer): integer; forward;
function MineSetSize: boolean; forward;
procedure MineClearNeighbors(Row, Col: integer); forward;
procedure MineClickCell(Row, Col: integer; MouseButton: TMouseButton); forward;
procedure MineDrawCell(Row, Col: integer); forward;
procedure MineDrawField; forward;
procedure MineHelpFirstMove(Row, Col: integer); forward;
procedure MineNewGame; forward;
procedure MinePause; forward;
procedure MinePlaySound(SoundType: TSound); forward;
procedure MinePrintStatus(MineCountOnly: Boolean; StatusMessage: string); forward;
procedure MinePrintTime; forward;
procedure MineReveal; forward;
procedure MineWin; forward;

procedure MineClearNeighbors(Row, Col: integer);
var
	CheckRow, CheckCol: integer;
	CheckNeighborRow, CheckNeighborCol: integer;
	NeighborsCleared: boolean;
begin
	{If the cell has neighbors, an empty space was not clicked and thus nothing
	 should be cleared around it}
	if MineGetNeighbors(Row, Col) <> 0 then
		exit;

	MouseHide;
	{Set the current pos in the mask as cleared, then start a loop that checks
	 all neighbors to cleared cells Empty cells are cleared as well and marked
	 in the mask, to be checked on end; loop. Repeat until no cells are cleared}
	MineField[Row, Col] := MineField[Row, Col] XOR FieldMasked;
	repeat
		NeighborsCleared := False;

		for CheckRow := 0 to FieldHeight - 1 do
		begin
			for CheckCol := 0 to FieldWidth - 1 do
			begin

				if (MineField[CheckRow, CheckCol] and FieldMasked) <> 0 then
				begin
					{Remove from mask to avoid redundant checks}
					MineField[CheckRow, CheckCol] := MineField[CheckRow, CheckCol] and not FieldMasked;

					{Clear only if has no neighbors}
					if MineGetNeighbors(CheckRow, CheckCol) = 0 then
					begin

						{Check all neighbors}
						for CheckNeighborRow := CheckRow - 1 TO CheckRow + 1 do
						begin
							for CheckNeighborCol := CheckCol - 1 TO CheckCol + 1 do
							begin

								{Prevent 'out of bounds' errors}
								if (CheckNeighborRow >= 0) and (CheckNeighborCol >= 0) then
								begin
									if (CheckNeighborRow < FieldHeight) and (CheckNeighborCol < FieldWidth) then
									begin
									
										if MineField[CheckNeighborRow, CheckNeighborCol] = 0 then
										begin
											{If neighbor is empty, clear it}
											MineField[CheckNeighborRow, CheckNeighborCol] := MineField[CheckNeighborRow, CheckNeighborCol] xor FieldCleared;
											MineDrawCell(CheckNeighborRow, CheckNeighborCol);
											NeighborsCleared := True;
											Inc(CellsCleared);

											{If cleared field has no neighbours, add it to the mask}
											if MineGetNeighbors(CheckNeighborRow, CheckNeighborCol) = 0 then
												MineField[CheckNeighborRow, CheckNeighborCol] := MineField[CheckNeighborRow, CheckNeighborCol] xor FieldMasked;
										end;
								
									end;
								end;

							end;
						end;

					end;
					
				end;

			end;
		end;

	until NeighborsCleared = false;
	MouseShow;
		
end;

procedure MineClickCell(Row, Col: integer; MouseButton: TMouseButton);
begin

	if (MineField[Row, Col] and FieldCleared) <> 0 then
	begin
		MinePlaySound(SoundIllegalMove);
		exit;
	end;

	if CellsCleared = 0 then
	begin
		StartTime := Timer;

		{If first move, make sure there are no mines where there was clicked}
		MineHelpFirstMove(Row, Col);
	end;

	case MouseButton of
		mbLeft:
		begin
			{Clicked a flagged cell}
			if (MineField[Row, Col] and FieldFlagged) <> 0 then
			begin
				MinePlaySound(SoundIllegalMove);
				exit;
			end;

			{Clicked a mined field}
			if (MineField[Row, Col] and FieldMined) <> 0 then
			begin
				MouseHide;
				for Row := 0 to FieldHeight - 1 do
				begin
					for Col := 0 to FieldWidth - 1 do
					begin
						if (MineField[Row, Col] and FieldMined) <> 0 then
						begin
							MineField[Row, Col] := MineField[Row, Col] or FieldExploded;
							MineDrawCell(Row, Col);
						end;
					end;
				end;
				MouseShow;
				MinePrintStatus(False, 'Kaboom! Game over.');
				MinePlaySound(SoundLoose);
				GameOver := true;
				exit;
			end;

			{If we reach this point, clear the field and adjacent empty fields}
			MouseHide;
			MineField[Row, Col] := MineField[Row, Col] or FieldCleared;
			Inc(CellsCleared);
			MineDrawCell(Row, Col);
			if CellsCleared = (FieldHeight * FieldWidth) - MineCount then
			begin
				MineWin;
				MouseShow;
			end
			else
			begin
				MinePlaySound(SoundClear);
				MineClearNeighbors(Row, Col);
				if CellsCleared = (FieldHeight * FieldWidth) - MineCount then
					MineWin;
			end;
			MouseShow;
		end;
			
		mbRight:
		begin

			{If right-clicked a cell, flag it}
			if (MineField[Row, Col] and FieldFlagged) = 0 then
			begin
				Inc(CellsFlagged);
				MineField[Row, Col] := MineField[Row, Col] or FieldFlagged;
			end
			else
			begin
				{If already flagged, unflag}
				Dec(CellsFlagged);
				MineField[Row, Col] := MineField[Row, Col] and not FieldFlagged;
			end;
			MouseHide;
			MineDrawCell(Row, Col);
			MinePrintStatus(true, '');
			MouseShow;
			MinePlaySound(SoundFlag);
		end;
	end;
																			
end;

procedure MineDrawCell(Row, Col: integer);
var
	x1, y1, x2, y2: integer;
	TextColor, Neighbors: integer;
	NeighborStr: string;
begin
	
	x1 := posField.Left + 1 + Col * CellSize;
	y1 := posField.Top + 1 + Row * CellSize;
	x2 := x1 + CellSize - 2;
	y2 := y1 + CellSize - 2;

	if (MineField[Row, Col] and FieldExploded) <> 0 then
	begin
		{Exploded field. Kaboom!}
		SetFillStyle(SolidFill,  Red);
		Bar(x1, y1, x2, y2);

		{Mine}
		SetFillStyle(SolidFill,  Black);
		Bar(x1 + 5, y1 + 3, x1 + 9, y1 + 11);
		Bar(x1 + 3, y1 + 5, x1 + 11, y1 + 9);
		PutPixel(x1 + 3, y1 + 3, Black);
		PutPixel(x1 + 3, y1 + 11, Black);
		PutPixel(x1 + 4, y1 + 4, Black);
		PutPixel(x1 + 4, y1 + 10, Black);
		PutPixel(x1 + 10, y1 + 10, Black);
		PutPixel(x1 + 11, y1 + 11, Black);
		PutPixel(x1 + 10, y1 + 4, Black);
		PutPixel(x1 + 11, y1 + 3, Black);
		SetColor(0);
		Line(x1 + 1, y1 + 7, x2 - 1, y1 + 7);
		Line(x1 + 7, y1 + 1, x1 + 7, y2 - 1);
		SetColor(White);
		Rectangle(x1 + 5, y1 + 5, x1 + 6, y1 + 6);
	end
	else if (MineField[Row, Col] and FieldFlagged) <> 0 then
	begin
		{Flagged field}
		{Background}
		if (MineField[Row, Col] and FieldKBSelected) <> 0 then
		begin
			SetFillStyle(SolidFill, White);
			Bar(x1 + 1, y1 + 1, x2 - 1, y2 - 1);
		end
		else
		begin
			SetFillStyle(SolidFill, LightGray);
			Bar(x1 + 1, y1 + 1, x2 - 1, y2 - 1);
		end;

		{Flag pole}
		SetColor(Black);
		Line(x1 + 6, y1 + 2, x1 + 6, y1 + 10);
		Line(x1 + 4, y1 + 11, x1 + 8, y1 + 11);
		Line(x1 + 3, y1 + 12, x1 + 9, y1 + 12);
		{Flag}
		SetColor(LightRed);
		Line(x1 + 7, y1 + 2, x1 + 7, y1 + 8);
		Line(x1 + 8, y1 + 3, x1 + 8, y1 + 7);
		Line(x1 + 9, y1 + 4, x1 + 9, y1 + 6);
		PutPixel(x1 + 10, y1 + 5, LightRed);
	end
	else if (MineField[Row, Col] and FieldCleared) <> 0 then
	begin
		{Cleared field}
		SetFillStyle(SolidFill, LightGray);
		Bar(x1, y1, x2, y2);

		{Draw keyboard indicator if selected}
		if (MineField[Row, Col] and FieldKBSelected) <> 0 then
		begin
			SetFillStyle(SolidFill, White);
			Bar(x1 + 1, y1 + 1, x2 - 1, y2 - 1);
		end;

		{Draw neighbor count, if any}
		Neighbors := MineGetNeighbors(Row, Col);
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
			FontPrint(NeighborStr, x1 + ((CellSize - FontGetWidth(NeighborStr, fontHeading)) div 2), y1 + 3, TextColor, fontHeading);
		end;
	end
	else if (MineField[Row, Col] and FieldKBSelected) <> 0 then
	begin
		{Uncleared, not flagged, not exploded, but selected with keyboard}
		{Draw keyboard indicator if selected}
		SetFillStyle(SolidFill, White);
		Bar(x1 + 1, y1 + 1, x2 - 1, y2 - 1);
	end
	else
	begin
		{Not cleared, flagged, exploded or selected - meaning flag must have been
		 removed.}

		{Clear button face}
		SetFillStyle(SolidFill, LightGray);
		Bar(x1 + 1, y1 + 1, x2 - 1, y2 - 1);
	end;

end;

procedure MineDrawField;
var
	FieldRow, FieldCol: integer;
	x1, y1, x2, y2: integer;
begin
	ObjSetSize(posField, SizeCenter, SizeRetain, FieldWidth * CellSize, FieldHeight * CellSize);
	posField.Top := 180 - (posField.Height div 2);

	x1 := posField.Left;
	y1 := posField.Top;
	x2 := posField.Left + posField.Width;
	y2 := posField.Top + posField.Height;

	MouseHide;
	SetFillStyle(SolidFill, Theme.Window);
	Bar(0, 29, 639, 349);

	{Button color}
	SetFillStyle(SolidFill, LightGray);
	Bar(x1, y1, x2, y2);

	{Button light and shadows for first row/column}
	SetColor(White);
	Line(x1 + 1, y1 + 1, x2, y1 + 1);
	Line(x1 + 1, y1 + 1, x1 + 1, y2);
	SetColor(DarkGray);
	Line(x1 + 2, y2 - 1, x2 - 1, y2 - 1);
	Line(x2 - 1, y1 + 2, x2 - 1, y2 - 1);

	{Button light and shadows}
	for FieldCol := 1 to FieldWidth - 1 do
	begin
		SetColor(White);
		Line(x1 + FieldCol * CellSize + 1, y1, x1 + FieldCol * CellSize + 1, y1 + FieldHeight * CellSize);
		SetColor(DarkGray);
		Line(x1 + FieldCol * CellSize - 1, y1 + 1, x1 + FieldCol * CellSize - 1, y1 + FieldHeight * CellSize);
	end;
	for FieldRow := 1 to FieldHeight - 1 do
	begin
		SetColor(White);
		Line(x1, y1 + FieldRow * CellSize + 1, x1 + FieldWidth * CellSize, y1 + FieldRow * CellSize + 1);
		SetColor(DarkGray);
		Line(x1 + 1, y1 + FieldRow * CellSize - 1, x1 + FieldWidth * CellSize, y1 + FieldRow * CellSize - 1);
	end;

	{Button borders}
	SetColor(Black);
	for FieldCol := 1 to FieldWidth - 1 do
		Line(x1 + FieldCol * CellSize, y1, x1 + FieldCol * CellSize, y1 + FieldHeight * CellSize);
	for FieldRow := 1 to FieldHeight - 1 do
		Line(x1, y1 + FieldRow * CellSize, x1 + FieldWidth * CellSize, y1 + FieldRow * CellSize);

	{Borders around playfield}
	Rectangle(x1, y1, x2, y2);
	
	MouseShow;

end;

function MineGetNeighbors(Row, Col: integer): integer;
var
	Neighbors: integer;
	CheckRow, CheckCol: integer;
begin
	Neighbors := 0;
	for CheckRow := Row - 1 to Row + 1 do
	begin
		for CheckCol := Col - 1 to Col + 1 do
		begin

			if (CheckRow >= 0) and (CheckCol >= 0) then
			begin
				if (CheckRow < FieldHeight) and (CheckCol < FieldWidth) then
				begin
					if (MineField[CheckRow, CheckCol] and FieldMined) <> 0 then
						Inc(Neighbors);
				end;
			end;

		end;
	end;

	MineGetNeighbors := Neighbors;
end;

procedure MineHelpFirstMove(Row, Col: integer);
var
	CheckRow, CheckCol, MinesMoved, MinePlace: integer;
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
				CheckRow := Random(FieldHeight);
				CheckCol := Random(FieldWidth);
				if (MineField[CheckRow, CheckCol] and FieldMined) = 0 then
				begin
					MineField[CheckRow, CheckCol] := FieldMined;
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
				if (CheckRow >= 0) and (CheckCol >= 0) then
				begin
					if (CheckRow < FieldHeight) and (CheckCol < FieldWidth) then
					begin
						if (MineField[CheckRow, CheckCol] and FieldMined) <> 0 then
						begin
							MineField[CheckRow, CheckCol] := 0;
							Inc(MinesMoved);
						end;
					end;
				end;
			end;
		end;

	until MinesMoved = 0;

end;

procedure MineNewGame;
var
	FieldRow, FieldCol, MinePlace: integer;
begin
	{Clear mine array}	
	FillChar(MineField, SizeOf(MineField), 0);

	case FieldWidth of
		9: MineCount := 10;   {0.12% of 9x9,    81}
		16: MineCount := 40;  {0.15% of 16x16, 240}
		22: MineCount := 67;  {0.17% of 18x22, 396}
		39: MineCount := 133; {0.19% of 18x39, 702}
	end;

	Randomize;
	MinePlace := 0;
	repeat
		FieldRow := Random(FieldHeight);
		FieldCol := Random(FieldWidth);
		if (MineField[FieldRow, FieldCol] and FieldMined) = 0 then
		begin
			MineField[FieldRow, FieldCol] := FieldMined;
			Inc(MinePlace);
		end;
	until MinePlace = MineCount;

	MineDrawField;
	MinePlaySound(SoundNew);
	GameOver := false;
	CellsCleared := 0;
	CellsFlagged := 0;
	StartTime := 0;
	KeyRow := FieldHeight div 2;
	KeyCol := FieldWidth div 2;
	
	MinePrintStatus(False, '');
end;

procedure MinePause;
var
	btnResume, btnExit: ButtonType;
	Row, Col: integer;
	PauseTime: real;
	Key: string;
begin
	PauseTime := Timer;
	
	btnResume.Init(3, 2, 92, 22, HotkeySymbol + 'Resume');
	btnExit.Init(545, 2, 92, 22, 'E' + HotkeySymbol + 'xit');

	MouseHide;
	{PCOPY 0, 1} {DEUG - save background}
	SetFillStyle(SolidFill, Theme.Window);
	Bar(0, 29, 639, 329);
	ObjDrawMenu;
	ObjDrawBtn(btnResume, False);
	ObjDrawBtn(btnExit, False);
	MouseShow;

	repeat
		Key := GetKey;

		if (Key = KeySpace) or (Key = KeyEnter) or (Key = KeyEscape) then
			break;

		if ObjBtnClick(btnResume) or (Key = 'r') then
			break;

		if ObjBtnClick(btnExit) then
		begin
			CloseGraph;
			Halt(0);
		end;
		
	until false;

	MouseHide;
	ObjDrawMenu;	
	ObjDrawBtn(btnNew, False);
	ObjDrawBtn(btnSize, False);
	ObjDrawBtn(btnAudio, False);
	ObjDrawBtn(btnPause, False);
	ObjDrawBtn(btnAbout, False);
	ObjDrawBtn(btnExit, False);
	MineDrawField;
	for Row := 0 to FieldHeight - 1 do
	begin
		for Col := 0 to FieldWidth - 1 do
		begin
			MineDrawCell(Row, Col);
		end;
	end;
	MouseShow;

	MinePrintStatus(False, '');
	if StartTime <> 0 then
		StartTime := StartTime + (Timer - PauseTime);
	MinePrintTime;

end;

procedure MinePlaySound(SoundType: TSound);
var
	i: integer;
begin

	if not EnableAudio then
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

procedure MinePrintStatus(MineCountOnly: boolean; StatusMessage: string);
var
	MessageText: String;
	FlaggedStr, CountStr: string;
begin
	
	Str(CellsFlagged, FlaggedStr);
	Str(MineCount, CountStr);
	SetFillStyle(SolidFill, Theme.Window);

	{Only hide mouse if it's near the timer, to avoid cursor flicker on old PCs}
	MousePoll;
	if MouseY > 310 then
		MouseHide;
	
	if MineCountOnly then
	begin
		
		Bar(106, 330, 184, 343);
		MessageText := FlaggedStr + '/' + CountStr;
		FontPrint(MessageText, 110, 332, Theme.WindowText, fontHeading);
		MouseShow;
		exit;
	end;

	{Clear both sides of timer}
	Bar(6, 330, 277, 343);
	Bar(361, 330, 632, 343);

	if Length(StatusMessage) > 0 then
		MessageText := StatusMessage
	else
		MessageText := 'Flagged mines: ' + FlaggedStr + '/' + CountStr;
	
	FontPrint(MessageText, 8, 332, Theme.WindowText, fontHeading);

	if EnableAudio then
		MessageText := 'Sound: On'
	else
		MessageText := 'Sound: Off';
	
	FontPrint(MessageText, (630 - FontGetWidth(MessageText, fontHeading)), 332, Theme.WindowText, fontHeading);
	
	MouseShow;

end;

procedure MinePrintTime;
var
	MessageText: String;
	Hours, Minutes, Seconds: integer;
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
	SetFillStyle(SolidFill, Theme.Window);
	Bar(278, 330, 360, 343);

	{DEBUG}
	{IF StartTime > INT(TIMER) then
		{If we cross midnight, start timer over to avoid weird times.
		{Ugly fix, might change later.
		StartTime = INT(TIMER)
	end;}

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

		FontPrint(MessageText, (640 - FontGetWidth(MessageText, fontHeading)) div 2, 332, Theme.WindowText, fontHeading);
	end;

	MouseShow;
end;

procedure MineReveal;
var
	x1, y1, x2, y2: integer;
	row, col: integer;
begin

	SetColor(Red);
	MouseHide;
	for Row := 0 to FieldHeight - 1 do
	begin
		for Col := 0 to FieldWidth - 1 do
		begin
			if (MineField[Row, Col] and FieldMined) <> 0 then
			begin
				x1 := posField.Left + 1 + Col * CellSize;
				y1 := posField.Top + 1 + Row * CellSize;
				x2 := x1 + CellSize - 2;
				y2 := y1 + CellSize - 2;
				Rectangle(x1, y1, x2, y2);
			end;
		end;
	end;
	MouseShow;
						
end;

function MineSetSize: boolean;
var
	winSetSize: WindowType;
	btnSize: array[0..3] of ButtonType;
	btnCancel: ButtonType;
	X, Y, TextOffset: integer;
	x1, y1, x2, y2: integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	TempStr: string;
	Key: string;
begin
	winSetSize.Init(SizeCenter, SizeCenter, 236, 264);
	
	btnSize[0].Init(winSetSize.Pos.Left + 13, winSetSize.Pos.Top + 11, 100, 100, '');
	btnSize[1].Init(btnSize[0].Pos.Left + 110, winSetSize.Pos.Top + 11, 100, 100, '');
	btnSize[2].Init(winSetSize.Pos.Left + 13, btnSize[0].Pos.Top + 110, 100, 100, '');
	btnSize[3].Init(btnSize[2].Pos.Left + 110, btnSize[2].Pos.Top, 100, 100, '');
	btnCancel.Init(winSetSize.Pos.Left + 13, btnSize[2].Pos.Top + 110, 210, 22, HotkeySymbol + 'Cancel');

	btnSize[0].Transparent := True;
	btnSize[1].Transparent := True;
	btnSize[2].Transparent := True;
	btnSize[3].Transparent := True;

	MouseHide;
	{Save background to restore when window is closed}
	x1 := winSetSize.Pos.Left;
	y1 := winSetSize.Pos.Top;
	x2 := winSetSize.Pos.Left + winSetSize.Pos.Width;
	y2 := winSetSize.Pos.Top + winSetSize.Pos.Height;
	BackgroundSize := ImageSize(x1, y1, x2, y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(x1, y1, x2, y2, BackgroundP^);

	ObjDrawWin(winSetSize);
	ObjDrawBtn(btnSize[0], False);
	ObjDrawBtn(btnSize[1], False);
	ObjDrawBtn(btnSize[2], False);
	ObjDrawBtn(btnSize[3], False);
	ObjDrawBtn(btnCancel, False);

	TempStr := '9x' + HotkeySymbol + '9';
	TextOffset := ((btnSize[0].Pos.Width - FontGetWidth(TempStr, fontHeading)) div 2);
	FontPrint(TempStr, btnSize[0].Pos.Left + TextOffset, btnSize[0].Pos.Top + 79, Theme.WindowText, fontHeading);
	
	TempStr := '16x1' + HotkeySymbol + '6';
	TextOffset := ((btnSize[1].Pos.Width - FontGetWidth(TempStr, fontHeading)) div 2);
	FontPrint(TempStr, btnSize[1].Pos.Left + TextOffset, btnSize[1].Pos.Top + 79, Theme.WindowText, fontHeading);

	TempStr := HotkeySymbol + '22x18';
	TextOffset := ((btnSize[2].Pos.Width - FontGetWidth(TempStr, fontHeading)) div 2);
	FontPrint(TempStr, btnSize[2].Pos.Left + TextOffset, btnSize[2].Pos.Top + 79, Theme.WindowText, fontHeading);

	TempStr := HotkeySymbol + '39x18';
	TextOffset := ((btnSize[3].Pos.Width - FontGetWidth(TempStr, fontHeading)) div 2);
	FontPrint(TempStr, btnSize[3].Pos.Left + TextOffset, btnSize[3].Pos.Top + 79, Theme.WindowText, fontHeading);
	
	SetColor(Theme.WindowText);
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

	MineSetSize := true; {Only cancel button will set this to false}

	repeat
		Key := GetKey;

		if ObjBtnClick(btnCancel) or (Key = KeyEscape) or (Key = 'c') then
		begin
			MineSetSize := False;
			break;
		end;

		if ObjBtnClick(btnSize[0]) or (Key = '9') then
		begin
			FieldHeight := 9;
			FieldWidth := 9;
			break;
		end;

		if ObjBtnClick(btnSize[1]) or (Key = '6') then
		begin
			FieldHeight := 16;
			FieldWidth := 16;
			break;
		end;

		if ObjBtnClick(btnSize[2]) or (Key = '2') then
		begin
			FieldHeight := 18;
			FieldWidth := 22;
			break;
		end;

		if ObjBtnClick(btnSize[3]) or (Key = '3') then
		begin
			FieldHeight := 18;
			FieldWidth := 39;
			break;
		end;

	until false;

	MouseHide;
	PutImage(x1, y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;		
end;

procedure MineWin;
var
	FieldRow, FieldCol: integer;
begin
	{Victory! Reveal mines, show status and end game}
	for FieldRow := 0 to FieldHeight - 1 do
	begin
		for FieldCol := 0 to FieldWidth - 1 do
		begin
			if (MineField[FieldRow, FieldCol] and FieldMined) <> 0 then
			begin
				if (MineField[FieldRow, FieldCol] and FieldFlagged) = 0 then
				begin
					MineField[FieldRow, FieldCol] := MineField[FieldRow, FieldCol] xor FieldFlagged;
					MineDrawCell(FieldRow, FieldCol);
					Inc(CellsFlagged);
				end;
			end;
		end;
	end;
	MinePrintStatus(False, 'Minefield cleared, good job!');
	MinePlaySound(SoundWin);
	GameOver := True;
end;


begin
	btnNew.Init(3, 2, 92, 22, HotkeySymbol + 'New game');
	btnPause.Init(102, 2, 92, 22, HotkeySymbol + 'Pause');
	btnSize.Init(201, 2, 92, 22, 'Si' + HotkeySymbol + 'ze');
	btnAudio.Init(300, 2, 92, 22, HotkeySymbol + 'Sound');
	btnAbout.Init(446, 2, 92, 22, HotkeySymbol + 'About...');
	btnExit.Init(545, 2, 92, 22, 'E' + HotkeySymbol + 'xit');
	
	MouseHide;
	ObjDrawMenu;
	
	ObjDrawBtn(btnNew, False);
	ObjDrawBtn(btnSize, False);
	ObjDrawBtn(btnAudio, False);
	ObjDrawBtn(btnPause, False);
	ObjDrawBtn(btnAbout, False);
	ObjDrawBtn(btnExit, False);
	MouseShow;

	{Default settings}
	EnableAudio := True;
	FieldWidth := 16;
	FieldHeight := 16;

	MineNewGame;
	
	TimeCompare := Timer + 1;
	repeat
		Key := GetKey;
		
		if ObjBtnClick(btnNew) or (Key = 'n') then
		begin
			MineNewGame;
			KeyVisible := False;
		end;

		if ObjBtnClick(btnAudio) or (Key = 's') then
		begin
			EnableAudio := not EnableAudio;
			MinePrintStatus(False, '');
		end;

		if ObjBtnClick(btnPause) or (Key = 'p') then
			MinePause;

		if ObjBtnClick(btnSize) or (Key = 'z') then
		begin
			if MineSetSize then
				MineNewGame;
		end;

		if ObjBtnClick(btnExit) or (Key = 'x') then
			break;

		if ObjBtnClick(btnAbout) or (Key = 'a') then
			SysAboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if not GameOver then
		begin
			if Key = '?' then
			begin
				DebugMode := true;
				MineReveal;
			end;

			if ((Key = KeySpace) or (Key = KeyEnter)) and (KeyVisible = false) then
			begin
				KeyVisible := True;
				MineField[KeyRow, KeyCol] := MineField[KeyRow, KeyCol] xor FieldKBSelected;
				MouseHide;
				MineDrawCell(KeyRow, KeyCol);
				MouseShow;
				Key := '';
				repeat
				until (Length(GetKey) = 0);
			end;

			if (Key = KeyEnter) and KeyVisible then
				MineClickCell(KeyRow, KeyCol, mbLeft);

			if (Key = KeySpace) and KeyVisible then
				MineClickCell(KeyRow, KeyCol, mbRight);
					
			{Up}
			if (Key = KeyUp) and (KeyRow > 0) then
			begin
				KeyVisible := true;
				MineField[KeyRow, KeyCol] := MineField[KeyRow, KeyCol] and not FieldKBSelected;
				MouseHide;
				MineDrawCell(KeyRow, KeyCol);
				Dec(KeyRow);
				MineField[KeyRow, KeyCol] := MineField[KeyRow, KeyCol] xor FieldKBSelected;
				MineDrawCell(KeyRow, KeyCol);
				MouseShow;
			end;

			{Down}
			if (Key = KeyDown) and (KeyRow < FieldHeight - 1) then
			begin
				KeyVisible := true;
				MineField[KeyRow, KeyCol] := MineField[KeyRow, KeyCol] and not FieldKBSelected;
				MouseHide;
				MineDrawCell(KeyRow, KeyCol);
				Inc(KeyRow);
				MineField[KeyRow, KeyCol] := MineField[KeyRow, KeyCol] xor FieldKBSelected;
				MineDrawCell(KeyRow, KeyCol);
				MouseShow;
			end;

			{Left}
			if (Key = KeyLeft) and (KeyCol > 0) then
			begin
				KeyVisible := true;
				MineField[KeyRow, KeyCol] := MineField[KeyRow, KeyCol] and not FieldKBSelected;
				MouseHide;
				MineDrawCell(KeyRow, KeyCol);
				Dec(KeyCol);
				MineField[KeyRow, KeyCol] := MineField[KeyRow, KeyCol] xor FieldKBSelected;
				MineDrawCell(KeyRow, KeyCol);
				MouseShow;
			end;

			{Right}
			if (Key = KeyRight) and (KeyCol < FieldWidth - 1) then
			begin
				KeyVisible := true;
				MineField[KeyRow, KeyCol] := MineField[KeyRow, KeyCol] and not FieldKBSelected;
				MouseHide;
				MineDrawCell(KeyRow, KeyCol);
				Inc(KeyCol);
				MineField[KeyRow, KeyCol] := MineField[KeyRow, KeyCol] xor FieldKBSelected;
				MineDrawCell(KeyRow, KeyCol);
				MouseShow;
			end;
			
			if (StartTime <> 0) and (TimeCompare < Timer) then
			begin
				MinePrintTime;
				TimeCompare := timer + 1;
			end;
		
			if (MouseClicked <> mbNone) and MouseInArea(posField) then
			begin
				MouseButton := MouseClicked;
				MousePoll;
			
				{Calculate which cell was clicked}
				FieldCol := (MouseX - posField.Left) div CellSize;
				FieldRow := (MouseY - posField.Top) div CellSize;

				{Play field is one pixel too wide for calculation above, dirty fix
				 for this to prevent out of bounds clicks}
				if FieldCol = FieldWidth then
					Dec(FieldCol);
				if FieldRow = FieldHeight then
					Dec(FieldRow);
			
				if KeyVisible then
				begin
					KeyVisible := false;
					MineField[KeyRow, KeyCol] := MineField[KeyRow, KeyCol] and not FieldKBSelected;
					MouseHide;
					MineDrawCell(KeyRow, KeyCol);
					MouseShow;
				end;
				MineClickCell(FieldRow, FieldCol, MouseButton);

				KeyRow := FieldRow;
				KeyCol := FieldCol;
				{Prevent audio from running wild if mouse/key is held down}
				repeat
				until (Length(GetKey) = 0) and (MouseClicked = mbNone);

			end;

		end;

	until false;

	CloseGraph;

end.