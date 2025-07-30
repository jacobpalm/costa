
unit InputDlg;

interface

uses
	Costalib, Strings, Graph, Crt;

function InputBox(MsgTitle, MsgText, MsgIcon, MsgDefault: string): string;

implementation

const
	CAP_OK     = #127 + 'OK';
	CAP_CANCEL = #127 + 'Cancel';
	CAP_INPUT  = 'I' + #127 + 'nput:';

function InputBox(MsgTitle, MsgText, MsgIcon, MsgDefault: string): string;
var
	WinInputBox: TWindow;
	TxtInput: TTextbox;
	BtnOK, BtnCancel: TButton;
	ImgIcon: TIcon;
	BoxW, BoxH: Integer;
	X1, Y1, X2, Y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Key: String;
begin
	BoxW := PrintW(MsgText) + 76;
	BoxH := PrintH(MsgText) + 120;
	if BoxW < 194 then
		BoxW := 194;
	WinInputBox.Init(sizeCenter, sizeCenter, BoxW, BoxH);
	X1 := WinInputBox.Left;
	Y1 := WinInputBox.Top;
	X2 := WinInputBox.Left + WinInputBox.Width;
	Y2 := WinInputBox.Top + WinInputBox.Height;

	ImgIcon.Init(X1 + 13, Y1 + 15, MsgIcon);
	BtnOK.Init(X2 - 207, Y2 - 36, SizeDefault, SizeDefault, CAP_OK);
	BtnCancel.Init(X2 - 105, BtnOK.Top, SizeDefault, SizeDefault, CAP_CANCEL);
	TxtInput.Init(X1 + 12, BtnOK.Top - 27, WinInputBox.Width - 25, SizeDefault, CAP_INPUT);
	TxtInput.Text := MsgDefault;

	MouseHide;
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);

	WinInputBox.Draw;
	BtnOK.Draw;
	BtnCancel.Draw;
	TxtInput.Draw;
	ImgIcon.Draw;

	Print(MsgTitle, X1 + 56, Y1 + 15, Thm.WinText);
	Print(MsgText, X1 + 56, Y1 + 31, Thm.WinText);
	MouseShow;

	repeat
		Key := GetKey;

		if BtnOK.Clicked or (Key = KeyAltO) or (Key = KeyEnter) then
		begin
			InputBox := TxtInput.Text;
			Break;
		end;

		if BtnCancel.Clicked or (Key = KeyAltC) or (Key = KeyEscape) then
		begin
			InputBox := '';
			Break;
		end;

		if TxtInput.Clicked or (Key = KeyAltN) then
			TxtInput.Edit;

	until False;

	ClearInputBuffer;
	MouseHide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;
end;

end.