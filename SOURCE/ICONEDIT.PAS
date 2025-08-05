program IconEditor;

uses
	CostaLib, FileDlg, InputDlg, Strings, DOS, Graph;

const
	AppName                = 'Icon Editor';
	AppVersion             = '2.0';
	AppAuthor              = 'Jacob Palm';
	AppIcon                = 'PAINT';

	IconSize               = 31; {Size of the icon in pixels, minus 1 because of zero-based indexing}
	PixelSize              = 9;  {Size of each field in the drawing area}
	OutOfBound             = -1; {Used to indicate out of bounds in GetCursorPos}
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

type
	TTool = (toolPencil, toolFloodFill);
	TCursorDir = (    
		DirHide,
		DirStay,
		DirLeft,
		DirRight,
		DirUp,
		DirDown        
	);
	TFillState = (NotFilled, FilledNeedsCheck, FilledChecked);
	TCanvasAction = (MouseAction, KeyboardAction);

	TIconData = array[0..IconSize, 0..IconSize] of byte;

var
	IconData: TIconData;
	CurrentTool: TTool;
	DrawColor: Integer;
	IconFileName: String;
	IconChanged: Boolean;

	IndicatorX, IndicatorY: Integer;
	OffsetX, OffsetY: Integer;
	KeyboardPosVisible: boolean;

	{Objects which are modified outside main loop}
	AreaCanvas: TArea;
	BtnPencil, BtnFloodFill: TButton;
	AreaColor: array[0..MaxColor] of TArea;
	ImgPreview: TIcon;

{Forward declarations}
procedure GetCursorPos(var X, Y: Integer); forward;
procedure MoveIndicator(Direction: TCursorDir); forward;
procedure SaveIcon(SaveAs: boolean); forward;
procedure SetPixel(X, Y, Col: Integer); forward;
procedure SetTool(Tool: TTool); forward;
procedure FillArea(X, Y, FillColor: Integer); forward;

procedure DoCanvasAction(Action: TCanvasAction);
var
	CanvasX, CanvasY: Integer;
begin
	{If keyboard action was taken but indicator is hidden, just show it without
	 drawing}
	if (Action = KeyboardAction) and (not KeyboardPosVisible) then
	begin
		KeyboardPosVisible := true;
		MoveIndicator(DirStay);
		exit;
	end;

	{Set CanvasX/Y to mouse position, or to indicator position if
	 keyboard action was taken}
	if Action = MouseAction then
	begin
		if KeyboardPosVisible then
			MoveIndicator(DirHide);
		GetCursorPos(CanvasX, CanvasY);
	end
	else
	begin
		CanvasX := IndicatorX;
		CanvasY := IndicatorY;
	end;

	{If outside bounds, do nothing}
	if (CanvasX < 0) or (CanvasY < 0) or (CanvasX > IconSize) or (CanvasY > IconSize) then
		exit;

	case CurrentTool of
		toolPencil:
			begin
				{Keep drawing until mouse is released - if keyboard action, loop will
				 exit after drawing one pixel}
				repeat
					if CanvasX <> OutOfBound then
					begin
						{Plot the current pixel if color is different}
						if IconData[CanvasX, CanvasY] <> DrawColor then
						begin
							MouseHide;
							SetPixel(CanvasX, CanvasY, DrawColor);
							MouseShow;
						end;
					end;

					if Action = KeyboardAction then
						break;

					GetCursorPos(CanvasX, CanvasY);

				until MouseClicked = MbNone;
			end;

		toolFloodFill:
			begin
				MouseHide;
				FillArea(CanvasX, CanvasY, DrawColor);
				MouseShow;
				{After flood fill, switch back to the pencil tool}
				SetTool(toolPencil);
			end;
	end;
	
	{Make sure indicator will appear where mouse was lifted}
	if Action = MouseAction then
	begin
		if CanvasX <> OutOfBound then
		begin
			IndicatorX := CanvasX;
			IndicatorY := CanvasY;
		end;
	end;

	{Redraw keyboard indicator if it was visible}
	if Action = KeyboardAction then
		MoveIndicator(DirStay);
end;

procedure SetPixel(X, Y, Col: Integer);
var
	CanvasX, CanvasY: Integer;
