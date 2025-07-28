program IconEditor;

uses
	CostaLib, FileDlg, InputDlg, Strings, DOS, Graph;

const
	AppName    = 'Icon Editor';
	AppVersion = '2.0';
	AppAuthor  = 'Jacob Palm';
	AppIcon    = 'PAINT';

	PixelSize  = 9; {Size of each field in the drawing area}

	CAP_EXIT   = 'E' + #127 + 'xit';
	CAP_ABOUT  = #127 + 'About...';
	CAP_NEW    = #127 + 'New';
	CAP_OPEN   = #127 + 'Open...';
	CAP_SAVE   = #127 + 'Save';
	CAP_PENCIL = 'P' + #127 + 'encil';
	CAP_FILL   = #127 + 'Fill';

	MSG_UNSAVED_TITLE      = 'Icon has been modified';
	MSG_UNSAVED_TEXT       = 'This icon contains unsaved changes. Do you' + #13 +
	                         'want to save it before you exit?';
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

	TIconData = array[0..31, 0..31] of byte;
	TFillMask = array[0..31, 0..31] of TFillState;

var
	IconData: TIconData;
	CurrentTool: TTool;
	DrawColor: Integer;
	IconFileName: String;
	IconChanged: Boolean;

	KeyX, KeyY: Integer;
	OffsetX, OffsetY: Integer;
	KeyboardPosVisible: boolean;

	{Objects which are modified outside main loop}
	TxtDrawArea: TTextbox;
	BtnPencil, BtnFloodFill: TButton;
	TxtColor: array[0..15] of TTextbox;
	ImgPreview: TIcon;

{Forward declarations}
procedure SaveIcon; forward;


procedure SetPixel(X, Y, Col: Integer);
var
	XPos, YPos: Integer;
begin
	if (X = -1) or (Y = -1) then
		exit;

	if (IconData[X, Y] = Col) then
		exit;

	{DrawAreaOffSet variables are the coords for the top-left corner of
	 the drawing area, and each 'pixel' in it is PixelSize times
	 PixelSize pixels in size}
	XPos := OffsetX + (X * PixelSize);
	YPos := OffsetY + (Y * PixelSize);

	IconChanged := true;
	IconData[X, Y] := Col;

	SetFillStyle(SolidFill, Col);
	Bar(XPos, YPos, XPos + PixelSize - 2, YPos + PixelSize - 2);
	PutPixel(ImgPreview.Left + X, ImgPreview.Top + Y, Col);
end;

procedure FillArea(X, Y, FillColor: Integer);
var
	FillMask: TFillMask;
	CheckX, CheckY: Integer;
	PixelsFilled: Boolean;
	ReplaceColor: Integer;

	{Helper function to fill a single pixel and mark its neighbors for check}
	procedure FillPixel(X, Y, ReplaceCol, FillCol: Integer);
	begin
		if (X < 0) or (Y < 0) or (X > 31) or (Y > 31) then
			exit;

		if IconData[X, Y] = ReplaceCol then
		begin
			SetPixel(X, Y, FillCol);
			FillMask[X, Y] := FilledNeedsCheck;
		end;
	end;
