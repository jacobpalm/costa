unit UIAREA;

interface

uses
	Costalib, Graph;

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
	SetParent(Parent);
	SetPos(X, Y);
	SetSize(DefaultW, DefaultH);
end;

procedure TArea.Draw;
var
	X1, X2, Y1, Y2: Integer;
	BgColor: Byte;
begin
	if GetState(SHidden) then
		exit;

	{Get absolute position and size of the object}
	Self.GetPos(X1, Y1, True);
	Self.GetSize(X2, Y2);
	Inc(X2, X1);
	Inc(Y2, Y1);

	BgColor := GetBGColor;
	if BgColor = ColorDefault then
		BgColor := Thm.Txt;

	DrawUIPrimitive(UIBorderDown, X1, Y1, X2, Y2, BgColor, GetState(STransparent));

	Inherited Draw;
end;

end.