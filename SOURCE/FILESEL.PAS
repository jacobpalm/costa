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

procedure DrawFileList(var TargetList: TextboxType; HighLightActive, FullRedraw: Boolean);
var
	I, Counter, TotalItems, ListStartPos, ListSelection: Integer;
	x1, y1, x2, y2, YOffset: Integer;
	FGColor, BGColor: Integer;
	ItemText: String;
begin
	if TargetList.MaxLen = FileList then
	begin
		TotalItems := ListCount[FileList];
		ListStartPos := ListStartPos[FileList];
		ListSelection := ListSelection[FileList];
	end
	else
	begin
		TotalItems := ListCount[FolderList];
		ListStartPos := ListStartPos[FolderList];
		ListSelection := ListSelection[FolderList];
	end;

	x1 := TargetList.Pos.Left + 2;
	y1 := TargetList.Pos.Top + 3;
	x2 := TargetList.Pos.Left + TargetList.Pos.Width - 2;
	y2 := TargetList.Pos.Top + 15;
	YOffset := ((ListSelection - ListStartPos) * ListItemHeight);

	MouseHide;
	if FullRedraw then
	begin
	SetFillStyle(SolidFill, Theme.Textbox);
	Bar(x1, y1, x2, y2 - 1 + ((MaxVisibleItems - 1) * ListItemHeight));
	Counter := 0;
	for I := ListStartPos to ListStartPos + MaxVisibleItems - 1 do
	begin
		if I <= TotalItems then
		begin
		if TargetList.MaxLen = FileList then
			ItemText := SubFiles[I]
		else
			ItemText := SubFolders[I];

		{Highlight active selected item}
		if (I = ListSelection) and (ActiveList = TargetList.MaxLen) then
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
	if HighLightActive and (ActiveList = TargetList.MaxLen) then
	begin
		FGColor := Theme.SelectText;
		BGColor := Theme.Select;
	end
	else
	begin
		FGColor := Theme.TextboxText;
		BGColor := Theme.Textbox;
	end;

	if TargetList.MaxLen = FileList then
		ItemText := SubFiles[ListSelection]
	else
		ItemText := SubFolders[ListSelection];
	
	if ItemText <> '' then
	begin
		SetFillStyle(SolidFill, BGColor);
		Bar(x1, y1 + YOffset, x2, y2 - 1 + YOffset);
		FontPrint(ItemText, x1 + 3, y1 + 2 + YOffset, FGColor, FontHeading);
	end;
	end;
	MouseShow;
end;

procedure FileMoveSelection(TargetList: TextboxType; Direction: Integer);
var
	RedrawNeeded: Boolean;
	TotalItems, ListStartPos, ListSelection: Integer;
