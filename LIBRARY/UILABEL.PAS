unit UILABEL;

interface

uses
	Costalib, Graph;

type
	PLabel = ^TLabel;
	TLabel = object(TUIObject)
		public
			Caption:    String;
			Align:      TAlign;

			constructor Init(X, Y: Integer; Cap: String; Parent: PContainer);
			procedure   Draw; virtual;

			procedure   SetCaption(Cap: string);
			procedure   SetAlign(Val: TAlign);
			procedure   AutoSize;
	end;

implementation

constructor TLabel.Init(X, Y: Integer; Cap: String; Parent: PContainer);
const
	DefaultW = 100;
	DefaultH = PrintLineH;
begin
	TUIObject.Init;
	Caption := Cap;
	Align := AlLeft;
	Left := X;
	Top := Y;
	Width := DefaultW;
	Height := DefaultH;
	Include(State, STransparent);
	SetParent(Parent);
end;

procedure TLabel.AutoSize;
begin
	Self.Width := PrintW(Caption);
	Self.Height := PrintH(Caption);
	Include(State, SDirty);
end;

procedure TLabel.Draw;
var
	X1, Y1, X2, Y2: Integer;
	FGColor, BgColor: Byte;
begin
	if SHidden in State then
		exit;

	{Get absolute position and size of the object}
	GetAbsPos(X1, Y1);
	X2 := X1 + Width;
	Y2 := Y1 + Height;

	FGColor := GetFGColor;
	BgColor := GetBGColor;

	{If a background color is set, fill the label area with it}
	if not (STransparent in State) then
	begin
		if BgColor = ColorDefault then
			BgColor := Thm.Win;
		SetFillStyle(SolidFill, BgColor);
		Bar(X1, Y1, X2, Y2);
	end;

	{Use FgColor for text if set, otherwise use window color}
	if FGColor = ColorDefault then
		FGColor := Thm.WinText;

	if Align = AlRight then
		X1 := X2 - PrintW(Caption);

	if Align = AlCenter then
		X1 := ((X2 - X1) - PrintW(Caption)) div 2 + X1;

	Print(Caption, X1, Y1, FgColor);

	TUIObject.Draw;
end;

procedure TLabel.SetCaption(Cap: string);
begin
	Caption := Cap;
	Include(State, SDirty);
end;


procedure TLabel.SetAlign(Val: TAlign);
begin
	if Align = Val then
		exit;

	Align := Val;
	Include(State, SDirty);
end;

end.