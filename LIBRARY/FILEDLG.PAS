unit FileDlg;

interface

uses
	Costalib, UIButton, UITxtbox, UILabel, UIList, UIIcon;

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

procedure GetChildFiles(Path: String; FilePattern: String);
var
	FileInfo: SearchRec;
begin
	{Clear previous file list}
	List[FileList]^.ClearItems;

	FindFirst(Path + '\' + FilePattern, Archive, FileInfo);
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
	
	FindFirst(Path + '\*.*', Directory, DirInfo);
	while DosError = 0 do
	begin
		if ((DirInfo.Attr and Directory) <> 0) and (DirInfo.Name <> '.') and (DirInfo.Name <> '..') then
			List[DirList]^.AddItem(DirInfo.Name);
		
		FindNext(DirInfo);
	end;
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
			ImgPreview^.RemoveState(SHidden);
			ImgPreview^.SetIcon(FName);
			exit;
		end;
	end;
	
	{Either there is no selection, or the preview should be hidden - do so if previously shown}
	if not ImgPreview^.GetState(SHidden) then
	begin
		Mouse.Hide;
		SetFillStyle(SolidFill, Thm.Win);
		ImgPreview^.GetPos(X1, Y1, True);
		Bar(X1 - 1, Y1 - 1, X1 + 32, Y1 + 32);
		Mouse.Show;
		ImgPreview^.AddState(SHidden);
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
		Mouse.Hide;
		List[FileList]^.Draw;
		List[DirList]^.Draw;
		Mouse.Show;
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
		Drive := Copy(Path, 1, 1);
		TxtDrive^.SetText(Drive);
		Mouse.Hide;
		List[FileList]^.Draw;
		List[DirList]^.Draw;
		TxtDrive^.Draw;
		Mouse.Show;
		Drive := Copy(Path, 1, 1);
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
	NewDrive := TxtDrive^.GetText;
	if not SetDrive(NewDrive[1]) then
	begin
		TxtDrive^.SetText(Drive); {Restore original drive letter}
		Mouse.Hide;
		TxtDrive^.Draw;
		Mouse.Show;
	end;
end;

procedure TxtPatternChange(Sender: PUIObject); far;
begin
	Pattern := TxtPattern^.GetText;
	if Length(Pattern) = 0 then
		Pattern := '*.*';
	GetChildFiles(Path, Pattern);
	Mouse.Hide;
	List[FileList]^.Draw;
	Mouse.Show;
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
var
	X1, Y1, X2, Y2: Integer;
begin
{Init window and save coordinates for later use}
	New(WinFileSelect, Init(0, 0, NoParent));
	with WinFileSelect^ do
	begin
		SetSize(468, 270);
		Center(OrBoth);
		SaveBackdrop;
		GetPos(X1, Y1, True);
		GetSize(X2, Y2);
		SetOnDraw(WinFileSelectDraw);
	end;
	Inc(X2, X1);
	Inc(Y2, Y1);

	New(TxtPattern, Init(15, 28, CAP_PATTERN, WinFileSelect));
	with TxtPattern^ do
	begin
		SetSize(150, SizeRetain);
		AddHotkey(KeyAltP);
		SetText(Pattern);
		SetOnChange(TxtPatternChange);
		SetMaxLength(12); {8.3 including the dot}
	end;

	New(TxtDrive, Init(187, 28, CAP_DRIVE, WinFileSelect));
	with TxtDrive^ do
	begin
		SetSize(150, SizeRetain);
		AddHotkey(KeyAltR);
		SetText(Drive);
		SetOnChange(TxtDriveChange);
		SetMaxLength(1);
	end;

	New(LblFiles, Init(16, 57, CAP_FILES, WinFileSelect));
	New(LblDirs, Init(187, 57, CAP_DIRS, WinFileSelect));

	New(List[FileList], Init(16, 71, WinFileSelect));
	with List[FileList]^ do
	begin
		SetSize(150, 185);
		AddHotkey(KeyAltF);
		SetOnChange(DrawPreview);
		SetOnClick(ListClicked);
		SetOnDoubleClick(ListDblClicked);
	end;

	New(List[DirList], Init(187, 71, WinFileSelect));
	with List[DirList]^ do
	begin
		SetSize(150, 185);
		AddHotkey(KeyAltD);
		SetOnClick(ListClicked);
		SetOnDoubleClick(ListDblClicked);
	end;

	New(BtnSelect, Init(363, 28, CAP_SELECT, WinFileSelect));
	with BtnSelect^ do
	begin
		AddHotkey(KeyAltS);
		AddHotkey(KeyEnter);
		SetOnClick(ListDblClicked);
	end;

	New(BtnCancel, Init(363, 58, CAP_CANCEL, WinFileSelect));
	with BtnCancel^ do
	begin
		AddHotkey(KeyAltC);
		AddHotkey(KeyEscape);
		SetOnClick(BtnCancelClick);
	end;

	New(BtnFilePrev, Init(168, 71, CharArrowUp, WinFileSelect));
	with BtnFilePrev^ do
	begin
		SetSize(14, 91);
		SetOnClick(BtnDirectionClick);
	end;

	New(BtnFileNext, Init(168, 71 + 94, CharArrowDown, WinFileSelect));
	with BtnFileNext^ do
	begin
		SetSize(14, 91);
		SetOnClick(BtnDirectionClick);
	end;

	New(BtnDirPrev, Init(339, 71, CharArrowUp, WinFileSelect));
	with BtnDirPrev^ do
	begin
		SetSize(14, 91);
		SetOnClick(BtnDirectionClick);
	end;

	New(BtnDirNext, Init(339, 71 + 94, CharArrowDown, WinFileSelect));
	with BtnDirNext^ do
	begin
		SetSize(14, 91);
		SetOnClick(BtnDirectionClick);
	end;

	New(ImgPreview, Init(393, 108, '', WinFileSelect));
	ImgPreview^.AddState(SHidden);
	
	New(HkUp, Init(KeyUp, WinFileSelect));
	HkUp^.SetOnClick(HkDirectionPress);
	
	New(HkDown, Init(KeyDown, WinFileSelect));
	HkDown^.SetOnClick(HkDirectionPress);
	
	New(HkPageUp, Init(KeyPageUp, WinFileSelect));
	HkPageUp^.SetOnClick(HkDirectionPress);
	
	New(HkPageDown, Init(KeyPageDown, WinFileSelect));
	HkPageDown^.SetOnClick(HkDirectionPress);
	
	New(HkHome, Init(KeyHome, WinFileSelect));
	HkHome^.SetOnClick(HkDirectionPress);
	
	New(HkEnd, Init(KeyEnd, WinFileSelect));
	HkEnd^.SetOnClick(HkDirectionPress);
	
	New(HkTab, Init(KeyTab, WinFileSelect));
	with HkTab^ do
	begin
		AddHotkey(KeyShiftTab);
		SetOnClick(HkTabPress);
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