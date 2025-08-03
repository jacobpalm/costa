program Desktop;

uses
	Costalib, FileDlg, Graph, Crt, Strings, DOS;

const
	AppName                   = 'Desktop';
	AppVersion                = '2.0';
	AppAuthor                 = 'Jacob Palm';
	AppIcon                   = 'LOGO';

	CaptionMaxLen             = 20; {Maximum length for link captions}

	CAP_BROWSE                = '...';
	CAP_OK                    = #127 + 'OK';
	CAP_CANCEL                = #127 + 'Cancel';
	CAP_PROGRAM               = #127 + 'Program:';
	CAP_PARAMETERS            = 'Pa' + #127 + 'rameters:';
	CAP_OPEN                  = #127 + 'Open';
	CAP_EDIT                  = #127 + 'Edit...';
	CAP_MOVE                  = #127 + 'Move';
	CAP_REMOVE                = #127 + 'Remove';
	CAP_SAVE                  = #127 + 'Save';
	CAP_PAUSE_ON_EXIT         = 'Pause after e' + #127 + 'xit';
	CAP_CAPTION               = 'C' + #127 + 'aption:';
	CAP_PATH                  = 'Pa' + #127 + 'th:';
	CAP_ADD                   = 'A' + #127 + 'dd...';
	CAP_RUN                   = #127 + 'Run...';
	CAP_ABOUT                 = #127 + 'About...';
	CAP_EXIT                  = 'E' + #127 + 'xit';

	MSG_LOAD_ERROR_TITLE      = 'Error loading desktop links';
	MSG_OUT_OF_MEMORY         = 'Out of memory.';
	MSG_DATA_ERROR            = 'Could not open file for reading. The' + #13 + 
	                            'file may corrupt or inaccesible:' + #13;
	MSG_FILE_SIZE_ERROR       = 'File size mismatch. This indicates that the desktop file' + #13 + 
	                            'is corrupt:' + #13;
	MSG_SAVE_ERROR_TITLE      = 'Error saving desktop links';
	MSG_SAVE_ERROR            = 'Could not open file for writing. The' + #13 + 
	                            'file may be read-only or inaccesible:' + #13;
	MSG_UNSPECIFIED           = 'Unspecified';
	MSG_NONE                  = 'None';
	MSG_PATH                  = 'Path:';
	MSG_PARAMETERS            = 'Parameters:';
	MSG_REMOVE_LINK_TITLE     = 'Remove desktop link';
	MSG_REMOVE_LINK           = 'This will permanently delete this' + #13 + 
	                            'desktop link. Are you sure?';
	MSG_INVALID_PROGRAM_TITLE = 'Invalid program';
	MSG_PROGRAM_MISSING       = 'The ''Program'' field cannot be empty.';
	MSG_INVALID_ICON_TITLE    = 'Invalid icon file';
	MSG_INVALID_ICON          = 'The selected file is not a valid icon file.' + #13 +
	                            'Please select a .BIN file from the ICONS directory.';
	MSG_NOT_A_PROGRAM_TITLE   = 'Not a program';
	MSG_NOT_A_PROGRAM         = 'The file you are trying to run is not a program.' + #13 +
	                            'Only .EXE, .COM and .BAT files can be executed.';
	MSG_FILE_NOT_FOUND_TITLE  = 'File not found';
	MSG_PROGRAM_NOT_FOUND     = 'The program/file you are trying to open was not found:' + #13;
	MSG_COMSPEC_TITLE         = 'COMSPEC not set';
	MSG_COMSPEC               = 'The COMSPEC environment variable is not set.' + #13 +
	                            'This is required to run batch files.';
	MSG_EXIT                  = 'Exit';
	MSG_EXIT_PROMPT           = 'This will exit Costa and return you to the DOS' + #13 +
	                            'prompt. Are you sure?';

type
	PLink = ^TLink;
	TLink = record
		Caption: String[CaptionMaxLen];
		FileName: PathStr;
		Path: DirStr;
		Parameters: ComStr;
		IconFile: String[8];
		PauseOnExit: Boolean;
		Left, Top: Integer;
	end;

	PLinkArray = ^TLinkArray;
	TLinkArray = Array[1..1] of PLink; {Flexible array to simulate dynamic sizing}

	TDirection = (None, Next, Previous); {For tabbing through links}

