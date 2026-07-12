{----------------------------------------------------------------------------}
{ Base UI object implementation }
{----------------------------------------------------------------------------}

constructor TUIObject.Init;
begin
	Left        := 0;
	Top         := 0;
	Width       := 0;
	Height      := 0;
	FgColor     := Black;
	BgColor     := White;
	State       := [SEnabled, SDirty];
	BorderStyle := BorNone;
	Transparent := false;
	Hotkey      := nil;
	OnClick     := nil;
	OnDraw      := nil;
	ParentObj   := nil;
end;

destructor TUIObject.Done;
var
	NextNode: PHotKeyNode;
begin
	{Free all hotkey nodes in the linked list}
	while Assigned(Hotkey) do
	begin
		NextNode := HotKey^.Next; {Store pointer to next node}
		Dispose(Hotkey);          {Free current node}
		Hotkey := NextNode;       {Move to next node}
	end;

	{If object was visible and has a parent, that parent needs to be redrawn}
	if not (SHidden in State) and (ParentObj <> nil) then
		ParentObj^.AddState(SDirty);
end;

{Check for hotkeys events assigned to the object}
function TUIObject.HotkeyPressed: boolean;
var
	CheckNode: PHotKeyNode;
begin
	HotkeyPressed := False;

	if not (SEnabled in State) or (Length(HotkeyInput) = 0) then
		exit;

	CheckNode := Hotkey;
	while Assigned(CheckNode) do
	begin
		if CheckNode^.HotKey = HotkeyInput then
		begin
			HotkeyInput := ''; {Reset hotkey}
			HotkeyPressed := True;
			exit;
		end;
		CheckNode := CheckNode^.Next; {Move to next node in linked list}
	end;
end;

{Check if mouse is over the object}
function TUIObject.IsMouseOver: Boolean;
var
	X1, Y1, X2, Y2: Integer;
begin
	{Get absolute position and size of the object}
	Self.GetAbsPos(X1, Y1);
	X2 := X1 + Self.Width;
	Y2 := Y1 + Self.Height;

	IsMouseOver := (Mouse.X >= X1) and (Mouse.X <= X2) and (Mouse.Y >= Y1) and (Mouse.Y <= Y2);
end;

{Add a hotkey to an object - a linked list is used to allow multiple hotkeys}
procedure TUIObject.AddHotkey(Key: string);
var
	CheckNode, NewNode: PHotKeyNode;
begin
	if (Length(Key) < 1) or (Length(Key) > 2) then
		exit; {Invalid hotkey, do nothing}

	New(NewNode);
	NewNode^.HotKey := Key;
	NewNode^.Next := Self.Hotkey;
	Self.Hotkey := NewNode;
end;

function TUIObject.GetHotkey: PHotkeyNode;
begin
	GetHotkey := Hotkey;
end;

procedure TUIObject.RemoveHotkey(Key: string);
var
	PrevNode, CheckNode: PHotKeyNode;
begin
	if not Assigned(Hotkey) then
		exit; {No hotkeys assigned}

	CheckNode := Hotkey;
	PrevNode := nil;

	{Check if the first node is the one to remove}
	if Hotkey^.HotKey = Key then
	begin
		CheckNode := Hotkey;
		Hotkey := Hotkey^.Next;
		Dispose(CheckNode);
		exit;
	end;

	{Search the linked list for the key to remove}
	while Assigned(CheckNode) do
	begin
		if CheckNode^.HotKey = Key then
		begin
			PrevNode^.Next := CheckNode^.Next;
			Dispose(CheckNode);
			exit;
		end;
		PrevNode := CheckNode;
		CheckNode := CheckNode^.Next;
	end;
end;

procedure TUIObject.AddState(S: TState);
begin
	{Do nothing is state is already there}
	if S in State then
		exit;

	Include(State, S);

	{Any state change should trigger redraw}
	Include(State, SDirty);

	{If state added is SHidden, parent must be redrawn to hide the object}
	if (s = SHidden) and (ParentObj <> nil) then
		ParentObj^.AddState(SDirty);
end;


procedure TUIObject.RemoveState(S: TState);
begin
	{Do nothing if state not present}
	if not (S in State) then
		exit;

	Exclude(State, S);

	{State change should trigger redraw - unless of course SDirty is being cleared because of redraw}
	if s <> SDirty then
		Include(State, SDirty);
end;

procedure TUIObject.SetTransparent(T: Boolean);
begin
	if Self.Transparent = T then Exit;

	Self.Transparent := T;
	Include(Self.State, SDirty);
end;

function TUIObject.GetBorderWidth: Word;
begin
	case Self.BorderStyle of
		BorNone:         GetBorderWidth := 0;
		Bor3D,
		Bor3DSunken,
		BorFrame,
		BorHorSeparator,
		BorVerSeparator: GetBorderWidth := 2;
		BorDialog:       GetBorderWidth := 6;
	end;
