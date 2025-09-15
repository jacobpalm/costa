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
	App:           TApplication;
	WinMain:       TWindow;
	BtnExit,
	BtnAbout,
	BtnPrevious,
	BtnNext:       TButton;
	FrmSettings,
	FrmTheme:      TFrame;
	FrmPreview:    TFrame;
	ImgSetting,
	ImgTheme:      TIcon;
	LblSettings,
	LblTheme,
	LblNoThemes:   TLabel;
	ChkSetting:    array[0..4] of TCheckbox;

	NewThemeList:  PThemeList;
	ThemeCount:    integer;
	SelectedTheme: integer;
	ThemeName:     string[20];
	ThemeAuthor:   string[20];

	{Objects that are used both in and outside of the main procedure}

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
	New(BtnLoading, Init(sizeCenter, sizeCenter, 110, 34, CAP_LOADING));
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
	WinPreview: TWindow;
	ImgLogo, ImgDeskLink: TIcon;
	TxtPreview: TTextbox;
	BtnPreview1, BtnPreview2: TButton;
	F: file;
	OrigTheme: TTheme;
	LoadError: boolean;
	ViewWidth, ViewHeight: integer;
	FileName: string;
begin
	LoadError := False;
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
		{We don't exit here, because we want to clear the preview window
		 if theme couldn't be loaded}
		Thm := OrigTheme;
		LoadError := True;
	end;

	Close(F);

	ViewWidth := FrmPreview.Width - 4;
	ViewHeight := FrmPreview.Height - 4;

	WinPreview.Init(FrmPreview.Left + 14, FrmPreview.Top + 12, ViewWidth - 28, 123);
	ImgLogo.Init(WinPreview.Left + 12, WinPreview.Top + 12, 'LOGO');
	ImgDeskLink.Init(WinPreview.Left, FrmPreview.Top + FrmPreview.Height - 42, 'PAINT');
	TxtPreview.Init(ImgLogo.Left, ImgLogo.Top + 45, WinPreview.Width - 23, SizeDefault, '');
	TxtPreview.Text := CAP_TEXTBOX;
	BtnPreview1.Init(WinPreview.Left + 12, WinPreview.Top + WinPreview.Height - 34, 86, SizeDefault, CAP_BUTTON);
	BtnPreview2.Init(WinPreview.Left + WinPreview.Width - 12 - BtnPreview1.Width, BtnPreview1.Top, 86, SizeDefault, CAP_BUTTON);

	Mouse.Hide;
	SetFillStyle(SolidFill, Thm.Desk);
	Bar(FrmPreview.Left + 2, FrmPreview.Top + 2,
		FrmPreview.Left + FrmPreview.Width - 2, FrmPreview.Top + FrmPreview.Height - 2);
	
	if LoadError then
	begin
		MsgBox(MSG_LOAD_ERROR_TITLE, ReplaceMsg(MSG_LOAD_ERROR_TEXT, FileName), MsgError);
		Exit;
	end;

	WinPreview.Draw;
	ImgLogo.Draw;
	ImgDeskLink.Draw;
	BtnPreview1.Draw;
	BtnPreview2.Draw;
	TxtPreview.Draw;
	
	Print(CAP_PREVIEW_LINK, ImgDeskLink.Left + 38, ImgDeskLink.Top + 4, Thm.DeskText);
	Print(CAP_PREVIEW_EXE, ImgDeskLink.Left + 38, ImgDeskLink.Top + 18, Thm.DeskText);

	Print(ThemeName, ImgLogo.Left + 42, ImgLogo.Top + 5, Thm.WinText);
	Print(ThemeAuthor, ImgLogo.Left + 42, ImgLogo.Top + 19, Thm.WinText);
	Mouse.Show;

	Thm := OrigTheme; {Restore original theme}
end;

procedure SwitchTheme(Sender: PBaseObject); far;
begin
	if Sender = @BtnPrevious then
		Dec(SelectedTheme)
	else if Sender = @BtnNext then
		Inc(SelectedTheme);

	FrmPreview.Draw;
end;

procedure FrmPreviewDraw(Sender: PBaseObject); far;
begin
	ThemePreview;
end;

procedure BtnExitClick(Sender: PBaseObject); far;
begin
	if ThemeCount > 0 then
		Setting.ThmFile := SelectedFileName;

	Setting.LinkCapt := ChkSetting[LinkDesc].GetChecked;
	Setting.LinkTarget := ChkSetting[LinkTarget].GetChecked;
	Setting.ConfLinkDel := ChkSetting[LinkDelete].GetChecked;
	Setting.ConfExit := ChkSetting[ConfExit].GetChecked;
	App.SaveSettings;
	
	WinMain.Close;
	App.Exit; {Debug - should happen automatically when last window is closed}
end;

procedure BtnAboutClick(Sender: PBaseObject); far;
begin
	AboutBox(@App);
end;

var	
	Key: string;
begin
	with App do
	begin
		Init;
		Name := AppName;
		Version := AppVersion;
		Author := AppAuthor;
		Icon := AppIcon;
	end;

	LoadThemeList;

	with BtnAbout do
	begin
		Init(446, 2, SizeDefault, SizeDefault, CAP_ABOUT);
		AddHotkey(KeyAltA);
		OnClick := BtnAboutClick;
	end;
	with BtnExit do
	begin
		Init(545, 2, SizeDefault, SizeDefault, CAP_EXIT);
		AddHotkey(KeyAltX);
		AddHotkey(KeyAltF4);
		OnClick := BtnExitClick;
	end;
	
	FrmSettings.Init(14, 43, 310, 293);
	ImgSetting.Init(FrmSettings.Left + 14, FrmSettings.Top + 14, 'CONFIG');
	LblSettings.Init(ImgSetting.Left + 42, ImgSetting.Top + 5, SizeDefault, SizeDefault, CAP_SETTINGS);
	with ChkSetting[LinkDesc] do
	begin
		Init(FrmSettings.Left + 14, FrmSettings.Top + 56, CAP_LINKDESC, Setting.LinkCapt);
		AddHotkey(KeyAltC);
	end;
	with ChkSetting[LinkTarget] do
	begin
		Init(ChkSetting[LinkDesc].Left, ChkSetting[LinkDesc].Top + 22, CAP_LINKTARGET, Setting.LinkTarget);
		AddHotkey(KeyAltO);
	end;
	with ChkSetting[LinkDelete] do
	begin
		Init(ChkSetting[LinkDesc].Left, ChkSetting[LinkTarget].Top + 22, CAP_LINKDELETE, Setting.ConfLinkDel);
		AddHotkey(KeyAltR);
	end;
	with ChkSetting[ConfExit] do
	begin
		Init(ChkSetting[LinkDesc].Left, ChkSetting[LinkDelete].Top + 22, CAP_CONFEXIT, Setting.ConfExit);
		AddHotkey(KeyAltE);
	end;

	FrmTheme.Init(338, 43, 288, 293);
	ImgTheme.Init(FrmTheme.Left + 14, FrmTheme.Top + 14, 'THEMES');
	LblTheme.Init(ImgTheme.Left + 42, ImgTheme.Top + 5, SizeDefault, SizeDefault, CAP_THEMES);
	with FrmPreview do
	begin
		Init(FrmTheme.Left + 14, FrmTheme.Top + 55, FrmTheme.Width - 28, 192);
		OnDraw := FrmPreviewDraw;
	end;
	with BtnPrevious do
	begin
		Init(FrmTheme.Left + 14, FrmTheme.Top + FrmTheme.Height - 34, SizeDefault, SizeDefault, CAP_PREVIOUS);
		AddHotkey(KeyAltP);
		AddHotkey(KeyLeft);
		OnClick := SwitchTheme;
	end;
	with BtnNext do
	begin
		Init(FrmTheme.Left + FrmTheme.Width - 92 - 14, BtnPrevious.Top, SizeDefault, SizeDefault, CAP_NEXT);
		AddHotkey(KeyAltN);
		AddHotkey(KeyRight);
		OnClick := SwitchTheme;
	end;
	LblNoThemes.Init(387, 310, SizeDefault, SizeDefault, MSG_NO_THEMES);
	
	with WinMain do
	begin
		Init(0, 0, GetMaxX, GetMaxY);
		Border := False;
		AddObject(@BtnExit);
		AddObject(@BtnAbout);
		AddObject(@FrmSettings);
		AddObject(@FrmTheme);
		AddObject(@FrmPreview);
		AddObject(@ImgSetting);
		AddObject(@ImgTheme);
		AddObject(@LblSettings);
		AddObject(@LblTheme);
		AddObject(@ChkSetting[LinkDesc]);
		AddObject(@ChkSetting[LinkTarget]);
		AddObject(@ChkSetting[LinkDelete]);
		AddObject(@ChkSetting[ConfExit]);
		if ThemeCount <> 0 then
		begin
			AddObject(@BtnPrevious);
			AddObject(@BtnNext);
		end
		else
			AddObject(@LblNoThemes);
	end;

	App.OpenWindow(@WinMain);
	App.Run;
end.