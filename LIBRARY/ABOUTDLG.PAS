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
	BtnClose:    PButton;
	ImgLogo:     PIcon;
	LblInfo:     array [0..2] of PLabel;

procedure AboutBoxClose(Sender: PUIObject); far;
begin
	WinAboutBox^.Close;
end;

procedure AboutBox(AppP: PApplication);
var
	X1, Y1, X2, Y2: Integer;
	Name, Version, Author, Icon: String;
	Text: String;
begin
	Text := ReplaceMsg(MSG_ABOUT_TEXT, LibName);
	Text := ReplaceMsg(Text, LibVersion);
	Text := ReplaceMsg(Text, LibYear);

	{Get app info}
	AppP^.GetInfo(Name, Version, Author, Icon);

	New(WinAboutBox, Init(0, 0, nil));
	with WinAboutBox^ do
	begin
		SetSize(PrintW(Text) + 29, PrintH(Text) + 99);
		Center(OrBoth);
		SaveBackdrop;
		GetPos(X1, Y1, True);
		GetSize(X2, Y2);
	end;
	Inc(X2, X1);
	Inc(Y2, Y1);

	New(ImgLogo, Init(13, 15, Icon, WinAboutBox));
	New(BtnClose, Init(0, Y2 - Y1 - 34, CAP_CLOSE, WinAboutBox));
	with BtnClose^ do
	begin
		Center(OrHorizontal);
		AddHotkey(KeyAltC);
		AddHotkey(KeyEnter);
		AddHotkey(KeyEscape);
		SetOnClick(AboutBoxClose);
	end;
	
	New(LblInfo[0], Init(56, 21, Name + ' ' + Version, WinAboutBox));
	New(LblInfo[1], Init(56, 33, ReplaceMsg(MSG_BY_TEXT, Author), WinAboutBox));
	New(LblInfo[2], Init(15, 57, Text, WinAboutBox));

	WinAboutBox^.Run;
	Dispose(WinAboutBox, Done);
end;

end.