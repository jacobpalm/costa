program IconEditor;

uses
	CostaLib, FileSel, InputBox, Strings, DOS, Graph;

const
    AppName    = 'Icon Editor';
    AppVersion = '2.0';
    AppAuthor  = 'Jacob Palm';
    AppIcon    = 'PAINT';

	PixelSize  = 9; {Size of each field in the drawing area}

type
	TTool = (toolPencil, toolFloodFill);
	TCursorDir = (    
		dirHide,
		dirStay,
		dirLeft,
		dirRight,
		dirUp,
		dirDown        
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
	txtDrawArea: TextboxType;
	btnPencil, btnFloodFill: ButtonType;
	txtColor: array[0..15] of TextboxType;
	imgPreview: ImageType;

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
	PutPixel(imgPreview.Pos.Left + X, imgPreview.Pos.Top + Y, Col);
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
		repeat until MouseClicked = mbNone;
		exit;
	end;

	IconChanged := true;
	FillChar(Fillmask, SizeOf(FillMask), #0);
	{Clicked pixel has the color we want to replace}
	ReplaceColor := IconData[X, Y];

	{Fill the specified pixel}
	FillPixel(X, Y, ReplaceColor, FillColor);
	PixelsFilled := true;
	
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
	repeat until MouseClicked = mbNone;
end;

procedure SetDrawColor(Col: integer);
var
	x1, y1, x2, y2: integer;
begin
	{Prevent color outside range}
	if Col < 0 then
		Col := 15
	else if Col > 15 then
		Col := 0;
	
	{Remove selection marker from previous color}
	MouseHide;
	x1 := txtColor[DrawColor].Pos.Left + 4;
	y1 := txtColor[DrawColor].Pos.Top + 4;
	x2 := txtColor[DrawColor].Pos.Left + txtColor[DrawColor].Pos.Width - 4;
	y2 := txtColor[DrawColor].Pos.Top + txtColor[DrawColor].Pos.Height - 4;
	SetFillStyle(SolidFill, DrawColor);
	Bar(x1, y1, x2, y2);

	{Change color and draw new selection marker}
	DrawColor := Col;
	x1 := txtColor[DrawColor].Pos.Left + 4;
	y1 := txtColor[DrawColor].Pos.Top + 4;
	x2 := txtColor[DrawColor].Pos.Left + txtColor[DrawColor].Pos.Width - 4;
	y2 := txtColor[DrawColor].Pos.Top + txtColor[DrawColor].Pos.Height - 4;
	SetColor(DarkGray);
	Rectangle(x1, y1, x2, y2);
	SetColor(White);
	Rectangle(x1 + 1, y1 + 1, x2 - 1, y2 - 1);
	MouseShow;
end;

procedure SetTool(Tool: TTool);
begin
	if Tool = CurrentTool then
		exit;

	{Set the current tool to the specified one, and update the button visuals}
	MouseHide;
	if Tool = toolPencil then
	begin
		ObjDrawBtn(btnPencil, true);
		ObjDrawBtn(btnFloodFill, false);
	end
	else if Tool = toolFloodFill then
	begin
		ObjDrawBtn(btnPencil, false);
		ObjDrawBtn(btnFloodFill, true);
	end;
	CurrentTool := Tool;
	MouseShow;
end;

procedure GetCursorPos(var X, Y: Integer);
var
	tmpX, tmpY: String;
begin
	if MouseInArea(txtDrawArea.Pos) then
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
	if (KeyboardPosVisible) or (Direction = dirHide) then
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

	if Direction = dirHide then
	begin
		KeyboardPosVisible := false;
		exit;
	end
	else
		KeyboardPosVisible := true;

	{No need to handle dirStay, all it does is ensure the indicator is visible}
	case Direction of
		dirUp: Dec(KeyY);
		dirDown: Inc(KeyY);
		dirLeft: Dec(KeyX);
		dirRight: Inc(KeyX);
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
		mbResult := SysMsgBox('Icon has been modified',
			'This icon contains unsaved changes. Do you' + NewLine +
			'want to save it before you make a new?', msgQuest);
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
	f: file;
	Size: Word;
	p: Pointer;
	x1, y1, x2, y2: Integer;
	mbResult: Boolean;
begin
	{If icon hasn't already been saved, prompt for a filename}
	if Length(IconFileName) = 0 then
	begin
		Filename := UpperCase(SysInputBox('Save icon file', 'Type a name for the icon file below, without path or' + NewLine +
			'extension (8 letters max, for example: MYICON).', 'PAINT', ''));

		{Validate input}
		if Length(Filename) = 0 then
			exit;
		if (Length(Filename) > 8) or (not ValidDOSFilename(FileName + '.BIN')) then
		begin
			mbResult := SysMsgBox('Invalid file name', 'The filename you specified was too long or invalid.' + NewLine +
				'Do not type a path or extension, only a filename' + NewLine
				+ 'with a maximum length of 8 characters.', msgError);
			exit;
		end;
		Filename := SysPath + 'IMAGES\' + Filename + '.BIN';
	end
	else
		Filename := IconFileName;

	{Check if file already exists}
	if FileExists(Filename) and (Filename <> IconFileName) then
	begin
		mbResult := SysMsgBox('File already exists', 'The specified icon file already exists. Do you want' + NewLine
			+ 'to overwrite it with this icon?', msgQuest);
		if mbResult = false then
			exit;
	end;
	
	{Allocate memory and get the image data}
	x1 := imgPreview.Pos.Left;
	y1 := imgPreview.Pos.Top;
	x2 := imgPreview.Pos.Left + 31;
	y2 := imgPreview.Pos.Top + 31;
	Size := ImageSize(x1, y1, x2, y2);
	GetMem(p, Size);
	GetImage(x1, y1, x2, y2, p^);
	
	{Open the file and output the data}
	Assign(f, Filename);
	{$I-}
	Rewrite(f, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		mbResult := SysMsgBox('Could not save icon',
			'The icon could not be saved. Verify that the filename is valid:' + NewLine +
			Filename, msgError);
		FreeMem(p, Size);
		exit;
	end;
	BlockWrite(f, p^, Size);
	Close(f);
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
		mbResult := SysMsgBox('Icon has been modified', 'This icon contains unsaved changes. Do you' + NewLine
			+ 'want to save it before you load another?', msgQuest);
		if mbResult = true then
		begin
			SaveIcon;
			{If icon is still changed it wasn't saved, so exit}
			if IconChanged = true then
				exit;
		end;
	end;

	IconToLoad := FileSelect('*.BIN', SysPath + 'IMAGES', true);
	if IconToLoad = '' then
		exit;

	FSplit(IconToLoad, FPath, FName, FExt);
	if (FPath <> SysPath + 'IMAGES\') or (FExt <> '.BIN') then
	begin
		mbResult := SysMsgBox('Invalid icon file',
			'The selected file is not a valid icon file.' + NewLine +
			'Please select a .BIN file from the IMAGES directory.',
			msgError);
		exit;
	end;
	
	if (FName = IconFileName) and (IconChanged = true) then
	begin
		{If the icon is already loaded, but has been changed, ask if we should reload it}
		mbResult := SysMsgBox('File already open', 'The icon you selected is already opened.' + NewLine +
			'Do you want to discard all changes and reload' + NewLine +
			'the icon as it was last saved?', msgQuest);
		if mbResult = false then
			exit;
	end;

	{We made it this far - load icon}

	{Clear IconData with invalid values - this makes sure color 0 will also be drawn}
	FillChar(IconData, SizeOf(IconData), 255);
	IconFileName := FName;
	imgPreview.ImageFile := Fname;
	
	MouseHide;
	ObjDrawImg(imgPreview);
	{Get color of each pixel from the preview image and set it in the icon data}
	for X := 0 to 31 do
	begin
		for Y := 0 to 31 do
		begin
			PixelCol := GetPixel(imgPreview.Pos.Left + X, imgPreview.Pos.Top + Y);
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
		mbResult := SysMsgBox('Icon has been modified', 'This icon contains unsaved changes. Do you' + NewLine +
			'want to save it before you exit?', msgQuest);
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
	btnPreview: ButtonType;
	btnNew, btnOpen, btnSave: ButtonType;
	btnExit, btnAbout: ButtonType;
	Key: string;
	YPos, XPos, CursorX, CursorY, i: Integer;
	ColChk: integer;
begin
	txtDrawArea.Init(175, 44, 290, 290);
	btnNew.Init(2, 2, 92, 22, HotkeySymbol + 'New');
	btnOpen.Init(101, 2, 92, 22, HotkeySymbol + 'Load');
	btnSave.Init(200, 2, 92, 22, HotkeySymbol + 'Save');
	btnAbout.Init(446, 2, 92, 22, HotkeySymbol + 'About...');
	btnExit.Init(545, 2, 92, 22, 'E' + HotkeySymbol + 'xit');

	XPos := txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 12;
	btnPencil.Init(XPos, txtDrawArea.Pos.Top + 14, 56, 22, 'P' + HotkeySymbol + 'encil');
	btnFloodFill.Init(XPos, btnPencil.Pos.Top + 26, 56, 22, HotkeySymbol + 'Fill');
	btnPreview.Init(XPos, btnFloodFill.Pos.Top + 51, 56, 56, '');

	{Center preview image in area}
	XPos := (btnPreview.Pos.Width - 34) div 2;
	YPos := (btnPreview.Pos.Height - 34) div 2;
	XPos := btnPreview.Pos.Left + XPos;
	YPos := btnPreview.Pos.Top + YPos;
	ObjSetSize(imgPreview.Pos, XPos, YPos, 32, 32);
	imgPreview.ImageFile := '';
	
	{Draw area offset is used to calculate the position of each pixel
	 in the drawing area, so that it can be drawn in the correct place}
	OffsetX := txtDrawArea.Pos.Left + 2;
	OffsetY := txtDrawArea.Pos.Top + 2;

	MouseHide;
	ObjDrawMenu;
	SetFillStyle(SolidFill, Theme.Window);
	Bar(0, 29, 639, 349);
	ObjDrawTxt(txtDrawArea, '', false);
	ObjDrawBtn(btnPencil, true);
	ObjDrawBtn(btnFloodFill, false);
	ObjDrawBtn(btnPreview, true);
	ObjDrawBtn(btnNew, false);
	ObjDrawBtn(btnOpen, false);
	ObjDrawBtn(btnSave, false);
	ObjDrawBtn(btnAbout, false);
	ObjDrawBtn(btnExit, false);

	{Init and draw each color selection box}
	for i := 0 to 15 do
	begin
		if i < 8 then
		begin
			XPos := txtDrawArea.Pos.Left - 51;
			YPos := txtDrawArea.Pos.Top + (i * 21) + 14;
		end
		else
		begin
			XPos := txtDrawArea.Pos.Left - 30;
			YPos := txtDrawArea.Pos.Top + ((i - 8) * 21) + 14;
		end;
		txtColor[i].Init(XPos, YPos, 20, 20);
		ObjDrawTxt(txtColor[i], '', false);
		SetFillStyle(SolidFill, i);
		Bar(XPos + 2, YPos + 2, XPos + 18, YPos + 18);
	end;

	{Draw preview area}
	SetFillStyle(SolidFill, Theme.Desktop);
	Bar(btnPreview.Pos.Left + 2, btnPreview.Pos.Top + 2,
		btnPreview.Pos.Left + btnPreview.Pos.Width - 2, btnPreview.Pos.Top + btnPreview.Pos.Height - 2);
	ObjDrawImg(imgPreview);

	{Draw grid in drawing area - black line with a dotted grey line on top so it's visible on all colors}
	for YPos := 0 to 31 do
	begin
		SetColor(DarkGray);
		SetLineStyle(SolidLn, 1, NormWidth);
		Line(txtDrawArea.Pos.Left + 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize),
			txtDrawArea.Pos.Left + txtDrawArea.Pos.Width - 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize));
		SetColor(Black);
		SetLineStyle(UserBitLn, $AAAA, 1);
		Line(txtDrawArea.Pos.Left + 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize),
			txtDrawArea.Pos.Left + txtDrawArea.Pos.Width - 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize));
	end;
	for XPos := 0 to 31 do
	begin
		SetColor(DarkGray);
		SetLineStyle(SolidLn, 1, NormWidth);
		Line(txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + 2,
			txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + txtDrawArea.Pos.Height - 2);
		SetColor(Black);
		SetLineStyle(UserBitLn, $AAAA, 1);
		Line(txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + 2,
			txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + txtDrawArea.Pos.Height - 2);
	end;
	SetLineStyle(SolidLn, 1, NormWidth);

	FontPrint('Preview', btnPreview.Pos.Left, btnPreview.Pos.Top - 15, Theme.WindowText, FontHeading);
	FontPrint(HotkeySymbol + 'Color', txtColor[0].Pos.Left, txtDrawArea.Pos.Top, Theme.WindowText, FontHeading);
	FontPrint('Tools', txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 12, txtDrawArea.Pos.Top, Theme.WindowText, FontHeading);
	MouseShow;

	{Sert array to invalid color values, so that any color including 0 will be drawn on first field click}
	FillChar(IconData, SizeOf(IconData), 255);
	SetDrawColor(0);
	KeyX := 16;
	KeyY := 16;
	
	{Main loop}
	repeat
		Key := GetKey;

		if ObjBtnClick(btnNew) or (Key = KeyAltN) then
			NewIcon;

		if ObjBtnClick(btnSave) or (Key = KeyAltS) then
			SaveIcon;

		if ObjBtnClick(btnOpen) or (Key = KeyAltL) then
			LoadIcon;

		if ObjBtnClick(btnAbout) or (Key = KeyAltA) then
			SysAboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if ObjBtnClick(btnExit) or (Key = KeyAltX) or (Key = KeyAltF4) then
			ExitEditor;

		if ObjClick(btnPencil.Pos) or (Key = KeyAltE) then
			SetTool(toolPencil);

		if ObjClick(btnFloodFill.Pos) or (Key = KeyAltF) then
			SetTool(toolFloodFill);

		if Key = KeyAltC then
			SetDrawColor(DrawColor + 1);

		if Key = KeyUp then
			MoveIndicator(dirUp);

		if Key = KeyDown then
			MoveIndicator(dirDown);

		if Key = KeyLeft then
			MoveIndicator(dirLeft);

		if Key = KeyRight then
			MoveIndicator(dirRight);

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
				MoveIndicator(dirStay)
			end
			else
			begin
				KeyboardPosVisible := true;
				MoveIndicator(dirStay);
			end;
		end;

		{Mouse clicked in color selection area}
		for i := 0 to 15 do
			if ObjClick(txtColor[i].Pos) then
					SetDrawColor(i);

		{Mouse clicked in drawing area}
		if (MouseClicked <> mbNone) and MouseInArea(txtDrawArea.Pos) then
		begin
			{Mouse clicked, so hide keybard indicator}
			if KeyboardPosVisible then
				MoveIndicator(dirHide);

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
						until MouseClicked = mbNone;
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