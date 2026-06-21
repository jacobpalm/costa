unit UICHKBOX;

interface

uses
	Costalib, Graph;

type
	PCheckbox = ^TCheckbox;
	TCheckbox = object(TUIObject)
		public
			constructor Init(X, Y: Integer; Cap: String; Checked: Boolean; Parent: PContainer);
			procedure   CheckEvent; virtual;
			procedure   Draw; virtual;

			procedure   SetCaption(Cap: string);
			function    GetCaption: string;

			function    GetChecked: boolean;
			procedure   SetChecked(Checked: boolean);

			procedure   SetOnChange(Proc: TEventProc);
		private
			Caption:    string;
			OnChange:   TEventProc;
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
	If Checked then
		AddState(SSelected);

	SetParent(Parent);
	SetSize(DefaultW, DefaultH);
	SetPos(X, Y);
end;

procedure TCheckbox.Draw;
var
	X1, X2, Y1, Y2, ChkColor: Integer;
	FgColor, BgColor: Byte;
begin
	if GetState(SHidden) then
		exit;

	{Get absolute position and size of the object}
	GetPos(X1, Y1, True);
	GetSize(X2, Y2);
	Inc(X2, X1);
	Inc(Y2, Y1);

	{Get colors}
	FgColor := GetFgColor;
	BgColor := GetBgColor;

	if FgColor = ColorDefault then
		FgColor := Thm.TxtText;
	if BgColor = ColorDefault then
		BgColor := Thm.Txt;

	DrawUIPrimitive(UIBorderDown, X1, Y1, X2, Y2, BgColor, False);

	if GetState(SSelected) then
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
	if not GetState(SEnabled) or GetState(SHidden) then
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
		Self.SetChecked(not GetState(SSelected));

		{Trigger OnClick event, if assigned}
		Self.Click;
	end;
end;

procedure TCheckbox.SetCaption(Cap: string);
begin
	Caption := Cap;
	AddState(SDirty);
end;

function TCheckbox.GetCaption: string;
begin
	GetCaption := Caption;
end;

function TCheckbox.GetChecked: boolean;
begin
	GetChecked := GetState(SSelected);
end;

procedure TCheckbox.SetChecked(Checked: boolean);
begin
	if Checked = GetState(SSelected) then
		exit;

	if Checked then
		AddState(SSelected)
	else
		RemoveState(SSelected);

	AddState(SDirty);

	if Assigned(OnChange) then
		OnChange(@Self);
end;

procedure TCheckbox.SetOnChange(Proc: TEventProc);
begin
	OnChange := Proc;
end;

end.