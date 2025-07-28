unit FileDlg;

interface

uses
	Costalib;

function FileSelect(DefaultPattern, StartPath: string; ImageSelect: boolean): string;

implementation

uses
	DOS, Graph;

const
	MaxFiles        = 150; {Maximum number of files}
	MaxDirs         = 100; {Maximum number of directories}
	MaxVisibleItems = 15;
	FileList        = 0;
	DirList         = -1;
	ListItemHeight  = 12;

	CAP_PATTERN     = #127 + 'Pattern';
	CAP_DRIVE       = 'D' + #127 + 'rive';
	CAP_FILES       = #127 + 'Files';
	CAP_DIRS        = #127 + 'Directories';
	CAP_SELECT      = #127 + 'Select';
	CAP_CANCEL      = #127 + 'Cancel';

type
	TDirection = (Up, Down, First, Last, PageUp, PageDown);

var
	TxtList:       array[-1..0] of TTextbox;
	ListStartPos:  array[-1..0] of Integer;
	ListSelection: array[-1..0] of Integer;
	ListCount:     array[-1..0] of Integer;
	SubDirs:       array[1..MaxDirs] of String[12];
	SubFiles:      array[1..MaxFiles] of String[12];

	PreviewShown:  boolean;
	ImgPreview:    TIcon;

	ActiveList: Integer;
	Path, Pattern: String;
	Drive: String[1];
	ClickedDoubleTimer: Real;

procedure SetActiveList(TargetList: Integer); forward;

procedure GetChildFiles(Path: String; FilePattern: String);
var
	FileInfo: SearchRec;
