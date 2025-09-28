unit UILABEL;

interface

uses
	Costalib, Graph;

type
	PLabel = ^TLabel;
	TLabel = object(TUIObject)
		public
			FgColor,
			BgColor:    Byte;
			constructor Init(X, Y: Integer; Cap: String; Parent: PContainer);
			procedure   AutoSize;
			procedure   Draw; virtual;
			procedure   SetCaption(Cap: string);
		private
			Caption:    String;
	end;

implementation

constructor TLabel.Init(X, Y: Integer; Cap: String; Parent: PContainer);
const
	DefaultW = 100;
	DefaultH = PrintLineH;
begin
	TUIObject.Init;
	Caption := Cap;
	FgColor := ColorDefault;
	BgColor := ColorDefault;
	
	SetParent(Parent);
	SetPos(X, Y);
	SetSize(DefaultW, DefaultH);
end;

procedure TLabel.AutoSize;
begin
	SetSize(PrintW(Caption), PrintH(Caption));
end;

procedure TLabel.Draw;
var
	X1, Y1, X2, Y2: Integer;
	TextColor, BackColor: Byte;
begin
	{Get absolute position and size of the object}
	GetPos(X1, Y1, True);
	GetSize(X2, Y2);
	Inc(X2, X1);
	Inc(Y2, Y1);

	{If a background color is set, fill the label area with it}
	if BgColor <= GetMaxColor then
	begin
		SetFillStyle(SolidFill, BgColor);
		Bar(X1, Y1, X2, Y2);
	end;
	
	{Use FgColor for text if set, otherwise use window color}
	if FGColor > GetMaxColor then
		TextColor := Thm.WinText
	else
		TextColor := FgColor;

	Print(Caption, X1, Y1, TextColor);

	TUIObject.Draw;
end;

procedure TLabel.SetCaption(Cap: string);
begin
	Mouse.Hide;
	Caption := Cap;
	Self.Draw;
	Mouse.Show;
end;

end.