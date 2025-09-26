
unit InputDlg;

interface

uses
	Costalib, UIIcon, UIButton, UITxtbox, UILabel, Strings, Graph, Crt;

function InputBox(MsgTitle, MsgText, MsgIcon, MsgDefault: string): string;

implementation

const
	CAP_OK     = #127 + 'OK';
	CAP_CANCEL = #127 + 'Cancel';
	CAP_INPUT  = 'I' + #127 + 'nput:';

var
	WinInputBox: PWindow;
	TxtInput: PTextbox;
	BtnOK, BtnCancel: PButton;
	ImgIcon: PIcon;
	LblTitle, lblText: PLabel;

	ReturnValue: string;

procedure BtnOkClick(Sender: PUIObject); far;
begin
	ReturnValue := TxtInput^.Text;
	WinInputBox^.Close;
end;

procedure BtnCancelClick(Sender: PUIObject); far;
begin
	WinInputBox^.Close;
end;

function InputBox(MsgTitle, MsgText, MsgIcon, MsgDefault: string): string;
var
	BoxW, BoxH: Integer;
	X1, Y1, X2, Y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
begin
	ReturnValue := '';

	{Calculate size of the Window based on text size}
	BoxW := PrintW(MsgText) + 76;
	BoxH := PrintH(MsgText) + 120;
	if BoxW < 194 then
		BoxW := 194;

	{Create the Window and all child objects}
	New(WinInputBox, Init(sizeCenter, sizeCenter, BoxW, BoxH));
	X1 := WinInputBox^.Left;
	Y1 := WinInputBox^.Top;
	X2 := X1 + WinInputBox^.Width;
	Y2 := Y1 + WinInputBox^.Height;

	New(ImgIcon, Init(X1 + 13, Y1 + 15, MsgIcon));
	New(BtnOK, Init(X2 - 207, Y2 - 36, SizeDefault, SizeDefault, CAP_OK));
	New(BtnCancel, Init(X2 - 105, BtnOK^.Top, SizeDefault, SizeDefault, CAP_CANCEL));
	New(TxtInput, Init(X1 + 12, BtnOK^.Top - 27, WinInputBox^.Width - 25, SizeDefault, CAP_INPUT));
	New(LblTitle, Init(X1 + 56, Y1 + 15, SizeDefault, SizeDefault, MsgTitle));
	New(LblText, Init(X1 + 56, Y1 + 31, SizeDefault, SizeDefault, MsgText));
	With BtnOK^ do
	begin
		AddHotkey(KeyAltO);
		AddHotkey(KeyEnter);
		OnClick := BtnOkClick;
	end;
	With BtnCancel^ do
	begin
		AddHotkey(KeyAltC);
		AddHotkey(KeyEscape);
		OnClick := BtnCancelClick;
	end;
	with TxtInput^ do
	begin
		Text := MsgDefault;
		AddHotkey(KeyAltN);
	end;

	{Add all objects to the Window}
	WinInputBox^.AddObject(BtnOK);
	WinInputBox^.AddObject(BtnCancel);
	WinInputBox^.AddObject(TxtInput);
	WinInputBox^.AddObject(ImgIcon);
	WinInputBox^.AddObject(LblTitle);
	WinInputBox^.AddObject(LblText);

	{Save background to restore when Window is closed}
	Mouse.Hide;
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);
	Mouse.Show;

	{Run the Window. This will not return until the Window is closed}
	WinInputBox^.Run;
	InputBox := ReturnValue;
	ClearInputBuffer;

	{Restore background}
	Mouse.Hide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	Mouse.Show;

	{Dispose of memory used by background and objects. Disposing of the Window
	 object will also dispose of all child objects}
	FreeMem(BackgroundP, BackgroundSize);
	Dispose(WinInputBox, Done);
end;

end.