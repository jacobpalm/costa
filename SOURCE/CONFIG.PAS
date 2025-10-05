program Configuration;

uses
	CostaLib, UIButton, UITxtbox, UIChkbox, UILabel, UIIcon, UIFrame, MsgDlg, AboutDlg, Graph, DOS;

const
	AppName              = 'Configuration Utility';
	AppVersion           = '2.0';
	AppAuthor            = 'Jacob Palm';
	AppIcon              = 'CONFIG';

	LinkDesc             = 0;
	LinkTarget           = 1;
	LinkDelete           = 2;
	ConfExit             = 3;

	CAP_EXIT             = 'E' + #127 + 'xit';
	CAP_ABOUT            = #127 + 'About...';
	CAP_PREVIOUS         = #27 + ' ' + #127 + 'Previous';
	CAP_NEXT             = #127 + 'Next ' + #26;
	CAP_LINKDESC         = 'Show icon ' + #127 + 'captions';
	CAP_LINKTARGET       = 'Show icon pr' + #127 + 'ogram names';
	CAP_LINKDELETE       = 'Confirm icon ' + #127 + 'removal';
	CAP_CONFEXIT         = 'Confirm before ' + #127 + 'exiting Costa';
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
	MSG_LOAD_ERROR_TITLE = 'Error loading';
	MSG_LOAD_ERROR_TEXT  = 'The theme file %s.BIN could not be loaded.' + #13 +
	                       'Please check that the file is accessible and not corrupted.';

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
	FrmTheme,
	FrmPreview:     PFrame;
	ImgSetting,
	ImgTheme:       PIcon;
	LblSettings,
	LblTheme,
	LblNoThemes:    PLabel;
	ChkSetting:     array[0..4] of PCheckbox;

	{Preview window and its contents}
	WinPreview:     PWindow;
	ImgPreview1,
	ImgPreview2:    PIcon;
	TxtPreview:     PTextbox;
	BtnPreview1,
	BtnPreview2:    PButton;
	LblPreviewInfo: PLabel;
	LblPreviewLink: PLabel;

	{Shared variables}
	NewThemeList:   PThemeList;
	ThemeCount:     integer;
	SelectedTheme:  integer;
	ThemeName:      string[20];
	ThemeAuthor:    string[20];

procedure AddThemeToList(const ThemeName: string); forward;

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
    ExpectedSize := SizeOf(TTheme) + SizeOf(ThemeAuthor) + SizeOf(ThemeName);

    {Load theme filenames into array}
    FindFirst(ProgramPath + 'THEMES\*.BIN', Archive, FileInfo);
    while DosError = 0 do
    begin

        {Load only if size matches expected size}
        if FileInfo.Size = ExpectedSize then
        begin
            FSplit(FileInfo.Name, FPath, FName, FExt);
			AddThemeToList(FName);
			
			if FName = Setting.ThmFile then
                SelectedTheme := ThemeCount;
        end;
		
        FindNext(FileInfo);
    end;

    if SelectedTheme = 0 then
        SelectedTheme := 1;
end;

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
	F: file;
	OrigTheme: TTheme;
	FileName: string;
begin
	OrigTheme := Thm; {Save original theme to restore later}
	
	FileName := SelectedFileName;
	if FileName = '' then
		exit;

	{Load the selected theme file}
	Assign(F, ProgramPath + 'THEMES\' + FileName + '.BIN');
	{$I-}
	Reset(F, 1);
	{$I+}
	if IOResult = 0 then
	begin
		BlockRead(F, Thm, SizeOf(TTheme));
		BlockRead(F, ThemeName, SizeOf(ThemeName));
		BlockRead(F, ThemeAuthor, SizeOf(ThemeAuthor));
	end
	else
	begin
		Thm := OrigTheme; {Restore original theme}
		MsgBox(MSG_LOAD_ERROR_TITLE, ReplaceMsg(MSG_LOAD_ERROR_TEXT, FileName), MsgError);
		Exit;
	end;
	Close(F);

	{Update preview objects with new theme colors}
	Mouse.Hide;
	LblPreviewInfo^.SetCaption(ThemeName + #13 + ThemeAuthor);
	FrmPreview^.SetBgColor(Thm.Desk);
	FrmPreview^.Draw;
	Mouse.Show;

	Thm := OrigTheme; {Restore original theme so objects outside preview are not affected}
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
	App^.SaveSettings;
	
	WinMain^.Close;
	App^.Exit; {Debug - should happen automatically when last window is closed}
end;

procedure BtnAboutClick(Sender: PUIObject); far;
begin
	AboutBox(App);
end;

var
	W, H: Integer;
begin
	New(App, Init);
	with App^ do
	begin
		Name := AppName;
		Version := AppVersion;
		Author := AppAuthor;
		Icon := AppIcon;
	end;

	New(WinMain, Init(0, 0, nil));
	with WinMain^ do
	begin
		SetSize(GetMaxX, GetMaxY);
		Border := False;
		Draw;
	end;

	LoadThemeList;

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

	{Theme frame and its contents}
	W := 288;
	H := 293;
	New(FrmTheme, Init(338, 43, WinMain));
	FrmTheme^.SetSize(W, H);
	New(ImgTheme, Init(14, 14, 'THEMES', FrmTheme));
	New(LblTheme, Init(56, 19, CAP_THEMES, FrmTheme));
	New(FrmPreview, Init(14, 55, FrmTheme));
	with FrmPreview^ do
	begin
		SetSize(W - 28, 192);
		SetBgColor(Thm.Desk);
		RemoveState(SEnabled);
	end;

	{Only create theme switch buttons if there are themes available, otherwise
	 create label saying that no themes were found}
	if ThemeCount <> 0 then
	begin
		New(BtnPrevious, Init(14, H - 34, CAP_PREVIOUS, FrmTheme));
		with BtnPrevious^ do
		begin
			AddHotkey(KeyAltP);
			AddHotkey(KeyLeft);
			SetOnClick(SwitchTheme);
		end;
		New(BtnNext, Init(W - 92 - 14, H - 34, CAP_NEXT, FrmTheme));
		with BtnNext^ do
		begin
			AddHotkey(KeyAltN);
			AddHotkey(KeyRight);
			SetOnClick(SwitchTheme);
		end;
	end
	else
		New(LblNoThemes, Init(387, 310, MSG_NO_THEMES, FrmTheme));

	{Initialize objects in preview frame}
	FrmPreview^.GetSize(W, H);
	{Preivew desktop icon and label}
	New(ImgPreview2, Init(14, H - 42, 'PAINT', FrmPreview));
	New(LblPreviewLink, Init(52, H - 38, CAP_PREVIEW_LINK + #13 + CAP_PREVIEW_EXE, FrmPreview));
	{Preview window and its contents}
	New(WinPreview, Init(14, 12, FrmPreview));
	WinPreview^.SetSize(W - 28, 123);
	New(ImgPreview1, Init(12, 12, 'LOGO', WinPreview));
	New(LblPreviewInfo, Init(54, 16, CAP_CURR_THEME, WinPreview));
	WinPreview^.GetSize(W, H);
	New(TxtPreview, Init(12, 57, '', WinPreview));
	with TxtPreview^ do
	begin
		SetSize(W - 23, SizeRetain);
		Text := CAP_TEXTBOX;
	end;
	New(BtnPreview1, Init(12, H - 34, CAP_BUTTON, WinPreview));
	New(BtnPreview2, Init(W - 104, H - 34, CAP_BUTTON, WinPreview));
	BtnPreview2^.AddState(SActive);

	App^.OpenWindow(WinMain);
	App^.Run;
end.