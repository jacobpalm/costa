program ThemeEditor;

uses
	CostaLib, InputBox, FileSel, Graph, DOS;

const
	AppName    = 'Theme Editor';
	AppVersion = '2.0';
	AppAuthor  = 'Jacob Palm';
	AppIcon    = 'THEMES';

var
	ThemeFile: string;
	ThemeName, ThemeAuthor: string;
	ThemeChanged: Boolean;
	ThemeData, SysTheme: ThemeType;

	SelectedColor: integer;
	SelectedObject: integer;

	{Objects used in mulitple procedures}
	btnColor: array[0..15] of ButtonType;
	btnObject: ButtonType;
	txtThemeName, txtThemeAuthor: TextboxType;

{Forward declarations}
procedure SelectColor(Color: integer; DrawPreview: boolean); forward;
procedure SelectObject; forward;
procedure LoadTheme; forward;
procedure UpdatePreview; forward;
function  SaveTheme(SaveAs: boolean): boolean; forward;

procedure SelectColor(Color: integer; DrawPreview: boolean);
var
	x1, y1, x2, y2: Integer;
begin
	if Color < 0 then
		Color := 15
	else if Color > 15 then
		Color := 0;
	
	MouseHide;
	{Erase previous selection}
	x1 := btnColor[SelectedColor].Pos.Left + 4;
	y1 := btnColor[SelectedColor].Pos.Top + 4;
	x2 := btnColor[SelectedColor].Pos.Left + btnColor[SelectedColor].Pos.Width - 4;
	y2 := btnColor[SelectedColor].Pos.Top + btnColor[SelectedColor].Pos.Height - 4;
	SetFillStyle(SolidFill, SelectedColor);
	Bar(x1, y1, x2, y2);

	{Change color and draw new selection}
	SelectedColor := Color;
	x1 := btnColor[SelectedColor].Pos.Left + 4;
	y1 := btnColor[SelectedColor].Pos.Top + 4;
	x2 := btnColor[SelectedColor].Pos.Left + btnColor[SelectedColor].Pos.Width - 4;
	y2 := btnColor[SelectedColor].Pos.Top + btnColor[SelectedColor].Pos.Height - 4;
	SetColor(DarkGray);
	Rectangle(x1, y1, x2, y2);
	SetColor(White);
	Rectangle(x1 + 1, y1 + 1, x2 - 1, y2 - 1);
	MouseShow;

	{Change the color of the currently selected object}
	case SelectedObject of
		1:  ThemeData.Desktop := Color;
		2:  ThemeData.DesktopText := Color;
		3:  ThemeData.Window := Color;
		4:  ThemeData.Titlebar := Color;
		5:  ThemeData.WindowText := Color;
		6:  ThemeData.Button := Color;
		7:  ThemeData.Textbox := Color;
		8:  ThemeData.TextBoxText := Color;
		9:  ThemeData.Light := Color;
		10: ThemeData.Shadow := Color;
		11: ThemeData.Select := Color;
		12: ThemeData.SelectText := Color;
		13: ThemeData.TitlebarText := Color;
	end;
	
	{Mark theme as changed and update preview}
	if DrawPreview then
	begin
		ThemeChanged := True;
		UpdatePreview;
	end;
end;

procedure UpdatePreview;
var
	frmPreview: FrameType;
	winPreview: WindowType;
	txtPreview: TextboxType;
	txtPreviewText: string;
	btnPreview1, btnPreview2, btnPreview3: ButtonType;
	imgPreview: ImageType;
	txtListPreview: TextboxType;
