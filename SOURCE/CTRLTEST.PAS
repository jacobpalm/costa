program CTRLTEST;

uses
	Costalib, UIButton, UITxtbox, UIFrame, MsgDlg, AboutDlg, FileDlg, Strings, Graph, Crt;

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
	{AboutBox(App);}
end;

procedure Btn2Click(Sender: PUIObject); far;
begin
	FileSelect('*.*', '', False);
end;

procedure Btn3Click(Sender: PUIObject); far;
begin
	CloseGraph;
	Halt(0);
end;

begin
	New(App, Init);
	with App^ do
	begin
		Name := AppName;
		Version := AppVersion;
		Author := AppAuthor;
		Icon := AppIcon;
	end;

	New(WinMain, Init(50, 50, NoParent));
	WinMain^.Center(OrBoth);
	
	New(Btn1, Init(20, 20, #127 + 'About...', WinMain));
	With Btn1^ do
	begin
		AddHotkey(KeyAltA);
		SetOnClick(Btn1Click);
	end;
	New(Btn2, Init(120, 20, #127 + 'Open...', WinMain));
	With Btn2^ do
	begin
		AddHotkey(KeyAltO);
		SetOnClick(Btn2Click);
	end;
	New(Btn3, Init(220, 20, 'E' + #127 + 'xit', WinMain));
	With Btn3^ do
	begin
		AddHotkey(KeyAltX);
		SetOnClick(Btn3Click);
	end;
	New(HkEsc, Init(KeyEscape, WinMain));
	HkEsc^.SetOnClick(Btn3Click);

	New(Frm1, Init(20, 50, NoParent));
	New(Txt1, Init(10, 10, 'Name:', WinMain));
	Txt1^.Text := 'John Doe';
	Txt1^.Center(OrHorizontal);

	WinMain^.Run;
	Dispose(WinMain, Done);
	{App^.OpenWindow(WinMain);
	App^.Run;}
	App^.Exit;
	SoundNote(440, 200);
end.