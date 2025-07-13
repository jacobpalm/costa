unit FileSel;

interface

uses
	Costalib;

function FileSelect(DefaultPattern: string): string;

implementation

uses
	DOS, Graph;

const
	MaxFiles        = 150; {Maximum number of files}
	MaxFolders      = 100; {Maximum number of folders}
	MaxVisibleItems = 15;
	FileList        = 0;
	FolderList      = -1;
	ListItemHeight  = 12;

	DirectionUp     = -1;
	DirectionDown   = 1;

var
	txtList:       array[-1..0] of TextboxType;
	ListStartPos:  array[-1..0] of Integer;
	ListSelection: array[-1..0] of Integer;
	ListCount:     array[-1..0] of Integer;
	SubFolders:    array[1..MaxFolders] of String[12];
	SubFiles:      array[1..MaxFiles] of String[12];

	ActiveList: Integer;
	Path, Pattern: String;
	Drive: String[1];
	ClickedDoubleTimer: Real;

procedure FileSetActiveList(TargetList: Integer); forward;

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

procedure GetChildFolders(Path: String);
var
	FolderInfo: SearchRec;
begin
	{Clear previous folder list}
	ListCount[FolderList] := 0;
	FillChar(SubFolders, SizeOf(SubFolders), #0);

	{Add '..' for parent directory if not at root}
	if Length(Path) > 3 then
	begin
	Inc(ListCount[FolderList]);
	SubFolders[ListCount[FolderList]] := '..';
	end;

	FindFirst(Path + '\*.*', Directory, FolderInfo);
	while DosError = 0 do
	begin
	if (FolderInfo.Attr and Directory) <> 0 then
	begin
		if (FolderInfo.Name <> '.') and (FolderInfo.Name <> '..') then
		begin
		if ListCount[FolderList] < MaxFolders then
		begin
			Inc(ListCount[FolderList]);
			SubFolders[ListCount[FolderList]] := FolderInfo.Name
		end
		else
			Break; {Stop if maximum folder count is exceeded}
		end;
	end;
	FindNext(FolderInfo);
	end;
end;

procedure DrawFileList(TargetList: integer; HighLightActive, FullRedraw: Boolean);
var
	I, Counter: Integer;
	x1, y1, x2, y2, YOffset: Integer;
	FGColor, BGColor: Integer;
	ItemText: String;
begin
	x1 := txtList[TargetList].Pos.Left + 2;
	y1 := txtList[TargetList].Pos.Top + 3;
	x2 := txtList[TargetList].Pos.Left + txtList[TargetList].Pos.Width - 2;
	y2 := txtList[TargetList].Pos.Top + 15;
	YOffset := ((ListSelection[TargetList] - ListStartPos[TargetList]) * ListItemHeight);

	MouseHide;
	if FullRedraw then
	begin
	SetFillStyle(SolidFill, Theme.Textbox);
	Bar(x1, y1, x2, y2 - 1 + ((MaxVisibleItems - 1) * ListItemHeight));
	Counter := 0;
	for I := ListStartPos[TargetList] to ListStartPos[TargetList] + MaxVisibleItems - 1 do
	begin
		if I <= ListCount[TargetList] then
		begin
		if TargetList = FileList then
			ItemText := SubFiles[I]
		else
			ItemText := SubFolders[I];

		{Highlight active selected item}
		if (I = ListSelection[TargetList]) and (ActiveList = TargetList) then
		begin
			{Draw highlighted item}
			SetFillStyle(SolidFill, Theme.Select);
			Bar(x1, y1 + (Counter * ListItemHeight), x2, y2 - 1 + (Counter * ListItemHeight));
			FontPrint(ItemText, x1 + 3, y1 + 2 + (Counter * ListItemHeight), Theme.SelectText, FontHeading);
		end
		else
		begin
			{Draw normal item}
			FontPrint(ItemText, x1 + 3, y1 + 2 + (Counter * ListItemHeight), Theme.TextboxText, FontHeading);
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
		FGColor := Theme.SelectText;
		BGColor := Theme.Select;
	end
	else
	begin
		FGColor := Theme.TextboxText;
		BGColor := Theme.Textbox;
	end;

	if TargetList = FileList then
		ItemText := SubFiles[ListSelection[FileList]]
	else
		ItemText := SubFolders[ListSelection[FolderList]];
	
	if ItemText <> '' then
	begin
		SetFillStyle(SolidFill, BGColor);
		Bar(x1, y1 + YOffset, x2, y2 - 1 + YOffset);
		FontPrint(ItemText, x1 + 3, y1 + 2 + YOffset, FGColor, FontHeading);
	end;
	end;
	MouseShow;
end;

procedure FileMoveSelection(TargetList, Direction: Integer);
var
	RedrawNeeded: Boolean;
begin
	RedrawNeeded := False;

	{Remove current selection}
	DrawFileList(TargetList, False, False);

	{Move selection - Direction is -1 for up, 1 for down - using constants}
	ListSelection[TargetList] := ListSelection[TargetList] + Direction;

	{Validate if lists need to be scrolled in either direction}
	if ListSelection[TargetList] < 1 then
	begin
		{If selection is below zero, set to last item instead}
		RedrawNeeded := True;
		ListSelection[TargetList] := ListCount[TargetList];
		ListStartPos[TargetList] := ListCount[TargetList] - MaxVisibleItems + 1;
		if ListStartPos[TargetList] < 1 then
			ListStartPos[TargetList] := 1;
	end;

	if ListSelection[TargetList] < ListStartPos[TargetList] then
	begin
		{If selection is below visible items, scroll up one page}
		RedrawNeeded := True;
		ListStartPos[TargetList] := ListStartPos[TargetList] - MaxVisibleItems;
		if ListStartPos[TargetList] < 1 then
			ListStartPos[TargetList] := 1;
	end;

	if ListSelection[TargetList] > ListCount[TargetList] then
	begin
		{If selection is higher than item count, set to first item instead}
		RedrawNeeded := True;
		ListSelection[TargetList] := 1;
		ListStartPos[TargetList] := 1;
	end;

	if ListSelection[TargetList] > ListStartPos[TargetList] + MaxVisibleItems - 1 then
	begin
		{If selected item is below visible items, scroll to make it first visible item}
		RedrawNeeded := True;
		ListStartPos[TargetList] := ListSelection[TargetList];
	end;

	if not RedrawNeeded then
	begin
		{Entire list won't be redrawn, so remove current selection}
		DrawFileList(TargetList, False, False);
	end;

	{Redraw is only needed if list has been scrolled, otherwise only active item will be drawn}
	if RedrawNeeded then
		DrawFileList(TargetList, True, True)
	else
		DrawFileList(TargetList, True, False);
end;

function FileMouseSelection(TargetList: integer): boolean;
var
	ClickedX, ClickedY, ClickedItem: Integer;
	DeleteThisVar: String;
begin
	MousePoll;
	ClickedX := MouseX - txtList[TargetList].Pos.Left;
	ClickedY := MouseY - txtList[TargetList].Pos.Top;
	FileMouseSelection := False;

	{Validate click inside, not on border}
	if (ClickedX > 1) and (ClickedX < txtList[TargetList].Pos.Width - 2) then
	begin
		if (ClickedY > 2) and (ClickedY < txtList[TargetList].Pos.Height - 1) then
		begin
			{Clicked inside}

			if ActiveList <> TargetList then
				FileSetActiveList(TargetList);
			
			{There is a 3-pixel border before the first item.
			Calculate clicked item}
			ClickedItem := ((ClickedY - 3) div ListItemHeight) + 1;
			
			if ClickedItem > MaxVisibleItems then
			begin
				{Clicked inside list area, but in the small gap after the last item.
				Draw current item with focus}
				DrawFileList(TargetList, True, False);
				while MouseClicked > mbNone do;
				FileMouseSelection := False;
				Exit;
			end;

			ClickedItem := ClickedItem + ListStartPos[TargetList] - 1;
			if ClickedItem <= ListCount[TargetList] then
			begin
				if ClickedItem = ListSelection[TargetList] then
				begin
					{Already selected and clicked again, check for double-click}
					if Timer < ClickedDoubleTimer + DoubleClickDelay then
						FileMouseSelection := True
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

	ClickedDoubleTimer := Timer;
	while MouseClicked > mbNone do;
end;

procedure FileSetActiveList(TargetList: Integer);
begin
	if TargetList = ActiveList then
		exit; {Already active}
	
	DrawFileList(ActiveList, False, False);
	ActiveList := TargetList;
	DrawFileList(ActiveList, True, False);
end;

function FileSetDrive(DriveLetter: Char): Boolean;
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
	if IOResult = 0then
	begin
		GetDir(0, Path);
		Drive := DriveLetter;
		GetChildFiles(Path, Pattern);
		GetChildFolders(Path);
		DrawFileList(FileList, True, True);
		DrawFileList(FolderList, False, True);
		FileSetDrive := True;
		Exit;
	end
	else
	 ChDir(Path); {Restore original path if drive change fails}
	end;

	FileSetDrive := False;
end;

procedure FileSetFolder(FolderName: String);
begin
	{$I-}
	ChDir(SubFolders[ListSelection[FolderList]]);
	{$I+}
	if IOResult = 0 then
	begin
		GetDir(0, Path);
		GetChildFiles(Path, Pattern);
		GetChildFolders(Path);
		ListStartPos[FileList] := 1;
		ListSelection[FileList] := 1;
		ListStartPos[FolderList] := 1;
		ListSelection[FolderList] := 1;
		DrawFileList(FileList, False, True);
		DrawFileList(FolderList, True, True);
	end;
end;

function FileSelect(DefaultPattern: string): string;
var
	winFileSelect: WindowType;
	txtDrive, txtPattern: TextboxType;
	btnSelect, btnCancel: ButtonType;
	btnFilePrev, btnFileNext: ButtonType;
	btnFolderPrev, btnFolderNext: ButtonType;
	txtPatternText, txtDriveText: string;
	OriginalPath: string;
	Counter, I: Integer;
	x1, y1, x2, y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Key: string;
	ClickedX, ClickedY, ClickedItem, RedrawNeeded: Integer;
begin
	{Start out with contents of current directory}
	GetDir(0, OriginalPath);
	Path := OriginalPath;
	Drive := Copy(Path, 1, 1);
	Pattern := DefaultPattern;
	txtDriveText := Drive;
	txtPatternText := DefaultPattern;
	ListStartPos[FolderList] := 1;
	ListStartPos[FileList] := 1;
	ListSelection[FileList] := 1;
	ListSelection[FolderList] := 1;
	ActiveList := FileList;

	winFileSelect.Init(sizeCenter, sizeCenter, 468, 270);
	txtPattern.Init(101, winFileSelect.Pos.Top + 28, 150, sizeDefault);
	txtDrive.Init(272, winFileSelect.Pos.Top + 28, 150, sizeDefault);
	txtPattern.Init(101, winFileSelect.Pos.Top + 28, 150, sizeDefault);
	txtDrive.Init(272, winFileSelect.Pos.Top + 28, 150, sizeDefault);
	txtList[FileList].Init(101, winFileSelect.Pos.Top + 71, 150, 185);
	txtList[FolderList].Init(272, winFileSelect.Pos.Top + 71, 150, 185);
	btnSelect.Init(448, winFileSelect.Pos.Top + 28, sizeDefault, sizeDefault, HotkeySymbol + 'Select');
	btnCancel.Init(448, winFileSelect.Pos.Top + 58, sizeDefault, sizeDefault, HotkeySymbol + 'Cancel');
	btnFilePrev.Init(253, txtList[FileList].Pos.Top, 14, 91, #24);
	btnFileNext.Init(253, txtList[FileList].Pos.Top + 94, 14, 91, #25);
	btnFolderPrev.Init(424, txtList[FolderList].Pos.Top, 14, 91, #24);
	btnFolderNext.Init(424, txtList[FolderList].Pos.Top + 94, 14, 91, #25);
	txtDrive.MaxLen := 1;
	txtPattern.MaxLen := 12; {8.3 including the dot}

	{These are used in File.DrawList to differentiate lists... It's a dirty hack, but works}
	txtList[FileList].MaxLen := FileList;
	txtList[FolderList].MaxLen := FolderList;

	MouseHide;

	{Save background to restore when window is closed}
	x1 := winFileSelect.Pos.Left;
	y1 := winFileSelect.Pos.Top;
	x2 := winFileSelect.Pos.Left + winFileSelect.Pos.Width;
	y2 := winFileSelect.Pos.Top + winFileSelect.Pos.Height;
	BackgroundSize := ImageSize(x1, y1, x2, y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(x1, y1, x2, y2, BackgroundP^);

	ObjDrawWin(winFileSelect);
	ObjDrawTxt(txtPattern, txtPatternText, False);
	ObjDrawTxt(txtDrive, txtDriveText, False);
	ObjDrawTxt(txtList[FileList], '', False);
	ObjDrawTxt(txtList[FolderList], '', False);
	ObjDrawBtn(btnSelect, False);
	ObjDrawBtn(btnCancel, False);
	ObjDrawBtn(btnFilePrev, False);
	ObjDrawBtn(btnFileNext, False);
	ObjDrawBtn(btnFolderPrev, False);
	ObjDrawBtn(btnFolderNext, False);
	FontPrint(HotkeySymbol + 'Pattern:', 101, winFileSelect.Pos.Top + 14, Theme.WindowText, FontNormal);
	FontPrint(HotkeySymbol + 'Drive:', 272, winFileSelect.Pos.Top + 14, Theme.WindowText, FontNormal);
	FontPrint(HotkeySymbol + 'Files:', 101, winFileSelect.Pos.Top + 57, Theme.WindowText, FontNormal);
	FontPrint('F' + HotkeySymbol + 'olders:', 272, winFileSelect.Pos.Top + 57, Theme.WindowText, FontNormal);
	MouseShow;

	GetChildFiles(Path, Pattern);
	GetChildFolders(Path);
	DrawFileList(FileList, True, True);
	DrawFileList(FolderList, False, True);

	repeat
		Key := GetKey;

		if (MouseClicked > mbNone) and MouseInArea(txtList[FileList].Pos) then
		begin
			if FileMouseSelection(FileList) then
				Key := KeyEnter; {Double-clicked file, select it}
		end;

		if (MouseClicked > mbNone) and MouseInArea(txtList[FolderList].Pos) then
		begin
			if FileMouseSelection(FolderList) then
				Key := KeyEnter; {Double-clicked folder, change to it}
		end;

		if ObjBtnClick(btnSelect) or (Key = KeyAltS) or (Key = KeyEnter) then
		begin
			if (ActiveList = FileList) and (SubFiles[ListSelection[FileList]] <> '') then
			begin
				{Make sure path ends with a backslash}
				if (Path[Length(Path)] <> '\') then
					Path := Path + '\';
				FileSelect := Path + SubFiles[ListSelection[FileList]];
				Break;
			end;
			
			if (ActiveList = FolderList) and (SubFolders[ListSelection[FolderList]] <> '') then
			begin
				FileSetFolder(SubFolders[ListSelection[FolderList]]);
			end;
		end;

		if ObjBtnClick(btnCancel) or (Key = KeyAltC) or (Key = KeyEscape) then
		begin
			FileSelect := '';
			Break;
		end;

		if ObjTxtClick(txtDrive) or (Key = KeyAltD) then
		begin
			ObjEditTxt(txtDrive, txtDriveText);
			if txtDriveText <> Drive Then
			begin
				if not FileSetDrive(txtDriveText[1]) then
				begin
					txtDriveText := Drive; {Restore original drive letter}
					ObjDrawTxt(txtDrive, txtDriveText, False);
				end;
			end;
		end;

		if ObjBtnClick(btnFilePrev) then
		begin
			FileSetActiveList(FileList);
			Key := KeyUp; {Simulate key press for moving selection up}
		end;

		if ObjBtnClick(btnFileNext) then
		begin
			FileSetActiveList(FileList);
			Key := KeyDown; {Simulate key press for moving selection down}
		end;

		if ObjBtnClick(btnFolderPrev) then
		begin
			FileSetActiveList(FolderList);
			Key := KeyPageUp; {Simulate key press for moving view up}
		end;

		if ObjBtnClick(btnFolderNext) then
		begin
			FileSetActiveList(FolderList);
			Key := KeyPageDown; {Simulate key press for moving view down}
		end;

		if Key = KeyUp then
			FileMoveSelection(ActiveList, DirectionUp);

		if Key = KeyDown then
			FileMoveSelection(ActiveList, DirectionDown);

		if Key = KeyHome then
		begin
			ListStartPos[ActiveList] := 1;
			ListSelection[ActiveList] := 1;
			DrawFileList(ActiveList, True, True);
		end;

		if Key = KeyEnd then
		begin
			ListStartPos[ActiveList] := ListCount[ActiveList] - MaxVisibleItems + 1;
			if ListStartPos[ActiveList] < 1 then
				ListStartPos[ActiveList] := 1;
			ListSelection[ActiveList] := ListCount[ActiveList];
			DrawFileList(ActiveList, True, True);
		end;

		if Key = KeyPageUp then
			FileMoveSelection(ActiveList, DirectionUp * MaxVisibleItems);

		if Key = KeyPageDown then
			FileMoveSelection(ActiveList, DirectionDown * MaxVisibleItems);


		if (Key = KeyAltF) then
			FileSetActiveList(FileList);

		if (Key = KeyAltO) then
			FileSetActiveList(FolderList);

		if (Key = KeyTab) or (Key = KeyShiftTab) then
			FileSetActiveList(not ActiveList);

		if ObjTxtClick(txtPattern) or (Key = KeyAltP) then
		begin
			ObjEditTxt(txtPattern, txtPatternText);
			if txtPatternText <> Pattern then
			begin
				Pattern := txtPatternText;
				GetChildFiles(Path, Pattern);
				ListStartPos[FileList] := 1;
				ListSelection[FileList] := 1;
				DrawFileList(FileList, True, True);
			end;
		end;

	until False;
	MouseHide;
	PutImage(x1, y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;

	{$I-}
	ChDir(OriginalPath); {Restore original path}
	{$I+}
end;

end.