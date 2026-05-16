unit UIIcoAre;

{Icon area - displays icons in an area, and allows for adding/removing/modifying icons.
 Only icon and caption are implemented, other properties must be handled by the application.
 When adding icons, an ID will be returned. The application can use this ID to reference
 the icon later for modification or removal.}

interface

uses
	CostaLib, UIIcon, DOS, Graph;

const
	IconGridSize  = 4;   {Icons are moved in increments of this size to help ease
	                      alignment}
	MaxIconCount  = 100; {Maximum number of icons allowed}
	MaxIconCapt   = 20;  {Maximum length for icon captions}

type
	{Actions that can be triggered on the tab keyboard indicator}
	TTabAction = (TabClear, TabHide, TabMoveNext, TabMovePrev);

	{linked list node for Icons}
	PIconNode = ^TIconNode;
	TIconNode = record
		Caption:  String[MaxIconCapt]; {Caption of the icon}
		IconFile: String[8];           {8 char filename w/o extension}
		Left,
		Top: Integer;                  {Position of the icon within the icon area}
		ID:       Byte;                {ID of the icon}
		Next:     PIconNode;           {Pointer to the next icon in the area}
	end;

	PIconArea  = ^TIconArea;
	TIconArea  = object(TContainer)
		public
			constructor  Init(X, Y: Integer; Parent: PContainer);
			destructor   Done; virtual;
			procedure    Draw; virtual;
			procedure    CheckEvent; virtual;

			function     AddIcon(Caption, IconFile: String): Byte;
			procedure    RemoveIcon(IconID: Byte);
			procedure    MoveIcon(IconID: Byte);
			procedure    ClearIcons;

			function     GetActiveIcon: Byte;

			procedure    SetMoveable(Movable: Boolean);
			function     GetMoveable: Boolean;

			procedure    SetOnRightClick(Proc: TEventProc);
		private
			Icons:        PIconNode;   {Head of the linked list of icons}
			IconCount:    Byte;        {Number of icons on the icon area}
			SelectedIcon: Byte;        {Currently selected icon, if any}
			IconMoveable,              {Whether icons can be moved by the user}
			TabVisible:   Boolean;     {Whether the keyboard tab indicator is visible}
			TabBgImg:     Pointer;     {Saved background image for tab indicator}
			TabBgSize:    Word;        {Memory size of the saved background image for tab indicator}
			OnRightClick: TEventProc;  {Event to trigger on icon right click - inherited OnClick is used for left click}

			procedure     DrawIcon(Icon: PIconNode);
			procedure     DoTabAction(Action: TTabAction);
			procedure     SortIcons;   {Sort icons alphabetically by caption}
	end;

implementation

constructor TIconArea.Init(X, Y: Integer; Parent: PContainer);
begin
	inherited Init(X, Y, Parent);
	Icons        := nil;
	IconCount    := 0;
	SelectedIcon := nil;
	IconMoveable := false;
	TabVisible   := false;
	TabBgSize    := ImageSize(0, 0, 37, 37); {Size of 34x34 tab indicator + 3px border}
	OnRightClick := nil;

	{Allocate memory for tab background image}
	GetMem(TabBgImg, TabBgSize);
end;

destructor TIconArea.Done;
begin
	Self.ClearIcons;
	FreeMem(TabBgImg, TabBgSize);
	inherited Done;
end;

procedure TIconArea.Draw;
var
	x1, y1, x2, y2: Integer;
	TempNode: PIconNode;
	BgColor: byte;
begin
	{Get absolute position and size}
	Self.GetPos(x1, y1, True);
	Self.GetSize(x2, y2);
	Inc(X2, X1);
	Inc(Y2, Y1);

	{Draw background}
	BgColor := GetBgColor;
	if BgColor = ColorDefault then
		BgColor := Thm.Txt;

	SetFillStyle(SolidFill, BgColor);
	Bar(X1, Y1, X2, Y2);

	{If OnDraw event assigned, call it before drawing Icons (none of parent objects
	 draw anything, but we call inherited Draw to maintain proper structure)}
	Inherited Draw;

	{Draw Icons}
	TempNode := Icons;
	while TempNode <> nil do
	begin
		DrawIcon(TempNode);
		TempNode := TempNode^.Next;
	end;
end;

procedure TIconArea.DrawIcon(Icon: PIconNode);
var
	ImgIcon: PIcon;
	X, Y: Integer;
	Color: byte;
begin
	if Icon = nil then
		Exit;

	{Get absolute position of icon area, and set icon position relative to it}
	GetPos(X, Y, True);
	Inc(X, Icon^.Left);
	Inc(Y, Icon^.Top);

	Color := GetFgColor;
	if Color = ColorDefault then
		Color := Thm.DeskText;

	New(ImgIcon, Init(X, Y, Icon^.IconFile, nil));
	ImgIcon^.Draw;
	Dispose(ImgIcon);

	{If caption display is enabled, draw it to the right of the icon - also
	 display the target filename if that setting is enabled}
	if Setting.LinkCapt then
		Print(Icon^.Caption, X + 38, Y + 4, Color);
