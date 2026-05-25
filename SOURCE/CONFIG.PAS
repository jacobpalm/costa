program Configuration;

uses
	CostaLib, UIButton, UITxtbox, UIChkbox, UILabel, UIIcon, UIFrame, UIThmPrw, MsgDlg, AboutDlg, Graph, DOS;

const
	AppName              = 'Configuration Utility';
	AppVersion           = '2.0';
	AppAuthor            = 'Jacob Palm';
	AppIcon              = 'CONFIG';

	LinkDesc             = 0;
	LinkTarget           = 1;
	LinkDelete           = 2;
	ConfExit             = 3;
	Audio                = 4;

	CAP_EXIT             = 'E' + #127 + 'xit';
	CAP_ABOUT            = #127 + 'About...';
	CAP_PREVIOUS         = #27 + ' ' + #127 + 'Previous';
	CAP_NEXT             = #127 + 'Next ' + #26;
	CAP_LINKDESC         = 'Show icon ' + #127 + 'captions';
	CAP_LINKTARGET       = 'Show icon pr' + #127 + 'ogram names';
	CAP_LINKDELETE       = 'Confirm icon ' + #127 + 'removal';
	CAP_CONFEXIT         = 'Confirm before ' + #127 + 'exiting Costa';
	CAP_AUDIO            = 'A' + #127 + 'udible alerts';
	CAP_BUTTON           = 'Button';
	CAP_TEXTBOX          = 'Textbox';
	CAP_CURR_THEME       = 'This is your current' + #13 + 'theme.';
	CAP_PREVIEW_LINK     = 'Preview link';
	CAP_PREVIEW_EXE      = 'preview.exe';
	CAP_SETTINGS         = 'Settings' + #13 +
	                       'Tweak various aspects of Costa.';
	CAP_THEMES           = 'Theme' + #13 +
	                       'Choose colors for the UI.';
	CAP_LOADING          = 'Loading...';

	MSG_NO_THEMES        = 'No themes found in \THEMES.';

type
	PThemeList = ^TThemeList;
	TThemeList = record
		FileName: string;
		Next: PThemeList;
	end;

var
	{Main window}
	App:            PApplication;
	WinMain:        PWindow;
	BtnExit,
	BtnAbout,
	BtnPrevious,
	BtnNext:        PButton;
	FrmSettings,
	FrmTheme:       PFrame;
	PrwTheme:       PThemePreview;
	ImgSetting,
	ImgTheme:       PIcon;
	LblSettings,
	LblTheme,
	LblNoThemes:    PLabel;
	ChkSetting:     array[0..5] of PCheckbox;

	{Shared variables}
	NewThemeList:   PThemeList;
	ThemeCount:     integer;
	SelectedTheme:  integer;

procedure AddThemeToList(const ThemeName: string);
var
	NewNode, LastNode: PThemeList;
begin
	{Initialize new node which will be added to the end of ThemeList}
	New(NewNode);
	NewNode^.FileName := ThemeName;
	NewNode^.Next := nil;

	if not Assigned(NewThemeList) then
		{This is the first node being added}
		NewThemeList := NewNode
	else
	begin
		{Previous nodes exists, so find last one and add pointer to new
		 node to it}
		LastNode := NewThemeList;
		while Assigned(LastNode^.Next) do
			LastNode := LastNode^.Next;
		LastNode^.Next := NewNode;
	end;

	Inc(ThemeCount);
end;

procedure LoadThemeList;
var
    FileInfo: SearchRec;
    FPath: DirStr;
    FName: NameStr;
    FExt: ExtStr;
    ExpectedSize: integer;
	BtnLoading: PButton;
begin
	New(BtnLoading, Init(110, 34, CAP_LOADING, nil));
	BtnLoading^.Center(OrBoth);
	Mouse.Hide;
	BtnLoading^.Draw;
	Mouse.Show;
	Dispose(BtnLoading, Done);

    ThemeCount := 0;
    ExpectedSize := SizeOf(TTheme) + 42; {Theme data + two 20-byte strings + 2 bytes for lengths}

    {Load theme filenames into array}
    FindFirst(ProgramPath + 'THEMES\*.BIN', Archive, FileInfo);
    while DosError = 0 do
    begin

        {Load only if size matches expected size}
        if FileInfo.Size = ExpectedSize then
        begin
            FSplit(FileInfo.Name, FPath, FName, FExt);
			AddThemeToList(FName);

			{If this is the currently selected theme, load it into the preview and set it
			 as the selected theme index}
			if FName = Setting.ThmFile then
			begin
				PrwTheme^.LoadFile(FName);
                SelectedTheme := ThemeCount;
			end;
        end;

        FindNext(FileInfo);
    end;

    if SelectedTheme = 0 then
        SelectedTheme := 1;
end;

function SelectedFileName: string;
var
	Node: PThemeList;
	i: Integer;
begin
	if SelectedTheme < 1 then
		SelectedTheme := ThemeCount
	else if SelectedTheme > ThemeCount then
		SelectedTheme := 1;

	Node := NewThemeList;
	i := 1;
	while Assigned(Node) and (i < SelectedTheme) do
	begin
		Node := Node^.Next;
		Inc(i);
	end;

	if i = SelectedTheme then
		SelectedFileName := Node^.FileName
	else
		SelectedFileName := '';
end;

procedure ThemePreview;
var
	FileName: string;
