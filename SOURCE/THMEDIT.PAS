program ThemeEditor;

uses
	CostaLib, InputBox, FileSel, Graph, DOS;

const
	AppName      = 'Theme Editor';
	AppVersion   = '2.0';
	AppAuthor    = 'Jacob Palm';
	AppIcon      = 'THEMES';

	ObjectCaptions: array[0..12] of string = (
		'Desktop', 'Desktop text', 'Window', 'Window border', 'Window title',
		'Window text', 'Button', 'Textbox', 'Textbox text', '3D light',
		'3D Shadow', 'Selection', 'Selection text');

	MSG_FILE_EXISTS_TITLE      = 'File already exists';
	MSG_FILE_EXISTS_PROMPT     = 'The specified file already exists. Do you want' + #13 +
	                             'to overwrite it?';
	MSG_INVALID_THEME_FILE     = 'The selected file is not a valid theme file. Please' + #13 +
	                             'select a .BIN file from the THEMES directory.';
	MSG_ERROR_OPENING_TITLE    = 'Error opening theme file';
	MSG_ERROR_OPENING          = 'The selected theme file could not be opened.' + #13 +
	                             'Please check the file and try again.';
	MSG_UNSAVED_CHANGES_TITLE  = 'Theme has been modified';
	MSG_UNSAVED_CHANGES_PROMPT = 'This theme contains unsaved changes. Do you' + #13 +
	                             'want to save before you continue?';
	MSG_FILENAME_TITLE	       = 'Save theme file';
	MSG_FILENAME_PROMPT        = 'Type a name for the theme file below, without path or' + #13 +
	                             'extension (8 letters max, for example: MYTHEME).';
	MSG_INVALID_FILENAME       = 'The filename you specified was too long or invalid.' + #13 +
	                             'Do not type a path or extension, only a filename' + #13 +
	                             'with a maximum length of 8 characters.';
	MSG_ERROR_SAVING_TITLE     = 'Error saving theme file';
	MSG_ERROR_SAVING           = 'The theme file could not be saved. Verify free disk' + #13 +
	                             'space and that the directory isn''t write-protected.';


type
	TThemeObject = (Desktop, DesktopText, Window, Titlebar, TitlebarText,
	                WindowText, Button, Textbox, TextBoxText, Light, Shadow,
					Select, SelectText);

var
	ThemeFile: string;
	ThemeName, ThemeAuthor: string;
	ThemeChanged: Boolean;
	ThemeData, SysTheme: ThemeType;

	SelectedColor: integer;
	SelectedObject: TThemeObject;

	{Objects used in mulitple procedures}
	btnColor: array[0..15] of ButtonType;
	btnObject: ButtonType;
	txtThemeName, txtThemeAuthor: TextboxType;

{Forward declarations}
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
		Desktop:      ThemeData.Desktop := Color;
		DesktopText:  ThemeData.DesktopText := Color;
		Window:       ThemeData.Window := Color;
		Titlebar:     ThemeData.Titlebar := Color;
		Titlebartext: ThemeData.TitlebarText := Color;
		WindowText:   ThemeData.WindowText := Color;
		Button:       ThemeData.Button := Color;
		Textbox:      ThemeData.Textbox := Color;
		TextboxText:  ThemeData.TextBoxText := Color;
		Light:        ThemeData.Light := Color;
		Shadow:       ThemeData.Shadow := Color;
		Select:       ThemeData.Select := Color;
		SelectText:   ThemeData.SelectText := Color;
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
	x1, y1, x2, y2: Integer;
