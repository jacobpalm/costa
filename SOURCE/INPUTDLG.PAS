
unit InputDlg;

interface

uses
	Costalib, Strings, Graph, Crt;

function InputBox(MsgTitle, MsgText, MsgIcon, MsgDefault: string): string;

implementation

function InputBox(MsgTitle, MsgText, MsgIcon, MsgDefault: string): string;
var
	MsgLines: array[1..16] of string;
	MsgLinesCount, MsgTextWidth, i, P: Integer;
	WinInputBox: TWindow;
	TxtInput: TTextbox;
	BtnOK, BtnCancel: TButton;
	ImgIcon: TIcon;
	Key: String;
	S: string;
	X1, Y1, X2, Y2, WindowWidth: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
begin
	S := MsgText;
	if (S <> '') and (S[Length(S)] = NewLine) then
		Delete(S, Length(S), 1);
	MsgLinesCount := 0;
	MsgTextWidth := 0;
	repeat
		P := Pos(NewLine, S);
		if P = 0 then
		begin
			Inc(MsgLinesCount);
			MsgLines[MsgLinesCount] := S;
			if PrintW(S) > MsgTextWidth then
				MsgTextWidth := PrintW(S);
			Break;
		end
		else
		begin
			Inc(MsgLinesCount);
			MsgLines[MsgLinesCount] := Copy(S, 1, P-1);
			if PrintW(MsgLines[MsgLinesCount]) > MsgTextWidth then
				MsgTextWidth := PrintW(MsgLines[MsgLinesCount]);
			Delete(S, 1, P);
		end;
	until S = '';

	WindowWidth := MsgTextWidth + 76;
	if WindowWidth < 194 then
		WindowWidth := 194;
	WinInputBox.Init(sizeCenter, sizeCenter, WindowWidth, MsgLinesCount * 15 + 120);
	TxtInput.Init(WinInputBox.Left + 12, WinInputBox.Top + 56 + (15 * MsgLinesCount), WinInputBox.Width - 25, SizeDefault);
	BtnOK.Init(WinInputBox.Left + WinInputBox.Width - 207, TxtInput.Top + 30, SizeDefault, SizeDefault, Hotkey + 'OK');
	BtnCancel.Init(WinInputBox.Left + WinInputBox.Width - 105, BtnOK.Top, SizeDefault, SizeDefault, Hotkey + 'Cancel');
	TxtInput.Text := MsgDefault;

	if Length(MsgIcon) > 0 then
	begin
		ImgIcon.Init(WinInputBox.Left + 12, WinInputBox.Top + 15, MsgIcon);
		if MsgLinesCount > 1 then
			Inc(ImgIcon.Top, 5);
	end;

	MouseHide;
	X1 := WinInputBox.Left;
	Y1 := WinInputBox.Top;
	X2 := WinInputBox.Left + WinInputBox.Width;
	Y2 := WinInputBox.Top + WinInputBox.Height;
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);

	WinInputBox.Draw;
	BtnOK.Draw;
	BtnCancel.Draw;
	TxtInput.Draw;

	if Length(MsgIcon) > 0 then
		Print(MsgTitle, WinInputBox.Left + 53, WinInputBox.Top + 15, Thm.WinText)
	else
		Print(MsgTitle, WinInputBox.Left + 12, WinInputBox.Top + 15, Thm.WinText);

	Y2 := WinInputBox.Top + 17;
	for i := 1 to MsgLinesCount do
	begin
		if (i < 3) and (Length(MsgIcon) > 0) then
				Print(MsgLines[i], WinInputBox.Left + 53, Y2 + (15 * i), Thm.WinText)
			else
				Print(MsgLines[i], WinInputBox.Left + 12, Y2 + (15 * i), Thm.WinText);
	end;
		

	Print('I' + Hotkey + 'nput:', TxtInput.Left, TxtInput.Top - 16, Thm.WinText);

	if Length(MsgIcon) > 0 then
		ImgIcon.Draw;

	MouseShow;

	repeat
		Key := GetKey;

		if BtnClick(BtnOK) or (Key = KeyAltO) or (Key = KeyEnter) then
		begin
			InputBox := TxtInput.Text;
			Break;
		end;

		if BtnClick(BtnCancel) or (Key = KeyAltC) or (Key = KeyEscape) then
		begin
			InputBox := '';
			Break;
		end;

		if TxtClick(TxtInput) or (Key = KeyAltN) then
			TxtInput.Edit;

	until False;

	ClearInputBuffer;
	MouseHide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;
end;

end.