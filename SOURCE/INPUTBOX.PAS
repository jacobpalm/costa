
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
	winInputBox: WindowType;
	txtInput: TextboxType;
	txtInputText: string;
	btnOK, btnCancel: ButtonType;
	imgIcon: ImageType;
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
			if FontGetWidth(S, FontNormal) > msgTextWidth then
				msgTextWidth := FontGetWidth(S, FontNormal);
			Break;
		end
		else
		begin
			Inc(msgLineCount);
			msgLines[msgLineCount] := Copy(S, 1, P-1);
			if FontGetWidth(msgLines[msgLineCount], FontNormal) > msgTextWidth then
				msgTextWidth := FontGetWidth(msgLines[msgLineCount], FontNormal);
			Delete(S, 1, P);
		end;
	until S = '';

	WindowWidth := msgTextWidth + 76;
	if WindowWidth < 194 then
		WindowWidth := 194;
	winInputBox.Init(sizeCenter, sizeCenter, WindowWidth, msgLineCount * 15 + 120);
	txtInput.Init(winInputBox.Pos.Left + 12, winInputBox.Pos.Top + 56 + (15 * msgLineCount), winInputBox.Pos.Width - 24, 22);
	btnOK.Init(winInputBox.Pos.Left + winInputBox.Pos.Width - 182, txtInput.Pos.Top + 30, 80, 22, HotkeySymbol + 'OK');
	btnCancel.Init(winInputBox.Pos.Left + winInputBox.Pos.Width - 92, btnOK.Pos.Top, 80, 22, HotkeySymbol + 'Cancel');
	txtInputText := msgDefault;

	if Length(msgIcon) > 0 then
	begin
		imgIcon.Pos.Left := winInputBox.Pos.Left + 12;
		imgIcon.Pos.Top := winInputBox.Pos.Top + 15;
		imgIcon.ImageFile := msgIcon;
		if msgLineCount > 1 then
			Inc(imgIcon.Pos.Top, 5);
	end;

	MouseHide;
	x1 := winInputBox.Pos.Left;
	y1 := winInputBox.Pos.Top;
	x2 := winInputBox.Pos.Left + winInputBox.Pos.Width;
	y2 := winInputBox.Pos.Top + winInputBox.Pos.Height;
	BackgroundSize := ImageSize(x1, y1, x2, y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(x1, y1, x2, y2, BackgroundP^);

	ObjDrawWin(winInputBox);
	ObjDrawBtn(btnOK, False);
	ObjDrawBtn(btnCancel, False);
	ObjDrawTxt(txtInput, txtInputText, False);

	if Length(msgIcon) > 0 then
		FontPrint(msgTitle, winInputBox.Pos.Left + 53, winInputBox.Pos.Top + 15, Theme.WindowText, 1)
	else
		FontPrint(msgTitle, winInputBox.Pos.Left + 12, winInputBox.Pos.Top + 15, Theme.WindowText, 1);

	y2 := winInputBox.Pos.Top + 17;
	for i := 1 to msgLineCount do
	begin
		if (i < 3) and (Length(msgIcon) > 0) then
				FontPrint(msgLines[i], winInputBox.Pos.Left + 53, y2 + (15 * i), Theme.WindowText, 2)
			else
				FontPrint(msgLines[i], winInputBox.Pos.Left + 12, y2 + (15 * i), Theme.WindowText, 2);
	end;
		

	FontPrint('I' + HotkeySymbol + 'nput:', txtInput.Pos.Left, txtInput.Pos.Top - 16, Theme.WindowText, FontHeading);

	if Length(msgIcon) > 0 then
		ObjDrawImg(imgIcon);

	MouseShow;

	repeat
		Key := GetKey;

		if ObjBtnClick(btnOK) or (Key = KeyAltO) or (Key = KeyEnter) then
		begin
			SysInputBox := txtInputText;
			Break;
		end;

		if ObjBtnClick(btnCancel) or (Key = KeyAltC) or (Key = KeyEscape) then
		begin
			SysInputBox := '';
			Break;
		end;

		if ObjTxtClick(txtInput) or (Key = KeyAltN) then
			ObjEditTxt(txtInput, txtInputText);

	until False;

	ClearKeyBuffer;
	MouseHide;
	PutImage(x1, y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;
end;

end.