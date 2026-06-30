unit UIDesk;

{Desktop control with links for applications and functionality to add/remove
 links, as well as move them around. Also able to load/save links from files.}

interface

uses
	CostaLib, UIIcon, DOS, Graph;

const
	LinkGridSize  = 4;   {Icons are moved in increments of this size to help ease
	                      alignment}
	MaxLinkCount  = 100; {Maximum number of links on the desktop}
	LinkCaptMax   = 20;  {Maximum length for link captions}

type
	{Actions that can be triggered on the tab keyboard indicator}
	TTabAction = (TabClear, TabHide, TabMoveNext, TabMovePrev);

	{Link record type}
	PLink = ^TLink;
	TLink = record
		Caption:     String[LinkCaptMax];
		FileName:    PathStr;
		Path:        DirStr;
		Parameters:  ComStr;
		IconFile:    String[8]; {8 char filename w/o extension}
		PauseOnExit: Boolean;
		Left,
		Top:         Integer;
	end;

	{Linked list node for links}
	PLinkNode = ^TLinkNode;
	TLinkNode = record
		Link: PLink;       {Link data}
		Next: PLinkNode;   {Pointer to the next node in the list}
	end;

	PDesktop  = ^TDesktop;
	TDesktop  = object(TContainer)
		public
			constructor  Init(X, Y: Integer; Parent: PContainer);
			destructor   Done; virtual;
			procedure    Draw; virtual;
			procedure    CheckEvent; virtual;

			procedure    AddLink(Link: PLink);
			procedure    RemoveLink(Link: PLink);

			procedure    MoveLink(Link: PLink);

			procedure    SetDisplay(Captions, Targets: boolean);

			function     LoadLinks(Filename: string): boolean;
			function     SaveLinks(Filename: string): boolean;
			procedure    ClearLinks;

			function     GetActiveLink: PLink;

			procedure    SetOnRightClick(Proc: TEventProc);
		private
			Links:        PLinkNode;   {Head of the linked list of links}
			LinkCount:    Byte;        {Number of links on the desktop}
			SelectedLink: PLink;       {Currently selected link, if any}
			TabVisible:   Boolean;     {Whether the keyboard tab indicator is visible}
			TabBgImg:     Pointer;     {Saved background image for tab indicator}
			TabBgSize:    Word;        {Memory size of the saved background image for tab indicator}
			OnRightClick: TEventProc;  {Event to trigger on link right click - inherited OnClick is used for left click}
			ShowCaption,
			ShowTarget:   Boolean;     {Toggles visibility of text next to icons}
			procedure     DrawLink(Link: PLink);
			procedure     DoTabAction(Action: TTabAction);
			procedure     SortLinks;   {Sort links based on position left to right, top to botton, for easy tab navigation}
	end;

implementation

constructor TDesktop.Init(X, Y: Integer; Parent: PContainer);
begin
	inherited Init(X, Y, Parent);
	Links        := nil;
	LinkCount    := 0;
	SelectedLink := nil;
	OnRightClick := nil;
	TabVisible   := false;
	TabBgSize    := ImageSize(0, 0, 37, 37);

	{Allocate memory for tab background image, 32x32 icon plus 3 pixel border}
	GetMem(TabBgImg, TabBgSize);
end;

destructor TDesktop.Done;
begin
	Self.ClearLinks;
	FreeMem(TabBgImg, TabBgSize);
	inherited Done;
end;

procedure TDesktop.Draw;
var
	x1, y1, x2, y2: Integer;
	TempNode: PLinkNode;
	BgColor: byte;
begin
	if GetState(SHidden) then
		Exit;

	{Get absolute position and size}
	Self.GetPos(x1, y1, True);
	Self.GetSize(x2, y2);
	Inc(X2, X1);
	Inc(Y2, Y1);

	{Draw background}
	BgColor := GetBgColor;
	if BgColor = ColorDefault then
		BgColor := Thm.Desk;

	SetFillStyle(SolidFill, BgColor);
	Bar(X1, Y1, X2, Y2);

	{If OnDraw event assigned, call it before drawing links (none of parent objects
	 draw anything, but we call inherited Draw to maintain proper structure)}
	Inherited Draw;

	{Draw links}
	TempNode := Links;
	while TempNode <> nil do
	begin
		DrawLink(TempNode^.Link);
		TempNode := TempNode^.Next;
	end;
