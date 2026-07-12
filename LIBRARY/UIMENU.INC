{----------------------------------------------------------------------------}
{ Menu object implementation }
{----------------------------------------------------------------------------}

constructor TMenu.Init(Style: TMenuStyle; Parent: PContainer);
begin
	Inherited Init(0, 0, Parent);
	Width     := 10; {Will be resized when menu items are added or when added to a window}
	Height    := 10;
	MenuStyle := Style;
	FGColor   := Thm.WinText;
	BgColor   := Thm.Win;
end;

procedure TMenu.Draw;
var
	X1, Y1, X2, Y2: Integer;
begin
	{Don't draw or trigger event if menu is hidden}
	if SHidden in State then
		exit;

	if MenuStyle = MsPopup then
	begin
		{Interior}
		SetFillStyle(SolidFill, BgColor);
		Bar(X1 + 2, Y1 + 2, X2 - 2, Y2 - 2);
		{Top + left outer border}
		SetColor(White);
		Line(X1, Y1, X2, Y1);
		Line(X1, Y1 + 1, X1, Y2);
		{Inner border}
		SetColor(Thm.Light);
		Line(X1 + 1, Y1 + 1, X2 - 1, Y1 + 1);
		Line (X1 + 1, Y1 + 2, X1 + 1, Y2 - 1);
		{Bottom + right outer border}
		SetColor(Black);
		Line(X2, Y1 + 1, X2, Y2);
		Line(X1 + 1, Y2, X2 - 1, Y2);
		{Inner border}
		SetColor(Thm.Shadow);
		Line(X2 - 1, Y1 + 2, X2 - 1, Y2 - 1);
		Line(X1 + 2, Y2 - 1, X2 - 2, Y2 - 1);
	end
	else
	begin
		{Get absolute position and size of the object}
		GetAbsPos(X1, Y1);
		X2 := X1 + Self.Width;
		Y2 := Y1 + Self.Height;

		{Interior}
		SetFillStyle(SolidFill, BgColor);
		Bar(X1, Y1, X2, Y2 - 2);

		{3D border below}
		SetColor(Thm.Shadow);
		Line(X1, Y2 - 1, X2, Y2 - 1);
		SetColor(Black);
		Line(X1, Y2, X2, Y2);
	end;

	DrawChildren; {Draw all menu items}
end;

procedure TMenu.AddMenuItem(Item: PMenuItem);
var
	X, Y, W, H: Integer;
	OffsetX, OffsetY: Integer;
	OffsetNode: PObjectNode;
begin
	OffsetX := 0;
	OffsetY := 0;

	{Item will be placed after the last existing item, and since items are added
	 to the start of the linked list, the first item in the list is the last added item}
	if Assigned(Objects) then
	begin
		OffsetNode := Objects;
		while Assigned(OffsetNode^.Next) do
			OffsetNode := OffsetNode^.Next;
		OffsetX := OffsetNode^.ObjectP^.Left + OffsetNode^.ObjectP^.Width + 1;
		OffsetY := OffsetNode^.ObjectP^.Top + OffsetNode^.ObjectP^.Height + 1;
	end;

	if MenuStyle = MsPopup then
	begin
		X := 2;
		Y := OffsetY;
		W := 10; {Width will be set later when menu is show}
	end
	else
	begin
		{Menu bar}
		X := OffsetX;
		Y := 0;
		W := PrintW(Item^.Caption) + 9; {Width based on caption length, plus spacing}
	end;
	H := MenuItemHeight;

	{Set position and size of the new menu item}
	Item^.Move(X, Y);
	Item^.Resize(W, H);

	{Add item to the menu's linked list of objects}
	Item^.SetParent(@Self);
end;

destructor TMenu.Done;
begin
	Inherited Done;
end;

{----------------------------------------------------------------------------}
{ Menu item object implementation }
{----------------------------------------------------------------------------}

constructor TMenuItem.Init(Cap: string; AsSeperator: Boolean; Parent: PMenu);
begin
	Inherited Init;
	Caption   := Cap;
	Seperator := AsSeperator;
	if Assigned(Parent) then
		Parent^.AddMenuItem(@Self);
end;

procedure TMenuItem.CheckEvent;
begin
	{Don't check for events if item is disabled or hidden}
	if not (SEnabled in State) or (SHidden in State) then
		exit;

	{Todo - if menu is a popup menu, only allow interaction when visible}

	if IsMouseOver then
	begin
		{Make sure item is highlighted when mouse is over}
		if not (SActive in State) then
		begin
			Include(State, SActive);
			Mouse.Hide;
			Self.Draw;
			Mouse.Show;
		end;

		if Mouse.Clicked = MbLeft then
		begin
			repeat;	until Mouse.Clicked = MbNone;
			{Check if mouse is still over the item after release}
			if Self.IsMouseOver then
			begin
				Exclude(State, SActive);
				Mouse.Hide;
				Self.Draw;
				Mouse.Show;
				Self.Click;
			end;
		end;
	end
	else
	begin
		{If mouse is not over the item, remove highlight}
		if SActive in State then
		begin
			Exclude(State, SActive);
			Mouse.Hide;
			Self.Draw;
			Mouse.Show;
		end;
	end;

	{Trigger OnClick event, if assigned}
	if Self.HotkeyPressed then
		Self.Click;
end;

procedure TMenuItem.Draw;
var
	X1, Y1, X2, Y2: Integer;
	TempFgColor, TempBgColor: Byte;
begin
	{Get absolute position and size of the object}
	GetAbsPos(X1, Y1);
	X2 := X1 + Width;
	Y2 := Y1 + Height;

	if SActive in State then
	begin
		TempFGColor := Thm.SelText;
		TempBgColor := Thm.Sel;
	end
	else
	begin
		{Get colors}
		TempFgColor := FGColor;
		TempBgColor := BGColor;
	end;

	{Interior}
	SetFillStyle(SolidFill, TempBgColor);
	Bar(X1, Y1, X2, Y2 - 2);
	Print(Caption, X1 + 5, Y1 + 3, TempFgColor);
end;

destructor TMenuItem.Done;
begin
	Inherited Done;
end;