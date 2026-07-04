unit ABOUTDLG;

interface

uses
	CostaLib, UIIcon, UIButton, UILabel;

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

procedure BtnCloseClick(Sender: PUIObject); far;
begin
	WinAboutBox^.Close;
end;

procedure AboutBox(AppP: PApplication);
var
	Text: String;
begin
	Text := Replace(MSG_ABOUT_TEXT, Placeholder, LibName);
	Text := Replace(Text, Placeholder, LibVersion);
	Text := Replace(Text, Placeholder, LibYear);

	New(WinAboutBox, Init(0, 0, nil));
	with WinAboutBox^ do
	begin
		SetSize(PrintW(Text) + 29, PrintH(Text) + 99);
		Center(OrBoth);
		SaveBackdrop;
	end;

	New(ImgLogo, Init(13, 15, AppP^.Icon, WinAboutBox));
	New(BtnClose, Init(0, WinAboutBox^.Height - 34, CAP_CLOSE, WinAboutBox));
	with BtnClose^ do
	begin
		Center(OrHorizontal);
		AddHotkey(KeyAltC);
		AddHotkey(KeyEnter);
		AddHotkey(KeyEscape);
		OnClick := BtnCloseClick;
	end;

	New(LblInfo[0], Init(56, 21, AppP^.Name + ' ' + AppP^.Version, WinAboutBox));
	New(LblInfo[1], Init(56, 33, Replace(MSG_BY_TEXT, Placeholder, AppP^.Author), WinAboutBox));
	New(LblInfo[2], Init(15, 57, Text, WinAboutBox));

	WinAboutBox^.Run;
	Dispose(WinAboutBox, Done);
	WinAboutBox := nil;
end;

end.