begin
	{Overwrite system theme with current theme}
	Theme := ThemeData;

	frmPreview.Init(12, 42, 410, 293);
	x1 := frmPreview.Pos.Left;
	y1 := frmPreview.Pos.Top;
	x2 := frmPreview.Pos.Left + frmPreview.Pos.Width;
	y2 := frmPreview.Pos.Top + frmPreview.Pos.Height;
	btnPreview3.Init(x2 - 96, y1 + 3, sizeDefault, sizeDefault, 'Button');
	txtListPreview.Init(x2 - 182, y2 - 82, 166, 66);
	txtPreviewText := 'Textbox contents';
	imgPreview.Init(frmPreview.Pos.Left + 16, y2 - 48, 'LOGO');
	imgPreview.ImageFile := 'LOGO';

	MouseHide;
	ObjDrawFrm(frmPreview, 15, Theme.Shadow);
	SetFillStyle(SolidFill, Theme.Desktop);
	Bar(frmPreview.Pos.Left + 2, y1 + 2, x2 - 2, y2 - 2);
	SetFillStyle(SolidFill, Theme.Window);
	Bar(frmPreview.Pos.Left + 2, y1 + 2, x2 - 2, y1 + 27);
	SetColor(Theme.Shadow);
	Line(frmPreview.Pos.Left + 2, y1 + 28, x2 - 2, y1 + 28);
	SetColor(Black);
	Line(frmPreview.Pos.Left + 2, y1 + 29, x2 - 2, y1 + 29);

	winPreview.Init(x1 + ((frmPreview.Pos.Width - 260) div 2), y1 + 65, 260, 127);
	x1 := winPreview.Pos.Left;
	y1 := winPreview.Pos.Top;
	txtPreview.Init(x1 + 12, y1 + 56, 236, 19);
	btnPreview1.Init(x1 + 14, y1 + 93, 111, sizeDefault, 'Button up');
	btnPreview2.Init(x1 + 133, y1 + 93, 111, sizeDefault, 'Button down');

	ObjDrawWin(winPreview);
	ObjDrawTxt(txtPreview, txtPreviewText, True);
	btnPreview1.Draw;
	btnPreview2.Draw;
	btnPreview3.Draw;
	ObjDrawImg(imgPreview);
	ObjDrawTxt(txtListPreview, '', False);

	{Text on desktop and window}
	FontPrint('This is a preview of your', x1 + 12, y1 + 14, Theme.WindowText);
	FontPrint('theme in action.', x1 + 12, y1 + 30, Theme.WindowText);
	FontPrint('Preview link', imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 4, Theme.DesktopText);
	FontPrint('preview.exe', imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 18, Theme.DesktopText);

	{Draw list preview}
	SetFillStyle(SolidFill, Theme.Select);
	x1 := txtListPreview.Pos.Left;
	y1 := txtListPreview.Pos.Top;
	x2 := txtListPreview.Pos.Left + txtListPreview.Pos.Width;
	Bar(x1 + 2, y1 + 15, x2 - 2, y1 + 27);
	FontPrint('List item', x1 + 5, y1 + 5, Theme.TextboxText);
	FontPrint('Selected item', x1 + 5, y1 + 5 + 12, Theme.SelectText);
	FontPrint('List item', x1 + 5, y1 + 5 + 24, Theme.TextboxText);
	FontPrint('List item', x1 + 5, y1 + 5 + 36, Theme.TextboxText);
	FontPrint('List item', x1 + 5, y1 + 5 + 48, Theme.TextboxText);
	MouseShow;

	{Restore system theme}
	Theme := SysTheme;
end;

procedure SelectObject;
var
	winSelectObject: WindowType;
	btnObjSelect: array[0..12] of ButtonType;
	i: integer;
	ActiveSelection: TThemeObject;
	NextSelection: integer;
	Key: string;
	x1, y1, x2, y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	ExitLoop: boolean;
