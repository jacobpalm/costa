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
	Caption     := Cap;
	Align       := AlLeft;
	Left        := X;
	Top         := Y;
	Width       := DefaultW;
	Height      := DefaultH;
	Transparent := true;
	FgColor     := Thm.WinText;
	BgColor     := Thm.Win;
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
begin
	if SHidden in State then
		exit;

	DrawBorder;

	if Length(Self.Caption) > 0 then
	begin
		GetAbsPos(X1, Y1);
		if Align = AlRight then
			X1 := X1 + Self.Width - PrintW(Caption);

		if Align = AlCenter then
			X1 := (Self.Width - PrintW(Caption)) div 2 + X1;

		Print(Caption, X1, Y1, FGColor);
	end;

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