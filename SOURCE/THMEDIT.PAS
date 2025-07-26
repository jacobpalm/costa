program ThemeEditor;

uses
	CostaLib, InputDlg, FileDlg, Graph, DOS;

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
	TThemeObject = (Desk, DeskText, Win, Title, TitleText,
	                WinText, Btn, Txt, TxtText, Light, Shadow,
					Sel, SelText);

var
	ThemeFile: string;
	ThemeChanged: Boolean;
	ThemeData, SysTheme: TTheme;

	SelectedColor: integer;
	SelectedObject: TThemeObject;

	{Objects used in mulitple procedures}
	BtnColor: array[0..15] of TButton;
	BtnObject: TButton;
	TxtName, TxtAuthor: TTextbox;

{Forward declarations}
procedure UpdatePreview; forward;
function  SaveTheme(SaveAs: boolean): boolean; forward;
function  RTrim(s: string): string; forward;

procedure SelectColor(Color: integer; DrawPreview: boolean);
var
	X1, Y1, X2, Y2: Integer;
begin
	if Color < 0 then
		Color := 15
	else if Color > 15 then
		Color := 0;
	
	MouseHide;
	{Erase previous selection}
	X1 := BtnColor[SelectedColor].Left + 4;
	Y1 := BtnColor[SelectedColor].Top + 4;
	X2 := BtnColor[SelectedColor].Left + BtnColor[SelectedColor].Width - 4;
	Y2 := BtnColor[SelectedColor].Top + BtnColor[SelectedColor].Height - 4;
	SetFillStyle(SolidFill, SelectedColor);
	Bar(X1, Y1, X2, Y2);

	{Change color and draw new selection}
	SelectedColor := Color;
	X1 := BtnColor[SelectedColor].Left + 4;
	Y1 := BtnColor[SelectedColor].Top + 4;
	X2 := BtnColor[SelectedColor].Left + BtnColor[SelectedColor].Width - 4;
	Y2 := BtnColor[SelectedColor].Top + BtnColor[SelectedColor].Height - 4;
	SetColor(DarkGray);
	Rectangle(X1, Y1, X2, Y2);
	SetColor(White);
	Rectangle(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
	MouseShow;

	{Change the color of the currently selected object}
	case SelectedObject of
		Desk:      ThemeData.Desk := Color;
		DeskText:  ThemeData.DeskText := Color;
		Win:       ThemeData.Win := Color;
		Title:     ThemeData.Title := Color;
		Titletext: ThemeData.TitleText := Color;
		WinText:   ThemeData.WinText := Color;
		Btn:       ThemeData.Btn := Color;
		Txt:       ThemeData.Txt := Color;
		TxtText:   ThemeData.TxtText := Color;
		Light:     ThemeData.Light := Color;
		Shadow:    ThemeData.Shadow := Color;
		Sel:       ThemeData.Sel := Color;
		SelText:   ThemeData.SelText := Color;
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
	FrmPreview: TFrame;
	WinPreview: TWindow;
	TxtPreview: TTextbox;
	TxtPreviewText: string;
	BtnPreview1, BtnPreview2, BtnPreview3: TButton;
	ImgPreview, ImgLogo: TIcon;
	TxtListPreview: TTextbox;
	X1, Y1, X2, Y2: Integer;
begin
	{Overwrite system theme with current theme}
	Thm := ThemeData;

	FrmPreview.Init(12, 42, 410, 293);
	X1 := FrmPreview.Left;
	Y1 := FrmPreview.Top;
	X2 := FrmPreview.Left + FrmPreview.Width;
	Y2 := FrmPreview.Top + FrmPreview.Height;
	BtnPreview3.Init(X2 - 96, Y1 + 3, SizeDefault, SizeDefault, 'Button');
	TxtListPreview.Init(X2 - 182, Y2 - 82, 166, 66);
	TxtPreviewText := 'Textbox contents';
	ImgPreview.Init(FrmPreview.Left + 16, Y2 - 48, 'PAINT');

	MouseHide;
	FrmPreview.Draw;
	SetFillStyle(SolidFill, Thm.Desk);
	Bar(FrmPreview.Left + 2, Y1 + 2, X2 - 2, Y2 - 2);
	SetFillStyle(SolidFill, Thm.Win);
	Bar(FrmPreview.Left + 2, Y1 + 2, X2 - 2, Y1 + 27);
	SetColor(Thm.Shadow);
	Line(FrmPreview.Left + 2, Y1 + 28, X2 - 2, Y1 + 28);
	SetColor(Black);
	Line(FrmPreview.Left + 2, Y1 + 29, X2 - 2, Y1 + 29);

	WinPreview.Init(X1 + ((FrmPreview.Width - 260) div 2), Y1 + 65, 260, 127);
	X1 := WinPreview.Left;
	Y1 := WinPreview.Top;
	ImgLogo.Init(X1 + 12, Y1 + 12, 'LOGO');
	TxtPreview.Init(X1 + 12, Y1 + 56, 236, SizeDefault);
	TxtPreview.Text := 'Textbox';
	BtnPreview1.Init(X1 + 14, Y1 + 93, 111, SizeDefault, 'Button up');
	BtnPreview2.Init(X1 + 133, Y1 + 93, 111, SizeDefault, 'Button down');
	BtnPreview2.State := BsDown;

	WinPreview.Draw;
	TxtPreview.Draw;
	BtnPreview1.Draw;
	BtnPreview2.Draw;
	BtnPreview3.Draw;
	TxtListPreview.Draw;
	ImgLogo.Draw;
	ImgPreview.Draw;
	
	{Text on Desk and window}
	Print('This is a preview of', ImgLogo.Left + 42, ImgLogo.Top + 5, Thm.WinText);
	Print('your theme.', ImgLogo.Left + 42, ImgLogo.Top + 19, Thm.WinText);
	Print('Preview link', ImgPreview.Left + 38, ImgPreview.Top + 4, Thm.DeskText);
	Print('preview.exe', ImgPreview.Left + 38, ImgPreview.Top + 18, Thm.DeskText);

	{Draw list preview}
	SetFillStyle(SolidFill, Thm.Sel);
	X1 := TxtListPreview.Left;
	Y1 := TxtListPreview.Top;
	X2 := TxtListPreview.Left + TxtListPreview.Width;
	Bar(X1 + 2, Y1 + 15, X2 - 2, Y1 + 27);
	Print('List item', X1 + 5, Y1 + 5, Thm.TxtText);
	Print('Selected item', X1 + 5, Y1 + 5 + 12, Thm.SelText);
	Print('List item', X1 + 5, Y1 + 5 + 24, Thm.TxtText);
	Print('List item', X1 + 5, Y1 + 5 + 36, Thm.TxtText);
	Print('List item', X1 + 5, Y1 + 5 + 48, Thm.TxtText);
	MouseShow;

	{Restore system theme}
	Thm := SysTheme;
end;

procedure SelectObject;
var
	WinSelectObject: TWindow;
	BtnObjSelect: array[0..12] of TButton;
	i: integer;
	ActiveSelection: TThemeObject;
	NextSelection: integer;
	Key: string;
	X1, Y1, X2, Y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	ExitLoop: boolean;
begin
	ExitLoop := False;
	WinSelectObject.Init(sizeCenter, sizeCenter, 226, 326);
	for i := 0 to High(BtnObjSelect) do
		BtnObjSelect[I].Init(WinSelectObject.Left + 13, WinSelectObject.Top + (I * 23) + 15, 200, SizeDefault, ObjectCaptions[i]);

	MouseHide;
	X1 := WinSelectObject.Left;
	Y1 := WinSelectObject.Top;
	X2 := WinSelectObject.Left + WinSelectObject.Width;
	Y2 := WinSelectObject.Top + WinSelectObject.Height;
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);
	
	WinSelectObject.Draw;
	ActiveSelection := SelectedObject;
	for i := 0 to High(BtnObjSelect) do
	begin
		if i = Ord(ActiveSelection) then
			BtnObjSelect[i].State := BsDown
		else
			BtnObjSelect[i].State := BsUp;
		BtnObjSelect[i].Draw;
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

		for i := 0 to High(BtnObjSelect) do
			if BtnClick(BtnObjSelect[i]) then
			begin
				SelectedObject := TThemeObject(i);
				ExitLoop := True;
			end;

		{Cycle up or down through list}
		if (Key = KeyUp) or (Key = KeyDown) then
		begin
			MouseHide;
			BtnObjSelect[Ord(ActiveSelection)].State := BsUp;
			BtnObjSelect[Ord(ActiveSelection)].Draw;
			if Key = KeyUp then
				NextSelection := Ord(ActiveSelection) - 1
			else
				NextSelection := Ord(ActiveSelection) + 1;
			
			if NextSelection < 0 then
				NextSelection := High(BtnObjSelect)
			else if NextSelection > High(BtnObjSelect) then
				NextSelection := 0;
				ActiveSelection := TThemeObject(NextSelection);
			BtnObjSelect[Ord(ActiveSelection)].State := BsDown;
			BtnObjSelect[Ord(ActiveSelection)].Draw;
			MouseShow;
		end;

	until ExitLoop;
	MouseHide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	BtnObject.Caption := ObjectCaptions[Ord(SelectedObject)];
	BtnObject.Draw;
	MouseShow;

	{Change the color of the currently selected object}
	case SelectedObject of
		Desk:      SelectColor(ThemeData.Desk, false);
		DeskText:  SelectColor(ThemeData.DeskText, false);
		Win:       SelectColor(ThemeData.Win, false);
		Title:     SelectColor(ThemeData.Title, false);
		TitleText: SelectColor(ThemeData.TitleText, false);
		WinText:   SelectColor(ThemeData.WinText, false);
		Btn:       SelectColor(ThemeData.Btn, false);
		Txt:       SelectColor(ThemeData.Txt, false);
		TxtText:   SelectColor(ThemeData.TxtText, false);
		Light:     SelectColor(ThemeData.Light, false);
		Shadow:    SelectColor(ThemeData.Shadow, false);
		Sel:       SelectColor(ThemeData.Sel, false);
		SelText:   SelectColor(ThemeData.SelText, false);
	end;
