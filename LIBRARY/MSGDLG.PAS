unit MSGDLG;

interface

uses
	Costalib, UIWindow, UIIcon, UIButton, Graph;

type
	TMsgBox = (MsgInfo, MsgWarn, MsgQuest, MsgError);

function MsgBox(const MsgTitle, MsgText: string; MsgType: TMsgBox): Boolean;

implementation

const
	CAP_OK      = #127 + 'OK';
	CAP_YES     = #127 + 'Yes';
	CAP_NO      = #127 + 'No';

var
	MsgBoxDone: Boolean;
	MsgBoxType: TMsgBox;
	ReturnValue: Boolean;

procedure BtnFirstClick(Sender: PBaseObject); far;
begin
	ReturnValue := True;
	MsgBoxDone := True;
end;

procedure BtnSecondClick(Sender: PBaseObject); far;
begin
	ReturnValue := False;
	MsgBoxDone := True;
end;

function MsgBox(const MsgTitle, MsgText: string; MsgType: TMsgBox): Boolean;
var
	WinMsgBox: TWindow;
	BtnFirst, BtnSecond: TButton;
	ImgIcon: TIcon;
	IconFile: string;
	BoxW, BoxH: Integer;
	X1, Y1, X2, Y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Key: String;
begin
	MsgBoxDone := False;
	MsgBoxType := MsgType;

	BoxW := PrintW(MsgText) + 68;
	BoxH := PrintH(MsgText) + 78;
	if BoxW < 270 then
		BoxW := 270;

	WinMsgBox.Init(sizeCenter, sizeCenter, BoxW, BoxH);
	case MsgType of
		MsgInfo:  IconFile := 'MSGINFO';
		MsgWarn:  IconFile := 'MSGWARN';
		MsgQuest: IconFile := 'MSGQUEST';
		MsgError: IconFile := 'MSGERROR';
	end;
	ImgIcon.Init(WinMsgBox.Left + 13, WinMsgBox.Top + 15, IconFile);
	
	if MsgType = MsgQuest then
	begin
		BtnFirst.Init(224, WinMsgBox.Top + WinMsgBox.Height - 36, SizeDefault, SizeDefault, CAP_YES);
		BtnFirst.AddHotkey(KeyAltY);
	end
	else
	begin
		BtnFirst.Init(sizeCenter, WinMsgBox.Top + WinMsgBox.Height - 36, SizeDefault, SizeDefault, CAP_OK);
		BtnFirst.AddHotkey(KeyAltO);
	end;
	BtnFirst.AddHotkey(KeyEnter);
	BtnFirst.OnClick := BtnFirstClick;
	if MsgType = MsgQuest then
	begin
		BtnSecond.Init(324, BtnFirst.Top, SizeDefault, SizeDefault, CAP_NO);
		BtnSecond.AddHotkey(KeyAltN);
		BtnSecond.AddHotkey(KeyEscape);
		BtnSecond.OnClick := BtnSecondClick;
	end;

	MouseHide;

	{Save background to restore when Window is closed}
	X1 := WinMsgBox.Left;
	Y1 := WinMsgBox.Top;
	X2 := WinMsgBox.Left + WinMsgBox.Width;
	Y2 := WinMsgBox.Top + WinMsgBox.Height;
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);

	WinMsgBox.Draw;
	BtnFirst.Draw;
	if MsgType = MsgQuest then
		BtnSecond.Draw;
	ImgIcon.Draw;
	Print(MsgTitle, WinMsgBox.Left+56, WinMsgBox.Top+15, Thm.WinText);
	Print(MsgText, WinMsgBox.Left+56, WinMsgBox.Top+31, Thm.WinText);
	MouseShow;

	repeat
		Key := GetKey;
		HotkeyPressed := Key; {DEBUG - move to event loop later}
		
		BtnFirst.CheckEvent;
		if MsgType = MsgQuest then
			BtnSecond.CheckEvent;
	until MsgboxDone;

	MsgBox := ReturnValue;
	MouseHide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;
end;

end.