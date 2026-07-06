unit UIAREA;

interface

uses
	Costalib;

type
	PArea = ^TArea;
	TArea = object(TUIObject)
		public
			constructor  Init(X, Y: Integer; Parent: PContainer);
			procedure    Draw; virtual;
	end;

implementation

constructor TArea.Init(X, Y: Integer; Parent: PContainer);
const
	DefaultW = 100;
	DefaultH = 100;
begin
	TUIObject.Init;
	Left   := X;
	Top    := Y;
	Width  := DefaultW;
	Height := DefaultH;
	SetParent(Parent);
end;

procedure TArea.Draw;
var
	X1, Y1: Integer;
	BgColor: Byte;
begin
	if SHidden in State then
		exit;

	{Get absolute position and size of the object}
	Self.GetAbsPos(X1, Y1);

	BgColor := GetBGColor;
	if BgColor = ColorDefault then
		BgColor := Thm.Txt;

	DrawUIPrimitive(UIBorderDown, X1, Y1, Self.Width, Self.Height, BgColor, (STransparent in State));

	Inherited Draw;
end;

end.