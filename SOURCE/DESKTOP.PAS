program DESKTOP;

{$M 32768, 0, 655360} {Require at least 32 KB stack}

uses
	Costalib, UIButton, UIDesk, UILabel, MsgDlg, RunDlg, AboutDlg, FileDlg, InputDlg,
	Strings, Graph, Crt, DeskEdit, DeskMenu, Dos;

const
	AppName                   = 'Desktop';
	AppVersion                = '2.0';
	AppAuthor                 = 'Jacob Palm';
	AppIcon                   = 'LOGO';
	AppConfigFile             = 'DESKTOP';

	RunFile                   = 'CONFIG\RUN.BIN';
	DeskFilePattern           = 'CONFIG\DESK%s.BIN'; {%s = placeholder for active desktop ID}
	DesktopDefault            = 'CONFIG\DESKDEF.BIN';
	MaxDesktops               = 5;
	KeyAltNoBase              = 120; {Key code for Alt+1, used to set hotkeys for desktops in loop}

	RunBinSize                = 277; {Size of RUN.BIN in bytes}
	RunBinOffsetFileName      = 0;   {Offsets within RUN.BIN where each variable is stored}
	RunBinOffsetPath          = 80;
	RunBinOffsetParameters    = 148;
	RunBinOffsetPause         = 276;

	CAP_ADD                   = 'A' + #127 + 'dd...';
	CAP_RUN                   = #127 + 'Run...';
	CAP_ABOUT                 = #127 + 'About...';
	CAP_EXIT                  = 'E' + #127 + 'xit';

	MSG_REMOVE_LINK_TITLE     = 'Remove desktop link';
	MSG_REMOVE_LINK           = 'This will permanently delete this' + #13 +
	                            'desktop link. Are you sure?';
	MSG_EXIT                  = 'Exit Costa';
	MSG_EXIT_PROMPT           = 'This will exit Costa and return you to the DOS' + #13 +
	                            'prompt. Continue?';
	MSG_SAVE_ERROR_TITLE      = 'Error writing to file';
	MSG_SAVE_ERROR            = '%s. Could not write to' + #13;
	MSG_LOAD_ERROR_TITLE      = 'Error loading desktop links';
	MSG_LOAD_ERROR            = 'Could not open file for reading. The' + #13 +
	                            'file may corrupt or inaccesible:' + #13;
	MSG_OUT_OF_MEMORY         = 'Out of memory.';
	MSG_NOT_A_PROGRAM_TITLE   = 'Not a program';
	MSG_NOT_A_PROGRAM         = 'The file you are trying to run is not a program.' + #13 +
	                            'Only .EXE, .COM and .BAT files can be executed.';
	MSG_FILE_NOT_FOUND_TITLE  = 'File not found';
	MSG_PROGRAM_NOT_FOUND     = 'The program or file was not found:' + #13;
	MSG_COMSPEC_TITLE         = 'COMSPEC not set';
	MSG_COMSPEC               = 'The COMSPEC environment variable is not set.' + #13 +
	                            'This is required to run batch files.';
	MSG_RUN_COSTA             = 'This program is intended to be run from within Costa.' + #10 + #13 +
	                            'Please run COSTA.EXE to start Costa and the desktop.';

type
	{$I DESKSET.INC} {Desktop settings are in separate file so CONFIG can use them too}

var
	App:         PApplication;
	WinMain:     PWindow;
	Desk:        PDesktop;
	BtnAdd,
	BtnRun,
	BtnAbout,
	BtnExit,
	BtnPrevious,
	BtnNext:     PButton;
	LblDesktop:  PLabel;
	HkDesktop:   array[1..MaxDesktops] of PHotkey;

	DesktopFile: PathStr;

	Settings:    TDeskSetting;

procedure RunExternal(Target: PLink);
var
	F:           file;
	FPath:       DirStr;
	FName:       NameStr;
	FExt:        ExtStr;
	ComSpec:     String;
	OutLink:     TLink;
	RunData:     array[0..RunBinSize - 1] of Char;
	ErrorCode:   integer;
