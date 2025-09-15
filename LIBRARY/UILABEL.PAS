unit UILABEL;

interface

uses
	Costalib, Graph;

type
	TLabelAlign = (LaLeft, LaCenter, LaRight);

	PLabel = ^TLabel;
	TLabel = object(TUIObject)
		public
			FgColor,
			BgColor:    Byte;
			constructor Init(X, Y, W, H: Integer; Cap: String);
			procedure   AutoSize;
			procedure   Draw; virtual;
			procedure   SetCaption(Cap: string);
		private
			Caption:    String;
	end;

implementation

constructor TLabel.Init(X, Y, W, H: Integer; Cap: String);
const
	DefaultW = 100;
	DefaultH = PrintLineH;
begin
	TUIObject.Init;
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	Caption := Cap;
	FgColor := ColorDefault;
	BgColor := ColorDefault;
end;

procedure TLabel.AutoSize;
begin
	Width := PrintW(Caption);
	Height := PrintH(Caption);
end;

procedure TLabel.Draw;
var
	TextColor, BackColor: Byte;
begin
	{If a background color is set, fill the label area with it}
	if BgColor <= GetMaxColor then
	begin
		SetFillStyle(SolidFill, BgColor);
		Bar(Left, Top, Left + Width, Top + Height);
	end;
	
	{Use FgColor for text if set, otherwise use window color}
	if FGColor > GetMaxColor then
		TextColor := Thm.WinText
	else
		TextColor := FgColor;

	Print(Caption, Left, Top, TextColor);

	if Assigned(OnDraw) then
		OnDraw(@Self);
end;

procedure TLabel.SetCaption(Cap: string);
begin
	Mouse.Hide;
	Caption := Cap;
	Self.Draw;
	Mouse.Show;
end;

end.