unit MSGDLG;

interface

uses
	Costalib, UIIcon, UIButton, Graph;

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

procedure BtnFirstClick(Sender: PUIObject); far;
begin
	ReturnValue := True;
	MsgBoxDone := True;
end;

procedure BtnSecondClick(Sender: PUIObject); far;
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

	WinMsgBox.Init(0, 0, NoParent);
	WinMsgBox.SetSize(BoxW, BoxH);
	WinMsgBox.Center(OrBoth);
	winMsgBox.GetPos(X1, Y1, True);
	winMsgBox.GetSize(X2, Y2);
	Inc(X2, X1);
	Inc(Y2, Y1);

	case MsgType of
		MsgInfo:  IconFile := 'MSGINFO';
		MsgWarn:  IconFile := 'MSGWARN';
		MsgQuest: IconFile := 'MSGQUEST';
		MsgError: IconFile := 'MSGERROR';
	end;
	ImgIcon.Init(X1 + 13, Y1 + 15, IconFile, @WinMsgBox);
	
	if MsgType = MsgQuest then
	begin
		BtnFirst.Init(224, Y2 - 36, CAP_YES, @WinMsgBox);
		BtnFirst.AddHotkey(KeyAltY);
	end
	else
	begin
		BtnFirst.Init(0, Y2 - 36, CAP_OK, @WinMsgBox);
		BtnFirst.Center(OrHorizontal);
		BtnFirst.AddHotkey(KeyAltO);
	end;
	BtnFirst.AddHotkey(KeyEnter);
	BtnFirst.SetOnClick(BtnFirstClick);
	if MsgType = MsgQuest then
	begin
		BtnSecond.Init(324, Y2 - 36, CAP_NO, @WinMsgBox);
		BtnSecond.AddHotkey(KeyAltN);
		BtnSecond.AddHotkey(KeyEscape);
		BtnSecond.SetOnClick(BtnSecondClick);
	end;

	Mouse.Hide;

	{Save background to restore when Window is closed}
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);

	WinMsgBox.Draw;
	BtnFirst.Draw;
	if MsgType = MsgQuest then
		BtnSecond.Draw;
	ImgIcon.Draw;
	{DEBUG - uses label below instead of printing directly}
	Print(MsgTitle, X1 + 56, Y1 + 15, Thm.WinText);
	Print(MsgText, X1 + Y1 + 56, Y1 + 31, Thm.WinText);
	Mouse.Show;

	repeat
		Key := GetKey;
		HotkeyInput := Key; {DEBUG - move to event loop later}
		
		BtnFirst.CheckEvent;
		if MsgType = MsgQuest then
			BtnSecond.CheckEvent;
	until MsgboxDone;

	MsgBox := ReturnValue;
	Mouse.Hide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	Mouse.Show;
end;

end.