unit FileDlg;

interface

uses
	Costalib, UIButton, UITxtbox, UILabel, UIList, UIIcon, MsgDlg;

function FileSelect(DefaultPattern, StartPath: string): string;

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

	MSG_ERROR_TITLE = 'Error';
	MSG_DOS_ERROR   = '%s while trying to read' + #13 + '%s';
	MSG_DRIVE_ERROR = 'Drive %s: not ready. Make sure there is a' + #13 +
	                  'disk in the drive.';

var
	WinFileSelect:  PWindow;
	TxtDrive,
	TxtPattern:     PTextbox;
	BtnSelect,
	BtnCancel,
	BtnFilePrev,
	BtnFileNext,
	BtnDirPrev,
	BtnDirNext:     PButton;
	LblFiles,
	LblDirs:        PLabel;
	ImgPreview:     PIcon;
	HkUp,
	HkDown,
	HkPageUp,
	HkPageDown,
	HkHome,
	HkEnd,
	HkTab:          PHotkey;

	List:           array[-1..0] of PList;
	ActiveList:     Integer;

	Path,
	Pattern:        String;
	Drive:          String[1];
	ReturnedFile:   String;

procedure HandleDosError(ErrorCode: Integer; Path: String);
var
	ErrMsg: String;
begin
	ErrMsg := Replace(MSG_DOS_ERROR, Placeholder, GetDosErrorMsg(ErrorCode));
	ErrMsg := Replace(ErrMsg, Placeholder, Path);
	MsgBox(MSG_ERROR_TITLE, ErrMsg, MsgError);
end;

procedure GetChildFiles(Path: String; FilePattern: String);
var
	FileInfo: SearchRec;
