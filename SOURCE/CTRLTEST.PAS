program CTRLTEST;

uses
	Costalib, UIButton, UITxtbox, UIFrame, MsgDlg, AboutDlg, FileDlg;

const
	AppName              = 'Control Test Application';
	AppVersion           = '2.0';
	AppAuthor            = 'Jacob Palm';
	AppIcon              = 'DOCUMENT';

var
	App: PApplication;
	WinMain: PWindow;

	Btn1, Btn2, Btn3: PButton;
	HkEsc: PHotkey;

	Frm1: PFrame;
	Txt1: PTextbox;

procedure Btn1Click(Sender: PUIObject); far;
begin
	AboutBox(App);
end;

procedure Btn2Click(Sender: PUIObject); far;
begin
	FileSelect('*.*', '');
end;

procedure Btn3Click(Sender: PUIObject); far;
var
	Result: Boolean;
begin
	Result := MsgBox('Confirm Exit', 'Do you really want to exit ' + #13 + AppName + '?', MsgQuest);
	if Result then
		WinMain^.Close;
end;

procedure Txt1Change(Sender: PUIObject); far;
begin
	MsgBox('Text Changed', 'The text has been changed to:' + #13 + Txt1^.Text, MsgInfo);
end;

begin
	New(App, Init);
	App^.SetInfo(AppName, AppVersion, AppAuthor, AppIcon);

	New(WinMain, Init(50, 50, NoParent));
	WinMain^.Center(OrBoth);

	New(Btn1, Init(20, 20, #127 + 'About...', WinMain));
	With Btn1^ do
	begin
		OnClick := Btn1Click;
		AddHotkey(KeyAltA);
	end;
	New(Btn2, Init(120, 20, #127 + 'Open...', WinMain));
	With Btn2^ do
	begin
		OnClick := Btn2Click;
		AddHotkey(KeyAltO);
	end;
	New(Btn3, Init(220, 20, 'E' + #127 + 'xit', WinMain));
	With Btn3^ do
	begin
		OnClick := Btn3Click;
		AddHotkey(KeyAltX);
	end;
	New(HkEsc, Init(KeyEscape, WinMain));
	HkEsc^.OnClick := Btn3Click;

	New(Frm1, Init(20, 50, WinMain));
	with Frm1^ do
	begin
		Width := 200;
		Height := 100;
	end
	New(Txt1, Init(10, 20, 'Name:', Frm1));
	With Txt1^ do
	begin
		Text := 'John Doe';
		OnChange := Txt1Change;
		Center(OrHorizontal);
	end;

	WinMain^.Run;
	Dispose(WinMain, Done);
	WinMain := nil;
	{App^.OpenWindow(WinMain);
	App^.Run;}
	App^.Terminate;
	SoundNote(440, 200);
end.