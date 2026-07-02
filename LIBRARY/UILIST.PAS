
unit UIList;

interface

uses
	Costalib, UIArea, Graph;

const
	{DEBUG - adapt to allow variable size lists}
	MaxVisibleItems = 15;
	ListItemHeight  = 12;

type
	TListDirection = (Up, Down, First, Last, PageUp, PageDown);

	PListItem = ^TListItem;
	TListItem = record
		Text: string;
		Next: PListItem;
	end;

	PList = ^TList;
	TList = object(TUIObject)
		public
			OnChange:      TEventProc;
			OnDoubleClick: TEventProc;

			constructor    Init(X, Y: Integer; Parent: PContainer);
			destructor     Done; virtual;
			procedure      CheckEvent; virtual;
			procedure      Draw; virtual;

			procedure      AddItem(const ItemText: string);
			function       GetItem(Index: integer): string;
			function       GetSelectedItem: string;
			procedure      ClearItems;

			procedure      MoveSelection(Direction: TListDirection);

			procedure      SetListActive(IsActive: boolean);
			function       GetListActive: boolean;

		private
			Head:          PListItem;
			Selection:     Integer;
			StartPos:      Integer;
			Length:        Integer;
			DblClickTimer: Real;
	end;

implementation

constructor TList.Init(X, Y: Integer; Parent: PContainer);
const
	DefaultW = 150;
	DefaultH = 185;
begin
	inherited Init;
	SetParent(Parent);
	SetPos(X, Y);
	SetSize(DefaultW, DefaultH);

	Head          := nil;
	Selection     := 1;
	StartPos      := 1;
	Length        := 0;
	DblClickTimer := 0.0;
	OnChange      := nil;
	OnDoubleClick := nil;
end;

procedure TList.AddItem(const ItemText: string);
var
	NewNode, LastNode: PListItem;
begin
	{Init new node}
	New(NewNode);
	NewNode^.Text := ItemText;
	NewNode^.Next := nil;

	if not Assigned(Head) then
	begin
		{First item in the list}
		Head := NewNode;
		Length := 1;
	end
	else
	begin
		{Find the last node in the list}
		LastNode := Head;
		while Assigned(LastNode^.Next) do
			LastNode := LastNode^.Next;
		{Add new node at the end}
		LastNode^.Next := NewNode;

		Inc(Length);
	end;
end;

procedure TList.CheckEvent;
var
	X1, Y1: Integer;
	ClickedX, ClickedY, ClickedItem: Integer;
	ListItem: TListItem;
	I: Integer;
