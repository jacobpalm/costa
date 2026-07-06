program IconEditor;

uses
	CostaLib, UIIcon, UIButton, UIArea, UILabel, UIIconCv, MsgDlg, FileDlg, InputDlg, AboutDlg, Graph, DOS;

const
	AppName                = 'Icon Editor';
	AppVersion             = '2.0';
	AppAuthor              = 'Jacob Palm';
	AppIcon                = 'PAINT';

	MaxColor               = 15; {Colors 0-15 are valid}

	CAP_EXIT               = 'E' + #127 + 'xit';
	CAP_ABOUT              = #127 + 'About...';
	CAP_NEW                = #127 + 'New';
	CAP_OPEN               = #127 + 'Open...';
	CAP_SAVE               = #127 + 'Save';
	CAP_SAVE_AS            = 'Sa' + #127 + 've as...';
	CAP_PENCIL             = 'P' + #127 + 'encil';
	CAP_FILL               = #127 + 'Fill';
	CAP_COLOR              = #127 + 'Color';
	CAP_PREVIEW            = 'Preview';
	CAP_TOOLS              = 'Tools';

	MSG_UNSAVED_TITLE      = 'Icon has been modified';
	MSG_UNSAVED_TEXT       = 'This icon contains unsaved changes. Do you' + #13 +
	                         'want to save it before you continue?';
	MSG_SAVE_TITLE         = 'Save icon file';
	MSG_SAVE_TEXT          = 'Type a name for the icon file below, without path or' + #13 +
	                         'extension (8 letters max, for example: MYICON).';
	MSG_INVALID_NAME_TITLE = 'Invalid filename';
	MSG_INVALID_NAME_TEXT  = 'The filename you specified was too long or invalid.' + #13 +
	                         'Do not type a path or extension, only a filename' + #13 +
	                         'with a maximum length of 8 characters.';
	MSG_FILE_EXISTS_TITLE  = 'File already exists';
	MSG_FILE_EXISTS_TEXT   = 'The specified icon file already exists. Do you want' + #13 +
	                         'to overwrite it with this icon?';
	MSG_SAVE_ERROR_TITLE   = 'Could not save icon';
	MSG_SAVE_ERROR_TEXT    = 'The icon could not be saved. Verify that the filename is valid:' + #13;
	MSG_ALREADY_OPEN_TITLE = 'File already open';
	MSG_ALREADY_OPEN_TEXT  = 'The icon you selected is already opened.' + #13 +
	                         'Do you want to discard all changes and reload' + #13 +
	                         'the icon as it was last saved?';
	MSG_INVALID_ICON_TITLE = 'Invalid icon file';
	MSG_INVALID_ICON_TEXT  = 'The selected file is not a valid icon file.' + #13 +
	                         'Please select a .BIN file from the ICONS directory.';

var
	{UI objects}
	App: PApplication;
	WinMain: PWindow;
	BtnNew, BtnOpen, BtnSave, BtnSaveAs: PButton;
	BtnExit, BtnAbout: PButton;
	AreaPreview: PArea;
	Canvas: PIconCanvas;
	BtnPencil, BtnFloodFill: PButton;
	AreaColor: array[0..MaxColor] of PArea;
	LblPreview, LblColor: PLabel;

	HkColor: PHotkey;

{Forward declarations}
function UnsavedChangesToKeep: Boolean; forward;



{SetDrawColor changes the currently selected drawing color and moves the
 selection marker to the corresponding color area}
procedure SetDrawColor(Col: Byte);
var
	NewColor: Byte;
begin
	{Trigger redraw of new and old color object}
	AreaColor[Canvas^.GetDrawColor]^.AddState(SDirty);
	AreaColor[Col]^.AddState(SDirty);

	{We get color right after setting it, in case SetColor wrapped around the value}
	Canvas^.SetDrawColor(Col);
	NewColor := Canvas^.GetDrawColor;
end;

{This procedure draws a selection marker in the active color area}
procedure AreaColorDraw(Sender: PUIObject); far;
var
	X1, Y1, X2, Y2: integer;
	Color: Byte;
