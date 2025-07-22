program Desktop;

uses
	Costalib, FileSel, Graph, Crt, Strings, DOS;

const
	AppName       = 'Desktop';
	AppVersion    = '2.0';
	AppAuthor     = 'Jacob Palm';
	AppIcon       = 'LOGO';

	CaptionMaxLen = 20; {Maximum length for link captions}

type
	PLink = ^TLink;
	TLink = record
		Caption: String[20];
		FileName: PathStr;
		Path: DirStr;
		Parameters: ComStr;
		ImageFile: String[8];
		PauseOnExit: Boolean;
		Left, Top: Integer;
	end;

	PLinkArray = ^TLinkArray;
	TLinkArray = Array[1..1] of PLink; {Flexible array to simulate dynamic sizing}

	TDirection = (None, Next, Previous); {For tabbing through links}

var
	DeskLink: PLinkArray;
	DeskLinkCount: Integer;
	KeySelection: Integer;
	TabImgSize: Word;
	TabBackgroundP: Pointer;

	{Buttons need to be redrawable from DeskDrawDesktop}
	btnAddLink, btnRunCmd, btnAboutCosta, btnExitCosta: ButtonType;
	btnPrevious, btnNext: ButtonType;
	btnTab: ButtonType;

{Forward declarations}
	procedure DeskDrawDesktop(FullRedraw: boolean); forward;
	procedure DeskRunDialog; forward;
	procedure DeskLinkEdit(TargetLink: integer); forward;
	procedure DeskLinkLoad; forward;
	procedure DeskLinkMenu(TargetLink: integer); forward;
	procedure DeskLinkMove(TargetLink: integer); forward;
	procedure DeskLinkSave; forward;
	procedure DeskLinkFree; forward;
	procedure DeskLinkTab(Direction: TDirection); forward;
	function DeskLinkInit: Boolean; forward;
	procedure DeskRun(TargetLink: TLink); forward;

function LinkHeapError(Size: Word): Integer; far;
var
	MsgResult: Boolean;
begin
	if Size = 0 then
	begin
		LinkHeapError := 0;
		Exit;
	end;

	DeskLinkFree; {Free any previously allocated lines}
	MsgResult := SysMsgBox('Out of memory', 'Not enough memory to load desktop links.', msgError);
	LinkHeapError := 1; {Make GetMem return a nil pointer}
end;

procedure DeskLinkFree;
var
	i: Integer;
begin
	if DeskLinkCount = 0 then
		exit;

	{Dispose all links in the array}
	for i := 1 to DeskLinkCount do
		Dispose(DeskLink^[i]);

	{Free the memory allocated for the array itself}
	FreeMem(DeskLink, DeskLinkCount * SizeOf(PLink));

	DeskLinkCount := 0;
end;

function DeskLinkInit: Boolean;
var
	DefaultHeapError: Pointer;
begin
	if DeskLinkCount = 0 then
	begin
		DeskLinkInit := false;
		Exit;
	end;

	{Use custom heap error handler to avoid program crash on out of memory}
	DefaultHeapError := HeapError;
	HeapError := @LinkHeapError;
	GetMem(DeskLink, DeskLinkCount * SizeOf(PLink));
	HeapError := DefaultHeapError;

	if DeskLink = nil then
		DeskLinkInit := false
	else
		DeskLinkInit := true;
end;

procedure DeskLinkLoad;
var
	i: integer;
	f: file;
	DeskLinkFile: string;
	ReadLink: TLink;
	ReadBytes: Word;
	NewLink: PLink;
	mbVoid: Boolean;
