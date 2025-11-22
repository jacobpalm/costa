program DESKTOP;

{$M 32768, 0, 655360} {Require at least 32 KB stack}

uses
	Costalib, UIButton, UIDesk, MsgDlg, RunDlg, AboutDlg, FileDlg, InputDlg, Strings, Graph, Crt, DeskEdit, DeskMenu, Dos;

const
	AppName                   = 'Desktop';
	AppVersion                = '2.0';
	AppAuthor                 = 'Jacob Palm';
	AppIcon                   = 'LOGO';

	RunFile                   = 'CONFIG\RUN.BIN';

	CAP_ADD                   = 'A' + #127 + 'dd...';
	CAP_RUN                   = #127 + 'Run...';
	CAP_ABOUT                 = #127 + 'About...';
	CAP_EXIT                  = 'E' + #127 + 'xit';

	MSG_REMOVE_LINK_TITLE     = 'Remove desktop link';
	MSG_REMOVE_LINK           = 'This will permanently delete this' + #13 + 
	                            'desktop link. Are you sure?';
	MSG_EXIT                  = 'Exit';
	MSG_EXIT_PROMPT           = 'This will exit Costa and return you to the DOS' + #13 +
	                            'prompt. Are you sure?';
	MSG_SAVE_ERROR_TITLE      = 'Error writing to file';
	MSG_SAVE_ERROR            = 'Could not open file for writing. The' + #13 + 
	                            'file may be read-only or inaccesible:' + #13;
	MSG_LOAD_ERROR_TITLE      = 'Error loading desktop links';
	MSG_LOAD_ERROR            = 'Could not open file for reading. The' + #13 + 
	                            'file may corrupt or inaccesible:' + #13;
	MSG_OUT_OF_MEMORY         = 'Out of memory.';
	MSG_NOT_A_PROGRAM_TITLE   = 'Not a program';
	MSG_NOT_A_PROGRAM         = 'The file you are trying to run is not a program.' + #13 +
	                            'Only .EXE, .COM and .BAT files can be executed.';
	MSG_FILE_NOT_FOUND_TITLE  = 'File not found';
	MSG_PROGRAM_NOT_FOUND     = 'The program/file you are trying to open was not found:' + #13;
	MSG_COMSPEC_TITLE         = 'COMSPEC not set';
	MSG_COMSPEC               = 'The COMSPEC environment variable is not set.' + #13 +
	                            'This is required to run batch files.';

var
	App:      PApplication;
	WinMain:  PWindow;
	Desk:     PDesktop;
	BtnAdd,
	BtnRun,
	BtnAbout,
	BtnExit:  PButton;

	DesktopFile: PathStr;

procedure RunExternal(Target: PLink);
var
	F:          file;
	FPath:      DirStr;
	FName:      NameStr;
	FExt:       ExtStr;
	ComSpec:    String;
	OutLink:    TLink;
