unit UICHKBOX;

interface

uses
	Costalib, Graph;

type
	PCheckbox = ^TCheckbox;
	TCheckbox = object(TUIObject)
		public
			OnChange:   TEventProc;
			Caption:    string;

			constructor Init(X, Y: Integer; Cap: String; Checked: Boolean; Parent: PContainer);
			procedure   CheckEvent; virtual;
			procedure   Draw; virtual;

			procedure   SetCaption(Cap: string);

			function    GetChecked: boolean;
			procedure   SetChecked(Checked: boolean);
		private
	end;

implementation

constructor TCheckbox.Init(X, Y: Integer; Cap: String; Checked: Boolean; Parent: PContainer);
const
	DefaultW = 15;
	DefaultH = 15;
begin
	TUIObject.Init;
	Caption := Cap;
	OnChange := nil;
	Left := X;
	Top := Y;
	Width := DefaultW;
	Height := DefaultH;
	SetParent(Parent);

	If Checked then
		Include(State, SSelected);
end;

procedure TCheckbox.Draw;
var
	X1, X2, Y1, Y2, ChkColor: Integer;
	FgColor, BgColor: Byte;
begin
	if SHidden in State then
		exit;

	{Get absolute position and size of the object}
	GetPos(X1, Y1, True);
	X2 := X1 + Width;
	Y2 := Y1 + Height;

	{Get colors}
	FgColor := GetFgColor;
	BgColor := GetBgColor;

	if FgColor = ColorDefault then
		FgColor := Thm.TxtText;
	if BgColor = ColorDefault then
		BgColor := Thm.Txt;

	DrawUIPrimitive(UIBorderDown, X1, Y1, X2, Y2, BgColor, False);

	if SSelected in State then
	begin
		SetColor(FgColor);
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

	TUIObject.Draw;
end;

procedure TCheckbox.CheckEvent;
var
	Clicked: boolean;
begin
	{Don't check for events if object is disabled or hidden}
	if not (SEnabled in State) or (SHidden in State) then
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
		Self.SetChecked(not (SSelected in State));

		{Trigger OnClick event, if assigned}
		Self.Click;
	end;
end;

procedure TCheckbox.SetCaption(Cap: string);
begin
	Caption := Cap;
	AddState(SDirty);
end;

function TCheckbox.GetChecked: boolean;
begin
	GetChecked := SSelected in State;
end;

procedure TCheckbox.SetChecked(Checked: boolean);
begin
	if Checked = (SSelected in State) then
		exit;

	if Checked then
		AddState(SSelected)
	else
		RemoveState(SSelected);

	if Assigned(OnChange) then
		OnChange(@Self);
end;

end.