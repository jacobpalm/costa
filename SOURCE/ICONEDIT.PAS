program IconEditor;

uses
	CostaLib, FileSel; Strings, DOS;

const
    AppName       = 'Icon Editor';
    AppVersion    = '2.0';
    AppAuthor     = 'Jacob Palm';
    AppIcon       = 'PAINT';

	dirLeft = 0
	dirRight = 1
	dirUp = 2
	dirDown = 3
	dirStay = 4
	dirHide = 5

	PixelSize = 9

type
	TIconData = array(0..31, 0..31) of byte;
	TFillMask = array(0..31, 0..31) of TFillState;
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

var
	IconData: TIconData;
	IconFileName: String;
	KeyboardPosX, KeyboardPosY, : Integer;
	PreviewOffsetX, PreviewOffsetY: Integer;
	KeyboardPosVisible, IconChanged: Boolean;
	DrawAreaOffsetX, DrawAreaOffsetY: Integer;
	txtColor: array(0..15) of TextboxType;

procedure DrawPixel(X, Y, Col: Integer; Force: Boolean);
var
	XPos, YPos: Integer;
begin
	if (X = -1) or (Y = -1) then
		exit;

	if (IconData[X, Y] <> Col) or (ForceDraw = true) then
		{DrawAreaOffSet variables are the coords for the top-left corner of
		 the drawing area, and each 'pixel' in it is PixelSize times
		 PixelSize pixels in size}
		XPos = DrawAreaOffsetX + (X * PixelSize);
		YPos = DrawAreaOffsetY + (Y * PixelSize);

		IconChanged := true;
		IconData[X, Y] = Col;

		SetFillStyle(SolidFill, Col);
		Bar(XPos, YPos, XPos + PixelSize - 2, YPos + PixelSize - 2);
		PutPixel(PreviewOffsetX + X, PreviewOffsetY + Y, Col);
	end;
end;

function FillPixel(X, Y, ReplaceCol, FillCol: Integer): TFillState;
begin
	FillPixel := NotFilled;
	if (X < 0) or (Y < 0) or (X > 31) or (Y > 31) then
		exit;

	if IconData[X, Y] = ReplaceCol then
	begin
		DrawPixel(X, Y, FillCol, false);
		IconData[X, Y] := FillCol;
		FillPixel := FilledNeedsCheck;
	end;
end;

procedure FillArea(X, Y, FillColor: Integer);
var
	FillMask: TFillMask;
	CheckX, CheckY: Integer;
	PixelsFilled: Boolean;
	ReplaceColor: Integer;
begin
	{If the pixel already has the current color, there's nothing to paint.
	 Wait mouse release and exit.}
	if IconData[X, Y] = FillColor then
	begin
		repeat until MouseClicked = mbNone;
		exit;
	end;
	
	{Clicked pixel has the color we want to replace}
	ReplaceColor := IconData[X, Y];

	{Fill the specified pixel}
	FillPixel(X, Y, ReplaceColor, FillColor);
	PixelsFilled = true;
	
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

procedure LoadIcon(IconToLoad: String);
var
	ErrMsg: Boolean;
	XPos, YPos: Integer;
