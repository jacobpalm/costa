program Minesweeper;

uses
	CostaLib, Graph, Crt;

const
	AppName           = 'Minesweeper';
	AppVersion        = '2.0';
	AppAuthor         = 'Jacob Palm';
	AppIcon           = 'MINE';

	FieldMined        = 1;
	FieldFlagged      = 2;
	FieldCleared      = 4;
	FieldNumbered     = 8;
	FieldExploded     = 16;
	FieldMasked       = 32;
	FieldKBSelected   = 64;

	CellSize          = 16; {Size of each clickable field}

	CAP_NEW_GAME      = #127 + 'New game';
	CAP_PAUSE         = #127 + 'Pause';
	CAP_SIZE          = 'Si' + #127 + 'ze';
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

var
	EnableAudio: boolean;
	GameOver: boolean;
	MineCount: integer;
	FieldW, FieldH: integer;
	AreaField: TArea;
	StartTime, TimeCompare: real;
	CellsCleared, CellsFlagged: integer;
	KeyRow, KeyCol: integer;
	MineField: array[0..17, 0..38] of integer;

	BtnNew, BtnSize, BtnAudio, BtnPause, BtnAbout, BtnExit: TButton;
	FieldRow, FieldCol: integer;
	MouseButton: TMouseButton;
	KeyVisible: boolean;
	Key: string;

function  GetNeighborCount(Row, Col: integer): integer; forward;
function  SetFieldSize: boolean; forward;
procedure ClearNeighbors(Row, Col: integer); forward;
procedure ClickCell(Row, Col: integer; MouseButton: TMouseButton); forward;
procedure DrawCell(Row, Col: integer); forward;
procedure DrawField; forward;
procedure HelpFirstMove(Row, Col: integer); forward;
procedure NewGame; forward;
procedure Pause; forward;
procedure PlaySound(SoundType: TSound); forward;
procedure PrintStatus(MineCountOnly: Boolean; StatusMessage: string); forward;
procedure PrintTime; forward;
procedure RevealMines; forward;
procedure WinGame; forward;

procedure ClearNeighbors(Row, Col: integer);
var
	CheckRow, CheckCol: integer;
	NeighborsCleared: boolean;

	function MaskNeighbors(Row, Col: integer): boolean;
	var
		NeighborRow, NeighborCol: integer;
	begin
		MaskNeighbors := false;
		{Check all neighbors}
		for NeighborRow := Row - 1 TO Row + 1 do
		begin
			for NeighborCol := Col - 1 TO Col + 1 do
			begin
				{Prevent 'out of bounds' errors}
				if (NeighborRow >= 0) and (NeighborCol >= 0) and
				   (NeighborRow < FieldH) and (NeighborCol < FieldW) then
				begin
					if MineField[NeighborRow, NeighborCol] = 0 then
					begin
						{If neighbor is empty, clear it}
						MineField[NeighborRow, NeighborCol] := MineField[NeighborRow, NeighborCol] xor FieldCleared;
						DrawCell(NeighborRow, NeighborCol);
						MaskNeighbors := true;
						Inc(CellsCleared);

						{If cleared field has no neighbours itself, mask if for next iteration}
						if GetNeighborCount(NeighborRow, NeighborCol) = 0 then
							MineField[NeighborRow, NeighborCol] := MineField[NeighborRow, NeighborCol] xor FieldMasked;
					end;
				end;
			end;
		end;
	end;