begin
	ObjSetSize(frmPreview.Pos, 12, 42, 410, 293);
	MouseHide;
	ObjDrawFrm(frmPreview, 15, Theme.Shadow);
	MouseShow;

	{Overwrite system theme with current theme}
	Theme := ThemeData;

	winPreview.Init(frmPreview.Pos.Left + ((frmPreview.Pos.Width - 260) div 2),
		frmPreview.Pos.Top + 65, 260, 127);
	txtPreview.Init(winPreview.Pos.Left + 12, winPreview.Pos.Top + 56, 236, 19);
	btnPreview1.Init(winPreview.Pos.Left + 14, winPreview.Pos.Top + 93, 111, 22, 'Button up');
	btnPreview2.Init(winPreview.Pos.Left + 133, winPreview.Pos.Top + 93, 111, 22, 'Button down');
	btnPreview3.Init(frmPreview.Pos.Left + frmPreview.Pos.Width - 96, frmPreview.Pos.Top + 3, 92, 22, 'Menu button');
	txtListPreview.Init(frmPreview.Pos.Left + frmPreview.Pos.Width - 182,
		frmPreview.Pos.Top + frmPreview.Pos.Height - 82, 166, 66);
	txtPreviewText := 'Textbox contents';
	ObjSetSize(imgPreview.Pos, frmPreview.Pos.Left + 16, frmPreview.Pos.Top +
		frmPreview.Pos.Height - 48, sizeRetain, sizeRetain);
	imgPreview.ImageFile := 'LOGO';

	MouseHide;
	SetFillStyle(SolidFill, Theme.Desktop);
	Bar(frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2,
		frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + frmPreview.Pos.Height - 2);
	SetFillStyle(SolidFill, Theme.Window);
	Bar(frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2, frmPreview.Pos.Left + frmPreview.Pos.Width - 2,
		frmPreview.Pos.Top + 27);
	SetColor(Theme.Shadow);
	Line(frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 28, frmPreview.Pos.Left + frmPreview.Pos.Width - 2,
		frmPreview.Pos.Top + 28);
	SetColor(Black);
	Line(frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 29, frmPreview.Pos.Left + frmPreview.Pos.Width - 2,
		frmPreview.Pos.Top + 29);

	ObjDrawWin(winPreview);
	ObjDrawTxt(txtPreview, txtPreviewText, True);
	ObjDrawBtn(btnPreview1, False);
	ObjDrawBtn(btnPreview2, True);
	ObjDrawBtn(btnPreview3, False);
	ObjDrawImg(imgPreview);
	ObjDrawTxt(txtListPreview, '', False);

	FontPrint('This is a preview of the theme', winPreview.Pos.Left + 12, winPreview.Pos.Top + 14,
		Theme.WindowText, FontHeading);
	FontPrint('you are editing.', winPreview.Pos.Left + 12, winPreview.Pos.Top + 30,
		Theme.WindowText, FontNormal);
	FontPrint('Preview link', imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 4, Theme.DesktopText, FontHeading);
	FontPrint('preview.exe', imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 18, Theme.DesktopText, FontNormal);

	SetFillStyle(SolidFill, Theme.Select);
	Bar(txtListPreview.Pos.Left + 2, txtListPreview.Pos.Top + 15, txtListPreview.Pos.Left + txtListPreview.Pos.Width - 2,
		txtListPreview.Pos.Top + 27);
	FontPrint('List item', txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5, Theme.TextboxText, FontHeading);
	FontPrint('Selected item', txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 12, Theme.SelectText, FontHeading);
	FontPrint('List item', txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 24, Theme.TextboxText, FontHeading);
	FontPrint('List item', txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 36, Theme.TextboxText, FontHeading);
	FontPrint('List item', txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 48, Theme.TextboxText, FontHeading);
	MouseShow;

	{Restore system theme}
	Theme := SysTheme;
end;

procedure SelectObject;
var
	winSelectObject: WindowType;
	btnObjSelect: array[1..13] of ButtonType;
	i, ActiveSelection: integer;
	Key: string;
	x1, y1, x2, y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
