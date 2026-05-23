unit UILABEL;

interface

uses
	Costalib, Graph;

type
	PLabel = ^TLabel;
	TLabel = object(TUIObject)
		public
			constructor Init(X, Y: Integer; Cap: String; Parent: PContainer);
			procedure   Draw; virtual;
			procedure   AutoSize;

			procedure   SetCaption(Cap: string);
			function    GetCaption: string;

			procedure   SetAlign(Val: TAlign);
			function    GetAlign: TAlign;
		private
			Caption:    String;
			Align:      TAlign;
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

	AddState(STransparent);
	SetParent(Parent);
	SetPos(X, Y);
	SetSize(DefaultW, DefaultH);
end;

procedure TLabel.AutoSize;
begin
	SetSize(PrintW(Caption), PrintH(Caption));
	AddState(SDirty);
end;

procedure TLabel.Draw;
var
	X1, Y1, X2, Y2: Integer;
	FGColor, BgColor: Byte;
begin
	if GetState(SHidden) then
		exit;

	{Get absolute position and size of the object}
	GetPos(X1, Y1, True);
	GetSize(X2, Y2);
	Inc(X2, X1);
	Inc(Y2, Y1);

	FGColor := GetFGColor;
	BgColor := GetBGColor;

	{If a background color is set, fill the label area with it}
	if not GetState(STransparent) then
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
	AddState(SDirty);
end;

function TLabel.GetCaption: string;
begin
	GetCaption := Caption;
end;

procedure TLabel.SetAlign(Val: TAlign);
begin
	Align := Val;
	AddState(SDirty);
end;

function TLabel.GetAlign: TAlign;
begin
	GetAlign := Align;
end;

end.