end;

procedure TDesktop.DrawLink(Link: PLink);
var
	ImgIcon: PIcon;
	X, Y: Integer;
	Color: byte;
	FDir:         DirStr;
	FName:        NameStr;
	FExt:         ExtStr;
begin
	if (Link = nil) or (GetState(SHidden)) then
		Exit;

	{Get absolute position of desktop, and set icon position relative to it}
	GetPos(X, Y, True);
	Inc(X, Link^.Left);
	Inc(Y, Link^.Top);

	Color := GetFgColor;
	if Color = ColorDefault then
		Color := Thm.DeskText;

	New(ImgIcon, Init(X, Y, Link^.IconFile, nil));
	ImgIcon^.Draw;
	Dispose(ImgIcon);

	{If caption display is enabled, draw it to the right of the icon - also
	 display the target filename if that setting is enabled}
	if ShowCaption then
	begin
		Print(Link^.Caption, X + 38, Y + 4, Color);
		if ShowTarget then
		begin
			FSplit(Link^.FileName, FDir, FName, FExt);
			Print(FName + FExt, X + 38, Y + 18, Color);
		end;
	end;
end;

procedure TDesktop.CheckEvent;
var
	TempNode: PLinkNode;
	OffsetX, OffsetY: integer;
	X1, Y1, X2, Y2: Integer;
	MouseButton: Word;
	KeyPressed: boolean;