end;

{Used for drawing objects, in order to reduce redundant drawing code and to ensure similarity of objects}
procedure TUIObject.DrawBorder;
var
	TopLeftOuterCol, TopLeftInnerCol, BottomRightOuterCol, BottomRightInnerCol: Byte;
	X1, Y1, X2, Y2, BorderWidth: Integer;
begin
	if SHidden in Self.State then
		exit;

	BorderWidth := Self.GetBorderWidth;
	Self.GetAbsPos(X1, Y1);
	X2 := X1 + Self.Width;
	Y2 := Y1 + Self.Height;

	{Interior}
	If Not Self.Transparent Then
	begin
		SetFillStyle(SolidFill, BgColor);
		Bar(X1 + BorderWidth, Y1 + BorderWidth, X2 - BorderWidth, Y2 - BorderWidth);
	end;

	if Self.BorderStyle = BorNone then
		exit;

	if (Self.BorderStyle = Bor3D) or (Self.BorderStyle = Bor3DSunken) then
	begin
		{Invert border colors if pressed down}
		if Self.BorderStyle = Bor3D then
		begin
			{Border is raised}
			TopLeftOuterCol := White;
			TopLeftInnerCol := Thm.Light;
			BottomRightOuterCol := Black;
			BottomRightInnerCol := Thm.Shadow;
		end
		else
		begin
			{Border is sunken}
			TopLeftOuterCol := Black;
			TopLeftInnerCol := Thm.Shadow;
			BottomRightOuterCol := White;
			BottomRightInnerCol := Thm.Light;
		end;

		{Top + left outer border}
		SetColor(TopLeftOuterCol);
		Line(X1, Y1, X2, Y1);
		Line(X1, Y1 + 1, X1, Y2);
		{Inner border}
		SetColor(TopLeftInnerCol);
		Line(X1 + 1, Y1 + 1, X2 - 1, Y1 + 1);
		Line (X1 + 1, Y1 + 2, X1 + 1, Y2 - 1);

		{Bottom + right outer border}
		SetColor(BottomRightOuterCol);
		Line(X2, Y1 + 1, X2, Y2);
		Line(X1 + 1, Y2, X2 - 1, Y2);
		{Inner border}
		SetColor(BottomRightInnerCol);
		Line(X2 - 1, Y1 + 2, X2 - 1, Y2 - 1);
		Line(X1 + 2, Y2 - 1, X2 - 2, Y2 - 1);
		Exit;
	end;

	if Self.BorderStyle = BorFrame then
	begin
		SetColor(White);
		Rectangle(X1 + 1, Y1 + 1, X2, Y2);
		SetColor(Thm.Shadow);
		Rectangle(X1, Y1, X2 - 1, Y2 - 1);
		PutPixel(X1, Y2, White); {Put missing pixel in bottom-left and top-right corners}
		PutPixel(X2, Y1, White);
		Exit;
	end;

	if Self.BorderStyle = BorDialog then
	begin
		{DEBUG - same areas drawn over multiple times, transparency is ignored}
		SetFillStyle(SolidFill, Thm.Title);
		Bar(X1 + 2, Y1 + 2, X2 - 2, Y2 - 1);
		SetFillStyle(SolidFill, BgColor);
		Bar(X1 + 7, Y1 + 7, X2 - 7, Y2 - 7);
		SetColor(White);
		Line(X1, Y1, X2 - 1, Y1);
		Line(X1, Y1 + 1, X1, Y2 - 1);
		SetColor(Black);
		Line(X2, Y1, X2, Y2);
		Line(X1, Y2, X2 - 1, Y2);
		SetColor(Thm.Shadow);
		Line(X2 - 1, Y1 + 1, X2 - 1, Y2 - 1);
		Line(X1 + 1, Y2 - 1, X2 - 2, Y2 - 1);
		SetColor(Thm.Light);
		Line(X1 + 1, Y1 + 1, X2 - 2, Y1 + 1);
		Line(X1 + 1, Y1 + 2, X1 + 1, Y2 - 2);
		SetColor(Thm.Shadow);
		Rectangle(X1 + 5, Y1 + 5, X2 - 5, Y2 - 5);
		SetColor(Thm.Light);
		Rectangle(X1 + 6, Y1 + 6, X2 - 6, Y2 - 6);
		Exit;
	end;

	if Self.BorderStyle = BorHorSeparator then
	begin
		SetColor(Thm.Shadow);
		Line(X1, Y1, X2, Y1);
		SetColor(White);
		Line(X1, Y1 + 1, X2, Y1 + 1);
		Exit;
	end;

	if Self.BorderStyle = BorVerSeparator then
	begin
		SetColor(Thm.Shadow);
		Line(X1, Y1, X1, Y2);
		SetColor(White);
		Line(X1 + 1, Y1, X1 + 1, Y2);
		Exit;
	end;
