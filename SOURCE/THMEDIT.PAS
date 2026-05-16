program ThemeEditor;

uses
	CostaLib, UIButton, UILabel, UITxtbox, UIArea, UIFrame, UIIcon, UIThmPrw, AboutDlg, MsgDlg, InputDlg, FileDlg, Graph, DOS;

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
	CAP_PREVIEW_LINK  = 'Preview link';
	CAP_PREVIEW_EXE   = 'preview.exe';
	CAP_LIST_ITEM     = 'List item';
	CAP_SELECTED_ITEM = 'Selected item';

	CAP_OBJECT: array[0..12] of string = (
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
	MSG_PREVIEW                = 'This is a preview of' + #13 + 'your theme';


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

	App: TApplication;

	{Main screen}
	WinMain: TWindow;
	AreaColor: array[0..15] of TArea;
	BtnNew, BtnOpen, BtnObject, BtnSave, BtnSaveAs, BtnAbout, BtnExit: TButton;
	TxtName, TxtAuthor: TTextbox;
	LblObject, LblColor: TLabel;
	HkNextColor: THotkey;

	{Object selection window}
	WinSelectObject: TWindow;
	BtnObjSelect: array[0..12] of TButton;
	HkUp, HkDown, HkEnter, HkEscape: THotkey;
	SelectObjectDone: boolean;
	ActiveSelection: TThemeObject;

	{Preview frame and contents}
	FrmPreview: TFrame;
	MnuPreview: TMenu;
	WinPreview: TWindow;
	TxtPreview: TTextbox;
	BtnPreview1, BtnPreview2, BtnPreview3: TButton;
	ImgPreview, ImgLogo: TIcon;
	AreaListPreview: TArea;

{Forward declarations}
function  SaveTheme(SaveAs: boolean): boolean; forward;
function  RTrim(s: string): string; forward;

procedure FrmPreviewDraw(Sender: PUIObject); far;
var
	X1, Y1, X2, Y2: Integer;
begin
	{Overwrite system theme with current theme}
	Thm := ThemeData;

	Mouse.Hide;
	SetFillStyle(SolidFill, Thm.Desk);
	Bar(FrmPreview.Left + 2, FrmPreview.Top + 2, FrmPreview.Left + FrmPreview.Width - 2, FrmPreview.Top + FrmPreview.Height - 2);
	MnuPreview.Draw;
	WinPreview.Draw;
	TxtPreview.Draw;
	BtnPreview1.Draw;
	BtnPreview2.Draw;
	BtnPreview3.Draw;
	AreaListPreview.Draw;
	ImgLogo.Draw;
	ImgPreview.Draw;

	{Text on Desk and window}
	Print(MSG_PREVIEW, ImgLogo.Left + 42, ImgLogo.Top + 5, Thm.WinText);
	Print(CAP_PREVIEW_LINK, ImgPreview.Left + 38, ImgPreview.Top + 4, Thm.DeskText);
	Print(CAP_PREVIEW_EXE, ImgPreview.Left + 38, ImgPreview.Top + 18, Thm.DeskText);

	{Draw list preview}
	X1 := AreaListPreview.Left;
	Y1 := AreaListPreview.Top;
	X2 := AreaListPreview.Left + AreaListPreview.Width;
	SetFillStyle(SolidFill, Thm.Sel);
	Bar(X1 + 2, Y1 + 14, X2 - 2, Y1 + 26);
	Print(CAP_LIST_ITEM, X1 + 5, Y1 + 5, Thm.TxtText);
	Print(CAP_SELECTED_ITEM, X1 + 5, Y1 + 5 + 12, Thm.SelText);
	Print(CAP_LIST_ITEM, X1 + 5, Y1 + 5 + 24, Thm.TxtText);
	Print(CAP_LIST_ITEM, X1 + 5, Y1 + 5 + 36, Thm.TxtText);
	Print(CAP_LIST_ITEM, X1 + 5, Y1 + 5 + 48, Thm.TxtText);
	Mouse.Show;

	{Restore system theme}
	Thm := SysTheme;
end;

procedure SelectColor(Color: integer; DrawPreview: boolean);
var
	PreviousColor: Integer;
begin
	if Color < 0 then
		Color := 15
	else if Color > 15 then
		Color := 0;

	PreviousColor := SelectedColor;
	SelectedColor := Color;
	Mouse.Hide;
	AreaColor[PreviousColor].Draw;
	AreaColor[SelectedColor].Draw;
	Mouse.Show;

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
		FrmPreview.Draw;
	end;
end;

procedure SelectNextColor(Sender: PUIObject); far;
begin
	SelectColor(SelectedColor + 1, true);
end;

procedure BtnObjSelectClick(Sender: PUIObject); far;
var
	i: integer;
begin
	{Check which button was pressed}
	for i := 0 to High(BtnObjSelect) do
	begin
		if Sender = @BtnObjSelect[i] then
		begin
			SelectedObject := TThemeObject(i);
			SelectObjectDone := True;
			Exit;
		end;
	end;

	{If no button was pressed, check if Enter was pressed. If so, ActiveSelection will already
	 contain the right value, and we can just mark selection as done}
	if Sender = @HkEnter then
	begin
		SelectedObject := ActiveSelection;
		SelectObjectDone := True;
	end;
end;

procedure SelectObjectEscPressed(Sender: PUIObject); far;
begin
	SelectObjectDone := True;
end;

procedure SelectObjectArrowPressed(Sender: PUIObject); far;
var
	NextSelection: integer;
begin
	Mouse.Hide;
	BtnObjSelect[Ord(ActiveSelection)].State := BsUp;
	BtnObjSelect[Ord(ActiveSelection)].Draw;
	if Sender = @HkUp then
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
	Mouse.Show;
end;

procedure SelectObject(Sender: PUIObject); far;
var
	i: integer;
	Key: string;
	X1, Y1, X2, Y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
begin
	SelectObjectDone := False;

	Mouse.Hide;
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
	Mouse.Show;

	repeat
		Key := GetKey;
		HotkeyInput := Key; {DEBUG - move to event loop later}

		for i := 0 to High(BtnObjSelect) do
			BtnObjSelect[i].CheckEvent;

		HkUp.CheckEvent;
		HkDown.CheckEvent;
		HkEnter.CheckEvent;
		HkEscape.CheckEvent;
	until SelectObjectDone;

	Mouse.Hide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	BtnObject.SetCaption( CAP_OBJECT[Ord(SelectedObject)] );
	BtnObject.Draw;
	Mouse.Show;

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
	TxtName.Text := DefaultName;
	TxtAuthor.Text := '';
	TxtName.Draw;
	TxtAuthor.Draw;
	SelectColor(ThemeData.Desk, false);
	ThemeChanged := False;
end;

procedure LoadTheme(Sender: PUIObject); far;
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
	if not (FDir = App.Path + 'THEMES\') or not (FExt = '.BIN') then
	begin
		MsgBox(MSG_ERROR_OPENING_TITLE, MSG_INVALID_THEME_FILE, MsgError);
		exit;
	end;

	LoadError := False;
	Assign(F, App.Path + 'THEMES\' + FName + '.BIN');
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

		Filename := App.Path + 'THEMES\' + FileName + '.BIN';
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

procedure AreaColorDraw(Sender: PUIObject); far;
var
	X1, Y1, X2, Y2: integer;
begin
	if Sender = @AreaColor[SelectedColor] then
	begin
		X1 := Sender^.Left + 4;
		Y1 := Sender^.Top + 4;
		X2 := Sender^.Left + Sender^.Width - 4;
		Y2 := Sender^.Top + Sender^.Height - 4;
		SetColor(DarkGray);
		Rectangle(X1, Y1, X2, Y2);
		SetColor(White);
		Rectangle(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
	end;
end;

procedure AreaColorClick(Sender: PUIObject); far;
var
	PAreaColor: ^TArea;
begin
	{Need to use a PAreaColor pointer here, since PUIObject doesn't
	 have a BGColor property}
	PAreaColor := Pointer(Sender);
	SelectColor(PAreaColor^.BGColor, true);
end;

procedure BtnSaveClick(Sender: PUIObject); far;
begin
	{If sender was BtnSaveAs, true will be passed to the SaveAs parameter}
	SaveTheme((Sender = @BtnSaveAs));
end;

procedure BtnAboutClick(Sender: PUIObject); far;
begin
	AboutBox(@App);
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
end;

procedure InitUI;
var
	i: integer;
	X1, Y1, X2, Y2: Integer;
begin
	{Main screen}
		with BtnNew do
		begin
			Init(2, 2, SizeDefault, SizeDefault, CAP_NEW);
			AddHotKey(KeyAltN);
			OnClick := NewTheme;
		end;

		with BtnOpen do
		begin
			Init(101, 2, SizeDefault, SizeDefault, CAP_OPEN);
			AddHotKey(KeyAltO);
			OnClick := LoadTheme;
		end;

		with BtnSave do
		begin
			Init(200, 2, SizeDefault, SizeDefault, CAP_SAVE);
			AddHotKey(KeyAltS);
			OnClick := BtnSaveClick;
		end;

		with BtnSaveAs do
		begin
			Init(299, 2, SizeDefault, SizeDefault, CAP_SAVE_AS);
			AddHotKey(KeyAltV);
			OnClick := BtnSaveClick;
		end;

		with BtnAbout do
		begin
			Init(446, 2, SizeDefault, SizeDefault, CAP_ABOUT);
			AddHotKey(KeyAltA);
			OnClick := BtnAboutClick;
		end;

		with BtnExit do
		begin
			Init(545, 2, SizeDefault, SizeDefault, CAP_EXIT);
			AddHotKey(KeyAltX);
			AddHotKey(KeyEscape);
			OnClick := BtnExitClick;
		end;

		with TxtName do
		begin
			Init(434, 59, 194, SizeDefault, CAP_NAME);
			AddHotKey(KeyAltM);
			OnChange := TextboxChange;
			MaxLen := 20;
		end;

		with TxtAuthor do
		begin
			Init(434, TxtName.Top + 48, 194, SizeDefault, CAP_AUTHOR);
			AddHotKey(KeyAltU);
			MaxLen := 20;
			OnChange := TextboxChange;
		end;

		with BtnObject do
		begin
			Init(434, TxtAuthor.Top + 48, 194, SizeDefault, CAP_OBJECT[0]);
			AddHotKey(KeyAltB);
			OnClick := SelectObject;
		end;

		with LblObject do
		begin
			Init(BtnObject.Left, BtnObject.Top - 15, SizeDefault, SizeDefault, CAP_OBJECT_SEL);
		end;

		Y1 := 0;
		X1 := 0;
		for I := 0 to 15 do
		begin
			if I = 8 then
			begin
				Y1 := 25;
				X1 := 0;
			end;
			with AreaColor[i] do
			begin
				Init(TxtAuthor.Left + X1, TxtAuthor.Top + 98 + Y1, 19, 19);
				BGColor := i;
				OnClick := AreaColorClick;
				OnDraw := AreaColorDraw;
			end;
			Inc(X1, 25);
		end;

		with LblColor do
		begin
			Init(AreaColor[0].Left, AreaColor[0].Top - 15, SizeDefault, SizeDefault, CAP_COLOR_SEL);
		end;

		with HkNextColor do
		begin
			Init(KeyAltC);
			OnClick := SelectNextColor;
		end;

		with FrmPreview do
		begin
			Init(12, 42, 410, 293);
			Transparent := True;
			OnDraw := FrmPreviewDraw;
		end;

		with WinMain do
		begin
			Init(0, 0, GetMaxX, GetMaxY);
			Border := false;
			AddObject(@BtnNew);
			AddObject(@BtnOpen);
			AddObject(@BtnSave);
			AddObject(@BtnSaveAs);
			AddObject(@BtnAbout);
			AddObject(@BtnExit);
			AddObject(@TxtName);
			AddObject(@TxtAuthor);
			AddObject(@BtnObject);
			AddObject(@HkNextColor);
			for i := 0 to 15 do
				AddObject(@AreaColor[i]);
			AddObject(@LblObject);
			AddObject(@LblColor);
			AddObject(@FrmPreview);
		end;
		App.OpenWindow(@WinMain);

	{Object selection window}
		WinSelectObject.Init(sizeCenter, sizeCenter, 226, 326);
		for i := 0 to High(BtnObjSelect) do
		begin
			BtnObjSelect[I].Init(WinSelectObject.Left + 13, WinSelectObject.Top + (I * 23) + 15, 200, SizeDefault, CAP_OBJECT[i]);
			BtnObjSelect[I].OnClick := BtnObjSelectClick;
		end;
		{DEBUG - make just one procedure for handling hotkeys}
		HkUp.Init(KeyUp);
		HkUp.OnClick := SelectObjectArrowPressed;
		HkDown.Init(KeyDown);
		HkDown.OnClick := SelectObjectArrowPressed;
		HkEnter.Init(KeyEnter);
		HkEnter.OnClick := BtnObjSelectClick;
		HkEscape.Init(KeyEscape);
		HkEscape.OnClick := SelectObjectEscPressed;

		With WinSelectObject do
		begin
			AddObject(@HkUp);
			AddObject(@HkDown);
			AddObject(@HkEnter);
			AddObject(@HkEscape);
			for i := 0 to High(BtnObjSelect) do
				AddObject(@BtnObjSelect[i]);
		end;

	{Preview frame contents}
		X1 := FrmPreview.Left;
		Y1 := FrmPreview.Top;
		X2 := FrmPreview.Left + FrmPreview.Width;
		Y2 := FrmPreview.Top + FrmPreview.Height;
		with MnuPreview do
		begin
			Init;
			Left := FrmPreview.Left + 2;
			Top := FrmPreview.Top + 2;
			Width := FrmPreview.Width - 4;
		end;
		BtnPreview3.Init(X2 - 96, Y1 + 3, SizeDefault, SizeDefault, CAP_OBJECT[Ord(TThemeObject(Btn))]);
		AreaListPreview.Init(X2 - 182, Y2 - 82, 166, 66);
		ImgPreview.Init(FrmPreview.Left + 16, Y2 - 48, 'PAINT');
		WinPreview.Init(X1 + ((FrmPreview.Width - 260) div 2), Y1 + 65, 260, 127);
		X1 := WinPreview.Left;
		Y1 := WinPreview.Top;
		ImgLogo.Init(X1 + 12, Y1 + 12, 'LOGO');
		with TxtPreview do
		begin
			Init(X1 + 12, Y1 + 56, 236, SizeDefault, '');
			Text := CAP_OBJECT[Ord(TThemeObject(Txt))];
		end;
		BtnPreview1.Init(X1 + 14, Y1 + 93, 111, SizeDefault, CAP_OBJECT[Ord(TThemeObject(Btn))]);
		with BtnPreview2 do
		begin
			Init(X1 + 133, Y1 + 93, 111, SizeDefault, CAP_OBJECT[Ord(TThemeObject(Btn))]);
			State := BsDown;
		end;
end;

begin

	App^.SetInfo(AppName, AppVersion, AppAuthor, AppIcon);

	InitUI;

	{Save current theme so we can restore it whenever preview has been drawn,
	 and set current theme as basis for editing}
	SysTheme := Thm;
	ThemeData := Thm;
	{Desktop is the default selected object, so use its color for default
	 color selection}
	SelectedColor := ThemeData.Desk;

	App.Run;
end.