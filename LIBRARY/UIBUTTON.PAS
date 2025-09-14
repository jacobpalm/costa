unit UIBUTTON;

interface

uses
	Costalib, Graph;

type
	TButtonState  = (BsUp, BsDown);
	
	TButton = object(TUIObject)
		public
			Transparent: Boolean;
			State:       TButtonState;
			constructor  Init(X, Y, W, H: Integer; Cap: string);
			procedure    CheckEvent; virtual;
			procedure    Draw; virtual;
			procedure    SetCaption(Cap: string);
		private
			Caption:     string;
	end;

implementation

constructor TButton.Init(X, Y, W, H: Integer; Cap: string);
const
	DefaultW = 92;
	DefaultH = 22;
begin
	TUIObject.Init;
	SetSize(X, Y, W, H, DefaultW, DefaultH);
	Caption := Cap;
	State := BsUp;
	Enabled := True;
	Transparent := False;
end;

procedure TButton.CheckEvent;
begin
	if not Enabled then
		exit;
	
	{Check for left click, while drawing button pressed while mouse is down and over
	 the button}
	if (Mouse.Clicked = MbLeft) and Self.IsMouseOver then
	begin
		Mouse.Hide;
		State := BsDown;
		Self.Draw;
		Mouse.Show;
		repeat
			if Self.IsMouseOver then
			begin
				if State = BsUp then
				begin
					State := BsDown;
					Mouse.Hide;
					Self.Draw;
					Mouse.Show;
				end;
			end
			else
			begin
				if State = BsDown then
				begin
					State := BsUp;
					Mouse.Hide;
					Self.Draw;
					Mouse.Show;
				end;
			end;
		until Mouse.Clicked = MbNone;

		if State = BsDown then
		begin
			State := BsUp;
			Mouse.Hide;
			Self.Draw;
			Mouse.Show;
		end;
		if Self.IsMouseOver then
		begin
			{Mouse was both clicked and released over the button, trigger OnClick event}
			if Assigned(OnClick) then
				OnClick(@Self);
			exit;
		end;
	end;

	Self.CheckHotkeys;
end;

procedure TButton.Draw;
var
	X1, X2, Y1, Y2: Integer;
	TLColor1, TLColor2, BRColor1, BRColor2: Byte; {TL = top+left, BR = bottom+right}
begin
	X1 := Left;
	Y1 := Top;
	X2 := X1 + Width;
	Y2 := Y1 + Height;

	{Interior}
	If Not Transparent Then
	Begin
		SetFillStyle(SolidFill, Thm.Btn);
		Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
	End;
	
	{Invert border colors if pressed down}
	if State = BsUp then
	begin
		TLColor1 := White;
		TLColor2 := Thm.Light;
		BRColor1 := Black;
		BRColor2 := Thm.Shadow;
	end
	else
	begin
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
		if State = BsDown then
		begin
			Inc(X1);
			Inc(Y1);
		end;
		Print(Caption, X1, Y1, Thm.WinText);
	end;

	if Assigned(OnDraw) then
		OnDraw(@Self);
end;

procedure TButton.SetCaption(Cap: string);
begin
	Caption := Cap;
	Self.Draw;
end;

end.