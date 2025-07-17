program IconEditor;

uses
	CostaLib, FileSel, Strings, DOS, Graph;

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
	DrawColor: Integer;
	IconFileName: String;
	KeyboardPosX, KeyboardPosY: Integer;
	PreviewOffsetX, PreviewOffsetY: Integer;
	KeyboardPosVisible, IconChanged: Boolean;
	DrawAreaOffsetX, DrawAreaOffsetY: Integer;
	txtColor: array[0..15] of TextboxType;

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
	XPos := DrawAreaOffsetX + (X * PixelSize);
	YPos := DrawAreaOffsetY + (Y * PixelSize);

	IconChanged := true;
	IconData[X, Y] := Col;

	SetFillStyle(SolidFill, Col);
	Bar(XPos, YPos, XPos + PixelSize - 2, YPos + PixelSize - 2);
	PutPixel(PreviewOffsetX + X, PreviewOffsetY + Y, Col);
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

procedure LoadIcon(IconToLoad: String);
var
	ErrMsg: Boolean;
	XPos, YPos: Integer;
begin

	{if not File.Exists('DATA\IMAGES\' + IconToLoad + '.BSV') then
	begin
		ErrMsg = SysMsgBox('File not found', 'Could not open the specified icon.' + NewLine
			+ 'Verify the filename and try again.', msgError)
		exit;
	end;


	if IconToLoad = IconFileName then

		{If nothing has changed and icon is already loaded, just return}
		{if IconChanged = false then
			exit;
		end;

		if SysMsgBox('File already open', 'The icon you selected is already opened.' + NewLine +
			'Do you want to discard all changes and reload' + NewLine + 'the icon as it was last saved?', msgQuest) = false then
			exit
		else
			IconChanged := false;

	end;

	if IconChanged = true then
		if SysMsgBox('Icon has been modified', 'This icon contains unsaved changes. Do you' + NewLine
			+ 'want to save it before you load another?', msgQuest) = true then
			if SaveIcon = false then
				{If the user said yes to saving, but didn't, exit here}
				{exit;}

	{We made it this far - load icon}

	{DEBUG - load icon and plot it at PreviewOffsetX, PreviewOffsetY}

{	IconFileName = IconToLoad

	for XPos = 0 to 31
		for YPos = 0 to 31
			SetPixel(XPos, YPos, POINT(PreviewOffsetX + XPos, PreviewOffsetY + YPos));
		end;
	end;
	MouseShow;
	IconChanged = false;

	exit;

LoadIconError:
	MouseShow;
	ErrMsg = SysMsgBox('Invalid image file', 'The icon you selected does not contain a valid icon. The' + NewLine
		+ 'file might be damaged, or not an icon file at all.', msgError)
	NewIcon
	exit;
	RESUME end;}
end;

procedure MoveIndicator(Direction: TCursorDir);
var
	XPos, YPos: Integer;
begin
	if (KeyboardPosVisible) or (Direction = dirHide) then
	begin
		{Remove indicator from previous pixel}
		if (KeyboardPosX > -1) and (KeyboardPosY > -1) then
		begin
			XPos := DrawAreaOffsetX + (KeyboardPosX * PixelSize);
			YPos := DrawAreaOffsetY + (KeyboardPosY * PixelSize);
			MouseHide;
			SetFillStyle(SolidFill, IconData[KeyboardPosX, KeyboardPosY]);
			Bar(XPos, YPos, XPos + PixelSize - 2, YPos + PixelSize - 2);
			MouseShow;
		end;
	end;

	if Direction = dirHide then
		exit;

	{No need to handle dirStay, all it does is ensure the indicator is visible}
	case Direction of
		dirUp: Dec(KeyboardPosY);
		dirDown: Inc(KeyboardPosY);
		dirLeft: Dec(KeyboardPosX);
		dirRight: Inc(KeyboardPosX);
	end;
	
	if KeyboardPosY < 0 then KeyboardPosY := 0;
	if KeyboardPosY > 31 then KeyboardPosY := 31;
	if KeyboardPosX < 0 then KeyboardPosX := 0;
	if KeyboardPosX > 31 then KeyboardPosX := 31;

	XPos := DrawAreaOffsetX + (KeyboardPosX * PixelSize);
	YPos := DrawAreaOffsetY + (KeyboardPosY * PixelSize);
	MouseHide;
	SetColor(DarkGray);
	Rectangle(XPos + 1, YPos + 1, XPos + 6, YPos + 6);
	SetColor(White);
	Line(XPos + 2, YPos + 2, XPos + 5, YPos + 5);
	MouseShow;
end;

procedure NewIcon;
var
	XPos, YPos: Integer;
begin
	IconFileName := '';
	IconChanged := false;

	{Draw all pixels white}
	MouseHide;
	for XPos := 0 to 31 do
		for YPos := 0 to 31 do
			SetPixel(XPos, YPos, White);
	MouseShow;
end;

function SaveIcon: boolean;
var
	SaveAs: String;
	f: file;
	XPos, YPos: Integer;
	DoSave: Boolean;
begin

{TopOfSave:}

	{SaveAs = SysInputBox('Save icon file', 'Type a name for the icon file below, without path or' + NewLine +
		'extension (8 letters max, for example: MYICON).', 'PAINT', IconFileName);
	if Length(SaveAs) = 0 then
		exit;

	if Length(SaveAs) > 8 then
	begin
		DoSave = SysMsgBox('Invalid file name', 'The filename you specified was too long.' + NewLine +
			'Do not type a path or extension, only a filename' + NewLine + 'with a maximun lenght of 8 characters.', msgError)
		exit;
	end;

	if File.Exists('IMAGES\' + SaveAs + '.BIN') then
	begin
		DoSave = SysMsgBox('File already exists', 'The specified icon file already exists. Do you want' + NewLine
			+ 'to owerwrite it with this icon?', msgQuest)
		if DoSave = false then
			SaveIcon := false;
			exit;
		end;
	end;}

	{ON LOCAL ERROR GOTO SaveIconError
	DIM scrBuffer(260)
	MouseHide;
	GET (PreviewOffsetX, PreviewOffsetY, PreviewOffsetX + 31, PreviewOffsetY + 31), scrBuffer
	MouseShow;
	DEF SEG = VARSEG(scrBuffer(0))
	BSAVE 'DATA\IMAGES\' + SaveAs + '.BSV', VARPTR(scrBuffer(0)), UBOUND(scrBuffer) * 2
	DEF SEG
	ON LOCAL ERROR GOTO 0}

	{IconFileName = UCASE$(SaveAs)

	SaveIcon = true
	IconChanged = false
	exit

SaveIconError:
	FileHandle = SysMsgBox('Could not save icon', 'An error occured while saving your icon, and it was not saved.' + NewLine +
		'Make sure the disk is not full or write-protected, and try again.', msgError)
	SaveIcon = false
	exit}
end;

var
	txtDrawArea: TextboxType;
	btnPreview, btnPencil, btnFloodFill: ButtonType;
	btnNew, btnOpen, btnSave: ButtonType;
	btnExit, btnAbout: ButtonType;
	Key: string;
	YPos, XPos, CursorX, CursorY, Void, i: Integer;
	ColChk: integer;
	CurrentTool: TTool;
begin

	txtDrawArea.Init(175, 44, 290, 290);
	btnNew.Init(2, 2, 92, 22, HotkeySymbol + 'New');
	btnOpen.Init(101, 2, 92, 22, HotkeySymbol + 'Load');
	btnSave.Init(200, 2, 92, 22, HotkeySymbol + 'Save');
	btnAbout.Init(446, 2, 92, 22, HotkeySymbol + 'About...');
	btnExit.Init(545, 2, 92, 22, 'E' + HotkeySymbol + 'xit');

	XPos := txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 12;
	btnPencil.Init(XPos, txtDrawArea.Pos.Top + 14, 52, 22, 'P' + HotkeySymbol + 'encil');
	btnFloodFill.Init(XPos, btnPencil.Pos.Top + 26, 52, 22, HotkeySymbol + 'Fill');
	btnPreview.Init(XPos, btnFloodFill.Pos.Top + 51, 52, 52, '');

	PreviewOffsetX := btnPreview.Pos.Left + 10;
	PreviewOffsetY := btnPreview.Pos.Top + 10;
	DrawAreaOffsetX := txtDrawArea.Pos.Left + 2;
	DrawAreaOffsetY := txtDrawArea.Pos.Top + 2;

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

	SetFillStyle(SolidFill, White);
	Bar(btnPreview.Pos.Left + 2, btnPreview.Pos.Top + 2,
		btnPreview.Pos.Left + btnPreview.Pos.Width - 2, btnPreview.Pos.Top + btnPreview.Pos.Height - 2);
	{Line(PreviewOffsetX - 1, PreviewOffsetY - 1, PreviewOffsetX + 32, PreviewOffsetY - 1), Theme.Light
	Line(PreviewOffsetX - 1, PreviewOffsetY, PreviewOffsetX - 1, PreviewOffsetY + 32), Theme.Light
	Line(PreviewOffsetX, PreviewOffsetY + 32, PreviewOffsetX + 32, PreviewOffsetY + 32), Theme.Shadow
	Line(PreviewOffsetX + 32, PreviewOffsetY, PreviewOffsetX + 32, PreviewOffsetY + 31), Theme.Shadow}

	{Draw grid in drawing area}
	for YPos := 0 to 31 do
	begin
		SetColor(DarkGray);
		Line(txtDrawArea.Pos.Left + 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize),
			txtDrawArea.Pos.Left + txtDrawArea.Pos.Width - 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize));
		{Line(txtDrawArea.Pos.Left + 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize),
			txtDrawArea.Pos.Left + txtDrawArea.Pos.Width - 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize)), 0, , &HAAAA}
	end;
	for XPos := 0 to 31 do
	begin
		SetColor(DarkGray);
		Line(txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + 2,
			txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + txtDrawArea.Pos.Height - 2);
		{Line(txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + 2,
			txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + txtDrawArea.Pos.Height - 2), 0, , &HAAAA}
	end;

	FontPrint('Preview', btnPreview.Pos.Left, btnPreview.Pos.Top - 15, Theme.WindowText, FontHeading);
	FontPrint(HotkeySymbol + 'Color', txtColor[0].Pos.Left, txtDrawArea.Pos.Top, Theme.WindowText, FontHeading);
	FontPrint('Tools', txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 12, txtDrawArea.Pos.Top, Theme.WindowText, FontHeading);
	MouseShow;

	SetDrawColor(0);
	KeyboardPosX := 16;
	KeyboardPosY := 16;

	if Length(ParamStr(1)) = 0 then
		NewIcon
	else
		LoadIcon(ParamStr(1));

	{Main loop}
	repeat
		Key := GetKey;

		if MouseInArea(txtDrawArea.Pos) then
		begin
			MousePoll;
			CursorX := (MouseX - (txtDrawArea.Pos.Left + 7)) div PixelSize;
			CursorY := (MouseY - (txtDrawArea.Pos.Top + 7)) div PixelSize;
			if CursorX < 0 then CursorX := 0;
			if CursorY < 0 then CursorY := 0;
			if CursorX > 31 then CursorX := 31;
			if CursorY > 31 then CursorY := 31;
		end
		else
		begin
			CursorX := -1;
			CursorY := -1;
		end;

		{if ObjBtnClick(btnNew) or (Key = KeyAltN) then
		begin
			if IconChanged = true then
			begin
				if SysMsgBox('Icon has been modified', 'This icon contains unsaved changes. Do you' + NewLine
					 + 'want to save it before you make a new?', msgQuest) = true then
				begin
					if SaveIcon then
						NewIcon
				end
				else
					NewIcon
				end;
			end
			else
				NewIcon;
		end;}

		{if ObjBtnClick(btnSave) or (Key = KeyAltS) then
			Void := SaveIcon;}

		{if ObjBtnClick(btnOpen) or (Key = KeyAltL) then
			}

		if ObjBtnClick(btnAbout) or (Key = KeyAltA) then
			SysAboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if ObjBtnClick(btnExit) or (Key = KeyAltX) or (Key = KeyAltF4) then
			break;
		{begin
			if IconChanged = true then
			begin
				if SysMsgBox('Icon has been modified', 'This icon contains unsaved changes. Do you' + NewLine
					+ 'want to save it before you exit?', msgQuest) = true then
					if SaveIcon = true then
						break;
				else
					break;
			end
			else
				break;
		end;}

		if ((MouseClicked <> mbNone) and MouseInArea(btnPencil.Pos)) or (Key = KeyAltE) then
		begin
			if CurrentTool <> toolPencil then
			begin
				MouseHide;
				ObjDrawBtn(btnPencil, true);
				ObjDrawBtn(btnFloodFill, false);
				CurrentTool := toolPencil;
				MouseShow;
				repeat until MouseClicked = mbNone;
			end;
		end;

		if ((MouseClicked <> mbNone) and MouseInArea(btnFloodFill.Pos)) or (Key = KeyAltF) then
		begin
			if CurrentTool <> toolFloodFill then
			begin
				MouseHide;
				ObjDrawBtn(btnPencil, false);
				ObjDrawBtn(btnFloodFill, true);
				CurrentTool := toolFloodFill;
				MouseShow;
				repeat until MouseClicked = mbNone;
			end;
		end;

		if Key = KeyAltC then
			SetDrawColor(DrawColor + 1);

		if Key = KeyUp then
		begin
			KeyboardPosVisible:= true;
			MoveIndicator(dirUp);
		end;

		if Key = KeyDown then
		begin
			KeyboardPosVisible := true;
			MoveIndicator(dirDown);
		end;

		if Key = KeyLeft then
		begin
			KeyboardPosVisible := true;
			MoveIndicator(dirLeft);
		end;

		if Key = KeyRight then
		begin
			KeyboardPosVisible := true;
			MoveIndicator(dirRight);
		end;

		if (Key = KeyEnter) or (Key = KeySpace) then
		begin
			if KeyboardPosVisible then
				{SELECT CASE CurrentTool
					CASE toolPencil
						MouseHide;
						SetPixel(KeyboardPosX, KeyboardPosY, DrawColor);
						MouseShow;
					CASE toolFloodFill
						MouseHide;
						FillArea KeyboardPosX, KeyboardPosY, DrawColor
						{After flood fill, switch back to the pencil tools}
						{ObjDrawBtn(btnPencil, true
						ObjDrawBtn(btnFloodFill, false
						CurrentTool = toolPencil
						MouseShow;
				end;}
				MoveIndicator(dirStay)
			else
			begin
				KeyboardPosVisible := true;
				MoveIndicator(dirStay);
			end;
		end;

		for ColChk := 0 to 15 do
			if (MouseClicked <> mbNone) and (MouseInArea(txtColor[ColChk].Pos)) then
				if not DrawColor = ColChk then
					SetDrawColor(ColChk);



		if (MouseClicked <> mbNone) and (CursorX > -1) and (CursorY > -1) then
		begin
			{Mouse clicked in drawing area}

			{if not KeyboardPosX = CursorX or not KeyboardPosY = CursorY then
				MoveIndicator(dirHide
			end;}

			case CurrentTool of
				toolPencil:
				begin
					repeat
						if IconData[CursorX, CursorY] <> DrawColor then
						begin
							MouseHide;
							SetPixel(CursorX, CursorY, DrawColor);
							MouseShow;
						end;

						if MouseInArea(txtDrawArea.Pos) then
						begin
							MousePoll;
							CursorX := (MouseX - (txtDrawArea.Pos.Left + 7)) div PixelSize;
							CursorY := (MouseY - (txtDrawArea.Pos.Top + 7)) div PixelSize;
							if CursorX < 0 then CursorX := 0;
							if CursorY < 0 then CursorY := 0;
							if CursorX > 31 then CursorX := 31;
							if CursorY > 31 then CursorY := 31;
						end
						else
						begin
							CursorX := -1;
							CursorY := -1;
						end;
					until MouseClicked = mbNone;

					{Make sure indicator will appear where mouse was lifted}
					KeyboardPosX := CursorX;
					KeyboardPosY := CursorY;
				end;
				toolFloodFill:
				begin
					MouseHide;
					FillArea(CursorX, CursorY, DrawColor);
					{After flood fill, switch back to the pencil tools}
					ObjDrawBtn(btnPencil, true);
					ObjDrawBtn(btnFloodFill, false);
					CurrentTool := toolPencil;
					MouseShow;
				end;
			end;

		end;

	until false;
	CloseGraph;
end.