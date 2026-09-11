{----------------------------------------------------------------------------}
{ Window object implementation }
{----------------------------------------------------------------------------}

constructor TWindow.Init(X, Y: Integer; Parent: PContainer);
const
	DefaultW = 320;
	DefaultH = 175;
begin
	Inherited Init(X, Y, Parent);
	Width            := DefaultW;
	Height           := DefaultH;
	DoClose          := False;
	OnRun            := nil;
	OnClose          := nil;
	MenuObj          := nil;
	BackdropP        := nil;
	BackdropS        := 0;
	EventQueue       := nil;
	PreserveBackdrop := False;
	BorderStyle      := BorDialog;
	FGColor          := Thm.WinText;
	BgColor          := Thm.Win;
end;

procedure TWindow.Draw;
var
	X1, X2, Y1, Y2: Integer;
begin
	{Don't draw or trigger event if window is hidden}
	if SHidden in State then
		exit;

	{If background preservation is enabled, and background hasn't been
	 captured yet, capture it now before drawing anything}
	if PreserveBackdrop and not Assigned(BackdropP) then
	begin
		{Get absolute position and size of the window}
		Self.GetAbsPos(X1, Y1);
		X2 := X1 + Width;
		Y2 := Y1 + Height;

		{Make sure we don't try to copy memory outside screen area}
		if X1 < 0 then X1 := 0;
		if Y1 < 0 then Y1 := 0;
		if X2 > ScreenWidth then X2 := ScreenWidth;
		if Y2 > ScreenHeight then Y2 := ScreenHeight;
		{Calculate size of memory block required to store background image}
		BackdropS := ImageSize(X1, Y1, X2, Y2);

		if MaxAvail > BackdropS then
		begin
			{Allocate memory required to store the background image}
			GetMem(BackdropP, BackdropS);

			{Capture background image}
			GetImage(X1, Y1, X2, Y2, BackdropP^);
		end;
	end;

	DrawBorder;

	{Trigger ondraw event via TUIObject, allowing apps to draw custom background etc. before
	 drawing child objects}
	TUIObject.Draw;
	DrawChildren;
end;

procedure TWindow.QueueEvent(Sender: PUIObject; Event: TEventType; MouseX, MouseY, MouseButton: Word; Key: TKeyPress);
var
	NewEvent: PEvent;
	NewEventNode, CheckEventNode: PEventNode;
begin
	{Create a new event record in memory and assign its data}
	NewEvent := New(PEvent);
	NewEvent^.Sender := Sender;
	NewEvent^.Event := Event;
	NewEvent^.MouseX := MouseX;
	NewEvent^.MouseY := MouseY;
	NewEvent^.MouseButton := MouseButton;
	NewEvent^.Key := Key;

	{Create a new node for the event queue and point it to the event record}
	NewEventNode := New(PEventNode);
	NewEventNode^.EventData := NewEvent;
	NewEventNode^.Next := nil;

	{If there is no queue, set new node as queue}
	if Self.EventQueue = nil then
	begin
		Self.EventQueue := NewEventNode;
		Exit;
	end;

	{If there is an existing queue, iterate through each item until a node with no
	 Next node is found}
	CheckEventNode := Self.EventQueue;
	while Assigned(CheckEventNode^.Next) do
		CheckEventNode := CheckEventNode^.Next;

	{Set Next of last node to the new node}
	CheckEventNode^.Next := NewEventNode;
end;

procedure TWindow.GetEvent(var Event: TEvent);
var
	TempNode: PEventNode;
begin
	if not (Assigned(Self.EventQueue)) then
	begin
		{Debug - this is where to check for user events}
		FillChar(Event, SizeOf(Event), 0);
		Exit;
	end;

	Event := Self.EventQueue^.EventData^;

	{Save event node pointer, and remove it from the queue by setting queue header to next event node}
	TempNode := Self.EventQueue;
	Self.EventQueue := Self.EventQueue^.Next;

	{Dispose of the event itself and the event node that held it}
	Dispose(TempNode^.EventData);
	Dispose(TempNode);
end;

procedure TWindow.ClearEventQueue;
var
	TempNode: PEventNode;
begin
	while Assigned(Self.EventQueue) do
	begin
		TempNode := Self.EventQueue;
		Self.EventQueue := Self.EventQueue^.Next;
		Dispose(TempNode^.EventData);
		Dispose(TempNode);
	end;
end;

procedure TWindow.Run;
var
	CurrObj: PObjectNode;
begin
	Self.DoClose := False;

	{OnRun can be used for initialization code before the window is drawn}
	if Assigned(OnRun) then
		OnRun(@Self);

	{Draw window and all objects in the window}
	Mouse.Hide;
	Self.Draw;
	Mouse.Show;

	while not Self.DoClose and Assigned(Objects) do
	begin
		HotkeyInput := GetKey;
		Self.CheckEvent;
		Self.DrawDirtyObjects;
	end;

	if Assigned(OnClose) then
		OnClose(@Self);

	{Restore background behind window, if it was saved}
	Self.RestoreBackdrop;
end;

procedure TWindow.CheckEvent;
var
	CurrObj: PObjectNode;
begin
	{Don't check for events if window is disabled or hidden}
	if not (SEnabled in State) or (SHidden in State) then
		exit;

	CurrObj := Objects;
	while Assigned(CurrObj) do
	begin
		CurrObj^.ObjectP^.CheckEvent;

		{If the window was closed by an event, exit the loop}
		if Self.DoClose then
			exit;

		CurrObj := CurrObj^.Next;
	end;
end;

procedure TWindow.RestoreBackdrop;
var
	X1, Y1: Integer;
begin
	if not Assigned(BackdropP) then
		exit;

	{DEBUG - out of bounds check}
	{Get absolute position of the window}
	Self.GetAbsPos(X1, Y1);

	{Restore background}
	Mouse.Hide;
	PutImage(X1, Y1, BackdropP^, NormalPut);
	Mouse.Show;

	{Free memory used to store background image}
	FreeMem(BackdropP, BackdropS);
	BackdropP := nil;
	BackdropS := 0;
end;

procedure TWindow.SaveBackdrop;
begin
	PreserveBackdrop := True;
end;

procedure TWindow.Close;
begin
	Self.DoClose := True;
end;

destructor TWindow.Done;
begin
	if Assigned(BackdropP) then
		FreeMem(BackdropP, BackdropS);

	Self.ClearEventQueue;

	{Call ancestor destructor for properties that aren't specific to TWindow}
	inherited Done;
end;