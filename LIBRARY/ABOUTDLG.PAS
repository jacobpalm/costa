unit ABOUTDLG;

interface

uses
	CostaLib, UIIcon, UIButton, UILabel, Graph;
	
procedure AboutBox(AppP: PApplication);

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
	WinAboutBox: PWindow;
	BtnClose: PButton;
	ImgLogo: PIcon;
	LblInfo: array [0..2] of PLabel;

procedure AboutBoxClose(Sender: PUIObject); far;
begin
	WinAboutBox^.Close;
end;

procedure AboutBox(AppP: PApplication);
var
	X1, Y1, X2, Y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Text: String;
begin
	Text := ReplaceMsg(MSG_ABOUT_TEXT, LibName);
	Text := ReplaceMsg(Text, LibVersion);
	Text := ReplaceMsg(Text, LibYear);

	New(WinAboutBox, Init(sizeCenter, sizeCenter, PrintW(Text) + 29, PrintH(Text) + 95));
	X1 := WinAboutBox^.Left;
	Y1 := WinAboutBox^.Top;
	X2 := X1 + WinAboutBox^.Width;
	Y2 := Y1 + WinAboutBox^.Height;
	New(ImgLogo, Init(X1 + 13, Y1 + 15, AppP^.Icon));
	New(BtnClose, Init(SizeCenter, Y2 - 34, SizeDefault, SizeDefault, CAP_CLOSE));
	with BtnClose^ do
	begin
		AddHotkey(KeyAltC);
		AddHotkey(KeyEnter);
		AddHotkey(KeyEscape);
		OnClick := AboutBoxClose;
	end;
	
	New(LblInfo[0], Init(X1 + 56, Y1 + 21, SizeDefault, SizeDefault, AppP^.Name + ' ' + AppP^.Version));
	New(LblInfo[1], Init(X1 + 56, Y1 + 33, SizeDefault, SizeDefault, ReplaceMsg(MSG_BY_TEXT, AppP^.Author)));
	New(LblInfo[2], Init(X1 + 15, Y1 + 53, SizeDefault, SizeDefault, Text));
	
	WinAboutBox^.AddObject(BtnClose);
	WinAboutBox^.AddObject(ImgLogo);
	WinAboutBox^.AddObject(LblInfo[0]);
	WinAboutBox^.AddObject(LblInfo[1]);
	WinAboutBox^.AddObject(LblInfo[2]);

	{Save background to restore when Window is closed}
	Mouse.Hide;
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);
	Mouse.Show;

	WinAboutBox^.Run;

	{Restore background}
	Mouse.Hide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	Mouse.Show;

	{Dispose of memory used by background and objects. Disposing of the Window
		object will also dispose of all child objects}
	FreeMem(BackgroundP, BackgroundSize);
	Dispose(WinAboutBox, Done);
end;

end.