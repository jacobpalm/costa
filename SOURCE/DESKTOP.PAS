program Desktop;

{$M 32768, 0, 655360} {Require at least 32 KB stack}

uses
	Costalib, FileDlg, Graph, Crt, Strings, DOS;

const
	AppName                   = 'Desktop';
	AppVersion                = '2.0';
	AppAuthor                 = 'Jacob Palm';
	AppIcon                   = 'LOGO';

	CaptionMaxLen             = 20; {Maximum length for link captions}

	CAP_OK                    = #127 + 'OK';
	CAP_CANCEL                = #127 + 'Cancel';
	CAP_FILENAME              = #127 + 'Filename:';
	CAP_PARAMETERS            = 'Pa' + #127 + 'rameters:';
	CAP_OPEN                  = #127 + 'Open';
	CAP_EDIT                  = #127 + 'Edit...';
	CAP_MOVE                  = #127 + 'Move';
	CAP_REMOVE                = #127 + 'Remove';
	CAP_SAVE                  = #127 + 'Save';
	CAP_PAUSE_ON_EXIT         = 'Pause after e' + #127 + 'xit';
	CAP_CAPTION               = 'C' + #127 + 'aption:';
	CAP_PATH                  = 'Pa' + #127 + 'th:';
	CAP_ICON                  = #127 + 'Icon:';
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
	MSG_PROGRAM_MISSING       = 'The ''Filename'' field cannot be empty.';
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
		IconFile: String[8]; {8 char filename w/o extension}
		PauseOnExit: Boolean;
		Left, Top: Integer;
	end;

	PLinkNode = ^TLinkNode;
	TLinkNode = record
		Link: TLink;       {Link data}
		Next: PLinkNode;   {Pointer to the next node in the list}
	end;

	TSelectAction = (Hide, Show, Next, Previous); {For tabbing through links}

var
	Links: PLinkNode;
	SelectedLink: PLinkNode; {Used for cycling through links with TAB key}
	TabImgSize: Word;
	TabBackgroundP: Pointer;

	{Buttons need to be redrawable from DrawDesktop}
	BtnAddLink, BtnRun, BtnAbout, BtnExit: TButton;
	BtnPrevious, BtnNext: TButton;
	BtnTab: TButton;

{Forward declarations}
	procedure DrawDesktop(FullRedraw: boolean); forward;
	procedure RunDlg; forward;
	procedure LinkAdd(NewLink: TLink); forward;
	procedure LinkEdit(TargetNode: PLinkNode); forward;
	procedure LinkLoad; forward;
	procedure LinkMenu(TargetNode: PLinkNode); forward;
	procedure LinkMove(TargetNode: PLinkNode); forward;
	procedure LinkSave; forward;
	procedure LinkFree; forward;
	procedure SetSelection(Action: TSelectAction); forward;
	procedure RunProg(TargetLink: TLink); forward;

procedure LinkFree;
var
	TempNode: PLinkNode;
begin
	{Traverse linked list and free each node}
	while Links <> nil do
	begin
		TempNode := Links;
		Links := Links^.Next;
		Dispose(TempNode);
	end;
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
	SelectedLink := nil;

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
		MsgBox(MSG_LOAD_ERROR_TITLE, MSG_DATA_ERROR + LinkFile, MsgError);
		Close(F);
		Exit;
	end;

	while not EOF(F) do
	begin
		FillChar(ReadLink, SizeOf(ReadLink), 0);
		BlockRead(F, ReadLink, SizeOf(ReadLink), ReadBytes);
		if ReadBytes = SizeOf(ReadLink) then
			LinkAdd(ReadLink)
		else
		begin
			{File size mismatch, probably corrupt file}
			MsgBox(MSG_LOAD_ERROR_TITLE, MSG_FILE_SIZE_ERROR + LinkFile, MsgError);
			Close(F);
			LinkFree;
			Exit;
		end;
	end;
	
	Close(F);
end;

procedure LinkSave;
var
	TempLink: PLink;
	TempNode: PLinkNode;
	F: file;
	LinkFile: string;
	i, j: integer;
begin
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

	{No links, close file}
	if Links = nil then
	begin
		Close(F);
		Exit;
	end;

	{Write all links to file}
	TempNode := Links;
	while TempNode <> nil do
	begin
		BlockWrite(F, TempNode^.Link, SizeOf(TLink));
		TempNode := TempNode^.Next;
	end;

	Close(F);
