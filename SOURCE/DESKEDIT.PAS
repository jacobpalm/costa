unit DeskEdit;

interface

uses
	UIDesk;

function EditLink(Link: PLink): boolean;

implementation
uses
	CostaLib, UILabel, UIButton, UIIcon, UITxtbox, UIFrame, UIChkBox, FileDlg, MsgDlg, Strings, DOS;

const
	CAP_OK                    = #127 + 'OK';
	CAP_CANCEL                = #127 + 'Cancel';
	CAP_FILENAME              = #127 + 'Filename:';
	CAP_PARAMETERS            = 'Pa' + #127 + 'rameters:';
	CAP_PATH                  = 'Pa' + #127 + 'th:';
	CAP_CAPTION               = 'C' + #127 + 'aption:';
	CAP_ICON                  = #127 + 'Icon:';
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
	BtnCancel:      PButton;
	LblIcon:        PLabel;
	FrmIcon:        PFrame;
	ImgIcon:        PIcon;
	ChkPauseOnExit: PCheckbox;
	DidEdit:        Boolean;
	TargetLink:     PLink;


procedure BtnOK_Click(Sender: PUIObject); far;
var
	CleanPath: string;
begin
	if Length(TxtFileName^.GetText) <> 0 then
	begin
		{Sanitize path}
		CleanPath := TxtPath^.GetText;
		if Length(CleanPath) <> 0 then
		begin
			if CleanPath[Length(CleanPath)] = '\' then
				CleanPath := Copy(CleanPath, 1, Length(CleanPath) - 1);
			if CleanPath + '\' = ProgramPath then
				CleanPath := '';
		end;
		TargetLink^.Caption := TxtCaption^.GetText;
		TargetLink^.Filename := TxtFileName^.GetText;
		TargetLink^.Path := TxtPath^.GetText;
		TargetLink^.Parameters := TxtParams^.GetText;
		TargetLink^.PauseOnExit := ChkPauseOnExit^.GetChecked;
		TargetLink^.IconFile := ImgIcon^.GetIcon;
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

procedure ImgIcon_Click(Sender: PUIObject); far;
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
			Mouse.Hide;
			FrmIcon^.Draw;
			Mouse.Show;
		end
		else
			MsgBox(MSG_INVALID_ICON_TITLE, MSG_INVALID_ICON, MsgError);
	end;
end;

procedure TxtFilename_Click(Sender: PUIObject); far;
var
	SelectedFile: string;
	FDir:         DirStr;
	FName:        NameStr;
	FExt:         ExtStr;
begin
	
	SelectedFile := FileSelect('*.EXE', '');
	if Length(SelectedFile) <> 0 then
	begin
		FSplit(SelectedFile, FDir, FName, FExt);
		TxtFileName^.SetText(FName + FExt);
		TxtPath^.SetText(FDir);
		Mouse.Hide;
		TxtFilename^.Draw;
		TxtPath^.Draw;
		Mouse.Show;
	end;
end;

procedure InitUI;
begin
	New (WinEdit, Init(0, 0, nil));
	With WinEdit^ do
	begin
		SetSize(220, 312);
		Center(OrBoth);
		SaveBackdrop;
	end;
	New(LblIcon, Init(12, 12, CAP_ICON, WinEdit));

	New(FrmIcon, Init(12, 26, WinEdit));
	With FrmIcon^ do
	begin
		SetSize(196, 41);
		SetBgColor(Thm.Desk);
	end;
	New(ImgIcon, Init(0, 5, TargetLink^.IconFile, FrmIcon));
	With ImgIcon^ do
	begin
		SetSize(32, 32);
		Center(OrHorizontal);
		AddHotkey(KeyAltI);
		SetOnClick(ImgIcon_Click);
	end;
	
	New(TxtCaption, Init(12, 86, CAP_CAPTION, WinEdit));
	With TxtCaption^ do
	begin
		SetSize(196, SizeRetain);
		SetMaxLength(LinkCaptMax);
		SetText(TargetLink^.Caption);
		AddHotkey(KeyAltA);
	end;
	New(TxtFilename, Init(12, 130, CAP_FILENAME, WinEdit));
	With TxtFilename^ do
	begin
		SetSize(196, SizeRetain);
		SetMaxLength(SizeOf(ComStr));
		SetText(TargetLink^.FileName);
		AddHotkey(KeyAltF);
	end;
	New(TxtPath, Init(12, 174, CAP_PATH, WinEdit));
	With TxtPath^ do
	begin
		SetSize(196, SizeRetain);
		SetMaxLength(SizeOf(DirStr));
		SetText(TargetLink^.Path);
		AddHotkey(KeyAltT);
	end;
	New(TxtParams, Init(12, 218, CAP_PARAMETERS, WinEdit));
	With TxtParams^ do
	begin
		SetSize(196, SizeRetain);
		SetMaxLength(SizeOf(ComStr));
		SetText(TargetLink^.Parameters);
		AddHotkey(KeyAltR);
	end;
	New(ChkPauseOnExit, Init(12, 250, CAP_PAUSE_ON_EXIT, TargetLink^.PauseOnExit, WinEdit));
	With ChkPauseOnExit^ do
	begin
		AddHotkey(KeyAltX);
	end;
	New(BtnOK, Init(12, 278, CAP_OK, WinEdit));
	With BtnOK^ do
	begin
		SetOnClick(BtnOK_Click);
		AddHotkey(KeyAltO);
		AddHotkey(KeyEnter);
	end;
	New(BtnCancel, Init(116, 278, CAP_CANCEL, WinEdit));
	With BtnCancel^ do
	begin
		AddHotkey(KeyAltC);
		AddHotkey(KeyEscape);
		SetOnClick(BtnCancel_Click);
	end;
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
	EditLink := DidEdit;
end;

end.