begin
	Color := Canvas^.GetDrawColor;

	{If this isn't the active area, just exit}
	If Sender <> PUIObject(AreaColor[Color]) then
		exit;

	{Get absolute position and size of area}
	AreaColor[Color]^.GetAbsPos(X1, Y1);
	X2 := AreaColor[Color]^.Width;
	Y2 := AreaColor[Color]^.Height;

	{Marker is a rectangle inset by 4 pixels from the area border}
	Inc(X1, 4);
	Inc(Y1, 4);
	Inc(X2, X1 - 8);
	Inc(Y2, Y1 - 8);

	{Draw marker}
	SetColor(DarkGray);
	Rectangle(X1, Y1, X2, Y2);
	SetColor(White);
	Rectangle(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
end;


procedure BtnNewClick(Sender: PUIObject); far;
begin
	if UnsavedChangesToKeep then
		exit;

	Canvas^.NewIcon;
end;

procedure BtnOpenClick(Sender: PUIObject); far;
var
	IconToLoad: String;
	FPath: DirStr;
	FName: NameStr;
	FExt: ExtStr;
	MbResult: Boolean;
begin
	if UnsavedChangesToKeep then
		exit;

	{Open file dialog to select icon file}
	IconToLoad := FileSelect('*.BIN', ProgramPath + 'ICONS');
	if Length(IconToLoad) = 0 then
		exit;

	{Validate the selected file - must be in the ICONS directory and have .BIN extension}
	FSplit(IconToLoad, FPath, FName, FExt);
	if (FPath <> ProgramPath + 'ICONS\') or (FExt <> '.BIN') then
	begin
		MsgBox(MSG_INVALID_ICON_TITLE, MSG_INVALID_ICON_TEXT, MsgError);
	end;

	{If the icon is already loaded, but has been changed, ask if we should reload it}
	if (FName = Canvas^.GetIconFile) and (Canvas^.IsChanged) then
	begin
		MbResult := MsgBox(MSG_ALREADY_OPEN_TITLE, MSG_ALREADY_OPEN_TEXT, MsgQuest);
		if MbResult = false then
			exit;
	end;

	{We made it this far - load icon}
	Canvas^.LoadIcon(FName);
end;

procedure BtnSaveClick(Sender: PUIObject); far;
var
	Filename: String;
	MbResult: Boolean;
begin
	{If icon hasn't already been saved, or SaveAs specified, prompt for a filename}
	if (Length(Canvas^.GetIconFile) = 0) or (Sender = PUIObject(BtnSaveAs)) then
	begin
		Filename := UpperCase(InputBox(MSG_SAVE_TITLE, MSG_SAVE_TEXT, AppIcon, ''));

		{Validate input}
		if Length(Filename) = 0 then
			exit;
		if (Length(Filename) > 8) or (not Valid8dot3(FileName + '.BIN')) then
		begin
			MsgBox(MSG_INVALID_NAME_TITLE, MSG_INVALID_NAME_TEXT, MsgError);
			exit;
		end;
		Filename := ProgramPath + 'ICONS\' + Filename + '.BIN';
	end
	else
		Filename := Canvas^.GetIconFile;

	{Check if file already exists}
	if FileExists(Filename) and (Filename <> Canvas^.GetIconFile) then
	begin
		MbResult := MsgBox(MSG_FILE_EXISTS_TITLE, MSG_FILE_EXISTS_TEXT, MsgQuest);
		if MbResult = false then
			exit;
	end;

	Canvas^.SaveIcon(Filename);

	{if he file could not be saved, show an error}
	if Canvas^.IsChanged then
		MsgBox(MSG_SAVE_ERROR_TITLE, MSG_SAVE_ERROR_TEXT + Filename, MsgError);
end;

procedure BtnToolClick(Sender: PUIObject); far;
begin
	{Set the current tool to the specified one, and update the button visuals so
	 that the button for the current tool appears pressed down}
	if Sender = PUIObject(BtnPencil) then
	begin
		BtnPencil^.AddState(SActive);
		BtnFloodFill^.RemoveState(SActive);
		Canvas^.SetTool(ToolPencil);
	end
	else if Sender = PUIObject(BtnFloodFill) then
	begin
		BtnPencil^.RemoveState(SActive);
		BtnFloodFill^.AddState(SActive);
		Canvas^.SetTool(ToolFloodFill);
	end;
end;

procedure BtnAboutClick(Sender: PUIObject); far;
begin
	AboutBox(App);
end;

{Exits the program. If there are unsaved changes, it prompts the user to save
 them first, and if the user cancels, it does not exit.}
procedure BtnExitClick(Sender: PUIObject); far;
begin
	if UnsavedChangesToKeep then
		exit;

	App^.Terminate;
end;

procedure AreaColorClick(Sender: PUIObject); far;
var
	Color: PArea;
begin
	Color := PArea(Sender);
	SetDrawColor(Color^.BgColor);
end;

procedure HkColorClick(Sender: PUIObject); far;
begin
	SetDrawColor(Canvas^.GetDrawColor + 1);
end;

procedure CanvasClick(Sender: PUIObject); far;
begin
	{Update preview image}
	{DEBUG}

	{After a flood fill, the canvas object will switch to pencil tool automatically.
	 Ensure the pencil/flood fill buttons are updated accordingly}
	if (Canvas^.GetTool = ToolPencil) and not (SActive in BtnPencil^.State) then
		BtnToolClick(PUIObject(BtnPencil));
end;

{UnsavedChangesToKeep checks if there are unsaved changes in the icon.
 If there are, it prompts the user to save the icon. If the user chooses to save,
 it calls BtnSaveClick. If the save is successful, there are no unsaved changes and
 the function returns false. If the user chooses not to save, or if the save fails,
 the function returns true, indicating that there are unsaved changes that should be kept.}
function UnsavedChangesToKeep: Boolean;
var
	MbResult: Boolean;
begin
	UnsavedChangesToKeep := false;

	if not Canvas^.IsChanged then
		exit;

	MbResult := MsgBox(MSG_UNSAVED_TITLE, MSG_UNSAVED_TEXT, MsgQuest);
	if MbResult = true then
	begin
		BtnSaveClick(nil);

		{If icon is still changed, it means the save was cancelled or failed.
		 If not, changes have been saved. Return changed status accordingly}
		UnsavedChangesToKeep := Canvas^.IsChanged;
	end;
end;

procedure InitUI;
var
	X, Y, W, H, I: Integer;
begin
	{Initialize UI objects}
	New(WinMain, Init(0, 0, nil));
	With WinMain^ do
	begin
		Width := ScreenWidth;
		Height := ScreenHeight;
		BorderStyle := BorNone;
	end;

	New(BtnNew, Init(2, 2, CAP_NEW, WinMain));
	With BtnNew^ do
	begin
		OnClick := BtnNewClick;
		AddHotkey(KeyAltN);
	end;
	New(BtnOpen, Init(101, 2, CAP_OPEN, WinMain));
	With BtnOpen^ do
	begin
		OnClick := BtnOpenClick;
		AddHotkey(KeyAltO);
	end;
	New(BtnSave, Init(200, 2, CAP_SAVE, WinMain));
	With BtnSave^ do
	begin
		OnClick := BtnSaveClick;
		AddHotkey(KeyAltS);
	end;
	New(BtnSaveAs, Init(299, 2, CAP_SAVE_AS, WinMain));
	With BtnSaveAs^ do
	begin
		OnClick := BtnSaveClick;
		AddHotkey(KeyAltV);
	end;
	New(BtnAbout, Init(446, 2, CAP_ABOUT, WinMain));
	With BtnAbout^ do
	begin
		OnClick := BtnAboutClick;
		AddHotkey(KeyAltA);
	end;
	New(BtnExit, Init(545, 2, CAP_EXIT, WinMain));
	With BtnExit^ do
	begin
		OnClick := BtnExitClick;
		AddHotkey(KeyAltX);
		AddHotkey(KeyAltF4);
	end;

	{Init now to ensure correct ZOrder, but set pos after we now position of canvas}
	New(LblPreview, Init(0, 0, CAP_PREVIEW, WinMain));
	New(AreaPreview, Init(0, 0, WinMain));
	With AreaPreview^ do
	begin
		Width := 56;
		Height := 56;
		BgColor := Thm.Desk;
	end;

	New(Canvas, Init(172, 44, WinMain));
	With Canvas^ do
	begin
		Width := 290;
		Height := 290;
		OnClick := CanvasClick;
		BgColor := White;
		SetPreviewPos(314, 89);
	end;

	{Get absolute position of canvas area, and its size, so other objects can be
	 positioned relative to it}
	Canvas^.GetAbsPos(X, Y);
	X := X + Canvas^.Width + 12;

	{Move preview area to the right of the canvas}
	LblPreview^.Left  := X;
	LblPreview^.Top   := Y + 62;
	AreaPreview^.Left := X;
	AreaPreview^.Top  := Y + 77;

	New(BtnPencil, Init(X, Y, CAP_PENCIL, WinMain));
	With BtnPencil^ do
	begin
		Width := 56;
		OnClick := BtnToolClick;
		Include(State, SActive);
		AddHotkey(KeyAltE);
	end;
	New(BtnFloodFill, Init(X, Y + 26, CAP_FILL, WinMain));
	With BtnFloodFill^ do
	begin
		Width := 56;
		OnClick := BtnToolClick;
		AddHotkey(KeyAltF);
	end;

	{Get position of canvas again, to position color areas left to it}
	Canvas^.GetAbsPos(X, Y);
	X := X - 51;
	New(LblColor, Init(X, Y, CAP_COLOR, WinMain));

	Y := Y + 14;
	for i := 0 to MaxColor do
	begin
		{On 8th item, move X to next column and reset Y}
		if i = 8 then
		begin
			Inc(X, 21);
			Dec(Y, 8 * 21);
		end;

		New(AreaColor[i], Init(X, Y, WinMain));
		With AreaColor[i]^ do
		begin
			Width := 20;
			Height := 20;
			OnClick := AreaColorClick;
			OnDraw := AreaColorDraw;
			BgColor := i;
		end;
		Inc(Y, 21);
	end;

	{Hotkey to change color}
	New(HkColor, Init(KeyAltC, WinMain));
	HkColor^.OnClick := HkColorClick;
end;

{Main program start}
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