end;

procedure LinkAdd(NewLink: TLink);
var
	NewNode, TempNode: PLinkNode;
begin
	New(NewNode);
	FillChar(NewNode^, SizeOf(TLinkNode), 0);
	NewNode^.Link := NewLink;
	NewNode^.Next := nil;

	{If no links already exist, this link will be head of the list}
	if Links = nil then
		Links := NewNode
	else
	begin
		{Find the end of the list and append the new link}
		TempNode := Links;
		while TempNode^.Next <> nil do
			TempNode := TempNode^.Next;
		TempNode^.Next := NewNode;
	end;
end;

procedure LinkRemove(TargetNode: PLinkNode);
var
	TempNode, PrevNode: PLinkNode;
	i: integer;
begin
	if TargetNode = nil then
		exit;

	TempNode := Links;
	PrevNode := nil;
	i := 1;

	{Find the target node in the linked list, and keep track of the previous node}
	while (TempNode <> nil) and (TempNode <> TargetNode) do
	begin
		PrevNode := TempNode;
		TempNode := TempNode^.Next;
		Inc(i);
	end;

	{TargetNode not found, nothing to remove}
	if TempNode = nil then
		Exit;

	{If no previous node, we are removing the head node}
	if PrevNode = nil then
		Links := TempNode^.Next
	else
		PrevNode^.Next := TempNode^.Next;

	{Free memory of removed link}
	Dispose(TempNode);

	SelectedLink := nil;
end;

{Sorts the links in the Links linked list by position on screen, from top left
 to bottom right. This is used to enable cycling through links with the TAB key,
 without having to iterate through the entire list to find the next link.}
procedure LinkSort;
var
	Sorted: Boolean;
	CurrentNode, NextNode, PrevNode: PLinkNode;
