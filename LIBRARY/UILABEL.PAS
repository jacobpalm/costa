unit UILABEL;

interface

uses
	Costalib, Graph;

type
	PLabel = ^TLabel;
	TLabel = object(TUIObject)
		public
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
	
	AddState(STransparent);
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
	Print(Caption, X1, Y1, FgColor);

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