end;

procedure TUIObject.SetBorderStyle(Style: TBorderStyle);
begin
	Self.BorderStyle := Style;
	Include(State, SDirty);
end;

{Check for events on object}
procedure TUIObject.CheckEvent;
var
	Clicked: boolean;
begin
	{Don't check for events if object is disabled or hidden}
	if not (SEnabled in State) or (SHidden in State) then
		exit;

	Clicked := False;
	{Check if mouse is clicked on the object}
	if (Mouse.Clicked = MbLeft) and Self.IsMouseOver then
	begin
		repeat;	until Mouse.Clicked = MbNone;
		{Check if mouse is still over the object after release}
		if Self.IsMouseOver then
			Clicked := True;
	end;

	if Clicked or Self.HotkeyPressed then
		{Trigger OnClick event, if assigned}
		Self.Click;
end;

{Descendants can call this method to trigger OnClick event}
procedure TUIObject.Click;
begin
	if Assigned(OnClick) then
		OnClick(@Self);
end;

{Descandants should implement their own versions with drawing code, but should call
 this version at the end to clear SDirty and trigger any custom drawing code assigned
 to OnDraw}
procedure TUIObject.Draw;
begin
	{Don't draw or trigger event if object is hidden}
	if SHidden in State then
		exit;

	Exclude(State, SDirty);

	if Assigned(OnDraw) then
		OnDraw(@Self);
end;

procedure TUIObject.Move(X, Y: Integer);
begin
	Left := X;
	Top := Y;
	Include(State, SDirty);

	{If the object is currently visible, the parent will need to be redrawn to erase the
	 object, otherwise the object would show twice when it is redrawn in new position}
	if not (SHidden in State) and (ParentObj <> nil) then
		ParentObj^.AddState(SDirty);
end;

procedure TUIObject.GetAbsPos(var X, Y: Integer);
var
	RelX, RelY: Integer;
	BorderWidth: Word;
begin
	X := Left;
	Y := Top;

	if Assigned(ParentObj) then
	begin
		ParentObj^.GetAbsPos(RelX, RelY);
		BorderWidth := ParentObj^.GetBorderWidth;
		X := X + RelX + BorderWidth;
		Y := Y + RelY + BorderWidth;
	end;
end;

procedure TUIObject.Center(Orientation: TOrientation);
var
	ParentW, ParentH: Integer;
begin
	if not Assigned(ParentObj) then
	begin
		{If no parent, use full screen dimensions}
		ParentW := ScreenWidth;
		ParentH := ScreenHeight;
	end
	else
	begin
		{Get parent dimensions}
		ParentW := ParentObj^.Width;
		ParentH := ParentObj^.Height;
	end;

	{To center, the size of the object is subtracted from the size of the parent.
	 The remaining space is the additional width the parent has, and dividing this by
	 2 will give the left/top position to center the object. Position is relative to
	 the parent so we don't need to add the parent's position here.}
	if Orientation in [OrHorizontal, OrBoth] then
		Left := (ParentW - Width) div 2;
	if Orientation in [OrVertical, OrBoth] then
		Top := (ParentH - Height) div 2;

	Include(State, SDirty);

	{If the object is currently visible, the parent will need to be redrawn or the object will show twice
	 when it is redrawn in new position}
	if not (SHidden in State) and (ParentObj <> nil) then
		ParentObj^.AddState(SDirty);
end;

procedure TUIObject.SetParent(Parent: PContainer);
begin
	{Debug - test when RemoveObject has been implemented}
	{if Assigned(Parent) then
		Parent^.RemoveObject(@Self);}

	ParentObj := Parent;

	{Add object to its parent, unless Parent passed is nil}
	if Assigned(ParentObj) then
		ParentObj^.AddObject(@Self);
end;


procedure TUIObject.Resize(W, H: Word);
begin
	if W > 0 then Width := W;
	if H > 0 then Height := H;
	Include(State, SDirty);

	{If the object is currently visible, the parent will need to be redrawn or the object will be drawn with new size
	 on top of the previous draw}
	if not (SHidden in State) and (ParentObj <> nil) then
		ParentObj^.AddState(SDirty);
end;

procedure TUIObject.SetFGColor(Color: Byte);
begin
	if (Color < 0) or (Color > MaxColor) then
		exit;

	FgColor := Color;
	Include(State, SDirty);
end;

procedure TUIObject.SetBGColor(Color: Byte);
begin
	if (Color < 0) or (Color > MaxColor) then
		exit;

	BGColor := Color;
	Include(State, SDirty);
end;

{TContainer overrides this function with one that returns true - used in event/draw loops
 to determine if an object can have children, since Turbo Pascal doesn't have a built-in
 way to determine inheritance at runtime}
function TUIObject.IsContainer: boolean;
begin
	IsContainer := false;
end;