begin
	{If the cell has neighbors, an empty space was not clicked and thus nothing
	 should be cleared around it}
	if GetNeighborCount(Row, Col) <> 0 then
		exit;

	MouseHide;
	{Set the current pos in the mask as cleared, then start a loop that checks
	 all neighbors to cleared cells. Empty cells are cleared as well and marked
	 in the mask, to be checked on next iteration. Repeat until no cells are
	 cleared}
	MineField[Row, Col] := MineField[Row, Col] XOR FieldMasked;
	repeat
		NeighborsCleared := false;
		for CheckRow := 0 to FieldH - 1 do
		begin
			for CheckCol := 0 to FieldW - 1 do
			begin
				if (MineField[CheckRow, CheckCol] and FieldMasked) <> 0 then
				begin
					{Remove from mask to avoid redundant checks}
					MineField[CheckRow, CheckCol] := MineField[CheckRow, CheckCol] and not FieldMasked;

					{Clear only if has no neighbors}
					if GetNeighborCount(CheckRow, CheckCol) = 0 then
						if MaskNeighbors(CheckRow, CheckCol) then
							NeighborsCleared := true;			
				end;
			end;
		end;
	until NeighborsCleared = false;
	MouseShow;
end;

procedure ClickCell(Row, Col: integer; MouseButton: TMouseButton);
begin

	if (MineField[Row, Col] and FieldCleared) <> 0 then
	begin
		PlaySound(SoundIllegalMove);
		exit;
	end;

	if CellsCleared = 0 then
	begin
		StartTime := Timer;

		{If first move, make sure there are no mines where there was clicked}
		HelpFirstMove(Row, Col);
	end;

	case MouseButton of
		MbLeft:
		begin
			{Clicked a flagged cell}
			if (MineField[Row, Col] and FieldFlagged) <> 0 then
			begin
				PlaySound(SoundIllegalMove);
				exit;
			end;

			{Clicked a mined field}
			if (MineField[Row, Col] and FieldMined) <> 0 then
			begin
				MouseHide;
				for Row := 0 to FieldH - 1 do
				begin
					for Col := 0 to FieldW - 1 do
					begin
						if (MineField[Row, Col] and FieldMined) <> 0 then
						begin
							MineField[Row, Col] := MineField[Row, Col] or FieldExploded;
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
			MineField[Row, Col] := MineField[Row, Col] or FieldCleared;
			Inc(CellsCleared);
			DrawCell(Row, Col);
			if CellsCleared = (FieldH * FieldW) - MineCount then
			begin
				WinGame;
				MouseShow;
			end
			else
			begin
				PlaySound(SoundClear);
				ClearNeighbors(Row, Col);
				if CellsCleared = (FieldH * FieldW) - MineCount then
					WinGame;
			end;
			MouseShow;
		end;
			
		MbRight:
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
			DrawCell(Row, Col);
			PrintStatus(true, '');
			MouseShow;
			PlaySound(SoundFlag);
		end;
	end;
																			
end;

procedure DrawCell(Row, Col: integer);
var
	X1, Y1, X2, Y2: integer;
	TextColor, Neighbors: integer;
	NeighborStr: string;
begin
	
	X1 := AreaField.Left + 1 + Col * CellSize;
	Y1 := AreaField.Top + 1 + Row * CellSize;
	X2 := X1 + CellSize - 2;
	Y2 := Y1 + CellSize - 2;

	if (MineField[Row, Col] and FieldExploded) <> 0 then
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
	else if (MineField[Row, Col] and FieldFlagged) <> 0 then
	begin
		{Flagged field}
		{Background}
		if (MineField[Row, Col] and FieldKBSelected) <> 0 then
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
	else if (MineField[Row, Col] and FieldCleared) <> 0 then
	begin
		{Cleared field}
		SetFillStyle(SolidFill, LightGray);
		Bar(X1, Y1, X2, Y2);

		{Draw keyboard indicator if selected}
		if (MineField[Row, Col] and FieldKBSelected) <> 0 then
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
	else if (MineField[Row, Col] and FieldKBSelected) <> 0 then
	begin
		{Uncleared, not flagged, not exploded, but selected with keyboard}
		{Draw keyboard indicator if selected}
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
	FieldRow, FieldCol: integer;
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

function GetNeighborCount(Row, Col: integer): integer;
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
				if (CheckRow < FieldH) and (CheckCol < FieldW) then
				begin
					if (MineField[CheckRow, CheckCol] and FieldMined) <> 0 then
						Inc(Neighbors);
				end;
			end;

		end;
	end;

	GetNeighborCount := Neighbors;