begin
	{If the pixel already has the current color, there's nothing to paint.
	 Wait mouse release and exit}
	if IconData[X, Y] = FillColor then
	begin
		repeat until MouseClicked = MbNone;
		exit;
	end;

	IconChanged := true;
	FillChar(Fillmask, SizeOf(FillMask), #0);
	{Clicked pixel has the color we want to replace}
	ReplaceColor := IconData[X, Y];

	{Fill the specified pixel}
	FillPixel(X, Y, ReplaceColor, FillColor);
	
	{Loop through FillMask as long as we find pixels that need to be checked}
	repeat
		PixelsFilled := false;

		for CheckX := 0 to 31 do
		begin
			for CheckY := 0 to 31 do
			begin
				if FillMask[CheckX, CheckY] = FilledNeedsCheck then
				begin
					PixelsFilled := true;
					FillPixel(CheckX - 1, CheckY, ReplaceColor, FillColor);
					FillPixel(CheckX + 1, CheckY, ReplaceColor, FillColor);
					FillPixel(CheckX, CheckY - 1, ReplaceColor, FillColor);
					FillPixel(CheckX, CheckY + 1, ReplaceColor, FillColor);
					{We've checked neighbors, so mark this pixel filled in mask}
					FillMask[CheckX, CheckY] := FilledChecked;
				end;
			end;
		end;
	until not PixelsFilled;

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
		Col := 15
	else if Col > 15 then
		Col := 0;
	
	{Remove selection marker from previous color}
	MouseHide;
	X1 := TxtColor[DrawColor].Left + 4;
	Y1 := TxtColor[DrawColor].Top + 4;
	X2 := TxtColor[DrawColor].Left + TxtColor[DrawColor].Width - 4;
	Y2 := TxtColor[DrawColor].Top + TxtColor[DrawColor].Height - 4;
	SetFillStyle(SolidFill, DrawColor);
	Bar(X1, Y1, X2, Y2);

	{Change color and draw new selection marker}
	DrawColor := Col;
	X1 := TxtColor[DrawColor].Left + 4;
	Y1 := TxtColor[DrawColor].Top + 4;
	X2 := TxtColor[DrawColor].Left + TxtColor[DrawColor].Width - 4;
	Y2 := TxtColor[DrawColor].Top + TxtColor[DrawColor].Height - 4;
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
	if TxtDrawArea.IsMouseOver then
	begin
		MousePoll;
		X := (MouseX - OffsetX) div PixelSize;
		Y := (MouseY - OffsetY) div PixelSize;
		if X < 0 then X := 0;
		if Y < 0 then Y := 0;
		if X > 31 then X := 31;
		if Y > 31 then Y := 31;
	end
	else
	begin
		{Out of bounds}
		X := -1;
		Y := -1;
	end;
end;

procedure MoveIndicator(Direction: TCursorDir);
var
	XPos, YPos: Integer;
begin
	if (KeyboardPosVisible) or (Direction = DirHide) then
	begin
		{Remove indicator from previous pixel}
		if (KeyX > -1) and (KeyY > -1) then
		begin
			XPos := OffsetX + (KeyX * PixelSize);
			YPos := OffsetY + (KeyY * PixelSize);
			MouseHide;
			SetFillStyle(SolidFill, IconData[KeyX, KeyY]);
			Bar(XPos, YPos, XPos + PixelSize - 2, YPos + PixelSize - 2);
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
		DirUp:    Dec(KeyY);
		DirDown:  Inc(KeyY);
		DirLeft:  Dec(KeyX);
		DirRight: Inc(KeyX);
	end;
	
	{Prevent out of bounds}
	if KeyY < 0 then KeyY := 0;
	if KeyY > 31 then KeyY := 31;
	if KeyX < 0 then KeyX := 0;
	if KeyX > 31 then KeyX := 31;

	{Draw indicator}
	XPos := OffsetX + (KeyX * PixelSize);
	YPos := OffsetY + (KeyY * PixelSize);
	MouseHide;
	SetColor(DarkGray);
	Rectangle(XPos + 1, YPos + 1, XPos + 6, YPos + 6);
	SetColor(White);
	Rectangle(XPos + 2, YPos + 2, XPos + 5, YPos + 5);
	MouseShow;
end;

procedure NewIcon;
var
	XPos, YPos: Integer;
	mbResult: Boolean;
begin

	if IconChanged = true then
	begin
		mbResult := MsgBox(MSG_UNSAVED_TITLE, MSG_UNSAVED_TEXT, MsgQuest);
		if mbResult = true then
		begin
			SaveIcon;
			{If icon is still changed it wasn't saved, so exit}
			if IconChanged = true then
				exit;
		end;
	end;

	{Draw all pixels white}
	MouseHide;
	for XPos := 0 to 31 do
		for YPos := 0 to 31 do
			SetPixel(XPos, YPos, White);
	MouseShow;

	KeyboardPosVisible := false;
	KeyX := 16;
	KeyY := 16;
	IconFileName := '';
	IconChanged := false;
end;

procedure SaveIcon;
var
	Filename: String;
	F: file;
	Size: Word;
	p: Pointer;
	X1, Y1, X2, Y2: Integer;
	mbResult: Boolean;
begin
	{If icon hasn't already been saved, prompt for a filename}
	if Length(IconFileName) = 0 then
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
	
	{Allocate memory and get the image data}
	X1 := ImgPreview.Left;
	Y1 := ImgPreview.Top;
	X2 := ImgPreview.Left + 31;
	Y2 := ImgPreview.Top + 31;
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
	if IconChanged = true then
	begin
		mbResult := MsgBox(MSG_UNSAVED_TITLE, MSG_UNSAVED_TEXT, MsgQuest);
		if mbResult = true then
		begin
			SaveIcon;
			{If icon is still changed it wasn't saved, so exit}
			if IconChanged = true then
				exit;
		end;
	end;

	IconToLoad := FileSelect('*.BIN', ProgramPath + 'ICONS', true);
	if IconToLoad = '' then
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
	ImgPreview.ImageFile := Fname;
	
	MouseHide;
	ImgPreview.Draw;
	{Get color of each pixel from the preview image and set it in the icon data}
	for X := 0 to 31 do
	begin
		for Y := 0 to 31 do
		begin
			PixelCol := GetPixel(ImgPreview.Left + X, ImgPreview.Top + Y);
			SetPixel(X, Y, PixelCol);
		end;
	end;
	MouseShow;

	KeyX := 16;
	KeyY := 16;
	KeyboardPosVisible := false;
	IconFilename := IconToLoad;
	IconChanged := false;
end;

procedure ExitEditor;
var
	mbResult: Boolean;
begin
	if IconChanged = true then
	begin
		mbResult := MsgBox(MSG_UNSAVED_TITLE, MSG_UNSAVED_TEXT, MsgQuest);
		if mbResult = true then
		begin
			SaveIcon;
			{If icon is still changed it wasn't saved, so exit}
			if IconChanged = true then
				exit;
		end;
	end;

	CloseGraph;
	Halt(0);
end;

{Main program start}
var
	BtnPreview: TButton;
	BtnNew, BtnOpen, BtnSave: TButton;
	BtnExit, BtnAbout: TButton;
	Key: string;
	YPos, XPos, CursorX, CursorY, i: Integer;
	ColChk: integer;
begin
	TxtDrawArea.Init(175, 44, 290, 290);
	BtnNew.Init(2, 2, SizeDefault, SizeDefault, CAP_NEW);
	BtnOpen.Init(101, 2, SizeDefault, SizeDefault, CAP_OPEN);
	BtnSave.Init(200, 2, SizeDefault, SizeDefault, CAP_SAVE);
	BtnAbout.Init(446, 2, SizeDefault, SizeDefault, CAP_ABOUT);
	BtnExit.Init(545, 2, SizeDefault, SizeDefault, CAP_EXIT);

	XPos := TxtDrawArea.Left + TxtDrawArea.Width + 12;
	BtnPencil.Init(XPos, TxtDrawArea.Top + 14, 56, SizeDefault, CAP_PENCIL);
	BtnPencil.State := BsDown;
	BtnFloodFill.Init(XPos, BtnPencil.Top + 26, 56, SizeDefault, CAP_FILL);
	BtnPreview.Init(XPos, BtnFloodFill.Top + 51, 56, 56, '');

	{Center preview image in area}
	XPos := (BtnPreview.Width - 34) div 2;
	YPos := (BtnPreview.Height - 34) div 2;
	XPos := BtnPreview.Left + XPos;
	YPos := BtnPreview.Top + YPos;
	ImgPreview.Init(XPos, YPos, '');
	
	{Draw area offset is used to calculate the position of each pixel
	 in the drawing area, so that it can be drawn in the correct place}
	OffsetX := TxtDrawArea.Left + 2;
	OffsetY := TxtDrawArea.Top + 2;

	MouseHide;
	MenuBar.Draw;
	SetFillStyle(SolidFill, Thm.Win);
	Bar(0, 29, 639, 349);
	TxtDrawArea.Draw;
	BtnPencil.Draw;
	BtnFloodFill.Draw;
	BtnPreview.Draw;
	BtnNew.Draw;
	BtnOpen.Draw;
	BtnSave.Draw;
	BtnAbout.Draw;
	BtnExit.Draw;

	{Init and draw each color selection box}
	for i := 0 to 15 do
	begin
		if i < 8 then
		begin
			XPos := TxtDrawArea.Left - 51;
			YPos := TxtDrawArea.Top + (i * 21) + 14;
		end
		else
		begin
			XPos := TxtDrawArea.Left - 30;
			YPos := TxtDrawArea.Top + ((i - 8) * 21) + 14;
		end;
		TxtColor[i].Init(XPos, YPos, 20, 20);
		TxtColor[i].Draw;
		SetFillStyle(SolidFill, i);
		Bar(XPos + 2, YPos + 2, XPos + 18, YPos + 18);
	end;

	{Draw preview area}
	SetFillStyle(SolidFill, Thm.Desk);
	Bar(BtnPreview.Left + 2, BtnPreview.Top + 2,
		BtnPreview.Left + BtnPreview.Width - 2, BtnPreview.Top + BtnPreview.Height - 2);
	ImgPreview.Draw;

	{Draw grid in drawing area - black line with a dotted grey line on top so it's visible on all colors}
	for YPos := 0 to 31 do
	begin
		SetColor(DarkGray);
		SetLineStyle(SolidLn, 1, NormWidth);
		Line(TxtDrawArea.Left + 2, TxtDrawArea.Top + 1 + (YPos * PixelSize),
			TxtDrawArea.Left + TxtDrawArea.Width - 2, TxtDrawArea.Top + 1 + (YPos * PixelSize));
		SetColor(Black);
		SetLineStyle(UserBitLn, $AAAA, 1);
		Line(TxtDrawArea.Left + 2, TxtDrawArea.Top + 1 + (YPos * PixelSize),
			TxtDrawArea.Left + TxtDrawArea.Width - 2, TxtDrawArea.Top + 1 + (YPos * PixelSize));
	end;
	for XPos := 0 to 31 do
	begin
		SetColor(DarkGray);
		SetLineStyle(SolidLn, 1, NormWidth);
		Line(TxtDrawArea.Left + 1 + (XPos * PixelSize), TxtDrawArea.Top + 2,
			TxtDrawArea.Left + 1 + (XPos * PixelSize), TxtDrawArea.Top + TxtDrawArea.Height - 2);
		SetColor(Black);
		SetLineStyle(UserBitLn, $AAAA, 1);
		Line(TxtDrawArea.Left + 1 + (XPos * PixelSize), TxtDrawArea.Top + 2,
			TxtDrawArea.Left + 1 + (XPos * PixelSize), TxtDrawArea.Top + TxtDrawArea.Height - 2);
	end;
	SetLineStyle(SolidLn, 1, NormWidth);

	Print('Preview', BtnPreview.Left, BtnPreview.Top - 15, Thm.WinText);
	Print(Hotkey + 'Color', TxtColor[0].Left, TxtDrawArea.Top, Thm.WinText);
	Print('Tools', TxtDrawArea.Left + TxtDrawArea.Width + 12, TxtDrawArea.Top, Thm.WinText);
	MouseShow;

	{Sert array to invalid color values, so that any color including 0 will be drawn on first field click}
	FillChar(IconData, SizeOf(IconData), 255);
	SetDrawColor(0);
	KeyX := 16;
	KeyY := 16;
	
	{Main loop}
	repeat
		Key := GetKey;

		if BtnClick(BtnNew) or (Key = KeyAltN) then
			NewIcon;

		if BtnClick(BtnSave) or (Key = KeyAltS) then
			SaveIcon;

		if BtnClick(BtnOpen) or (Key = KeyAltO) then
			LoadIcon;

		if BtnClick(BtnAbout) or (Key = KeyAltA) then
			AboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if BtnClick(BtnExit) or (Key = KeyAltX) or (Key = KeyAltF4) then
			ExitEditor;

		if ObjClick(BtnPencil) or (Key = KeyAltE) then
			SetTool(toolPencil);

		if ObjClick(BtnFloodFill) or (Key = KeyAltF) then
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

		if (Key = KeyEnter) or (Key = KeySpace) then
		begin
			if KeyboardPosVisible then
			begin
				case CurrentTool of
					toolPencil:
						begin
							MouseHide;
							SetPixel(KeyX, KeyY, DrawColor);
							MouseShow;
						end;
					toolFloodFill:
						begin
							MouseHide;
							FillArea(KeyX, KeyY, DrawColor);
							MouseShow;
							SetTool(toolPencil);
						end;
				end;
				MoveIndicator(DirStay)
			end
			else
			begin
				KeyboardPosVisible := true;
				MoveIndicator(DirStay);
			end;
		end;

		{Mouse clicked in color selection area}
		for i := 0 to 15 do
			if ObjClick(TxtColor[i]) then
					SetDrawColor(i);

		{Mouse clicked in drawing area}
		if (MouseClicked <> MbNone) and TxtDrawArea.IsMouseOver then
		begin
			{Mouse clicked, so hide keybard indicator}
			if KeyboardPosVisible then
				MoveIndicator(DirHide);

			case CurrentTool of
				toolPencil:
					begin
						{Keep drawing until mouse is released}
						repeat
							GetCursorPos(CursorX, CursorY);
							if (CursorX = -1) then
								continue;

							{Plot the current pixel if color is different}
							if IconData[CursorX, CursorY] <> DrawColor then
							begin
								MouseHide;
								SetPixel(CursorX, CursorY, DrawColor);
								MouseShow;
							end;
						until MouseClicked = MbNone;
					end;

				toolFloodFill:
					begin
						GetCursorPos(CursorX, CursorY);
						if (CursorX = -1) then
							continue;
						MouseHide;
						FillArea(CursorX, CursorY, DrawColor);
						MouseShow;
						{After flood fill, switch back to the pencil tool}
						SetTool(toolPencil);
					end;
			end;
			
			{Make sure indicator will appear where mouse was lifted}
			if (CursorX > -1) then
			begin
				KeyX := CursorX;
				KeyY := CursorY;
			end;
		end;

	until false;
end.