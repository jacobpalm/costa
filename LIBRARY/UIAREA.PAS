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
	Left        := X;
	Top         := Y;
	Width       := DefaultW;
	Height      := DefaultH;
	BorderStyle := Bor3DSunken;
	FgColor := Thm.TxtText;
	BgColor := Thm.Txt;
	SetParent(Parent);
end;

procedure TArea.Draw;
begin
	if SHidden in State then
		exit;

	DrawBorder;
	Inherited Draw;
end;

end.