end;

procedure HelpFirstMove(Row, Col: integer);
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
				CheckRow := Random(FieldH);
				CheckCol := Random(FieldW);
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
					if (CheckRow < FieldH) and (CheckCol < FieldW) then
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

procedure NewGame;
var
	FieldRow, FieldCol, MinePlace: integer;
begin
	{Clear mine array}	
	FillChar(MineField, SizeOf(MineField), 0);

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
		if (MineField[FieldRow, FieldCol] and FieldMined) = 0 then
		begin
			MineField[FieldRow, FieldCol] := FieldMined;
			Inc(MinePlace);
		end;
	until MinePlace = MineCount;

	DrawField;
	PlaySound(SoundNew);
	GameOver := false;
	CellsCleared := 0;
	CellsFlagged := 0;
	StartTime := 0;
	KeyRow := FieldH div 2;
	KeyCol := FieldW div 2;
	
	PrintStatus(False, '');
end;

procedure Pause;
var
	BtnResume, BtnExit: TButton;
	Row, Col: integer;
	PauseTime: real;
	Key: string;
begin
	PauseTime := Timer;
	
	BtnResume.Init(3, 2, SizeDefault, SizeDefault, CAP_RESUME);
	BtnExit.Init(545, 2, SizeDefault, SizeDefault, CAP_EXIT);

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

		if BtnClick(BtnResume) or (Key = KeyAltR) then
			break;

		if BtnClick(BtnExit) then
		begin
			CloseGraph;
			Halt(0);
		end;
		
	until false;

	MouseHide;
	MenuBar.Draw;
	BtnNew.Draw;
	BtnSize.Draw;
	BtnAudio.Draw;
	BtnPause.Draw;
	BtnAbout.Draw;
	BtnExit.Draw;
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

procedure PrintStatus(MineCountOnly: boolean; StatusMessage: string);
var
	MessageText: String;
	FlaggedStr, CountStr: string;
begin
	
	Str(CellsFlagged, FlaggedStr);
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
	if EnableAudio then
		MessageText := MessageText + MSG_ON
	else
		MessageText := MessageText + MSG_OFF;
	
	Print(MessageText, (630 - PrintW(MessageText)), 332, Thm.WinText);
	MouseShow;
end;

procedure PrintTime;
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
	Row, Col: integer;
begin

	SetColor(Red);
	MouseHide;
	for Row := 0 to FieldH - 1 do
	begin
		for Col := 0 to FieldW - 1 do
		begin
			if (MineField[Row, Col] and FieldMined) <> 0 then
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

		if BtnClick(BtnCancel) or (Key = KeyEscape) or (Key = KeyAltC) then
		begin
			SetFieldSize := False;
			break;
		end;

		if BtnClick(BtnSize[0]) or (Key = '9') then
		begin
			FieldH := 9;
			FieldW := 9;
			break;
		end;

		if BtnClick(BtnSize[1]) or (Key = '1') then
		begin
			FieldH := 16;
			FieldW := 16;
			break;
		end;

		if BtnClick(BtnSize[2]) or (Key = '2') then
		begin
			FieldH := 18;
			FieldW := 22;
			break;
		end;

		if BtnClick(BtnSize[3]) or (Key = '3') then
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

procedure MoveKBIndicator(Direction: TDirection);
begin
	KeyVisible := true;
	MineField[KeyRow, KeyCol] := MineField[KeyRow, KeyCol] and not FieldKBSelected;
	MouseHide;
	DrawCell(KeyRow, KeyCol);
	case Direction of
		DirUp:
			if KeyRow > 0 then
				Dec(KeyRow);
		DirDown:
			if KeyRow < FieldH - 1 then
				Inc(KeyRow);
		DirLeft:
			if KeyCol > 0 then
				Dec(KeyCol);
		DirRight:
			if KeyCol < FieldW - 1 then
				Inc(KeyCol);
		DirHide:
			begin
				MouseShow;
				exit;
			end;
	end;
	MineField[KeyRow, KeyCol] := MineField[KeyRow, KeyCol] xor FieldKBSelected;
	DrawCell(KeyRow, KeyCol);
	MouseShow;
