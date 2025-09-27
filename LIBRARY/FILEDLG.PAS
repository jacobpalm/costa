unit FileDlg;

interface

uses
	Costalib, UIButton, UITxtbox, UIList, UIIcon;

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

procedure DrawPreview(Sender: PUIObject); far;
var
	SelectedFile: String;
	FDir: DirStr;
	FName: NameStr;
	FExt: ExtStr;
	X1, Y1: Integer;
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
		Mouse.Hide;
		SetFillStyle(SolidFill, Thm.Win);
		ImgPreview.GetPos(X1, Y1, True);
		Bar(X1 - 1, Y1 - 1, X1 + 32, Y1 + 32);
		Mouse.Show;
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
	List[TargetList].SetListActive(True);
	List[not TargetList].SetListActive(False);
	ActiveList := TargetList;
end;

procedure ListClicked(Sender: PUIObject); far;
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

procedure ListDblClicked(Sender: PUIObject); far;
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

procedure BtnCancelClick(Sender: PUIObject); far;
begin
	FileSelectDone := True;
end;

procedure BtnDirectionClick(Sender: PUIObject); far;
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

procedure TxtDriveChange(Sender: PUIObject); far;
begin
	if not SetDrive(TxtDrive.Text[1]) then
	begin
		TxtDrive.Text := Drive; {Restore original drive letter}
		Mouse.Hide;
		TxtDrive.Draw;
		Mouse.Show;
	end;
end;

procedure TxtPatternChange(Sender: PUIObject); far;
begin
	Pattern := TxtPattern.Text;
	GetChildFiles(Path, Pattern);
	List[FileList].Draw;
	DrawPreview(nil);
end;

Procedure HkDirectionPress(Sender: PUIObject); far;
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

procedure HkTabPress(Sender: PUIObject); far;
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

	{Init window and save coordinates for later use}
	WinFileSelect.Init(0, 0, NoParent);
	WinFileSelect.SetSize(468, 270);
	WinFileSelect.GetPos(X1, Y1, True);
	WinFileSelect.GetSize(X2, Y2);
	Inc(X2, X1);
	Inc(Y2, Y1);

	TxtPattern.Init(101, Y1 + 28, CAP_PATTERN, @WinFileSelect);
	TxtPattern.SetSize(150, SizeRetain);
	TxtPattern.AddHotkey(KeyAltP);
	TxtPattern.OnChange := TxtPatternChange;
	TxtPattern.MaxLen := 12; {8.3 including the dot}
	TxtDrive.Init(272, Y1 + 28, CAP_DRIVE, @WinFileSelect);
	TxtDrive.SetSize(150, SizeRetain);
	TxtDrive.AddHotkey(KeyAltR);
	TxtDrive.OnChange := TxtDriveChange;
	TxtDrive.MaxLen := 1;
	List[FileList].Init(101, Y1 + 71, @WinFileSelect);
	List[FileList].SetSize(150, 185);
	List[FileList].AddHotkey(KeyAltF);
	List[FileList].OnChange := DrawPreview;
	List[FileList].OnClick := ListClicked;
	List[FileList].OnDoubleClick := ListDblClicked;
	List[DirList].Init(272, Y1 + 71, @WinFileSelect);
	List[DirList].SetSize(150, 185);
	List[DirList].AddHotkey(KeyAltD);
	List[DirList].OnClick := ListClicked;
	List[DirList].OnDoubleClick := ListDblClicked;
	BtnSelect.Init(448, Y1 + 28, CAP_SELECT, @WinFileSelect);
	BtnSelect.AddHotkey(KeyAltS);
	BtnSelect.AddHotkey(KeyEnter);
	BtnSelect.OnClick := ListDblClicked;
	BtnCancel.Init(448, Y1 + 58, CAP_CANCEL, @WinFileSelect);
	BtnCancel.AddHotkey(KeyAltC);
	BtnCancel.AddHotkey(KeyEscape);
	BtnCancel.OnClick := BtnCancelClick;
	BtnFilePrev.Init(253, Y1 + 71, CharArrowUp, @WinFileSelect);
	BtnFilePrev.SetSize(14, 91);
	BtnFilePrev.OnClick := BtnDirectionClick;
	BtnFileNext.Init(253, Y1 + 71 + 94, CharArrowDown, @WinFileSelect);
	BtnFileNext.SetSize(14, 91);
	BtnFileNext.OnClick := BtnDirectionClick;
	BtnDirPrev.Init(424, Y1 + 71, CharArrowUp, @WinFileSelect);
	BtnDirPrev.SetSize(14, 91);
	BtnDirPrev.OnClick := BtnDirectionClick;
	BtnDirNext.Init(424, Y1 + 71 + 94, CharArrowDown, @WinFileSelect);
	BtnDirNext.SetSize(14, 91);
	BtnDirNext.OnClick := BtnDirectionClick;
	ImgPreview.Init(448, Y1 + 108, '', @WinFileSelect);
	HkUp.Init(KeyUp, @WinFileSelect);
	HkUp.OnClick := HkDirectionPress;
	HkDown.Init(KeyDown, @WinFileSelect);
	HkDown.OnClick := HkDirectionPress;
	HkPageUp.Init(KeyPageUp, @WinFileSelect);
	HkPageUp.OnClick := HkDirectionPress;
	HkPageDown.Init(KeyPageDown, @WinFileSelect);
	HkPageDown.OnClick := HkDirectionPress;
	HkHome.Init(KeyHome, @WinFileSelect);
	HkHome.OnClick := HkDirectionPress;
	HkEnd.Init(KeyEnd, @WinFileSelect);
	HkEnd.OnClick := HkDirectionPress;
	HkTab.Init(KeyTab, @WinFileSelect);
	HkTab.AddHotkey(KeyShiftTab);
	HkTab.OnClick := HkTabPress;
	
	GetDir(0, OriginalPath); {Save to restore later}
	Path := OriginalPath;

	Drive := Copy(Path, 1, 1);
	Pattern := DefaultPattern;
	TxtDrive.Text := Drive;
	TxtPattern.Text := DefaultPattern;
	ActiveList := FileList;
	List[FileList].SetListActive(True);
	ReturnedFile := '';

	Mouse.Hide;

	{Save background to restore when window is closed}
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);

	WinFileSelect.Draw;
	{TxtPattern.Draw;
	TxtDrive.Draw;
	List[FileList].Draw;
	List[DirList].Draw;
	BtnSelect.Draw;
	BtnCancel.Draw;
	BtnFilePrev.Draw;
	BtnFileNext.Draw;
	BtnDirPrev.Draw;
	BtnDirNext.Draw;}
	{DEBUG - use captions instead of printing}
	Print(CAP_FILES, 101, Y1 + 57, Thm.WinText);
	Print(CAP_DIRS, 272, Y1 + 57, Thm.WinText);
	Mouse.Show;

	{If path provided, use it - otherwise use current directory}
	if Length(StartPath) > 0 then
		SetDir(StartPath)
	else
		SetDir(Path);

	repeat
		Key := GetKey;
		HotkeyInput := Key; {DEBUG - move to event loop later}

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
	Mouse.Hide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	Mouse.Show;

	{$I-}
	ChDir(OriginalPath); {Restore original path}
	{$I+}
end;

end.