begin
	{ Can't sort Links if there are no links }
	if Links = nil then
		Exit;

	{Itererate through Links until no swaps are made}
	repeat
		Sorted := true;
		CurrentNode := Links;
		PrevNode := nil;
 
		while (CurrentNode <> nil) and (CurrentNode^.Next <> nil) do
		begin
			NextNode := CurrentNode^.Next;

			{If the current node is further to the left than the next node, swap them. If they are at the same left position,
			 swap them if the next node is further down}
			if (CurrentNode^.Link.Left > NextNode^.Link.Left) or
			   ((CurrentNode^.Link.Left = NextNode^.Link.Left) and
			    (CurrentNode^.Link.Top > NextNode^.Link.Top)) then
			begin
				{Swap the two nodes in the Links linked list}
				
				{If PrevNode is nil, we are swapping the head node}
				if PrevNode = nil then
					Links := NextNode
				else
					PrevNode^.Next := NextNode;

				CurrentNode^.Next := NextNode^.Next;
				NextNode^.Next := CurrentNode;

				{We are not sorted yet, since we made a swap}
				Sorted := false;

				{NextNode is now the previous node for the next iteration}
				PrevNode := NextNode;
			end
			else
			begin
				{No swap occured, move to the next node}
				PrevNode := CurrentNode;
				CurrentNode := CurrentNode^.Next;
			end;
		end;
	until Sorted;
end;

procedure DrawDesktop(FullRedraw: boolean);
var
	ImgIcon: TIcon;
	TempNode: PLinkNode;
	X, Y: integer;
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
	
	TempNode := Links;
	while TempNode <> nil do
	begin
		X := TempNode^.Link.Left;
		Y := TempNode^.Link.Top;
		ImgIcon.Init(X, Y, TempNode^.Link.IconFile);
		ImgIcon.Draw;

		if Setting.LinkCapt then
		begin
			Print(TempNode^.Link.Caption, X + 38, Y + 4, Thm.DeskText);
			if Setting.LinkTarget then
				Print(TempNode^.Link.FileName, X + 38, Y + 18, Thm.DeskText);
		end;

		TempNode := TempNode^.Next;
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

	DrawDesktop(true);
end;

procedure SetSelection(Action: TSelectAction);
var
	LastNode, PrevNode: PLinkNode;
begin
	{Nothing to tab through, exit}
	if Links = nil then
		exit;

	{Remove current selection, if any}
	if (SelectedLink <> nil) and (Action <> Show) then
	begin
		MouseHide;
		PutImage(SelectedLink^.Link.Left - 3, SelectedLink^.Link.Top - 3, TabBackgroundP^, NormalPut);
		MouseShow;
	end;

	case Action of
		Hide:
			{No selection, so nothing else to do}
			exit;

		Next:
			{If no selection, or last node selected, wrap around to first node}
			if (SelectedLink = nil) or (SelectedLink^.Next = nil) then
				SelectedLink := Links
			else
				SelectedLink := SelectedLink^.Next;

		Previous:
			begin
				{If no previous selection, or first node selected, wrap around to last node}
				if (SelectedLink = nil) or (SelectedLink = Links) then
				begin
					{Find the last node in Links by iterating until there is no Next node}
					SelectedLink := Links;
					while (SelectedLink^.Next <> nil) do
						SelectedLink := SelectedLink^.Next;
				end
				else
				begin
					{Find the previous node by iterating through the list}
					PrevNode := Links;
					while (PrevNode <> nil) and (PrevNode^.Next <> SelectedLink) do
						PrevNode := PrevNode^.Next;
					if PrevNode <> nil then
						SelectedLink := PrevNode
					else
						SelectedLink := Links; {We didn't find the previous node, so wrap around to the head node}
				end;
			end;
	end;

	{Draw the selected link, saving background first}
	MouseHide;
	{Save background of new selected link}
	GetImage(SelectedLink^.Link.Left - 3, SelectedLink^.Link.Top - 3,
	         SelectedLink^.Link.Left + 34, SelectedLink^.Link.Top + 34, TabBackgroundP^);
	{Draw the tab button around the selected link}
	BtnTab.Left := SelectedLink^.Link.Left - 3;
	BtnTab.Top := SelectedLink^.Link.Top - 3;
	BtnTab.Draw;
	MouseShow;
end;

procedure RunDlg;
var
	WinRun: TWindow;
	TxtFilename, TxtParams: TTextbox;
	BtnOK, BtnCancel: TButton;
	Key: string;
	SelectedFile: string;
	X1, Y1, X2, Y2: integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	RunLink: TLink;
begin
	FillChar(RunLink, SizeOf(RunLink), 0);

	WinRun.Init(sizeCenter, sizeCenter, 382, 137);
	TxtFilename.Init(WinRun.Left + 12, WinRun.Top + 27, WinRun.Width - 68, SizeDefault, CAP_FILENAME);
	TxtParams.Init(TxtFilename.Left, TxtFilename.Top + 46, TxtFilename.Width, SizeDefault, CAP_PARAMETERS);
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

		if TxtFilename.Clicked or (Key = KeyAltF) then
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

procedure LinkMenu(TargetNode: PLinkNode);
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
	ImgIcon.Init(WinLinkMenu.Left + 12, WinLinkMenu.Top + 11, TargetNode^.Link.IconFile);

	Path := TargetNode^.Link.Path;
	Parameters := TargetNode^.Link.Parameters;
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

	Print(TargetNode^.Link.Caption, X1 + 54, Y1 + 17, Thm.WinText);
	Print(TargetNode^.Link.Filename, X1 + 54, Y1 + 31, Thm.WinText);
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
			RunProg(TargetNode^.Link);
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
			LinkEdit(TargetNode);
			break;
		end;

		{Move}
		if BtnMove.Clicked or (Key = KeyAltM) then
		begin
			MouseHide;
			PutImage(X1, Y1, BackgroundP^, NormalPut);
			MouseShow;
			FreeMem(BackgroundP, BackgroundSize);
			LinkMove(TargetNode);
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
				LinkRemove(TargetNode);
				DrawDesktop(false);
				LinkSave;
				FreeMem(BackgroundP, BackgroundSize);
				break;
			end;
		end;

	until False;
			 
end;

procedure LinkMove(TargetNode: PLinkNode);
const
	GridSize = 4; {Size of grid in pixels, used for aligning icons}
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
	IconToMove := TargetNode^.Link;
	LinkRemove(TargetNode);
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
	LinkSort; {Sort links by position on screen}
	LinkSave;
	SelectedLink := nil;
	DrawDesktop(true);
	
	ClearInputBuffer;
end;

procedure LinkEdit(TargetNode: PLinkNode);
var
	WinEdit: TWindow;
	TxtCaption, TxtFilename, TxtParams, TxtPath: TTextbox;
	BtnOK, BtnCancel, BtnIcon: TButton;
	ImgIcon: TIcon;
	ChkPauseOnExit: TCheckbox;
	Key: string;
	SelectedFile: string;
	X1, Y1, X2, Y2: integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	FDir: DirStr;
	FName: NameStr;
	FExt: ExtStr;
begin
	{Can't edit a non-existing link}
	if TargetNode = nil then
		exit;

	WinEdit.Init(210, 31, 220, 317);

	BtnIcon.Init(SizeCenter, WinEdit.Top + 26, 41, 41, '');
	ImgIcon.Init(BtnIcon.Left + 5, BtnIcon.Top + 5, TargetNode^.Link.IconFile);
	
	TxtCaption.Init(222, BtnIcon.Top + 66, 196, SizeDefault, CAP_CAPTION);
	TxtFilename.Init(222, TxtCaption.Top + 44, 196, SizeDefault, CAP_FILENAME);
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
	TxtFileName.Text := TargetNode^.Link.Filename;
	TxtParams.Text := TargetNode^.Link.Parameters;
	TxtPath.Text := TargetNode^.Link.Path;
	TxtCaption.Text := TargetNode^.Link.Caption;
	ChkPauseOnExit.Checked := TargetNode^.Link.PauseOnExit;

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
	Print(CAP_ICON, 222, WinEdit.Top + 11, Thm.WinText);
	MouseShow;

	SelectedFile := '';

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
				TargetNode^.Link.Caption := TxtCaption.Text;
				TargetNode^.Link.Filename := TxtFileName.Text;
				TargetNode^.Link.Path := TxtPath.Text;
				TargetNode^.Link.Parameters := TxtParams.Text;
				TargetNode^.Link.PauseOnExit := ChkPauseOnExit.Checked;
				TargetNode^.Link.IconFile := ImgIcon.IconFile;
				
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
	Key: String;
	TempNode: PLinkNode;
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

		if Key = KeyF5 then
		begin
			LinkSort;
			{DEBUG}
			DrawDesktop(false);
		end;

		MousePoll;
		if (MouseClicked <> MbNone) and (MouseY > 32) then
		begin
			{The mouse was clicked. Check if it was on a link icon}
			TempNode := Links;
			while TempNode <> nil do
			begin
				if (MouseX >= TempNode^.Link.Left) and
				   (MouseX <= TempNode^.Link.Left + 31) and
				   (MouseY >= TempNode^.Link.Top) and
				   (MouseY <= TempNode^.Link.Top + 31) then
				begin
					LinkMenu(TempNode);
					Break;
				end;
				TempNode := TempNode^.Next;
			end;
		end;

		if BtnAddLink.Clicked or (Key = KeyAltD) then
		begin
			{Add a new link}
			FillChar(TempLink, SizeOf(TempLink), 0);
			TempLink.IconFile := 'RUNPROG';
			TempLink.Left := 304;
			TempLink.Top := 174;
			LinkAdd(TempLink);
			
			{Find the newly added link in the linked list, it will
			 be the last one with a nil Next pointer}
			TempNode := Links;
			while TempNode^.Next <> nil do
				TempNode := TempNode^.Next;
			
			{Edit the new link}
			LinkEdit(TempNode);

			{If the filename of the link is empty, the user didn't save it,
			 so remove the link from the list. Otherwise, let the user place
			 it where they'd like using LinkMove}
			if Length(TempNode^.Link.Filename) = 0 then
				LinkRemove(TempNode)
			else
				LinkMove(TempNode);
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
			SetSelection(Next);
		
		if (Key = KeyShiftTab) then
			SetSelection(Previous);
				
		if (Key = KeyEnter) and (SelectedLink <> nil) then
		begin
			SetSelection(Hide); {Remove the indicator around the selected link}
			LinkMenu(SelectedLink);
			if SelectedLink <> nil then
				SetSelection(Show); {Redraw the indicator around the selected link}
		end;
	
	until False;
	
	SysSaveSettings;
	FreeMem(TabBackgroundP, TabImgSize);
	CloseGraph;
	Halt(1); {Error code 1 makes COSTA.EXE terminate and return to DOS prompt}
end.