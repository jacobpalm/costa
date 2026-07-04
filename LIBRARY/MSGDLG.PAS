unit MSGDLG;

interface

uses
	Costalib, UIIcon, UIButton, UILabel;

type
	TMsgBox = (MsgInfo, MsgWarn, MsgQuest, MsgError);

function MsgBox(const MsgTitle, MsgText: string; MsgType: TMsgBox): Boolean;

implementation

const
	CAP_OK      = #127 + 'OK';
	CAP_YES     = #127 + 'Yes';
	CAP_NO      = #127 + 'No';

var
	WinMsgBox:   PWindow;
	BtnFirst,
	BtnSecond:   PButton;
	ImgIcon:     PIcon;
	LblTitle,
	LblText:     PLabel;

	MsgBoxType:  TMsgBox; {Audible alert needs to know type of message to select sound}

	ReturnValue: Boolean;

procedure BtnClick(Sender: PUIObject); far;
begin
	ReturnValue := (Sender = PUIObject(BtnFirst)); {True if sender is BtnFirst, False if BtnSecond}
	WinMsgBox^.Close;
end;

procedure WinMsgBoxDraw(Sender: PUIObject); far;
begin
	if MsgBoxType = MsgError then
		SystemSound(sndError)
	else
		SystemSound(sndAttention);
end;

function MsgBox(const MsgTitle, MsgText: string; MsgType: TMsgBox): Boolean;
begin
	New(WinMsgBox, Init(0, 0, NoParent));
	With WinMsgBox^ do
	begin
		Width := PrintW(MsgText) + 68;
		if Width < 270 then Width := 270;
		Height := PrintH(MsgText) + 78;
		Center(OrBoth);
		SaveBackdrop;
		OnDraw := WinMsgBoxDraw;
	end;

	New(ImgIcon, Init(13, 15, '', WinMsgBox));
	case MsgType of
		MsgInfo:  ImgIcon^.IconFile := 'MSGINFO';
		MsgWarn:  ImgIcon^.IconFile := 'MSGWARN';
		MsgQuest: ImgIcon^.IconFile := 'MSGQUEST';
		MsgError: ImgIcon^.IconFile := 'MSGERROR';
	end;
	MsgBoxType := MsgType;

	if MsgType = MsgQuest then
	begin
		New(BtnFirst, Init((WinMsgBox^.Width div 2) - 98, WinMsgBox^.Height - 36, CAP_YES, WinMsgBox));
		BtnFirst^.AddHotkey(KeyAltY);
	end
	else
	begin
		New(BtnFirst, Init(0, WinMsgBox^.Height - 36, CAP_OK, WinMsgBox));
		BtnFirst^.Center(OrHorizontal);
		BtnFirst^.AddHotkey(KeyAltO);
	end;
	BtnFirst^.AddHotkey(KeyEnter);
	BtnFirst^.OnClick := BtnClick;
	if MsgType = MsgQuest then
	begin
		New(BtnSecond, Init((WinMsgBox^.Width div 2) + 6, WinMsgBox^.Height - 36, CAP_NO, WinMsgBox));
		With BtnSecond^ do
		begin
			AddHotkey(KeyAltN);
			AddHotkey(KeyEscape);
			OnClick := BtnClick;
		end;
	end;
	New(LblTitle, Init(56, 15, MsgTitle, WinMsgBox));
	New(LblText, Init(56, 31, MsgText, WinMsgBox));

	WinMsgBox^.Run;
	Dispose(WinMsgBox, Done);
	WinMsgBox := nil;
	MsgBox := ReturnValue;
end;

end.