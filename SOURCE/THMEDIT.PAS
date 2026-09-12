program ThemeEditor;

uses
	CostaLib, UIButton, UILabel, UITxtbox, UIArea, UIFrame, UIIcon, UIThmPrw,
	AboutDlg, MsgDlg, InputDlg, ThmSelec, FileDlg, DOS, Graph;

const
	AppName           = 'Theme Editor';
	AppVersion        = '2.0';
	AppAuthor         = 'Jacob Palm';
	AppIcon           = 'THEMES';

	DefaultName       = 'New Theme';

	CAP_NEW           = #127 + 'New';
	CAP_OPEN          = #127 + 'Open...';
	CAP_SAVE          = #127 + 'Save';
	CAP_SAVE_AS       = 'Sa' + #127 + 've as...';
	CAP_ABOUT         = #127 + 'About...';
	CAP_EXIT          = 'E' + #127 + 'xit';
	CAP_NAME          = 'Theme na' + #127 + 'me';
	CAP_AUTHOR        = 'Theme a' + #127 + 'uthor';
	CAP_OBJECT_SEL    = 'O' + #127 + 'bject selected:';
	CAP_COLOR_SEL     = #127 + 'Color for object:';

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
	MSG_PREVIEW                = 'This is a preview of' + #13 + 'your theme';

var
	App:              PApplication;

	{Main screen}
	WinMain:          PWindow;
	AreaColor:        Array[0..15] of PArea;
	BtnNew,
	BtnOpen,
	BtnObject,
	BtnSave,
	BtnSaveAs,
	BtnAbout,
	BtnExit:          PButton;
	TxtName,
	TxtAuthor:        PTextbox;
	PrwTheme:         PThemePreview;
	LblObject,
	LblColor:         PLabel;
	HkNextColor:      PHotkey;

	ThemeFile:        String;
	ThemeChanged:     Boolean;
	ThemeData,
	SysTheme:         TTheme;

	SelectedColor:    Integer;
	SelectedObject:   TThemeObject;

{Forward declarations}
function  SaveTheme(SaveAs: boolean): boolean; forward;
function  RTrim(s: string): string; forward;

procedure SelectColor(Color: integer; DrawPreview: boolean);
var
	PreviousColor: Integer;
begin
	if Color < 0 then
		Color := 15
	else if Color > 15 then
		Color := 0;

	{Adding dirty states triggers redraw}
	AreaColor[SelectedColor]^.AddState(SDirty);
	AreaColor[Color]^.AddState(SDirty);
	SelectedColor := Color;

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
		PrwTheme^.LoadMem(@ThemeData, TxtName^.Text, TxtAuthor^.Text);
	end;
end;

procedure SelectNextColor(Sender: PUIObject); far;
begin
	SelectColor(SelectedColor + 1, true);
end;

procedure BtnObjectClick(Sender: PUIObject); far;
begin
	SelectedObject := SelectThemeObject(SelectedObject);

	{Change the color selection to the currently selected object}
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

	BtnObject^.SetCaption(CAP_OBJECT[Ord(SelectedObject)]);
end;

procedure NewTheme(Sender: PUIObject); far;
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
	TxtName^.SetText(DefaultName);
	TxtAuthor^.SetText('');
	SelectColor(ThemeData.Desk, false);
	PrwTheme^.LoadMem(@Thm, '', '');
	ThemeChanged := False;
end;