begin
	if not Assigned(Target) then
		exit;

	{Make copy of link so we can modify it}
	OutLink := Target^;

	{Remove trailing backslash if present, to avoid problems with path change}
	if OutLink.Path[Length(OutLink.Path)] = '\' then
		Dec(OutLink.Path[0]);

	{If file not found, try adding the path from the link}
	if not FileExists(OutLink.Filename) and (Length(OutLink.Path) > 0) then
		OutLink.Filename := Concat(OutLink.Path, '\', OutLink.FileName);

	{If still not found, don't run it}
	if not FileExists(OutLink.Filename) then
	begin
		MsgBox(MSG_FILE_NOT_FOUND_TITLE, MSG_PROGRAM_NOT_FOUND + OutLink.Filename, MsgError);
		exit;
	end;

	FSplit(OutLink.Filename, FPath, FName, FExt);
	FExt := UpperCase(FExt);
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
			MsgBox(MSG_COMSPEC_TITLE, MSG_COMSPEC, MsgError);
			exit;
		end;
		{Move batch filename and parameters to parameters}
		OutLink.Parameters := Concat('/C ', OutLink.Filename, ' ', OutLink.Parameters);
		{Replace filename with command.com}
		OutLink.FileName := ComSpec;
	end;

	if Length(OutLink.Parameters) > 0 then
		OutLink.Parameters := #32 + OutLink.Parameters; {If parameters exist, ensure they start with space}
	OutLink.Parameters := Char(Length(OutLink.Parameters)) + OutLink.Parameters;
		{Ensure parameters end with CR, req. by cmd tail}

	{Convert strings to ASCIIZ - COSTA.EXE expects this format and we use fixed size
	 records for simplicity in loading data in COSTA.EXE}
	FillChar(RunData, SizeOf(RunData), 0); {Clear buffer}

	Move(OutLink.Filename[1], RunData[RunBinOffsetFilename], Length(OutLink.Filename));
	RunData[RunBinOffsetFilename + Length(OutLink.Filename)] := #0; {Add ASCIIZ terminator}

  	Move(OutLink.Path[1], RunData[RunBinOffsetPath], Length(OutLink.Path) );
	RunData[RunBinOffsetPath + Length(OutLink.Path)] := #0; {Add ASCIIZ terminator}

	Move(OutLink.Parameters[1], RunData[RunBinOffsetParameters], Length(OutLink.Parameters));
	RunData[RunBinOffsetParameters + Length(OutLink.Parameters)] := #13; {CR terminator used for cmd tail}

	RunData[RunBinOffSetPause] := Char(OutLink.PauseOnExit);

	Assign(F, ProgramPath + RunFile);
	{$I-}
	Rewrite(F, 1);
	{$I+}
	ErrorCode := IOResult;
	if ErrorCode <> 0 then
	begin
		MsgBox(MSG_SAVE_ERROR_TITLE, ReplaceMsg(MSG_SAVE_ERROR, GetDosErrorMsg(ErrorCode)) + RunFile, MsgError);
		exit;
	end;

	BlockWrite(F, RunData, SizeOf(RunData));
	Close(F);

	App^.SetExitCode(0);
	WinMain^.Close;
end;

procedure SwitchDesktop(DeskID: Byte; ForceSwitch: Boolean);
var
	sDeskID,
	sMaxDesktops: string;
	result:       boolean;
begin
	result := false;

	{Don't switch if the requested desktop is already active}
	if (DeskID = Settings.DeskID) and not ForceSwitch then
		exit;

	{Make sure current desktop is saved before clearing}
	if Length(DesktopFile) > 0 then
	begin
		Desk^.SaveLinks(DesktopFile);
		Desk^.ClearLinks;
	end;

	{Make sure we stay within bounds}
	if (DeskID < 1) then
		Settings.DeskID := MaxDesktops
	else if (DeskID > MaxDesktops) then
		Settings.DeskID := 1
	else
		Settings.DeskID := DeskID;

	{Replace the placeholder char}
	Str(Settings.DeskID, sDeskID);
	DesktopFile := App^.Path + ReplaceMsg(DeskFilePattern, sDeskID);
	Str(MaxDesktops, sMaxDesktops);
	LblDesktop^.SetCaption( Concat(sDeskID, '/', sMaxDesktops) );

	{Load the links, and exit if successful}
	if FileExists(DesktopFile) then
	begin
		result := Desk^.LoadLinks(DesktopFile);

		if result then
			exit;

		{If we reach here, loading failed - show error message}
		MsgBox(MSG_LOAD_ERROR_TITLE, MSG_LOAD_ERROR + DesktopFile, MsgError);
	end;

	{If loading failed or file wasn't found, try to load default desktop links}
	if FileExists(DesktopDefault) and (Settings.DeskID = 1) then
		Desk^.LoadLinks(DesktopDefault);

	{Wether we loaded default links or not, save the links so that the file now exists}
	Desk^.SaveLinks(DesktopFile);
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
var
	RunLink: PLink;
begin
	RunLink := nil;
	RunLink := RunDialog;
	if Assigned(RunLink) then
	begin
		RunExternal(RunLink);
		{Dispose in case RunExternal fails}
		Dispose(RunLink);
	end;
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

	if not Settings.ConfExit then
		{If exit confirmation is disabled, just exit}
		DoExit := true
	else
		{Otherwise, ask for confirmation}
		if MsgBox(MSG_EXIT, MSG_EXIT_PROMPT, MsgQuest) then
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
				Desk^.AddState(SDirty);
		end;

		{Move link on current desktop}
		laMove:
		begin
			Desk^.MoveLink(ClickedLink);
		end;

		{Remove/delete link}
		laRemove:
		begin
			if Settings.ConfLinkDel then
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

procedure BtnPreviousClick(Sender: PUIObject); far;
begin
	SwitchDesktop(Settings.DeskID - 1, false);
end;

procedure BtnNextClick(Sender: PUIObject); far;
begin
	SwitchDesktop(Settings.DeskID + 1, false);
end;

procedure HkDesktopClick(Sender: PUIObject); far;
var
	i: integer;
begin
	{Check which desktop hotkey was pressed}
	for i := 1 to MaxDesktops do
	begin
		if Sender = PUIObject(HkDesktop[i]) then
		begin
			{Switch to that desktop if it's not the current one}
			if i <> Settings.DeskID then
				SwitchDesktop(i, false);
			exit;
		end;
	end;
end;

procedure WinMainDraw(Sender: PUIObject); far;
begin
	{First time the main window is drawn, load the desktop links}
	if Length(DesktopFile) = 0 then
	begin
		SwitchDesktop(Settings.DeskID, true);
		{Show the desktop now that links are loaded}
		Desk^.RemoveState(SHidden);
	end;
end;

procedure WinMainClose(Sender: PUIObject); far;
begin
	{When the window is closed, the desktop will exit. Save data before closing}
	Desk^.SaveLinks(DesktopFile);
	App^.SaveSettings;
	App^.Terminate;
end;

procedure AppRun(Sender: PUIObject); far;
begin
	if not App^.LoadSettings then
	begin
		{If loading of settings fails, use defaults}
		SoundNote(800, 100);
		Settings.DeskID      := 1;
		Settings.LinkCapt    := True;
		Settings.LinkTarget  := False;
		Settings.ConfLinkDel := True;
		Settings.ConfExit    := False;
	end;

	Desk^.SetDisplay(Settings.LinkCapt, Settings.LinkTarget);
end;

procedure InitUI;
var
	i: integer;
begin
{Initialize UI objects}
	New(WinMain, Init(0, 0, nil));
	With WinMain^ do
	begin
		SetSize(640, 350);
		RemoveState(SBordered);
		SetOnDraw(WinMainDraw);
		SetOnClose(WinMainClose);
	end;

	New(BtnAdd, Init(2, 2, CAP_ADD, WinMain));
	With BtnAdd^ do
	begin
		AddHotkey(KeyAltD);
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
		SetOnClick(BtnAboutClick);
	end;
	New(BtnExit, Init(545, 2, CAP_EXIT, WinMain));
	With BtnExit^ do
	begin
		AddHotkey(KeyAltX);
		AddHotkey(KeyAltF4);
		SetOnClick(BtnExitClick);
	end;

	New(LblDesktop, Init(10, 10, ' / ', WinMain));
	With LblDesktop^ do
	begin
		AutoSize;
		Center(OrHorizontal);
		RemoveState(STransparent);
	end;
	New(BtnPrevious, Init(255, 2, HotkeyChr + CharArrowLeft, WinMain));
	With BtnPrevious^ do
	begin
		SetSize(42, SizeRetain);
		AddHotkey(KeyLeft);
		SetOnClick(BtnPreviousClick);
	end;
	New(BtnNext, Init(343, 2, HotkeyChr + CharArrowRight, WinMain));
	With BtnNext^ do
	begin
		SetSize(42, SizeRetain);
		AddHotkey(KeyRight);
		SetOnClick(BtnNextClick);
	end;

	New(Desk, Init(0, 29, WinMain));
	With Desk^ do
	begin
		SetSize(640, 321);
		SetOnClick(DeskClick);
		SetOnRightClick(DeskRightClick);
		AddState(SHidden); {Start hidden, will be shown when links are loaded}
	end;

	for i := 1 to MaxDesktops do
	begin
		New(HkDesktop[i], Init(#0 + Chr(KeyAltNoBase + i - 1), WinMain)); {Alt+1, Alt+2, ...}
		HkDesktop[i]^.AddHotkey(Chr(48 + i)); {Also add '1', '2', ... as hotkeys}
		HkDesktop[i]^.SetOnClick(HkDesktopClick);
	end;
end;

begin
	{Desktop won't work if run outside Costa, so make sure the right parameter is passed from COSTA.EXE}
	if not (ParamStr(1) = '/RUN') then
	begin
		Writeln(MSG_RUN_COSTA);
		Exit;
	end;

	New(App, Init);
	App^.SetInfo(AppName, AppVersion, AppAuthor, AppIcon);
	App^.SetConfigFile(AppConfigFile, @Settings, SizeOf(TDeskSetting));
	App^.SetOnRun(AppRun);

	InitUI;

	App^.OpenWindow(WinMain);
	App^.Run;
end.