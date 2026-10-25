unit UIFRAME;

interface

uses
	Costalib, Graph;

type
	PFrame = ^TFrame;
	TFrame = object(TContainer)
		public
			Caption:     String[15];

			constructor  Init(X, Y: Integer; Parent: PContainer);
			procedure    Draw; virtual;

			procedure    SetCaption(Cap: String);
	end;

implementation

constructor TFrame.Init(X, Y: Integer; Parent: PContainer);
const
	DefaultW = 100;
	DefaultH = 100;
begin
	Inherited Init(X, Y, Parent);
	Width       := DefaultW;
	Height      := DefaultH;
	BorderStyle := BorFrame;
	Caption     := '';
	FgColor     := Thm.WinText;
	BgColor     := Thm.Win;
end;

procedure TFrame.Draw;
var
	X1, Y1: Integer;
begin
	if SHidden in State then
		exit;

	DrawBorder;

	{DEBUG - test draw caption}
	if Length(Self.Caption) > 0 then
	begin
		Self.GetAbsPos(X1, Y1);
		if BorderStyle = BorFrame then
			Inc(X1, 7);

		SetFillStyle(SolidFill, BgColor);
		Bar(X1, Y1 - 3, X1 + PrintW(Caption) + 2, Y1 + 4);
		Print(Caption, X1 + 2, Y1 - 3, FGColor);
	end;

	{Draw child objects and call inherited draw to update State etc.}
	DrawChildren;
	TUIObject.Draw;
end;

procedure TFrame.SetCaption(Cap: string);
begin
	Caption := Cap;
	Include(State, SDirty);
end;

end.