unit UIAREA;

interface

uses
	Costalib, Graph;

type
	PArea = ^TArea;
	TArea = object(TUIObject)
		public
			Transparent: Boolean;
			BGColor:     Integer;
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
	BGColor := ColorDefault;
	Transparent := False;

	SetParent(Parent);
	SetPos(X, Y);
	SetSize(DefaultW, DefaultH);
end;

procedure TArea.Draw;
var
	X1, X2, Y1, Y2: Integer;
	BorderTLColor, BorderBRColor, BackColor: Byte; {TL = top+left, BR = bottom+right}
begin
	{Get absolute position and size of the object}
	Self.GetPos(X1, Y1, True);
	Self.GetSize(X2, Y2);
	Inc(X2, X1);
	Inc(Y2, Y1);

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