begin
	PrwTheme^.LoadFile(SelectedFileName);
end;

procedure SwitchTheme(Sender: PUIObject); far;
begin
	if PButton(Sender) = BtnPrevious then
		Dec(SelectedTheme)
	else if PButton(Sender) = BtnNext then
		Inc(SelectedTheme);

	ThemePreview;
end;

procedure BtnExitClick(Sender: PUIObject); far;
begin
	if ThemeCount > 0 then
		Setting.ThmFile := SelectedFileName;

	Setting.LinkCapt := ChkSetting[LinkDesc]^.GetChecked;
	Setting.LinkTarget := ChkSetting[LinkTarget]^.GetChecked;
	Setting.ConfLinkDel := ChkSetting[LinkDelete]^.GetChecked;
	Setting.ConfExit := ChkSetting[ConfExit]^.GetChecked;
	Setting.Audio := ChkSetting[Audio]^.GetChecked;

	App^.SaveSystemSettings;
	App^.Terminate;
end;

procedure BtnAboutClick(Sender: PUIObject); far;
begin
	AboutBox(App);
end;

procedure WinMainRun(Sender: PUIObject); far;
begin
	LoadThemeList;

	{Only show theme switch buttons if there are themes available, otherwise
	 show label saying that no themes were found}
	if ThemeCount <> 0 then
	begin
		BtnPrevious^.RemoveState(SHidden);
		BtnNext^.RemoveState(SHidden);
	end
	else
		LblNoThemes^.RemoveState(SHidden);
end;

procedure InitUI;
var
	W, H: Integer;
begin
	New(WinMain, Init(0, 0, nil));
	with WinMain^ do
	begin
		SetSize(GetMaxX, GetMaxY);
		RemoveState(SBordered);
		SetOnRun(WinMainRun);
	end;

	New(BtnAbout, Init(446, 2, CAP_ABOUT, WinMain));
	with BtnAbout^ do
	begin
		AddHotkey(KeyAltA);
		SetOnClick(BtnAboutClick);
	end;
	New(BtnExit, Init(545, 2, CAP_EXIT, WinMain));
	with BtnExit^ do
	begin
		AddHotkey(KeyAltX);
		AddHotkey(KeyAltF4);
		SetOnClick(BtnExitClick);
	end;

	{Settings frame and its contents}
	New(FrmSettings, Init(14, 43, WinMain));
	FrmSettings^.SetSize(310, 293);
	New(ImgSetting, Init(14, 14, 'CONFIG', FrmSettings));
	New(LblSettings, Init(56, 19, CAP_SETTINGS, FrmSettings));
	New(ChkSetting[LinkDesc], Init(14, 56, CAP_LINKDESC, Setting.LinkCapt, FrmSettings));
	ChkSetting[LinkDesc]^.AddHotkey(KeyAltC);
	New(ChkSetting[LinkTarget], Init(14, 78, CAP_LINKTARGET, Setting.LinkTarget, FrmSettings));
	ChkSetting[LinkTarget]^.AddHotkey(KeyAltO);
	New(ChkSetting[LinkDelete], Init(14, 100, CAP_LINKDELETE, Setting.ConfLinkDel, FrmSettings));
	ChkSetting[LinkDelete]^.AddHotkey(KeyAltR);
	New(ChkSetting[ConfExit], Init(14, 122, CAP_CONFEXIT, Setting.ConfExit, FrmSettings));
	ChkSetting[ConfExit]^.AddHotkey(KeyAltE);
	New(ChkSetting[Audio], Init(14, 144, CAP_AUDIO, Setting.Audio, FrmSettings));
	ChkSetting[Audio]^.AddHotkey(KeyAltU);

	{Theme frame and its contents}
	W := 288;
	H := 293;
	New(FrmTheme, Init(338, 43, WinMain));
	FrmTheme^.SetSize(W, H);
	New(ImgTheme, Init(14, 14, 'THEMES', FrmTheme));
	New(LblTheme, Init(56, 19, CAP_THEMES, FrmTheme));
	New(PrwTheme, Init(14, 55, FrmTheme));
	with PrwTheme^ do
	begin
		SetSize(W - 28, 192);
		RemoveState(SEnabled);
		SetLightColor(Thm.Light);
		SetDarkColor(Thm.Shadow);
	end;

	{Theme navigation buttons and no-themes label}
	New(BtnPrevious, Init(14, H - 34, CAP_PREVIOUS, FrmTheme));
	with BtnPrevious^ do
	begin
		AddHotkey(KeyAltP);
		AddHotkey(KeyLeft);
		SetOnClick(SwitchTheme);
		AddState(SHidden);
	end;
	New(BtnNext, Init(W - 92 - 14, H - 34, CAP_NEXT, FrmTheme));
	with BtnNext^ do
	begin
		AddHotkey(KeyAltN);
		AddHotkey(KeyRight);
		SetOnClick(SwitchTheme);
		AddState(SHidden);
	end;
	New(LblNoThemes, Init(0, H - 28, MSG_NO_THEMES, FrmTheme));
	with LblNoThemes^ do
	begin
		AutoSize;
		Center(OrHorizontal);
		AddState(SHidden);
	end;
end;

begin
	New(App, Init);
	App^.SetInfo(AppName, AppVersion, AppAuthor, AppIcon);

	InitUI;

	App^.OpenWindow(WinMain);
	App^.Run;
	App^.Terminate;
end.