end;

procedure NewTheme;
var
	DoSave: boolean;
begin
	if ThemeChanged then
	begin
		DoSave := MsgBox(MSG_UNSAVED_CHANGES_TITLE, MSG_UNSAVED_CHANGES_PROMPT, MsgQuest);
		if DoSave then
			if not SaveTheme(false) then
				exit; {Theme was not saved, exit}
	end;

	{Start with current theme as basis for editing}
	ThemeData := Thm;
	ThemeFile := '';
	TxtName.Text := 'New Theme';
	TxtAuthor.Text := '';
	TxtName.Draw;
	TxtAuthor.Draw;
	SelectColor(ThemeData.Desk, true);
	ThemeChanged := False;
end;

procedure LoadTheme;
var
	SelectedFile: string;
	LoadName, LoadAuthor: string[20];
	FDir: DirStr;
	FName: NameStr;
	FExt: ExtStr;
	F: File;
	LoadError: boolean;
	DoSave: boolean;
begin
	if ThemeChanged then
	begin
		DoSave := MsgBox(MSG_UNSAVED_CHANGES_TITLE, MSG_UNSAVED_CHANGES_PROMPT, MsgQuest);
		if DoSave then
			if not SaveTheme(false) then
				exit; {Theme was not saved, exit}
	end;
	
	SelectedFile := FileSelect('*.BIN', 'THEMES', True);
	if Length(SelectedFile) = 0 then
		exit;

	FSplit(SelectedFile, FDir, FName, FExt);
	if not (FDir = ProgramPath + 'THEMES\') or not (FExt = '.BIN') then
	begin
		MsgBox(MSG_ERROR_OPENING_TITLE, MSG_INVALID_THEME_FILE, MsgError);
		exit;
	end;

	LoadError := False;
	Assign(F, ProgramPath + 'THEMES\' + FName + '.BIN');
	{$I-}
	Reset(F, 1);
	{$I+}
	if IOResult <> 0 then
		LoadError := True
	else if FileSize(F) <> SizeOf(TTheme) + 42 then
		LoadError := True;
	
	if LoadError then
	begin
		Close(F);
		MsgBox(MSG_ERROR_OPENING_TITLE, MSG_ERROR_OPENING, MsgError);
		exit;
	end;

	BlockRead(F, ThemeData, SizeOf(TTheme));
	BlockRead(F, LoadName, SizeOf(LoadName));
	BlockRead(F, LoadAuthor, SizeOf(LoadAuthor));
	Close(F);

	TxtName.Text := Rtrim(LoadName);
	TxtAuthor.Text := Rtrim(LoadAuthor);
	SelectColor(ThemeData.Desk, true);
	ThemeFile := SelectedFile;
	TxtName.Draw;
	TxtAuthor.Draw;
	ThemeChanged := False;
end;

function SaveTheme(SaveAs: boolean): boolean;
var	
	F: File;
	Filename: string;
	SaveName, SaveAuthor: string[20];
	SaveError: boolean;
	MbResult: boolean;
begin
	SaveTheme := False;

	if (Length(ThemeFile) = 0) or SaveAs then
	begin
		Filename := UpperCase(InputBox(MSG_FILENAME_TITLE, MSG_FILENAME_PROMPT, AppIcon, ''));

		{Validate input}
		if Length(Filename) = 0 then
			exit;

		if not Valid8dot3(FileName + '.BIN') then
		begin
			MsgBox(MSG_ERROR_SAVING_TITLE, MSG_INVALID_FILENAME, MsgError);
			exit;
		end;

		Filename := ProgramPath + 'THEMES\' + FileName + '.BIN';
	end
	else
		Filename := ThemeFile;

	{Check if file already exists}
	if FileExists(Filename) and (Filename <> ThemeFile) then
	begin
		mbResult := MsgBox(MSG_FILE_EXISTS_TITLE, MSG_FILE_EXISTS_PROMPT, MsgQuest);
		if mbResult = false then
			exit;
	end;

	FillChar(SaveName, SizeOf(SaveName), 0);
	FillChar(SaveAuthor, SizeOf(SaveAuthor), 0);
	SaveName := TxtName.Text;
	SaveAuthor := TxtAuthor.Text;
	Assign(F, Filename);
	{$I-}
	Rewrite(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		MsgBox(MSG_ERROR_SAVING_TITLE, MSG_ERROR_SAVING, MsgError);
		exit;
	end;
	BlockWrite(F, ThemeData, SizeOf(TTheme));
	BlockWrite(F, SaveName, SizeOf(SaveName));
	BlockWrite(F, SaveAuthor, SizeOf(SaveAuthor));
	Close(F);
	ThemeFile := Filename;
	ThemeChanged := False;
	SaveTheme := True;
end;

function RTrim(s: string): string;
var
	endIdx: Integer;
begin
	endIdx := Length(s);
	while (endIdx > 0) and (s[endIdx] = ' ') do
		Dec(endIdx);
	RTrim := Copy(s, 1, endIdx);
end;

var
	BtnNew, BtnOpen, BtnSave, BtnSaveAs: TButton;
	BtnAbout, BtnExit: TButton;

	i, YPos, XPos: integer;
	OriginalText: string[20];
	Key: string;
	DoSave: boolean;
begin
	MouseHide;
	MenuBar.Draw;
	SetFillStyle(SolidFill, Thm.Win);
	Bar(0, 29, 639, 349);

	BtnNew.Init(2, 2, SizeDefault, SizeDefault, Hotkey + 'New');
	BtnOpen.Init(101, 2, SizeDefault, SizeDefault, Hotkey + 'Load');
	BtnSave.Init(200, 2, SizeDefault, SizeDefault, Hotkey + 'Save');
	BtnSaveAs.Init(299, 2, SizeDefault, SizeDefault, 'Sa' + Hotkey + 've as');
	BtnAbout.Init(446, 2, SizeDefault, SizeDefault, Hotkey + 'About...');
	BtnExit.Init(545, 2, SizeDefault, SizeDefault, 'E' + Hotkey + 'xit');
	TxtName.Init(434, 59, 194, SizeDefault);
	TxtAuthor.Init(434, TxtName.Top + 48, 194, SizeDefault);
	BtnObject.Init(434, TxtAuthor.Top + 48, 194, SizeDefault, 'Desk');

	TxtName.MaxLen := 20;
	TxtAuthor.MaxLen := 20;

	YPos := 0;
	XPos := 0;
	for I := 0 to 15 do
	begin
		if I = 8 then
		begin
			YPos := 25;
			XPos := 0;
		end;
		BtnColor[i].Init(TxtAuthor.Left + XPos, TxtAuthor.Top + 98 + YPos, 19, 19, '');
		BtnColor[i].Transparent := True;
		Inc(XPos, 25);
	end;

	MouseHide;
	BtnNew.Draw;
	BtnOpen.Draw;
	BtnSave.Draw;
	BtnSaveAs.Draw;
	BtnAbout.Draw;
	BtnExit.Draw;
	TxtName.Draw;
	TxtAuthor.Draw;
	BtnObject.Draw;
	for i := 0 to 15 do
	begin
		BtnColor[i].State := BsDown;
		BtnColor[i].Draw;
		SetFillStyle(SolidFill, i);
		Bar(BtnColor[i].Left + 2, BtnColor[i].Top + 2, BtnColor[i].Left + BtnColor[i].Width - 2,
			BtnColor[i].Top + BtnColor[i].Height - 2);
	end;

	Print('Theme na' + Hotkey + 'me:', TxtName.Left, TxtName.Top - 16,
		Thm.WinText);
	Print('Theme a' + Hotkey + 'uthor:', TxtAuthor.Left, TxtAuthor.Top - 16,
		Thm.WinText);
	Print(Hotkey + 'Object selected:', 434, BtnObject.Top - 16, Thm.WinText);
	Print(Hotkey + 'Color for object:', 434, BtnColor[0].Top - 16, Thm.WinText);
	
	{Save system theme}
	SysTheme := Thm;
	NewTheme;

	repeat
		Key := GetKey;

		for i := 0 to 15 do
			if ObjClick(BtnColor[i]) then
				SelectColor(i, true);

		if Key = KeyAltC then
			SelectColor(SelectedColor + 1, true);

		if BtnClick(BtnNew) or (Key = KeyAltN) then
			NewTheme;

		if BtnClick(BtnOpen) or (Key = KeyAltL) then
			LoadTheme;
		
		if BtnClick(BtnSave) or (Key = KeyAltS) then
			SaveTheme(false);

		if BtnClick(BtnSaveAs) or (Key = KeyAltV) then
			SaveTheme(true);

		if BtnClick(BtnObject) or (Key = KeyAltO) then
			SelectObject;

		if TxtClick(TxtName) or (Key = KeyAltM) then
		begin
			OriginalText := TxtName.Text;
			TxtName.Edit;
			if not (TxtName.Text = OriginalText) then
				ThemeChanged := True;
		end;

		if TxtClick(TxtAuthor) or (Key = KeyAltU) then
		begin
			OriginalText := TxtAuthor.Text;
			TxtAuthor.Edit;
			if not (TxtAuthor.Text = OriginalText) then
				ThemeChanged := True;
		end;

		if BtnClick(BtnAbout) or (Key = KeyAltA) then
			AboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if BtnClick(BtnExit) or (Key = KeyAltX) or (Key = KeyEscape) then
		begin
			{No changes, just exit}
			if ThemeChanged = False then
				break;

			{Otherwise, ask to save}
			DoSave := MsgBox(MSG_UNSAVED_CHANGES_TITLE, MSG_UNSAVED_CHANGES_PROMPT, MsgQuest);
			if not DoSave then
				break;
			
			{User wants to save, do so and exit if successful}
			if SaveTheme(false) then
				break;
		end;
					
	until false;
	CloseGraph;
end.