begin
	{Clear previous file list}
	ListCount[FileList] := 0;
	FillChar(SubFiles, SizeOf(SubFiles), #0);

	FindFirst(Path + '\' + FilePattern, Archive, FileInfo);
	while DosError = 0 do
	begin
	if (FileInfo.Attr and Directory) = 0 then
	begin
		{If CON is opened the program will crash}
		if (ListCount[FileList] < MaxFiles) and (FileInfo.Name <> 'CON') then
		begin
			Inc(ListCount[FileList]);
			SubFiles[ListCount[FileList]] := FileInfo.Name;
		end
		else
			Break; {Stop if maximum file count is exceeded}
	end;
	FindNext(FileInfo);
	end;
end;

procedure GetChildDirs(Path: String);
var
	DirInfo: SearchRec;
begin
	{Clear previous directory list}
	ListCount[DirList] := 0;
	FillChar(SubDirs, SizeOf(SubDirs), #0);

	{Add '..' for parent directory if not at root}
	if Length(Path) > 3 then
	begin
		Inc(ListCount[DirList]);
		SubDirs[ListCount[DirList]] := '..';
	end;

	FindFirst(Path + '\*.*', Directory, DirInfo);
	while DosError = 0 do
	begin
	if (DirInfo.Attr and Directory) <> 0 then
	begin
		if (DirInfo.Name <> '.') and (DirInfo.Name <> '..') then
		begin
			if ListCount[DirList] < MaxDirs then
			begin
				Inc(ListCount[DirList]);
				SubDirs[ListCount[DirList]] := DirInfo.Name
			end
			else
				Break; {Stop if maximum directory count is exceeded}
		end;
	end;
	FindNext(DirInfo);
	end;
end;

procedure DrawFileList(TargetList: integer; HighLightActive, FullRedraw: Boolean);
var
	I, Counter: Integer;
	X1, Y1, X2, Y2, YOffset: Integer;
	FGColor, BGColor: Integer;
	ItemText: String;
begin
	X1 := TxtList[TargetList].Left + 2;
	Y1 := TxtList[TargetList].Top + 3;
	X2 := TxtList[TargetList].Left + TxtList[TargetList].Width - 2;
	Y2 := TxtList[TargetList].Top + 15;
	YOffset := ((ListSelection[TargetList] - ListStartPos[TargetList]) * ListItemHeight);

	MouseHide;
	if FullRedraw then
	begin
		SetFillStyle(SolidFill, Thm.Txt);
		Bar(X1, Y1, X2, Y2 - 1 + ((MaxVisibleItems - 1) * ListItemHeight));
		Counter := 0;
		for I := ListStartPos[TargetList] to ListStartPos[TargetList] + MaxVisibleItems - 1 do
		begin
			if I <= ListCount[TargetList] then
			begin
			if TargetList = FileList then
				ItemText := SubFiles[I]
			else
				ItemText := SubDirs[I];

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

		if TargetList = FileList then
			ItemText := SubFiles[ListSelection[FileList]]
		else
			ItemText := SubDirs[ListSelection[DirList]];
		
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
	ImageFile: String;
	FDir: DirStr;
	FName: NameStr;
	FExt: ExtStr;
begin
	if (Path = ProgramPath + 'ICONS') and (ListSelection[FileList] <> 0) then
	begin
		FSplit(SubFiles[ListSelection[FileList]], FDir, FName, FExt);
		if (Length(FName) <> 0) and (FExt = '.BIN') then
		begin
			MouseHide;
			ImgPreview.ImageFile := FName;
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
	NewSelection, NewStartPos: Integer;
begin
	NewSelection := ListSelection[TargetList];
	NewStartPos := ListStartPos[TargetList];

	case Direction of
		Up: Dec(NewSelection);
		Down: Inc(NewSelection);
		First: NewSelection := 1;
		Last: NewSelection := ListCount[TargetList];
		PageUp: Dec(NewSelection, MaxVisibleItems);
		PageDown: Inc(NewSelection, MaxVisibleItems);
	end;

	{Check for out of bounds selection}
	if NewSelection < 1 then
		NewSelection := 1
	else if NewSelection > ListCount[TargetList] then
		NewSelection := ListCount[TargetList];
	
	{If selection is the same, no need to do anything}
	if NewSelection = ListSelection[TargetList] then
		exit;

	{If there aren't enough items to span more than one page, always start displaying from the first item}
	if ListCount[TargetList] < MaxVisibleItems then
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
			if NewStartPos > ListCount[TargetList] then
				NewStartPos := ListCount[TargetList];
		end;
	end;

	{If list has scrolled, we need a full redraw}
	if NewStartPos <> ListStartPos[TargetList] then
	begin
		ListSelection[TargetList] := NewSelection;
		ListStartPos[TargetList] := NewStartPos;
		DrawFileList(TargetList, True, True);
	end
	else
	begin
		{Remove current selection}
		DrawFileList(TargetList, False, False);
		{Draw new selection}
		ListSelection[TargetList] := NewSelection;
		DrawFileList(TargetList, True, False);
	end;
		
	{Update image preview in case an image file is now selected}
	DrawPreview;
end;

function MouseSelection(TargetList: integer): boolean;
var
	ClickedX, ClickedY, ClickedItem: Integer;
begin
	MousePoll;
	ClickedX := MouseX - TxtList[TargetList].Left;
	ClickedY := MouseY - TxtList[TargetList].Top;
	MouseSelection := False;

	{Validate click inside, not on border}
	if (ClickedX > 1) and (ClickedX < TxtList[TargetList].Width - 2) then
	begin
		if (ClickedY > 2) and (ClickedY < TxtList[TargetList].Height - 1) then
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
				DrawFileList(TargetList, True, False);
				while MouseClicked > MbNone do;
				MouseSelection := False;
				Exit;
			end;

			ClickedItem := ClickedItem + ListStartPos[TargetList] - 1;
			if ClickedItem <= ListCount[TargetList] then
			begin
				if ClickedItem = ListSelection[TargetList] then
				begin
					{Already selected and clicked again, check for double-click}
					if Timer < ClickedDoubleTimer + DoubleClickDelay then
						MouseSelection := True
					else
						DrawFileList(TargetList, True, False);
				end
				else
				begin
					{Clicked item is not the current selection, move selection}
					DrawFileList(TargetList, False, False);
					ListSelection[TargetList] := ClickedItem;
					DrawFileList(TargetList, True, False);
				end;
			end
			else
			begin
				{Clicked in list, but below any items. Give focus to current selection}
				DrawFileList(TargetList, True, False);
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
	
	DrawFileList(ActiveList, False, False);
	ActiveList := TargetList;
	DrawFileList(ActiveList, True, False);
end;

function SetDrive(DriveLetter: Char): Boolean;
var
	CurrentDir: String;
	TempLetter: String[1];
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
		DrawFileList(FileList, True, True);
		DrawFileList(DirList, False, True);
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
		ListStartPos[FileList] := 1;
		ListSelection[FileList] := 1;
		ListStartPos[DirList] := 1;
		ListSelection[DirList] := 1;
		DrawFileList(FileList, False, True);
		DrawFileList(DirList, True, True);
	end;
	DrawPreview;
end;

function FileSelect(DefaultPattern, StartPath: string; ImageSelect: boolean): string;
var
	WinFileSelect: TWindow;
	TxtDrive, TxtPattern: TTextbox;
	BtnSelect, BtnCancel: TButton;
	BtnFilePrev, BtnFileNext: TButton;
	BtnDirPrev, BtnDirNext: TButton;
	OriginalPath: string;
	Counter, I: Integer;
	X1, Y1, X2, Y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Key: string;
	ClickedX, ClickedY, ClickedItem, RedrawNeeded: Integer;
begin
	WinFileSelect.Init(sizeCenter, sizeCenter, 468, 270);
	TxtPattern.Init(101, WinFileSelect.Top + 28, 150, SizeDefault);
	TxtDrive.Init(272, WinFileSelect.Top + 28, 150, SizeDefault);
	TxtPattern.Init(101, WinFileSelect.Top + 28, 150, SizeDefault);
	TxtDrive.Init(272, WinFileSelect.Top + 28, 150, SizeDefault);
	TxtList[FileList].Init(101, WinFileSelect.Top + 71, 150, 185);
	TxtList[DirList].Init(272, WinFileSelect.Top + 71, 150, 185);
	BtnSelect.Init(448, WinFileSelect.Top + 28, SizeDefault, SizeDefault, CAP_SELECT);
	BtnCancel.Init(448, WinFileSelect.Top + 58, SizeDefault, SizeDefault, CAP_CANCEL);
	BtnFilePrev.Init(253, TxtList[FileList].Top, 14, 91, CharArrowUp);
	BtnFileNext.Init(253, TxtList[FileList].Top + 94, 14, 91, CharArrowDown);
	BtnDirPrev.Init(424, TxtList[DirList].Top, 14, 91, CharArrowUp);
	BtnDirNext.Init(424, TxtList[DirList].Top + 94, 14, 91, CharArrowDown);
	TxtDrive.MaxLen := 1;
	TxtPattern.MaxLen := 12; {8.3 including the dot}
	ImgPreview.Init(BtnCancel.Left + 30, BtnCancel.Top + 50, '');
	
	GetDir(0, OriginalPath); {Save to restore later}
	Path := OriginalPath;

	Drive := Copy(Path, 1, 1);
	Pattern := DefaultPattern;
	TxtDrive.Text := Drive;
	TxtPattern.Text := DefaultPattern;
	ListStartPos[DirList] := 1;
	ListStartPos[FileList] := 1;
	ListSelection[FileList] := 1;
	ListSelection[DirList] := 1;
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
	TxtList[FileList].Draw;
	TxtList[DirList].Draw;
	BtnSelect.Draw;
	BtnCancel.Draw;
	BtnFilePrev.Draw;
	BtnFileNext.Draw;
	BtnDirPrev.Draw;
	BtnDirNext.Draw;
	Print(CAP_PATTERN, 101, WinFileSelect.Top + 14, Thm.WinText);
	Print(CAP_DRIVE, 272, WinFileSelect.Top + 14, Thm.WinText);
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
		DrawFileList(FileList, True, True);
		DrawFileList(DirList, False, True);
	end;

	repeat
		Key := GetKey;

		if (MouseClicked > MbNone) and TxtList[FileList].IsMouseOver then
		begin
			if MouseSelection(FileList) then
				Key := KeyEnter; {Double-clicked file, select it}
		end;

		if (MouseClicked > MbNone) and TxtList[DirList].IsMouseOver then
		begin
			if MouseSelection(DirList) then
				Key := KeyEnter; {Double-clicked directory, change to it}
		end;

		if BtnClick(BtnSelect) or (Key = KeyAltS) or (Key = KeyEnter) then
		begin
			if (ActiveList = FileList) and (SubFiles[ListSelection[FileList]] <> '') then
			begin
				{Make sure path ends with a backslash}
				if (Path[Length(Path)] <> '\') then
					Path := Path + '\';
				FileSelect := Path + SubFiles[ListSelection[FileList]];
				Break;
			end;
			
			if (ActiveList = DirList) and (SubDirs[ListSelection[DirList]] <> '') then
			begin
				SetDir(SubDirs[ListSelection[DirList]]);
			end;
		end;

		if BtnClick(BtnCancel) or (Key = KeyAltC) or (Key = KeyEscape) then
		begin
			FileSelect := '';
			Break;
		end;

		if TxtClick(TxtDrive) or (Key = KeyAltR) then
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

		if BtnClick(BtnFilePrev) then
		begin
			SetActiveList(FileList);
			Key := KeyPageUp; {Simulate key press for moving selection up}
		end;

		if BtnClick(BtnFileNext) then
		begin
			SetActiveList(FileList);
			Key := KeyPageDown; {Simulate key press for moving selection down}
		end;

		if BtnClick(BtnDirPrev) then
		begin
			SetActiveList(DirList);
			Key := KeyPageUp; {Simulate key press for moving view up}
		end;

		if BtnClick(BtnDirNext) then
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

		if TxtClick(TxtPattern) or (Key = KeyAltP) then
		begin
			TxtPattern.Edit;
			if TxtPattern.Text <> Pattern then
			begin
				Pattern := TxtPattern.Text;
				GetChildFiles(Path, Pattern);
				ListStartPos[FileList] := 1;
				ListSelection[FileList] := 1;
				DrawFileList(FileList, True, True);
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