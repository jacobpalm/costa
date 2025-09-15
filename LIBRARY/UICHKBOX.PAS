unit UICHKBOX;

interface

uses
	Costalib, Graph;

type
	PCheckbox = ^TCheckbox;
	TCheckbox = object(TUIObject)
		public
			Caption:    string;
			OnChange:   TEventProc;
			constructor Init(X, Y: Integer; Cap: String; Checked: Boolean);
			procedure   CheckEvent; virtual;
			function    GetChecked: boolean;
			procedure   SetChecked(Checked: boolean);
			procedure   Draw; virtual;
		private
			ChkState:   boolean;
	end;

implementation

constructor TCheckbox.Init(X, Y: Integer; Cap: String; Checked: Boolean);
const
	DefaultW = 15;
	DefaultH = 15;
begin
	TUIObject.Init;
	Self.SetSize(X, Y, DefaultW, DefaultH, DefaultW, DefaultH);
	Caption := Cap;
	ChkState := Checked;
	OnChange := nil;
end;

procedure TCheckbox.Draw;
var
	X1, X2, Y1, Y2, ChkColor: Integer;
begin
	X1 := Left;
	Y1 := Top;
	X2 := X1 + 15;
	Y2 := Y1 + 15;

	{Interior}
	SetFillStyle(SolidFill, Thm.Txt);
	Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);

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

	if ChkState then
	begin
		SetColor(Thm.TxtText);
		Line(X1 + 5, Y1 + 8, X1 + 7, Y1 + 10);
		Line(X1 + 5, Y1 + 9, X1 + 7, Y1 + 11);
		Line(X1 + 8, Y1 + 9, X1 + 11, Y1 + 6);
		Line(X1 + 8, Y1 + 10, X1 + 11, Y1 + 7);
		SetColor(Thm.Shadow);
		Line(X1 + 5, Y1 + 7, X1 + 7, Y1 + 9);
		Line(X1 + 8, Y1 + 8, X1 + 11, Y1 + 5);
		SetColor(Thm.Light);
		Line(X1 + 5, Y1 + 10, X1 + 6, Y1 + 11);
		Line(X1 + 8, Y1 + 11, X1 + 11, Y1 + 8);
	end;
	if Length(Caption) > 0 then
		Print (Caption, X1 + 22, Y1 + 4, Thm.WinText);

	if Assigned(OnDraw) then
		OnDraw(@Self);
end;

procedure TCheckbox.CheckEvent;
var
	Clicked: boolean;
begin
	if not Enabled then
		exit;

	Clicked := False;
	
	{Check if mouse is clicked on the object}
	if (Mouse.Clicked = MbLeft) and Self.IsMouseOver then
	begin
		repeat;	until Mouse.Clicked = MbNone;
		{If mouse was released over the object, toggle the checkbox state}
		if Self.IsMouseOver then
		begin
			Clicked := True;
		end;
	end;

	if Clicked or Self.HotkeyPressed then
	begin
		{Toggle checkbox state}
		Self.SetChecked(not ChkState);

		{Trigger OnClick event, if assigned}
		if Assigned(OnClick) then
			OnClick(@Self);
	end;
end;

function TCheckbox.GetChecked: boolean;
begin
	GetChecked := ChkState;
end;

procedure TCheckbox.SetChecked(Checked: boolean);
begin
	if ChkState <> Checked then
	begin
		ChkState := Checked;
		Mouse.Hide;
		Self.Draw;
		Mouse.Show;
		if Assigned(OnChange) then
			OnChange(@Self);
	end;
end;

end.