begin
	{Don't check for events if object is disabled or hidden}
	if not (SEnabled in State) or (SHidden in State) then
		exit;

	{Get absolute position and size of the object}
	GetPos(X1, Y1, True);

	if (Mouse.Clicked = MbNone) or (not Self.IsMouseOver) then
	begin
		{No mouse click or click outside the object, check for hotkeys only}
		if Self.HotkeyPressed then
			Self.Click;
		exit;
	end;

	{Make clicked coordinates relative to the list area}
	ClickedX := Mouse.X - X1;
	ClickedY := Mouse.Y - Y1;

	{Validate click inside, not on border}
	if (ClickedX > 1) and (ClickedX < Width - 2) and
	   (ClickedY > 2) and (ClickedY < Height - 1) then
	begin
		{There is a 3-pixel border before the first item.
		Calculate clicked item}
		ClickedItem := ((ClickedY - 3) div ListItemHeight) + 1;

		if ClickedItem > MaxVisibleItems then
		begin
			{Clicked inside list area, but in the small gap after the last item.
			Draw current item with focus}
			Self.SetListActive(True);
			while Mouse.Clicked > MbNone do;
			exit;
		end;

		ClickedItem := ClickedItem + StartPos - 1;
		if ClickedItem <= Length then
		begin
			if ClickedItem = Selection then
			begin
				{Already selected and clicked again, check for double-click}

				if (Timer - DblClickTimer) <= DoubleClickDelay then
					if Assigned(OnDoubleClick) then
					begin
						while Mouse.Clicked > MbNone do;
						OnDoubleClick(@Self);
						exit;
					end
				else
					{Make sure the list is active and the selected item is highlighted}
					Self.SetListActive(True);
			end
			else
			begin
				{Clicked item is not the current selection, move selection}
				Self.SetListActive(False);
				Selection := ClickedItem;
				Self.SetListActive(True);
				{DEBUG - this is a drity hack, since SetListActive triggers redraw of list by modifying SActive state...}
				Self.RemoveState(SDirty);
				{Trigger change event if assigned}
				if Assigned(OnChange) then
					OnChange(@Self);
			end;
		end
		else
		begin
			{Clicked in list, but below any items. Give focus to current selection}
			Self.SetListActive(True);
		end;

		DblClickTimer := Timer;
		while Mouse.Clicked > MbNone do;
	end;

	{Trigger click event if assigned}
	Self.Click;
end;

procedure TList.ClearItems;
var
	NextNode: PListItem;
begin
	while Assigned(Head) do
	begin
		NextNode := Head^.Next;
		Dispose(Head);
		Head := NextNode;
	end;
	Length := 0;
	StartPos := 1;
	Selection := 1;
end;

function TList.GetItem(Index: integer): string;
var
    I: Integer;
	TargetNode: PListItem;
begin
    TargetNode := Head;
	if Index > 1 then
	begin
		for I := 1 to Index - 1 do
		begin
			if not Assigned(TargetNode) then
				break;

			TargetNode := TargetNode^.Next
		end;
	end;

	if Assigned(TargetNode) then
		GetItem := TargetNode^.Text
	else
		GetItem := '';
end;

function TList.GetSelectedItem: string;
begin
	GetSelectedItem := Self.GetItem(Selection);
end;

procedure TList.Draw;
var
	I, Counter: Integer;
	X1, Y1, X2, Y2, YOffset: Integer;
	ItemText: String;
	FgColor, BgColor: Byte;
begin
	if Head = nil then
		exit; {Nothing to draw}

	{Get absolute position and size of the object}
	GetPos(X1, Y1, True);
	X2 := X1 + Width;
	Y2 := Y1 + Height;

	{Get colors}
	FgColor := GetFgColor;
	BgColor := GetBgColor;
	if FgColor = ColorDefault then
		FgColor := Thm.TxtText;
	if BgColor = ColorDefault then
		BgColor := Thm.Txt;

	DrawUIPrimitive(UIBorderDown, X1, Y1, X2, Y2, BgColor, (STransparent in State));

	{Draw contents of list}
	{Set X coordinates to internal area inside border, and Y coordinates to the first item position}
	Inc(X1, 2);
	Dec(X2, 2);
	Inc(Y1, 3);
	Y2 := Y1 + 12;
	Counter := 0;

	if StartPos > Length then
		StartPos := 1; {Reset start position if it exceeds item count}

	{Draw items from the start position}
	for I := StartPos to StartPos + MaxVisibleItems - 1 do
	begin
		if I <= Length then
		begin
			ItemText := Self.GetItem(I);

			{Highlight selected item if list is active}
			if (I = Selection) and (SActive in State) then
			begin
				SetFillStyle(SolidFill, Thm.Sel);
				Bar(X1, Y1 + (Counter * ListItemHeight), X2, Y2 - 1 + (Counter * ListItemHeight));
				Print(ItemText, X1 + 3, Y1 + 2 + (Counter * ListItemHeight), Thm.SelText);
			end
			else
			begin
				{Draw normal, unselected item}
				Print(ItemText, X1 + 3, Y1 + 2 + (Counter * ListItemHeight), FgColor);
			end;

			{Increment counter, it's used to calculate Y position}
			Inc(Counter);
		end;
	end;

	TUIObject.Draw;
end;

procedure TList.MoveSelection(Direction: TListDirection);
var
	NewSelection, NewStartPos, i: Integer;
	ListItem: PListItem;
begin
	NewSelection := Selection;
	NewStartPos := StartPos;

	case Direction of
		Up: Dec(NewSelection);
		Down: Inc(NewSelection);
		First: NewSelection := 1;
		Last: NewSelection := Length;
		PageUp: Dec(NewSelection, MaxVisibleItems);
		PageDown: Inc(NewSelection, MaxVisibleItems);
	end;

	{Check for out of bounds selection}
	if NewSelection < 1 then
		NewSelection := 1
	else if NewSelection > Length then
		NewSelection := Length;

	{If selection is the same, no need to do anything}
	if NewSelection = Selection then
		exit;

	{If there aren't enough items to span more than one page, always start displaying from the first item}
	if Length < MaxVisibleItems then
		NewStartPos := 1
	else
	begin
		{More than one page, check if the selection is above or below the current visible items}

		{If selection is above visible items, scroll up one page at a time until it is visible}
		if NewSelection < NewStartPos then
		begin
			repeat
				Dec(NewStartPos, MaxVisibleItems);
			until NewStartPos <= NewSelection;
			if NewStartPos < 1 then
				NewStartPos := 1;
		end;

		{If selection is below visible items, scroll down one page at a time until it is visible}
		if NewSelection > NewStartPos + MaxVisibleItems - 1 then
		begin
			repeat
				Inc(NewStartPos, MaxVisibleItems);
			until (NewStartPos <= NewSelection) and
				(NewStartPos + MaxVisibleItems - 1 >= NewSelection);
			if NewStartPos > Length then
				NewStartPos := Length;
		end;
	end;

	{If list has scrolled, we need a full redraw}
	if (NewStartPos <> StartPos) or not (SActive in State) then
	begin
		AddState(SActive);
		AddState(SDirty); {Ensure full redraw}
		Selection := NewSelection;
		StartPos := NewStartPos;
	end
	else
	begin
		{Redraw without selection, redrawing just the selected item}
		Self.SetListActive(False);
		{Move selection and redraw only that item}
		Selection := NewSelection;
		Self.SetListActive(True);
		{DEBUG - dirty hack, should be handled better than this}
		Self.RemoveState(SDirty);
	end;

	if Assigned(OnChange) then
		OnChange(@Self);
end;

procedure TList.SetListActive(IsActive: boolean);
var
	X1, Y1, X2, Y2: Integer;
	YOffset: Integer;
	ItemText: String;
	Counter: Integer;
	FgColor, BgColor: Byte;
begin
	if (SActive in State) = IsActive then
		exit;

	if IsActive then
		AddState(SActive)
	else
		RemoveState(SActive);

	{If there's no valid selection, we won't draw anything}
	if (Selection < 1) or (Selection > Length) then
		exit;

	{If list is not visible, we won't draw anything}
	if SHidden in State then
		exit;

	{Get absolute position and size of the object}
	GetPos(X1, Y1, True);
	X2 := X1 + Width;

	{Calculate selection position and update it to reflect the new state}
	Inc(X1, 2);
	Dec(X2, 2);
	Inc(Y1, 3);
	Y2 := Y1 + 12;
	YOffset := (Selection - StartPos) * ListItemHeight;
	Counter := 0;

	{If list is active, use selection colors, otherwise use normal colors defined on object}
	if SActive in State then
	begin
		FgColor := Thm.SelText;
		BgColor := Thm.Sel;
	end
	else
	begin
		{Get colors}
		FgColor := GetFgColor;
		BgColor := GetBgColor;
		if FgColor = ColorDefault then
			FgColor := Thm.TxtText;
		if BgColor = ColorDefault then
			BgColor := Thm.Txt;
	end;

	{Redraw only the selected item}
	ItemText := Self.GetItem(Selection);
	if ItemText <> '' then
	begin
		Mouse.Hide;
		SetFillStyle(SolidFill, BgColor);
		Bar(X1, Y1 + YOffset, X2, Y2 - 1 + YOffset);
		Print(ItemText, X1 + 3, Y1 + 2 + YOffset, FgColor);
		Mouse.Show;
	end;
end;

function TList.GetListActive: boolean;
begin
	GetListActive := SActive in State;
end;

destructor TList.Done;
begin
	{Free all list items and call ancestor destructor to free up
	 hotkeys and other generic memory}
	Self.ClearItems;
	inherited Done;
end;

end.