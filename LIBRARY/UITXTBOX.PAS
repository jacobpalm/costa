unit UITXTBOX;

interface

uses
	Costalib, Graph;

type
	PTextbox = ^TTextbox;
	TTextbox = object(TUIObject)
		public
			OnChange:   TEventProc;
			Caption,
			Text:       String;
			MaxLength:  Byte;

			constructor Init(X, Y: Integer; Cap: String; Parent: PContainer);
			procedure   CheckEvent; virtual;
			procedure   Draw; virtual;

			procedure   Edit;

			procedure   SetCaption(Cap: string);

			procedure   SetText(Txt: string);
			procedure   SetMaxLength(Len: Byte);
	end;

implementation

constructor TTextbox.Init(X, Y: Integer; Cap: String; Parent: PContainer);
const
	DefaultW = 120;
	DefaultH = 19;
begin
	TUIObject.Init;
	Caption     := Cap;
	Text        := '';
	MaxLength   := 255;
	OnChange    := nil;
	Left        := X;
	Top         := Y;
	Width       := DefaultW;
	Height      := DefaultH;

	SetParent(Parent);
end;

procedure TTextbox.CheckEvent;
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
		{Check if mouse is still over the object after release}
		if Self.IsMouseOver then
		begin
			Clicked := True;
		end;
	end;

	if Clicked or Self.HotkeyPressed then
	begin
		{Trigger OnClick event, if assigned}
		Self.Click;

		{Allow user to edit the text}
		Self.Edit;
	end;
end;

procedure TTextbox.Edit;
var
	OrigTxt, Key: string;
	X1, Y1, CursorX, MaxShow: integer;
	BgColor, FgColor: Byte;
begin
	{Get absolute position of the object}
	GetAbsPos(X1, Y1);

	{Text is located 5 pixels from the left border, and vertically centered}
	Inc(X1, 5);
	Y1 := (Height - 7) div 2 + Y1;

	FgColor := GetFgColor;
	if FGColor = ColorDefault then
		FGColor := Thm.TxtText;
	BgColor := GetBgColor;
	if BgColor = ColorDefault then
		BgColor := Thm.Txt;

	MaxShow := Width - 10;
	OrigTxt := Text;

	{Redraw the textbox to show the editing state}
	Mouse.Hide;
	Include(State, SActive);
	Self.Draw;
	Mouse.Show;

	ClearInputBuffer;
	repeat
		Key := GetKey;

		{If mouse is clicked outside the textbox, stop editing}
		if (Mouse.Clicked > MbNone) and not Self.IsMouseOver then
			break;

		if Key = KeyBackspace then
		begin
			if Length(Text) > 0 then
			begin
				Mouse.Hide;
				if PrintW(Text) + 2 < MaxShow then
				begin
					{Erase only the last char}
					CursorX := X1 + PrintW(Text);
					SetFillStyle(SolidFill, BgColor);
					Bar(CursorX + 2, Y1 - 2, CursorX - 8, Y1 + 11);
					Text := Copy(Text, 1, Length(Text) - 1);
					{Cursor}
					CursorX := X1 + PrintW(Text) + 2;
					SetColor(FgColor);
					Line(CursorX, Y1 - 1, CursorX, Y1 + 8);
				end
				else
				begin
					{There's more text that's not shown, so we'll have to redraw the entire textbox}
					Text := Copy(Text, 1, Length(Text) - 1);
					Self.Draw;
				end;
				Mouse.Show;
			end;
		end;

		If Key = KeyEnter then
			break;

		if Key = KeyEscape then
		begin
			Text := OrigTxt;
			Exclude(State, SActive);
			Mouse.Hide;
			Self.Draw;
			Mouse.Show;
			exit;
		end;

		{Any printable character}
		if (Length(Key) = 1) and (Length(Text) < MaxLength) then
		begin
			if (Ord(Key[1]) < 32) or (Ord(Key[1]) > 126) then
				continue;

			Mouse.Hide;
			if PrintW(Text + Key) + 2 < MaxShow then
			begin
				{Erase only the cursor}
				CursorX := X1 + PrintW(Text) + 2;
				SetColor(BgColor);
				Line(CursorX, Y1 - 1, CursorX, Y1 + 8);
				{Print new text}
				Text := Text + Key;
				Print(Text, X1, Y1, FgColor);
				{Cursor}
				CursorX := X1 + PrintW(Text) + 2;
				SetColor(FgColor);
				Line(CursorX, Y1 - 1, CursorX, Y1 + 8);
			end
			else
			begin
				Text := Text + Key;
				Self.Draw;
			end;
			Mouse.Show;
		end;

	until False;

	Exclude(State, SActive);
	Mouse.Hide;
	if PrintW(Text) + 2 < MaxShow then
	begin
		{Erase only the cursor}
		CursorX := X1 + PrintW(Text) + 2;
		SetColor(BgColor);
		Line(CursorX, Y1 - 1, CursorX, Y1 + 8);
	end
	else
		{There's more text than fits, so we'll have to redraw the entire textbox}
		Self.Draw;
	Mouse.Show;
	ClearInputBuffer;

	If Text <> OrigTxt then
		if Assigned(OnChange) then
			OnChange(@Self);
end;

procedure TTextbox.Draw;
var
	X1, Y1, MaxShow: Integer;
	S: string;
	FgColor, BGColor: Byte;
begin
	if SHidden in State then
		exit;

	{Get absolute position and size of the object}
	GetAbsPos(X1, Y1);

	{Draw caption if set}
	if Length(Caption) > 0 then
		Print(Caption, X1, Y1 - 15, Thm.WinText);

	FGColor := GetFgColor;
	if FGColor = ColorDefault then
		FGColor := Thm.TxtText;
	BGColor := GetBgColor;
	if BGColor = ColorDefault then
		BGColor := Thm.Txt;

	DrawUIPrimitive(UIBorderDown, X1, Y1, Self.Width, Self.Height, BGColor, (STransparent in State));

	{Draw text inside the textbox}
	Y1 := (Height - 7) div 2 + Y1; {Centered vertically}
	S := Text;
	if S <> '' then
	begin
		{DEBUG - font is monospaced, so we could optimize this}
		MaxShow := Width - 10;
		while PrintW(S) >= MaxShow do
			Delete(S, 1, 1);
		Print(S, X1 + 5, Y1, FGColor);
	end;

	if SActive in State then
	begin
		{Cursor}
		X1 := X1 + 7 + PrintW(S);
		SetColor(FGColor);
		Line(X1, Y1 - 1, X1, Y1 + 8);
	end;

	TUIObject.Draw;
end;

procedure TTextbox.SetCaption(Cap: string);
begin
	Caption := Cap;
	Include(State, SDirty);
end;


procedure TTextbox.SetText(Txt: string);
begin
	Text := Txt;
	Include(State, SDirty);
	if Assigned(OnChange) then
		OnChange(@Self);
end;

procedure TTextbox.SetMaxLength(Len: Byte);
begin
	MaxLength := Len;

	{If current text is longer than new max, trim it and trigger redraw}
	if Length(Text) > MaxLength then
	begin
		Text := Copy(Text, 1, MaxLength);
		Include(State, SDirty);
	end;
end;

end.