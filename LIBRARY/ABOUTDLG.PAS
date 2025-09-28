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

	New(WinAboutBox, Init(0, 0, nil));
	with WinAboutBox^ do
	begin
		SetSize(PrintW(Text) + 29, PrintH(Text) + 95);
		Center(OrBoth);
		GetPos(X1, Y1, True);
		GetSize(X2, Y2);
	end;
	Inc(X2, X1);
	Inc(Y2, Y1);

	New(ImgLogo, Init(X1 + 13, Y1 + 15, AppP^.Icon, WinAboutBox));
	New(BtnClose, Init(0, Y2 - 34, CAP_CLOSE, WinAboutBox));
	with BtnClose^ do
	begin
		Center(OrHorizontal);
		AddHotkey(KeyAltC);
		AddHotkey(KeyEnter);
		AddHotkey(KeyEscape);
		SetOnClick(AboutBoxClose);
	end;
	
	New(LblInfo[0], Init(X1 + 56, Y1 + 21, AppP^.Name + ' ' + AppP^.Version, WinAboutBox));
	New(LblInfo[1], Init(X1 + 56, Y1 + 33, ReplaceMsg(MSG_BY_TEXT, AppP^.Author), WinAboutBox));
	New(LblInfo[2], Init(X1 + 15, Y1 + 53, Text, WinAboutBox));

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