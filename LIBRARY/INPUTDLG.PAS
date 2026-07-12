
unit InputDlg;

interface

function InputBox(Title, Prompt, IconFile, DefaultValue: string): string;

implementation

uses
	Costalib, UIIcon, UIButton, UITxtbox, UILabel;

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

procedure BtnClick(Sender: PUIObject); far;
begin
	{If OK clicked, return value of textfield - if not, Cancel was clicked and nothing should be returned}
	if Sender = PUIObject(BtnOk) then
		ReturnValue := TxtInput^.Text
	else
		ReturnValue := '';

	WinInputBox^.Close;
end;

function InputBox(Title, Prompt, IconFile, DefaultValue: string): string;
begin
	{Create the Window and all child objects}
	New(WinInputBox, Init(0, 0, NoParent));
	with WinInputBox^ do
	begin
		Width := PrintW(Prompt) + 76;
		Height := PrintH(Prompt) + 120;
		if Width < 194 then Width := 194;
		Center(OrBoth);
		SaveBackdrop;
	end;

	New(ImgIcon, Init(5, 7, IconFile, WinInputBox));
	New(BtnOK, Init(WinInputBox^.Width - 210, WinInputBox^.Height - 40, CAP_OK, WinInputBox));
	New(BtnCancel, Init(WinInputBox^.Width - 111, WinInputBox^.Height - 40, CAP_CANCEL, WinInputBox));
	New(TxtInput, Init(6, WinInputBox^.Height - 69, CAP_INPUT, WinInputBox));
	TxtInput^.Width := WinInputBox^.Width - 24;
	New(LblTitle, Init(50, 9, Title, WinInputBox));
	New(LblText, Init(50, 25, Prompt, WinInputBox));
	With BtnOK^ do
	begin
		OnClick := BtnClick;
		AddHotkey(KeyAltO);
		AddHotkey(KeyEnter);
	end;
	With BtnCancel^ do
	begin
		OnClick := BtnClick;
		AddHotkey(KeyAltC);
		AddHotkey(KeyEscape);
	end;
	with TxtInput^ do
	begin
		Text := DefaultValue;
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