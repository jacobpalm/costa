unit ABOUTDLG;

interface

uses
	CostaLib, UIIcon, UIButton, Graph;
	
procedure AboutBox(const ProgramName, ProgramVersion, ProgramAuthor, IconFile: string);

implementation

const
	CAP_CLOSE      = #127 + 'Close';

	MSG_BY_TEXT    = 'By %s';
	MSG_ABOUT_TEXT = 'Made with the %s version' + #13 +
	                 '%s by Jacob Palm, 2004-%s.' + #13 +
	                 #13 +
	                 'May be freely distributed under the' + #13 +
	                 'terms of the MIT License. More details' + #13 +
	                 'can be found in the LICENSE file.' + #13 +
	                 #13 +
	                 'More information and news online at:' + #13 +
	                 'https://costa.jacobpalm.dk';

var
	WinAboutBox: TWindow;
	BtnClose: TButton;
	ImgLogo: TIcon;

	AboutBoxDone: Boolean;

procedure AboutBoxClose(Sender: PBaseObject); far;
begin
	AboutBoxDone := True;
end;

procedure AboutBox(const ProgramName, ProgramVersion, ProgramAuthor, IconFile: string);
var
	X1, Y1, X2, Y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Text, Key: String;
begin
	AboutBoxDone := False;
	Text := ReplaceMsg(MSG_ABOUT_TEXT, LibName);
	Text := ReplaceMsg(Text, LibVersion);
	Text := ReplaceMsg(Text, LibYear);

	WinAboutBox.Init(sizeCenter, sizeCenter, PrintW(Text) + 29, PrintH(Text) + 95);
	X1 := WinAboutBox.Left;
	Y1 := WinAboutBox.Top;
	X2 := WinAboutBox.Left + WinAboutBox.Width;
	Y2 := WinAboutBox.Top + WinAboutBox.Height;
	ImgLogo.Init(X1 + 13, Y1 + 15, IconFile);
	BtnClose.Init(SizeCenter, Y2 - 34, SizeDefault, SizeDefault, CAP_CLOSE);
	BtnClose.AddHotkey(KeyAltC);
	BtnClose.AddHotkey(KeyEnter);
	BtnClose.AddHotkey(KeyEscape);
	BtnClose.OnClick := AboutBoxClose;

	MouseHide;

	{Save background to restore when Window is closed}
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);

	WinAboutBox.Draw;
	BtnClose.Draw;
	ImgLogo.Draw;
	Print(ProgramName + ' ' + ProgramVersion, X1 + 56, Y1 + 21, Thm.WinText);
	Print(ReplaceMsg(MSG_BY_TEXT, ProgramAuthor), X1 + 56, Y1 + 33, Thm.WinText);
	
	Print(Text, X1 + 15, Y1 + 53, Thm.WinText);
	
	MouseShow;
	repeat
		Key := GetKey;
		HotkeyPressed := Key; {DEBUG - move to event loop later}
		
		BtnClose.CheckEvent;
	until AboutBoxDone;
	MouseHide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	MouseShow;
	FreeMem(BackgroundP, BackgroundSize);
end;

end.