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
	frmThemePreview: FrameType;

procedure LoadThemeList;
var
    FileInfo: SearchRec;
    FPath: DirStr;
    FName: NameStr;
    FExt: ExtStr;
    MaxThemesStr: string;
    ExpectedSize: integer;
    mbVoid: Boolean;
begin
    ThemeCount := 0;
    ExpectedSize := SizeOf(ThemeType) + SizeOf(ThemeAuthor) + SizeOf(ThemeName);

    {Load theme filenames into array}
    FindFirst(SysPath + 'THEMES\*.BIN', Archive, FileInfo);
    while DosError = 0 do
    begin
        if ThemeCount = High(ThemeList) then
        begin
            Str(ThemeCount, MaxThemesStr);
            mbVoid := SysMsgBox('Too many themes',
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
	winPreview: WindowType;
	imgLogo, imgDeskLink: ImageType;
	txtPreview: TextboxType;
	btnPreview1, btnPreview2: ButtonType;
	f: file;
	mbVoid, LoadError: boolean;
	ViewWidth, ViewHeight: integer;
begin
	LoadError := False;

	{Load the selected theme file}
	if SelectedTheme < 1 then
		SelectedTheme := ThemeCount
	else if SelectedTheme > ThemeCount then
		SelectedTheme := 1;
	
	Assign(f, SysPath + 'THEMES\' + ThemeList[SelectedTheme] + '.BIN');
	{$I-}
	Reset(f, 1);
	{$I+}
	if IOResult = 0 then
	begin
		BlockRead(f, Theme, SizeOf(ThemeType));
		BlockRead(f, ThemeName, SizeOf(ThemeName));
		BlockRead(f, ThemeAuthor, SizeOf(ThemeAuthor));
	end;
	Close(f);

	ViewWidth := frmThemePreview.Pos.Width - 4;
	ViewHeight := frmThemePreview.Pos.Height - 4;

	winPreview.Init(frmThemePreview.Pos.Left + 14, frmThemePreview.Pos.Top + 12, ViewWidth - 28, 123);
	ObjSetSize(imgLogo.Pos, winPreview.Pos.Left + 12, winPreview.Pos.Top + 12, sizeDefault, sizeDefault);
	ObjSetSize(imgDeskLink.Pos, winPreview.Pos.Left, frmThemePreview.Pos.Top + frmThemePreview.Pos.Height - 42,
		sizeDefault, sizeDefault);
	txtPreview.Init(imgLogo.Pos.Left, imgLogo.Pos.Top + 45, winPreview.Pos.Width - 23, sizeDefault);
	btnPreview1.Init(winPreview.Pos.Left + 12, winPreview.Pos.Top + winPreview.Pos.Height - 34, 86, 22, 'Button');
	btnPreview2.Init(winPreview.Pos.Left + winPreview.Pos.Width - 12 - btnPreview1.Pos.Width,
		btnPreview1.Pos.Top, btnPreview1.Pos.Width, 22, 'Button');
	imgLogo.ImageFile := 'LOGO';
	imgDeskLink.ImageFile := 'PAINT';

	MouseHide;
	SetFillStyle(SolidFill, Theme.Desktop);
	Bar(frmThemePreview.Pos.Left + 2, frmThemePreview.Pos.Top + 2,
		frmThemePreview.Pos.Left + frmThemePreview.Pos.Width - 2, frmThemePreview.Pos.Top + frmThemePreview.Pos.Height - 2);
	
	if LoadError then
	begin
		mbVoid := SysMsgBox('Theme load error',
			'The theme file ' + ThemeList[SelectedTheme] + '.BIN could not be loaded.' + NewLine +
			'Please check that the file is accesible and not corrupted.', msgError);
		Exit;
	end;

	ObjDrawWin(winPreview);
	ObjDrawImg(imgLogo);
	ObjDrawImg(imgDeskLink);
	ObjDrawBtn(btnPreview1, False);
	ObjDrawBtn(btnPreview2, True);
	ObjDrawTxt(txtPreview, 'Example textbox', False);
	
	FontPrint('Preview link', imgDeskLink.Pos.Left + 38, imgDeskLink.Pos.Top + 4, Theme.DesktopText, fontHeading);
	FontPrint('preview.exe', imgDeskLink.Pos.Left + 38, imgDeskLink.Pos.Top + 18, Theme.DesktopText, fontNormal);

	FontPrint(ThemeName, imgLogo.Pos.Left + 42, imgLogo.Pos.Top + 5,
		Theme.WindowText, fontHeading);
	FontPrint(ThemeAuthor, imgLogo.Pos.Left + 42, imgLogo.Pos.Top + 19,
		Theme.WindowText, fontNormal);
	MouseShow;

	SysLoadTheme(Setting.ThemeFile);
end;

var
	btnExit, btnAbout: ButtonType;
	btnPrevious, btnNext: ButtonType;
	frmSettings, frmTheme: FrameType;
	imgSetting, imgTheme: ImageType;
	chkSetting: array[0..4] of CheckboxType;
	
	Key: string;
begin
	SysShowLoading;

	LoadThemeList;

	btnExit.Init(545, 2, 92, 22, 'E' + HotkeySymbol + 'xit');
	btnAbout.Init(446, 2, 92, 22, HotkeySymbol + 'About...');
	
	ObjSetSize(frmSettings.Pos, 14, 43, 310, 293);
	ObjSetSize(frmTheme.Pos, 338, 43, 288, 293);
	ObjSetSize(imgSetting.Pos, frmSettings.Pos.Left + 14, frmSettings.Pos.Top + 14, sizeRetain, sizeRetain);
	ObjSetSize(imgTheme.Pos, frmTheme.Pos.Left + 14, frmTheme.Pos.Top + 14, sizeRetain, sizeRetain);

	ObjSetSize(chkSetting[LinkDesc].Pos, frmSettings.Pos.Left + 14, frmSettings.Pos.Top + 14 + 32 + 10, sizeRetain, sizeRetain);
	ObjSetSize(chkSetting[LinkTarget].Pos, chkSetting[LinkDesc].Pos.Left, chkSetting[LinkDesc].Pos.Top + 22,
		sizeRetain, sizeRetain);
	ObjSetSize(chkSetting[LinkDelete].Pos, chkSetting[LinkDesc].Pos.Left, chkSetting[LinkTarget].Pos.Top + 22,
		sizeRetain, sizeRetain);
	ObjSetSize(chkSetting[ConfExit].Pos, chkSetting[LinkDesc].Pos.Left, chkSetting[LinkDelete].Pos.Top + 22,
		sizeRetain, sizeRetain);

	ObjSetSize(frmThemePreview.Pos, frmTheme.Pos.Left + 14, frmTheme.Pos.Top + 55, frmTheme.Pos.Width - 28, 192);
	btnPrevious.Init(frmTheme.Pos.Left + 14, frmTheme.Pos.Top + frmTheme.Pos.Height - 34,
		92, 22, '< ' + HotkeySymbol + 'Previous');
	btnNext.Init(frmTheme.Pos.Left + frmTheme.Pos.Width - 92 - 14, btnPrevious.Pos.Top,
		92, 22, HotkeySymbol + 'Next >');

	imgSetting.ImageFile := 'CONFIG';
	imgTheme.ImageFile := 'THEMES';

	chkSetting[LinkDesc].Checked := Setting.ShowLinkDescriptions;
	chkSetting[LinkTarget].Checked := Setting.ShowLinkTargetFiles;
	chkSetting[LinkDelete].Checked := Setting.ConfirmLinkDelete;
	chkSetting[ConfExit].Checked := Setting.ConfirmExit;
	
	MouseHide;
	ObjDrawMenu;
	SetFillStyle(SolidFill, Theme.Window);
	Bar(0, 29, 639, 349);
	
	ObjDrawBtn(btnExit, False);
	ObjDrawBtn(btnAbout, False);

	if ThemeCount <> 0 then
	begin
		ObjDrawBtn(btnPrevious, False);
		ObjDrawBtn(btnNext, False);
	end;

	ObjDrawFrm(frmSettings, 15, Theme.Shadow);
	ObjDrawFrm(frmTheme, 15, Theme.Shadow);
	ObjDrawFrm(frmThemePreview, 15, Theme.Shadow);

	ObjDrawChk(chkSetting[LinkDesc]);
	ObjDrawChk(chkSetting[LinkTarget]);
	ObjDrawChk(chkSetting[LinkDelete]);
	ObjDrawChk(chkSetting[ConfExit]);
	ObjDrawImg(imgSetting);
	ObjDrawImg(imgTheme);

	FontPrint('Show icon ' + HotkeySymbol + 'descriptions', chkSetting[LinkDesc].Pos.Left + 20, chkSetting[LinkDesc].Pos.Top + 3,
		Theme.WindowText, fontNormal);
	FontPrint('Show icon ' + HotkeySymbol + 'targets', chkSetting[LinkTarget].Pos.Left + 20, chkSetting[LinkTarget].Pos.Top + 3,
		Theme.WindowText, fontNormal);
	FontPrint('Confirm icon ' + HotkeySymbol + 'removal', chkSetting[LinkDelete].Pos.Left + 20,
		chkSetting[LinkDelete].Pos.Top + 3, Theme.WindowText, fontNormal);
	FontPrint('Confirm before ' + HotkeySymbol + 'exiting Costa', chkSetting[ConfExit].Pos.Left + 20,
		chkSetting[ConfExit].Pos.Top + 3, Theme.WindowText, fontNormal);

	FontPrint('Settings', imgSetting.Pos.Left + 42, imgSetting.Pos.Top + 5, Theme.WindowText, fontHeading);
	FontPrint('Tweak various aspects of Costa.', imgSetting.Pos.Left + 42, imgSetting.Pos.Top + 19, Theme.WindowText, fontNormal);
	FontPrint('Theme', imgTheme.Pos.Left + 42, imgTheme.Pos.Top + 5, Theme.WindowText, fontHeading);
	FontPrint('Choose colors for the UI.', imgTheme.Pos.Left + 42, imgTheme.Pos.Top + 19, Theme.WindowText, fontNormal);

	if ThemeCount = 0 then
		FontPrint('No themes found in \THEMES.', 387, 310, Theme.WindowText, FontNormal);
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
			ObjDrawChk(chkSetting[LinkDesc]);
			MouseShow;
		end;
		if Key = KeyAltT then
		begin
			chkSetting[LinkTarget].Checked:= not chkSetting[LinkTarget].Checked;
			MouseHide;
			ObjDrawChk(chkSetting[LinkTarget]);
			MouseShow;
		end;
		if Key = KeyAltR then
		begin
			chkSetting[LinkDelete].Checked := not chkSetting[LinkDelete].Checked;
			MouseHide;
			ObjDrawChk(chkSetting[LinkDelete]);
			MouseShow;
		end;
		if Key = KeyAltE then
		begin
			chkSetting[ConfExit].Checked := not chkSetting[ConfExit].Checked;
			MouseHide;
			ObjDrawChk(chkSetting[ConfExit]);
			MouseShow;
		end;

		if ObjBtnClick(btnAbout) or (Key = KeyAltA) then
			SysAboutBox(AppName, AppVersion, AppAuthor, AppIcon);

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