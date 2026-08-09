{----------------------------------------------------------------------------}
{ Container object implementation }
{----------------------------------------------------------------------------}

constructor TContainer.Init(X, Y: Integer; Parent: PContainer);
const
	DefaultW = 320;
	DefaultH = 175;
begin
	TUIObject.Init;
	Objects     := nil;
	Left        := X;
	Top         := Y;
	Width       := DefaultW;
	Height      := DefaultH;
	BorderStyle := BorNone;
	SetParent(Parent);
end;

procedure TContainer.AddObject(Obj: PUIObject);
var
	NewNode, LastNode: PObjectNode;
begin
	if not Assigned(Obj) then
		exit;

	New(NewNode);
	NewNode^.ObjectP := Obj;
	NewNode^.Next := nil;

	{If this is the first object, set it as head of the list,
	 otherwise, find the end of the list and add it there}
	if Objects = nil then
		Objects := NewNode
	else
	begin
		LastNode := Objects;
		while LastNode^.Next <> nil do
			LastNode := LastNode^.Next;
		LastNode^.Next := NewNode;
	end;

	{Since object has just been added, a draw is needed}
	Obj^.AddState(SDirty);
end;

procedure TContainer.Draw;
begin
	if SHidden in State then
		exit;

	{TContainer has no visible element, so just draw its children}
	DrawChildren;

	{Call inherited Draw to handle state etc.}
	TUIObject.Draw;
end;

procedure TContainer.CheckEvent;
var
	CurrObj: PObjectNode;
begin
	{Don't check for events if container is disabled or hidden}
	if not (SEnabled in State) or (SHidden in State) then
		exit;

	CurrObj := Objects;
	while Assigned(CurrObj) do
	begin
		CurrObj^.ObjectP^.CheckEvent;
		CurrObj := CurrObj^.Next;
	end;
end;

procedure TContainer.DrawChildren;
var
	CurrObj: PObjectNode;
begin
	{Don't draw if container is hidden or has no objects}
	if (SHidden in State) or not Assigned(Objects) then
		exit;

	{Draw all objects in the linked list}
	CurrObj := Objects;
	CurrObj^.ObjectP^.Draw;
	while Assigned(CurrObj^.Next) do
	begin
		CurrObj := CurrObj^.Next;
		CurrObj^.ObjectP^.Draw;
	end;

	{OnDraw is not triggered by the container, as it is not a visual object -
	 descendants should implement their own Draw method and trigger OnDraw there}
end;

{Any objects in container that have queued a redraw is taken care of in this proc}
procedure TContainer.DrawDirtyObjects;
var
	CurrObj: PObjectNode;
	ContainerObj: PContainer;
	MouseHidden: Boolean;
begin
	{Keep track of mouse state - we don't want it to flicker if nothing is redrawn}
	{DEBUG - maybe only hide mouse if near a redrawn object?}
	MouseHidden := False;

	{If the window itself is dirty, EVERYTHING in it needs redraw - so just call Draw}
	if SDirty in State then
	begin
		Mouse.Hide;
		Self.Draw;
		Mouse.Show;
		Exit;
	end;

	{Window clean, so iterate through Objects in window to find dirty ones}
	CurrObj := Objects;
	while Assigned(CurrObj) do
	begin
		{Skip hidden objects}
		if SHidden in CurrObj^.ObjectP^.State then
		begin
			CurrObj := CurrObj^.Next;
			continue;
		end;

		{If object is dirty, redraw it - after making sure cursor is hidden}
		if (SDirty in CurrObj^.ObjectP^.State) then
		begin
			if not MouseHidden then
			begin
				Mouse.Hide;
				MouseHidden := true;
			end;
			CurrObj^.ObjectP^.Draw; {TUIObject.Draw removes dirty state}
		end;

		{If object is a container, trigger DrawDirtyObjects on it too to make
		 sure dirty objects in it get redrawn. If entire object has bee redrawn above,
		 there will be nothing dirty and so nothing will get drawn twice}
		if CurrObj^.ObjectP^.IsContainer then
			PContainer(CurrObj^.ObjectP)^.DrawDirtyObjects;

		{Move to next object}
		CurrObj := CurrObj^.Next;
	end;

	if MouseHidden then
		Mouse.Show;
end;

procedure TContainer.GetClientArea(var X, Y: Integer; Var W, H: Word);
var
	BorderWidth: Word;
begin
	BorderWidth := Self.GetBorderWidth;
	Self.GetAbsPos(X, Y);
	Inc(X, BorderWidth);
	Inc(Y, BorderWidth);
	W := Self.Width - (BorderWidth * 2);  {Times two since border is on both sides}
	H := Self.Height - (BorderWidth * 2);
end;

function TContainer.IsContainer: boolean;
begin
	IsContainer := true;
end;

destructor TContainer.Done;
var
	NextNode: PObjectNode;
	PrevNode, LastNode: PObjectNode;
begin
	{Dispose of all objects in the linked list}
	while Assigned(Objects) do
	begin
		NextNode := Objects^.Next;
		{Call the destructor of the object}
		if Assigned(Objects^.ObjectP) then
			Dispose(Objects^.ObjectP, Done);
		{Dispose of the node}
		Dispose(Objects);
		Objects := NextNode;
	end;

	{Call ancestor destructor for properties that aren't specific to TContainer}
	inherited Done;
end;