begin
	RedrawNeeded := False;
	{Retrieve values to temp variables - so both lists can be handled by same code}
	if TargetList.MaxLen = FileList then
	begin
	TotalItems := ListCount[FileList];
	ListStartPos := ListStartPos[FileList];
	ListSelection := ListSelection[FileList];
	end
	else
	begin
	TotalItems := ListCount[FolderList];
	ListStartPos := ListStartPos[FolderList];
	ListSelection := ListSelection[FolderList];
	end;

	{Move selection - Direction is -1 for up, 1 for down - using constants}
	ListSelection := ListSelection + Direction;

	{Validate if lists need to be scrolled in either direction}
	if ListSelection < 1 then
	begin
	{If selection is below zero, set to last item instead}
	RedrawNeeded := True;
	ListSelection := TotalItems;
	ListStartPos := TotalItems - MaxVisibleItems + 1;
	if ListStartPos < 1 then
		ListStartPos := 1;
	end;

	if ListSelection < ListStartPos then
	begin
	{If selection is below visible items, scroll up one page}
	RedrawNeeded := True;
	ListStartPos := ListStartPos - MaxVisibleItems;
	if ListStartPos < 1 then
		ListStartPos := 1;
	end;

	if ListSelection > TotalItems then
	begin
	{If selection is higher than item count, set to first item instead}
	RedrawNeeded := True;
	ListSelection := 1;
	ListStartPos := 1;
	end;

	if ListSelection > ListStartPos + MaxVisibleItems - 1 then
	begin
	{If selected item is below visible items, scroll to make it first visible item}
	RedrawNeeded := True;
	ListStartPos := ListSelection;
	end;

	if not RedrawNeeded then
	begin
	{Entire list won't be redrawn, so remove current selection}
	DrawFileList(TargetList, False, False);
	end;

	{Put temporary values back in proper variables}
	if TargetList.MaxLen = FileList then
	begin
	ListStartPos[FileList] := ListStartPos;
	ListSelection[FileList] := ListSelection;
	end
	else
	begin
	ListStartPos[FolderList] := ListStartPos;
	ListSelection[FolderList] := ListSelection;
	end;

	{Redraw is only needed if list has been scrolled, otherwise only active item will be drawn}
	if RedrawNeeded then
	DrawFileList(TargetList, True, True)
	else
	DrawFileList(TargetList, True, False);
end;

function FileMouseSelection(var TargetList: TextboxType): Boolean;
var
	ClickedX, ClickedY, ClickedItem: Integer;
	TotalItems, ListStartPos, ListSelection: Integer;
	DeleteThisVar: String;
begin
	MousePoll;
	ClickedX := MouseX - TargetList.Pos.Left;
	ClickedY := MouseY - TargetList.Pos.Top;
	FileMouseSelection := False;

	{Retrieve values to temp variables - so both lists can be handled by same code}
	if TargetList.MaxLen = FileList then
	begin
		TotalItems := ListCount[FileList];
		ListStartPos := ListStartPos[FileList];
		ListSelection := ListSelection[FileList];
	end
	else
	begin
		TotalItems := ListCount[FolderList];
		ListStartPos := ListStartPos[FolderList];
		ListSelection := ListSelection[FolderList];
	end;

	{Validate click inside, not on border}
	if (ClickedX > 1) and (ClickedX < TargetList.Pos.Width - 2) then
	begin
	if (ClickedY > 2) and (ClickedY < TargetList.Pos.Height - 1) then
	begin
		{Clicked inside}

		if ActiveList <> TargetList.MaxLen then
		begin
		{Clicked list is not active. Make it so, and remove selection from other list}
		if ActiveList = FileList then
		begin
			ActiveList := FolderList;
			DrawFileList(txtList[FileList], False, False);
		end
		else
		begin
			ActiveList := FileList;
			DrawFileList(txtList[FolderList], False, False);
		end;
		end;
		
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

		ClickedItem := ClickedItem + ListStartPos - 1;
		if ClickedItem <= TotalItems then
		begin
		if ClickedItem = ListSelection then
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
			if TargetList.MaxLen = FileList then
				ListSelection[FileList] := ClickedItem
			else
				ListSelection[FolderList] := ClickedItem;
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
		DrawFileList(txtList[FileList], True, True);
		DrawFileList(txtList[FolderList], False, True);
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
		DrawFileList(txtList[FileList], False, True);
		DrawFileList(txtList[FolderList], True, True);
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
	DrawFileList(txtList[FileList], True, True);
	DrawFileList(txtList[FolderList], False, True);

	repeat
		Key := GetKey;

		if (MouseClicked > mbNone) and MouseInArea(txtList[FileList].Pos) then
		begin
			if FileMouseSelection(txtList[FileList]) then
				Key := KeyEnter; {Double-clicked file, select it}
		end;

		if (MouseClicked > mbNone) and MouseInArea(txtList[FolderList].Pos) then
		begin
			if FileMouseSelection(txtList[FolderList]) then
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
			if not ActiveList = FileList then
			begin
				ActiveList := FileList;
				DrawFileList(txtList[FolderList], False, False);
			end;
			Key := KeyUp; {Simulate key press for moving selection up}
		end;

		if ObjBtnClick(btnFileNext) then
		begin
			if not ActiveList = FileList then
			begin
				ActiveList := FileList;
				DrawFileList(txtList[FolderList], False, False);
			end;
			Key := KeyDown; {Simulate key press for moving selection down}
		end;

		if ObjBtnClick(btnFolderPrev) then
		begin
			if not ActiveList = FolderList then
			begin
				ActiveList := FolderList;
				DrawFileList(txtList[FileList], False, False);
			end;
			Key := KeyPageUp; {Simulate key press for moving view up}
		end;

		if ObjBtnClick(btnFolderNext) then
		begin
			if not ActiveList = FolderList then
			begin
				ActiveList := FolderList;
				DrawFileList(txtList[FileList], False, False);
			end;
			Key := KeyPageDown; {Simulate key press for moving view down}
		end;

		if Key = KeyUp then
		begin
			if ActiveList = FileList then
				FileMoveSelection(txtList[FileList], DirectionUp)
			else
				FileMoveSelection(txtList[FolderList], DirectionUp);
		end;

		if Key = KeyDown then
		begin
			if ActiveList = FileList then
				FileMoveSelection(txtList[FileList], DirectionDown)
			else
				FileMoveSelection(txtList[FolderList], DirectionDown);
		end;

		if Key = KeyHome then
		begin
			if ActiveList = FileList then
			begin
				ListStartPos[FileList] := 1;
				ListSelection[FileList] := 1;
				DrawFileList(txtList[FileList], True, True);
			end
			else
			begin
				ListStartPos[FolderList] := 1;
				ListSelection[FolderList] := 1;
				DrawFileList(txtList[FolderList], True, True);
			end;
		end;

		if Key = KeyEnd then
		begin
			if ActiveList = FileList then
			begin
				ListStartPos[FileList] := ListCount[FileList] - MaxVisibleItems + 1;
				if ListStartPos[FileList] < 1 then
					ListStartPos[FileList] := 1;
				ListSelection[FileList] := ListCount[FileList];
				DrawFileList(txtList[FileList], True, True);
			end
			else
			begin
				ListStartPos[FolderList] := ListCount[FolderList] - MaxVisibleItems + 1;
				if ListStartPos[FolderList] < 1 then
					ListStartPos[FolderList] := 1;
				ListSelection[FolderList] := ListCount[FolderList];
				DrawFileList(txtList[FolderList], True, True);
			end;
		end;

		if Key = KeyPageUp then
		begin
			if ActiveList = FileList then
			begin
				FileMoveSelection(txtList[FileList], DirectionUp * MaxVisibleItems);
			end
			else
			begin
				FileMoveSelection(txtList[FolderList], DirectionUp * MaxVisibleItems);
			end;
		end;

		if Key = KeyPageDown then
		begin
			if ActiveList = FileList then
			begin
				FileMoveSelection(txtList[FileList], DirectionDown * MaxVisibleItems);
			end
			else
			begin
				FileMoveSelection(txtList[FolderList], DirectionDown * MaxVisibleItems);
			end;
		end;

		if Key = KeyAltF then
		begin
		if ActiveList <> FileList then
			begin
				ActiveList := FileList;
				DrawFileList(txtList[FolderList], False, False);
				DrawFileList(txtList[FileList], True, False);
			end;
		end;

		if Key = KeyAltO then
		begin
			if ActiveList <> FolderList then
			begin
				ActiveList := FolderList;
				DrawFileList(txtList[FileList], False, False);
				DrawFileList(txtList[FolderList], True, False);
			end;
		end;

		if Key = KeyTab then
		begin
			if ActiveList = FileList then
			begin
				ActiveList := FolderList;
				DrawFileList(txtList[FileList], False, False);
				DrawFileList(txtList[FolderList], True, False);
			end
			else
			begin
				ActiveList := FileList;
				DrawFileList(txtList[FolderList], False, False);
				DrawFileList(txtList[FileList], True, False);
			end;
		end;

		if ObjTxtClick(txtPattern) or (Key = KeyAltP) then
		begin
			ObjEditTxt(txtPattern, txtPatternText);
			if txtPatternText <> Pattern then
			begin
				Pattern := txtPatternText;
				GetChildFiles(Path, Pattern);
				ListStartPos[FileList] := 1;
				ListSelection[FileList] := 1;
				DrawFileList(txtList[FileList], True, True);
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