begin
	{DrawAreaOffSet variables are the coords for the top-left corner of
	 the drawing area, and each 'pixel' in it is PixelSize times
	 PixelSize pixels in size}
	CanvasX := OffsetX + (X * PixelSize);
	CanvasY := OffsetY + (Y * PixelSize);

	IconChanged := true;
	IconData[X, Y] := Col;

	SetFillStyle(SolidFill, Col);
	Bar(CanvasX, CanvasY, CanvasX + PixelSize - 2, CanvasY + PixelSize - 2);
	PutPixel(ImgPreview.Left + X, ImgPreview.Top + Y, Col);
end;

procedure FillArea(X, Y, FillColor: Integer);
type
	PNode = ^TNode;
	TNode = record
		X, Y: Integer;
		Next: PNode;
	end;
var
	Stack: PNode; {Pointer to the first item in the stack}
	ReplaceColor: Integer;

	{Pushes a pixel onto the stack for checking later}
	procedure Push(X, Y: Integer);
	var
		NewNode: PNode;
	begin
		{Allocate a new node and set its values}
		New(NewNode);
		NewNode^.X := X;
		NewNode^.Y := Y;
		{Point new nodes Next to the current stack, and set it as
		 the new stack head}
		NewNode^.Next := Stack;
		Stack := NewNode;
	end;

	{Retrieves a pixel from the stack for processing}
	function Pop(var X, Y: Integer): Boolean;
	var
		TempNode: PNode;
	begin
		if Stack <> nil then
		begin
			X := Stack^.X;
			Y := Stack^.Y;
			TempNode := Stack;
			Stack := Stack^.Next; {Set next stack item as head}
			Dispose(TempNode); {Dispose the TNode element that was popped}
			Pop := true;
		end
		else
			Pop := false;
	end;

begin
	ReplaceColor := IconData[X, Y];

	if ReplaceColor = FillColor then
		exit;

	Stack := nil;

	{Add initially clicked pixel to the stack}
	Push(X, Y);

	{As long as there are pixels in the stack, check them}
	while Pop(X, Y) do
	begin
		if (X < 0) or (Y < 0) or (X > IconSize) or (Y > IconSize) then
			continue;

		if IconData[X, Y] = ReplaceColor then
		begin
			{Set color of the pixel, and mark its neighbours for checking by
			 pushing them onto the stack}
			SetPixel(X, Y, FillColor);
			Push(X - 1, Y);
			Push(X + 1, Y);
			Push(X, Y - 1);
			Push(X, Y + 1);
		end;
	end;

	{Stick around as long as the mouse is clicked - to avoid fill while mouse
	 is moved around. We only want one fill per click.}
	repeat until MouseClicked = MbNone;
end;

procedure SetDrawColor(Col: integer);
var
	X1, Y1, X2, Y2: integer;
