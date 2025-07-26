program Configuration;

uses
	CostaLib, Graph, DOS;

const
	AppName    = 'Configuration Utility';
	AppVersion = '2.0';
	AppAuthor  = 'Jacob Palm';
	AppIcon    = 'CONFIG';

const
	LinkDesc   = 0;
	LinkTarget = 1;
	LinkDelete = 2;
	ConfExit   = 3;

var
	ThemeList:     array[1..100] of string;
	ThemeCount:    integer;
	SelectedTheme: integer;
	ThemeName:     string[20];
	ThemeAuthor:   string[20];

	{Objects that are used both in and outside of the main procedure}
	FrmThemePreview: TFrame;

procedure LoadThemeList;
var
    FileInfo: SearchRec;
    FPath: DirStr;
    FName: NameStr;
    FExt: ExtStr;
    MaxThemesStr: string;
    ExpectedSize: integer;
begin
    ThemeCount := 0;
    ExpectedSize := SizeOf(TTheme) + SizeOf(ThemeAuthor) + SizeOf(ThemeName);

    {Load theme filenames into array}
    FindFirst(ProgramPath + 'THEMES\*.BIN', Archive, FileInfo);
    while DosError = 0 do
    begin
        if ThemeCount = High(ThemeList) then
        begin
            Str(ThemeCount, MaxThemesStr);
            MsgBox('Too many themes',
                'Only the first ' + MaxThemesStr + ' themes in the THEME directory' + NewLine +
                'will be shown. Remove some themes to show all.', MsgError);
            break;
        end;

        {Load only if size matches expected size}
        if FileInfo.Size = ExpectedSize then
        begin
            FSplit(FileInfo.Name, FPath, FName, FExt);
			Inc(ThemeCount);
            ThemeList[ThemeCount] := FName;
			if FName = Setting.ThmFile then
                SelectedTheme := ThemeCount;
        end;
		
        FindNext(FileInfo);
    end;

    if SelectedTheme = 0 then
        SelectedTheme := 1;
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
begin
	LoadError := False;

	{Load the selected theme file}
	if SelectedTheme < 1 then
		SelectedTheme := ThemeCount
	else if SelectedTheme > ThemeCount then
		SelectedTheme := 1;
	
	OrigTheme := Thm; {Save original theme to restore later}
	
	Assign(F, ProgramPath + 'THEMES\' + ThemeList[SelectedTheme] + '.BIN');
	{$I-}
	Reset(F, 1);
	{$I+}
	if IOResult = 0 then
	begin
		BlockRead(F, Thm, SizeOf(TTheme));
		BlockRead(F, ThemeName, SizeOf(ThemeName));
		BlockRead(F, ThemeAuthor, SizeOf(ThemeAuthor));
	end;
	Close(F);

	ViewWidth := FrmThemePreview.Width - 4;
	ViewHeight := FrmThemePreview.Height - 4;

	WinPreview.Init(FrmThemePreview.Left + 14, FrmThemePreview.Top + 12, ViewWidth - 28, 123);
	ImgLogo.Init(WinPreview.Left + 12, WinPreview.Top + 12, 'LOGO');
	ImgDeskLink.Init(WinPreview.Left, FrmThemePreview.Top + FrmThemePreview.Height - 42, 'PAINT');
	TxtPreview.Init(ImgLogo.Left, ImgLogo.Top + 45, WinPreview.Width - 23, SizeDefault);
	TxtPreview.Text := 'Textbox';
	BtnPreview1.Init(WinPreview.Left + 12, WinPreview.Top + WinPreview.Height - 34, 86, SizeDefault, 'Button');
	BtnPreview2.Init(WinPreview.Left + WinPreview.Width - 12 - BtnPreview1.Width, BtnPreview1.Top, 86, SizeDefault, 'Button');

	MouseHide;
	SetFillStyle(SolidFill, Thm.Desk);
	Bar(FrmThemePreview.Left + 2, FrmThemePreview.Top + 2,
		FrmThemePreview.Left + FrmThemePreview.Width - 2, FrmThemePreview.Top + FrmThemePreview.Height - 2);
	
	if LoadError then
	begin
		MsgBox('Theme load error',
			'The theme file ' + ThemeList[SelectedTheme] + '.BIN could not be loaded.' + NewLine +
			'Please check that the file is accesible and not corrupted.', MsgError);
		Exit;
	end;

	WinPreview.Draw;;
	ImgLogo.Draw;
	ImgDeskLink.Draw;
	BtnPreview1.Draw;
	BtnPreview2.Draw;
	TxtPreview.Draw;
	
	Print('Preview link', ImgDeskLink.Left + 38, ImgDeskLink.Top + 4, Thm.DeskText);
	Print('preview.exe', ImgDeskLink.Left + 38, ImgDeskLink.Top + 18, Thm.DeskText);

	Print(ThemeName, ImgLogo.Left + 42, ImgLogo.Top + 5, Thm.WinText);
	Print(ThemeAuthor, ImgLogo.Left + 42, ImgLogo.Top + 19, Thm.WinText);
	MouseShow;

	Thm := OrigTheme; {Restore original theme}
end;

var
	BtnExit, BtnAbout: TButton;
	BtnPrevious, BtnNext: TButton;
	FrmSettings, FrmTheme: TFrame;
	ImgSetting, ImgTheme: TIcon;
	ChkSetting: array[0..4] of TCheckbox;
	
	Key: string;
begin
	ShowLoading;

	LoadThemeList;

	BtnExit.Init(545, 2, SizeDefault, SizeDefault, 'E' + Hotkey + 'xit');
	BtnAbout.Init(446, 2, SizeDefault, SizeDefault, Hotkey + 'About...');
	
	FrmSettings.Init(14, 43, 310, 293);
	FrmTheme.Init(338, 43, 288, 293);
	ImgSetting.Init(FrmSettings.Left + 14, FrmSettings.Top + 14, 'CONFIG');
	
	ChkSetting[LinkDesc].Init(FrmSettings.Left + 14, FrmSettings.Top + 56, SizeDefault, SizeDefault);
	ChkSetting[LinkTarget].Init(ChkSetting[LinkDesc].Left, ChkSetting[LinkDesc].Top + 22, SizeDefault, SizeDefault);
	ChkSetting[LinkDelete].Init(ChkSetting[LinkDesc].Left, ChkSetting[LinkTarget].Top + 22, SizeDefault, SizeDefault);
	ChkSetting[ConfExit].Init(ChkSetting[LinkDesc].Left, ChkSetting[LinkDelete].Top + 22, SizeDefault, SizeDefault);

	FrmThemePreview.Init(FrmTheme.Left + 14, FrmTheme.Top + 55, FrmTheme.Width - 28, 192);
	ImgTheme.Init(FrmTheme.Left + 14, FrmTheme.Top + 14, 'THEMES');
	BtnPrevious.Init(FrmTheme.Left + 14, FrmTheme.Top + FrmTheme.Height - 34,
		SizeDefault, SizeDefault, CharArrowLeft + ' ' + Hotkey + 'Previous');
	BtnNext.Init(FrmTheme.Left + FrmTheme.Width - 92 - 14, BtnPrevious.Top,
		SizeDefault, SizeDefault, Hotkey + 'Next ' + CharArrowRight);

	ChkSetting[LinkDesc].Checked := Setting.LinkCapt;
	ChkSetting[LinkTarget].Checked := Setting.LinkTarget;
	ChkSetting[LinkDelete].Checked := Setting.ConfLinkDel;
	ChkSetting[ConfExit].Checked := Setting.ConfExit;
	
	MouseHide;
	MenuBar.Draw;
	SetFillStyle(SolidFill, Thm.Win);
	Bar(0, 29, 639, 349);
	
	BtnExit.Draw;
	BtnAbout.Draw;

	if ThemeCount <> 0 then
	begin
		BtnPrevious.Draw;
		BtnNext.Draw;
	end;

	FrmSettings.Draw;
	FrmTheme.Draw;
	FrmThemePreview.Draw;

	ChkSetting[LinkDesc].Draw;
	ChkSetting[LinkTarget].Draw;
	ChkSetting[LinkDelete].Draw;
	ChkSetting[ConfExit].Draw;
	ImgSetting.Draw;
	ImgTheme.Draw;

	Print('Show icon ' + Hotkey + 'descriptions', ChkSetting[LinkDesc].Left + 20, ChkSetting[LinkDesc].Top + 3,
		Thm.WinText);
	Print('Show icon ' + Hotkey + 'targets', ChkSetting[LinkTarget].Left + 20, ChkSetting[LinkTarget].Top + 3,
		Thm.WinText);
	Print('Confirm icon ' + Hotkey + 'removal', ChkSetting[LinkDelete].Left + 20,
		ChkSetting[LinkDelete].Top + 3, Thm.WinText);
	Print('Confirm before ' + Hotkey + 'exiting Costa', ChkSetting[ConfExit].Left + 20,
		ChkSetting[ConfExit].Top + 3, Thm.WinText);

	Print('Settings', ImgSetting.Left + 42, ImgSetting.Top + 5, Thm.WinText);
	Print('Tweak various aspects of Costa.', ImgSetting.Left + 42, ImgSetting.Top + 19, Thm.WinText);
	Print('Theme', ImgTheme.Left + 42, ImgTheme.Top + 5, Thm.WinText);
	Print('Choose colors for the UI.', ImgTheme.Left + 42, ImgTheme.Top + 19, Thm.WinText);

	if ThemeCount = 0 then
		Print('No themes found in \THEMES.', 387, 310, Thm.WinText);
	MouseShow;

	ThemePreview;

	repeat
		Key := GetKey;

		if ThemeCount > 0 then
		begin
			if BtnClick(BtnPrevious) or (Key = KeyAltP) or (Key = KeyLeft) then
			 begin
				Dec(SelectedTheme);
				ThemePreview;
			end;

			if BtnClick(BtnNext) or (Key = KeyAltN) or (Key = KeyRight) then
			begin
				Inc(SelectedTheme);
				ThemePreview;
			end;
		end;

		ChkClick(ChkSetting[LinkDesc]);
		ChkClick(ChkSetting[LinkTarget]);
		ChkClick(ChkSetting[LinkDelete]);
		ChkClick(ChkSetting[ConfExit]);

		if Key = KeyAltD then
		begin
			ChkSetting[LinkDesc].Checked := not ChkSetting[LinkDesc].Checked;
			MouseHide;
			ChkSetting[LinkDesc].Draw;
			MouseShow;
		end;
		if Key = KeyAltT then
		begin
			ChkSetting[LinkTarget].Checked:= not ChkSetting[LinkTarget].Checked;
			MouseHide;
			ChkSetting[LinkTarget].Draw;
			MouseShow;
		end;
		if Key = KeyAltR then
		begin
			ChkSetting[LinkDelete].Checked := not ChkSetting[LinkDelete].Checked;
			MouseHide;
			ChkSetting[LinkDelete].Draw;
			MouseShow;
		end;
		if Key = KeyAltE then
		begin
			ChkSetting[ConfExit].Checked := not ChkSetting[ConfExit].Checked;
			MouseHide;
			ChkSetting[ConfExit].Draw;
			MouseShow;
		end;

		if BtnClick(BtnAbout) or (Key = KeyAltA) then
			AboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if BtnClick(BtnExit) or (Key = KeyAltX) or (Key = KeyAltF4) then
		begin
			if ThemeCount > 0 then
				Setting.ThmFile := ThemeList[SelectedTheme];
			Setting.LinkCapt := ChkSetting[LinkDesc].Checked;
			Setting.LinkTarget := ChkSetting[LinkTarget].Checked;
			Setting.ConfLinkDel := ChkSetting[LinkDelete].Checked;
			Setting.ConfExit := ChkSetting[ConfExit].Checked;
			SysSaveSettings;
			break;
		end;

	until false;

	CloseGraph;
end.