end;

procedure WinGame;
var
	FieldRow, FieldCol: integer;
begin
	{Victory! Reveal mines, show status and end game}
	for FieldRow := 0 to FieldH - 1 do
	begin
		for FieldCol := 0 to FieldW - 1 do
		begin
			if (MineField[FieldRow, FieldCol] and FieldMined) <> 0 then
			begin
				if (MineField[FieldRow, FieldCol] and FieldFlagged) = 0 then
				begin
					MineField[FieldRow, FieldCol] := MineField[FieldRow, FieldCol] xor FieldFlagged;
					DrawCell(FieldRow, FieldCol);
					Inc(CellsFlagged);
				end;
			end;
		end;
	end;
	PrintStatus(False, MSG_WIN);
	PlaySound(SoundWin);
	GameOver := True;
end;


begin
	BtnNew.Init(3, 2, SizeDefault, SizeDefault, CAP_NEW_GAME);
	BtnPause.Init(102, 2, SizeDefault, SizeDefault, CAP_PAUSE);
	BtnSize.Init(201, 2, SizeDefault, SizeDefault, CAP_SIZE);
	BtnAudio.Init(300, 2, SizeDefault, SizeDefault, CAP_SOUND);
	BtnAbout.Init(446, 2, SizeDefault, SizeDefault, CAP_ABOUT);
	BtnExit.Init(545, 2, SizeDefault, SizeDefault, CAP_EXIT);
	
	MouseHide;
	MenuBar.Draw;
	BtnNew.Draw;
	BtnSize.Draw;
	BtnAudio.Draw;
	BtnPause.Draw;
	BtnAbout.Draw;
	BtnExit.Draw;
	MouseShow;

	{Default settings}
	EnableAudio := True;
	FieldW := 16;
	FieldH := 16;

	NewGame;
	
	TimeCompare := Timer + 1;
	repeat
		Key := GetKey;
		
		if BtnClick(BtnNew) or (Key = KeyAltN) then
		begin
			NewGame;
			KeyVisible := False;
		end;

		if BtnClick(BtnAudio) or (Key = KeyAltS) then
		begin
			EnableAudio := not EnableAudio;
			PrintStatus(False, '');
		end;

		if BtnClick(BtnPause) or (Key = KeyAltP) then
			Pause;

		if BtnClick(BtnSize) or (Key = KeyAltZ) then
		begin
			if SetFieldSize then
				NewGame;
		end;

		if BtnClick(BtnExit) or (Key = KeyAltX) then
			break;

		if BtnClick(BtnAbout) or (Key = KeyAltA) then
			AboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if not GameOver then
		begin
			if Key = '?' then
				RevealMines;

			if (Key = KeyEnter) and KeyVisible then
				ClickCell(KeyRow, KeyCol, MbLeft);

			if (Key = KeySpace) and KeyVisible then
				ClickCell(KeyRow, KeyCol, MbRight);

			if ((Key = KeySpace) or (Key = KeyEnter)) and (KeyVisible = false) then
			begin
				MoveKBIndicator(DirShow);
				ClearInputBuffer;
			end;

			If Key = KeyUp then
				MoveKBIndicator(DirUp);
			If Key = KeyDown then
				MoveKBIndicator(DirDown);
			If Key = KeyLeft then
				MoveKBIndicator(DirLeft);
			If Key = KeyRight then
				MoveKBIndicator(DirRight);
			
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
			
				if KeyVisible then
					MoveKBIndicator(DirHide);
				
				ClickCell(FieldRow, FieldCol, MouseButton);

				KeyRow := FieldRow;
				KeyCol := FieldCol;
				{Prevent audio from running wild if mouse/key is held down}
				ClearInputBuffer;

			end;

		end;

	until false;

	CloseGraph;

end.