begin
	if not Assigned(Target) then
		exit;

	{Make copy of link so we can modify it}
	OutLink := Target^;

	{If file not found, try adding the path from the link}
	if not FileExists(OutLink.Filename) then
		OutLink.Filename := OutLink.Path + '\' + OutLink.FileName;

	{If still not found, don't run it}
	if not FileExists(OutLink.Filename) then
	begin
		MsgBox(MSG_FILE_NOT_FOUND_TITLE, MSG_PROGRAM_NOT_FOUND + OutLink.Filename, MsgError);
		exit;
	end;

	FSplit(OutLink.Filename, FPath, FName, FExt);
	if (FExt <> '.EXE') and (FExt <> '.COM') and (FExt <> '.BAT') then
	begin
		MsgBox(MSG_NOT_A_PROGRAM_TITLE, MSG_NOT_A_PROGRAM, MsgError);
		exit;
	end;

	{Batch files cannot be run directly, use COMSPEC to find command.com and
	 run the batch file with it}
	if FExt = '.BAT' then
	begin
		ComSpec := GetEnv('COMSPEC');
		if Length(ComSpec) = 0 then
		begin
			MsgBox(MSG_COMSPEC_TITLE,
				MSG_COMSPEC,
				MsgError);
			exit;
		end;
		{Move batch filename and parameters to parameters}
		OutLink.Parameters := '/C ' + OutLink.Filename + ' ' + OutLink.Parameters;
		{Replace filename with command.com}
		OutLink.FileName := ComSpec;
	end;

	Assign(F, ProgramPath + RunFile);
	{$I-}
	Rewrite(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		Close(F);
		MsgBox(MSG_SAVE_ERROR_TITLE, MSG_SAVE_ERROR + RunFile, MsgError);
		exit;
	end;

	BlockWrite(F, OutLink, SizeOf(OutLink));
	Close(F);
	
	App^.SetExitCode(0);
	WinMain^.Close;
end;

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

	{Regardless of whether the user pressed OK or Cancel, dispose of the link.
	 If it was added to the desktop, the desktop object now has its own copy.}
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
var
	DoExit: Boolean;
begin
	DoExit := false;

	if not Setting.ConfExit then
		{If exit confirmation is disabled, just exit}
		DoExit := true
	else
		{Otherwise, ask for confirmation}
		if MsgBox(MSG_EXIT + ' ' + appName, MSG_EXIT_PROMPT, MsgQuest) then
			DoExit := true;
	
	if DoExit then
	begin
		App^.SetExitCode(1); {Error code 1 makes COSTA.EXE terminate and return to DOS prompt}
		WinMain^.Close;
	end;
end;

procedure DeskClick(Sender: PUIObject); far;
var
	ClickedLink: PLink;
	LinkAction:  TLinkAction;
	result:      boolean;
begin
	ClickedLink := Desk^.GetActiveLink;
	if not Assigned(ClickedLink) then
		exit;
	
	LinkAction := LinkMenu(ClickedLink);
	case LinkAction of

		{Open/run}
		laOpen:
		begin
			{Desk^.OpenLink(ClickedLink);}
			RunExternal(ClickedLink);
		end;

		{Edit properties}
		laEdit:
		begin
			if EditLink(ClickedLink) then
			begin
				Mouse.Hide;
				Desk^.Draw;
				Mouse.Show;
			end;
		end;

		{Move link on current desktop}
		laMove:
		begin
			Desk^.MoveLink(ClickedLink);
		end;

		{Remove/delete link}
		laRemove:
		begin
			if Setting.ConfLinkDel then
				{Link delete confirmation enabled, prompt user}
				result := MsgBox(MSG_REMOVE_LINK_TITLE, MSG_REMOVE_LINK, MsgQuest)
			else
				{Link delete confirmation disabled, just proceed}
				result := true;
			
			if result then
				Desk^.RemoveLink(ClickedLink);
		end;
	end;
end;

procedure DeskRightClick(Sender: PUIObject); far;
var
	ClickedLink: PLink;
begin
	ClickedLink := Desk^.GetActiveLink;
	if Assigned(ClickedLink) then
		Desk^.MoveLink(ClickedLink);
end;

procedure WinMainRun(Sender: PUIObject); far;
var
	result:   boolean;
begin
	DesktopFile := App^.Path + 'CONFIG\TEST.BIN';
	result := Desk^.LoadLinks(DesktopFile);

	if not result then
		MsgBox(MSG_LOAD_ERROR_TITLE, MSG_LOAD_ERROR + DesktopFile, MsgError);
end;

procedure WinMainClose(Sender: PUIObject); far;
begin
	{When the window is closed, the desktop will exit. Save data before closing}
	Desk^.SaveLinks(DesktopFile);
end;

procedure InitUI;
begin
{Initialize UI objects}
	New(WinMain, Init(0, 0, nil));
	With WinMain^ do
	begin
		SetSize(640, 350);
		RemoveState(SBordered);
		SetOnRun(WinMainRun)
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
end;

begin
	New(App, Init);
	App^.SetInfo(AppName, AppVersion, AppAuthor, AppIcon);

	InitUI;

	WinMain^.Run;
	Dispose(WinMain, Done);
	WinMain := nil;
	App^.Exit;
end.