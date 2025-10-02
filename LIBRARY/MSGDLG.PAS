unit MSGDLG;

interface

uses
	Costalib, UIIcon, UIButton, UILabel, Graph;

type
	TMsgBox = (MsgInfo, MsgWarn, MsgQuest, MsgError);

function MsgBox(const MsgTitle, MsgText: string; MsgType: TMsgBox): Boolean;

implementation

const
	CAP_OK      = #127 + 'OK';
	CAP_YES     = #127 + 'Yes';
	CAP_NO      = #127 + 'No';

var
	WinMsgBox: PWindow;
	BtnFirst, BtnSecond: PButton;
	ImgIcon: PIcon;
	LblTitle, LblText: PLabel;

	ReturnValue: Boolean;

procedure BtnFirstClick(Sender: PUIObject); far;
begin
	ReturnValue := True;
	WinMsgBox^.Close;
end;

procedure BtnSecondClick(Sender: PUIObject); far;
begin
	ReturnValue := False;
	WinMsgBox^.Close;
end;

function MsgBox(const MsgTitle, MsgText: string; MsgType: TMsgBox): Boolean;
var
	IconFile: string;
	X1, Y1, X2, Y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Key: String;
begin
	{Calculate size of message box based on text dimensions}
	X2 := PrintW(MsgText) + 68;
	Y2 := PrintH(MsgText) + 78;
	if X2 < 270 then
		X2 := 270;

	New(WinMsgBox, Init(0, 0, NoParent));
	With WinMsgBox^ do
	begin
		SetSize(X2, Y2);
		Center(OrBoth);
		GetPos(X1, Y1, True);
	end;

	case MsgType of
		MsgInfo:  IconFile := 'MSGINFO';
		MsgWarn:  IconFile := 'MSGWARN';
		MsgQuest: IconFile := 'MSGQUEST';
		MsgError: IconFile := 'MSGERROR';
	end;
	New(ImgIcon, Init(13, 15, IconFile, WinMsgBox));
	
	if MsgType = MsgQuest then
	begin
		New(BtnFirst, Init((X2 div 2) - 98, Y2 - 36, CAP_YES, WinMsgBox));
		BtnFirst^.AddHotkey(KeyAltY);
	end
	else
	begin
		New(BtnFirst, Init(0, Y2 - 36, CAP_OK, WinMsgBox));
		BtnFirst^.Center(OrHorizontal);
		BtnFirst^.AddHotkey(KeyAltO);
	end;
	BtnFirst^.AddHotkey(KeyEnter);
	BtnFirst^.SetOnClick(BtnFirstClick);
	if MsgType = MsgQuest then
	begin
		New(BtnSecond, Init((X2 div 2) + 6, Y2 - 36, CAP_NO, WinMsgBox));
		With BtnSecond^ do
		begin
			AddHotkey(KeyAltN);
			AddHotkey(KeyEscape);
			SetOnClick(BtnSecondClick);
		end;
	end;
	New(LblTitle, Init(56, 15, MsgTitle, WinMsgBox));
	New(LblText, Init(56, 31, MsgText, WinMsgBox));
	
	{Save background to restore when Window is closed}
	Inc(X2, X1); {X2/Y2 contain width and height, add X1/Y1 to get actual coordinates}
	Inc(Y2, Y1);
	Mouse.Hide;
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);
	Mouse.Show;

	WinMsgBox^.Run;
	MsgBox := ReturnValue;

	Mouse.Hide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	Mouse.Show;
end;

end.