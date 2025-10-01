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
	{Get absolute position and size of the object}
	Self.GetPos(X1, Y1, True);
	Self.GetSize(X2, Y2);
	Inc(X2, X1);
	Inc(Y2, Y1);

	{Interior}
	If Not GetState(Transparent) Then
	Begin
		BgColor := GetBGColor;
		if BgColor = ColorDefault then
			BgColor := Thm.Txt;
		SetFillStyle(SolidFill, BgColor);
		Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
	End;

	{Top + left border}
	SetColor(Black);
	Line(X1, Y1, X2, Y1);
	Line(X1, Y1 + 1, X1, Y2);
	SetColor(Thm.Shadow);
	Line(X1 + 1, Y1 + 1, X2 - 1, Y1 + 1);
	Line (X1 + 1, Y1 + 2, X1 + 1, Y2 - 1);

	{Bottom + right border}
	SetColor(White);
	Line(X2, Y1 + 1, X2, Y2);
	Line(X1 + 1, Y2, X2 - 1, Y2);
	SetColor(Thm.Light);
	Line(X2 - 1, Y1 + 2, X2 - 1, Y2 - 1);
	Line(X1 + 2, Y2 - 1, X2 - 2, Y2 - 1);

	TUIObject.Draw;
end;

end.