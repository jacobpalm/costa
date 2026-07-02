unit UIFRAME;

interface

uses
	Costalib, Graph;

type
	PFrame = ^TFrame;
	TFrame = object(TContainer)
		public
			LightColor,
			DarkColor:   Byte;

			constructor  Init(X, Y: Integer; Parent: PContainer);
			procedure    Draw; virtual;

			procedure    SetLightColor(Color: Byte);
			procedure    SetDarkColor(Color: Byte);
		private
	end;

implementation

constructor TFrame.Init(X, Y: Integer; Parent: PContainer);
const
	DefaultW = 100;
	DefaultH = 100;
begin
	Inherited Init(X, Y, Parent);
	Width := DefaultW;
	Height := DefaultH;
	AddState(SBordered);
	LightColor := Thm.Light;
	DarkColor := Thm.Shadow;
end;

procedure TFrame.Draw;
var
	X1, X2, Y1, Y2: Integer;
	BgColor: Byte;
begin
	if SHidden in State then
		exit;

	{Get absolute position and size of the object}
	Self.GetPos(X1, Y1, True);
	X2 := X1 + Width;
	Y2 := Y1 + Height;

	{Interior}
	if not (STransparent in State) then
	begin
		BgColor := GetBGColor;
		if BgColor = ColorDefault then
			BgColor := Thm.Win;
		SetFillStyle(SolidFill, BGColor);
		if SBordered in State then
			Bar(X1 + 2, Y1 + 2, X2 - 2, Y2 - 2)
		else
			Bar(X1, Y1, X2, Y2);
	end;

	{Borders}
	if SBordered in State then
	begin
		SetColor(LightColor);
		Rectangle(X1 + 1, Y1 + 1, X2 - 1, Y2);
		SetColor(DarkColor);
		Rectangle(X1, Y1, X2 - 1, Y2 - 1);
	end;

	{Draw child objects and call inherited draw to update State etc.}
	DrawChildren;
	TUIObject.Draw;
end;

procedure TFrame.SetLightColor(Color: Byte);
begin
	if ((Color >= 0) and (Color <= GetMaxColor)) or
	   (Color = ColorDefault) then
		LightColor := Color;

	AddState(SDirty);
end;

procedure TFrame.SetDarkColor(Color: Byte);
begin
	if ((Color >= 0) and (Color <= GetMaxColor)) or
	   (Color = ColorDefault) then
		DarkColor := Color;

	AddState(SDirty);
end;

end.