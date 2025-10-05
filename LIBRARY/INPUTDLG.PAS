
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
	TxtInput:    PTextbox;
	BtnOK,
	BtnCancel:   PButton;
	ImgIcon:     PIcon;
	LblTitle,
	lblText:     PLabel;

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
	X2 := PrintW(MsgText) + 76;
	Y2 := PrintH(MsgText) + 120;
	if X2 < 194 then
		X2 := 194;

	{Create the Window and all child objects}
	New(WinInputBox, Init(0, 0, NoParent));
	with WinInputBox^ do
	begin
		SetSize(X2, Y2);
		Center(OrBoth);
		SaveBackdrop;
		GetPos(X1, Y1, True);
	end;
	Inc(X2, X1);
	Inc(Y2, Y1);

	New(ImgIcon, Init(X1 + 13, Y1 + 15, MsgIcon, WinInputBox));
	New(BtnOK, Init(X2 - 207, Y2 - 36, CAP_OK, WinInputBox));
	New(BtnCancel, Init(X2 - 105, Y2 - 36, CAP_CANCEL, WinInputBox));
	New(TxtInput, Init(X1 + 12, Y2 - 63, CAP_INPUT, WinInputBox));
	TxtInput^.SetSize(X2 - X1 - 24, SizeRetain);
	New(LblTitle, Init(X1 + 56, Y1 + 15, MsgTitle, WinInputBox));
	New(LblText, Init(X1 + 56, Y1 + 31, MsgText, WinInputBox));
	With BtnOK^ do
	begin
		AddHotkey(KeyAltO);
		AddHotkey(KeyEnter);
		SetOnClick(BtnOkClick);
	end;
	With BtnCancel^ do
	begin
		AddHotkey(KeyAltC);
		AddHotkey(KeyEscape);
		SetOnClick(BtnCancelClick);
	end;
	with TxtInput^ do
	begin
		Text := MsgDefault;
		AddHotkey(KeyAltN);
	end;

	{Run the Window. This will not return until the Window is closed}
	WinInputBox^.Run;
	Dispose(WinInputBox, Done);

	InputBox := ReturnValue;
	ClearInputBuffer;
end;

end.