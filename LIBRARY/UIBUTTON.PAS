unit UIBUTTON;

interface

uses
	Costalib, Graph;

type
	PButton = ^TButton;
	TButton = object(TUIObject)
		public
			constructor  Init(X, Y: Integer; Cap: string; Parent: PContainer);
			procedure    CheckEvent; virtual;
			procedure    Draw; virtual;

			procedure    SetCaption(Cap: string);
			function     GetCaption: string;
		private
			Caption:     string;
	end;

implementation

constructor TButton.Init(X, Y: Integer; Cap: string; Parent: PContainer);
const
	DefaultW = 92;
	DefaultH = 22;
begin
	TUIObject.Init;
	Caption := Cap;

	SetParent(Parent);
	SetSize(DefaultW, DefaultH);
	SetPos(X, Y);
end;

procedure TButton.CheckEvent;
var
	Clicked: boolean;
begin
	{Don't check for events if object is disabled or hidden}
	if not GetState(SEnabled) or GetState(SHidden) then
		exit;

	Clicked := False;
	{Check for left click, while drawing button pressed while mouse is down and over
	 the button}
	if (Mouse.Clicked = MbLeft) and Self.IsMouseOver then
	begin
		Mouse.Hide;
		AddState(SActive);
		Self.Draw;
		Mouse.Show;
		repeat
			if Self.IsMouseOver then
			begin
				{Mouse over button, show pressed state if not already shown}
				if not GetState(SActive) then
				begin
					AddState(SActive);
					Mouse.Hide;
					Self.Draw;
					Mouse.Show;
				end;
			end
			else
			begin
				{Mouse not over button, show unpressed state if not already shown}
				if GetState(SActive) then
				begin
					RemoveState(SActive);
					Mouse.Hide;
					Self.Draw;
					Mouse.Show;
				end;
			end;
		until Mouse.Clicked = MbNone;

		if GetState(SActive) then
		begin
			RemoveState(SActive);
			Mouse.Hide;
			Self.Draw;
			Mouse.Show;
		end;
		if Self.IsMouseOver then
		begin
			{Mouse was both clicked and released over the button, trigger OnClick event}
			Clicked := True;
		end;
	end;

	if Clicked or Self.HotkeyPressed then
		{Trigger OnClick event, if assigned}
		Self.Click;
end;

procedure TButton.Draw;
var
	X1, X2, Y1, Y2: Integer;
	FgColor, BgColor: Byte;
	TLColor1, TLColor2, BRColor1, BRColor2: Byte; {TL = top+left, BR = bottom+right}
begin
	if GetState(SHidden) then
		exit;

	{Get absolute position and size of the object}
	GetPos(X1, Y1, True);
	GetSize(X2, Y2);
	Inc(X2, X1);
	Inc(Y2, Y1);

	{Get colors}
	FgColor := GetFGColor;
	BgColor := GetBGColor;

	{Interior}
	If Not GetState(STransparent) Then
	Begin
		if BgColor = ColorDefault then
			BgColor := Thm.Btn;
		SetFillStyle(SolidFill, BgColor);
		Bar(X1 + 2, Y1 + 2, X2 - 2, Y2 - 2);
	End;

	{Invert border colors if pressed down}
	if not GetState(SActive) then
	begin
		{Button is up}
		TLColor1 := White;
		TLColor2 := Thm.Light;
		BRColor1 := Black;
		BRColor2 := Thm.Shadow;
	end
	else
	begin
		{Button is down}
		TLColor1 := Black;
		TLColor2 := Thm.Shadow;
		BRColor1 := White;
		BRColor2 := Thm.Light;
	end;

	{Top + left outer border}
	SetColor(TLColor1);
	Line(X1, Y1, X2, Y1);
	Line(X1, Y1 + 1, X1, Y2);
	{Inner border}
	SetColor(TLColor2);
	Line(X1 + 1, Y1 + 1, X2 - 1, Y1 + 1);
	Line (X1 + 1, Y1 + 2, X1 + 1, Y2 - 1);

	{Bottom + right outer border}
	SetColor(BRColor1);
	Line(X2, Y1 + 1, X2, Y2);
	Line(X1 + 1, Y2, X2 - 1, Y2);
	{Inner border}
	SetColor(BRColor2);
	Line(X2 - 1, Y1 + 2, X2 - 1, Y2 - 1);
	Line(X1 + 2, Y2 - 1, X2 - 2, Y2 - 1);

	if Caption <> '' then
	begin
		X1 := (X2 - X1) div 2 + X1;
		X1 := X1 - PrintW(Caption) div 2;
		Y1 := (Y2 - Y1) div 2 + Y1 - 4; {4 is the offset to center text vertically}

		if FgColor = ColorDefault then
			FgColor := Thm.WinText;

		{If button is pressed, move text 1 pixel down and right}
		if GetState(SActive) then
		begin
			Inc(X1);
			Inc(Y1);
		end;
		Print(Caption, X1, Y1, FgColor);
	end;

	TUIObject.Draw;
end;

procedure TButton.SetCaption(Cap: string);
begin
	Caption := Cap;
	Self.Draw;
end;

function TButton.GetCaption: string;
begin
	GetCaption := Caption;
end;

end.