begin
	ExitLoop := False;
	winSelectObject.Init(sizeCenter, sizeCenter, 226, 326);
	for i := 0 to High(btnObjSelect) do
		btnObjSelect[I].Init(winSelectObject.Pos.Left + 13, winSelectObject.Pos.Top + (I * 23) + 15, 200, 22, ObjectCaptions[i]);

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
	for i := 0 to High(btnObjSelect) do
	begin
		if i = Ord(ActiveSelection) then
			btnObjSelect[i].State := bsDown
		else
			btnObjSelect[i].State := bsUp;
		btnObjSelect[i].Draw;
	end;
	MouseShow;

	repeat
		Key := GetKey;

		if Key = KeyEnter then
		begin
			SelectedObject := ActiveSelection;
			break;
		end;

		if Key = KeyEscape then
			break;

		for i := 0 to High(btnObjSelect) do
			if ObjBtnClick(btnObjSelect[i]) then
			begin
				SelectedObject := TThemeObject(i);
				ExitLoop := True;
			end;

		{Cycle up or down through list}
		if (Key = KeyUp) or (Key = KeyDown) then
		begin
			MouseHide;
			btnObjSelect[Ord(ActiveSelection)].State := bsUp;
			btnObjSelect[Ord(ActiveSelection)].Draw;
			if Key = KeyUp then
				NextSelection := Ord(ActiveSelection) - 1
			else
				NextSelection := Ord(ActiveSelection) + 1;
			
			if NextSelection < 0 then
				NextSelection := High(btnObjSelect)
			else if NextSelection > High(btnObjSelect) then
				NextSelection := 0;
				ActiveSelection := TThemeObject(NextSelection);
			btnObjSelect[Ord(ActiveSelection)].State := bsDown;
			btnObjSelect[Ord(ActiveSelection)].Draw;
			MouseShow;
		end;

	until ExitLoop;
	MouseHide;
	PutImage(x1, y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	btnObject.Caption := ObjectCaptions[Ord(SelectedObject)];
	btnObject.Draw;
	MouseShow;

	{Change the color of the currently selected object}
	case SelectedObject of
		Desktop:      SelectColor(ThemeData.Desktop, false);
		DesktopText:  SelectColor(ThemeData.DesktopText, false);
		Window:       SelectColor(ThemeData.Window, false);
		Titlebar:     SelectColor(ThemeData.Titlebar, false);
		TitlebarText: SelectColor(ThemeData.TitlebarText, false);
		WindowText:   SelectColor(ThemeData.WindowText, false);
		Button:       SelectColor(ThemeData.Button, false);
		Textbox:      SelectColor(ThemeData.Textbox, false);
		TextboxText:  SelectColor(ThemeData.TextBoxText, false);
		Light:        SelectColor(ThemeData.Light, false);
		Shadow:       SelectColor(ThemeData.Shadow, false);
		Select:       SelectColor(ThemeData.Select, false);
		SelectText:   SelectColor(ThemeData.SelectText, false);
	end;
end;

procedure NewTheme;
var
	DoSave: boolean;
begin
	if ThemeChanged then
	begin
		DoSave := SysMsgBox(MSG_UNSAVED_CHANGES_TITLE, MSG_UNSAVED_CHANGES_PROMPT, msgQuest);
		if DoSave then
			if not SaveTheme(false) then
				exit; {Theme was not saved, exit}
	end;

	{Start with current theme as basis for editing}
	ThemeData := Theme;
	ThemeFile := '';
	ThemeName := 'New Theme';
	ThemeAuthor := '';
	ObjDrawTxt(txtThemeName, ThemeName, False);
	ObjDrawTxt(txtThemeAuthor, ThemeAuthor, False);
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
	DoSave: boolean;
begin
	if ThemeChanged then
	begin
		DoSave := SysMsgBox(MSG_UNSAVED_CHANGES_TITLE, MSG_UNSAVED_CHANGES_PROMPT, msgQuest);
		if DoSave then
			if not SaveTheme(false) then
				exit; {Theme was not saved, exit}
	end;
	
	SelectedFile := FileSelect('*.BIN', 'THEMES', True);
	if Length(SelectedFile) = 0 then
		exit;

	FSplit(SelectedFile, FDir, FName, FExt);
	if not (FDir = SysPath + 'THEMES\') or not (FExt = '.BIN') then
	begin
		SysMsgBox(MSG_ERROR_OPENING_TITLE, MSG_INVALID_THEME_FILE, msgError);
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
		SysMsgBox(MSG_ERROR_OPENING_TITLE, MSG_ERROR_OPENING, msgError);
		exit;
	end;

	BlockRead(f, ThemeData, SizeOf(ThemeType));
	BlockRead(f, LoadName, SizeOf(LoadName));
	BlockRead(f, LoadAuthor, SizeOf(LoadAuthor));
	Close(f);

	ThemeName := Rtrim(LoadName);
	ThemeAuthor := Rtrim(LoadAuthor);
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
	MbResult: boolean;
begin
	SaveTheme := False;

	if (Length(ThemeFile) = 0) or SaveAs then
	begin
		Filename := UpperCase(SysInputBox(MSG_FILENAME_TITLE, MSG_FILENAME_PROMPT, AppIcon, ''));

		{Validate input}
		if Length(Filename) = 0 then
			exit;

		if not ValidDOSFilename(FileName + '.BIN') then
		begin
			SysMsgBox(MSG_ERROR_SAVING_TITLE, MSG_INVALID_FILENAME, msgError);
			exit;
		end;

		Filename := SysPath + 'THEMES\' + FileName + '.BIN';
	end
	else
		Filename := ThemeFile;

	{Check if file already exists}
	if FileExists(Filename) and (Filename <> ThemeFile) then
	begin
		mbResult := SysMsgBox(MSG_FILE_EXISTS_TITLE, MSG_FILE_EXISTS_PROMPT, msgQuest);
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
		SysMsgBox(MSG_ERROR_SAVING_TITLE, MSG_ERROR_SAVING, msgError);
		exit;
	end;
	BlockWrite(f, ThemeData, SizeOf(ThemeType));
	BlockWrite(f, SaveName, SizeOf(SaveName));
	BlockWrite(f, SaveAuthor, SizeOf(SaveAuthor));
	Close(f);
	ThemeFile := Filename;
	ThemeChanged := False;
	SaveTheme := True;
end;

var
	btnNew, btnOpen, btnSave, btnSaveAs: ButtonType;
	btnAbout, btnExit: ButtonType;

	i, YPos, XPos: integer;
	OriginalText: string[20];
	Key: string;
	DoSave: boolean;
begin
	MouseHide;
	ObjDrawMenu;
	SetFillStyle(SolidFill, Theme.Window);
	Bar(0, 29, 639, 349);

	btnNew.Init(2, 2, sizeDefault, sizeDefault, HotkeySymbol + 'New');
	btnOpen.Init(101, 2, sizeDefault, sizeDefault, HotkeySymbol + 'Load');
	btnSave.Init(200, 2, sizeDefault, sizeDefault, HotkeySymbol + 'Save');
	btnSaveAs.Init(299, 2, sizeDefault, sizeDefault, 'Sa' + HotkeySymbol + 've as');
	btnAbout.Init(446, 2, sizeDefault, sizeDefault, HotkeySymbol + 'About...');
	btnExit.Init(545, 2, sizeDefault, sizeDefault, 'E' + HotkeySymbol + 'xit');
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
		btnColor[i].Init(txtThemeAuthor.Pos.Left + XPos, txtThemeAuthor.Pos.Top + 98 + YPos, 19, 19, '');
		btnColor[i].Transparent := True;
		Inc(XPos, 25);
	end;

	MouseHide;
	btnNew.Draw;
	btnOpen.Draw;
	btnSave.Draw;
	btnSaveAs.Draw;
	btnAbout.Draw;
	btnExit.Draw;
	ObjDrawTxt(txtThemeName, ThemeName, False);
	ObjDrawTxt(txtThemeAuthor, ThemeAuthor, False);
	btnObject.Draw;
	for i := 0 to 15 do
	begin
		btnColor[i].State := bsDown;
		btnColor[i].Draw;
		SetFillStyle(SolidFill, i);
		Bar(btnColor[i].Pos.Left + 2, btnColor[i].Pos.Top + 2, btnColor[i].Pos.Left + btnColor[i].Pos.Width - 2,
			btnColor[i].Pos.Top + btnColor[i].Pos.Height - 2);
	end;

	FontPrint('Theme na' + HotkeySymbol + 'me:', txtThemeName.Pos.Left, txtThemeName.Pos.Top - 16,
		Theme.WindowText);
	FontPrint('Theme a' + HotkeySymbol + 'uthor:', txtThemeAuthor.Pos.Left, txtThemeAuthor.Pos.Top - 16,
		Theme.WindowText);
	FontPrint(HotkeySymbol + 'Object selected:', 434, btnObject.Pos.Top - 16, Theme.WindowText);
	FontPrint(HotkeySymbol + 'Color for object:', 434, btnColor[0].Pos.Top - 16, Theme.WindowText);
	
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
			{No changes, just exit}
			if ThemeChanged = False then
				break;

			{Otherwise, ask to save}
			DoSave := SysMsgBox(MSG_UNSAVED_CHANGES_TITLE, MSG_UNSAVED_CHANGES_PROMPT, msgQuest);
			if not DoSave then
				break;
			
			{User wants to save, do so and exit if successful}
			if SaveTheme(false) then
				break;
		end;
					
	until false;
	CloseGraph;
end.