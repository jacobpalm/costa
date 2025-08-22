
unit UIList;

interface

uses
	Costalib, Graph;

const
	MaxVisibleItems = 15;
	ListItemHeight  = 12;

type
	TListDirection = (Up, Down, First, Last, PageUp, PageDown);
	TListState     = (LsActive, LsInactive);

	PListItem = ^TListItem;
	TListItem = record
		Text: string;
		Next: PListItem;
	end;
	
	TList = object(TArea)
		public
			OnChange:      Procedure(Sender: PUIObject);
			OnDoubleClick: Procedure(Sender: PUIObject);
			constructor    Init(X, Y, W, H: Integer);
			procedure      AddItem(const ItemText: string);
			procedure      CheckEvent;
			procedure      ClearItems;
			function       GetItem(Index: integer): string;
			function       GetSelectedItem: string;
			procedure      Draw;
			procedure      MoveSelection(Direction: TListDirection);
			procedure      SetState(State: TListState);
		private
			ListState:     TListState;
			Head:          PListItem;
			Selection:     Integer;
			StartPos:      Integer;
			Length:        Integer;
			DblClickTimer: Real;
	end;

implementation

constructor TList.Init(X, Y, W, H: Integer);
begin
	inherited Init(X, Y, W, H);
	ListState := LsInactive;
	Head := nil;
	Selection := 1;
	StartPos := 1;
	Length := 0;
	Transparent := false;
	BGColor := Thm.Txt;
	DblClickTimer := 0.0;
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
	ClickedX, ClickedY, ClickedItem: Integer;
	ListItem: TListItem;
	I: Integer;
begin
	MousePoll;
	if (MouseClicked = MbNone) or (not Self.IsMouseOver) then
		exit; {No mouse click, nothing to do}

	{Make clicked coordinates relative to the list area}
	ClickedX := MouseX - Left;
	ClickedY := MouseY - Top;

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
			Self.SetState(LsActive);
			while MouseClicked > MbNone do;
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
						while MouseClicked > MbNone do;
						OnDoubleClick(@Self);
						exit;
					end
				else
					{Make sure the list is active and the selected item is highlighted}
					Self.SetState(LsActive);
			end
			else
			begin
				{Clicked item is not the current selection, move selection}
				Self.SetState(LsInactive);
				Selection := ClickedItem;
				Self.SetState(LsActive);
				{Trigger change event if assigned}
				if Assigned(OnChange) then
					OnChange(@Self);
			end;
		end
		else
		begin
			{Clicked in list, but below any items. Give focus to current selection}
			Self.SetState(LsActive);
		end;

		DblClickTimer := Timer;
		while MouseClicked > MbNone do;
	end;
	
	{Trigger click event if assigned}
	if Assigned(OnClick) then
		OnClick(@Self);
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
begin
	{Draw procedure of TArea draws the background and border}
	MouseHide;
	inherited Draw;
	MouseShow;

	if Head = nil then
		exit;; {Nothing to draw}

	X1 := Left + 2;
	Y1 := Top + 3;
	X2 := Left + Width - 2;
	Y2 := Top + 15;
	Counter := 0;

	if StartPos > Length then
		StartPos := 1; {Reset start position if it exceeds item count}

	MouseHide;
	{Draw items from the start position}
	for I := StartPos to StartPos + MaxVisibleItems - 1 do
	begin
		if I <= Length then
		begin
			ItemText := Self.GetItem(I);

			{Highlight selected item if list is active}
			if (I = Selection) and (ListState = LsActive) then
			begin
				SetFillStyle(SolidFill, Thm.Sel);
				Bar(X1, Y1 + (Counter * ListItemHeight), X2, Y2 - 1 + (Counter * ListItemHeight));
				Print(ItemText, X1 + 3, Y1 + 2 + (Counter * ListItemHeight), Thm.SelText);
			end
			else
			begin
				{Draw normal, unselected item}
				Print(ItemText, X1 + 3, Y1 + 2 + (Counter * ListItemHeight), Thm.TxtText);
			end;

			{Increment counter, it's used to calculate Y position}
			Inc(Counter);
		end;
	end;
	MouseShow;
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
	if (NewStartPos <> StartPos) or (ListState = LsInactive) then
	begin
		ListState := LsActive;
		Selection := NewSelection;
		StartPos := NewStartPos;
		Self.Draw;
	end
	else
	begin
		{Redraw without selection, redrawing just the selected item}
		Self.SetState(LsInactive);
		{Move selection and redraw only that item}
		Selection := NewSelection;
		Self.SetState(LsActive);
	end;

	if Assigned(OnChange) then
		OnChange(@Self);
end;

procedure TList.SetState(State: TListState);
var
	X1, Y1, X2, Y2: Integer;
	YOffset: Integer;
	SelFGColor, SelBGColor: Integer;
	ItemText: String;
	Counter: Integer;
begin
	if State = ListState then
		exit;

	ListState := State;

	{If there's no valid selection, we won't draw anything}
	if (Selection < 1) or (Selection > Length) then
		exit;
	
	{Calculate selection position and update it to reflect the new state}
	X1 := Left + 2;
	Y1 := Top + 3;
	X2 := Left + Width - 2;
	Y2 := Top + 15;
	YOffset := (Selection - StartPos) * ListItemHeight;
	Counter := 0;

	if ListState = LsActive then
	begin
		SelFGColor := Thm.SelText;
		SelBGColor := Thm.Sel;
	end
	else
	begin
		SelFGColor := Thm.TxtText;
		SelBGColor := Thm.Txt;
	end;

	ItemText := Self.GetItem(Selection);
	if ItemText <> '' then
	begin
		MouseHide;
		SetFillStyle(SolidFill, SelBGColor);
		Bar(X1, Y1 + YOffset, X2, Y2 - 1 + YOffset);
		Print(ItemText, X1 + 3, Y1 + 2 + YOffset, SelFGColor);
	end;
		MouseShow;
end;

end.