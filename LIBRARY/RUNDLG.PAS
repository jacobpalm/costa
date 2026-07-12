unit RunDlg;

{Run dialog for the desktop}

interface

uses
	CostaLib, UIDesk, UITxtbox, UIButton, FileDlg, DOS;

function RunDialog: PLink;

implementation

const
	CAP_OK         = #127 + 'OK';
	CAP_CANCEL     = #127 + 'Cancel';
	CAP_BROWSE     = #127 + 'Browse...';
	CAP_FILENAME   = #127 + 'Filename:';
	CAP_PARAMETERS = 'Pa' + #127 + 'rameters:';

var
	WinRun:        PWindow;
	TxtFilename,
	TxtParams:     PTextbox;
	BtnOK,
	BtnCancel,
	BtnBrowse:     PButton;
	RunLink:       PLink;

procedure TxtFilename_Change(Sender: PUIObject); far;
begin
	if (Length(TxtFilename^.Text) > 0) and not (SEnabled in BtnOK^.State) then
		BtnOK^.AddState(SEnabled)
	else if (Length(TxtFilename^.Text) = 0) and (SEnabled in BtnOK^.State) then
		BtnOK^.RemoveState(SEnabled);
end;

procedure BtnOK_Click(Sender: PUIObject); far;
begin
	if Length(TxtFilename^.Text) > 0 then
	begin
		New(RunLink);
		FillChar(RunLink^, SizeOf(TLink), 0);
		RunLink^.FileName := UpperCase(TxtFilename^.Text);
		RunLink^.Parameters := TxtParams^.Text;
		RunLink^.PauseOnExit := true;
		WinRun^.Close;
	end;
end;

procedure BtnCancel_Click(Sender: PUIObject); far;
begin
	WinRun^.Close;
end;

procedure BtnBrowse_Click(Sender: PUIObject); far;
var
	SelectedFile: string;
begin
	SelectedFile := FileSelect('*.EXE', '');
	if Length(SelectedFile) <> 0 then
		TxtFilename^.SetText(SelectedFile);
end;

procedure InitUI;
begin
	New(WinRun, Init(0, 0, nil));
	with WinRun^ do
	begin
		Width := 382;
		Height := 137;
		Center(OrBoth);
		SaveBackdrop;
	end;
	New(TxtFilename, Init(6, 21, CAP_FILENAME, WinRun));
	with TxtFilename^ do
	begin
		Width := 358;
		OnChange := TxtFilename_Change;
		AddHotkey(KeyAltF);
	end;
	New(TxtParams, Init(6, 67, CAP_PARAMETERS, WinRun));
	with TxtParams^ do
	begin
		Width := 358;
		AddHotkey(KeyAltR);
	end;
	New(BtnOK, Init(68, 97, CAP_OK, WinRun));
	with BtnOK^ do
	begin
		Exclude(State, SEnabled);
		OnClick := BtnOK_Click;
		AddHotkey(KeyAltO);
		AddHotkey(KeyEnter);
	end;
	New(BtnCancel, Init(170, 97, CAP_CANCEL, WinRun));
	with BtnCancel^ do
	begin
		OnClick := BtnCancel_Click;
		AddHotkey(KeyAltC);
		AddHotkey(KeyEscape);
	end;
	New(BtnBrowse, Init(272, 97, CAP_BROWSE, WinRun));
	with BtnBrowse^ do
	begin
		OnClick := BtnBrowse_Click;
		AddHotkey(KeyAltB);
	end;
end;

function RunDialog: PLink;
begin
	RunLink := nil;
	InitUI;
	WinRun^.Run;
	Dispose(WinRun, Done);
	WinRun := nil;
	RunDialog := RunLink;
end;

end.