procedure LoadTheme(Sender: PUIObject); far;
var
	SelectedFile: string;
	LoadName, LoadAuthor: string[20];
	ExpectedSize: Integer;
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

	SelectedFile := FileSelect('*.BIN', 'THEMES');
	if Length(SelectedFile) = 0 then
		exit;

	FSplit(SelectedFile, FDir, FName, FExt);
	if not (FDir = App^.Path + 'THEMES\') or not (FExt = '.BIN') then
	begin
		MsgBox(MSG_ERROR_OPENING_TITLE, MSG_INVALID_THEME_FILE, MsgError);
		exit;
	end;

	LoadError := False;
	ExpectedSize := SizeOf(ThemeData) + SizeOf(LoadName) + SizeOf(LoadAuthor);
	Assign(F, App^.Path + 'THEMES\' + FName + '.BIN');
	FileMode := FileRead;
	{$I-}
	Reset(F, 1);
	{$I+}
	if IOResult <> 0 then
		LoadError := True
	else if FileSize(F) <> ExpectedSize then
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

	TxtName^.SetText(RTrim(LoadName));
	TxtAuthor^.SetText(RTrim(LoadAuthor));
	SelectColor(ThemeData.Desk, False);
	ThemeFile := SelectedFile;
	PrwTheme^.LoadMem(@ThemeData, LoadName, LoadAuthor);
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

		Filename := App^.Path + 'THEMES\' + FileName + '.BIN';
	end
	else
		Filename := ThemeFile;

	{Check if file already exists}
	if FileExists(Filename) and (Filename <> ThemeFile) then
	begin
		MbResult := MsgBox(MSG_FILE_EXISTS_TITLE, MSG_FILE_EXISTS_PROMPT, MsgQuest);
		if MbResult = false then
			exit;
	end;

	FillChar(SaveName, SizeOf(SaveName), 0);
	FillChar(SaveAuthor, SizeOf(SaveAuthor), 0);
	SaveName := TxtName^.Text;
	SaveAuthor := TxtAuthor^.Text;
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

procedure AreaColorDraw(Sender: PUIObject); far;
var
	X1, Y1, X2, Y2: integer;
begin
	if PArea(Sender) = AreaColor[SelectedColor] then
	begin
		AreaColor[SelectedColor]^.GetAbsPos(X1, Y1);
		X2 := X1 + AreaColor[SelectedColor]^.Width;
		Y2 := Y1 + AreaColor[SelectedColor]^.Height;
		Inc(X1, 4);
		Inc(Y1, 4);
		Dec(X2, 4);
		Dec(Y2, 4);
		SetColor(DarkGray);
		Rectangle(X1, Y1, X2, Y2);
		SetColor(White);
		Rectangle(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
	end;
end;

procedure AreaColorClick(Sender: PUIObject); far;
var
	PAreaColor: PArea;
begin
	{Need to use a PAreaColor pointer here, since PUIObject doesn't
	 have a BGColor property}
	PAreaColor := Pointer(Sender);
	SelectColor(PAreaColor^.BGColor, true);
end;

procedure BtnSaveClick(Sender: PUIObject); far;
begin
	{If sender was BtnSaveAs, true will be passed to the SaveAs parameter}
	SaveTheme((Sender = PUIObject(BtnSaveAs)));
end;

procedure BtnAboutClick(Sender: PUIObject); far;
begin
	AboutBox(App);
end;

procedure BtnExitClick(Sender: PUIObject); far;
var
	DoSave: boolean;
begin
	if ThemeChanged = True then
	begin
		{Otherwise, ask to save}
		DoSave := MsgBox(MSG_UNSAVED_CHANGES_TITLE, MSG_UNSAVED_CHANGES_PROMPT, MsgQuest);
		if DoSave then
			{User wants to save before exiting}
			if not SaveTheme(false) then
				{Save failed or was cancelled, do not exit - leave procedure}
				exit;
	end;

	App^.Terminate;
end;

procedure TextboxChange(Sender: PUIObject); far;
begin
	ThemeChanged := True;
	PrwTheme^.LoadMem(@ThemeData, TxtName^.Text, TxtAuthor^.Text);
end;

procedure WinMainRun(Sender: PUIObject); far;
begin
	{Save current theme so we can restore it whenever preview has been drawn,
	 and set current theme as basis for editing}
	SysTheme := Thm;
	ThemeData := Thm;
	{Desktop is the default selected object, so use its color for default
	 color selection}
	SelectedObject := Desk;
	SelectedColor := ThemeData.Desk;
end;

procedure InitUI;
var
	i: integer;
	X1, Y1, X2, Y2: Integer;
begin
	New(WinMain, Init(0, 0, nil));
	with WinMain^ do
	begin
		Width := ScreenWidth;
		Height := ScreenHeight;
		OnRun := WinMainRun;
		BorderStyle := BorNone;
	end;

	{Main screen}
	New(BtnNew, Init(2, 2, CAP_NEW, WinMain));
	with BtnNew^ do
	begin
		OnClick := NewTheme;
		AddHotKey(KeyAltN);
	end;

	New(BtnOpen, Init(101, 2, CAP_OPEN, WinMain));
	with BtnOpen^ do
	begin
		OnClick := LoadTheme;
		AddHotKey(KeyAltO);
	end;

	New(BtnSave, Init(200, 2, CAP_SAVE, WinMain));
	with BtnSave^ do
	begin
		OnClick := BtnSaveClick;
		AddHotKey(KeyAltS);
	end;

	New(BtnSaveAs, Init(299, 2, CAP_SAVE_AS, WinMain));
	with BtnSaveAs^ do
	begin
		OnClick := BtnSaveClick;
		AddHotKey(KeyAltV);
	end;

	New(BtnAbout, Init(446, 2, CAP_ABOUT, WinMain));
	with BtnAbout^ do
	begin
		OnClick := BtnAboutClick;
		AddHotKey(KeyAltA);
	end;

	New(BtnExit, Init(545, 2, CAP_EXIT, WinMain));
	with BtnExit^ do
	begin
		OnClick := BtnExitClick;
		AddHotKey(KeyAltX);
		AddHotKey(KeyEscape);
	end;

	New(TxtName, Init(434, 59, CAP_NAME, WinMain));
	with TxtName^ do
	begin
		Width := 194;
		MaxLength := 20;
		OnChange := TextboxChange;
		AddHotKey(KeyAltM);
	end;

	New(TxtAuthor, Init(434, 107, CAP_AUTHOR, WinMain));
	with TxtAuthor^ do
	begin
		Width := 194;
		MaxLength := 20;
		OnChange := TextboxChange;
		AddHotKey(KeyAltU);
	end;

	New(BtnObject, Init(434, 155, CAP_OBJECT[0], WinMain));
	with BtnObject^ do
	begin
		Width := 194;
		OnClick := BtnObjectClick;
		AddHotKey(KeyAltB);
	end;

	New(LblObject, Init(434, 140, CAP_OBJECT_SEL, WinMain));

	{Color boxes}
	Y1 := 0;
	X1 := 0;
	for I := 0 to 15 do
	begin
		{8 starts new row, so back to top and move right}
		if I = 8 then
		begin
			Y1 := 25;
			X1 := 0;
		end;
		New(AreaColor[i], Init(434 + X1, 205 + Y1, WinMain));
		with AreaColor[i]^ do
		begin
			Width := 19;
			Height := 19;
			OnClick := AreaColorClick;
			OnDraw := AreaColorDraw;
			BgColor := i;
		end;
		Inc(X1, 25);
	end;

	New(LblColor, Init(434, 190, CAP_COLOR_SEL, WinMain));

	New(HkNextColor, Init(KeyAltC, WinMain));
	HkNextColor^.OnClick := SelectNextColor;

	New(PrwTheme, Init(12, 42, WinMain));
	with PrwTheme^ do
	begin
		Width := 410;
		Height := 293;
		Exclude(State, SEnabled);
	end;
end;

begin
	New(App, Init);
	With App^ do
	begin
		Name := AppName;
		Version := AppVersion;
		Author := AppAuthor;
		Icon := AppIcon;
	end;

	InitUI;

	App^.OpenWindow(WinMain);
	App^.Run;
	App^.Terminate;
end.