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
	frmThemePreview: TFrame;

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
                'will be shown. Remove some themes to show all.', msgError);
            break;
        end;

        {Load only if size matches expected size}
        if FileInfo.Size = ExpectedSize then
        begin
            FSplit(FileInfo.Name, FPath, FName, FExt);
			Inc(ThemeCount);
            ThemeList[ThemeCount] := FName;
			if FName = Setting.ThemeFile then
                SelectedTheme := ThemeCount;
        end;
		
        FindNext(FileInfo);
    end;

    if SelectedTheme = 0 then
        SelectedTheme := 1;
end;

procedure ThemePreview;
var
	winPreview: TWindow;
	imgLogo, imgDeskLink: TIcon;
	txtPreview: TTextbox;
	btnPreview1, btnPreview2: TButton;
	f: file;
	LoadError: boolean;
	ViewWidth, ViewHeight: integer;
begin
	LoadError := False;

	{Load the selected theme file}
	if SelectedTheme < 1 then
		SelectedTheme := ThemeCount
	else if SelectedTheme > ThemeCount then
		SelectedTheme := 1;
	
	Assign(f, ProgramPath + 'THEMES\' + ThemeList[SelectedTheme] + '.BIN');
	{$I-}
	Reset(f, 1);
	{$I+}
	if IOResult = 0 then
	begin
		BlockRead(f, Theme, SizeOf(TTheme));
		BlockRead(f, ThemeName, SizeOf(ThemeName));
		BlockRead(f, ThemeAuthor, SizeOf(ThemeAuthor));
	end;
	Close(f);

	ViewWidth := frmThemePreview.Width - 4;
	ViewHeight := frmThemePreview.Height - 4;

	winPreview.Init(frmThemePreview.Left + 14, frmThemePreview.Top + 12, ViewWidth - 28, 123);
	imgLogo.Init(winPreview.Left + 12, winPreview.Top + 12, 'LOGO');
	imgDeskLink.Init(winPreview.Left, frmThemePreview.Top + frmThemePreview.Height - 42, 'PAINT');
	txtPreview.Init(imgLogo.Left, imgLogo.Top + 45, winPreview.Width - 23, sizeDefault);
	txtPreview.Text := 'Example textbox';
	btnPreview1.Init(winPreview.Left + 12, winPreview.Top + winPreview.Height - 34, 86, 22, 'Button');
	btnPreview2.Init(winPreview.Left + winPreview.Width - 12 - btnPreview1.Width,
		btnPreview1.Top, btnPreview1.Width, 22, 'Button');

	MouseHide;
	SetFillStyle(SolidFill, Theme.Desktop);
	Bar(frmThemePreview.Left + 2, frmThemePreview.Top + 2,
		frmThemePreview.Left + frmThemePreview.Width - 2, frmThemePreview.Top + frmThemePreview.Height - 2);
	
	if LoadError then
	begin
		MsgBox('Theme load error',
			'The theme file ' + ThemeList[SelectedTheme] + '.BIN could not be loaded.' + NewLine +
			'Please check that the file is accesible and not corrupted.', msgError);
		Exit;
	end;

	winPreview.Draw;;
	imgLogo.Draw;
	imgDeskLink.Draw;
	btnPreview1.Draw;
	btnPreview2.Draw;
	txtPreview.Draw;
	
	Print('Preview link', imgDeskLink.Left + 38, imgDeskLink.Top + 4, Theme.DesktopText);
	Print('preview.exe', imgDeskLink.Left + 38, imgDeskLink.Top + 18, Theme.DesktopText);

	Print(ThemeName, imgLogo.Left + 42, imgLogo.Top + 5, Theme.WindowText);
	Print(ThemeAuthor, imgLogo.Left + 42, imgLogo.Top + 19, Theme.WindowText);
	MouseShow;

	SysLoadTheme(Setting.ThemeFile);
end;

var
	btnExit, btnAbout: TButton;
	btnPrevious, btnNext: TButton;
	frmSettings, frmTheme: TFrame;
	imgSetting, imgTheme: TIcon;
	chkSetting: array[0..4] of TCheckbox;
	
	Key: string;
begin
	SysShowLoading;

	LoadThemeList;

	btnExit.Init(545, 2, sizeDefault, sizeDefault, 'E' + HotkeySymbol + 'xit');
	btnAbout.Init(446, 2, sizeDefault, sizeDefault, HotkeySymbol + 'About...');
	
	frmSettings.Init(14, 43, 310, 293);
	frmTheme.Init(338, 43, 288, 293);
	imgSetting.Init(frmSettings.Left + 14, frmSettings.Top + 14, 'CONFIG');
	
	chkSetting[LinkDesc].Init(frmSettings.Left + 14, frmSettings.Top + 56, sizeDefault, sizeDefault);
	chkSetting[LinkTarget].Init(chkSetting[LinkDesc].Left, chkSetting[LinkDesc].Top + 22, sizeDefault, sizeDefault);
	chkSetting[LinkDelete].Init(chkSetting[LinkDesc].Left, chkSetting[LinkTarget].Top + 22, sizeDefault, sizeDefault);
	chkSetting[ConfExit].Init(chkSetting[LinkDesc].Left, chkSetting[LinkDelete].Top + 22, sizeDefault, sizeDefault);

	frmThemePreview.Init(frmTheme.Left + 14, frmTheme.Top + 55, frmTheme.Width - 28, 192);
	imgTheme.Init(frmTheme.Left + 14, frmTheme.Top + 14, 'THEMES');
	btnPrevious.Init(frmTheme.Left + 14, frmTheme.Top + frmTheme.Height - 34,
		sizeDefault, sizeDefault, '< ' + HotkeySymbol + 'Previous');
	btnNext.Init(frmTheme.Left + frmTheme.Width - 92 - 14, btnPrevious.Top,
		sizeDefault, sizeDefault, HotkeySymbol + 'Next >');

	chkSetting[LinkDesc].Checked := Setting.ShowLinkDescriptions;
	chkSetting[LinkTarget].Checked := Setting.ShowLinkTargetFiles;
	chkSetting[LinkDelete].Checked := Setting.ConfirmLinkDelete;
	chkSetting[ConfExit].Checked := Setting.ConfirmExit;
	
	MouseHide;
	MenuBar.Draw;
	SetFillStyle(SolidFill, Theme.Window);
	Bar(0, 29, 639, 349);
	
	btnExit.Draw;
	btnAbout.Draw;

	if ThemeCount <> 0 then
	begin
		btnPrevious.Draw;
		btnNext.Draw;
	end;

	frmSettings.Draw;
	frmTheme.Draw;
	frmThemePreview.Draw;

	chkSetting[LinkDesc].Draw;
	chkSetting[LinkTarget].Draw;
	chkSetting[LinkDelete].Draw;
	chkSetting[ConfExit].Draw;
	imgSetting.Draw;
	imgTheme.Draw;

	Print('Show icon ' + HotkeySymbol + 'descriptions', chkSetting[LinkDesc].Left + 20, chkSetting[LinkDesc].Top + 3,
		Theme.WindowText);
	Print('Show icon ' + HotkeySymbol + 'targets', chkSetting[LinkTarget].Left + 20, chkSetting[LinkTarget].Top + 3,
		Theme.WindowText);
	Print('Confirm icon ' + HotkeySymbol + 'removal', chkSetting[LinkDelete].Left + 20,
		chkSetting[LinkDelete].Top + 3, Theme.WindowText);
	Print('Confirm before ' + HotkeySymbol + 'exiting Costa', chkSetting[ConfExit].Left + 20,
		chkSetting[ConfExit].Top + 3, Theme.WindowText);

	Print('Settings', imgSetting.Left + 42, imgSetting.Top + 5, Theme.WindowText);
	Print('Tweak various aspects of Costa.', imgSetting.Left + 42, imgSetting.Top + 19, Theme.WindowText);
	Print('Theme', imgTheme.Left + 42, imgTheme.Top + 5, Theme.WindowText);
	Print('Choose colors for the UI.', imgTheme.Left + 42, imgTheme.Top + 19, Theme.WindowText);

	if ThemeCount = 0 then
		Print('No themes found in \THEMES.', 387, 310, Theme.WindowText);
	MouseShow;

	ThemePreview;

	repeat
		Key := GetKey;

		if ThemeCount > 0 then
		begin
			if ObjBtnClick(btnPrevious) or (Key = KeyAltP) or (Key = KeyLeft) then
			 begin
				Dec(SelectedTheme);
				ThemePreview;
			end;

			if ObjBtnClick(btnNext) or (Key = KeyAltN) or (Key = KeyRight) then
			begin
				Inc(SelectedTheme);
				ThemePreview;
			end;
		end;

		ObjChkClick(chkSetting[LinkDesc]);
		ObjChkClick(chkSetting[LinkTarget]);
		ObjChkClick(chkSetting[LinkDelete]);
		ObjChkClick(chkSetting[ConfExit]);

		if Key = KeyAltD then
		begin
			chkSetting[LinkDesc].Checked := not chkSetting[LinkDesc].Checked;
			MouseHide;
			chkSetting[LinkDesc].Draw;
			MouseShow;
		end;
		if Key = KeyAltT then
		begin
			chkSetting[LinkTarget].Checked:= not chkSetting[LinkTarget].Checked;
			MouseHide;
			chkSetting[LinkTarget].Draw;
			MouseShow;
		end;
		if Key = KeyAltR then
		begin
			chkSetting[LinkDelete].Checked := not chkSetting[LinkDelete].Checked;
			MouseHide;
			chkSetting[LinkDelete].Draw;
			MouseShow;
		end;
		if Key = KeyAltE then
		begin
			chkSetting[ConfExit].Checked := not chkSetting[ConfExit].Checked;
			MouseHide;
			chkSetting[ConfExit].Draw;
			MouseShow;
		end;

		if ObjBtnClick(btnAbout) or (Key = KeyAltA) then
			AboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if ObjBtnClick(btnExit) or (Key = KeyAltX) or (Key = KeyAltF4) then
		begin
			if ThemeCount > 0 then
				Setting.ThemeFile := ThemeList[SelectedTheme];
			Setting.ShowLinkDescriptions := chkSetting[LinkDesc].Checked;
			Setting.ShowLinkTargetFiles := chkSetting[LinkTarget].Checked;
			Setting.ConfirmLinkDelete := chkSetting[LinkDelete].Checked;
			Setting.ConfirmExit := chkSetting[ConfExit].Checked;
			SysSaveSettings;
			break;
		end;

	until false;

	CloseGraph;
end.