begin
	{Clear previous file list}
	List[FileList]^.ClearItems;

	{Add backslash if missing}
	if (Path[Length(Path)] <> '\') then
		Path := Path + '\';

	FindFirst(Path + FilePattern, Archive, FileInfo);
	{If an error other than 18 (no files found) occurred, show message}
	if (DosError > 0) and (DosError <> 18) then
	begin
		HandleDosError(DosError, Path);
		exit;
	end;
	while DosError = 0 do
	begin
		if (FileInfo.Attr and Directory) = 0 then
		begin
			{If CON is opened the program will crash}
			if FileInfo.Name <> 'CON' then
				List[FileList]^.AddItem(FileInfo.Name);
		end;
		FindNext(FileInfo);
	end;
	{Trigger redraw of list}
	List[FileList]^.AddState(SDirty);
end;

procedure GetChildDirs(Path: String);
var
	DirInfo: SearchRec;
begin
	{Clear previous directory list}
	List[DirList]^.ClearItems;

	{Add '..' for parent directory if not at root}
	if Length(Path) > 3 then
		List[DirList]^.AddItem('..');

	{Add backslash if missing}
	if (Path[Length(Path)] <> '\') then
		Path := Path + '\';

	FindFirst(Path + '*.*', Directory, DirInfo);
	{If an error other than 18 (no files found) occurred, show message}
	if (DosError > 0) and (DosError <> 18) then
	begin
		HandleDosError(DosError, Path);
		exit;
	end;
	while DosError = 0 do
	begin
		if ((DirInfo.Attr and Directory) <> 0) and (DirInfo.Name <> '.') and (DirInfo.Name <> '..') then
			List[DirList]^.AddItem(DirInfo.Name);

		FindNext(DirInfo);
	end;
	{Trigger redraw of list}
	List[DirList]^.AddState(SDirty);
end;

procedure DrawPreview(Sender: PUIObject); far;
var
	SelectedFile: String;
	FDir: DirStr;
	FName: NameStr;
	FExt: ExtStr;
	X1, Y1: Integer;
begin
	SelectedFile := List[FileList]^.GetSelectedItem;
	if (Path = ProgramPath + 'ICONS') and (Length(SelectedFile) <> 0) then
	begin
		FSplit(SelectedFile, FDir, FName, FExt);
		if (Length(FName) <> 0) and (FExt = '.BIN') then
		begin
			ImgPreview^.SetIcon(FName);
			exit;
		end;
	end;

	{Either there is no selection, or the preview should be hidden}
	ImgPreview^.SetIcon('');
end;

function SetDrive(DriveLetter: Char): Boolean;
var
	DriveNum, ErrorCode: Integer;
	DiskCheck: LongInt;
	Int24Old: Pointer;
begin
	SetDrive := false;
	DriveLetter := UpCase(DriveLetter);
	if (DriveLetter < 'A') or (DriveLetter > 'Z') then
		exit;

	DriveNum := Ord(DriveLetter) - 64; {Substracting 64 from ASCII code makes A=1, B=2 etc.}
	DiskCheck := DiskFree(DriveNum);

	if DiskCheck = -1 then
	begin
		MsgBox(MSG_ERROR_TITLE, Replace(MSG_DRIVE_ERROR, Placeholder, DriveLetter), msgError);
		exit;
	end;

	{$I-}
	ChDir(DriveLetter + ':\');
	{$I+}
	ErrorCode := IOResult;
	if ErrorCode = 0 then
	begin
		GetDir(0, Path);
		Drive := DriveLetter;
		GetChildFiles(Path, Pattern);
		GetChildDirs(Path);
		SetDrive := True;
		DrawPreview(nil);
	end
	else
	begin
		ChDir(Path); {Restore original path if drive change fails}
		HandleDosError(ErrorCode, DriveLetter + ':\');
	end;
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
		Drive := Copy(Path, 1, 1);
		TxtDrive^.Text := Drive;    {Set directly and add dirty state to avoid triggering change event}
		TxtDrive^.AddState(SDirty);
	end
	else
	begin
		HandleDosError(DosError, Path);
	end;
	DrawPreview(nil);
end;
procedure SetActiveList(TargetList: Integer);
begin
	List[TargetList]^.SetListActive(True);
	List[not TargetList]^.SetListActive(False);
	ActiveList := TargetList;
end;

procedure ListClicked(Sender: PUIObject); far;
var
	ClickedList: Integer;
begin
	if Sender = PUIObject(List[FileList]) then
		ClickedList := FileList
	else
		ClickedList := DirList;

	{If the list is not active, make it active}
	if ActiveList <> ClickedList then
		SetActiveList(ClickedList);
end;

procedure ListDblClicked(Sender: PUIObject); far;
var
	TargetList: Integer;
	SelectedItemName: String[MaxNameLength];
begin
	{If sender is one of the lists, use that list as target - otherwise
	 use the currently active list}
	if Sender = PUIObject(List[FileList]) then
		TargetList := FileList
	else if Sender = PUIObject(List[DirList]) then
		TargetList := DirList
	else
		TargetList := ActiveList;

	SelectedItemName := List[TargetList]^.GetSelectedItem;
	if SelectedItemName <> '' then
	begin
		if TargetList = FileList then
		begin
			{Make sure path ends with a backslash}
			if (Path[Length(Path)] <> '\') then
				Path := Path + '\';
			ReturnedFile := Path + SelectedItemName;
			WinFileSelect^.Close;
		end
		else
			SetDir(SelectedItemName);
	end;
end;

procedure BtnCancelClick(Sender: PUIObject); far;
begin
	WinFileSelect^.Close;
end;

procedure BtnDirectionClick(Sender: PUIObject); far;
begin
	{Activate the list to which the button belongs}
	if (Sender = PUIObject(BtnFilePrev)) or (Sender = PUIObject(BtnFileNext)) then
		SetActiveList(FileList)
	else
		SetActiveList(DirList);

	{Scroll the active list in the appropriate direction}
	if (Sender = PUIObject(BtnFilePrev)) or (Sender = PUIObject(BtnDirPrev)) then
		List[ActiveList]^.MoveSelection(PageUp)
	else
		List[ActiveList]^.MoveSelection(PageDown);
end;

procedure TxtDriveChange(Sender: PUIObject); far;
var
	NewDrive: String[1];
begin
	NewDrive := TxtDrive^.Text;
	if not SetDrive(NewDrive[1]) then
	begin
		TxtDrive^.SetText(Drive); {Restore original drive letter}
	end;
end;

procedure TxtPatternChange(Sender: PUIObject); far;
begin
	Pattern := TxtPattern^.Text;
	if Length(Pattern) = 0 then
		Pattern := '*.*';
	GetChildFiles(Path, Pattern);
	DrawPreview(nil);
end;

Procedure HkDirectionPress(Sender: PUIObject); far;
begin

	if Sender = PUIObject(HkUp) then
		List[ActiveList]^.MoveSelection(Up);

	if Sender = PUIObject(HkDown) then
		List[ActiveList]^.MoveSelection(Down);

	if Sender = PUIObject(HkHome) then
		List[ActiveList]^.MoveSelection(First);

	if Sender = PUIObject(HkEnd) then
		List[ActiveList]^.MoveSelection(Last);

	if Sender = PUIObject(HkPageUp) then
		List[ActiveList]^.MoveSelection(PageUp);

	if Sender = PUIObject(HkPageDown) then
		List[ActiveList]^.MoveSelection(PageDown);
end;

procedure HkTabPress(Sender: PUIObject); far;
begin
	SetActiveList(not ActiveList);
end;

procedure WinFileSelectDraw(Sender: PUIObject); far;
begin
	{When window is first drawn, set active directory to load list contents}
	List[ActiveList]^.SetListActive(True);
	Mouse.Hide;
	SetDir(Path);
end;

procedure InitUI;
begin
{Init window and save coordinates for later use}
	New(WinFileSelect, Init(0, 0, NoParent));
	with WinFileSelect^ do
	begin
		Width := 468;
		Height := 270;
		OnDraw := WinFileSelectDraw;
		Center(OrBoth);
		SaveBackdrop;
	end;

	New(TxtPattern, Init(15, 28, CAP_PATTERN, WinFileSelect));
	with TxtPattern^ do
	begin
		Width := 150;
		Text := Pattern;
		MaxLength := 12; {8.3 including the dot}
		OnChange := TxtPatternChange;
		AddHotkey(KeyAltP);
	end;

	New(TxtDrive, Init(187, 28, CAP_DRIVE, WinFileSelect));
	with TxtDrive^ do
	begin
		Width := 150;
		Text := Drive;
		MaxLength := 1;
		OnChange := TxtDriveChange;
		AddHotkey(KeyAltR);
	end;

	New(LblFiles, Init(16, 57, CAP_FILES, WinFileSelect));
	New(LblDirs, Init(187, 57, CAP_DIRS, WinFileSelect));

	New(List[FileList], Init(16, 71, WinFileSelect));
	with List[FileList]^ do
	begin
		Width := 150;
		Height := 185;
		OnChange := DrawPreview;
		OnClick := ListClicked;
		OnDoubleClick := ListDblClicked;
		AddHotkey(KeyAltF);
	end;

	New(List[DirList], Init(187, 71, WinFileSelect));
	with List[DirList]^ do
	begin
		Width := 150;
		Height := 185;
		OnClick := ListClicked;
		OnDoubleClick := ListDblClicked;
		AddHotkey(KeyAltD);
	end;

	New(BtnSelect, Init(363, 28, CAP_SELECT, WinFileSelect));
	with BtnSelect^ do
	begin
		OnClick := ListDblClicked;
		AddHotkey(KeyAltS);
		AddHotkey(KeyEnter);
	end;

	New(BtnCancel, Init(363, 58, CAP_CANCEL, WinFileSelect));
	with BtnCancel^ do
	begin
		OnClick := BtnCancelClick;
		AddHotkey(KeyAltC);
		AddHotkey(KeyEscape);
	end;

	New(BtnFilePrev, Init(168, 71, CharArrowUp, WinFileSelect));
	with BtnFilePrev^ do
	begin
		Width := 14;
		Height := 91;
		OnClick := BtnDirectionClick;
	end;

	New(BtnFileNext, Init(168, 71 + 94, CharArrowDown, WinFileSelect));
	with BtnFileNext^ do
	begin
		Width := 14;
		Height := 91;
		OnClick := BtnDirectionClick;
	end;

	New(BtnDirPrev, Init(339, 71, CharArrowUp, WinFileSelect));
	with BtnDirPrev^ do
	begin
		Width := 14;
		Height := 91;
		OnClick := BtnDirectionClick;
	end;

	New(BtnDirNext, Init(339, 71 + 94, CharArrowDown, WinFileSelect));
	with BtnDirNext^ do
	begin
		Width := 14;
		Height := 91;
		OnClick := BtnDirectionClick;
	end;

	New(ImgPreview, Init(393, 108, '', WinFileSelect));
	with ImgPreview^ do
	begin
		BorderStyle := BorNone;
		BgColor := Thm.Win;
	end;

	New(HkUp, Init(KeyUp, WinFileSelect));
	HkUp^.OnClick := HkDirectionPress;

	New(HkDown, Init(KeyDown, WinFileSelect));
	HkDown^.OnClick := HkDirectionPress;

	New(HkPageUp, Init(KeyPageUp, WinFileSelect));
	HkPageUp^.OnClick := HkDirectionPress;

	New(HkPageDown, Init(KeyPageDown, WinFileSelect));
	HkPageDown^.OnClick := HkDirectionPress;

	New(HkHome, Init(KeyHome, WinFileSelect));
	HkHome^.OnClick := HkDirectionPress;

	New(HkEnd, Init(KeyEnd, WinFileSelect));
	HkEnd^.OnClick := HkDirectionPress;

	New(HkTab, Init(KeyTab, WinFileSelect));
	with HkTab^ do
	begin
		OnClick := HkTabPress;
		AddHotkey(KeyShiftTab);
	end;
end;

function FileSelect(DefaultPattern, StartPath: string): string;
var
	OriginalPath: string;
begin
	ReturnedFile := '';
	Pattern := DefaultPattern;
	ActiveList := FileList;

	GetDir(0, OriginalPath); {Save to restore later}

	{If path provided, use it - otherwise use current directory}
	if Length(StartPath) > 0 then
		Path := StartPath
	else
		Path := OriginalPath;

	InitUI;

	WinFileSelect^.Run;
	Dispose(WinFileSelect, Done);
	WinFileSelect := nil;

	FileSelect := ReturnedFile;

	{$I-}
	ChDir(OriginalPath); {Restore original path}
	{$I+}
end;

end.