begin
	winSelectObject.Init(sizeCenter, sizeCenter, 226, 326);
	for i := 1 to 13 do
		btnObjSelect[I].Init(winSelectObject.Pos.Left + 13, winSelectObject.Pos.Top + (I * 23) - 8, 200, 22, '');
	
	btnObjSelect[1].Caption := 'Desktop';
	btnObjSelect[2].Caption := 'Desktop text';
	btnObjSelect[3].Caption := 'Window';
	btnObjSelect[4].Caption := 'Window border';
	btnObjSelect[5].Caption := 'Window text';
	btnObjSelect[6].Caption := 'Button';
	btnObjSelect[7].Caption := 'Textbox';
	btnObjSelect[8].Caption := 'Textbox text';
	btnObjSelect[9].Caption := '3D light';
	btnObjSelect[10].Caption := '3D Shadow';
	btnObjSelect[11].Caption := 'Selection';
	btnObjSelect[12].Caption := 'Selection text';
	btnObjSelect[13].Caption := 'Titlebar text';

	MouseHide;
	x1 := winSelectObject.Pos.Left;
	y1 := winSelectObject.Pos.Top;
	x2 := winSelectObject.Pos.Left + winSelectObject.Pos.Width;
	y2 := winSelectObject.Pos.Top + winSelectObject.Pos.Height;
	BackgroundSize := ImageSize(x1, y1, x2, y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(x1, y1, x2, y2, BackgroundP^);
	
	ObjDrawWin(winSelectObject);
	ActiveSelection := SelectedObject;
	for i := 1 to 13 do
		ObjDrawBtn(btnObjSelect[i], (i = ActiveSelection));
	MouseShow;

	repeat
		Key := GetKey;

		if Key = KeyEnter then
		begin
			SelectedObject := ActiveSelection;
			break;
		end;

		if Key = KeyEscape then
		begin
			break;
		end;

		{DEBUG - broken}
		if MouseClicked <> mbNone then
		begin
			for i := 1 to 12 do
			begin
				if ObjBtnClick(btnObjSelect[i]) then
				begin
					SelectedObject := i;
					break;
				end;
			end;
		end;

		if Key = KeyUp then
		begin
			MouseHide;
			ObjDrawBtn(btnObjSelect[ActiveSelection], False);
			if ActiveSelection > 1 then
				Dec(ActiveSelection)
			else
				ActiveSelection := 13;
			ObjDrawBtn(btnObjSelect[ActiveSelection], True);
			MouseShow;
		end;

		if Key = KeyDown then
		begin
			MouseHide;
			ObjDrawBtn(btnObjSelect[ActiveSelection], False);
			if ActiveSelection < 13 then
				Inc(ActiveSelection)
			else
				ActiveSelection := 1;
			ObjDrawBtn(btnObjSelect[ActiveSelection], True);
			MouseShow;
		end;

	until false;
	MouseHide;
	PutImage(x1, y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	btnObject.Caption := btnObjSelect[SelectedObject].Caption;
	ObjDrawBtn(btnObject, False);
	MouseShow;

	{Change the color of the currently selected object}
	case SelectedObject of
		1:  SelectColor(ThemeData.Desktop, false);
		2:  SelectColor(ThemeData.DesktopText, false);
		3:  SelectColor(ThemeData.Window, false);
		4:  SelectColor(ThemeData.Titlebar, false);
		5:  SelectColor(ThemeData.WindowText, false);
		6:  SelectColor(ThemeData.Button, false);
		7:  SelectColor(ThemeData.Textbox, false);
		8:  SelectColor(ThemeData.TextBoxText, false);
		9:  SelectColor(ThemeData.Light, false);
		10: SelectColor(ThemeData.Shadow, false);
		11: SelectColor(ThemeData.Select, false);
		12: SelectColor(ThemeData.SelectText, false);
		13: SelectColor(ThemeData.TitlebarText, false);
	end;
end;

procedure NewTheme;
begin
	{DEBUG - check if theme should be saved first}

	{Start with current theme as basis for editing}
	ThemeData := Theme;
	ThemeFile := '';
	SelectedObject := 1; {Desktop}
	SelectColor(ThemeData.Desktop, true);
	ThemeChanged := False;
end;

procedure LoadTheme;
var
	SelectedFile: string;
	LoadName, LoadAuthor: string[20];
	FDir: DirStr;
	FName: NameStr;
	FExt: ExtStr;
	f: File;
	LoadError: boolean;
begin
	{DEBUG - check if theme should be saved first}
	SelectedFile := FileSelect('*.BIN', 'THEMES', True);
	if Length(SelectedFile) = 0 then
		exit;

	FSplit(SelectedFile, FDir, FName, FExt);
	if not (FDir = SysPath + 'THEMES\') or not (FExt = '.BIN') then
	begin
		SysMsgBox('Invalid theme file',
			'The selected file is not a valid theme file. Please' + NewLine +
			'select a .BIN file from the THEMES directory.',
			msgError);
		exit;
	end;

	LoadError := False;
	Assign(f, SysPath + 'THEMES\' + FName + '.BIN');
	{$I-}
	Reset(f, 1);
	{$I+}
	if IOResult <> 0 then
		LoadError := True
	else if FileSize(f) <> SizeOf(ThemeType) + 42 then
		LoadError := True;
	
	if LoadError then
	begin
		Close(f);
		SysMsgBox('Error opening theme file',
			'The selected theme file could not be opened.' + NewLine +
			'Please check the file and try again.',
			msgError);
		exit;
	end;

	BlockRead(f, ThemeData, SizeOf(ThemeType));
	BlockRead(f, LoadName, SizeOf(LoadName));
	BlockRead(f, LoadAuthor, SizeOf(LoadAuthor));
	Close(f);

	ThemeName := Rtrim(LoadName);
	ThemeAuthor := Rtrim(LoadAuthor);
	SelectedObject := 1; {Desktop}
	SelectColor(ThemeData.Desktop, true);
	ThemeFile := SelectedFile;
	ObjDrawTxt(txtThemeName, ThemeName, False);
	ObjDrawTxt(txtThemeAuthor, ThemeAuthor, False);
	ThemeChanged := False;
end;

function SaveTheme(SaveAs: boolean): boolean;
var	
	f: File;
	Filename: string;
	SaveName, SaveAuthor: string[20];
	SaveError: boolean;
begin
	SaveTheme := False;

	if (Length(ThemeFile) = 0) or SaveAs then
	begin
		Filename := UpperCase(SysInputBox('Save theme file', 'Type a name for the theme file below, without path or' + NewLine +
			'extension (8 letters max, for example: MYTHEME).', 'THEME', ''));

		{Validate input}
		if Length(Filename) = 0 then
			exit;
		if (Length(Filename) > 8) or (not ValidDOSFilename(FileName + '.BIN')) then
		begin
			SysMsgBox('Invalid file name', 'The filename you specified was too long or invalid.' + NewLine +
				'Do not type a path or extension, only a filename' + NewLine
				+ 'with a maximum length of 8 characters.', msgError);
			exit;
		end;

		Filename := SysPath + 'THEMES\' + FileName + '.BIN';
	end
	else
		Filename := ThemeFile;

	{Check if file already exists}
	if FileExists(Filename) and (Filename <> ThemeFile) then
	begin
		mbResult := SysMsgBox('File already exists', 'The specified icon file already exists. Do you want' + NewLine
			+ 'to overwrite it with this icon?', msgQuest);
		if mbResult = false then
			exit;
	end;

	FillChar(SaveName, SizeOf(SaveName), 0);
	FillChar(SaveAuthor, SizeOf(SaveAuthor), 0);
	SaveName := ThemeName;
	SaveAuthor := ThemeAuthor;
	Assign(f, Filename);
	{$I-}
	Rewrite(f, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		SysMsgBox('Error saving theme file', 'The theme file could not be saved. Verify free disk' + NewLine +
			'space and that the directory isn''t write-protected.', msgError);
		exit;
	end;
	BlockWrite(f, ThemeData, SizeOf(ThemeType));
	BlockWrite(f, SaveName, SizeOf(SaveName));
	BlockWrite(f, SaveAuthor, SizeOf(SaveAuthor));
	Close(f);
	ThmeFile := Filename;
	SaveTheme := True;
end;

var
	btnNew, btnOpen, btnSave, btnSaveAs: ButtonType;
	btnAbout, btnExit: ButtonType;

	i, YPos, XPos: integer;
	OriginalText: string[20];
	Key: string;
begin
	MouseHide;
	ObjDrawMenu;
	SetFillStyle(SolidFill, Theme.Window);
	Bar(0, 29, 639, 349);

	btnNew.Init(2, 2, 92, 22, HotkeySymbol + 'New');
	btnOpen.Init(101, 2, 92, 22, HotkeySymbol + 'Load');
	btnSave.Init(200, 2, 92, 22, HotkeySymbol + 'Save');
	btnSaveAs.Init(299, 2, 92, 22, 'Sa' + HotkeySymbol + 've as');
	btnAbout.Init(446, 2, 92, 22, HotkeySymbol + 'About...');
	btnExit.Init(545, 2, 92, 22, 'E' + HotkeySymbol + 'xit');
	txtThemeName.Init(434, 59, 194, 0);
	txtThemeAuthor.Init(434, txtThemeName.Pos.Top + 48, 194, 0);
	btnObject.Init(434, txtThemeAuthor.Pos.Top + 48, 194, 0, 'Desktop');

	txtThemeName.MaxLen := 20;
	txtThemeAuthor.MaxLen := 20;

	YPos := 0;
	XPos := 0;
	for I := 0 to 15 do
	begin
		if I = 8 then
		begin
			YPos := 25;
			XPos := 0;
		end;
		ObjSetSize(btnColor[i].Pos, txtThemeAuthor.Pos.Left + XPos, txtThemeAuthor.Pos.Top + 98 + YPos, 19, 19);
		btnColor[i].Transparent := True;
		Inc(XPos, 25);
	end;

	MouseHide;
	ObjDrawBtn(btnNew, False);
	ObjDrawBtn(btnOpen, False);
	ObjDrawBtn(btnSave, False);
	ObjDrawBtn(btnSaveAs, False);
	ObjDrawBtn(btnAbout, False);
	ObjDrawBtn(btnExit, False);
	ObjDrawTxt(txtThemeName, ThemeName, False);
	ObjDrawTxt(txtThemeAuthor, ThemeAuthor, False);
	ObjDrawBtn(btnObject, False);
	for i := 0 to 15 do
	begin
		ObjDrawBtn(btnColor[i], True);
		SetFillStyle(SolidFill, i);
		Bar(btnColor[i].Pos.Left + 2, btnColor[i].Pos.Top + 2, btnColor[i].Pos.Left + btnColor[i].Pos.Width - 2,
			btnColor[i].Pos.Top + btnColor[i].Pos.Height - 2);
	end;

	FontPrint('Theme na' + HotkeySymbol + 'me:', txtThemeName.Pos.Left, txtThemeName.Pos.Top - 16,
		Theme.WindowText, FontHeading);
	FontPrint('Theme a' + HotkeySymbol + 'uthor:', txtThemeAuthor.Pos.Left, txtThemeAuthor.Pos.Top - 16,
		Theme.WindowText, FontHeading);
	FontPrint(HotkeySymbol + 'Object selected:', 434, btnObject.Pos.Top - 16, Theme.WindowText, FontHeading);
	FontPrint(HotkeySymbol + 'Color for object:', 434, btnColor[0].Pos.Top - 16, Theme.WindowText, FontHeading);
	{Save system theme}
	SysTheme := Theme;

	NewTheme;

	repeat
		Key := GetKey;

		for i := 0 to 15 do
			if ObjClick(btnColor[i].Pos) then
				SelectColor(i, true);

		if Key = KeyAltC then
			SelectColor(SelectedColor + 1, true);

		if ObjBtnClick(btnNew) or (Key = KeyAltN) then
			NewTheme;

		if ObjBtnClick(btnOpen) or (Key = KeyAltL) then
			LoadTheme;
		
		if ObjBtnClick(btnSave) or (Key = KeyAltS) then
			SaveTheme(false);

		if ObjBtnClick(btnSaveAs) or (Key = KeyAltV) then
			SaveTheme(true);

		if ObjBtnClick(btnObject) or (Key = KeyAltO) then
			SelectObject;

		if ObjTxtClick(txtThemeName) or (Key = KeyAltM) then
		begin
			OriginalText := ThemeName;
			ObjEditTxt(txtThemeName, ThemeName);
			if not (ThemeName = OriginalText) then
				ThemeChanged := True;
		end;

		if ObjTxtClick(txtThemeAuthor) or (Key = KeyAltU) then
		begin
			OriginalText := ThemeAuthor;
			ObjEditTxt(txtThemeAuthor, ThemeAuthor);
			if not (ThemeAuthor = OriginalText) then
				ThemeChanged := True;
		end;

		if ObjBtnClick(btnAbout) or (Key = KeyAltA) then
			SysAboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if ObjBtnClick(btnExit) or (Key = KeyAltX) or (Key = KeyEscape) then
		begin
			if ThemeChanged = False then
				break;

			if SysMsgBox('Theme has been modified', 'This theme contains unsaved changes. Do you' + NewLine
			+ 'want to save before you exit?', msgQuest) then
				SaveTheme(false);
			
			break;
			{Debug - if not saved and user said they wanted to, then cancel}
		end;
					
	until false;
	CloseGraph;
end.