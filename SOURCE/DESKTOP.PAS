program Desktop;

uses
	Costalib, FileDlg, Graph, Crt, Strings, DOS;

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
	BtnAddLink, BtnRunCmd, BtnAboutCosta, BtnExitCosta: TButton;
	BtnPrevious, BtnNext: TButton;
	BtnTab: TButton;

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
begin
	if Size = 0 then
	begin
		LinkHeapError := 0;
		Exit;
	end;

	DeskLinkFree; {Free any previously allocated lines}
	MsgBox('Out of memory', 'Not enough memory to load desktop links.', MsgError);
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
	F: file;
	DeskLinkFile: string;
	ReadLink: TLink;
	ReadBytes: Word;
	NewLink: PLink;
begin
	{Make sure DeskLink is freed before loading new links}
	DeskLinkFree;

	Str(Setting.DeskID, DeskLinkFile);
	DeskLinkFile := 'CONFIG\DESKLNK' + DeskLinkFile + '.BIN';
	
	{If file doesn't exist, try to load default desktop links. If
	 that file doesn't exist either, exit and show empty desktop}
	if not FileExists(DeskLinkFile) then
	begin
		if FileExists('CONFIG\DESKDEF.BIN') and (Setting.DeskID = 1) then
			DeskLinkFile := 'CONFIG\DESKDEF.BIN'
		else
			exit;
	end;

	Assign(F, DeskLinkFile);
	{$I-}
	Reset(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		MsgBox('Error loading desktop links', 'Could not open file for reading. The' + NewLine + 
			'file may corrupt or inaccesible:' + newLine +
			DeskLinkFile, MsgError);
		Close(F);
		Exit;
	end;

	{Read the number of links in the file}
	BlockRead(F, DeskLinkCount, SizeOf(DeskLinkCount));
	
	{No links, exit}
	if DeskLinkCount = 0 then
	begin
		Close(F);
		exit;
	end;

	{Allocate memory for the array of links - DeskLinkCount is global so
	 DesklLinkInit knows the appropriate size}
	if not DeskLinkInit then
	begin
		MsgBox('Error loading desktop links',
			'Ran out of memory while loading desktop links.', MsgError);
		Close(F);
		Exit;
	end;
	
	{Load all links from file}
	for i := 1 to DeskLinkCount do
	begin
		FillChar(ReadLink, SizeOf(ReadLink), 0);
		BlockRead(F, ReadLink, SizeOf(ReadLink), ReadBytes);
		if ReadBytes <> SizeOf(ReadLink) then
		begin
			MsgBox('Error loading desktop links',
				'File size mismatch. This indicates that the desktop file' + NewLine + 
				'is corrupt:' + NewLine +
				DeskLinkFile, MsgError);
			Close(F);
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
	Close(F);
end;

procedure DeskLinkSave;
var
	i, j: integer;
	TempLink: PLink;
	F: file;
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
	Str(Setting.DeskID, DeskLinkFile);
	DeskLinkFile := 'CONFIG\DESKLNK' + DeskLinkFile + '.BIN';
	Assign(F, DeskLinkFile);
	{$I-}
	Rewrite(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		MsgBox('Error saving desktop links', 'Could not open file for writing. The' + NewLine + 
			'file read-only or inaccesible:' + newLine +
			DeskLinkFile, MsgError);
		Close(F);
		Exit;
	end;
	BlockWrite(F, DesklinkCount, SizeOf(DesklinkCount));

	{No links, close file}
	if DeskLinkCount = 0 then
	begin
		Close(F);
		Exit;
	end;

	{Write all links to file}
	for i := 1 to DeskLinkCount do
	begin
		BlockWrite(F, DeskLink^[i]^, SizeOf(TLink));
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
	ImgDeskLinkIcon: TIcon;
	i, X, Y: integer;
	DeskStr: string;
begin
	MouseHide;

	if FullRedraw then
	begin
		MenuBar.Draw;
		BtnAddLink.Draw;
		BtnRunCmd.Draw;
		BtnAboutCosta.Draw;
		BtnExitCosta.Draw;
		BtnPrevious.Draw;
		BtnNext.Draw;
		Str(Setting.DeskID, DeskStr);
		Print(DeskStr + '/5', 310, 10, Thm.WinText);
	end;

	{Clear background}
	SetFillStyle(SolidFill, Thm.Desk);
	Bar(0, 29, 639, 349);
	
	if DeskLinkCount = 0 then
	begin
		MouseShow;
		exit;
	end;
	
	for i := 1 to DeskLinkCount do
	begin
		X := DeskLink^[i]^.Left;
		Y := DeskLink^[i]^.Top;
		ImgDeskLinkIcon.Init(X, Y, DeskLink^[i]^.ImageFile);
		ImgDeskLinkIcon.Draw;

		if Setting.LinkCapt then
		begin
			Print(DeskLink^[i]^.Caption, X + 38, Y + 4, Thm.DeskText);
			if Setting.LinkTarget then
				Print(DeskLink^[i]^.FileName, X + 38, Y + 18, Thm.DeskText);
		end;
	end;
	
	MouseShow;
end;

procedure DeskSwitchDesktop(DeskID: integer);
begin
	if DeskID < 1 then
		DeskID := 5
	else if DeskID > 5 then
		DeskID := 1;

	Setting.DeskID := DeskID;
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
	BtnTab.Left := DeskLink^[KeySelection]^.Left - 3;
	BtnTab.Top := DeskLink^[KeySelection]^.Top - 3;
	BtnTab.Draw;
	MouseShow;
end;

procedure DeskRunDialog;
var
	WinRun: TWindow;
	TxtProgram, TxtParameters: TTextbox;
	BtnOK, BtnCancel, BtnBrowse: TButton;
	Key: string;
	SelectedFile: string;
	X1, Y1, X2, Y2: integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	RunLink: TLink;
begin
	TxtProgram.Text := '';
	TxtParameters.Text := '';
	FillChar(RunLink, SizeOf(RunLink), 0);

	WinRun.Init(sizeCenter, sizeCenter, 382, 137);
	TxtProgram.Init(WinRun.Left + 12, WinRun.Top + 27, WinRun.Width - 68, SizeDefault);
	TxtParameters.Init(TxtProgram.Left, TxtProgram.Top + 46, WinRun.Width - 26, SizeDefault);
	BtnBrowse.Init(TxtProgram.Left + TxtProgram.Width + 9, TxtProgram.Top, 33, SizeDefault, '...');
	BtnOK.Init(WinRun.Left + WinRun.Width - 184, TxtParameters.Top + 30, 80, SizeDefault, Hotkey + 'OK');
	BtnCancel.Init(WinRun.Left + WinRun.Width - 94, BtnOK.Top, 80, SizeDefault, Hotkey + 'Cancel');
		
	MouseHide;
	X1 := WinRun.Left;
	Y1 := WinRun.Top;
	X2 := WinRun.Left + WinRun.Width;
	Y2 := WinRun.Top + WinRun.Height;
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);

	WinRun.Draw;
	BtnOK.Draw;
	BtnCancel.Draw;
	BtnBrowse.Draw;
	TxtProgram.Draw;
	TxtParameters.Draw;
	
	Print(Hotkey + 'Program:', TxtProgram.Left, TxtProgram.Top - 16, Thm.WinText);
	Print('Pa' + Hotkey + 'rameters:', TxtParameters.Left, TxtParameters.Top - 16, Thm.WinText);
	MouseShow;

	repeat
		Key := GetKey;

		if BtnClick(BtnOK) or (Key = KeyAltO) or (Key = KeyEnter) then
		begin
			if Length(TxtProgram.Text) > 0 then
			begin
				RunLink.FileName := TxtProgram.Text;
				RunLink.Parameters := TxtParameters.Text;
				DeskRun(RunLink);
			end;
			break;
		end;

		if BtnClick(BtnCancel) or (Key = KeyAltC) or (Key = KeyEscape) then
			break;

		if BtnClick(BtnBrowse) or TxtClick(TxtProgram) or (Key = '.') or (Key = KeyAltP) then
		begin
			SelectedFile := FileSelect('*.exe', '', false);
			if Length(SelectedFile) > 0 then
			begin
				TxtProgram.Text := SelectedFile;
				MouseHide;
				TxtProgram.Draw;
				MouseShow;
			end;
		end;

		if TxtClick(TxtParameters) or (Key = KeyAltR) then
			TxtParameters.Edit;
	until false;

	{Restore background}
	MouseHide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;		
end;

procedure DeskLinkMenu(TargetLink: integer);
var
	WinLinkMenu: TWindow;
	BtnOpen, BtnEdit, BtnMove, BtnRemove, BtnCancel: TButton;
	ImgIcon: TIcon;
	X1, Y1, X2, Y2: integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Caption, Filename, Path, Parameters: string;
	DoDelete: boolean;
	Key, CroppedText: string;
begin
	WinLinkMenu.Init(sizeCenter, sizeCenter, 413, 165);
	BtnOpen.Init(WinLinkMenu.Left + 12, WinLinkMenu.Top + WinLinkMenu.Height - 64, 389,
		SizeDefault, Hotkey + 'Open');
	BtnEdit.Init(BtnOpen.Left, BtnOpen.Top + 30, SizeDefault, SizeDefault, Hotkey + 'Edit...');
	BtnMove.Init(BtnEdit.Left + 99, BtnEdit.Top, SizeDefault, SizeDefault, Hotkey + 'Move');
	BtnRemove.Init(BtnMove.Left + 99, BtnEdit.Top, SizeDefault, SizeDefault, Hotkey + 'Remove');
	BtnCancel.Init(BtnRemove.Left + 99, BtnEdit.Top, SizeDefault, SizeDefault, Hotkey + 'Cancel');
	ImgIcon.Init(WinLinkMenu.Left + 12, WinLinkMenu.Top + 11, DeskLink^[TargetLink]^.ImageFile);

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
	X1 := WinLinkMenu.Left;
	Y1 := WinLinkMenu.Top;
	X2 := WinLinkMenu.Left + WinLinkMenu.Width;
	Y2 := WinLinkMenu.Top + WinLinkMenu.Height;
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);
	
	WinLinkMenu.Draw;
	BtnOpen.Draw;
	BtnEdit.Draw;
	BtnMove.Draw;
	BtnRemove.Draw;
	BtnCancel.Draw;
	ImgIcon.Draw;

	Print(DeskLink^[TargetLink]^.Caption, X1 + 54, Y1 + 17, 0);
	Print(DeskLink^[TargetLink]^.Filename, X1 + 54, Y1 + 31, 0);
	Print('Path:', X1 + 12, Y1 + 59, 0);
	Print('Parameters:', X1 + 12, Y1 + 76, 0);
	
	Print(Path, X1 + 108, Y1 + 59, Thm.WinText);
	Print(Parameters, X1 + 108, Y1 + 76, Thm.WinText);
	MouseShow;

	{Clear buffers, sometimes needed on DOSBox}
	ClearInputBuffer;

	repeat
		Key := GetKey;
	
		{Cancel, or Escape key}
		if BtnClick(BtnCancel) or (Key = KeyAltC) or (Key = KeyEscape) then
		begin
			MouseHide;
			PutImage(X1, Y1, BackgroundP^, NormalPut);
			MouseShow;
			FreeMem(BackgroundP, BackgroundSize);
			break;
		end;
	
		{Open/run, or Enter key}
		if BtnClick(BtnOpen) or (Key = KeyAltO) or (Key = KeyEnter) then
		begin
			FreeMem(BackgroundP, BackgroundSize);
			DeskRun(DeskLink^[TargetLink]^);
			{If we've returned from the run, redraw the desktop since we've freed the memory}
			DeskDrawDesktop(true);
			break;
		end;

		{Configure}
		if BtnClick(BtnEdit) or (Key = KeyAltE) then
		begin
			MouseHide;
			PutImage(X1, Y1, BackgroundP^, NormalPut);
			MouseShow;
			FreeMem(BackgroundP, BackgroundSize);
			DeskLinkEdit(TargetLink);
			break;
		end;

		{Move}
		if BtnClick(BtnMove) or (Key = KeyAltM) then
		begin
			MouseHide;
			PutImage(X1, Y1, BackgroundP^, NormalPut);
			MouseShow;
			FreeMem(BackgroundP, BackgroundSize);
			DeskLinkMove(TargetLink);
			break;
		end;

		{Remove}
		if BtnClick(BtnRemove) or (Key = KeyAltR) then
		begin
			if Setting.ConfLinkDel then
				DoDelete := MsgBox('Remove desktop link', 'This will permanently delete this' +
					NewLine + 'desktop link. Are you sure?', MsgQuest)
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
	BtnPrevious, BtnNext: TButton;
	IconSize: Word;
	LinkIconP, BackdropP: Pointer;
	DrawX, DrawY: integer;
	CurGridX, CurGridY, LastGridX, LastGridY: integer;
	OriginalDesktop, SwitchedDesktop: integer;
	IconToMove: TLink;
	Key: String;
begin
	OriginalDesktop := Setting.DeskID;
	SwitchedDesktop := Setting.DeskID;
	
	{Delete current icon - it will be recreated after move to same or other
	 desktop}
	IconToMove := DeskLink^[TargetLink]^;
	DeskLinkRemove(TargetLink);
	DeskLinkSave;

	DrawX := IconToMove.Left;
	DrawY := IconToMove.Top;
	LastGridX := 0;
	LastGridY := 0;

	BtnPrevious.Init(255, 2, 42, SizeDefault, CharArrowLeft);
	BtnNext.Init(343, 2, 42, SizeDefault, CharArrowRight);

	MouseHide;
	IconSize := ImageSize(0, 0, 31, 31);
	GetMem(LinkIconP, IconSize);
	GetMem(BackdropP, IconSize);
	GetImage(DrawX, DrawY, DrawX + 31, DrawY + 31, LinkIconP^);
	GetImage(DrawX, DrawY, DrawX + 31, DrawY + 31, BackdropP^);
	MouseShow;

	{Center mouse on icon}
	MouseMove(DrawX + 16, DrawY + 16);

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
	ClearInputBuffer;
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
			MouseMove(MouseX, MouseY);

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

		if BtnClick(BtnPrevious) or (Key = KeyPageUp) then
			DeskSwitchDesktop(Setting.DeskID - 1);

		if BtnClick(BtnNext) or (Key = KeyPageDown) then
			DeskSwitchDesktop(Setting.DeskID + 1);

		{Redraw icon at current position if desktop has been switched}
		if Setting.DeskID <> SwitchedDesktop then
		begin
			MouseHide;
			GetImage(DrawX, DrawY, DrawX + 31, DrawY + 31, BackdropP^);
			PutImage(DrawX, DrawY, LinkIconP^, NormalPut);
			MouseShow;
			SwitchedDesktop := Setting.DeskID;
		end;

	until (MouseClicked <> MbNone) and (MouseY > 28);

	IconToMove.Left := DrawX;
	IconToMove.Top := DrawY;
	DeskLinkAdd(IconToMove);
	DeskLinkSave;
	DeskDrawDesktop(true);
	
	ClearInputBuffer;
end;

procedure DeskLinkEdit(TargetLink: integer);
var
	WinEdit: TWindow;
	TxtCaption, TxtFilename, TxtParams, TxtPath: TTextbox;
	BtnOK, BtnCancel, BtnIcon: TButton;
	ImgIcon: TIcon;
	ChkPauseOnExit: TCheckbox;
	Key: string;
	MbVoid: Boolean;
	SelectedFile: string;
	X1, Y1, X2, Y2: integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	FDir: DirStr;
	FName: NameStr;
	FExt: ExtStr;
begin
	WinEdit.Init(210, 35, 220, 312);

	BtnIcon.Init(296, WinEdit.Top + 12, 48, 48, '');
	ImgIcon.Init(305, BtnIcon.Top + 9, DeskLink^[TargetLink]^.ImageFile);
	
	TxtCaption.Init(222, BtnIcon.Top + 73, 196, SizeDefault);
	TxtFilename.Init(222, TxtCaption.Top + 44, 196, SizeDefault);
	TxtPath.Init(222, TxtFilename.Top + 44, 196, SizeDefault);
	TxtParams.Init(222, TxtPath.Top + 44, 196, SizeDefault);
	ChkPauseOnExit.Init(222, TxtParams.Top + 32, SizeDefault, SizeDefault);
	BtnOK.Init(229, ChkPauseOnExit.Top + 28, 84, SizeDefault, Hotkey + 'Save');
	BtnCancel.Init(326, BtnOK.Top, 84, SizeDefault, Hotkey + 'Cancel');

	BtnIcon.Transparent := true;
	TxtCaption.MaxLen := CaptionMaxLen;
	TxtFilename.MaxLen := SizeOf(ComStr); {Max length of a filename +}
	TxtParams.MaxLen := SizeOf(ComStr);
	TxtPath.MaxLen := SizeOf(DirStr);;
	TxtFileName.Text := DeskLink^[TargetLink]^.Filename;
	TxtParams.Text := DeskLink^[TargetLink]^.Parameters;
	TxtPath.Text := DeskLink^[TargetLink]^.Path;
	TxtCaption.Text := DeskLink^[TargetLink]^.Caption;
	ChkPauseOnExit.Checked := DeskLink^[TargetLink]^.PauseOnExit;

	MouseHide;
	X1 := WinEdit.Left;
	Y1 := WinEdit.Top;
	X2 := WinEdit.Left + WinEdit.Width;
	Y2 := WinEdit.Top + WinEdit.Height;
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);

	WinEdit.Draw;
	TxtCaption.Draw;
	BtnIcon.Draw;
	TxtFilename.Draw;
	TxtParams.Draw;
	TxtPath.Draw;
	ChkPauseOnExit.Draw;
	BtnOK.Draw;
	BtnCancel.Draw;
	Print('C' + Hotkey + 'aption:', 222, TxtCaption.Top - 15, Thm.WinText);
	Print(Hotkey + 'Program:', 222, TxtFilename.Top - 15, Thm.WinText);
	Print('Pa' + Hotkey + 'th:', 222, TxtPath.Top - 15, Thm.WinText);
	Print('Pa' + Hotkey + 'rameters:', 222, TxtParams.Top - 15, Thm.WinText);
	Print('Pause after e' + Hotkey + 'xecution', 242, ChkPauseOnExit.Top + 3, Thm.WinText);
	SetFillStyle(SolidFill, Thm.Desk);
	Bar(BtnIcon.Left + 2, BtnIcon.Top + 2, BtnIcon.Left + BtnIcon.Width - 2, BtnIcon.Top + BtnIcon.Height - 2);
	ImgIcon.Draw;
	MouseShow;

	repeat
		Key := GetKey;

		if BtnClick(BtnOK) or (Key = KeyEnter) or (Key = KeyAltS) then
		begin
			if Length(TxtFileName.Text) <> 0 then
			begin
				{Sanitize path}
				if Length(TxtPath.Text) <> 0 then
				begin
					if TxtPath.Text[Length(TxtPath.Text)] = '\' then
							TxtPath.Text := Copy(TxtPath.Text, 1, Length(TxtPath.Text) - 1);
					if TxtPath.Text + '\' = ProgramPath then
						TxtPath.Text := '';
				end;
				DeskLink^[TargetLink]^.Caption := TxtCaption.Text;
				DeskLink^[TargetLink]^.Filename := TxtFileName.Text;
				DeskLink^[TargetLink]^.Path := TxtPath.Text;
				DeskLink^[TargetLink]^.Parameters := TxtParams.Text;
				DeskLink^[TargetLink]^.PauseOnExit := ChkPauseOnExit.Checked;
				DeskLink^[TargetLink]^.ImageFile := ImgIcon.ImageFile;
				
				DeskLinkSave;
				DeskDrawDesktop(false);
				FreeMem(BackgroundP, BackgroundSize);
				exit;
			end
			else
			begin
				MsgBox('Invalid program',
					'The ''Program'' field cannot be empty.',
					MsgError);
			end;
		end;

		if BtnClick(BtnCancel) or (Key = KeyEscape) or (Key = KeyAltC) then
			break;

		if BtnClick(BtnIcon) or (Key = KeyAltI) then
		begin
			SelectedFile := FileSelect('*.bin', 'ICONS', True);
			if Length(SelectedFile) > 0 then
			begin
				FSplit(SelectedFile, FDir, FName, FExt);
				if (FDir = ProgramPath + 'ICONS\') and (FExt = '.BIN') then
				begin
					MouseHide;
					SetFillStyle(SolidFill, Thm.Desk);
					Bar(BtnIcon.Left + 2,
						BtnIcon.Top + 2, 
						BtnIcon.Left + BtnIcon.Width - 2,
						BtnIcon.Top + BtnIcon.Height - 2);
					ImgIcon.ImageFile := FName;
					ImgIcon.Draw;
					MouseShow;
				end
				else
					MsgBox('Invalid icon file',
						'The selected file is not a valid icon file.' + NewLine +
						'Please select a .BIN file from the ICONS directory.',
						MsgError);
			end;
		end;

		if TxtClick(TxtFilename) or (Key = KeyAltF) then
		begin
			SelectedFile := FileSelect('*.exe', '', False);
			if Length(SelectedFile) <> 0 then
			begin
				FSplit(SelectedFile, FDir, FName, FExt);
				TxtFileName.Text := FName + FExt;
				TxtPath.Text := FDir;
				MouseHide;
				TxtFilename.Draw;
				TxtPath.Draw;
				MouseShow;
			end;
		end;
	
		if TxtClick(TxtCaption) or (Key = KeyAltA) then
			TxtCaption.Edit;

		if TxtClick(TxtParams) or (Key = KeyAltR) then
			TxtParams.Edit;

		if TxtClick(TxtPath) or (Key = KeyAltT) then
			TxtPath.Edit;

		ChkClick(ChkPauseOnExit);
		if Key = KeyAltX then
		begin
			ChkPauseOnExit.Checked := not ChkPauseOnExit.Checked;
			MouseHide;
			ChkPauseOnExit.Draw;
			MouseShow;
		end;
			
	until false;

	MouseHide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;
end;

procedure DeskRun(TargetLink: TLink);
const
	RunFile = 'CONFIG\RUN.BIN';
var
	MbVoid: boolean;
	F: file;
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
		MsgBox('File not found',
			'The program/file you are trying to open was not found:' + NewLine +
			TargetLink.Filename,
			MsgError);
		exit;
	end;

	FSplit(TargetLink.Filename, FPath, FName, FExt);
	if (FExt <> '.EXE') and (FExt <> '.COM') and (FExt <> '.BAT') then
	begin
		MsgBox('Invalid file type',
			'The file you are trying to run is not a program.' + NewLine +
			'Only .EXE, .COM and .BAT files can be executed.',
			MsgError);
		exit;
	end;

	{Batch files cannot be run directly, use COMSPEC to find command.com and
	 run the batch file with it}
	if FExt = '.BAT' then
	begin
		ComSpec := GetEnv('COMSPEC');
		if Length(ComSpec) = 0 then
		begin
			MsgBox('COMSPEC not set',
				'The COMSPEC environment variable is not set.' + NewLine +
				'This is required to run batch files.',
				MsgError);
			exit;
		end;
		{Move batch filename and parameters to parameters}
		TargetLink.Parameters := '/C ' + TargetLink.Filename + ' ' + TargetLink.Parameters;
		{Replace filename with command.com}
		TargetLink.FileName := ComSpec;
	end;

	Assign(F, ProgramPath + RunFile);
	{$I-}
	Rewrite(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		Close(F);
		MsgBox('Writing '+ RunFile + ' failed',
			'Could not write to data file, can''t continue.' + NewLine +
			'Please check that the CONFIG directory exists and is writable.',
			MsgError);
		exit;
	end;

	BlockWrite(F, TargetLink, SizeOf(TargetLink));
	Close(F);
	SysSaveSettings;

	ClearInputBuffer;
	CloseGraph;
	Halt(0); {Exit desktop. COSTA.EXE will read the file and execute the program}
end;

{Main program}
var
	SelectedLink, i: Integer;
	Key: String;
	TempLink: TLink;
begin
	BtnAddLink.Init(3, 2, SizeDefault, SizeDefault, 'A' + Hotkey + 'dd...');
	BtnRunCmd.Init(102, 2, SizeDefault, SizeDefault, Hotkey + 'Run...');
	BtnPrevious.Init(255, 2, 42, SizeDefault, Hotkey + CharArrowLeft);
	BtnNext.Init(343, 2, 42, SizeDefault, Hotkey + CharArrowRight);
	BtnAboutCosta.Init(446, 2, SizeDefault, SizeDefault, Hotkey + 'About...');
	BtnExitCosta.Init(545, 2, SizeDefault, SizeDefault, 'E' + Hotkey + 'xit');
	BtnTab.Init(0, 0, 37, 37, '');
	BtnTab.Transparent := true;
	
	{Used for saving background when tabbing through icons}
	TabImgSize := ImageSize(0, 0, 37, 37);
	GetMem(TabBackgroundP, TabImgSize);

	{Switching desktop also loads links and draws the desktop}
	DeskSwitchDesktop(Setting.DeskID);
	
	repeat
		Key := GetKey;

		MousePoll;
		if (MouseClicked <> MbNone) and (MouseY > 32) then
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

		if BtnClick(BtnAddLink) or (Key = KeyAltD) then
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

		if BtnClick(BtnRunCmd) or (Key = KeyAltR) then
			DeskRunDialog;

		if BtnClick(BtnAboutCosta) or (Key = KeyAltA) then
			AboutBox(AppName, AppVersion, AppAuthor, AppIcon);
		
		if BtnClick(BtnPrevious) or (Key = KeyLeft) or (Key = KeyPageUp) then
			DeskSwitchDesktop(Setting.DeskID - 1);

		if BtnClick(BtnNext) or (Key = KeyRight) or (Key = KeyPageDown) then
			DeskSwitchDesktop(Setting.DeskID + 1);

		if Key = '1' then DeskSwitchDesktop(1);
		if Key = '2' then DeskSwitchDesktop(2);
		if Key = '3' then DeskSwitchDesktop(3);
		if Key = '4' then DeskSwitchDesktop(4);
		if Key = '5' then DeskSwitchDesktop(5);

		if BtnClick(BtnExitCosta) or (Key = KeyAltX) or (Key = KeyAltF4) then
		begin
			if not Setting.ConfExit then
				breaK;

			if MsgBox('Exit ' + appName, 'This will exit Costa and return you to the DOS'
					+ NewLine + 'prompt. Are you sure?', MsgQuest) then
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