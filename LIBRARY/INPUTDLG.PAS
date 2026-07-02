
unit InputDlg;

interface

uses
	Costalib, UIIcon, UIButton, UITxtbox, UILabel;

function InputBox(Title, Prompt, IconFile, DefaultValue: string): string;

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
	LblText:     PLabel;

	ReturnValue: string;

procedure BtnOkClick(Sender: PUIObject); far;
begin
	ReturnValue := TxtInput^.GetText;
	WinInputBox^.Close;
end;

procedure BtnCancelClick(Sender: PUIObject); far;
begin
	WinInputBox^.Close;
end;

function InputBox(Title, Prompt, IconFile, DefaultValue: string): string;
var
	W, H: Integer;
begin
	ReturnValue := '';

	{Calculate size of the Window based on text size}
	W := PrintW(Prompt) + 76;
	H := PrintH(Prompt) + 120;
	if W < 194 then
		W := 194;

	{Create the Window and all child objects}
	New(WinInputBox, Init(0, 0, NoParent));
	with WinInputBox^ do
	begin
		SetSize(W, H);
		Center(OrBoth);
		SaveBackdrop;
	end;

	New(ImgIcon, Init(13, 15, IconFile, WinInputBox));
	New(BtnOK, Init(W - 207, H - 36, CAP_OK, WinInputBox));
	New(BtnCancel, Init(W - 105, H - 36, CAP_CANCEL, WinInputBox));
	New(TxtInput, Init(12, H - 63, CAP_INPUT, WinInputBox));
	TxtInput^.SetSize(W - 24, SizeRetain);
	New(LblTitle, Init(56, 15, Title, WinInputBox));
	New(LblText, Init(56, 31, Prompt, WinInputBox));
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
		SetText(DefaultValue);
		AddHotkey(KeyAltN);
	end;

	{Run the Window. This will not return until the Window is closed}
	WinInputBox^.Run;
	Dispose(WinInputBox, Done);
	WinInputBox := nil;

	InputBox := ReturnValue;
	ClearInputBuffer;
end;

end.