
unit Inputbox;

interface

uses
	Costalib, Strings, Graph, Crt;

function SysInputBox(msgTitle, msgText, msgIcon, msgDefault: string): string;

implementation

function SysInputBox(msgTitle, msgText, msgIcon, msgDefault: string): string;
var
	msgLines: array[1..16] of string;
	msgLineCount, msgTextWidth, i, P: Integer;
	winInputBox: TWindow;
	txtInput: TTextbox;
	btnOK, btnCancel: TButton;
	imgIcon: TIcon;
	Key: String;
	S: string;
	x1, y1, x2, y2, WindowWidth: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
begin
	S := msgText;
	if (S <> '') and (S[Length(S)] = NewLine) then
		Delete(S, Length(S), 1);
	msgLineCount := 0;
	msgTextWidth := 0;
	repeat
		P := Pos(NewLine, S);
		if P = 0 then
		begin
			Inc(msgLineCount);
			msgLines[msgLineCount] := S;
			if FontGetWidth(S) > msgTextWidth then
				msgTextWidth := FontGetWidth(S);
			Break;
		end
		else
		begin
			Inc(msgLineCount);
			msgLines[msgLineCount] := Copy(S, 1, P-1);
			if FontGetWidth(msgLines[msgLineCount]) > msgTextWidth then
				msgTextWidth := FontGetWidth(msgLines[msgLineCount]);
			Delete(S, 1, P);
		end;
	until S = '';

	WindowWidth := msgTextWidth + 76;
	if WindowWidth < 194 then
		WindowWidth := 194;
	winInputBox.Init(sizeCenter, sizeCenter, WindowWidth, msgLineCount * 15 + 120);
	txtInput.Init(winInputBox.Left + 12, winInputBox.Top + 56 + (15 * msgLineCount), winInputBox.Width - 24, 22);
	btnOK.Init(winInputBox.Left + winInputBox.Width - 182, txtInput.Top + 30, 80, sizeDefault, HotkeySymbol + 'OK');
	btnCancel.Init(winInputBox.Left + winInputBox.Width - 92, btnOK.Top, 80, sizeDefault, HotkeySymbol + 'Cancel');
	txtInput.Text := msgDefault;

	if Length(msgIcon) > 0 then
	begin
		imgIcon.Init(winInputBox.Left + 12, winInputBox.Top + 15, msgIcon);
		if msgLineCount > 1 then
			Inc(imgIcon.Top, 5);
	end;

	MouseHide;
	x1 := winInputBox.Left;
	y1 := winInputBox.Top;
	x2 := winInputBox.Left + winInputBox.Width;
	y2 := winInputBox.Top + winInputBox.Height;
	BackgroundSize := ImageSize(x1, y1, x2, y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(x1, y1, x2, y2, BackgroundP^);

	winInputBox.Draw;
	btnOK.Draw;
	btnCancel.Draw;
	txtInput.Draw;

	if Length(msgIcon) > 0 then
		Print(msgTitle, winInputBox.Left + 53, winInputBox.Top + 15, Theme.WindowText)
	else
		Print(msgTitle, winInputBox.Left + 12, winInputBox.Top + 15, Theme.WindowText);

	y2 := winInputBox.Top + 17;
	for i := 1 to msgLineCount do
	begin
		if (i < 3) and (Length(msgIcon) > 0) then
				Print(msgLines[i], winInputBox.Left + 53, y2 + (15 * i), Theme.WindowText)
			else
				Print(msgLines[i], winInputBox.Left + 12, y2 + (15 * i), Theme.WindowText);
	end;
		

	Print('I' + HotkeySymbol + 'nput:', txtInput.Left, txtInput.Top - 16, Theme.WindowText);

	if Length(msgIcon) > 0 then
		imgIcon.Draw;

	MouseShow;

	repeat
		Key := GetKey;

		if ObjBtnClick(btnOK) or (Key = KeyAltO) or (Key = KeyEnter) then
		begin
			SysInputBox := txtInput.Text;
			Break;
		end;

		if ObjBtnClick(btnCancel) or (Key = KeyAltC) or (Key = KeyEscape) then
		begin
			SysInputBox := '';
			Break;
		end;

		if ObjTxtClick(txtInput) or (Key = KeyAltN) then
			ObjEditTxt(txtInput, txtInput.Text);

	until False;

	ClearInputBuffer;
	MouseHide;
	PutImage(x1, y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;
end;

end.