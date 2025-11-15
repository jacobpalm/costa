program DESKTEST;

uses
	Costalib, UIButton, UIDesk, MsgDlg, RunDlg, AboutDlg, FileDlg, InputDlg, Strings, Graph, Crt, DeskEdit;

const
	AppName                   = 'Desktop';
	AppVersion                = '2.0';
	AppAuthor                 = 'Jacob Palm';
	AppIcon                   = 'LOGO';

	CAP_OK                    = #127 + 'OK';
	CAP_CANCEL                = #127 + 'Cancel';
	CAP_FILENAME              = #127 + 'Filename:';
	CAP_PARAMETERS            = 'Pa' + #127 + 'rameters:';
	CAP_OPEN                  = #127 + 'Open';
	CAP_EDIT                  = #127 + 'Edit...';
	CAP_MOVE                  = #127 + 'Move';
	CAP_REMOVE                = #127 + 'Remove';
	CAP_SAVE                  = #127 + 'Save';
	CAP_PAUSE_ON_EXIT         = 'Pause after e' + #127 + 'xit';
	CAP_CAPTION               = 'C' + #127 + 'aption:';
	CAP_PATH                  = 'Pa' + #127 + 'th:';
	CAP_ICON                  = #127 + 'Icon:';
	CAP_ADD                   = 'A' + #127 + 'dd...';
	CAP_RUN                   = #127 + 'Run...';
	CAP_ABOUT                 = #127 + 'About...';
	CAP_EXIT                  = 'E' + #127 + 'xit';

	MSG_LOAD_ERROR_TITLE      = 'Error loading desktop links';
	MSG_OUT_OF_MEMORY         = 'Out of memory.';
	MSG_DATA_ERROR            = 'Could not open file for reading. The' + #13 + 
	                            'file may corrupt or inaccesible:' + #13;
	MSG_FILE_SIZE_ERROR       = 'File size mismatch. This indicates that the desktop file' + #13 + 
	                            'is corrupt:' + #13;
	MSG_SAVE_ERROR_TITLE      = 'Error saving desktop links';
	MSG_SAVE_ERROR            = 'Could not open file for writing. The' + #13 + 
	                            'file may be read-only or inaccesible:' + #13;
	MSG_UNSPECIFIED           = 'Unspecified';
	MSG_NONE                  = 'None';
	MSG_PATH                  = 'Path:';
	MSG_PARAMETERS            = 'Parameters:';
	MSG_REMOVE_LINK_TITLE     = 'Remove desktop link';
	MSG_REMOVE_LINK           = 'This will permanently delete this' + #13 + 
	                            'desktop link. Are you sure?';
	MSG_INVALID_PROGRAM_TITLE = 'Invalid program';
	MSG_PROGRAM_MISSING       = 'The ''Filename'' field cannot be empty.';
	MSG_INVALID_ICON_TITLE    = 'Invalid icon file';
	MSG_INVALID_ICON          = 'The selected file is not a valid icon file.' + #13 +
	                            'Please select a .BIN file from the ICONS directory.';
	MSG_NOT_A_PROGRAM_TITLE   = 'Not a program';
	MSG_NOT_A_PROGRAM         = 'The file you are trying to run is not a program.' + #13 +
	                            'Only .EXE, .COM and .BAT files can be executed.';
	MSG_FILE_NOT_FOUND_TITLE  = 'File not found';
	MSG_PROGRAM_NOT_FOUND     = 'The program/file you are trying to open was not found:' + #13;
	MSG_COMSPEC_TITLE         = 'COMSPEC not set';
	MSG_COMSPEC               = 'The COMSPEC environment variable is not set.' + #13 +
	                            'This is required to run batch files.';
	MSG_EXIT                  = 'Exit';
	MSG_EXIT_PROMPT           = 'This will exit Costa and return you to the DOS' + #13 +
	                            'prompt. Are you sure?';

var
	App:      PApplication;
	WinMain:  PWindow;
	Desk:     PDesktop;
	BtnAdd,
	BtnRun,
	BtnAbout,
	BtnExit:  PButton;

	Filename: string;

procedure BtnAddClick(Sender: PUIObject); far;
var
  NewLink: PLink;
begin
	{Create new link with default values}
	New(NewLink);
	With NewLink^ do
	begin
		Caption := '';
		IconFile := 'PROGRAM';
		FileName := '';
		Path := '';
		Parameters := '';
		Left := 50;
		Top := 50;
		PauseOnExit := False;
	end;

	{Edit the new link - if the user pressed OK, add it to the desktop}
	if EditLink(NewLink) then
		Desk^.AddLink(NewLink);

	{Regardless of whether the user pressed OK or Cancel, dispose of the link
	 (if it was added to the desktop, the desktop now has its own copy)}
	Dispose(NewLink);
end;

procedure BtnRunClick(Sender: PUIObject); far;
begin
	RunDialog;
end;



procedure BtnAboutClick(Sender: PUIObject); far;
begin
	AboutBox(App);
end;

procedure BtnExitClick(Sender: PUIObject); far;
begin
	App^.Exit;
end;

procedure DeskClick(Sender: PUIObject); far;
var
	ClickedLink: PLink;
begin
	ClickedLink := Desk^.GetActiveLink;
	if Assigned(ClickedLink) then
	begin
		{MsgBox('Link Clicked', 'You clicked the link: ' + ClickedLink^.Caption + #13 + 'Right-click to move link.', MsgInfo);}
		if EditLink(ClickedLink) then
		begin
			Mouse.Hide;
			Desk^.Draw;
			Mouse.Show;
		end;
	end
	else
		MsgBox('Desktop Clicked', 'You clicked on the desktop background.', MsgInfo);
end;

procedure DeskRightClick(Sender: PUIObject); far;
var
	ClickedLink: PLink;
begin
	ClickedLink := Desk^.GetActiveLink;
	if Assigned(ClickedLink) then
	begin
		Desk^.MoveLink(ClickedLink);
	end
	else
		MsgBox('Desktop Right-Clicked', 'You right-clicked on the desktop background.', MsgInfo);
end;

begin
	New(App, Init);
	App^.SetInfo(AppName, AppVersion, AppAuthor, AppIcon);

	{Initialize UI objects}
	New(WinMain, Init(0, 0, nil));
	With WinMain^ do
	begin
		SetSize(640, 350);
		RemoveState(SBordered);
	end;

	New(Desk, Init(0, 29, WinMain));
	With Desk^ do
	begin
		SetSize(640, 321);
		SetOnClick(DeskClick);
		SetOnRightClick(DeskRightClick);
	end;

	New(BtnAdd, Init(2, 2, CAP_ADD, WinMain));
	With BtnAdd^ do
	begin
		AddHotkey(KeyAltA);
		SetOnClick(BtnAddClick);
	end;	
	New(BtnRun, Init(101, 2, CAP_RUN, WinMain));
	With BtnRun^ do
	begin
		AddHotkey(KeyAltR);
		SetOnClick(BtnRunClick);
	end;
	
	New(BtnAbout, Init(446, 2, CAP_ABOUT, WinMain));
	With BtnAbout^ do
	begin
		AddHotkey(KeyAltA);
		AddHotkey(KeyF1);
		SetOnClick(BtnAboutClick);
	end;
	New(BtnExit, Init(545, 2, CAP_EXIT, WinMain));
	With BtnExit^ do
	begin
		AddHotkey(KeyAltX);
		AddHotkey(KeyAltF4);
		SetOnClick(BtnExitClick);
	end;

	App^.OpenWindow(WinMain);
	App^.Run;
end.