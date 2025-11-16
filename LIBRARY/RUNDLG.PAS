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
	RunLink:	   PLink;

procedure TxtFilename_Change(Sender: PUIObject); far;
begin
	if (Length(TxtFilename^.GetText) > 0) and (not BtnOK^.GetState(SEnabled)) then
		BtnOK^.AddState(SEnabled)
	else if (Length(TxtFilename^.GetText) = 0) and BtnOK^.GetState(SEnabled) then
		BtnOK^.RemoveState(SEnabled)
	else
		exit;
	
	Mouse.Hide;
	BtnOK^.Draw;
	Mouse.Show;
end;

procedure BtnOK_Click(Sender: PUIObject); far;
begin
	if Length(TxtFilename^.GetText) > 0 then
	begin
		New(RunLink);
		RunLink^.FileName := TxtFilename^.GetText;
		RunLink^.Parameters := TxtParams^.GetText;
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
	FDir:         DirStr;
	FName:        NameStr;
	FExt:         ExtStr;
begin
	SelectedFile := FileSelect('*.EXE', '');
	if Length(SelectedFile) <> 0 then
	begin
		TxtFilename^.SetText(SelectedFile);
		Mouse.Hide;
		TxtFilename^.Draw;
		Mouse.Show;
		TxtFilename_Change(nil);
	end;
end;

procedure InitUI;
begin
	New(WinRun, Init(0, 0, nil));
	with WinRun^ do
	begin
		SetSize(382, 137);
		Center(OrBoth);
		SaveBackdrop;
	end;
	New(TxtFilename, Init(12, 27, CAP_FILENAME, WinRun));
	with TxtFilename^ do
	begin
		SetSize(358, SizeRetain);
		AddHotkey(KeyAltF);
		SetOnChange(TxtFilename_Change);
	end;
	New(TxtParams, Init(12, 73, CAP_PARAMETERS, WinRun));
	with TxtParams^ do
	begin
		SetSize(358, SizeRetain);
		AddHotkey(KeyAltR);
	end;
	New(BtnOK, Init(74, 103, CAP_OK, WinRun));
	with BtnOK^ do
	begin
		AddHotkey(KeyAltO);
		AddHotkey(KeyEnter);
		RemoveState(SEnabled);
		SetOnClick(BtnOK_Click);
	end;
	New(BtnCancel, Init(176, 103, CAP_CANCEL, WinRun));
	with BtnCancel^ do
	begin
		AddHotkey(KeyAltC);
		AddHotkey(KeyEscape);
		SetOnClick(BtnCancel_Click);
	end;
	New(BtnBrowse, Init(278, 103, CAP_BROWSE, WinRun));
	with BtnBrowse^ do
	begin
		AddHotkey(KeyAltB);
		SetOnClick(BtnBrowse_Click);
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