unit UIAREA;

interface

uses
	Costalib, Graph;

type
	TArea = object(TUIObject)
		public
			Transparent: Boolean;
			BGColor:     Integer;
			constructor  Init(X, Y, W, H: Integer);
			procedure    Draw; virtual;
	end;

implementation

constructor TArea.Init(X, Y, W, H: Integer);
const
	DefaultW = 50;
	DefaultH = 50;
begin
	TUIObject.Init;
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	BGColor := ColorDefault;
	Transparent := False;
end;

procedure TArea.Draw;
var
	X1, X2, Y1, Y2: Integer;
	BorderTLColor, BorderBRColor, BackColor: Byte; {TL = top+left, BR = bottom+right}
begin
	X1 := Left;
	Y1 := Top;
	X2 := X1 + Width;
	Y2 := Y1 + Height;

	{Interior}
	If Not Transparent Then
	Begin
		if BgColor > GetMaxColor then
			BackColor := Thm.Txt
		else
			BackColor := BgColor;
		SetFillStyle(SolidFill, BackColor);
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

	if Assigned(OnDraw) then
		OnDraw(@Self);
end;

end.