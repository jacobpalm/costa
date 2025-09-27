unit UITXTBOX;

interface

uses
	Costalib, UIArea, Graph, Strings;

type
	PTextbox = ^TTextbox;
	TTextbox = object(TArea)
		public
			Caption,
			Text:       string;
			MaxLen:     Integer;
			OnChange:   TEventProc;
			constructor Init(X, Y, W, H: Integer; Cap: String);
			procedure   CheckEvent; virtual;
			procedure   Edit;
			procedure   Draw; virtual;
	end;

implementation

constructor TTextbox.Init(X, Y, W, H: Integer; Cap: String);
const
	DefaultW = 120;
	DefaultH = 19;
begin
	TUIObject.Init;
	Caption     := Cap;
	Text        := '';
	MaxLen      := 255;
	OnChange    := nil;
	BGColor     := ColorDefault;
	Transparent := False;
	
	if W = SizeDefault then
		W := DefaultW;
	if H = SizeDefault then
		H := DefaultH;
	SetPos(X, Y);
	SetSize(W, H);
end;

procedure TTextbox.CheckEvent;
var
	Clicked: boolean;
begin
	if not GetState(Enabled) then
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
		if Assigned(OnClick) then
			OnClick(@Self);

		{Allow user to edit the text}
		Self.Edit;
	end;
end;

procedure TTextbox.Edit;
var
	OrigTxt, Key: string;
	X1, Y1, Width, Height, CursorX, MaxShow: integer;
begin
	{Get absolute position of the object}
	GetPos(X1, Y1, True);
	GetSize(Width, Height);

	Inc(X1, 5);
	Inc(Y1, 5);
	Y1 := (Height - 7) div 2 + Y1;
	if MaxLen > 255 then MaxLen := 255;
	MaxShow := Width - 10;
	OrigTxt := Text;

	{Redraw the textbox to show the editing state}
	Mouse.Hide;
	AddState(Active);
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
					SetFillStyle(SolidFill, Thm.Txt);
					Bar(CursorX + 2, Y1 - 2, CursorX - 8, Y1 + 11);
					Text := Copy(Text, 1, Length(Text) - 1);
					{Cursor}
					CursorX := X1 + PrintW(Text) + 2;
					SetColor(Thm.TxtText);
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
			RemoveState(Active);
			Mouse.Hide;
			Self.Draw;
			Mouse.Show;
			exit;
		end;

		{Any printable character}
		if (Length(Key) = 1) and (Length(Text) < MaxLen) then
		begin
			if (Ord(Key[1]) < 32) or (Ord(Key[1]) > 126) then
				continue;

			Mouse.Hide;
			if PrintW(Text + Key) + 2 < MaxShow then
			begin
				CursorX := X1 + PrintW(Text) + 2;
				SetColor(Thm.Txt);
				Line(CursorX, Y1 - 1, CursorX, Y1 + 10);
				Text := Text + Key;
				Print(Text, X1, Y1, Thm.TxtText);
				{Cursor}
				CursorX := X1 + PrintW(Text) + 2;
				SetColor(Thm.TxtText);
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

	RemoveState(Active);
	Mouse.Hide;
	if PrintW(Text) + 2 < MaxShow then
	begin
		{Erase only the cursor}
		CursorX := X1 + PrintW(Text) + 2;
		SetColor(Thm.Txt);
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
	X1, Y1, Width, Height, MaxShow: Integer;
	S: string;
begin
	{Draw the textbox border+interior inherited from TArea}
	inherited Draw;

	{Get absolute position and size of the object}
	GetPos(X1, Y1, True);
	GetSize(Width, Height);

	{Draw caption if set}
	if Length(Caption) > 0 then
		Print(Caption, X1, Y1 - 15, Thm.WinText);

	Y1 := (Height - 7) div 2 + Y1;

	{Draw text inside the textbox}
	S := Text;
	if S <> '' then
	begin
		{DEBUG - font is monospaced, so we could optimize this}
		MaxShow := Width - 10;
		while PrintW(S) >= MaxShow do
			Delete(S, 1, 1);
		Print(S, X1 + 5, Y1, Thm.TxtText);
	end;

	if GetState(Active) then
	begin
		{Cursor}
		X1 := X1 + 7 + PrintW(S);
		SetColor(Thm.TxtText);
		Line(X1, Y1 - 1, X1, Y1 + 8);
	end;

	if Assigned(OnDraw) then
		OnDraw(@Self);
end;

end.