unit FileDlg;

interface

uses
	Costalib;

function FileSelect(DefaultPattern, StartPath: string; IconSelect: boolean): string;

{Only the FileSelect function is exported, the rest are internal}

implementation

uses
	DOS, Graph;

const
	FileList        = 0;
	DirList         = -1;
	MaxVisibleItems = 15;
	ListItemHeight  = 12;

	MaxNameLength   = 12; {8.3 filename including the dot}

	CAP_PATTERN     = #127 + 'Pattern';
	CAP_DRIVE       = 'D' + #127 + 'rive';
	CAP_FILES       = #127 + 'Files';
	CAP_DIRS        = #127 + 'Directories';
	CAP_SELECT      = #127 + 'Select';
	CAP_CANCEL      = #127 + 'Cancel';

type
	TDirection = (Up, Down, First, Last, PageUp, PageDown);

	PFileNode = ^TFileNode;
	TFileNode = record
		Name: string[MaxNameLength];
		Next: PFileNode;
	end;

var
	ListHead:      array[-1..0] of PFileNode;
	ListStartPos:  array[-1..0] of Integer;
	ListSelection: array[-1..0] of Integer;
	ListLength:    array[-1..0] of Integer;
	AreaList:      array[-1..0] of TArea;
	ActiveList:    Integer;

	PreviewShown:  boolean;
	ImgPreview:    TIcon;

	Path, Pattern: String;
	Drive:         String[1];

	ClickedDoubleTimer: Real;

procedure SetActiveList(TargetList: Integer); forward;

procedure AddToList(const ItemName: string; TargetList: Integer);
var
	NewNode, LastNode: PFileNode;
begin
	{Init new node}
	New(NewNode);
	NewNode^.Name := ItemName;
	NewNode^.Next := nil;

	if not Assigned(ListHead[TargetList]) then
	begin
		{First item in the list}
		ListHead[TargetList] := NewNode;
		ListLength[TargetList] := 1;
	end
	else
	begin
		{Find the last node in the list}
		LastNode := ListHead[TargetList];
		while Assigned(LastNode^.Next) do
			LastNode := LastNode^.Next;
		{Add new node at the end}
		LastNode^.Next := NewNode;

		Inc(ListLength[TargetList]);
	end;
end;

procedure ClearList(TargetList: Integer);
var
	NextNode: PFileNode;
begin
	while Assigned(ListHead[TargetList]) do
	begin
		NextNode := ListHead[TargetList]^.Next;
		Dispose(ListHead[TargetList]);
		ListHead[TargetList] := NextNode;
	end;
	ListLength[TargetList] := 0;
	ListStartPos[TargetList] := 1;
	ListSelection[TargetList] := 1;
end;

function GetListItemName(TargetList, Position: Integer): String;
var
    I: Integer;
	TargetNode: PFileNode;
begin
    TargetNode := ListHead[TargetList];
	if Position > 1 then
	begin
		for I := 1 to Position - 1 do
		begin
			if not Assigned(TargetNode) then
				break;
			
			TargetNode := TargetNode^.Next
		end;
	end;

	if Assigned(TargetNode) then
		GetListItemName := TargetNode^.Name
	else
		GetListItemName := '';
end;

procedure GetChildFiles(Path: String; FilePattern: String);
var
	FileInfo: SearchRec;
