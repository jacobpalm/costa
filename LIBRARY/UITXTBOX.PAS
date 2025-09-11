unit UITXTBOX;

interface

uses
	Costalib, Graph, Strings;

type
	TTextboxState = (TsNormal, TsEditing);

	TTextbox = object(TUIObject)
		public
			Caption,
			Text:       string;
			MaxLen:     Integer;
			OnChange:   TEventProc;
			constructor Init(X, Y, W, H: Integer; Cap: String);
			procedure   CheckEvent; virtual;
			procedure   CheckHotkeys; virtual;
			procedure   Edit;
			procedure   Draw; virtual;
		private
			State:      TTextboxState;
	end;

implementation

constructor TTextbox.Init(X, Y, W, H: Integer; Cap: String);
const
	DefaultW = 120;
	DefaultH = 19;
begin
	TUIObject.Init;
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	Caption := Cap;
	MaxLen := 255;
	State := TsNormal;
	Text := '';
	OnChange := nil;
end;

procedure TTextbox.CheckEvent;
begin
	{Check if mouse is clicked on the object}
	if (MouseClicked = MbLeft) and Self.IsMouseOver then
	begin
		repeat;	until MouseClicked = MbNone;
		{Check if mouse is still over the object after release}
		if Self.IsMouseOver then
		begin
			{Trigger OnClick event, if assigned}
			if Assigned(OnClick) then
				OnClick(@Self);

			{Allow user to edit the text}
			Self.Edit;
			exit;
		end;
	end;

	Self.CheckHotkeys;
end;

procedure TTextbox.CheckHotkeys;
var
	CheckNode: PHotKeyNode;
begin
	if (Length(HotkeyPressed) > 0) then
	begin
		CheckNode := Hotkey;
		while Assigned(CheckNode) do
		begin
			if CheckNode^.HotKey = HotkeyPressed then
			begin
				HotkeyPressed := ''; {Reset hotkey}
				Self.Edit;
				exit;
			end;
			CheckNode := CheckNode^.Next; {Move to next node in linked list}
		end;
	end;
end;

procedure TTextbox.Edit;
var
	OrigTxt, Key: string;
	X1, Y1, CursorX, MaxShow: integer;
begin
	X1 := Left + 5;
	Y1 := Top + 5;
	if MaxLen > 255 then MaxLen := 255;
	MaxShow := Width - 10;
	OrigTxt := Text;

	{Redraw the textbox to show the editing state}
	MouseHide;
	State := TsEditing;
	Self.Draw;
	MouseShow;

	ClearInputBuffer;
	repeat
		Key := GetKey;

		{If mouse is clicked outside the textbox, stop editing}
		if (MouseClicked > MbNone) and not Self.IsMouseOver then
			break;
		
		if Key = KeyBackspace then
		begin
			if Length(Text) > 0 then
			begin
				MouseHide;
				if PrintW(Text) + 2 < MaxShow then
				begin
					{Erase only the last char}
					CursorX := X1 + PrintW(Text);
					SetFillStyle(SolidFill, Thm.Txt);
					Bar(CursorX + 2, Y1 - 2, CursorX - 8, Y1 + 11);
					Text := Copy(Text, 1, Length(Text) - 1);
					CursorX := X1 + PrintW(Text) + 2;
					SetColor(Thm.TxtText);
					Line(CursorX, Y1 - 1, CursorX, Y1 + 10);
				end
				else
				begin
					{There's more text that's not shown, so we'll have to redraw the entire textbox}
					Text := Copy(Text, 1, Length(Text) - 1);
					Self.Draw;
				end;
				MouseShow;
			end;
		end;

		If Key = KeyEnter then
			break;

		if Key = KeyEscape then
		begin
			Text := OrigTxt;
			State := TsNormal;
			MouseHide;
			Self.Draw;
			MouseShow;
			exit;
		end;

		{Any printable character}
		if (Length(Key) = 1) and (Length(Text) < MaxLen) then
		begin
			if (Ord(Key[1]) < 32) or (Ord(Key[1]) > 126) then
				continue;

			MouseHide;
			if PrintW(Text + Key) + 2 < MaxShow then
			begin
				CursorX := X1 + PrintW(Text) + 2;
				SetColor(Thm.Txt);
				Line(CursorX, Y1 - 1, CursorX, Y1 + 10);
				Text := Text + Key;
				Print(Text, X1, Y1, Thm.TxtText);
				CursorX := X1 + PrintW(Text) + 2;
				SetColor(Thm.TxtText);
				Line(CursorX, Y1 - 1, CursorX, Y1 + 10);
			end
			else
			begin
				Text := Text + Key;
				Self.Draw;
			end;
			MouseShow;
		end;

	until False;

	State := TsNormal;
	MouseHide;
	if PrintW(Text) + 2 < MaxShow then
	begin
		{Erase only the cursor}
		CursorX := X1 + PrintW(Text) + 2;
		SetColor(Thm.Txt);
		Line(CursorX, Y1 - 1, CursorX, Y1 + 10);
	end
	else
		{There's more text than fits, so we'll have to redraw the entire textbox}
		Self.Draw;
	MouseShow;
	ClearInputBuffer;

	If Text <> OrigTxt then
		if Assigned(OnChange) then
			OnChange(@Self);
end;

procedure TTextbox.Draw;
var
	X1, X2, Y1, Y2, MaxShow: Integer;
	S: string;
begin
	X1 := Left;
	Y1 := Top;
	X2 := X1 + Width;
	Y2 := Y1 + Height;

	{Interior}
	SetFillStyle(SolidFill, Thm.Txt);
	Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);

	{Top + left border}
	SetColor(Thm.Shadow);
	Line(X1, Y1, X2, Y1);
	Line(X1, Y1 + 1, X1, Y2);
	SetColor(Black);
	Line(X1 + 1, Y1 + 1, X2 - 1, Y1 + 1);
	Line (X1 + 1, Y1 + 2, X1 + 1, Y2 - 1);

	{Bottom + right border}
	SetColor(White);
	Line(X2, Y1 + 1, X2, Y2);
	Line(X1 + 1, Y2, X2 - 1, Y2);
	SetColor(Thm.Light);
	Line(X2 - 1, Y1 + 2, X2 - 1, Y2 - 1);
	Line(X1 + 2, Y2 - 1, X2 - 2, Y2 - 1);

	{Draw caption if set}
	if Length(Caption) > 0 then
	Print(Caption, X1, Y1 - 15, Thm.WinText);

	{Draw text inside the textbox}
	S := Text;
	if S <> '' then
	begin
		MaxShow := Width - 10;
		while PrintW(S) >= MaxShow do
			Delete(S, 1, 1);
		Print(S, X1 + 5, Y1 + 5, Thm.TxtText);
	end;
	if State = TsEditing then
	begin
		X1 := X1 + 7 + PrintW(S);
		Line(X1, Y1 + 4, X1, Y1 + 15);
	end;

	if Assigned(OnDraw) then
		OnDraw(@Self);
end;

end.