var
	Links: PLinkArray;
	LinkCount: Integer;
	KeySelection: Integer;
	TabImgSize: Word;
	TabBackgroundP: Pointer;

	{Buttons need to be redrawable from DrawDesktop}
	BtnAddLink, BtnRun, BtnAbout, BtnExit: TButton;
	BtnPrevious, BtnNext: TButton;
	BtnTab: TButton;

{Forward declarations}
	procedure DrawDesktop(FullRedraw: boolean); forward;
	procedure RunDlg; forward;
	procedure LinkEdit(TargetLink: integer); forward;
	procedure LinkLoad; forward;
	procedure LinkMenu(TargetLink: integer); forward;
	procedure LinkMove(TargetLink: integer); forward;
	procedure LinkSave; forward;
	procedure LinkFree; forward;
	procedure LinkTab(Direction: TDirection); forward;
	function  LinkInit: Boolean; forward;
	procedure RunProg(TargetLink: TLink); forward;

function LinkHeapError(Size: Word): Integer; far;
begin
	if Size = 0 then
	begin
		LinkHeapError := 0;
		Exit;
	end;

	LinkFree; {Free any previously allocated lines}
	MsgBox(MSG_LOAD_ERROR_TITLE, MSG_OUT_OF_MEMORY, MsgError);
	LinkHeapError := 1; {Make GetMem return a nil pointer}
end;

procedure LinkFree;
var
	i: Integer;
begin
	if LinkCount = 0 then
		exit;

	{Dispose all links in the array}
	for i := 1 to LinkCount do
		Dispose(Links^[i]);

	{Free the memory allocated for the array itself}
	FreeMem(Links, LinkCount * SizeOf(PLink));

	LinkCount := 0;
end;

function LinkInit: Boolean;
var
	DefaultHeapError: Pointer;
begin
	if LinkCount = 0 then
	begin
		LinkInit := false;
		Exit;
	end;

	{Use custom heap error handler to avoid program crash on out of memory}
	DefaultHeapError := HeapError;
	HeapError := @LinkHeapError;
	GetMem(Links, LinkCount * SizeOf(PLink));
	HeapError := DefaultHeapError;

	if Links = nil then
		LinkInit := false
	else
		LinkInit := true;
end;

procedure LinkLoad;
var
	i: integer;
	F: file;
	LinkFile: string;
	ReadLink: TLink;
	ReadBytes: Word;
	NewLink: PLink;