begin
	{Clear previous file list}
	ClearList(FileList);

	FindFirst(Path + '\' + FilePattern, Archive, FileInfo);
	while DosError = 0 do
	begin
		if (FileInfo.Attr and Directory) = 0 then
		begin
			{If CON is opened the program will crash}
			if FileInfo.Name <> 'CON' then
				AddToList(FileInfo.Name, FileList);
		end;
		FindNext(FileInfo);
	end;
end;

procedure GetChildDirs(Path: String);
var
	DirInfo: SearchRec;
begin
	{Clear previous directory list}
	ClearList(DirList);
	
	{Add '..' for parent directory if not at root}
	if Length(Path) > 3 then
		AddToList('..', DirList);
	
	FindFirst(Path + '\*.*', Directory, DirInfo);
	while DosError = 0 do
	begin
		if ((DirInfo.Attr and Directory) <> 0) and (DirInfo.Name <> '.') and (DirInfo.Name <> '..') then
			AddToList(DirInfo.Name, DirList);
		
		FindNext(DirInfo);
	end;
end;

procedure DrawList(TargetList: integer; HighLightActive, FullRedraw: Boolean);
var
	I, Counter: Integer;
	X1, Y1, X2, Y2, YOffset: Integer;
	FGColor, BGColor: Integer;
	ItemText: String;
begin
	X1 := AreaList[TargetList].Left + 2;
	Y1 := AreaList[TargetList].Top + 3;
	X2 := AreaList[TargetList].Left + AreaList[TargetList].Width - 2;
	Y2 := AreaList[TargetList].Top + 15;
	YOffset := ((ListSelection[TargetList] - ListStartPos[TargetList]) * ListItemHeight);
	Counter := 0;

	MouseHide;
	if FullRedraw then
	begin
		SetFillStyle(SolidFill, Thm.Txt);
		Bar(X1, Y1, X2, Y2 - 1 + ((MaxVisibleItems - 1) * ListItemHeight));
		
		if ListHead[TargetList] = nil then
			Exit; {Nothing to draw}

		if ListStartPos[TargetList] > ListLength[TargetList] then
			ListStartPos[TargetList] := 1; {Reset start position if it exceeds item count}


		{Draw items from the start position}
		for I := ListStartPos[TargetList] to ListStartPos[TargetList] + MaxVisibleItems - 1 do
		begin
			if I <= ListLength[TargetList] then
			begin
				{ItemText := ListItem^.Name;}
				ItemText := GetListItemName(TargetList, I);

				{Highlight active selected item}
				if (I = ListSelection[TargetList]) and (ActiveList = TargetList) then
				begin
					{Draw highlighted item}
					SetFillStyle(SolidFill, Thm.Sel);
					Bar(X1, Y1 + (Counter * ListItemHeight), X2, Y2 - 1 + (Counter * ListItemHeight));
					Print(ItemText, X1 + 3, Y1 + 2 + (Counter * ListItemHeight), Thm.SelText);
				end
				else
				begin
					{Draw normal item}
					Print(ItemText, X1 + 3, Y1 + 2 + (Counter * ListItemHeight), Thm.TxtText);
				end;

				Inc(Counter);
			end;
		end;
	end
	else
	begin
		{Not a full redraw, only draw the selected item}

		{Unless we're out of bounds}
		if (ListSelection[TargetList] > ListLength[TargetList]) or
		   (ListSelection[TargetList] < 1) then
		begin
			MouseShow;
			Exit;
		end;

		if HighLightActive and (ActiveList = TargetList) then
		begin
			FGColor := Thm.SelText;
			BGColor := Thm.Sel;
		end
		else
		begin
			FGColor := Thm.TxtText;
			BGColor := Thm.Txt;
		end;

		ItemText := GetListItemName(TargetList, ListSelection[TargetList]);
		if ItemText <> '' then
		begin
			SetFillStyle(SolidFill, BGColor);
			Bar(X1, Y1 + YOffset, X2, Y2 - 1 + YOffset);
			Print(ItemText, X1 + 3, Y1 + 2 + YOffset, FGColor);
		end;
	end;
	MouseShow;
end;

procedure DrawPreview;
var
	IconFile: String;
	FDir: DirStr;
	FName: NameStr;
	FExt: ExtStr;
begin
	if (Path = ProgramPath + 'ICONS') and (ListSelection[FileList] <> 0) then
	begin
		FSplit(GetListItemName(FileList, ListSelection[FileList]), FDir, FName, FExt);
		if (Length(FName) <> 0) and (FExt = '.BIN') then
		begin
			MouseHide;
			ImgPreview.IconFile := FName;
			ImgPreview.Draw;
			MouseShow;
			PreviewShown := true;
			exit;
		end;
	end;
	
	{Either there is no selection, or the preview should be hidden}
	if (PreviewShown) or (ListSelection[FileList] <> 0) then
	begin
		MouseHide;
		SetFillStyle(SolidFill, Thm.Win);
		Bar(ImgPreview.Left - 1, ImgPreview.Top - 1, ImgPreview.Left + 32, ImgPreview.Top + 32);
		MouseShow;
		PreviewShown := false;
	end;
end;

procedure MoveSelection(TargetList: Integer; Direction: TDirection);
var
	NewSelection, NewStartPos, i: Integer;
	ListItem: PFileNode;
begin
	NewSelection := ListSelection[TargetList];
	NewStartPos := ListStartPos[TargetList];

	case Direction of
		Up: Dec(NewSelection);
		Down: Inc(NewSelection);
		First: NewSelection := 1;
		Last: NewSelection := ListLength[TargetList];
		PageUp: Dec(NewSelection, MaxVisibleItems);
		PageDown: Inc(NewSelection, MaxVisibleItems);
	end;

	{Check for out of bounds selection}
	if NewSelection < 1 then
		NewSelection := 1
	else if NewSelection > ListLength[TargetList] then
		NewSelection := ListLength[TargetList];
	
	{If selection is the same, no need to do anything}
	if NewSelection = ListSelection[TargetList] then
		exit;

	{If there aren't enough items to span more than one page, always start displaying from the first item}
	if ListLength[TargetList] < MaxVisibleItems then
		NewStartPos := 1
	else
	begin
		{More than one page, check if the selection is above or below the current visible items}

		{If selection is above visible items, scroll up one page at a time until it is visible}
		if NewSelection < NewStartPos then
		begin
			repeat
				Dec(NewStartPos, MaxVisibleItems);
			until NewStartPos <= NewSelection;
			if NewStartPos < 1 then
				NewStartPos := 1;
		end;

		{If selection is below visible items, scroll down one page at a time until it is visible}
		if NewSelection > NewStartPos + MaxVisibleItems - 1 then
		begin
			repeat
				Inc(NewStartPos, MaxVisibleItems);
			until (NewStartPos <= NewSelection) and 
				(NewStartPos + MaxVisibleItems - 1 >= NewSelection);
			if NewStartPos > ListLength[TargetList] then
				NewStartPos := ListLength[TargetList];
		end;
	end;

	{If list has scrolled, we need a full redraw}
	if NewStartPos <> ListStartPos[TargetList] then
	begin
		ListSelection[TargetList] := NewSelection;
		ListStartPos[TargetList] := NewStartPos;
		DrawList(TargetList, True, True);
	end
	else
	begin
		{Remove current selection}
		DrawList(TargetList, False, False);
		{Draw new selection}
		ListSelection[TargetList] := NewSelection;
		DrawList(TargetList, True, False);
	end;

	{Update Icon preview in case an Icon file is now selected}
	DrawPreview;
end;

function MouseSelection(TargetList: integer): boolean;
var
	ClickedX, ClickedY, ClickedItem: Integer;
	ListItem: PFileNode;
	I: Integer;
begin
	MousePoll;
	ClickedX := MouseX - AreaList[TargetList].Left;
	ClickedY := MouseY - AreaList[TargetList].Top;
	MouseSelection := False;

	{Validate click inside, not on border}
	if (ClickedX > 1) and (ClickedX < AreaList[TargetList].Width - 2) then
	begin
		if (ClickedY > 2) and (ClickedY < AreaList[TargetList].Height - 1) then
		begin
			{Clicked inside}

			if ActiveList <> TargetList then
				SetActiveList(TargetList);
			
			{There is a 3-pixel border before the first item.
			Calculate clicked item}
			ClickedItem := ((ClickedY - 3) div ListItemHeight) + 1;
			
			if ClickedItem > MaxVisibleItems then
			begin
				{Clicked inside list area, but in the small gap after the last item.
				Draw current item with focus}
				DrawList(TargetList, True, False);
				while MouseClicked > MbNone do;
				MouseSelection := False;
				Exit;
			end;

			ClickedItem := ClickedItem + ListStartPos[TargetList] - 1;
			if ClickedItem <= ListLength[TargetList] then
			begin
				if ClickedItem = ListSelection[TargetList] then
				begin
					{Already selected and clicked again, check for double-click}
					if Timer < ClickedDoubleTimer + DoubleClickDelay then
						MouseSelection := True
					else
						DrawList(TargetList, True, False);
				end
				else
				begin
					{Clicked item is not the current selection, move selection}
					DrawList(TargetList, False, False);
					ListSelection[TargetList] := ClickedItem;
					DrawList(TargetList, True, False);
				end;
			end
			else
			begin
				{Clicked in list, but below any items. Give focus to current selection}
				DrawList(TargetList, True, False);
			end;
		end;
	end;

	DrawPreview;
	ClickedDoubleTimer := Timer;
	while MouseClicked > MbNone do;
end;

procedure SetActiveList(TargetList: Integer);
begin
	if TargetList = ActiveList then
		exit; {Already active}
	
	DrawList(ActiveList, False, False);
	ActiveList := TargetList;
	DrawList(ActiveList, True, False);
end;

function SetDrive(DriveLetter: Char): Boolean;
var
	CurrentDir: String;
begin
	DriveLetter := UpCase(DriveLetter);
	if (DriveLetter >= 'A') and (DriveLetter <= 'Z') then
	begin
	{$I-}
	ChDir(DriveLetter + ':\');
	{$I+}
	if IOResult = 0 then
	begin
		GetDir(0, Path);
		Drive := DriveLetter;
		GetChildFiles(Path, Pattern);
		GetChildDirs(Path);
		DrawList(FileList, True, True);
		DrawList(DirList, False, True);
		SetDrive := True;
		DrawPreview;
		Exit;
	end
	else
	 ChDir(Path); {Restore original path if drive change fails}
	end;

	SetDrive := False;
end;

procedure SetDir(DirName: String);
begin
	{$I-}
	ChDir(DirName);
	{$I+}
	if IOResult = 0 then
	begin
		GetDir(0, Path);
		GetChildFiles(Path, Pattern);
		GetChildDirs(Path);
		DrawList(FileList, False, True);
		DrawList(DirList, True, True);
	end;
	DrawPreview;
end;

function FileSelect(DefaultPattern, StartPath: string; IconSelect: boolean): string;
var
	WinFileSelect: TWindow;
	TxtDrive, TxtPattern: TTextbox;
	BtnSelect, BtnCancel: TButton;
	BtnFilePrev, BtnFileNext: TButton;
	BtnDirPrev, BtnDirNext: TButton;
	OriginalPath: string;
	I: Integer;
	X1, Y1, X2, Y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Key: string;
	SelectedItemName: String[MaxNameLength];
begin
	WinFileSelect.Init(sizeCenter, sizeCenter, 468, 270);
	TxtPattern.Init(101, WinFileSelect.Top + 28, 150, SizeDefault, CAP_PATTERN);
	TxtDrive.Init(272, WinFileSelect.Top + 28, 150, SizeDefault, CAP_DRIVE);
	TxtPattern.Init(101, WinFileSelect.Top + 28, 150, SizeDefault, CAP_PATTERN);
	TxtDrive.Init(272, WinFileSelect.Top + 28, 150, SizeDefault, CAP_DRIVE);
	AreaList[FileList].Init(101, WinFileSelect.Top + 71, 150, 185);
	AreaList[DirList].Init(272, WinFileSelect.Top + 71, 150, 185);
	BtnSelect.Init(448, WinFileSelect.Top + 28, SizeDefault, SizeDefault, CAP_SELECT);
	BtnCancel.Init(448, WinFileSelect.Top + 58, SizeDefault, SizeDefault, CAP_CANCEL);
	BtnFilePrev.Init(253, AreaList[FileList].Top, 14, 91, CharArrowUp);
	BtnFileNext.Init(253, AreaList[FileList].Top + 94, 14, 91, CharArrowDown);
	BtnDirPrev.Init(424, AreaList[DirList].Top, 14, 91, CharArrowUp);
	BtnDirNext.Init(424, AreaList[DirList].Top + 94, 14, 91, CharArrowDown);
	TxtDrive.MaxLen := 1;
	TxtPattern.MaxLen := 12; {8.3 including the dot}
	ImgPreview.Init(BtnCancel.Left + 30, BtnCancel.Top + 50, '');
	
	GetDir(0, OriginalPath); {Save to restore later}
	Path := OriginalPath;

	Drive := Copy(Path, 1, 1);
	Pattern := DefaultPattern;
	TxtDrive.Text := Drive;
	TxtPattern.Text := DefaultPattern;
	ActiveList := FileList;

	MouseHide;

	{Save background to restore when window is closed}
	X1 := WinFileSelect.Left;
	Y1 := WinFileSelect.Top;
	X2 := WinFileSelect.Left + WinFileSelect.Width;
	Y2 := WinFileSelect.Top + WinFileSelect.Height;
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);

	WinFileSelect.Draw;
	TxtPattern.Draw;
	TxtDrive.Draw;
	AreaList[FileList].Draw;
	AreaList[DirList].Draw;
	BtnSelect.Draw;
	BtnCancel.Draw;
	BtnFilePrev.Draw;
	BtnFileNext.Draw;
	BtnDirPrev.Draw;
	BtnDirNext.Draw;
	Print(CAP_FILES, 101, WinFileSelect.Top + 57, Thm.WinText);
	Print(CAP_DIRS, 272, WinFileSelect.Top + 57, Thm.WinText);
	MouseShow;

	{If path provided, use it}
	if Length(StartPath) > 0 then
		SetDir(StartPath)
	else
	begin
		GetChildFiles(Path, Pattern);
		GetChildDirs(Path);
		DrawList(FileList, True, True);
		DrawList(DirList, False, True);
	end;

	repeat
		Key := GetKey;

		if (MouseClicked > MbNone) and AreaList[FileList].IsMouseOver then
		begin
			if MouseSelection(FileList) then
				Key := KeyEnter; {Double-clicked file, select it}
		end;

		if (MouseClicked > MbNone) and AreaList[DirList].IsMouseOver then
		begin
			if MouseSelection(DirList) then
				Key := KeyEnter; {Double-clicked directory, change to it}
		end;

		if BtnSelect.Clicked or (Key = KeyAltS) or (Key = KeyEnter) then
		begin
			SelectedItemName := GetListItemName(ActiveList, ListSelection[ActiveList]);
			if SelectedItemName <> '' then
			begin
				if ActiveList = FileList then
				begin
					{Make sure path ends with a backslash}
					if (Path[Length(Path)] <> '\') then
						Path := Path + '\';
					FileSelect := Path + SelectedItemName;
					Break;
				end;
				
				if ActiveList = DirList then
				begin
					SetDir(SelectedItemName);
				end;
			end;
		end;

		if BtnCancel.Clicked or (Key = KeyAltC) or (Key = KeyEscape) then
		begin
			FileSelect := '';
			Break;
		end;

		if TxtDrive.Clicked or (Key = KeyAltR) then
		begin
			TxtDrive.Edit;
			if TxtDrive.Text <> Drive Then
			begin
				if not SetDrive(TxtDrive.Text[1]) then
				begin
					TxtDrive.Text := Drive; {Restore original drive letter}
					MouseHide;
					TxtDrive.Draw;
					MouseShow;
				end;
			end;
		end;

		if BtnFilePrev.Clicked then
		begin
			SetActiveList(FileList);
			Key := KeyPageUp; {Simulate key press for moving selection up}
		end;

		if BtnFileNext.Clicked then
		begin
			SetActiveList(FileList);
			Key := KeyPageDown; {Simulate key press for moving selection down}
		end;

		if BtnDirPrev.Clicked then
		begin
			SetActiveList(DirList);
			Key := KeyPageUp; {Simulate key press for moving view up}
		end;

		if BtnDirNext.Clicked then
		begin
			SetActiveList(DirList);
			Key := KeyPageDown; {Simulate key press for moving view down}
		end;

		if Key = KeyUp then
			MoveSelection(ActiveList, Up);

		if Key = KeyDown then
			MoveSelection(ActiveList, Down);

		if Key = KeyHome then
			MoveSelection(ActiveList, First);

		if Key = KeyEnd then
			MoveSelection(ActiveList, Last);

		if Key = KeyPageUp then
			MoveSelection(ActiveList, PageUp);

		if Key = KeyPageDown then
			MoveSelection(ActiveList, PageDown);

		if (Key = KeyAltF) then
			SetActiveList(FileList);

		if (Key = KeyAltD) then
			SetActiveList(DirList);

		if (Key = KeyTab) or (Key = KeyShiftTab) then
			SetActiveList(not ActiveList);

		if TxtPattern.Clicked or (Key = KeyAltP) then
		begin
			TxtPattern.Edit;
			if TxtPattern.Text <> Pattern then
			begin
				Pattern := TxtPattern.Text;
				GetChildFiles(Path, Pattern);
				DrawList(FileList, True, True);
				DrawPreview;
			end;
		end;

	until False;
	MouseHide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;

	{$I-}
	ChDir(OriginalPath); {Restore original path}
	{$I+}
end;

end.