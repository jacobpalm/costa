unit FileDlg;

interface

uses
	Costalib, UIWindow, UIButton, UITxtbox, UIList, UIIcon;

function FileSelect(DefaultPattern, StartPath: string; IconSelect: boolean): string;

{Only the FileSelect function is exported, the rest are internal}

implementation

uses
	DOS, Graph;

const
	FileList        = 0;
	DirList         = -1;

	MaxNameLength   = 12; {8.3 filename including the dot}

	CAP_PATTERN     = #127 + 'Pattern';
	CAP_DRIVE       = 'D' + #127 + 'rive';
	CAP_FILES       = #127 + 'Files';
	CAP_DIRS        = #127 + 'Directories';
	CAP_SELECT      = #127 + 'Select';
	CAP_CANCEL      = #127 + 'Cancel';

var
	WinFileSelect: TWindow;
	TxtDrive, TxtPattern: TTextbox;
	BtnSelect, BtnCancel: TButton;
	BtnFilePrev, BtnFileNext: TButton;
	BtnDirPrev, BtnDirNext: TButton;
	HkUp, HkDown, HkPageUp, HkPageDown, HkHome, HkEnd, HkTab: THotkey;
	
	List:           array[-1..0] of TList;
	ActiveList:     Integer;

	PreviewShown:   boolean;
	ImgPreview:     TIcon;

	Path, Pattern:  String;
	Drive:          String[1];
	ReturnedFile:   String;

	FileSelectDone: Boolean;

procedure GetChildFiles(Path: String; FilePattern: String);
var
	FileInfo: SearchRec;
