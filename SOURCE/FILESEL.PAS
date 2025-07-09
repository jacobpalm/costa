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
	txtFileList, txtFolderList: TextboxType;
	FolderCount, FileCount: Integer;
	SubFolders: array[1..MaxFolders] of String[12];
	SubFiles: array[1..MaxFiles] of String[12];
	FileListStartPos, FolderListStartPos: Integer;
	FileListSelection, FolderListSelection, ActiveList: Integer;
	Path, Pattern: String;
	Drive: String[1];
	TestOutput: String;
	ClickedDoubleTimer: Real;

procedure GetChildFiles(Path: String; FilePattern: String);
var
	FileInfo: SearchRec;
begin
	{Clear previous file list}
	FileCount := 0;
	FillChar(SubFiles, SizeOf(SubFiles), #0);

	FindFirst(Path + '\' + FilePattern, Archive, FileInfo);
	while DosError = 0 do
	begin
	if (FileInfo.Attr and Directory) = 0 then
	begin
		{If CON is opened the program will crash}
		if (FileCount < MaxFiles) and (FileInfo.Name <> 'CON') then
		begin
		Inc(FileCount);
		SubFiles[FileCount] := FileInfo.Name;
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
	FolderCount := 0;
	FillChar(SubFolders, SizeOf(SubFolders), #0);

	{Add '..' for parent directory if not at root}
	if Length(Path) > 3 then
	begin
	Inc(FolderCount);
	SubFolders[FolderCount] := '..';
	end;

	FindFirst(Path + '\*.*', Directory, FolderInfo);
	while DosError = 0 do
	begin
	if (FolderInfo.Attr and Directory) <> 0 then
	begin
		if (FolderInfo.Name <> '.') and (FolderInfo.Name <> '..') then
		begin
		if FolderCount < MaxFolders then
		begin
			Inc(FolderCount);
			SubFolders[FolderCount] := FolderInfo.Name
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
	TotalItems := FileCount;
	ListStartPos := FileListStartPos;
	ListSelection := FileListSelection;
	end
	else
	begin
	TotalItems := FolderCount;
	ListStartPos := FolderListStartPos;
	ListSelection := FolderListSelection;
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
	TotalItems := FileCount;
	ListStartPos := FileListStartPos;
	ListSelection := FileListSelection;
	end
	else
	begin
	TotalItems := FolderCount;
	ListStartPos := FolderListStartPos;
	ListSelection := FolderListSelection;
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
	FileListStartPos := ListStartPos;
	FileListSelection := ListSelection;
	end
	else
	begin
	FolderListStartPos := ListStartPos;
	FolderListSelection := ListSelection;
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
	TotalItems := FileCount;
	ListStartPos := FileListStartPos;
	ListSelection := FileListSelection;
	end
	else
	begin
	TotalItems := FolderCount;
	ListStartPos := FolderListStartPos;
	ListSelection := FolderListSelection;
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
			DrawFileList(txtFileList, False, False);
		end
		else
		begin
			ActiveList := FileList;
			DrawFileList(txtFolderList, False, False);
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
			FileListSelection := ClickedItem
			else
			FolderListSelection := ClickedItem;
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
		DrawFileList(txtFileList, True, True);
		DrawFileList(txtFolderList, False, True);
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
	ChDir(SubFolders[FolderListSelection]);
	{$I+}
	if IOResult = 0 then
	begin
		GetDir(0, Path);
		GetChildFiles(Path, Pattern);
		GetChildFolders(Path);
		FileListStartPos := 1;
		FileListSelection := 1;
		FolderListStartPos := 1;
		FolderListSelection := 1;
		DrawFileList(txtFileList, False, True);
		DrawFileList(txtFolderList, True, True);
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
	FolderListStartPos := 1;
	FileListStartPos := 1;
	FileListSelection := 1;
	FolderListSelection := 1;

	winFileSelect.Init(sizeCenter, sizeCenter, 468, 270);
	txtPattern.Init(101, winFileSelect.Pos.Top + 28, 150, sizeDefault);
	txtDrive.Init(272, winFileSelect.Pos.Top + 28, 150, sizeDefault);
	txtPattern.Init(101, winFileSelect.Pos.Top + 28, 150, sizeDefault);
	txtDrive.Init(272, winFileSelect.Pos.Top + 28, 150, sizeDefault);
	txtFileList.Init(101, winFileSelect.Pos.Top + 71, 150, 185);
	txtFolderList.Init(272, winFileSelect.Pos.Top + 71, 150, 185);
	btnSelect.Init(448, winFileSelect.Pos.Top + 28, sizeDefault, sizeDefault, HotkeySymbol + 'Select');
	btnCancel.Init(448, winFileSelect.Pos.Top + 58, sizeDefault, sizeDefault, HotkeySymbol + 'Cancel');
	btnFilePrev.Init(253, txtFileList.Pos.Top, 14, 91, #24);
	btnFileNext.Init(253, txtFileList.Pos.Top + 94, 14, 91, #25);
	btnFolderPrev.Init(424, txtFolderList.Pos.Top, 14, 91, #24);
	btnFolderNext.Init(424, txtFolderList.Pos.Top + 94, 14, 91, #25);
	txtDrive.MaxLen := 1;
	txtPattern.MaxLen := 12; {8.3 including the dot}

	{These are used in File.DrawList to differentiate lists... It's a dirty hack, but works}
	txtFileList.MaxLen := FileList;
	txtFolderList.MaxLen := FolderList;

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
	ObjDrawTxt(txtFileList, '', False);
	ObjDrawTxt(txtFolderList, '', False);
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
	DrawFileList(txtFileList, True, True);
	DrawFileList(txtFolderList, False, True);

	repeat
	Key := GetKey;

	if (MouseClicked > mbNone) and MouseInArea(txtFileList.Pos) then
	begin
		if FileMouseSelection(txtFileList) then
			Key := KeyEnter; {Double-clicked file, select it}
	end;

	if (MouseClicked > mbNone) and MouseInArea(txtFolderList.Pos) then
	begin
		if FileMouseSelection(txtFolderList) then
			Key := KeyEnter; {Double-clicked folder, change to it}
	end;

	if ObjBtnClick(btnSelect) or (Key = KeyAltS) or (Key = KeyEnter) then
	begin
		if (ActiveList = FileList) and (SubFiles[FileListSelection] <> '') then
		begin
			{Make sure path ends with a backslash}
			if (Path[Length(Path)] <> '\') then
				Path := Path + '\';
			FileSelect := Path + SubFiles[FileListSelection];
			Break;
		end;
		
		if (ActiveList = FolderList) and (SubFolders[FolderListSelection] <> '') then
		begin
			FileSetFolder(SubFolders[FolderListSelection]);
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
			DrawFileList(txtFolderList, False, False);
		end;
		Key := KeyUp; {Simulate key press for moving selection up}
	end;

	if ObjBtnClick(btnFileNext) then
	begin
		if not ActiveList = FileList then
		begin
			ActiveList := FileList;
			DrawFileList(txtFolderList, False, False);
		end;
		Key := KeyDown; {Simulate key press for moving selection down}
	end;

	if ObjBtnClick(btnFolderPrev) then
	begin
		if not ActiveList = FolderList then
		begin
			ActiveList := FolderList;
			DrawFileList(txtFileList, False, False);
		end;
		Key := KeyPageUp; {Simulate key press for moving view up}
	end;

	if ObjBtnClick(btnFolderNext) then
	begin
		if not ActiveList = FolderList then
		begin
			ActiveList := FolderList;
			DrawFileList(txtFileList, False, False);
		end;
		Key := KeyPageDown; {Simulate key press for moving view down}
	end;

	if Key = KeyUp then
	begin
		if ActiveList = FileList then
			FileMoveSelection(txtFileList, DirectionUp)
		else
			FileMoveSelection(txtFolderList, DirectionUp);
	end;

	if Key = KeyDown then
	begin
		if ActiveList = FileList then
			FileMoveSelection(txtFileList, DirectionDown)
		else
			FileMoveSelection(txtFolderList, DirectionDown);
	end;

	if Key = KeyHome then
	begin
		if ActiveList = FileList then
		begin
			FileListStartPos := 1;
			FileListSelection := 1;
			DrawFileList(txtFileList, True, True);
		end
		else
		begin
			FolderListStartPos := 1;
			FolderListSelection := 1;
			DrawFileList(txtFolderList, True, True);
		end;
	end;

	if Key = KeyEnd then
	begin
		if ActiveList = FileList then
		begin
			FileListStartPos := FileCount - MaxVisibleItems + 1;
			if FileListStartPos < 1 then
				FileListStartPos := 1;
			FileListSelection := FileCount;
			DrawFileList(txtFileList, True, True);
		end
		else
		begin
			FolderListStartPos := FolderCount - MaxVisibleItems + 1;
			if FolderListStartPos < 1 then
				FolderListStartPos := 1;
			FolderListSelection := FolderCount;
			DrawFileList(txtFolderList, True, True);
		end;
	end;

	if Key = KeyPageUp then
	begin
		if ActiveList = FileList then
		begin
			FileMoveSelection(txtFileList, DirectionUp * MaxVisibleItems);
		end
		else
		begin
			FileMoveSelection(txtFolderList, DirectionUp * MaxVisibleItems);
		end;
	end;

	if Key = KeyPageDown then
	begin
		if ActiveList = FileList then
		begin
			FileMoveSelection(txtFileList, DirectionDown * MaxVisibleItems);
		end
		else
		begin
			FileMoveSelection(txtFolderList, DirectionDown * MaxVisibleItems);
		end;
	end;

	if Key = KeyAltF then
	begin
	if ActiveList <> FileList then
		begin
			ActiveList := FileList;
			DrawFileList(txtFolderList, False, False);
			DrawFileList(txtFileList, True, False);
		end;
	end;

	if Key = KeyAltO then
	begin
		if ActiveList <> FolderList then
		begin
			ActiveList := FolderList;
			DrawFileList(txtFileList, False, False);
			DrawFileList(txtFolderList, True, False);
		end;
	end;

	if Key = KeyTab then
	begin
		if ActiveList = FileList then
		begin
			ActiveList := FolderList;
			DrawFileList(txtFileList, False, False);
			DrawFileList(txtFolderList, True, False);
		end
		else
		begin
			ActiveList := FileList;
			DrawFileList(txtFolderList, False, False);
			DrawFileList(txtFileList, True, False);
		end;
	end;

	if ObjTxtClick(txtPattern) or (Key = KeyAltP) then
	begin
		ObjEditTxt(txtPattern, txtPatternText);
		if txtPatternText <> Pattern then
		begin
			Pattern := txtPatternText;
			GetChildFiles(Path, Pattern);
			FileListStartPos := 1;
			FileListSelection := 1;
			DrawFileList(txtFileList, True, True);
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