begin
	{Make sure Links is freed before loading new links}
	LinkFree;

	Str(Setting.DeskID, LinkFile);
	LinkFile := 'CONFIG\DESKLNK' + LinkFile + '.BIN';
	
	{If file doesn't exist, try to load default desktop links. If
	 that file doesn't exist either, exit and show empty desktop}
	if not FileExists(LinkFile) then
	begin
		if FileExists('CONFIG\DESKDEF.BIN') and (Setting.DeskID = 1) then
			LinkFile := 'CONFIG\DESKDEF.BIN'
		else
			exit;
	end;

	Assign(F, LinkFile);
	{$I-}
	Reset(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		MsgBox(MSG_LOAD_ERROR_TITLE, MSG_DATA_ERROR +
			LinkFile, MsgError);
		Close(F);
		Exit;
	end;

	{Read the number of links in the file}
	BlockRead(F, LinkCount, SizeOf(LinkCount));
	
	{No links, exit}
	if LinkCount = 0 then
	begin
		Close(F);
		exit;
	end;

	{Allocate memory for the array of links - LinkCount is global so
	 LinkInit knows the appropriate size}
	if not LinkInit then
	begin
		MsgBox(MSG_LOAD_ERROR_TITLE, MSG_OUT_OF_MEMORY, MsgError);
		Close(F);
		Exit;
	end;
	
	{Load all links from file}
	for i := 1 to LinkCount do
	begin
		FillChar(ReadLink, SizeOf(ReadLink), 0);
		BlockRead(F, ReadLink, SizeOf(ReadLink), ReadBytes);
		if ReadBytes <> SizeOf(ReadLink) then
		begin
			MsgBox(MSG_LOAD_ERROR_TITLE, MSG_FILE_SIZE_ERROR + LinkFile, MsgError);
			Close(F);
			LinkFree;
			if NewLink <> nil then
				Dispose(NewLink);
			Exit;
		end;
		
		{Create a new link pointer and assign the read data}
		New(NewLink);
		NewLink^ := ReadLink;
		{Add to array}
		Links^[i] := NewLink;
	end;
	Close(F);
end;

procedure LinkSave;
var
	i, j: integer;
	TempLink: PLink;
	F: file;
	LinkFile: string;
	mbVoid: Boolean;
begin
	{Sort before saving if array contains more than one item - this
	 enables TAB cycling from left to right, top to bottom}
	if LinkCount > 1 then
	begin
		for i := 1 to LinkCount - 1 do
		begin
			for j := 1 to LinkCount - i do
			begin
				{Compare positions: first by Left, then by Top if Left is equal}
				if (Links^[j]^.Left > Links^[j + 1]^.Left) or
				   ((Links^[j]^.Left = Links^[j + 1]^.Left) and
					(Links^[j]^.Top > Links^[j + 1]^.Top)) then
				begin
					{Swap links}
					TempLink := Links^[j];
					Links^[j] := Links^[j + 1];
					Links^[j + 1] := TempLink;
				end;
			end;
		end;
	end;

	{Save}
	Str(Setting.DeskID, LinkFile);
	LinkFile := 'CONFIG\DESKLNK' + LinkFile + '.BIN';
	Assign(F, LinkFile);
	{$I-}
	Rewrite(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		MsgBox(MSG_SAVE_ERROR_TITLE, MSG_SAVE_ERROR + LinkFile, MsgError);
		Close(F);
		Exit;
	end;
	BlockWrite(F, LinkCount, SizeOf(LinkCount));

	{No links, close file}
	if LinkCount = 0 then
	begin
		Close(F);
		Exit;
	end;

	{Write all links to file}
	for i := 1 to LinkCount do
	begin
		BlockWrite(F, Links^[i]^, SizeOf(TLink));
	end;
end;

procedure LinkAdd(NewLink: TLink);
var
	NewLinks: PLinkArray;
	PNewLink: PLink;
	i: Integer;
	DefaultHeapError: Pointer;
begin
	{If array hasn't been initialized, do so now}
	if LinkCount = 0 then
	begin
		LinkCount := 1;
		LinkInit;
	end
	else
	begin
		{Allocate new memory for the resized array}
		DefaultHeapError := HeapError;
		HeapError := @LinkHeapError;
		GetMem(NewLinks, (LinkCount + 1) * SizeOf(PLink));
		HeapError := DefaultHeapError;

		{If memory allocation failed, exit - error message will
		 already have been shown}
		if NewLinks = nil then
			exit;

		{Copy existing lines to the new array}
		Move(Links^[1], NewLinks^[1], LinkCount * SizeOf(PLink));

		{Free memory of the old array}
		FreeMem(Links, LinkCount * SizeOf(PLink));

		{Update the pointer to the new array}
		Links := NewLinks;

		Inc(LinkCount);
	end;

	New(PNewLink);
	PNewLink^ := NewLink;
	Links^[LinkCount] := PNewLink;
end;

procedure LinkRemove(TargetLink: integer);
var
	NewLinks: PLinkArray;
	PNewLink: PLink;
	i, Copied: Integer;
	DefaultHeapError: Pointer;
begin
	{If only one link left, or none, free the array}
	if LinkCount <= 1 then
	begin
		LinkFree;
		LinkCount := 0;
		Exit;
	end;

	{Allocate new memory for the resized array}
	DefaultHeapError := HeapError;
	HeapError := @LinkHeapError;
	GetMem(NewLinks, (LinkCount - 1) * SizeOf(PLink));
	HeapError := DefaultHeapError;

	if NewLinks = nil then
	begin
		{DEBUG - out of memory}
		exit;
	end;

	{Copy existing lines to the new array}
	Copied := 0;
	for i := 1 to LinkCount do
	begin
		if i <> TargetLink then
		begin
			Inc(Copied);
			NewLinks^[Copied] := Links^[i];
		end;
	end;

	{Dispose of the link being removed}
	Dispose(Links^[TargetLink]);

	{Free memory of the old array}
	FreeMem(Links, LinkCount * SizeOf(PLink));

	{Update the pointer to the new array}
	Links := NewLinks;
	Dec(LinkCount);
end;

procedure DrawDesktop(FullRedraw: boolean);
var
	ImgIcon: TIcon;
	i, X, Y: integer;
	DeskStr: string;
begin
	MouseHide;

	if FullRedraw then
	begin
		MenuBar.Draw;
		BtnAddLink.Draw;
		BtnRun.Draw;
		BtnAbout.Draw;
		BtnExit.Draw;
		BtnPrevious.Draw;
		BtnNext.Draw;
		Str(Setting.DeskID, DeskStr);
		Print(DeskStr + '/5', 310, 10, Thm.WinText);
	end;

	{Clear background}
	SetFillStyle(SolidFill, Thm.Desk);
	Bar(0, 29, 639, 349);
	
	if LinkCount = 0 then
	begin
		MouseShow;
		exit;
	end;
	
	for i := 1 to LinkCount do
	begin
		X := Links^[i]^.Left;
		Y := Links^[i]^.Top;
		ImgIcon.Init(X, Y, Links^[i]^.IconFile);
		ImgIcon.Draw;

		if Setting.LinkCapt then
		begin
			Print(Links^[i]^.Caption, X + 38, Y + 4, Thm.DeskText);
			if Setting.LinkTarget then
				Print(Links^[i]^.FileName, X + 38, Y + 18, Thm.DeskText);
		end;
	end;
	
	MouseShow;
end;

procedure SwitchDesk(DeskID: integer);
begin
	if DeskID < 1 then
		DeskID := 5
	else if DeskID > 5 then
		DeskID := 1;

	Setting.DeskID := DeskID;
	LinkLoad;
	KeySelection := 0;

	DrawDesktop(true);
end;

procedure LinkTab(Direction: TDirection);
begin

	{Check if any links exist before tabbing}
	if LinkCount = 0 then
		Exit;

	{If an icon is already selected, then deselect it by restoring the background}
	if KeySelection <> 0 then
	begin
		MouseHide;
		PutImage(Links^[KeySelection]^.Left - 3, Links^[KeySelection]^.Top - 3,
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
	if KeySelection > LinkCount then
		KeySelection := 1
	else if KeySelection < 1 then
		KeySelection := LinkCount;

	{Draw the selected link, saving background first}
	MouseHide;
	{Save background of new selected link}
	GetImage(Links^[KeySelection]^.Left - 3, Links^[KeySelection]^.Top - 3,
		Links^[KeySelection]^.Left + 34, Links^[KeySelection]^.Top + 34, TabBackgroundP^);
	{Draw the tab button around the selected link}
	BtnTab.Left := Links^[KeySelection]^.Left - 3;
	BtnTab.Top := Links^[KeySelection]^.Top - 3;
	BtnTab.Draw;
	MouseShow;
end;

procedure RunDlg;
var
	WinRun: TWindow;
	TxtFilename, TxtParams: TTextbox;
	BtnOK, BtnCancel, BtnBrowse: TButton;
	Key: string;
	SelectedFile: string;
	X1, Y1, X2, Y2: integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	RunLink: TLink;
begin
	FillChar(RunLink, SizeOf(RunLink), 0);

	WinRun.Init(sizeCenter, sizeCenter, 382, 137);
	TxtFilename.Init(WinRun.Left + 12, WinRun.Top + 27, WinRun.Width - 68, SizeDefault, CAP_PROGRAM);
	TxtParams.Init(TxtFilename.Left, TxtFilename.Top + 46, WinRun.Width - 26, SizeDefault, CAP_PARAMETERS);
	BtnBrowse.Init(TxtFilename.Left + TxtFilename.Width + 9, TxtFilename.Top, 33, SizeDefault, CAP_BROWSE);
	BtnOK.Init(WinRun.Left + WinRun.Width - 184, TxtParams.Top + 30, 80, SizeDefault, CAP_OK);
	BtnCancel.Init(WinRun.Left + WinRun.Width - 94, BtnOK.Top, 80, SizeDefault, CAP_CANCEL);
		
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
	TxtFilename.Draw;
	TxtParams.Draw;
	MouseShow;

	repeat
		Key := GetKey;

		if BtnOK.Clicked or (Key = KeyAltO) or (Key = KeyEnter) then
		begin
			if Length(TxtFilename.Text) > 0 then
			begin
				RunLink.FileName := TxtFilename.Text;
				RunLink.Parameters := TxtParams.Text;
				RunProg(RunLink);
			end;
			break;
		end;

		if BtnCancel.Clicked or (Key = KeyAltC) or (Key = KeyEscape) then
			break;

		if BtnBrowse.Clicked or TxtFilename.Clicked or (Key = '.') or (Key = KeyAltP) then
		begin
			SelectedFile := FileSelect('*.exe', '', false);
			if Length(SelectedFile) > 0 then
			begin
				TxtFilename.Text := SelectedFile;
				MouseHide;
				TxtFilename.Draw;
				MouseShow;
			end;
		end;

		if TxtParams.Clicked or (Key = KeyAltR) then
			TxtParams.Edit;
	until false;

	{Restore background}
	MouseHide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;		
end;

procedure LinkMenu(TargetLink: integer);
var
	WinLinkMenu: TWindow;
	BtnOpen, BtnEdit, BtnMove, BtnRemove, BtnCancel: TButton;
	ImgIcon: TIcon;
	X1, Y1, X2, Y2: integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Path, Parameters: string;
	DoDelete: boolean;
	Key: string;
begin
	WinLinkMenu.Init(sizeCenter, sizeCenter, 413, 165);
	BtnOpen.Init(WinLinkMenu.Left + 12, WinLinkMenu.Top + WinLinkMenu.Height - 64, 389, SizeDefault, CAP_OPEN);
	BtnEdit.Init(BtnOpen.Left, BtnOpen.Top + 30, SizeDefault, SizeDefault, CAP_EDIT);
	BtnMove.Init(BtnEdit.Left + 99, BtnEdit.Top, SizeDefault, SizeDefault, CAP_MOVE);
	BtnRemove.Init(BtnMove.Left + 99, BtnEdit.Top, SizeDefault, SizeDefault, CAP_REMOVE);
	BtnCancel.Init(BtnRemove.Left + 99, BtnEdit.Top, SizeDefault, SizeDefault, CAP_CANCEL);
	ImgIcon.Init(WinLinkMenu.Left + 12, WinLinkMenu.Top + 11, Links^[TargetLink]^.IconFile);

	Path := Links^[TargetLink]^.Path;
	Parameters := Links^[TargetLink]^.Parameters;
	if Length(Path) = 0 then
		Path := MSG_UNSPECIFIED;
	if Length(Parameters) = 0 then
		Parameters := MSG_NONE;

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

	Print(Links^[TargetLink]^.Caption, X1 + 54, Y1 + 17, Thm.WinText);
	Print(Links^[TargetLink]^.Filename, X1 + 54, Y1 + 31, Thm.WinText);
	Print(MSG_PATH, X1 + 12, Y1 + 59, Thm.WinText);
	Print(MSG_PARAMETERS, X1 + 12, Y1 + 76, Thm.WinText);
	Print(Path, X1 + 108, Y1 + 59, Thm.WinText);
	Print(Parameters, X1 + 108, Y1 + 76, Thm.WinText);
	MouseShow;

	{Clear buffers, sometimes needed on DOSBox}
	ClearInputBuffer;

	repeat
		Key := GetKey;
	
		{Cancel, or Escape key}
		if BtnCancel.Clicked or (Key = KeyAltC) or (Key = KeyEscape) then
		begin
			MouseHide;
			PutImage(X1, Y1, BackgroundP^, NormalPut);
			MouseShow;
			FreeMem(BackgroundP, BackgroundSize);
			break;
		end;
	
		{Open/run, or Enter key}
		if BtnOpen.Clicked or (Key = KeyAltO) or (Key = KeyEnter) then
		begin
			FreeMem(BackgroundP, BackgroundSize);
			RunProg(Links^[TargetLink]^);
			{If we've returned from the run, redraw the desktop since we've freed the memory}
			DrawDesktop(true);
			break;
		end;

		{Configure}
		if BtnEdit.Clicked or (Key = KeyAltE) then
		begin
			MouseHide;
			PutImage(X1, Y1, BackgroundP^, NormalPut);
			MouseShow;
			FreeMem(BackgroundP, BackgroundSize);
			LinkEdit(TargetLink);
			break;
		end;

		{Move}
		if BtnMove.Clicked or (Key = KeyAltM) then
		begin
			MouseHide;
			PutImage(X1, Y1, BackgroundP^, NormalPut);
			MouseShow;
			FreeMem(BackgroundP, BackgroundSize);
			LinkMove(TargetLink);
			break;
		end;

		{Remove}
		if BtnRemove.Clicked or (Key = KeyAltR) then
		begin
			if Setting.ConfLinkDel then
				DoDelete := MsgBox(MSG_REMOVE_LINK_TITLE, MSG_REMOVE_LINK, MsgQuest)
			else
				DoDelete := true;

			if DoDelete then
			begin
				LinkRemove(TargetLink);
				DrawDesktop(false);
				LinkSave;
				FreeMem(BackgroundP, BackgroundSize);
				break;
			end;
		end;

	until False;
			 
end;

procedure LinkMove(TargetLink: integer);
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
	IconToMove := Links^[TargetLink]^;
	LinkRemove(TargetLink);
	LinkSave;

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
			SwitchDesk(OriginalDesktop);
			LinkAdd(IconToMove);
			LinkSave;
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

		if Key = '1' then SwitchDesk(1);
		if Key = '2' then SwitchDesk(2);
		if Key = '3' then SwitchDesk(3);
		if Key = '4' then SwitchDesk(4);
		if Key = '5' then SwitchDesk(5);

		if BtnPrevious.Clicked or (Key = KeyPageUp) then
			SwitchDesk(Setting.DeskID - 1);

		if BtnNext.Clicked or (Key = KeyPageDown) then
			SwitchDesk(Setting.DeskID + 1);

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
	LinkAdd(IconToMove);
	LinkSave;
	DrawDesktop(true);
	
	ClearInputBuffer;
end;

procedure LinkEdit(TargetLink: integer);
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
	ImgIcon.Init(305, BtnIcon.Top + 9, Links^[TargetLink]^.IconFile);
	
	TxtCaption.Init(222, BtnIcon.Top + 73, 196, SizeDefault, CAP_CAPTION);
	TxtFilename.Init(222, TxtCaption.Top + 44, 196, SizeDefault, CAP_PROGRAM);
	TxtPath.Init(222, TxtFilename.Top + 44, 196, SizeDefault, CAP_PATH);
	TxtParams.Init(222, TxtPath.Top + 44, 196, SizeDefault, CAP_PARAMETERS);
	ChkPauseOnExit.Init(222, TxtParams.Top + 32, CAP_PAUSE_ON_EXIT);
	BtnOK.Init(229, ChkPauseOnExit.Top + 28, 84, SizeDefault, CAP_SAVE);
	BtnCancel.Init(326, BtnOK.Top, 84, SizeDefault, CAP_CANCEL);

	BtnIcon.Transparent := true;
	TxtCaption.MaxLen := CaptionMaxLen;
	TxtFilename.MaxLen := SizeOf(ComStr); {Max length of a filename +}
	TxtParams.MaxLen := SizeOf(ComStr);
	TxtPath.MaxLen := SizeOf(DirStr);
	TxtFileName.Text := Links^[TargetLink]^.Filename;
	TxtParams.Text := Links^[TargetLink]^.Parameters;
	TxtPath.Text := Links^[TargetLink]^.Path;
	TxtCaption.Text := Links^[TargetLink]^.Caption;
	ChkPauseOnExit.Checked := Links^[TargetLink]^.PauseOnExit;

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
	SetFillStyle(SolidFill, Thm.Desk);
	Bar(BtnIcon.Left + 2, BtnIcon.Top + 2, BtnIcon.Left + BtnIcon.Width - 2, BtnIcon.Top + BtnIcon.Height - 2);
	ImgIcon.Draw;
	MouseShow;

	repeat
		Key := GetKey;

		if BtnOK.Clicked or (Key = KeyEnter) or (Key = KeyAltS) then
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
				Links^[TargetLink]^.Caption := TxtCaption.Text;
				Links^[TargetLink]^.Filename := TxtFileName.Text;
				Links^[TargetLink]^.Path := TxtPath.Text;
				Links^[TargetLink]^.Parameters := TxtParams.Text;
				Links^[TargetLink]^.PauseOnExit := ChkPauseOnExit.Checked;
				Links^[TargetLink]^.IconFile := ImgIcon.IconFile;
				
				LinkSave;
				DrawDesktop(false);
				FreeMem(BackgroundP, BackgroundSize);
				exit;
			end
			else
			begin
				MsgBox(MSG_INVALID_PROGRAM_TITLE, MSG_PROGRAM_MISSING, MsgInfo);
			end;
		end;

		if BtnCancel.Clicked or (Key = KeyEscape) or (Key = KeyAltC) then
			break;

		if BtnIcon.Clicked or (Key = KeyAltI) then
		begin
			SelectedFile := FileSelect('*.BIN', 'ICONS', True);
			if Length(SelectedFile) > 0 then
			begin
				FSplit(SelectedFile, FDir, FName, FExt);
				if (FDir = ProgramPath + 'ICONS\') and (FExt = '.BIN') then
				begin
					MouseHide;
					SetFillStyle(SolidFill, Thm.Desk);
					Bar(BtnIcon.Left + 2, BtnIcon.Top + 2, BtnIcon.Left + BtnIcon.Width - 2, BtnIcon.Top + BtnIcon.Height - 2);
					ImgIcon.IconFile := FName;
					ImgIcon.Draw;
					MouseShow;
				end
				else
					MsgBox(MSG_INVALID_ICON_TITLE, MSG_INVALID_ICON, MsgError);
			end;
		end;

		if TxtFilename.Clicked or (Key = KeyAltF) then
		begin
			SelectedFile := FileSelect('*.EXE', '', False);
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
	
		if TxtCaption.Clicked or (Key = KeyAltA) then
			TxtCaption.Edit;

		if TxtParams.Clicked or (Key = KeyAltR) then
			TxtParams.Edit;

		if TxtPath.Clicked or (Key = KeyAltT) then
			TxtPath.Edit;

		if ChkPauseOnExit.Clicked or (Key = KeyAltX) then
			chkPauseOnExit.Toggle;
			
	until false;

	MouseHide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;
end;

procedure RunProg(TargetLink: TLink);
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
		MsgBox(MSG_FILE_NOT_FOUND_TITLE, MSG_PROGRAM_NOT_FOUND + TargetLink.Filename, MsgError);
		exit;
	end;

	FSplit(TargetLink.Filename, FPath, FName, FExt);
	if (FExt <> '.EXE') and (FExt <> '.COM') and (FExt <> '.BAT') then
	begin
		MsgBox(MSG_NOT_A_PROGRAM_TITLE, MSG_NOT_A_PROGRAM, MsgError);
		exit;
	end;

	{Batch files cannot be run directly, use COMSPEC to find command.com and
	 run the batch file with it}
	if FExt = '.BAT' then
	begin
		ComSpec := GetEnv('COMSPEC');
		if Length(ComSpec) = 0 then
		begin
			MsgBox(MSG_COMSPEC_TITLE,
				MSG_COMSPEC,
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
		MsgBox(MSG_SAVE_ERROR_TITLE, MSG_SAVE_ERROR + RunFile, MsgError);
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
	BtnAddLink.Init(3, 2, SizeDefault, SizeDefault, CAP_ADD);
	BtnRun.Init(102, 2, SizeDefault, SizeDefault, CAP_RUN);
	BtnPrevious.Init(255, 2, 42, SizeDefault, HotkeyChr + CharArrowLeft);
	BtnNext.Init(343, 2, 42, SizeDefault, HotkeyChr + CharArrowRight);
	BtnAbout.Init(446, 2, SizeDefault, SizeDefault, CAP_ABOUT);
	BtnExit.Init(545, 2, SizeDefault, SizeDefault, CAP_EXIT);
	BtnTab.Init(0, 0, 37, 37, '');
	BtnTab.Transparent := true;
	
	{Used for saving background when tabbing through icons}
	TabImgSize := ImageSize(0, 0, 37, 37);
	GetMem(TabBackgroundP, TabImgSize);

	{Switching desktop also loads links and draws the desktop}
	SwitchDesk(Setting.DeskID);
	
	repeat
		Key := GetKey;

		MousePoll;
		if (MouseClicked <> MbNone) and (MouseY > 32) then
		begin
			{The mouse was clicked. Before checking if a desktop link was clicked,
			 check to see if any desktop links are present}
			if LinkCount <> 0 then
			begin
				for i := LinkCount downto 1 do
				begin
					{Check if the mouse was within the coordinates of the link}
					if (MouseX >= Links^[i]^.Left) and (MouseX <= Links^[i]^.Left + 31) then
					begin
						if (MouseY >= Links^[i]^.Top) and (MouseY <= Links^[i]^.Top + 31) then
						begin
							{If we reach this point, the link was clicked}
							LinkMenu(i);
							break;
						end;
					end;

				end;
			end;
		end;

		if BtnAddLink.Clicked or (Key = KeyAltD) then
		begin
			FillChar(TempLink, SizeOf(TempLink), 0);
			TempLink.IconFile := 'RUNPROG';
			TempLink.Left := 304;
			TempLink.Top := 174;
			LinkAdd(TempLink);
			LinkEdit(LinkCount);
			if Length(Links^[LinkCount]^.Filename) = 0 then
				LinkRemove(LinkCount)
			else
				LinkMove(LinkCount);
		end;

		if BtnRun.Clicked or (Key = KeyAltR) then
			RunDlg;

		if BtnAbout.Clicked or (Key = KeyAltA) then
			AboutBox(AppName, AppVersion, AppAuthor, AppIcon);
		
		if BtnPrevious.Clicked or (Key = KeyLeft) or (Key = KeyPageUp) then
			SwitchDesk(Setting.DeskID - 1);

		if BtnNext.Clicked or (Key = KeyRight) or (Key = KeyPageDown) then
			SwitchDesk(Setting.DeskID + 1);

		if Key = '1' then SwitchDesk(1);
		if Key = '2' then SwitchDesk(2);
		if Key = '3' then SwitchDesk(3);
		if Key = '4' then SwitchDesk(4);
		if Key = '5' then SwitchDesk(5);

		if BtnExit.Clicked or (Key = KeyAltX) or (Key = KeyAltF4) then
		begin
			if not Setting.ConfExit then
				break;

			if MsgBox(MSG_EXIT + ' ' + appName, MSG_EXIT_PROMPT, MsgQuest) then
					break;
		end;

		if (Key = KeyTab) then
			LinkTab(Next);
		
		if (Key = KeyShiftTab) then
			LinkTab(Previous);
				
		if (Key = KeyEnter) and (KeySelection <> 0) then
		begin
			SelectedLink := KeySelection;
			LinkTab(None);
			LinkMenu(SelectedLink);
		end;
	
	until False;
	
	SysSaveSettings;
	FreeMem(TabBackgroundP, TabImgSize);
	CloseGraph;
	Halt(1); {Error code 1 makes COSTA.EXE terminate and return to DOS prompt}
end.