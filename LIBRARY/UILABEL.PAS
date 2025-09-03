unit UILABEL;

interface

uses
	Costalib;

type
	TLabel = object(TUIObject)
		Caption: String;
		constructor Init(X, Y, W, H: Integer; Cap: String);
		procedure Draw;
	end;

implementation

constructor TLabel.Init(X, Y, W, H: Integer; Cap: String);
const
	DefaultW = 100;
	DefaultH = PrintLineH;
begin
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	Caption := Cap;
end;

procedure TLabel.Draw;
begin
	Print(Caption, Left, Top, Thm.WinText);
end;

end.