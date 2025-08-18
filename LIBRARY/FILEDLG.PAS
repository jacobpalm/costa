unit FileDlg;

interface

uses
	Costalib, UIList;

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
	List:          array[-1..0] of TList;
	ActiveList:    Integer;

	PreviewShown:  boolean;
	ImgPreview:    TIcon;

	Path, Pattern: String;
	Drive:         String[1];

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
begin
	SelectedFile := List[FileList].GetSelectedItem;
	if (Path = ProgramPath + 'ICONS') and (Length(SelectedFile) <> 0) then
	begin
		FSplit(SelectedFile, FDir, FName, FExt);
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

procedure SetActiveList(TargetList: Integer);
begin
	List[TargetList].SetState(LsActive);
	List[not TargetList].SetState(LsInactive);
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
	List[FileList].Init(101, WinFileSelect.Top + 71, 150, 185);
	List[DirList].Init(272, WinFileSelect.Top + 71, 150, 185);
	List[FileList].OnChange := DrawPreview;
	List[FileList].OnClick := ListClicked;
	List[DirList].OnClick := ListClicked;
	BtnSelect.Init(448, WinFileSelect.Top + 28, SizeDefault, SizeDefault, CAP_SELECT);
	BtnCancel.Init(448, WinFileSelect.Top + 58, SizeDefault, SizeDefault, CAP_CANCEL);
	BtnFilePrev.Init(253, List[FileList].Top, 14, 91, CharArrowUp);
	BtnFileNext.Init(253, List[FileList].Top + 94, 14, 91, CharArrowDown);
	BtnDirPrev.Init(424, List[DirList].Top, 14, 91, CharArrowUp);
	BtnDirNext.Init(424, List[DirList].Top + 94, 14, 91, CharArrowDown);
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

		List[FileList].CheckEvent;
		List[DirList].CheckEvent;

		if BtnSelect.Clicked or (Key = KeyAltS) or (Key = KeyEnter) then
		begin
			SelectedItemName := List[ActiveList].GetSelectedItem;
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
			List[ActiveList].MoveSelection(Up);

		if Key = KeyDown then
			List[ActiveList].MoveSelection(Down);

		if Key = KeyHome then
			List[ActiveList].MoveSelection(First);

		if Key = KeyEnd then
			List[ActiveList].MoveSelection(Last);

		if Key = KeyPageUp then
			List[ActiveList].MoveSelection(PageUp);

		if Key = KeyPageDown then
			List[ActiveList].MoveSelection(PageDown);

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
				List[FileList].Draw;
				DrawPreview(nil);
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