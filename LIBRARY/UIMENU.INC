{----------------------------------------------------------------------------}
{ Container object implementation }
{----------------------------------------------------------------------------}

constructor TMenuBar.Init(Parent: PContainer);
const
	DefaultW = 100;
var
	X, Y: Integer;
	W, H: Word;
begin
	Inherited Init(0, 0, Parent);
	Width       := DefaultW;
	Height      := MenuBarHeight;
	BorderStyle := Bor3DBottom;
	FgColor     := Thm.WinText;
	BgColor     := Thm.Win;

	if Assigned(Parent) then
	begin
		Parent^.GetClientArea(X, Y, W, H);
		Self.Width := W;
	end;
end;

procedure TMenuBar.Draw;
begin
	if SHidden in State then
		exit;

	DrawBorder;

	{Trigger ondraw event via TUIObject, allowing apps to draw custom background etc. before
	 drawing child objects}
	TUIObject.Draw;
	DrawChildren;
end;