begin
	{Prevent color outside range}
	if Col < 0 then
		Col := MaxColor
	else if Col > MaxColor then
		Col := 0;
	
	{Remove selection marker from previous color}
	MouseHide;
	AreaColor[DrawColor].Draw;

	{Change color and draw new selection marker}
	DrawColor := Col;
	X1 := AreaColor[DrawColor].Left + 4;
	Y1 := AreaColor[DrawColor].Top + 4;
	X2 := AreaColor[DrawColor].Left + AreaColor[DrawColor].Width - 4;
	Y2 := AreaColor[DrawColor].Top + AreaColor[DrawColor].Height - 4;
	SetColor(DarkGray);
	Rectangle(X1, Y1, X2, Y2);
	SetColor(White);
	Rectangle(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
	MouseShow;
end;

procedure SetTool(Tool: TTool);
begin
	if Tool = CurrentTool then
		exit;

	{Set the current tool to the specified one, and update the button visuals}
	if Tool = toolPencil then
	begin
		BtnPencil.State := BsDown;
		BtnFloodFill.State := BsUp;
	end
	else if Tool = toolFloodFill then
	begin
		BtnPencil.State := BsUp;
		BtnFloodFill.State := BsDown;
	end;
	MouseHide;
	BtnPencil.Draw;
	BtnFloodFill.Draw;
	CurrentTool := Tool;
	MouseShow;
end;

procedure GetCursorPos(var X, Y: Integer);
var
	tmpX, tmpY: String;
begin
	if AreaCanvas.IsMouseOver then
	begin
		MousePoll;
		X := (MouseX - OffsetX) div PixelSize;
		Y := (MouseY - OffsetY) div PixelSize;
		if X < 0 then X := 0;
		if Y < 0 then Y := 0;
		if X > IconSize then X := IconSize;
		if Y > IconSize then Y := IconSize;
	end
	else
	begin
		{Out of bounds}
		X := OutOfBound;
		Y := OutOfBound;
	end;
end;

procedure MoveIndicator(Direction: TCursorDir);
var
	CanvasX, CanvasY: Integer;
begin
	if (KeyboardPosVisible) or (Direction = DirHide) then
	begin
		{Remove indicator from previous pixel}
		if (IndicatorX > OutOfBound) and (IndicatorY > OutOfBound) then
		begin
			CanvasX := OffsetX + (IndicatorX * PixelSize);
			CanvasY := OffsetY + (IndicatorY * PixelSize);
			MouseHide;
			SetFillStyle(SolidFill, IconData[IndicatorX, IndicatorY]);
			Bar(CanvasX, CanvasY, CanvasX + PixelSize - 2, CanvasY + PixelSize - 2);
			MouseShow;
		end;
	end;

	if Direction = DirHide then
	begin
		KeyboardPosVisible := false;
		exit;
	end
	else
		KeyboardPosVisible := true;

	{No need to handle DirStay, all it does is ensure the indicator is visible}
	case Direction of
		DirUp:    Dec(IndicatorY);
		DirDown:  Inc(IndicatorY);
		DirLeft:  Dec(IndicatorX);
		DirRight: Inc(IndicatorX);
	end;
	
	{Prevent out of bounds}
	if IndicatorY < 0 then IndicatorY := 0;
	if IndicatorY > IconSize then IndicatorY := IconSize;
	if IndicatorX < 0 then IndicatorX := 0;
	if IndicatorX > IconSize then IndicatorX := IconSize;

	{Draw indicator}
	CanvasX := OffsetX + (IndicatorX * PixelSize);
	CanvasY := OffsetY + (IndicatorY * PixelSize);
	MouseHide;
	SetColor(DarkGray);
	Rectangle(CanvasX + 1, CanvasY + 1, CanvasX + 6, CanvasY + 6);
	SetColor(White);
	Rectangle(CanvasX + 2, CanvasY + 2, CanvasX + 5, CanvasY + 5);
	MouseShow;
end;

procedure DrawGrid;
var
  Pos: Integer;
begin
  for Pos := 0 to IconSize do
  begin
    {Horizontal lines}
    SetColor(DarkGray);
    SetLineStyle(SolidLn, 1, NormWidth);
    Line(AreaCanvas.Left + 2, AreaCanvas.Top + 1 + (Pos * PixelSize),
         AreaCanvas.Left + AreaCanvas.Width - 2, AreaCanvas.Top + 1 + (Pos * PixelSize));
    SetColor(Black);
    SetLineStyle(UserBitLn, $AAAA, 1);
    Line(AreaCanvas.Left + 2, AreaCanvas.Top + 1 + (Pos * PixelSize),
         AreaCanvas.Left + AreaCanvas.Width - 2, AreaCanvas.Top + 1 + (Pos * PixelSize));

    {Vertical lines}
    SetColor(DarkGray);
    SetLineStyle(SolidLn, 1, NormWidth);
    Line(AreaCanvas.Left + 1 + (Pos * PixelSize), AreaCanvas.Top + 2,
         AreaCanvas.Left + 1 + (Pos * PixelSize), AreaCanvas.Top + AreaCanvas.Height - 2);
    SetColor(Black);
    SetLineStyle(UserBitLn, $AAAA, 1);
    Line(AreaCanvas.Left + 1 + (Pos * PixelSize), AreaCanvas.Top + 2,
         AreaCanvas.Left + 1 + (Pos * PixelSize), AreaCanvas.Top + AreaCanvas.Height - 2);
  end;
  SetLineStyle(SolidLn, 1, NormWidth);
end;

function UnsavedChangesToKeep: Boolean;
var
	mbResult: Boolean;
begin
	UnsavedChangesToKeep := false;
	if IconChanged = false then
		exit;

	mbResult := MsgBox(MSG_UNSAVED_TITLE, MSG_UNSAVED_TEXT, MsgQuest);
	if mbResult = true then
	begin
		SaveIcon(false);

		{If iconchanged is still true, it means the save was cancelled or failed}
		UnsavedChangesToKeep := IconChanged;
	end;
end;

procedure NewIcon;
var
	CanvasX, CanvasY: Integer;
	mbResult: Boolean;
begin
	if UnsavedChangesToKeep then
		exit;

	{Draw all pixels white}
	MouseHide;
	for CanvasX := 0 to IconSize do
		for CanvasY := 0 to IconSize do
			SetPixel(CanvasX, CanvasY, White);
	MouseShow;

	KeyboardPosVisible := false;
	IndicatorX := 16;
	IndicatorY := 16;
	IconFileName := '';
	IconChanged := false;
end;

procedure SaveIcon(SaveAs: boolean);
var
	Filename: String;
	F: file;
	Size: Word;
	p: Pointer;
	X1, Y1, X2, Y2: Integer;
	mbResult: Boolean;
begin
	{If icon hasn't already been saved, or SaveAs specified, prompt for a filename}
	if (Length(IconFileName) = 0) or SaveAs then
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
		Filename := IconFileName;

	{Check if file already exists}
	if FileExists(Filename) and (Filename <> IconFileName) then
	begin
		mbResult := MsgBox(MSG_FILE_EXISTS_TITLE, MSG_FILE_EXISTS_TEXT, MsgQuest);
		if mbResult = false then
			exit;
	end;
	
	{Allocate memory and get the icon data}
	X1 := ImgPreview.Left;
	Y1 := ImgPreview.Top;
	X2 := ImgPreview.Left + IconSize;
	Y2 := ImgPreview.Top + IconSize;
	Size := ImageSize(X1, Y1, X2, Y2);
	GetMem(p, Size);
	GetImage(X1, Y1, X2, Y2, p^);
	
	{Open the file and output the data}
	Assign(F, Filename);
	{$I-}
	Rewrite(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		MsgBox(MSG_SAVE_ERROR_TITLE, MSG_SAVE_ERROR_TEXT + Filename, MsgError);
		FreeMem(p, Size);
		exit;
	end;
	BlockWrite(F, p^, Size);
	Close(F);
	FreeMem(p, Size);

	IconFileName := Filename;
	IconChanged := false;
end;

procedure LoadIcon;
var
	IconToLoad: String;
	FPath: DirStr;
	FName: NameStr;
	FExt: ExtStr;
	mbResult: Boolean;
	X, Y, PixelCol: Integer;
begin
	if UnsavedChangesToKeep then
		exit;

	IconToLoad := FileSelect('*.BIN', ProgramPath + 'ICONS', true);
	if length(IconToLoad) = 0 then
		exit;

	FSplit(IconToLoad, FPath, FName, FExt);
	if (FPath <> ProgramPath + 'ICONS\') or (FExt <> '.BIN') then
	begin
		MsgBox(MSG_INVALID_ICON_TITLE, MSG_INVALID_ICON_TEXT, MsgError);
	end;
	
	if (FName = IconFileName) and (IconChanged = true) then
	begin
		{If the icon is already loaded, but has been changed, ask if we should reload it}
		mbResult := MsgBox(MSG_ALREADY_OPEN_TITLE, MSG_ALREADY_OPEN_TEXT, MsgQuest);
		if mbResult = false then
			exit;
	end;

	{We made it this far - load icon}

	{Clear IconData with invalid values - this makes sure color 0 will also be drawn}
	FillChar(IconData, SizeOf(IconData), 255);
	IconFileName := FName;
	ImgPreview.IconFile := Fname;
	
	MouseHide;
	ImgPreview.Draw;
	{Get color of each pixel from the preview icon and set it in the icon data}
	for X := 0 to IconSize do
	begin
		for Y := 0 to IconSize do
		begin
			PixelCol := GetPixel(ImgPreview.Left + X, ImgPreview.Top + Y);
			SetPixel(X, Y, PixelCol);
		end;
	end;
	MouseShow;

	IndicatorX := 16;
	IndicatorY := 16;
	KeyboardPosVisible := false;
	IconFilename := IconToLoad;
	IconChanged := false;
end;

procedure ExitEditor;
var
	mbResult: Boolean;
begin
	if UnsavedChangesToKeep then
		exit;

	CloseGraph;
	Halt(0);
end;

{Main program start}
var
	BtnNew, BtnOpen, BtnSave, BtnSaveAs: TButton;
	BtnExit, BtnAbout: TButton;
	AreaPreview: TArea;
	Key: string;
	YPos, XPos, i: Integer;
begin
	AreaCanvas.Init(175, 44, 290, 290);
	BtnNew.Init(2, 2, SizeDefault, SizeDefault, CAP_NEW);
	BtnOpen.Init(101, 2, SizeDefault, SizeDefault, CAP_OPEN);
	BtnSave.Init(200, 2, SizeDefault, SizeDefault, CAP_SAVE);
	BtnSaveAs.Init(299, 2, SizeDefault, SizeDefault, CAP_SAVE_AS);
	BtnAbout.Init(446, 2, SizeDefault, SizeDefault, CAP_ABOUT);
	BtnExit.Init(545, 2, SizeDefault, SizeDefault, CAP_EXIT);

	XPos := AreaCanvas.Left + AreaCanvas.Width + 12;
	BtnPencil.Init(XPos, AreaCanvas.Top + 14, 56, SizeDefault, CAP_PENCIL);
	BtnPencil.State := BsDown;
	BtnFloodFill.Init(XPos, BtnPencil.Top + 26, 56, SizeDefault, CAP_FILL);
	AreaPreview.Init(XPos, BtnFloodFill.Top + 51, 56, 56);
	AreaPreview.BgColor := Thm.Desk;
	ImgPreview.Init(AreaPreview.Left + 12, AreaPreview.Top + 12, '');
	
	{Draw area offset is used to calculate the position of each pixel
	 in the drawing area, so that it can be drawn in the correct place}
	OffsetX := AreaCanvas.Left + 2;
	OffsetY := AreaCanvas.Top + 2;

	MouseHide;
	MenuBar.Draw;
	SetFillStyle(SolidFill, Thm.Win);
	Bar(0, 29, 639, 349);
	AreaCanvas.Draw;
	AreaPreview.Draw;
	ImgPreview.Draw;
	BtnNew.Draw;
	BtnOpen.Draw;
	BtnSave.Draw;
	BtnSaveAs.Draw;
	BtnAbout.Draw;
	BtnExit.Draw;
	BtnPencil.Draw;
	BtnFloodFill.Draw;

	{Init and draw each color selection box}
	XPos := AreaCanvas.Left - 51;
	YPos := AreaCanvas.Top + 14;
	for i := 0 to MaxColor do
	begin
		{On 8th item, move XPos to next column and reset YPos}
		if i = 8 then
		begin
			inc(XPos, 21);
			YPos := AreaCanvas.Top + 14;
		end;
		AreaColor[i].Init(XPos, YPos, 20, 20);
		AreaColor[i].BGColor := i;
		AreaColor[i].Draw;
		inc(YPos, 21);
	end;

	DrawGrid;

	Print(CAP_PREVIEW, AreaPreview.Left, AreaPreview.Top - 15, Thm.WinText);
	Print(CAP_COLOR, AreaColor[0].Left, AreaCanvas.Top, Thm.WinText);
	Print(CAP_TOOLS, AreaCanvas.Left + AreaCanvas.Width + 12, AreaCanvas.Top, Thm.WinText);
	MouseShow;

	{Set array to invalid color values, so that any color including 0 will be drawn on first field click}
	FillChar(IconData, SizeOf(IconData), 255);
	SetDrawColor(0);
	IndicatorX := 16;
	IndicatorY := 16;
	
	{Main loop}
	repeat
		Key := GetKey;

		if BtnNew.Clicked or (Key = KeyAltN) then
			NewIcon;

		if BtnSave.Clicked or (Key = KeyAltS) then
			SaveIcon(false);
		
		if BtnSaveAs.Clicked or (Key = KeyAltV) then
			SaveIcon(true);

		if BtnOpen.Clicked or (Key = KeyAltO) then
			LoadIcon;

		if BtnAbout.Clicked or (Key = KeyAltA) then
			AboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if BtnExit.Clicked or (Key = KeyAltX) or (Key = KeyAltF4) then
			ExitEditor;

		if BtnPencil.Clicked or (Key = KeyAltE) then
			SetTool(toolPencil);

		if BtnFloodFill.Clicked or (Key = KeyAltF) then
			SetTool(toolFloodFill);

		if Key = KeyAltC then
			SetDrawColor(DrawColor + 1);

		if Key = KeyUp then
			MoveIndicator(DirUp);

		if Key = KeyDown then
			MoveIndicator(DirDown);

		if Key = KeyLeft then
			MoveIndicator(DirLeft);

		if Key = KeyRight then
			MoveIndicator(DirRight);

		{Mouse clicked in color selection area}
		for i := 0 to MaxColor do
			if AreaColor[i].Clicked then
					SetDrawColor(i);

		{Draw using keyboard}
		if (Key = KeyEnter) or (Key = KeySpace) then
			DoCanvasAction(KeyboardAction);

		{Draw using mouse}
		if (MouseClicked <> MbNone) and AreaCanvas.IsMouseOver then
			DoCanvasAction(MouseAction);

	until false;
end.