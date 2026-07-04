unit DeskEdit;

interface

uses
	UIDesk;

function EditLink(Link: PLink): boolean;

implementation
uses
	CostaLib, UILabel, UIButton, UIIcon, UITxtbox, UIChkBox, FileDlg, MsgDlg, DOS;

const
	CAP_OK                    = #127 + 'OK';
	CAP_CANCEL                = #127 + 'Cancel';
	CAP_FILENAME              = #127 + 'Filename:';
	CAP_PARAMETERS            = 'Pa' + #127 + 'rameters:';
	CAP_PATH                  = 'Pa' + #127 + 'th:';
	CAP_CAPTION               = 'C' + #127 + 'aption:';
	CAP_BROWSE                = #127 + 'Browse...';
	CAP_ICON                  = #127 + 'Icon...';
	CAP_PAUSE_ON_EXIT         = 'Pause after e' + #127 + 'xit';

	MSG_INVALID_PROGRAM_TITLE = 'Invalid program';
	MSG_PROGRAM_MISSING       = 'The ''Filename'' field cannot be empty.';
	MSG_INVALID_ICON_TITLE    = 'Invalid icon file';
	MSG_INVALID_ICON          = 'The selected file is not a valid icon file.' + #13 +
	                            'Please select a .BIN file from the ICONS directory.';

var
	WinEdit:        PWindow;
	TxtCaption,
	TxtFilename,
	TxtParams,
	TxtPath:        PTextbox;
	BtnOK,
	BtnCancel,
	BtnBrowse,
	BtnIcon:        PButton;
	ImgIcon:        PIcon;
	ChkPauseOnExit: PCheckbox;
	DidEdit:        Boolean;
	TargetLink:     PLink;


procedure BtnOK_Click(Sender: PUIObject); far;
var
	CleanPath: string;
begin
	if Length(TxtFileName^.Text) > 0 then
	begin
		{Sanitize path}
		CleanPath := TxtPath^.Text;
		if Length(CleanPath) > 0 then
		begin
			if CleanPath[Length(CleanPath)] = '\' then
				CleanPath := Copy(CleanPath, 1, Length(CleanPath) - 1);
			if CleanPath + '\' = ProgramPath then
				CleanPath := '';
		end;
		TargetLink^.Caption := TxtCaption^.Text;
		TargetLink^.Filename := TxtFileName^.Text;
		TargetLink^.Path := TxtPath^.Text;
		TargetLink^.Parameters := TxtParams^.Text;
		TargetLink^.PauseOnExit := ChkPauseOnExit^.GetChecked;
		TargetLink^.IconFile := ImgIcon^.IconFile;
		DidEdit := True;
		WinEdit^.Close;
	end
	else
	begin
		MsgBox(MSG_INVALID_PROGRAM_TITLE, MSG_PROGRAM_MISSING, MsgInfo);
	end;
end;

procedure BtnCancel_Click(Sender: PUIObject); far;
begin
	WinEdit^.Close;
end;

procedure BtnBrowse_Click(Sender: PUIObject); far;
var
	SelectedFile: string;
	Path: DirStr;
	FName: NameStr;
	FExt: ExtStr;
begin
	SelectedFile := FileSelect('*.EXE', '');
	if Length(SelectedFile) <> 0 then
	begin
		{If the Path field is empty, copy path from selected file there}
		if Length(TxtPath^.Text) = 0 then
		begin
			FSplit(SelectedFile, Path, FName, FExt);
			TxtPath^.SetText(Path);
		end;
		TxtFileName^.SetText(SelectedFile);
	end;
end;

procedure BtnIcon_Click(Sender: PUIObject); far;
var
	SelectedFile: string;
	FDir:         DirStr;
	FName:        NameStr;
	FExt:         ExtStr;
begin
	SelectedFile := FileSelect('*.BIN', 'ICONS');
	if Length(SelectedFile) > 0 then
	begin
		FSplit(SelectedFile, FDir, FName, FExt);
		if (FDir = ProgramPath + 'ICONS\') and (FExt = '.BIN') then
		begin
			ImgIcon^.SetIcon(FName);
		end
		else
			MsgBox(MSG_INVALID_ICON_TITLE, MSG_INVALID_ICON, MsgError);
	end;
end;

procedure InitUI;
begin
	New (WinEdit, Init(0, 0, nil));
	With WinEdit^ do
	begin
		Width := 335;
		Height := 214;
		Center(OrBoth);
		SaveBackdrop;
	end;

	New(TxtCaption, Init(12, 26, CAP_CAPTION, WinEdit));
	With TxtCaption^ do
	begin
		Width := 211;
		MaxLength := LinkCaptMax;
		Text := TargetLink^.Caption;
		AddHotkey(KeyAltA);
	end;
	New(TxtFilename, Init(12, 70, CAP_FILENAME, WinEdit));
	With TxtFilename^ do
	begin
		Width := 211;
		MaxLength := SizeOf(ComStr);
		Text := TargetLink^.FileName;
		AddHotkey(KeyAltF);
	end;
	New(TxtPath, Init(12, 114, CAP_PATH, WinEdit));
	With TxtPath^ do
	begin
		Width := 211;
		MaxLength := SizeOf(DirStr);
		Text := TargetLink^.Path;
		AddHotkey(KeyAltT);
	end;
	New(TxtParams, Init(12, 158, CAP_PARAMETERS, WinEdit));
	With TxtParams^ do
	begin
		Width := 211;
		MaxLength := SizeOf(ComStr);
		Text := TargetLink^.Parameters;
		AddHotkey(KeyAltR);
	end;
	New(ChkPauseOnExit, Init(12, 187, CAP_PAUSE_ON_EXIT, TargetLink^.PauseOnExit, WinEdit));
	With ChkPauseOnExit^ do
	begin
		AddHotkey(KeyAltX);
	end;

	New(BtnOK, Init(231, 26, CAP_OK, WinEdit));
	With BtnOK^ do
	begin
		OnClick := BtnOK_Click;
		AddHotkey(KeyAltO);
		AddHotkey(KeyEnter);
	end;
	New(BtnCancel, Init(231, 54, CAP_CANCEL, WinEdit));
	With BtnCancel^ do
	begin
		OnClick := BtnCancel_Click;
		AddHotkey(KeyAltC);
		AddHotkey(KeyEscape);
	end;
	New(BtnBrowse, Init(231, 82, CAP_BROWSE, WinEdit));
	With BtnBrowse^ do
	begin
		OnClick := BtnBrowse_Click;
		AddHotkey(KeyAltB);
	end;
	New(BtnIcon, Init(231, 110, CAP_ICON, WinEdit));
	With BtnIcon^ do
	begin
		OnClick := BtnIcon_Click;
		AddHotkey(KeyAltI);
	end;

	New(ImgIcon, Init(261, 157, TargetLink^.IconFile, WinEdit));
	ImgIcon^.OnClick := BtnIcon_Click;
end;

function EditLink(Link: PLink): boolean;
begin
	DidEdit := false;

	{Can't edit a non-existing link}
	if not Assigned(Link) then
		exit;

	TargetLink := Link;

	InitUI;
	WinEdit^.Run;
	Dispose(WinEdit, Done);
	WinEdit := nil;
	EditLink := DidEdit;
end;

end.