begin
	{Clear previous file list}
	List[FileList].ClearItems;

	FindFirst(Path + '\' + FilePattern, Archive, FileInfo);
	while DosError = 0 do
	begin
		if (FileInfo.Attr and Directory) = 0 then
		begin
			{If CON is opened the program will crash}
			if FileInfo.Name <> 'CON' then
				List[FileList].AddItem(FileInfo.Name);
		end;
		FindNext(FileInfo);
	end;
end;

procedure GetChildDirs(Path: String);
var
	DirInfo: SearchRec;
begin
	{Clear previous directory list}
	List[DirList].ClearItems;
	
	{Add '..' for parent directory if not at root}
	if Length(Path) > 3 then
		List[DirList].AddItem('..');
	
	FindFirst(Path + '\*.*', Directory, DirInfo);
	while DosError = 0 do
	begin
		if ((DirInfo.Attr and Directory) <> 0) and (DirInfo.Name <> '.') and (DirInfo.Name <> '..') then
			List[DirList].AddItem(DirInfo.Name);
		
		FindNext(DirInfo);
	end;
end;

procedure DrawPreview(Sender: PBaseObject); far;
var
	SelectedFile: String;
	FDir: DirStr;
	FName: NameStr;
	FExt: ExtStr;
begin
	SelectedFile := List[FileList].GetSelectedItem;
	if (Path = ProgramPath + 'ICONS') and (Length(SelectedFile) <> 0) then
	begin
		FSplit(SelectedFile, FDir, FName, FExt);
		if (Length(FName) <> 0) and (FExt = '.BIN') then
		begin
			ImgPreview.SetIcon(FName);
			PreviewShown := true;
			exit;
		end;
	end;
	
	{Either there is no selection, or the preview should be hidden - so so if previously shown}
	if (PreviewShown) then
	begin
		MouseHide;
		SetFillStyle(SolidFill, Thm.Win);
		Bar(ImgPreview.Left - 1, ImgPreview.Top - 1, ImgPreview.Left + 32, ImgPreview.Top + 32);
		MouseShow;
		PreviewShown := false;
	end;
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
		List[FileList].Draw;
		List[DirList].Draw;
		SetDrive := True;
		DrawPreview(nil);
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
		List[FileList].Draw;
		List[DirList].Draw;
	end;
	DrawPreview(nil);
end;
procedure SetActiveList(TargetList: Integer);
begin
	List[TargetList].SetState(LsActive);
	List[not TargetList].SetState(LsInactive);
	ActiveList := TargetList;
end;

procedure ListClicked(Sender: PBaseObject); far;
var
	ClickedList: Integer;
begin
	if Sender = @List[FileList] then
		ClickedList := FileList
	else
		ClickedList := DirList;
	
	{If the list is not active, make it active}
	if ActiveList <> ClickedList then
		SetActiveList(ClickedList);
end;

procedure ListDblClicked(Sender: PBaseObject); far;
var
	TargetList: Integer;
	SelectedItemName: String[MaxNameLength];
begin
	{If sender is one of the lists, use that list as target - otherwise
	 use the currently active list}
	if Sender = @List[FileList] then
		TargetList := FileList
	else if Sender = @List[DirList] then
		TargetList := DirList
	else
		TargetList := ActiveList;
	
	SelectedItemName := List[TargetList].GetSelectedItem;
	if SelectedItemName <> '' then
	begin
		if TargetList = FileList then
		begin
			{Make sure path ends with a backslash}
			if (Path[Length(Path)] <> '\') then
				Path := Path + '\';
			ReturnedFile := Path + SelectedItemName;
			FileSelectDone := True;
		end
		else
			SetDir(SelectedItemName);
	end;
end;

procedure BtnCancelClick(Sender: PBaseObject); far;
begin
	FileSelectDone := True;
end;

procedure BtnDirectionClick(Sender: PBaseObject); far;
begin
	{Activate the list to which the button belongs}
	if (Sender = @BtnFilePrev) or (Sender = @BtnFileNext) then
		SetActiveList(FileList)
	else
		SetActiveList(DirList);

	{Scroll the active list in the appropriate direction}
	if (Sender = @BtnFilePrev) or (Sender = @BtnDirPrev) then
		List[ActiveList].MoveSelection(PageUp)
	else
		List[ActiveList].MoveSelection(PageDown);
end;

procedure TxtDriveChange(Sender: PBaseObject); far;
begin
	if not SetDrive(TxtDrive.Text[1]) then
	begin
		TxtDrive.Text := Drive; {Restore original drive letter}
		MouseHide;
		TxtDrive.Draw;
		MouseShow;
	end;
end;

procedure TxtPatternChange(Sender: PBaseObject); far;
begin
	Pattern := TxtPattern.Text;
	GetChildFiles(Path, Pattern);
	List[FileList].Draw;
	DrawPreview(nil);
end;

Procedure HkDirectionPress(Sender: PBaseObject); far;
begin

	if Sender = @HkUp then
		List[ActiveList].MoveSelection(Up);

	if Sender = @HkDown then
		List[ActiveList].MoveSelection(Down);

	if Sender = @HkHome then
		List[ActiveList].MoveSelection(First);

	if Sender = @HkEnd then
		List[ActiveList].MoveSelection(Last);

	if Sender = @HkPageUp then
		List[ActiveList].MoveSelection(PageUp);

	if Sender = @HkPageDown then
		List[ActiveList].MoveSelection(PageDown);
end;

procedure HkTabPress(Sender: PBaseObject); far;
begin
	SetActiveList(not ActiveList);
end;

function FileSelect(DefaultPattern, StartPath: string; IconSelect: boolean): string;
var
	OriginalPath: string;
	I: Integer;
	X1, Y1, X2, Y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Key: string;
begin
	FileSelectDone := False;
	ReturnedFile := '';
	PreviewShown := false;

	WinFileSelect.Init(sizeCenter, sizeCenter, 468, 270);
	TxtPattern.Init(101, WinFileSelect.Top + 28, 150, SizeDefault, CAP_PATTERN);
	TxtPattern.Init(101, WinFileSelect.Top + 28, 150, SizeDefault, CAP_PATTERN);
	TxtPattern.AddHotkey(KeyAltP);
	TxtPattern.OnChange := TxtPatternChange;
	TxtPattern.MaxLen := 12; {8.3 including the dot}
	TxtDrive.Init(272, WinFileSelect.Top + 28, 150, SizeDefault, CAP_DRIVE);
	TxtDrive.AddHotkey(KeyAltR);
	TxtDrive.OnChange := TxtDriveChange;
	TxtDrive.MaxLen := 1;
	List[FileList].Init(101, WinFileSelect.Top + 71, 150, 185);
	List[FileList].AddHotkey(KeyAltF);
	List[FileList].OnChange := DrawPreview;
	List[FileList].OnClick := ListClicked;
	List[FileList].OnDoubleClick := ListDblClicked;
	List[DirList].Init(272, WinFileSelect.Top + 71, 150, 185);
	List[DirList].AddHotkey(KeyAltD);
	List[DirList].OnClick := ListClicked;
	List[DirList].OnDoubleClick := ListDblClicked;
	BtnSelect.Init(448, WinFileSelect.Top + 28, SizeDefault, SizeDefault, CAP_SELECT);
	BtnSelect.AddHotkey(KeyAltS);
	BtnSelect.AddHotkey(KeyEnter);
	BtnSelect.OnClick := ListDblClicked;
	BtnCancel.Init(448, WinFileSelect.Top + 58, SizeDefault, SizeDefault, CAP_CANCEL);
	BtnCancel.AddHotkey(KeyAltC);
	BtnCancel.AddHotkey(KeyEscape);
	BtnCancel.OnClick := BtnCancelClick;
	BtnFilePrev.Init(253, List[FileList].Top, 14, 91, CharArrowUp);
	BtnFilePrev.OnClick := BtnDirectionClick;
	BtnFileNext.Init(253, List[FileList].Top + 94, 14, 91, CharArrowDown);
	BtnFileNext.OnClick := BtnDirectionClick;
	BtnDirPrev.Init(424, List[DirList].Top, 14, 91, CharArrowUp);
	BtnDirPrev.OnClick := BtnDirectionClick;
	BtnDirNext.Init(424, List[DirList].Top + 94, 14, 91, CharArrowDown);
	BtnDirNext.OnClick := BtnDirectionClick;
	ImgPreview.Init(BtnCancel.Left + 30, BtnCancel.Top + 50, '');
	HkUp.Init(KeyUp);
	HkUp.OnClick := HkDirectionPress;
	HkDown.Init(KeyDown);
	HkDown.OnClick := HkDirectionPress;
	HkPageUp.Init(KeyPageUp);
	HkPageUp.OnClick := HkDirectionPress;
	HkPageDown.Init(KeyPageDown);
	HkPageDown.OnClick := HkDirectionPress;
	HkHome.Init(KeyHome);
	HkHome.OnClick := HkDirectionPress;
	HkEnd.Init(KeyEnd);
	HkEnd.OnClick := HkDirectionPress;
	HkTab.Init(KeyTab);
	HkTab.AddHotkey(KeyShiftTab);
	HkTab.OnClick := HkTabPress;
	
	GetDir(0, OriginalPath); {Save to restore later}
	Path := OriginalPath;

	Drive := Copy(Path, 1, 1);
	Pattern := DefaultPattern;
	TxtDrive.Text := Drive;
	TxtPattern.Text := DefaultPattern;
	ActiveList := FileList;
	List[FileList].SetState(LsActive);
	ReturnedFile := '';

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
	List[FileList].Draw;
	List[DirList].Draw;
	BtnSelect.Draw;
	BtnCancel.Draw;
	BtnFilePrev.Draw;
	BtnFileNext.Draw;
	BtnDirPrev.Draw;
	BtnDirNext.Draw;
	Print(CAP_FILES, 101, WinFileSelect.Top + 57, Thm.WinText);
	Print(CAP_DIRS, 272, WinFileSelect.Top + 57, Thm.WinText);
	MouseShow;

	{If path provided, use it - otherwise use current directory}
	if Length(StartPath) > 0 then
		SetDir(StartPath)
	else
		SetDir(Path);

	repeat
		Key := GetKey;
		HotkeyPressed := Key; {DEBUG - move to event loop later}

		List[FileList].CheckEvent;
		List[DirList].CheckEvent;
		BtnSelect.CheckEvent;
		BtnCancel.CheckEvent;
		BtnFilePrev.CheckEvent;
		BtnFileNext.CheckEvent;
		BtnDirPrev.CheckEvent;
		BtnDirNext.CheckEvent;
		TxtPattern.CheckEvent;
		TxtDrive.CheckEvent;

		HkUp.CheckEvent;
		HkDown.CheckEvent;
		HkPageUp.CheckEvent;
		HkPageDown.CheckEvent;
		HkHome.CheckEvent;
		HkEnd.CheckEvent;
		HkTab.CheckEvent;

	until FileSelectDone;

	FileSelect := ReturnedFile;
	
	{Restore background}
	MouseHide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;

	{$I-}
	ChDir(OriginalPath); {Restore original path}
	{$I+}
end;

end.