
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
	WinInputBox: TWindow;
	TxtInput: TTextbox;
	BtnOK, BtnCancel: TButton;
	ImgIcon: TIcon;
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
			if PrintW(S) > msgTextWidth then
				msgTextWidth := PrintW(S);
			Break;
		end
		else
		begin
			Inc(msgLineCount);
			msgLines[msgLineCount] := Copy(S, 1, P-1);
			if PrintW(msgLines[msgLineCount]) > msgTextWidth then
				msgTextWidth := PrintW(msgLines[msgLineCount]);
			Delete(S, 1, P);
		end;
	until S = '';

	WindowWidth := msgTextWidth + 76;
	if WindowWidth < 194 then
		WindowWidth := 194;
	WinInputBox.Init(sizeCenter, sizeCenter, WindowWidth, msgLineCount * 15 + 120);
	TxtInput.Init(WinInputBox.Left + 12, WinInputBox.Top + 56 + (15 * msgLineCount), WinInputBox.Width - 24, 22);
	BtnOK.Init(WinInputBox.Left + WinInputBox.Width - 182, TxtInput.Top + 30, 80, SizeDefault, HotkeySymbol + 'OK');
	BtnCancel.Init(WinInputBox.Left + WinInputBox.Width - 92, BtnOK.Top, 80, SizeDefault, HotkeySymbol + 'Cancel');
	TxtInput.Text := msgDefault;

	if Length(msgIcon) > 0 then
	begin
		ImgIcon.Init(WinInputBox.Left + 12, WinInputBox.Top + 15, msgIcon);
		if msgLineCount > 1 then
			Inc(ImgIcon.Top, 5);
	end;

	MouseHide;
	x1 := WinInputBox.Left;
	y1 := WinInputBox.Top;
	x2 := WinInputBox.Left + WinInputBox.Width;
	y2 := WinInputBox.Top + WinInputBox.Height;
	BackgroundSize := ImageSize(x1, y1, x2, y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(x1, y1, x2, y2, BackgroundP^);

	WinInputBox.Draw;
	BtnOK.Draw;
	BtnCancel.Draw;
	TxtInput.Draw;

	if Length(msgIcon) > 0 then
		Print(msgTitle, WinInputBox.Left + 53, WinInputBox.Top + 15, Thm.WinText)
	else
		Print(msgTitle, WinInputBox.Left + 12, WinInputBox.Top + 15, Thm.WinText);

	y2 := WinInputBox.Top + 17;
	for i := 1 to msgLineCount do
	begin
		if (i < 3) and (Length(msgIcon) > 0) then
				Print(msgLines[i], WinInputBox.Left + 53, y2 + (15 * i), Thm.WinText)
			else
				Print(msgLines[i], WinInputBox.Left + 12, y2 + (15 * i), Thm.WinText);
	end;
		

	Print('I' + HotkeySymbol + 'nput:', TxtInput.Left, TxtInput.Top - 16, Thm.WinText);

	if Length(msgIcon) > 0 then
		ImgIcon.Draw;

	MouseShow;

	repeat
		Key := GetKey;

		if ObjBtnClick(BtnOK) or (Key = KeyAltO) or (Key = KeyEnter) then
		begin
			SysInputBox := TxtInput.Text;
			Break;
		end;

		if ObjBtnClick(BtnCancel) or (Key = KeyAltC) or (Key = KeyEscape) then
		begin
			SysInputBox := '';
			Break;
		end;

		if ObjTxtClick(TxtInput) or (Key = KeyAltN) then
			ObjEditTxt(TxtInput, TxtInput.Text);

	until False;

	ClearInputBuffer;
	MouseHide;
	PutImage(x1, y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;
end;

end.