begin
	{Don't check for events if object is disabled or hidden}
	if not GetState(SEnabled) or GetState(SHidden) then
		exit;

	{Check for mouse click}
	if IsMouseOver and (Mouse.Clicked <> MbNone) then
	begin
		{Capture mouse state}
		MouseButton := Mouse.Clicked;

		{Mouse was clicked, so hide keyboard tab indicator and clear SelectedItem}
		DoTabAction(TabClear);

		{Get absolute position of desktop and calculate substract it from mouse position,
		 giving us the realtive position on the desktop which can be compared against links}
		GetPos(OffsetX, OffsetY, True);
		OffsetX := Mouse.X - OffSetX;
		OffsetY := Mouse.Y - OffSetY;

		{Iterate through links to see if one was clicked}
		TempNode := Links;
		while TempNode <> nil do
		begin
			{Get coordinates of the link area (34x34 pixels since there is a 1px border
			 around the 32x32 icon that should also be clicckable)}
			X1 := TempNode^.Link^.Left - 1;
			Y1 := TempNode^.Link^.Top - 1;
			X2 := X1 + 33;
			Y2 := Y1 + 33;
			if (OffsetX >= X1) and (OffsetX <= X2) and
			   (OffsetY >= Y1) and (OffsetY <= Y2) then
			begin
				{Link was clicked, set it as active link}
				SelectedLink := TempNode^.Link;
				break;
			end;
			{Not clicked, check next link}
			TempNode := TempNode^.Next;
		end;

		{Wait for mouse button release before calling event handler to avoid multiple clicks}
		repeat; until Mouse.Clicked = MbNone;

		{Trigger click or right-click event - if a link was clicked, SelectedLink
		 will be set to it, otherwise it will be nil. Application can check that
		 using GetActiveLink}
		case MouseButton of
			MbLeft:
				Self.Click;
			MbRight:
				if Assigned(OnRightClick) then
					OnRightClick(@Self);
		end;
	end;

	{Check for keyboard input}
	if Length(HotkeyInput) = 0 then
		exit;

	{KeyPressed tracks whether any relevant key was pressed, to clear HotkeyInput later
	 so other objects won't catch it and to trigger OnClick event}
	KeyPressed := false;

	{Tab/Shift+Tab to cycle through links}
	if HotkeyInput = KeyTab then
	begin
		KeyPressed := true;
		DoTabAction(TabMoveNext);
	end;
	if HotkeyInput = KeyShiftTab then
	begin
		KeyPressed := true;
		DoTabAction(TabMovePrev);
	end;

	{Enter to clear a cell, Space to toggle flag}
	if (HotkeyInput = KeyEnter) and Assigned(SelectedLink) then
	begin
		KeyPressed := true;
		if Assigned(SelectedLink) then
			Self.Click;
	end;

	{If a key was pressed, clear it so other objects won't catch it}
	if KeyPressed then
		HotkeyInput := '';
end;

{Adds a new link to the desktop. The link data is copied into a new node
 in the linked list, so it's up to the caller to dispose of the original link data
 if needed and the pointer passed cannot be used to reference the link later}
procedure TDesktop.AddLink(Link: PLink);
var
	NewNode: PLinkNode;
	NewLink: PLink;
begin
	if LinkCount >= MaxLinkCount then
		Exit; {Maximum link count reached}

	{Hide selection tab if visible as link order may change now}
	DoTabAction(TabClear);
	SelectedLink := nil;

	{Copy link data into new node, set its next pointer to current head,
	 and update head pointer to new node}
	New(NewNode);
	New(NewLink);
	NewLink^ := Link^;
	NewNode^.Link := NewLink;
	NewNode^.Next := Links;
	Links := NewNode;

	{Draw the new link on the desktop - we don't use SDirty flag here because
	 we only want to draw a single icon, not entire object}
	Mouse.Hide;
	DrawLink(NewLink);
	Mouse.Show;

	{Increment link count so we can track if we reach the maximum}
	Inc(LinkCount);

	Self.SortLinks;
end;

procedure TDesktop.RemoveLink(Link: PLink);
var
	TempNode, PrevNode: PLinkNode;
begin
	if Links = nil then
		Exit; {No links to remove}

	{Hide selection tab if visible as link order may change now}
	DoTabAction(TabClear);

	TempNode := Links;
	PrevNode := nil;
	while TempNode <> nil do
	begin
		if TempNode^.Link = Link then
		begin
			{Found the link to remove}
			if PrevNode = nil then
			begin
				{Removing head node}
				Links := TempNode^.Next;
			end
			else
			begin
				{Bypass the node to remove it}
				PrevNode^.Next := TempNode^.Next;
			end;

			if Assigned(TempNode^.Link) then
				Dispose(TempNode^.Link);
			Dispose(TempNode);

			Dec(LinkCount);
			break;
		end;
		PrevNode := TempNode;
		TempNode := TempNode^.Next;
	end;

	AddState(SDirty);
end;

procedure TDesktop.MoveLink(Link: PLink);
var
	IconSize: Word;
	LinkIconImg, BackdropImg: Pointer;
	OffsetX, OffsetY: Integer;
	MinX, MinY, MaxX, MaxY: Integer;
	DrawX, DrawY: integer;
	CurGridX, CurGridY, LastGridX, LastGridY: integer;
	CursorX, CursorY: integer;
	Key: String;
	WasMoved: Boolean;
begin
	if Link = nil then
		Exit;

	{Unless escape is pressed, we assume the link was moved}
	WasMoved := true;

	{Clear current tab selection, link order will likely change after move}
	Self.DoTabAction(TabClear);

	{Get absolute position of desktop to calculate relative mouse position and
	 movement boundaries}
	GetPos(OffsetX, OffsetY, True);
	GetSize(MaxX, MaxY);
	MinX := OffsetX + 20;
	MinY := OffsetY + 20;
	MaxX := OffsetX + MaxX - 20;
	MaxY := OffsetY + MaxY - 20;

	{Calculate initial draw position based on current link position and offset}
	DrawX := Link^.Left + OffsetX;
	DrawY := Link^.Top + OffsetY;
	LastGridX := 0;
	LastGridY := 0;

	Mouse.Hide;
	IconSize := ImageSize(0, 0, 31, 31);
	GetMem(LinkIconImg, IconSize);
	GetMem(BackdropImg, IconSize);
	GetImage(DrawX, DrawY, DrawX + 31, DrawY + 31, LinkIconImg^);
	GetImage(DrawX, DrawY, DrawX + 31, DrawY + 31, BackdropImg^);
	Mouse.Show;

	{Center mouse on icon}
	Mouse.Move(DrawX + 16, DrawY + 16);

	if Mouse.Supported then
	begin
		CursorX := Mouse.X;
		CursorY := Mouse.Y;
	end
	else
	begin
		{Set mouse pos variables manually to make the rest of the code work
		 if no mouse is present}
		CursorX := DrawX + 16;
		CursorY := DrawY + 16;
	end;

	CurGridX := CursorX div LinkGridSize;
	CurGridY := CursorY div LinkGridSize;
	ClearInputBuffer;
	repeat
		Key := GetKey;

		{Escape cancels move}
		if Key = KeyEscape then
		begin
			WasMoved := false;
			break;
		end;

		{Enter confirms move}
		if Key = KeyEnter then
			break;

		CursorX := Mouse.X;
		CursorY := Mouse.Y;

		{Arrow keys - move mouse cursor in direction pressed}
		if Key = KeyLeft then CursorX := CursorX - LinkGridSize;
		if Key = KeyRight then CursorX:= CursorX + LinkGridSize - 1;
		if Key = KeyUp then CursorY := CursorY - LinkGridSize;
		if Key = KeyDown then CursorY := CursorY + LinkGridSize - 1;

		if CursorX < MinX then CursorX:= MinX;
		if CursorX > MaxX then CursorX:= MaxX;
		if CursorY < MinY then CursorY := MinY;
		if CursorY > MaxY then CursorY := MaxY;

		{If icon is moved with arrow keys, set cursor position}
		if Length(Key) = 2 then
			Mouse.Move(CursorX, CursorY);

		{Calculate grid position}
		CurGridX := (CursorX- 16) div LinkGridSize;
		if CurGridX < 0 then
			CurGridX := 0;
		CurGridY := (CursorY - 16) div LinkGridSize;
		if CurGridY < 4 then
			CurGridY := 4;

		if (CurGridX <> LastGridX) or (CurGridY <> LastGridY) then
		begin
			Mouse.Hide;
			{Restore backdrop}
			PutImage(DrawX, DrawY, BackdropImg^, NormalPut);
			DrawX := CurGridX * LinkGridSize;
			DrawY := CurGridY * LinkGridSize;
			if DrawY > 318 then
				DrawY := 318;

			{Save backdrop, plot icon in its place}
			GetImage(DrawX, DrawY, DrawX + 31, DrawY + 31, BackdropImg^);
			PutImage(DrawX, DrawY, LinkIconImg^, NormalPut);
			Mouse.Show;
			LastGridX := CurGridX;
			LastGridY := CurGridY;

			{Reduce flicker}
			{Delay(10);} {DEBUG}
			while (Port[$3DA] and 8) = 0 do;
		end;

	until (Mouse.Clicked = MbLeft) and Self.IsMouseOver;

	if WasMoved then
	begin
		Link^.Left := DrawX - OffsetX;
		Link^.Top := DrawY - OffsetY;
		Self.SortLinks;
		AddState(SDirty);
	end
	else
	begin
		{Restore original position visually - no need to redraw entire desktop}
		Mouse.Hide;
		PutImage(DrawX, DrawY, BackdropImg^, NormalPut);
		PutImage(Link^.Left + OffsetX, Link^.Top + OffsetY, LinkIconImg^, NormalPut);
		Mouse.Show;
	end;

	{Free allocated memory}
	FreeMem(LinkIconImg, IconSize);
	FreeMem(BackdropImg, IconSize);
	ClearInputBuffer;
end;

procedure TDesktop.ClearLinks;
var
	TempNode: PLinkNode;
begin
	{Remove tab indicator if visible}
	DoTabAction(TabClear);

	{Dispose all link nodes and their data}
	while Links <> nil do
	begin
		TempNode := Links;
		Links := Links^.Next;
		if Assigned(TempNode^.Link) then
			Dispose(TempNode^.Link);
		Dispose(TempNode);
	end;
	LinkCount := 0;

	{Redraw immediately, in case we are called for LoadLinks which
	 will start drawing links on top directly after clear}
	Mouse.Hide;
	Self.Draw;
	Mouse.Show;
end;

procedure TDesktop.SetDisplay(Captions, Targets: boolean);
begin
	ShowCaption := Captions;
	ShowTarget := Targets;
	Self.AddState(SDirty);
end;

function TDesktop.LoadLinks(Filename: string): boolean;
var
	F: file;
	ReadLink: TLink;
	ReadBytes: Word;
begin
	LoadLinks := false;
	DoTabAction(TabClear);

	{Make sure Links is empty before loading new links - ClearLinks also
	 draws the desktop to remove any existing links visually}
	Self.ClearLinks;
	SelectedLink := nil;

	{If file doesn't exist, do nothing}
	if not FileExists(Filename) then
		exit;

	Assign(F, Filename);
	{$I-}
	Reset(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		{File could not be opened}
		Close(F);
		Exit;
	end;

	{Read links from file until EOF}
	while not EOF(F) do
	begin
		{Clear record to avoid garbage data, and load from file}
		FillChar(ReadLink, SizeOf(ReadLink), 0);
		BlockRead(F, ReadLink, SizeOf(ReadLink), ReadBytes);
		{If size of read data matches link record size, add it to desktop}
		if ReadBytes = SizeOf(ReadLink) then
			Self.AddLink(@ReadLink)
		else
		begin
			{If size doesn't matter, the file is corrupted - clear any loaded links and exit}
			Close(F);
			Self.ClearLinks;
			Exit;
		end;
	end;

	Close(F);

	{Make sure links are sorted by position after loading, to enable tab navigation}
	Self.SortLinks;
	LoadLinks := true;

	{We don't need to redraw here, as AddLink already draws each link}
end;

function TDesktop.SaveLinks(Filename: string): boolean;
var
	TempNode: PLinkNode;
	F: file;
begin
	SaveLinks := false;

	Assign(F, Filename);
	{$I-}
	Rewrite(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		Close(F);
		Exit;
	end;

	{No links, close file to leave it empty}
	if not Assigned(Links) then
	begin
		Close(F);
		SaveLinks := true;
		Exit;
	end;

	{Write all links to file}
	TempNode := Links;
	while Assigned(TempNode) do
	begin
		BlockWrite(F, TempNode^.Link^, SizeOf(TLink));
		TempNode := TempNode^.Next;
	end;

	Close(F);
	SaveLinks := true;
end;

function TDesktop.GetActiveLink: PLink;
begin
	GetActiveLink := SelectedLink;
end;

procedure TDesktop.SetOnRightClick(Proc: TEventProc);
begin
	OnRightClick := Proc;
end;

procedure TDesktop.DoTabAction(Action: TTabAction);
var
	TempNode, PrevNode: PLinkNode;

	{Helper procedure to hide the tab indicator if visible}
	procedure HideTabIndicator;
	var
		x1, y1: Integer;
	begin
		if not TabVisible or not Assigned(SelectedLink) then
			exit;

		{Restore saved background}
		if Assigned(TabBgImg) then
		begin
			Mouse.Hide;
			{Get absolute position of desktop, and set icon position relative to it}
			GetPos(x1, y1, True);
			Inc(x1, SelectedLink^.Left);
			Inc(y1, SelectedLink^.Top);
			PutImage(x1 - 3, y1 - 3, TabBgImg^, NormalPut);
			Mouse.Show;
		end;
		TabVisible := false;
	end;

	{Helper procedure to draw the tab indicator at SelectedLink}
	procedure DrawTabIndicator;
	var
		x1, y1, x2, y2: Integer;
	begin
		if not Assigned(SelectedLink) then
			exit;

		Mouse.Hide;
		{Get absolute position of desktop, and set icon position relative to it}
		GetPos(x1, y1, True);
		Inc(x1, SelectedLink^.Left);
		Inc(y1, SelectedLink^.Top);
		x1 := x1 - 3;
		y1 := y1 - 3;
		x2 := x1 + 37;
		y2 := y1 + 37;
		GetImage(x1, y1, x2, y2, TabBgImg^);

		SetFillStyle(SolidFill, Thm.Btn);
		Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);

		{Top + left outer border}
		SetColor(White);
		Line(X1, Y1, X2, Y1);
		Line(X1, Y1 + 1, X1, Y2);
		{Inner border}
		SetColor(Thm.Shadow);
		Line(X1 + 1, Y1 + 1, X2 - 1, Y1 + 1);
		Line (X1 + 1, Y1 + 2, X1 + 1, Y2 - 1);

		{Bottom + right outer border}
		SetColor(Black);
		Line(X2, Y1 + 1, X2, Y2);
		Line(X1 + 1, Y2, X2 - 1, Y2);
		{Inner border}
		SetColor(Thm.Light);
		Line(X2 - 1, Y1 + 2, X2 - 1, Y2 - 1);
		Line(X1 + 2, Y2 - 1, X2 - 2, Y2 - 1);

		DrawLink(SelectedLink);

		Mouse.Show;

		TabVisible := true;
	end;

begin
	if Action = TabClear then
	begin
		HideTabIndicator;
		SelectedLink := nil;
	end;

	if Action = TabHide then
		HideTabIndicator;

	If (LinkCount = 0) or not Assigned(Links) then
		Exit; {No links to select}

	if Action in [TabMoveNext, TabMovePrev] then
	begin
		{If no link is currently selected, select the first link}
		if not Assigned(SelectedLink) then
		begin
			SelectedLink := Links^.Link;
			DrawTabIndicator;
			Exit;
		end
		else
			if LinkCount = 1 then
				Exit; {Only one link, nothing to cycle through}
	end;

	{Hide current tab indicator before moving to next/previous link}
	HideTabIndicator;

	if Action = TabMoveNext then
	begin
		{Find the next link in the list after the currently selected one}
		TempNode := Links;
		while Assigned(TempNode) do
		begin
			if TempNode^.Link = SelectedLink then
			begin
				{Found current link, move to next if possible}
				if Assigned(TempNode^.Next) then
					SelectedLink := TempNode^.Next^.Link
				else
					SelectedLink := Links^.Link; {Wrap around to first link}

				break;
			end;
			TempNode := TempNode^.Next;
		end;

	end;

	if Action = TabMovePrev then
	begin
		{Find the previous link in the list before the currently selected one}
		TempNode := Links;
		PrevNode := nil;
		while Assigned(TempNode) do
		begin
			if TempNode^.Link = SelectedLink then
			begin
				{Found current link, move to previous if possible}
				if Assigned(PrevNode) then
					SelectedLink := PrevNode^.Link
				else
				begin
					{If no previous node, find the last node so that we wrap around}
					while Assigned(TempNode^.Next) do
						TempNode := TempNode^.Next;
					SelectedLink := TempNode^.Link;
				end;
				break;
			end;
			PrevNode := TempNode;
			TempNode := TempNode^.Next;
		end;
	end;

	{Draw tab indicator at new selected link}
	DrawTabIndicator;
end;

{Sorts the links in the Links linked list by position on screen, from top left
 to bottom right. This is used to enable cycling through links with the TAB key,
 without having to iterate through the entire list to find the next link.}
procedure TDesktop.SortLinks;
var
	Sorted: Boolean;
	CurrentNode, NextNode, PrevNode: PLinkNode;
begin
	if not Assigned(Links) then
		Exit;

	DoTabAction(TabClear);

	{Itererate through Links until no swaps are made}
	repeat
		Sorted := true;
		CurrentNode := Links;
		PrevNode := nil;

		while Assigned(CurrentNode) and Assigned(CurrentNode^.Next) do
		begin
			NextNode := CurrentNode^.Next;

			{If the current node is further to the left than the next node, swap them. If they are at the same left position,
			 swap them if the next node is further down}
			if (CurrentNode^.Link^.Left > NextNode^.Link^.Left) or
			   ((CurrentNode^.Link^.Left = NextNode^.Link^.Left) and
			    (CurrentNode^.Link^.Top > NextNode^.Link^.Top)) then
			begin
				{Swap the two nodes in the Links linked list}

				{If PrevNode is nil, we are swapping the head node}
				if not Assigned(PrevNode) then
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
	until Sorted; {Continue until no swaps are made}
end;

end.