begin
	{Make sure DeskLink is freed before loading new links}
	DeskLinkFree;

	Str(Setting.DesktopID, DeskLinkFile);
	DeskLinkFile := 'CONFIG\DESKLNK' + DeskLinkFile + '.BIN';
	
	{If file doesn't exist, try to load default desktop links. If
	 that file doesn't exist either, exit and show empty desktop}
	if not FileExists(DeskLinkFile) then
	begin
		if FileExists('CONFIG\DESKDEF.BIN') and (Setting.DesktopID = 1) then
			DeskLinkFile := 'CONFIG\DESKDEF.BIN'
		else
			exit;
	end;

	Assign(f, DeskLinkFile);
	{$I-}
	Reset(f, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		mbVoid := SysMsgBox('Error loading desktop links', 'Could not open file for reading. The' + NewLine + 
			'file may corrupt or inaccesible:' + newLine +
			DeskLinkFile, msgError);
		Close(f);
		Exit;
	end;

	{Read the number of links in the file}
	BlockRead(f, DeskLinkCount, SizeOf(DeskLinkCount));
	
	{No links, exit}
	if DeskLinkCount = 0 then
	begin
		Close(f);
		exit;
	end;

	{Allocate memory for the array of links - DeskLinkCount is global so
	 DesklLinkInit knows the appropriate size}
	if not DeskLinkInit then
	begin
		mbVoid := SysMsgBox('Error loading desktop links',
			'Ran out of memory while loading desktop links.', msgError);
		Close(f);
		Exit;
	end;
	
	{Load all links from file}
	for i := 1 to DeskLinkCount do
	begin
		FillChar(ReadLink, SizeOf(ReadLink), 0);
		BlockRead(f, ReadLink, SizeOf(ReadLink), ReadBytes);
		if ReadBytes <> SizeOf(ReadLink) then
		begin
			mbVoid := SysMsgBox('Error loading desktop links',
				'File size mismatch. This indicates that the desktop file' + NewLine + 
				'is corrupt:' + NewLine +
				DeskLinkFile, msgError);
			Close(f);
			DeskLinkFree;
			if NewLink <> nil then
				Dispose(NewLink);
			Exit;
		end;
		
		{Create a new link pointer and assign the read data}
		New(NewLink);
		NewLink^ := ReadLink;
		{Add to array}
		DeskLink^[i] := NewLink;
	end;
	Close(f);
end;

procedure DeskLinkSave;
var
	i, j: integer;
	TempLink: PLink;
	f: file;
	DeskLinkFile: string;
	mbVoid: Boolean;
begin
	{Sort before saving if array contains more than one item - this
	 enables TAB cycling from left to right, top to bottom}
	if DeskLinkCount > 1 then
	begin
		for i := 1 to DeskLinkCount - 1 do
		begin
			for j := 1 to DeskLinkCount - i do
			begin
				{Compare positions: first by Left, then by Top if Left is equal}
				if (DeskLink^[j]^.Left > DeskLink^[j + 1]^.Left) or
				((DeskLink^[j]^.Left = DeskLink^[j + 1]^.Left) and
					(DeskLink^[j]^.Top > DeskLink^[j + 1]^.Top)) then
				begin
					{Swap links}
					TempLink := DeskLink^[j];
					DeskLink^[j] := DeskLink^[j + 1];
					DeskLink^[j + 1] := TempLink;
				end;
			end;
		end;
	end;

	{Save}
	Str(Setting.DesktopID, DeskLinkFile);
	DeskLinkFile := 'CONFIG\DESKLNK' + DeskLinkFile + '.BIN';
	Assign(f, DeskLinkFile);
	{$I-}
	Rewrite(f, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		MbVoid := SysMsgBox('Error saving desktop links', 'Could not open file for writing. The' + NewLine + 
			'file read-only or inaccesible:' + newLine +
			DeskLinkFile, msgError);
		Close(f);
		Exit;
	end;
	BlockWrite(f, DesklinkCount, SizeOf(DesklinkCount));

	{No links, close file}
	if DeskLinkCount = 0 then
	begin
		Close(f);
		Exit;
	end;

	{Write all links to file}
	for i := 1 to DeskLinkCount do
	begin
		BlockWrite(f, DeskLink^[i]^, SizeOf(TLink));
	end;
end;

procedure DeskLinkAdd(NewLink: TLink);
var
	NewDeskLinkArr: PLinkArray;
	PNewLink: PLink;
	i: Integer;
	DefaultHeapError: Pointer;
begin
	{If array hasn't been initialized, do so now}
	if DeskLinkCount = 0 then
	begin
		DeskLinkCount := 1;
		DeskLinkInit;
	end
	else
	begin
		{Allocate new memory for the resized array}
		DefaultHeapError := HeapError;
		HeapError := @LinkHeapError;
		GetMem(NewDeskLinkArr, (DeskLinkCount + 1) * SizeOf(PLink));
		HeapError := DefaultHeapError;

		if NewDeskLinkArr = nil then
		begin
			{DEBUG - link add failed, out of memory}
			CloseGraph;
			WriteLn('Out of memory while adding a new link.');
			halt;
			exit;
		end;

		{Copy existing lines to the new array}
		Move(DeskLink^[1], NewDeskLinkArr^[1], DeskLinkCount * SizeOf(PLink));

		{Free memory of the old array}
		FreeMem(DeskLink, DeskLinkCount * SizeOf(PLink));

		{Update the pointer to the new array}
		DeskLink := NewDeskLinkArr;

		Inc(DeskLinkCount);
	end;

	New(PNewLink);
	PNewLink^ := NewLink;
	DeskLink^[DeskLinkCount] := PNewLink;
end;

procedure DeskLinkRemove(TargetLink: integer);
var
	NewDeskLinkArr: PLinkArray;
	PNewLink: PLink;
	i, Copied: Integer;
	DefaultHeapError: Pointer;
begin
	{If only one link left, or none, free the array}
	if DeskLinkCount <= 1 then
	begin
		DeskLinkFree;
		DeskLinkCount := 0;
		Exit;
	end;

	{Allocate new memory for the resized array}
	DefaultHeapError := HeapError;
	HeapError := @LinkHeapError;
	GetMem(NewDeskLinkArr, (DeskLinkCount - 1) * SizeOf(PLink));
	HeapError := DefaultHeapError;

	if NewDeskLinkArr = nil then
	begin
		{DEBUG - out of memory}
		exit;
	end;

	{Copy existing lines to the new array}
	Copied := 0;
	for i := 1 to DeskLinkCount do
	begin
		if i <> TargetLink then
		begin
			Inc(Copied);
			NewDeskLinkArr^[Copied] := DeskLink^[i];
		end;
	end;

	{Dispose of the link being removed}
	Dispose(DeskLink^[TargetLink]);

	{Free memory of the old array}
	FreeMem(DeskLink, DeskLinkCount * SizeOf(PLink));

	{Update the pointer to the new array}
	DeskLink := NewDeskLinkArr;
	Dec(DeskLinkCount);
end;

procedure DeskDrawDesktop(FullRedraw: boolean);
var
	imgDeskLinkIcon: ImageType;
	i, x, y: integer;
	DeskStr: string;
begin
	MouseHide;

	if FullRedraw then
	begin
		ObjDrawMenu;
		ObjDrawBtn(btnAddLink, false);
		ObjDrawBtn(btnRunCmd, false);
		ObjDrawBtn(btnAboutCosta, false);
		ObjDrawBtn(btnExitCosta, false);
		ObjDrawBtn(btnPrevious, false);
		ObjDrawBtn(btnNext, false);
		Str(Setting.DesktopID, DeskStr);
		FontPrint(DeskStr + '/5', 310, 10, Theme.WindowText);
	end;

	{Clear background}
	SetFillStyle(SolidFill, Theme.Desktop);
	Bar(0, 29, 639, 349);
	
	if DeskLinkCount = 0 then
	begin
		MouseShow;
		exit;
	end;
	
	for i := 1 to DeskLinkCount do
	begin
		x := DeskLink^[i]^.Left;
		y := DeskLink^[i]^.Top;
		ObjSetSize(imgDeskLinkIcon.Pos, x, y, sizeDefault, sizeDefault);
		imgDeskLinkIcon.ImageFile := DeskLink^[i]^.ImageFile;
		ObjDrawImg(imgDeskLinkIcon);

		if Setting.ShowLinkDescriptions then
		begin
			FontPrint(DeskLink^[i]^.Caption, x + 38, y + 4, Theme.DesktopText);
			if Setting.ShowLinkTargetFiles then
				FontPrint(DeskLink^[i]^.FileName, x + 38, y + 18, Theme.DesktopText);
		end;
	end;
	
	MouseShow;
end;

procedure DeskSwitchDesktop(DesktopID: integer);
begin
	if DesktopID < 1 then
		DesktopID := 5
	else if DesktopID > 5 then
		DesktopID := 1;

	Setting.DesktopID := DesktopID;
	DeskLinkLoad;
	KeySelection := 0;

	DeskDrawDesktop(true);
end;

procedure DeskLinkTab(Direction: TDirection);
begin

	{Check if any links exist before tabbing}
	if DeskLinkCount = 0 then
		Exit;

	{If an icon is already selected, then deselect it by restoring the background}
	if KeySelection <> 0 then
	begin
		MouseHide;
		PutImage(DeskLink^[KeySelection]^.Left - 3, DeskLink^[KeySelection]^.Top - 3,
			TabBackgroundP^, NormalPut);
		MouseShow;
	end;

	if Direction = None then
	begin
		KeySelection := 0;
		Exit;
	end;

	if Direction = Next then
		Inc(KeySelection)
	else if Direction = Previous then
		Dec(KeySelection);

	{Wrap around if we go below first or above last link}
	if KeySelection > DeskLinkCount then
		KeySelection := 1
	else if KeySelection < 1 then
		KeySelection := DeskLinkCount;

	{Draw the selected link, saving background first}
	MouseHide;
	{Save background of new selected link}
	GetImage(DeskLink^[KeySelection]^.Left - 3, DeskLink^[KeySelection]^.Top - 3,
		DeskLink^[KeySelection]^.Left + 34, DeskLink^[KeySelection]^.Top + 34, TabBackgroundP^);
	{Draw the tab button around the selected link}
	btnTab.Pos.Left := DeskLink^[KeySelection]^.Left - 3;
	btnTab.Pos.Top := DeskLink^[KeySelection]^.Top - 3;
	ObjDrawBtn(btnTab, false);
	MouseShow;
end;

procedure DeskRunDialog;
var
	winRun: WindowType;
	txtProgram, txtParameters: TextboxType;
	txtProgramText, txtParametersText: string;
	btnOK, btnCancel, btnBrowse: ButtonType;
	Key: string;
	SelectedFile: string;
	x1, y1, x2, y2: integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	RunLink: TLink;
begin
	txtProgramText := '';
	txtParametersText := '';
	FillChar(RunLink, SizeOf(RunLink), 0);

	winRun.Init(sizeCenter, sizeCenter, 382, 137);
	txtProgram.Init(winRun.Pos.Left + 12, winRun.Pos.Top + 27, winRun.Pos.Width - 68, sizeDefault);
	txtParameters.Init(txtProgram.Pos.Left, txtProgram.Pos.Top + 46, winRun.Pos.Width - 26, sizeDefault);
	btnBrowse.Init(txtProgram.Pos.Left + txtProgram.Pos.Width + 9, txtProgram.Pos.Top, 33, 19, '...');
	btnOK.Init(winRun.Pos.Left + winRun.Pos.Width - 184, txtParameters.Pos.Top + 30, 80, 22, HotkeySymbol + 'OK');
	btnCancel.Init(winRun.Pos.Left + winRun.Pos.Width - 94, btnOK.Pos.Top, 80, 22, HotkeySymbol + 'Cancel');
		
	MouseHide;
	x1 := winRun.Pos.Left;
	y1 := winRun.Pos.Top;
	x2 := winRun.Pos.Left + winRun.Pos.Width;
	y2 := winRun.Pos.Top + winRun.Pos.Height;
	BackgroundSize := ImageSize(x1, y1, x2, y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(x1, y1, x2, y2, BackgroundP^);

	ObjDrawWin(winRun);
	ObjDrawBtn(btnOK, false);
	ObjDrawBtn(btnCancel, false);
	ObjDrawTxt(txtProgram, txtProgramText, false);
	ObjDrawTxt(txtParameters, txtParametersText, false);
	ObjDrawBtn(btnBrowse, false);
	
	y2 := txtProgram.Pos.Top - 16;
	FontPrint(HotkeySymbol + 'Program:', txtProgram.Pos.Left, y2, Theme.WindowText);
	y2 := txtParameters.Pos.Top - 16;
	FontPrint('Pa' + HotkeySymbol + 'rameters:', txtParameters.Pos.Left, y2, Theme.WindowText);
	MouseShow;

	repeat
		Key := GetKey;

		if ObjBtnClick(btnOK) or (Key = KeyAltO) or (Key = KeyEnter) then
		begin
			if Length(txtProgramText) > 0 then
			begin
				RunLink.FileName := txtProgramText;
				RunLink.Parameters := txtParametersText;
				DeskRun(RunLink);
			end;
			break;
		end;

		if ObjBtnClick(btnCancel) or (Key = KeyAltC) or (Key = KeyEscape) then
			break;

		if ObjBtnClick(btnBrowse) or ObjTxtClick(txtProgram) or (Key = '.') or (Key = KeyAltP) then
		begin
			SelectedFile := FileSelect('*.exe', '', false);
			if Length(SelectedFile) > 0 then
			begin
				txtProgramText := SelectedFile;
				MouseHide;
				ObjDrawTxt(txtProgram, txtProgramText, false);
				MouseShow;
			end;
		end;

		if ObjTxtClick(txtParameters) or (Key = KeyAltR) then
			ObjEditTxt(txtParameters, txtParametersText);
	until false;

	{Restore background}
	MouseHide;
	PutImage(x1, y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;		
end;

procedure DeskLinkMenu(TargetLink: integer);
var
	winLinkMenu: WindowType;
	btnOpen, btnEdit, btnMove, btnRemove, btnCancel: ButtonType;
	imgIcon: ImageType;
	x1, y1, x2, y2: integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Caption, Filename, Path, Parameters: string;
	DoDelete: boolean;
	Key, CroppedText: string;
begin
	winLinkMenu.Init(sizeCenter, sizeCenter, 413, 165);
	btnOpen.Init(winLinkMenu.Pos.Left + 12, winLinkMenu.Pos.Top + winLinkMenu.Pos.Height - 64, 389, 22, HotkeySymbol + 'Open');
	btnEdit.Init(btnOpen.Pos.Left, btnOpen.Pos.Top + 30, 92, 22, HotkeySymbol + 'Edit...');
	btnMove.Init(btnEdit.Pos.Left + 99, btnEdit.Pos.Top, 92, 22, HotkeySymbol + 'Move');
	btnRemove.Init(btnMove.Pos.Left + 99, btnEdit.Pos.Top, 92, 22, HotkeySymbol + 'Remove');
	btnCancel.Init(btnRemove.Pos.Left + 99, btnEdit.Pos.Top, 92, 22, HotkeySymbol + 'Cancel');
	
	ObjSetSize(imgIcon.Pos, winLinkMenu.Pos.Left + 12, winLinkMenu.Pos.Top + 11, sizeRetain, sizeRetain);
	imgIcon.ImageFile := DeskLink^[TargetLink]^.ImageFile;

	Caption := DeskLink^[TargetLink]^.Caption;
	Filename := DeskLink^[TargetLink]^.Filename;
	Path := DeskLink^[TargetLink]^.Path;
	Parameters := DeskLink^[TargetLink]^.Parameters;
	if Length(Path) = 0 then
		Path := 'Unspecified';
	if Length(Parameters) = 0 then
		Parameters := 'None';

	if Length(Path) > 36 then
		Path := Copy(Path, 1, 33) + '...';
	if Length(Parameters) > 36 then
		Parameters := Copy(Parameters, 1, 33) + '...';

	MouseHide;
	x1 := winLinkMenu.Pos.Left;
	y1 := winLinkMenu.Pos.Top;
	x2 := winLinkMenu.Pos.Left + winLinkMenu.Pos.Width;
	y2 := winLinkMenu.Pos.Top + winLinkMenu.Pos.Height;
	BackgroundSize := ImageSize(x1, y1, x2, y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(x1, y1, x2, y2, BackgroundP^);
	
	ObjDrawWin(winLinkMenu);
	ObjDrawBtn(btnOpen, false);
	ObjDrawBtn(btnEdit, false);
	ObjDrawBtn(btnMove, false);
	ObjDrawBtn(btnRemove, false);
	ObjDrawBtn(btnCancel, false);
	ObjDrawImg(imgIcon);

	FontPrint(DeskLink^[TargetLink]^.Caption, x1 + 54, y1 + 17, 0);
	FontPrint(DeskLink^[TargetLink]^.Filename, x1 + 54, y1 + 31, 0);
	FontPrint('Path:', x1 + 12, y1 + 59, 0);
	FontPrint('Parameters:', x1 + 12, y1 + 76, 0);
	
	FontPrint(Path, x1 + 108, y1 + 59, Theme.WindowText);
	FontPrint(Parameters, x1 + 108, y1 + 76, Theme.WindowText);
	MouseShow;

	{Clear buffers, sometimes needed on DOSBox}
	repeat; until MouseClicked = mbNone;
	repeat; until Length(GetKey) = 0;

	repeat
		Key := GetKey;
	
		{Cancel, or Escape key}
		if ObjBtnClick(btnCancel) or (Key = KeyAltC) or (Key = KeyEscape) then
		begin
			MouseHide;
			PutImage(x1, y1, BackgroundP^, NormalPut);
			MouseShow;
			FreeMem(BackgroundP, BackgroundSize);
			break;
		end;
	
		{Open/run, or Enter key}
		if ObjBtnClick(btnOpen) or (Key = KeyAltO) or (Key = KeyEnter) then
		begin
			FreeMem(BackgroundP, BackgroundSize);
			DeskRun(DeskLink^[TargetLink]^);
			{If we've returned from the run, redraw the desktop since we've freed the memory}
			DeskDrawDesktop(true);
			break;
		end;

		{Configure}
		if ObjBtnClick(btnEdit) or (Key = KeyAltE) then
		begin
			MouseHide;
			PutImage(x1, y1, BackgroundP^, NormalPut);
			MouseShow;
			FreeMem(BackgroundP, BackgroundSize);
			DeskLinkEdit(TargetLink);
			break;
		end;

		{Move}
		if ObjBtnClick(btnMove) or (Key = KeyAltM) then
		begin
			MouseHide;
			PutImage(x1, y1, BackgroundP^, NormalPut);
			MouseShow;
			FreeMem(BackgroundP, BackgroundSize);
			DeskLinkMove(TargetLink);
			break;
		end;

		{Remove}
		if ObjBtnClick(btnRemove) or (Key = KeyAltR) then
		begin
			if Setting.ConfirmLinkDelete then
				DoDelete := SysMsgBox('Remove desktop link', 'This will permanently delete this' +
					NewLine + 'desktop link. Are you sure?', msgQuest)
			else
				DoDelete := true;

			if DoDelete then
			begin
				DeskLinkRemove(TargetLink);
				DeskDrawDesktop(false);
				FreeMem(BackgroundP, BackgroundSize);
				break;
			end;
		end;

	until False;
			 
end;

procedure DeskLinkMove(TargetLink: integer);
const
	GridSize   = 4; {Size of grid in pixels, used for aligning icons}
var
	btnPrevious, btnNext: ButtonType;
	IconSize: Word;
	LinkIconP, BackdropP: Pointer;
	DrawX, DrawY: integer;
	CurGridX, CurGridY, LastGridX, LastGridY: integer;
	OriginalDesktop, SwitchedDesktop: integer;
	IconToMove: TLink;
	Key: String;
begin
	OriginalDesktop := Setting.DesktopID;
	SwitchedDesktop := Setting.DesktopID;
	
	{Delete current icon - it will be recreated after move to same or other
	 desktop}
	IconToMove := DeskLink^[TargetLink]^;
	DeskLinkRemove(TargetLink);
	DeskLinkSave;

	DrawX := IconToMove.Left;
	DrawY := IconToMove.Top;
	LastGridX := 0;
	LastGridY := 0;

	btnPrevious.Init(255, 2, 42, 22, '<');
	btnNext.Init(343, 2, 42, 22, '>');

	MouseHide;
	IconSize := ImageSize(0, 0, 31, 31);
	GetMem(LinkIconP, IconSize);
	GetMem(BackdropP, IconSize);
	GetImage(DrawX, DrawY, DrawX + 31, DrawY + 31, LinkIconP^);
	GetImage(DrawX, DrawY, DrawX + 31, DrawY + 31, BackdropP^);
	MouseShow;

	{Center mouse on icon}
	MouseSetPos(DrawX + 16, DrawY + 16);

	if not MouseSupport then
	begin
		{Set mouse pos variables manually to make the rest of the code work
		 if no mouse is present}
		MouseX := DrawX + 16;
		MouseY := DrawY + 16;
	end;

	MousePoll;
	CurGridX := MouseX div GridSize;
	CurGridY := MouseY div GridSize;
	repeat; until MouseClicked = mbNone;
	repeat
		Key := GetKey;
		
		{Escape}
		if Key = KeyEscape then
		begin
			DeskSwitchDesktop(OriginalDesktop);
			DeskLinkAdd(IconToMove);
			DeskLinkSave;
			exit;
		end;
		
		{Enter}
		if Key = KeyEnter then
			break;

		MousePoll;

		{Arrow keys - move mouse cursor in direction pressed}
		if Key = KeyLeft then MouseX := MouseX - GridSize;
		if Key = KeyRight then MouseX := MouseX + GridSize - 1;
		if Key = KeyUp then MouseY := MouseY - GridSize;
		if Key = KeyDown then MouseY := MouseY + GridSize - 1;

		if MouseX < 20 then MouseX := 20;
		if MouseX > 620 then MouseX := 620;
		if MouseY < 48 then MouseY := 48;
		if MouseY > 333 then MouseY := 333;

		{If icon is moved with arrow keys, set cursor position}
		if Length(Key) = 2 then
			MouseSetPos(MouseX, MouseY);

		{Calculate grid position}
		CurGridX := (MouseX - 16) div GridSize;
		if CurGridX < 0 then
			CurGridX := 0;
		CurGridY := (MouseY - 16) div GridSize;
		if CurGridY < 4 then
			CurGridY := 4;

		if (CurGridX <> LastGridX) or (CurGridY <> LastGridY) then
		begin
			MouseHide;
			{Restore backdrop}
			PutImage(DrawX, DrawY, BackdropP^, NormalPut);
			DrawX := CurGridX * GridSize;
			DrawY := CurGridY * GridSize;
			if DrawY > 318 then
				DrawY := 318;
		
			{Save backdrop, plot icon in its place}
			GetImage(DrawX, DrawY, DrawX + 31, DrawY + 31, BackdropP^);
			PutImage(DrawX, DrawY, LinkIconP^, NormalPut);
			MouseShow;
			LastGridX := CurGridX;
			LastGridY := CurGridY;

			{Reduce flicker}
			Delay(10);
			while (Port[$3DA] and 8) = 0 do;
		end;

		if Key = '1' then DeskSwitchDesktop(1);
		if Key = '2' then DeskSwitchDesktop(2);
		if Key = '3' then DeskSwitchDesktop(3);
		if Key = '4' then DeskSwitchDesktop(4);
		if Key = '5' then DeskSwitchDesktop(5);

		if ObjBtnClick(btnPrevious) or (Key = KeyPageUp) then
			DeskSwitchDesktop(Setting.DesktopID - 1);

		if ObjBtnClick(btnNext) or (Key = KeyPageDown) then
			DeskSwitchDesktop(Setting.DesktopID + 1);

		{Redraw icon at current position if desktop has been switched}
		if Setting.DesktopID <> SwitchedDesktop then
		begin
			MouseHide;
			GetImage(DrawX, DrawY, DrawX + 31, DrawY + 31, BackdropP^);
			PutImage(DrawX, DrawY, LinkIconP^, NormalPut);
			MouseShow;
			SwitchedDesktop := Setting.DesktopID;
		end;

	until (MouseClicked <> mbNone) and (MouseY > 28);

	IconToMove.Left := DrawX;
	IconToMove.Top := DrawY;
	DeskLinkAdd(IconToMove);
	DeskLinkSave;
	DeskDrawDesktop(true);
	
	repeat; until MouseClicked = mbNone;
end;

procedure DeskLinkEdit(TargetLink: integer);
var
	winEdit: WindowType;
	txtCaption, txtFilename, txtParams, txtPath: TextboxType;
	txtCaptionText, txtFileNameText, txtParamsText, txtPathText: string;
	btnOK, btnCancel, btnIcon: ButtonType;
	imgIcon: ImageType;
	chkPauseOnExit: CheckBoxType;
	Key: string;
	MbVoid: Boolean;
	SelectedFile: string;
	x1, y1, x2, y2: integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	FDir: DirStr;
	FName: NameStr;
	FExt: ExtStr;
begin
	winEdit.Init(210, 35, 220, 312);

	btnIcon.Init(296, winEdit.Pos.Top + 12, 48, 48, '');
	ObjSetSize(imgIcon.Pos, 305, btnIcon.Pos.Top + 9, 32, 32);
	txtCaption.Init(222, btnIcon.Pos.Top + 73, 196, 19);
	txtFilename.Init(222, txtCaption.Pos.Top + 44, 196, 19);
	txtPath.Init(222, txtFilename.Pos.Top + 44, 196, 19);
	txtParams.Init(222, txtPath.Pos.Top + 44, 196, 19);
	ObjSetSize(chkPauseOnExit.Pos, 222, txtParams.Pos.Top + 32, 16, 16);
	btnOK.Init(229, chkPauseOnExit.Pos.Top + 28, 84, 22, HotkeySymbol + 'Save');
	btnCancel.Init(326, btnOK.Pos.Top, 84, 22, HotkeySymbol + 'Cancel');

	btnIcon.Transparent := true;
	txtCaption.MaxLen := CaptionMaxLen;
	txtFilename.MaxLen := SizeOf(ComStr); {Max length of a filename +}
	txtParams.MaxLen := SizeOf(ComStr);
	txtPath.MaxLen := SizeOf(DirStr);;
	txtFileNameText := DeskLink^[TargetLink]^.Filename;
	txtParamsText := DeskLink^[TargetLink]^.Parameters;
	txtPathText := DeskLink^[TargetLink]^.Path;
	txtCaptionText := DeskLink^[TargetLink]^.Caption;
	imgIcon.ImageFile := DeskLink^[TargetLink]^.ImageFile;
	chkPauseOnExit.Checked := DeskLink^[TargetLink]^.PauseOnExit;

	MouseHide;
	x1 := winEdit.Pos.Left;
	y1 := winEdit.Pos.Top;
	x2 := winEdit.Pos.Left + winEdit.Pos.Width;
	y2 := winEdit.Pos.Top + winEdit.Pos.Height;
	BackgroundSize := ImageSize(x1, y1, x2, y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(x1, y1, x2, y2, BackgroundP^);

	ObjDrawWin(winEdit);
	ObjDrawTxt(txtCaption, txtCaptionText, false);
	ObjDrawBtn(btnIcon, False);
	ObjDrawTxt(txtFilename, txtFileNameText, false);
	ObjDrawTxt(txtParams, txtParamsText, false);
	ObjDrawTxt(txtPath, txtPathText, false);
	ObjDrawChk(chkPauseOnExit);
	ObjDrawBtn(btnOK, false);
	ObjDrawBtn(btnCancel, false);
	FontPrint('C' + HotkeySymbol + 'aption:', 222, txtCaption.Pos.Top - 15, Theme.WindowText);
	FontPrint(HotkeySymbol + 'Program:', 222, txtFilename.Pos.Top - 15, Theme.WindowText);
	FontPrint('Pa' + HotkeySymbol + 'th:', 222, txtPath.Pos.Top - 15, Theme.WindowText);
	FontPrint('Pa' + HotkeySymbol + 'rameters:', 222, txtParams.Pos.Top - 15, Theme.WindowText);
	FontPrint('Pause after e' + HotkeySymbol + 'xecution', 242, chkPauseOnExit.Pos.Top + 3, Theme.WindowText);
	SetFillStyle(SolidFill, Theme.Desktop);
	Bar(btnIcon.Pos.Left + 2, btnIcon.Pos.Top + 2, btnIcon.Pos.Left +
		btnIcon.Pos.Width - 2, btnIcon.Pos.Top + btnIcon.Pos.Height - 2);
	ObjDrawImg(imgIcon);
	MouseShow;

	repeat
		Key := GetKey;

		if ObjBtnClick(btnOK) or (Key = KeyEnter) or (Key = KeyAltS) then
		begin
			if Length(txtFileNameText) <> 0 then
			begin
				{Sanitize path}
				if Length(txtPathText) <> 0 then
				begin
					if txtPathText[Length(txtPathText)] = '\' then
							txtPathText := Copy(txtPathText, 1, Length(txtPathText) - 1);
					if txtPathText + '\' = SysPath then
						txtPathText := '';
				end;
				DeskLink^[TargetLink]^.Caption := RTrim(txtCaptionText);
				DeskLink^[TargetLink]^.Filename := RTrim(txtFileNameText);
				DeskLink^[TargetLink]^.Path := RTrim(txtPathText);
				DeskLink^[TargetLink]^.Parameters := RTrim(txtParamsText);
				DeskLink^[TargetLink]^.PauseOnExit := chkPauseOnExit.Checked;
				DeskLink^[TargetLink]^.ImageFile := ImgIcon.ImageFile;
				
				DeskLinkSave;
				DeskDrawDesktop(false);
				FreeMem(BackgroundP, BackgroundSize);
				exit;
			end
			else
			begin
				MbVoid := SysMsgBox('Invalid program',
									'The ''Program'' field cannot be empty.',
									msgError);
			end;
		end;

		if ObjBtnClick(btnCancel) or (Key = KeyEscape) or (Key = KeyAltC) then
			break;

		if ObjBtnClick(btnIcon) or (Key = KeyAltI) then
		begin
			SelectedFile := FileSelect('*.bin', 'ICONS', True);
			if Length(SelectedFile) > 0 then
			begin
				FSplit(SelectedFile, FDir, FName, FExt);
				if (FDir = SysPath + 'ICONS\') and (FExt = '.BIN') then
				begin
					MouseHide;
					SetFillStyle(SolidFill, Theme.Desktop);
					Bar(btnIcon.Pos.Left + 2,
						btnIcon.Pos.Top + 2, 
						btnIcon.Pos.Left + btnIcon.Pos.Width - 2,
						btnIcon.Pos.Top + btnIcon.Pos.Height - 2);
					imgIcon.ImageFile := FName;
					ObjDrawImg(imgIcon);
					MouseShow;
				end
				else
					MbVoid := SysMsgBox('Invalid icon file',
						'The selected file is not a valid icon file.' + NewLine +
						'Please select a .BIN file from the ICONS directory.',
						msgError);
			end;
		end;

		if ObjTxtClick(txtFilename) or (Key = KeyAltF) then
		begin
			SelectedFile := FileSelect('*.exe', '', False);
			if Length(SelectedFile) <> 0 then
			begin
				FSplit(SelectedFile, FDir, FName, FExt);
				txtFilenameText := FName + FExt;
				txtPathText := FDir;
				MouseHide;
				ObjDrawTxt(txtFilename, txtFileNameText, false);
				ObjDrawTxt(txtPath, txtPathText, false);
				MouseShow;
			end;
		end;
	
		if ObjTxtClick(txtCaption) or (Key = KeyAltA) then
			ObjEditTxt(txtCaption, txtCaptionText);

		if ObjTxtClick(txtParams) or (Key = KeyAltR) then
			ObjEditTxt(txtParams, txtParamsText);

		if ObjTxtClick(txtPath) or (Key = KeyAltT) then
			ObjEditTxt(txtPath, txtPathText);

		ObjChkClick(chkPauseOnExit);
		if Key = KeyAltX then
		begin
			chkPauseOnExit.Checked := not chkPauseOnExit.Checked;
			MouseHide;
			ObjDrawChk(chkPauseOnExit);
			MouseShow;
		end;
			
	until false;

	MouseHide;
	PutImage(x1, y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;
end;

procedure DeskRun(TargetLink: TLink);
const
	RunFile = 'CONFIG\RUN.BIN';
var
	MbVoid: boolean;
	f: file;
	FPath: DirStr;
	FName: NameStr;
	FExt: ExtStr;
	ComSpec: String;
begin
	{If file not found, try adding the path from the link}
	if not FileExists(TargetLink.Filename) then
		TargetLink.Filename := TargetLink.Path + '\' + TargetLink.FileName;

	{If still not found, don't run it}
	if not FileExists(TargetLink.Filename) then
	begin
		MbVoid := SysMsgBox('File not found',
			'The program/file you are trying to open was not found:' + NewLine +
			TargetLink.Filename,
			msgError);
		exit;
	end;

	FSplit(TargetLink.Filename, FPath, FName, FExt);
	if (FExt <> '.EXE') and (FExt <> '.COM') and (FExt <> '.BAT') then
	begin
		MbVoid := SysMsgBox('Invalid file type',
			'The file you are trying to run is not a program.' + NewLine +
			'Only .EXE, .COM and .BAT files can be executed.',
			msgError);
		exit;
	end;

	{Batch files cannot be run directly, use COMSPEC to find command.com and
	 run the batch file with it}
	if FExt = '.BAT' then
	begin
		ComSpec := GetEnv('COMSPEC');
		if Length(ComSpec) = 0 then
		begin
			MbVoid := SysMsgBox('COMSPEC not set',
				'The COMSPEC environment variable is not set.' + NewLine +
				'This is required to run batch files.',
				msgError);
			exit;
		end;
		{Move batch filename and parameters to parameters}
		TargetLink.Parameters := '/C ' + TargetLink.Filename + ' ' + TargetLink.Parameters;
		{Replace filename with command.com}
		TargetLink.FileName := ComSpec;
	end;

	Assign(f, SysPath + RunFile);
	{$I-}
	Rewrite(f, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		Close(f);
		MbVoid := SysMsgBox('Writing '+ RunFile + ' failed',
			'Could not write to data file, can''t continue.' + NewLine +
			'Please check that the CONFIG directory exists and is writable.',
			msgError);
		exit;
	end;

	BlockWrite(f, TargetLink, SizeOf(TargetLink));
	Close(f);
	SysSaveSettings;

	repeat; until (Length(GetKey) = 0) and (MouseClicked = mbNone); {Clear buffers}
	CloseGraph;
	Halt(0); {Exit desktop. COSTA.EXE will read the file and execute the program}
end;

{Main program}
var
	SelectedLink, i: Integer;
	Key: String;
	TempLink: TLink;
begin
	btnAddLink.Init(3, 2, 92, 22, 'A' + HotkeySymbol + 'dd...');
	btnRunCmd.Init(102, 2, 92, 22, HotkeySymbol + 'Run...');
	btnPrevious.Init(255, 2, 42, 22, HotkeySymbol + '<');
	btnNext.Init(343, 2, 42, 22, HotkeySymbol + '>');
	btnAboutCosta.Init(446, 2, 92, 22, HotkeySymbol + 'About...');
	btnExitCosta.Init(545, 2, 92, 22, 'E' + HotkeySymbol + 'xit');
	btnTab.Init(0, 0, 37, 37, '');
	btnTab.Transparent := true;
	
	{Used for saving background when tabbing through icons}
	TabImgSize := ImageSize(0, 0, 37, 37);
	GetMem(TabBackgroundP, TabImgSize);

	{Switching desktop also loads links and draws the desktop}
	DeskSwitchDesktop(Setting.DesktopID);
	
	repeat
		Key := GetKey;

		MousePoll;
		if (MouseClicked <> mbNone) and (MouseY > 32) then
		begin
			{The mouse was clicked. Before checking if a desktop link was clicked,
			 check to see if any desktop links are present}
			if DeskLinkCount <> 0 then
			begin
				for i := DeskLinkCount downto 1 do
				begin
					{Check if the mouse was within the coordinates of the link}
					if (MouseX >= DeskLink^[i]^.Left) and (MouseX <= DeskLink^[i]^.Left + 31) then
					begin
						if (MouseY >= DeskLink^[i]^.Top) and (MouseY <= DeskLink^[i]^.Top + 31) then
						begin
							{If we reach this point, the link was clicked}
							DeskLinkMenu(i);
							break;
						end;
					end;

				end;
			end;
		end;

		if ObjBtnClick(btnAddLink) or (Key = KeyAltD) then
		begin
			FillChar(TempLink, SizeOf(TempLink), 0);
			TempLink.ImageFile := 'RUNPROG';
			TempLink.Left := 304;
			TempLink.Top := 174;
			DeskLinkAdd(TempLink);
			DeskLinkEdit(DeskLinkCount);
			if Length(DeskLink^[DeskLinkCount]^.Filename) = 0 then
				DeskLinkRemove(DeskLinkCount)
			else
				DeskLinkMove(DeskLinkCount);
		end;

		if ObjBtnClick(btnRunCmd) or (Key = KeyAltR) then
			DeskRunDialog;

		if ObjBtnClick(btnAboutCosta) or (Key = KeyAltA) then
			SysAboutBox(AppName, AppVersion, AppAuthor, AppIcon);
		
		if ObjBtnClick(btnPrevious) or (Key = KeyLeft) or (Key = KeyPageUp) then
			DeskSwitchDesktop(Setting.DesktopID - 1);

		if ObjBtnClick(btnNext) or (Key = KeyRight) or (Key = KeyPageDown) then
			DeskSwitchDesktop(Setting.DesktopID + 1);

		if Key = '1' then DeskSwitchDesktop(1);
		if Key = '2' then DeskSwitchDesktop(2);
		if Key = '3' then DeskSwitchDesktop(3);
		if Key = '4' then DeskSwitchDesktop(4);
		if Key = '5' then DeskSwitchDesktop(5);

		if ObjBtnClick(btnExitCosta) or (Key = KeyAltX) or (Key = KeyAltF4) then
		begin
			if not Setting.ConfirmExit then
				breaK;

			if SysMsgBox('Exit ' + appName, 'This will exit Costa and return you to the DOS'
					+ NewLine + 'prompt. Are you sure?', msgQuest) then
					break;
		end;

		if (Key = KeyTab) then
			DeskLinkTab(Next);
		
		if (Key = KeyShiftTab) then
			DeskLinkTab(Previous);
				
		if (Key = KeyEnter) and (KeySelection <> 0) then
		begin
			SelectedLink := KeySelection;
			DeskLinkTab(None);
			DeskLinkMenu(SelectedLink);
		end;
	
	until False;
	
	SysSaveSettings;
	FreeMem(TabBackgroundP, TabImgSize);
	CloseGraph;
	Halt(1); {Error code 1 makes COSTA.EXE terminate and return to DOS prompt}
end.