begin

	if not File.Exists('DATA\IMAGES\' + IconToLoad + '.BSV') then
		ErrMsg = SysMsgBox('File not found', 'Could not open the specified icon.' + NewLine + 'Verify the filename and try again.', msgError)
		exit;
	end;


	if IconToLoad = IconFileName then

		{If nothing has changed and icon is already loaded, just return}
		if IconChanged = false then
			exit;
		end;

		if SysMsgBox('File already open', 'The icon you selected is already opened.' + NewLine + 'Do you want to discard all changes and reload' + NewLine + 'the icon as it was last saved?', msgQuest) = false then
			exit;
		else
			IconChanged = false
		end;

	end;

	if IconChanged = true then
		if SysMsgBox('Icon has been modified', 'This icon contains unsaved changes. Do you' + NewLine + 'want to save it before you load another?', msgQuest) = true then
			if SaveIcon = false then
				{If the user said yes to saving, but didn't, exit here}
				exit;
			end;
		end;
	end;


  {We made it this far - load icon}

  {DEBUG - load icon and plot it at PreviewOffsetX, PreviewOffsetY}

  IconFileName = IconToLoad

	for XPos = 0 to 31
		for YPos = 0 to 31
			DrawPixel(XPos, YPos, POINT(PreviewOffsetX + XPos, PreviewOffsetY + YPos), true
		end;
	end;
	MouseShow;
	IconChanged = false;

	exit;

LoadIconError:
	MouseShow;
	ErrMsg = SysMsgBox('Invalid image file', 'The icon you selected does not contain a valid icon. The' + NewLine + 'file might be damaged, or not an icon file at all.', msgError)
	NewIcon
	exit;
	RESUME end;
end;

procedure MoveIndicator(Direction: TCursorDir);
var
	XPos, YPos: Integer;
begin
	if (KeyboardPosVisible) or (Direction = dirHide) then
		{Remove indicator from previous pixel}
		if KeyboardPosX > -1 AND KeyboardPosY > -1 then
			XPos = DrawAreaOffsetX + (KeyboardPosX * PixelSize)
			YPos = DrawAreaOffsetY + (KeyboardPosY * PixelSize)
			MouseHide;
			SetFillStyle(SolidFill, IconData[KeyboardPosX, KeyboardPosY));
			Bar(XPos, YPos, XPos + PixelSize - 2, YPos + PixelSize - 2)
			MouseShow;
		end;
	end;

	if {KeyboardPosVisible = false} or {Direction = dirHide} then exit;

	SELECT CASE Direction
	  CASE dirUp
		KeyboardPosY = KeyboardPosY - 1
	  CASE dirDown
		KeyboardPosY = KeyboardPosY + 1
	  CASE dirLeft
		KeyboardPosX = KeyboardPosX - 1
	  CASE dirRight
		KeyboardPosX = KeyboardPosX + 1
	end;
	
	if KeyboardPosY < 0 then KeyboardPosY = 0
	if KeyboardPosY > 31 then KeyboardPosY = 31
	if KeyboardPosX < 0 then KeyboardPosX = 0
	if KeyboardPosX > 31 then KeyboardPosX = 31

	XPos = DrawAreaOffsetX + (KeyboardPosX * PixelSize)
	YPos = DrawAreaOffsetY + (KeyboardPosY * PixelSize)
	MouseHide;
	Line(XPos + 1, YPos + 1, XPos + 6, YPos + 6), 8, B
	Line(XPos + 2, YPos + 2, XPos + 5, YPos + 5), 15, B
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
	for XPos = 0 to 31
		for YPos = 0 to 31
			DrawPixel(XPos, YPos, White, true;
		end;
	end;
	MouseShow;
end;

function SaveIcon: boolean;
var
	SaveAs: String;
	f: file;
	XPos, YPos: Integer;
	DoSave: Boolean;
begin

TopOfSave:

	SaveAs = SysInputBox('Save icon file', 'Type a name for the icon file below, without path or' + NewLine + 'extension (8 letters max, for example: MYICON).', 'PAINT', IconFileName);
	if Length(SaveAs) = 0 then
		exit;

	if Length(SaveAs) > 8 then
	begin
		DoSave = SysMsgBox('Invalid file name', 'The filename you specified was too long.' + NewLine + 'Do not type a path or extension, only a filename' + NewLine + 'with a maximun lenght of 8 characters.', msgError)
		exit;
	end;

	if File.Exists('IMAGES\' + SaveAs + '.BIN') then
	begin
		DoSave = SysMsgBox('File already exists', 'The specified icon file already exists. Do you want' + NewLine + 'to owerwrite it with this icon?', msgQuest)
		if DoSave = false then
			SaveIcon := false;
			exit;
		end;
	end;

	{ON LOCAL ERROR GOTO SaveIconError
	DIM scrBuffer(260)
	MouseHide;
	GET (PreviewOffsetX, PreviewOffsetY, PreviewOffsetX + 31, PreviewOffsetY + 31), scrBuffer
	MouseShow;
	DEF SEG = VARSEG(scrBuffer(0))
	BSAVE 'DATA\IMAGES\' + SaveAs + '.BSV', VARPTR(scrBuffer(0)), UBOUND(scrBuffer) * 2
	DEF SEG
	ON LOCAL ERROR GOTO 0}

	IconFileName = UCASE$(SaveAs)

	SaveIcon = true
	IconChanged = false
	exit

SaveIconError:
	FileHandle = SysMsgBox('Could not save icon', 'An error occured while saving your icon, and it was not saved.' + NewLine + 'Make sure the disk is not full or write-protected, and try again.', msgError)
	SaveIcon = false
	exit
end;

var
	txtDrawArea: TextboxType;
	btnPreview, btnPencil, btnFloodFill: ButtonType;
	btnNew, btnOpen, btnSave: ButtonType;
	btnExit, btnAbout: ButtonType;

	Key, YPos, XPos, CursorX, CursorY, DrawColor, Void: Integer;
	ColChk: integer;
	CurrentTool: TTool;
begin

	txtDrawArea.Init(175, 44, 290, 290);
	btnNew.Init(2, 2, 92, 22, HotkeySymbol + 'New');
	btnOpen.Init(101, 2, 92, 22, HotkeySymbol + 'Load');
	btnSave.Init(200, 2, 92, 22, HotkeySymbol + 'Save');
	btnAbout.Init(446, 2, 92, 22, HotkeySymbol + 'About...');
	btnExit.Init(545, 2, 92, 22, 'E' + HotkeySymbol + 'xit');
	ObjSetSize btnNew.Pos, 2, 2, 92, 22
	ObjSetSize btnOpen.Pos, 101, 2, 92, 22
	ObjSetSize btnSave.Pos, 200, 2, 92, 22
	ObjSetSize btnAbout.Pos, 446, 2, 92, 22
	ObjSetSize btnExit.Pos, 545, 2, 92, 22

	btnNew.Caption = HotkeySymbol + 'New'
	btnOpen.Caption = HotkeySymbol + 'Load'
	btnSave.Caption = HotkeySymbol + 'Save'
	btnAbout.Caption = HotkeySymbol + 'About...'
	btnExit.Caption = 'E' + HotkeySymbol + 'xit'

	ObjSetSize btnPencil.Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 12, txtDrawArea.Pos.Top + 14, 52, 22
	btnPencil.Caption = 'P' + HotkeySymbol + 'encil'

	ObjSetSize btnFloodFill.Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 12, txtDrawArea.Pos.Top + 40, 52, 22
	btnFloodFill.Caption = HotkeySymbol + 'Fill'

	ObjSetSize btnPreview.Pos, txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 12, btnFloodFill.Pos.Top + 51, 52, 52
	btnPreview.Transparent = true

	PreviewOffsetX = btnPreview.Pos.Left + 10
	PreviewOffsetY = btnPreview.Pos.Top + 10
	DrawAreaOffsetX = txtDrawArea.Pos.Left + 2
	DrawAreaOffsetY = txtDrawArea.Pos.Top + 2

	MouseHide;
	ObjDrawMenu
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

	for YPos := 0 to 7 do
	begin
		ObjSetSize txtColor(YPos).Pos, txtDrawArea.Pos.Left - 51, txtDrawArea.Pos.Top + (YPos * 21) + 14, 20, 20
		ObjDrawTxt txtColor(YPos), '', false
		Line(txtColor(YPos).Pos.Left + 2, txtColor(YPos).Pos.Top + 2, txtColor(YPos).Pos.Left + txtColor(YPos).Pos.Width - 2, txtColor(YPos).Pos.Top + txtColor(YPos).Pos.Height - 2), YPos, BF
	end;
	for YPos := 8 to 15 do
	begin
		ObjSetSize txtColor(YPos).Pos, txtDrawArea.Pos.Left - 30, txtDrawArea.Pos.Top + ((YPos - 8) * 21) + 14, 20, 20
		ObjDrawTxt txtColor(YPos), '', false
		Line(txtColor(YPos).Pos.Left + 2, txtColor(YPos).Pos.Top + 2, txtColor(YPos).Pos.Left + txtColor(YPos).Pos.Width - 2, txtColor(YPos).Pos.Top + txtColor(YPos).Pos.Height - 2), YPos, BF
	end;

	{Selection marker in color 0}
	Line(txtColor[DrawColor].Pos.Left + 4, txtColor[DrawColor].Pos.Top + 4, txtColor[DrawColor].Pos.Left + txtColor[DrawColor].Pos.Width - 4, txtColor[DrawColor].Pos.Top + txtColor[DrawColor].Pos.Height - 4), 8, B
	Line(txtColor[DrawColor].Pos.Left + 5, txtColor[DrawColor].Pos.Top + 5, txtColor[DrawColor].Pos.Left + txtColor[DrawColor].Pos.Width - 5, txtColor[DrawColor].Pos.Top + txtColor[DrawColor].Pos.Height - 5), 15, B

	Line(btnPreview.Pos.Left + 2, btnPreview.Pos.Top + 2, btnPreview.Pos.Left + btnPreview.Pos.Width - 2, btnPreview.Pos.Top + btnPreview.Pos.Height - 2), 15, BF
	Line(PreviewOffsetX - 1, PreviewOffsetY - 1, PreviewOffsetX + 32, PreviewOffsetY - 1), Theme.Light
	Line(PreviewOffsetX - 1, PreviewOffsetY, PreviewOffsetX - 1, PreviewOffsetY + 32), Theme.Light
	Line(PreviewOffsetX, PreviewOffsetY + 32, PreviewOffsetX + 32, PreviewOffsetY + 32), Theme.Shadow
	Line(PreviewOffsetX + 32, PreviewOffsetY, PreviewOffsetX + 32, PreviewOffsetY + 31), Theme.Shadow

	{Draw grid in drawing area}
	for YPos = 0 to 31
		Line(txtDrawArea.Pos.Left + 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize), txtDrawArea.Pos.Left + txtDrawArea.Pos.Width - 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize)), 8
		Line(txtDrawArea.Pos.Left + 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize), txtDrawArea.Pos.Left + txtDrawArea.Pos.Width - 2, txtDrawArea.Pos.Top + 1 + (YPos * PixelSize)), 0, , &HAAAA
	end;
	for XPos = 0 to 31
		Line(txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + 2, txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + txtDrawArea.Pos.Height - 2), 8
		Line(txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + 2, txtDrawArea.Pos.Left + 1 + (XPos * PixelSize), txtDrawArea.Pos.Top + txtDrawArea.Pos.Height - 2), 0, , &HAAAA
	end;

	FontPrint(HotkeySymbol + 'Preview', btnPreview.Pos.Left, btnPreview.Pos.Top - 15, Theme.WindowText, FontHeading);
	FontPrint(HotkeySymbol + 'Color', txtColor(0).Pos.Left, txtDrawArea.Pos.Top, Theme.WindowText, FontHeading);
	FontPrint('Tools', txtDrawArea.Pos.Left + txtDrawArea.Pos.Width + 12, txtDrawArea.Pos.Top, Theme.WindowText, FontHeading);
	MouseShow;

	KeyboardPosX := 16;
	KeyboardPosY := 16;

	if Length(ParamStr(1)) = 0 then
	NewIcon
	else
	LoadIcon(ParamStr(1));

	{Main loop}
	DO
		Key = GetKey;

		if MouseInArea(txtDrawArea.Pos) then
			MousePoll;
			CursorX = (MouseX - (txtDrawArea.Pos.Left + 7)) div PixelSize;
			CursorY = (MouseY - (txtDrawArea.Pos.Top + 7)) div PixelSize;
			if CursorX < 0 then CursorX = 0
			if CursorY < 0 then CursorY = 0
			if CursorX > 31 then CursorX = 31
			if CursorY > 31 then CursorY = 31
		else
			CursorX = -1
			CursorY = -1
		end;

		if ObjBtnClick(btnNew) or (Key = KeyAltN) then
			if IconChanged = true then
				if SysMsgBox('Icon has been modified', 'This icon contains unsaved changes. Do you' + NewLine + 'want to save it before you make a new?', msgQuest) = true then
					if SaveIcon then
					NewIcon
					end;
				else
					NewIcon
				end;
			else
				NewIcon;
		end;

		if ObjBtnClick(btnSave) or (Key = KeyAltS) then
			Void = SaveIcon
		end;

		if ObjBtnClick(btnOpen) or (Key = KeyAltL) then
			ShowLoadDialog
		end;

		if ObjBtnClick(btnAbout) or (Key = KeyAltA) then
			SysAboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if ObjBtnClick(btnExit) or (Key = KeyAltX) or (Key = KeyAltF4) then
		begin
			if IconChanged = true then
				if SysMsgBox('Icon has been modified', 'This icon contains unsaved changes. Do you' + NewLine + 'want to save it before you exit?', msgQuest) = true then
					if SaveIcon = true then
						break;
				else
					break;
			else
				break;
		end;

		if (MouseClicked AND MouseInArea(btnPencil.Pos)) or (Key = KeyAltE) then
			if not CurrentTool = toolPencil then
			MouseHide;
			ObjDrawBtn(btnPencil, true);
			ObjDrawBtn(btnFloodFill, false);
			CurrentTool = toolPencil
			MouseShow;
			repeat until MouseClicked = mbNone;
			end;
		end;

		if (MouseClicked and MouseInArea(btnFloodFill.Pos)) or (Key = KeyAltF) then
			if not CurrentTool = toolFloodFill then
				MouseHide;
				ObjDrawBtn(btnPencil, false
				ObjDrawBtn(btnFloodFill, true
				CurrentTool = toolFloodFill
				MouseShow;
				repeat until MouseClicked = mbNone;
			end;
		end;

		if Key = 'c' then
			MouseHide;
			{Remove selection marker from current color}
			Line(txtColor[DrawColor].Pos.Left + 4, txtColor[DrawColor].Pos.Top + 4, txtColor[DrawColor].Pos.Left + txtColor[DrawColor].Pos.Width - 4, txtColor[DrawColor].Pos.Top + txtColor[DrawColor].Pos.Height - 4), DrawColor, BF

			{Change color according to key pressed}
			DrawColor = DrawColor + 1
			if DrawColor > 15 then DrawColor = 0

			{Draw new selection marker}
			Line(txtColor[DrawColor].Pos.Left + 4, txtColor[DrawColor].Pos.Top + 4, txtColor[DrawColor].Pos.Left + txtColor[DrawColor].Pos.Width - 4, txtColor[DrawColor].Pos.Top + txtColor[DrawColor].Pos.Height - 4), 8, B
			Line(txtColor[DrawColor].Pos.Left + 5, txtColor[DrawColor].Pos.Top + 5, txtColor[DrawColor].Pos.Left + txtColor[DrawColor].Pos.Width - 5, txtColor[DrawColor].Pos.Top + txtColor[DrawColor].Pos.Height - 5), 15, B
			MouseShow;
		end;

		if Key = KeyUp then
			KeyboardPosVisible = true
			MoveIndicator(dirUp
		end;

		if Key = KeyDown then
			KeyboardPosVisible = true
			MoveIndicator(dirDown
		end;

		if Key = KeyLeft then
			KeyboardPosVisible = true
			MoveIndicator(dirLeft
		end;

		if Key = KeyRight then
			KeyboardPosVisible = true
			MoveIndicator(dirRight
		end;

		if (Key = KeyEnter) or (Key = KeySpace) then
			if KeyboardPosVisible then
				SELECT CASE CurrentTool
					CASE toolPencil
						MouseHide;
						DrawPixel(KeyboardPosX, KeyboardPosY, DrawColor, false
						MouseShow;
					CASE toolFloodFill
						MouseHide;
						FillArea KeyboardPosX, KeyboardPosY, DrawColor
						{After flood fill, switch back to the pencil tools}
						ObjDrawBtn(btnPencil, true
						ObjDrawBtn(btnFloodFill, false
						CurrentTool = toolPencil
						MouseShow;
				end;
				MoveIndicator(dirStay
			else
				KeyboardPosVisible = true
				MoveIndicator(dirStay
			end;
		end;

		for ColChk = 0 to 15
			if ObjTxtClick(txtColor[ColChk]) then
				if not DrawColor = ColChk then
					MouseHide;
					{Remove selection marker}
					Line(txtColor[DrawColor].Pos.Left + 4, txtColor[DrawColor].Pos.Top + 4, txtColor[DrawColor].Pos.Left + txtColor[DrawColor].Pos.Width - 4, txtColor[DrawColor].Pos.Top + txtColor[DrawColor].Pos.Height - 4), DrawColor, BF

					DrawColor = ColChk
					{Draw new selection marker}
					Line(txtColor[DrawColor].Pos.Left + 4, txtColor[DrawColor].Pos.Top + 4, txtColor[DrawColor].Pos.Left + txtColor[DrawColor].Pos.Width - 4, txtColor[DrawColor].Pos.Top + txtColor[DrawColor].Pos.Height - 4), 8, B
					Line(txtColor[DrawColor].Pos.Left + 5, txtColor[DrawColor].Pos.Top + 5, txtColor[DrawColor].Pos.Left + txtColor[DrawColor].Pos.Width - 5, txtColor[DrawColor].Pos.Top + txtColor[DrawColor].Pos.Height - 5), 15, B
					MouseShow;
				end;
			end;
		end;



		if MouseClicked AND CursorX > -1 AND CursorY > -1 then
			{Mouse clicked in drawing area}

			if not KeyboardPosX = CursorX or not KeyboardPosY = CursorY then
				MoveIndicator(dirHide
			end;

			SELECT CASE CurrentTool
				CASE toolPencil
					DO
						if not IconData[CursorX, CursorY) = DrawColor then
							MouseHide;
							DrawPixel(CursorX, CursorY, DrawColor, false
							MouseShow;
						end;

						if MouseInArea(txtDrawArea.Pos) then
							MousePoll
							CursorX = (MouseX - (txtDrawArea.Pos.Left + 7)) / PixelSize
							CursorY = (MouseY - (txtDrawArea.Pos.Top + 7)) / PixelSize
							if CursorX < 0 then CursorX = 0
							if CursorY < 0 then CursorY = 0
							if CursorX > 31 then CursorX = 31
							if CursorY > 31 then CursorY = 31
						else
							CursorX = -1
							CursorY = -1
						end;
					LOOP WHILE MouseClicked

					{Make sure indicator will appear where mouse was lifted}
					KeyboardPosX = CursorX
					KeyboardPosY = CursorY

				CASE toolFloodFill
					MouseHide;
					FillArea CursorX, CursorY, DrawColor
					{After flood fill, switch back to the pencil tools}
					ObjDrawBtn(btnPencil, true
					ObjDrawBtn(btnFloodFill, false
					CurrentTool = toolPencil
					MouseShow;
			end;

		end;

	LOOP

end.