end;

procedure TIconArea.CheckEvent;
var
	TempNode: PIconNode;
	OffsetX, OffsetY: integer;
	X1, Y1, X2, Y2: Integer;
	MouseButton: TMouseButton;
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
		Mouse.Poll;

		{Mouse was clicked, so hide keyboard tab indicator and clear SelectedItem}
		DoTabAction(TabClear);

		{Get absolute position of icon area and calculate substract it from mouse position,
		 giving us the realtive position on the icon area which can be compared against Icons}
		GetPos(OffsetX, OffsetY, True);
		OffsetX := Mouse.X - OffSetX;
		OffsetY := Mouse.Y - OffSetY;

		{Iterate through Icons to see if one was clicked}
		TempNode := Icons;
		while TempNode <> nil do
		begin
			{Get coordinates of the icon area (34x34 pixels since there is a 1px border
			 around the 32x32 icon that should also be clicckable)}
			X1 := TempNode^..Left - 1;
			Y1 := TempNode^..Top - 1;
			X2 := X1 + 33;
			Y2 := Y1 + 33;
			if (OffsetX >= X1) and (OffsetX <= X2) and
			   (OffsetY >= Y1) and (OffsetY <= Y2) then
			begin
				{icon was clicked, set it as active icon}
				SelectedIcon := TempNode^.ID;
				break;
			end;
			{Not clicked, check next icon}
			TempNode := TempNode^.Next;
		end;

		{Trigger click or right-click event - if a icon was clicked, SelectedIcon
		 will be set to it, otherwise it will be nil. Application can check that
		 using GetActiveIcon}
		case MouseButton of
			MbLeft:
				Self.Click;
			MbRight:
				if Assigned(OnRightClick) then
					OnRightClick(@Self);
		end;

		repeat; until Mouse.Clicked = MbNone;
	end;

	{Check for keyboard input}
	if Length(HotkeyInput) = 0 then
		exit;

	{KeyPressed tracks whether any relevant key was pressed, to clear HotkeyInput later
	 so other objects won't catch it and to trigger OnClick event}
	KeyPressed := false;

	{Tab/Shift+Tab to cycle through Icons}
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
	if (HotkeyInput = KeyEnter) and Assigned(SelectedIcon) then
	begin
		KeyPressed := true;
		if Assigned(SelectedIcon) then
			Self.Click;
	end;

	{If a key was pressed, clear it so other objects won't catch it}
	if KeyPressed then
		HotkeyInput := '';
end;

{Adds a new icon to the icon area. The icon data is copied into a new node
 in the linked list, so it's up to the caller to dispose of the original icon data
 if needed and the pointer passed cannot be used to reference the icon later}
function TIconArea.AddIcon(Caption, IconFile: String): Byte;
var
	NewNode: PIconNode;
begin
	if IconCount >= MaxIconCount then
		Exit; {Maximum icon count reached}

	{Hide selection tab if visible as icon order may change now}
	DoTabAction(TabClear);
	SelectedIcon := nil;

	{Copy icon data into new node, set its next pointer to current head,
	 and update head pointer to new node}
	New(NewNode);
	NewNode^.ID := IconCount + 1; {IDs start at 1} {DEBUG - this could lead to ID reuse if icons are removed}
	NewNode^.Caption := Caption;
	NewNode^.IconFile := IconFile;
	NewNode^.Next := Icons;
	Icons := NewNode;

	{Draw the new icon on the icon area}
	Mouse.Hide;
	DrawIcon(NewNode);
	Mouse.Show;

	{Increment icon count so we can track if we reach the maximum}
	Inc(IconCount);

	Self.SortIcons;
end;

procedure TIconArea.RemoveIcon(IconID: Byte);
var
	TempNode, PrevNode: PIconNode;
begin
	if Icons = nil then
		Exit; {No Icons to remove}

	{Hide selection tab if visible as icon order may change now}
	DoTabAction(TabClear);

	TempNode := Icons;
	PrevNode := nil;
	while TempNode <> nil do
	begin
		if TempNode^.ID = IconID then
		begin
			{Found the icon to remove}
			if PrevNode = nil then
			begin
				{Removing head node}
				Icons := TempNode^.Next;
			end
			else
			begin
				{Bypass the node to remove it}
				PrevNode^.Next := TempNode^.Next;
			end;

			Dispose(TempNode);

			Dec(IconCount);
			break;
		end;
		PrevNode := TempNode;
		TempNode := TempNode^.Next;
	end;

	Mouse.Hide;
	Self.Draw; {Redraw entire icon area to remove the icon visually}
	Mouse.Show;
end;

procedure TIconArea.ClearIcons;
var
	TempNode: PIconNode;
begin
	{Remove tab indicator if visible}
	DoTabAction(TabClear);

	{Dispose all icon nodes and their data}
	while Icons <> nil do
	begin
		TempNode := Icons;
		Icons := Icons^.Next;
		Dispose(TempNode);
	end;
	IconCount := 0;

	Mouse.Hide;
	Self.Draw; {Redraw icon area to clear all Icons visually}
	Mouse.Show;
end;

function TIconArea.GetActiveIcon: Byte;
begin
	GetActiveIcon := SelectedIcon;
end;

procedure TIconArea.SetOnRightClick(Proc: TEventProc);
begin
	OnRightClick := Proc;
end;

procedure TIconArea.DoTabAction(Action: TTabAction);
var
	TempNode, PrevNode: PIconNode;

	{Helper procedure to hide the tab indicator if visible}
	procedure HideTabIndicator;
	begin
		if not TabVisible or not Assigned(SelectedIcon) then
			exit;

		{Restore saved background}
		Mouse.Hide;
		if Assigned(TabBgImg) then
			PutImage(SelectedIcon^.Left - 3, SelectedIcon^.Top - 3, TabBgImg^, NormalPut);
		Mouse.Show;
		TabVisible := false;
	end;

	{Helper procedure to draw the tab indicator at SelectedIcon}
	procedure DrawTabIndicator;
	begin
		if not Assigned(SelectedIcon) then
			exit;

		Mouse.Hide;
		GetImage(SelectedIcon^.Left - 3, SelectedIcon^.Top - 3, SelectedIcon^.Left + 34, SelectedIcon^.Top + 34, TabBgImg^);
		Mouse.Show;

		TabVisible := true;
	end;

begin
	if Action = TabClear then
	begin
		HideTabIndicator;
		SelectedIcon := nil;
	end;

	if Action = TabHide then
		HideTabIndicator;

	If (IconCount = 0) or not Assigned(Icons) then
		Exit; {No Icons to select}

	if Action in [TabMoveNext, TabMovePrev] then
	begin
		{If no icon is currently selected, select the first icon}
		if not Assigned(SelectedIcon) then
		begin
			SelectedIcon := Icons^.icon;
			DrawTabIndicator;
			Exit;
		end
		else
			if IconCount = 1 then
				Exit; {Only one icon, nothing to cycle through}
	end;

	{Hide current tab indicator before moving to next/previous icon}
	HideTabIndicator;

	if Action = TabMoveNext then
	begin
		{Find the next icon in the list after the currently selected one}
		TempNode := Icons;
		while Assigned(TempNode) do
		begin
			if TempNode^.ID = SelectedIcon then
			begin
				{Found current icon, move to next if possible}
				if Assigned(TempNode^.Next) then
					SelectedIcon := TempNode^.Next^.ID
				else
					SelectedIcon := Icons^.ID; {Wrap around to first icon}

				break;
			end;
			TempNode := TempNode^.Next;
		end;

	end;

	if Action = TabMovePrev then
	begin
		{Find the previous icon in the list before the currently selected one}
		TempNode := Icons;
		PrevNode := nil;
		while Assigned(TempNode) do
		begin
			if TempNode^.ID = SelectedIcon then
			begin
				{Found current icon, move to previous if possible}
				if Assigned(PrevNode) then
					SelectedIcon := PrevNode^.ID
				else
				begin
					{If no previous node, find the last node so that we wrap around}
					while Assigned(TempNode^.Next) do
						TempNode := TempNode^.Next;
					SelectedIcon := TempNode^.ID;
				end;
				break;
			end;
			PrevNode := TempNode;
			TempNode := TempNode^.Next;
		end;
	end;

	{Draw tab indicator at new selected icon}
	DrawTabIndicator;
end;

{Sorts the Icons in the Icons linked list by position on screen, from top left
 to bottom right. This is used to enable cycling through Icons with the TAB key,
 without having to iterate through the entire list to find the next icon.}
procedure TIconArea.SortIcons;
var
	Sorted: Boolean;
	CurrentNode, NextNode, PrevNode: PIconNode;
begin
	if not Assigned(Icons) then
		Exit;

	DoTabAction(TabClear);

	{Itererate through Icons until no swaps are made}
	repeat
		Sorted := true;
		CurrentNode := Icons;
		PrevNode := nil;

		while Assigned(CurrentNode) and Assigned(CurrentNode^.Next) do
		begin
			NextNode := CurrentNode^.Next;

			{If the current node is further to the left than the next node, swap them. If they are at the same left position,
			 swap them if the next node is further down}
			if (CurrentNode^.Left > NextNode^.Left) or
			   ((CurrentNode^.Left = NextNode^.Left) and
			    (CurrentNode^.Top > NextNode^.Top)) then
			begin
				{Swap the two nodes in the Icons linked list}

				{If PrevNode is nil, we are swapping the head node}
				if not Assigned(PrevNode) then
					Icons := NextNode
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

procedure TIconArea.MoveIcon(IconID: Byte);
var
	IconSize: Word;
	IconImgP, BackdropImgP: Pointer;
	OffsetX, OffsetY: Integer;
	MinX, MinY, MaxX, MaxY: Integer;
	DrawX, DrawY: integer;
	CurGridX, CurGridY, LastGridX, LastGridY: integer;
	CursorX, CursorY: integer;
	Key: String;
	WasMoved: Boolean;
begin
	if icon = nil then
		Exit;

	{Unless escape is pressed, we assume the icon was moved}
	WasMoved := true;

	{Clear current tab selection, icon order will likely change after move}
	Self.DoTabAction(TabClear);

	{Get absolute position of desktop to calculate relative mouse position and
	 movement boundaries}
	GetPos(OffsetX, OffsetY, True);
	GetSize(MaxX, MaxY);
	MinX := OffsetX + 20;
	MinY := OffsetY + 20;
	MaxX := OffsetX + MaxX - 20;
	MaxY := OffsetY + MaxY - 20;

	{Calculate initial draw position based on current icon position and offset}
	DrawX := icon^.Left + OffsetX;
	DrawY := icon^.Top + OffsetY;
	LastGridX := 0;
	LastGridY := 0;

	Mouse.Hide;
	IconSize := ImageSize(0, 0, 31, 31);
	GetMem(IconImgP, IconSize);
	GetMem(BackdropImgP, IconSize);
	GetImage(DrawX, DrawY, DrawX + 31, DrawY + 31, IconImgP^);
	GetImage(DrawX, DrawY, DrawX + 31, DrawY + 31, BackdropImgP^);
	Mouse.Show;

	{Center mouse on icon}
	Mouse.Move(DrawX + 16, DrawY + 16);

	if Mouse.Supported then
	begin
		Mouse.Poll;
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

	CurGridX := CursorX div iconGridSize;
	CurGridY := CursorY div iconGridSize;
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

		Mouse.Poll;
		CursorX := Mouse.X;
		CursorY := Mouse.Y;

		{Arrow keys - move mouse cursor in direction pressed}
		if Key = KeyLeft then CursorX := CursorX - iconGridSize;
		if Key = KeyRight then CursorX:= CursorX + iconGridSize - 1;
		if Key = KeyUp then CursorY := CursorY - iconGridSize;
		if Key = KeyDown then CursorY := CursorY + iconGridSize - 1;

		if CursorX < MinX then CursorX:= MinX;
		if CursorX > MaxX then CursorX:= MaxX;
		if CursorY < MinY then CursorY := MinY;
		if CursorY > MaxY then CursorY := MaxY;

		{If icon is moved with arrow keys, set cursor position}
		if Length(Key) = 2 then
			Mouse.Move(CursorX, CursorY);

		{Calculate grid position}
		CurGridX := (CursorX- 16) div iconGridSize;
		if CurGridX < 0 then
			CurGridX := 0;
		CurGridY := (CursorY - 16) div iconGridSize;
		if CurGridY < 4 then
			CurGridY := 4;

		if (CurGridX <> LastGridX) or (CurGridY <> LastGridY) then
		begin
			Mouse.Hide;
			{Restore backdrop}
			PutImage(DrawX, DrawY, BackdropImgP^, NormalPut);
			DrawX := CurGridX * iconGridSize;
			DrawY := CurGridY * iconGridSize;
			if DrawY > 318 then
				DrawY := 318;

			{Save backdrop, plot icon in its place}
			GetImage(DrawX, DrawY, DrawX + 31, DrawY + 31, BackdropImgP^);
			PutImage(DrawX, DrawY, IconImgP^, NormalPut);
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
		icon^.Left := DrawX - OffsetX;
		icon^.Top := DrawY - OffsetY;
		Self.Sorticons;
		Mouse.Hide;
		Self.Draw;
		Mouse.Show;
	end
	else
	begin
		{Restore original position visually - no need to redraw entire desktop}
		Mouse.Hide;
		PutImage(DrawX, DrawY, BackdropImgP^, NormalPut);
		PutImage(icon^.Left + OffsetX, icon^.Top + OffsetY, IconImgP^, NormalPut);
		Mouse.Show;
	end;

	{Free allocated memory}
	FreeMem(IconImgP, IconSize);
	FreeMem(BackdropImgP, IconSize);
	ClearInputBuffer;
end;

end.