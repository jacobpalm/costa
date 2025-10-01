unit UIFRAME;

interface

uses
	Costalib, Graph;

type
	PFrame = ^TFrame;
	TFrame = object(TContainer)
		public
			LightColor,
			DarkColor:   Integer;
			Transparent: Boolean;
			constructor  Init(X, Y: Integer; Parent: PContainer);
			procedure    Draw; virtual;
	end;

implementation

constructor TFrame.Init(X, Y: Integer; Parent: PContainer);
const
	DefaultW = 100;
	DefaultH = 100;
begin
	TUIObject.Init;
	LightColor := Thm.Light;
	DarkColor := Thm.Shadow;
	Transparent := True;
	SetParent(Parent);
	SetPos(X, Y);
	SetSize(DefaultW, DefaultH);
end;

procedure TFrame.Draw;
var
	X1, X2, Y1, Y2: Integer;
	BgColor: Byte;
begin
	{Get absolute position and size of the object}
	Self.GetPos(X1, Y1, True);
	Self.GetSize(X2, Y2);
	Inc(X2, X1);
	Inc(Y2, Y1);

	{Interior}
	BgColor := GetBGColor;
	if not Transparent then
	begin
		if BgColor = ColorDefault then
			BgColor := Thm.Win;
		SetFillStyle(SolidFill, BGColor);
		Bar(X1 + 2, Y1 + 2, X2 - 2, Y2 - 2);
	end;

	{Borders}
	SetColor(LightColor);
	Rectangle(X1 + 1, Y1 + 1, X2 - 1, Y2);
	SetColor(DarkColor);
	Rectangle(X1, Y1, X2 - 1, Y2 - 1);

	DrawChildren;

	TUIObject.Draw;
end;

end.