unit UIFRAME;

interface

uses
	Costalib, Graph;

type
	TFrame = object(TUIObject)
		public
			LightColor,
			DarkColor,
			BGColor:     Integer;
			Transparent: Boolean;
			constructor  Init(X, Y, W, H: Integer);
			procedure    Draw; virtual;
	end;

implementation

constructor TFrame.Init(X, Y, W, H: Integer);
const
	DefaultW = 100;
	DefaultH = 100;
begin
	TUIObject.Init;
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	LightColor := Thm.Light;
	DarkColor := Thm.Shadow;
	BGColor := Thm.Win;
	Transparent := True;
end;

procedure TFrame.Draw;
begin
	{Interior}
	if not Transparent then
	begin
		SetFillStyle(SolidFill, BGColor);
		Bar(Left + 2, Top + 2, Left + Width - 2, Top + Height - 2);
	end;

	{Borders}
	SetColor(LightColor);
	Rectangle(Left + 1, Top + 1, Left + Width - 1, Top + Height);
	SetColor(DarkColor);
	Rectangle(Left, Top, Left + Width - 1, Top + Height - 1);

	if Assigned(OnDraw) then
		OnDraw(@Self);
end;

end.