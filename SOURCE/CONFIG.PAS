program Configuration;

uses
	CostaLib, Graph, DOS;

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
	NewThemeList:  PThemeList;
	ThemeCount:    integer;
	SelectedTheme: integer;
	ThemeName:     string[20];
	ThemeAuthor:   string[20];

	{Objects that are used both in and outside of the main procedure}
	FrmThemePreview: TFrame;

procedure AddThemeToList(const ThemeName: string); forward;

procedure LoadThemeList;
var
    FileInfo: SearchRec;
    FPath: DirStr;
    FName: NameStr;
    FExt: ExtStr;
    ExpectedSize: integer;
	BtnLoading: TButton;
begin
	MouseHide;
	BtnLoading.Init(sizeCenter, sizeCenter, 110, 34, CAP_LOADING);
	BtnLoading.Draw;
	MouseShow;

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

	ViewWidth := FrmThemePreview.Width - 4;
	ViewHeight := FrmThemePreview.Height - 4;

	WinPreview.Init(FrmThemePreview.Left + 14, FrmThemePreview.Top + 12, ViewWidth - 28, 123);
	ImgLogo.Init(WinPreview.Left + 12, WinPreview.Top + 12, 'LOGO');
	ImgDeskLink.Init(WinPreview.Left, FrmThemePreview.Top + FrmThemePreview.Height - 42, 'PAINT');
	TxtPreview.Init(ImgLogo.Left, ImgLogo.Top + 45, WinPreview.Width - 23, SizeDefault, '');
	TxtPreview.Text := CAP_TEXTBOX;
	BtnPreview1.Init(WinPreview.Left + 12, WinPreview.Top + WinPreview.Height - 34, 86, SizeDefault, CAP_BUTTON);
	BtnPreview2.Init(WinPreview.Left + WinPreview.Width - 12 - BtnPreview1.Width, BtnPreview1.Top, 86, SizeDefault, CAP_BUTTON);

	MouseHide;
	SetFillStyle(SolidFill, Thm.Desk);
	Bar(FrmThemePreview.Left + 2, FrmThemePreview.Top + 2,
		FrmThemePreview.Left + FrmThemePreview.Width - 2, FrmThemePreview.Top + FrmThemePreview.Height - 2);
	
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

	BtnExit.Init(545, 2, SizeDefault, SizeDefault, CAP_EXIT);
	BtnAbout.Init(446, 2, SizeDefault, SizeDefault, CAP_ABOUT);
	
	FrmSettings.Init(14, 43, 310, 293);
	FrmTheme.Init(338, 43, 288, 293);
	ImgSetting.Init(FrmSettings.Left + 14, FrmSettings.Top + 14, 'CONFIG');
	
	ChkSetting[LinkDesc].Init(FrmSettings.Left + 14, FrmSettings.Top + 56, CAP_LINKDESC);
	ChkSetting[LinkTarget].Init(ChkSetting[LinkDesc].Left, ChkSetting[LinkDesc].Top + 22, CAP_LINKTARGET);
	ChkSetting[LinkDelete].Init(ChkSetting[LinkDesc].Left, ChkSetting[LinkTarget].Top + 22, CAP_LINKDELETE);
	ChkSetting[ConfExit].Init(ChkSetting[LinkDesc].Left, ChkSetting[LinkDelete].Top + 22, CAP_CONFEXIT);
	ChkSetting[LinkDesc].Checked := Setting.LinkCapt;
	ChkSetting[LinkTarget].Checked := Setting.LinkTarget;
	ChkSetting[LinkDelete].Checked := Setting.ConfLinkDel;
	ChkSetting[ConfExit].Checked := Setting.ConfExit;

	FrmThemePreview.Init(FrmTheme.Left + 14, FrmTheme.Top + 55, FrmTheme.Width - 28, 192);
	ImgTheme.Init(FrmTheme.Left + 14, FrmTheme.Top + 14, 'THEMES');
	BtnPrevious.Init(FrmTheme.Left + 14, FrmTheme.Top + FrmTheme.Height - 34, SizeDefault, SizeDefault, CAP_PREVIOUS);
	BtnNext.Init(FrmTheme.Left + FrmTheme.Width - 92 - 14, BtnPrevious.Top, SizeDefault, SizeDefault, CAP_NEXT);
	
	MouseHide;
	MenuBar.Draw;
	SetFillStyle(SolidFill, Thm.Win);
	Bar(0, 29, 639, 349);
	
	BtnExit.Draw;
	BtnAbout.Draw;
	FrmSettings.Draw;
	FrmTheme.Draw;
	FrmThemePreview.Draw;
	ChkSetting[LinkDesc].Draw;
	ChkSetting[LinkTarget].Draw;
	ChkSetting[LinkDelete].Draw;
	ChkSetting[ConfExit].Draw;
	Print(CAP_SETTINGS, ImgSetting.Left + 42, ImgSetting.Top + 5, Thm.WinText);
	Print(CAP_THEMES, ImgTheme.Left + 42, ImgTheme.Top + 5, Thm.WinText);
	ImgSetting.Draw;
	ImgTheme.Draw;

	if ThemeCount <> 0 then
	begin
		BtnPrevious.Draw;
		BtnNext.Draw;
	end
	else
		Print(MSG_NO_THEMES, 387, 310, Thm.WinText);
	MouseShow;

	ThemePreview;

	repeat
		Key := GetKey;

		if ThemeCount > 0 then
		begin
			if BtnPrevious.Clicked or (Key = KeyAltP) or (Key = KeyLeft) then
			 begin
				Dec(SelectedTheme);
				ThemePreview;
			end;

			if BtnNext.Clicked or (Key = KeyAltN) or (Key = KeyRight) then
			begin
				Inc(SelectedTheme);
				ThemePreview;
			end;
		end;

		if ChkSetting[LinkDesc].Clicked or (Key = KeyAltC) then
			ChkSetting[LinkDesc].Toggle;
		if ChkSetting[LinkTarget].Clicked or (Key = KeyAltO) then
			ChkSetting[LinkTarget].Toggle;
		if ChkSetting[LinkDelete].Clicked or (Key = KeyAltR) then
			ChkSetting[LinkDelete].Toggle;
		if ChkSetting[ConfExit].Clicked or (Key = KeyAltE) then
			ChkSetting[ConfExit].Toggle;

		if BtnAbout.Clicked or (Key = KeyAltA) then
			AboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if BtnExit.Clicked or (Key = KeyAltX) or (Key = KeyAltF4) then
		begin
			if ThemeCount > 0 then
				Setting.ThmFile := SelectedFileName;
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