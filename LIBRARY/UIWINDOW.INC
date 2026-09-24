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

	{Call ancestor destructor for properties that aren't specific to TWindow}
	inherited Done;
end;