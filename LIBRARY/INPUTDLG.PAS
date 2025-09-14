
unit InputDlg;

interface

uses
	Costalib, UIIcon, UIButton, UITxtbox, Strings, Graph, Crt;

function InputBox(MsgTitle, MsgText, MsgIcon, MsgDefault: string): string;

implementation

const
	CAP_OK     = #127 + 'OK';
	CAP_CANCEL = #127 + 'Cancel';
	CAP_INPUT  = 'I' + #127 + 'nput:';

var
	WinInputBox: TWindow;
	TxtInput: TTextbox;
	BtnOK, BtnCancel: TButton;
	ImgIcon: TIcon;

	ReturnValue: string;
	InputBoxDone: Boolean;

procedure BtnOkClick(Sender: PBaseObject); far;
begin
	ReturnValue := TxtInput.Text;
	InputBoxDone := True;
end;

procedure BtnCancelClick(Sender: PBaseObject); far;
begin
	InputBoxDone := True;
end;

function InputBox(MsgTitle, MsgText, MsgIcon, MsgDefault: string): string;
var
	BoxW, BoxH: Integer;
	X1, Y1, X2, Y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Key: String;
begin
	InputBoxDone := False;
	ReturnValue := '';
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
	BtnOK.AddHotkey(KeyAltO);
	BtnOK.AddHotkey(KeyEnter);
	BtnOK.OnClick := BtnOKClick;
	BtnCancel.Init(X2 - 105, BtnOK.Top, SizeDefault, SizeDefault, CAP_CANCEL);
	BtnCancel.AddHotkey(KeyAltC);
	BtnCancel.AddHotkey(KeyEscape);
	BtnCancel.OnClick := BtnCancelClick;
	TxtInput.Init(X1 + 12, BtnOK.Top - 27, WinInputBox.Width - 25, SizeDefault, CAP_INPUT);
	TxtInput.Text := MsgDefault;
	TxtInput.AddHotkey(KeyAltN);

	Mouse.Hide;
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
	Mouse.Show;

	repeat
		Key := GetKey;
		HotkeyPressed := Key; {DEBUG - move to event loop later}

		BtnOK.CheckEvent;
		BtnCancel.CheckEvent;
		TxtInput.CheckEvent;
	until InputboxDone;

	InputBox := ReturnValue;

	ClearInputBuffer;
	Mouse.Hide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	Mouse.Show;
end;

end.