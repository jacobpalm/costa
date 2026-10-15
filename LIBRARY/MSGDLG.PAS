unit MSGDLG;

interface

uses
	Costalib, UIIcon, UIButton, UILabel;

type
	TMsgBoxType = (MsgInfo, MsgWarn, MsgYesNo, MsgQuest, MsgError);
	TMsgBoxButtonCount = 0..1;

	TMsgBox = Object(TWindow)
		public
			ButtonCount: TMsgBoxButtonCount;
	end;
function MsgBox(const MsgText: string; MsgType: TMsgBoxType): Boolean;

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
	LblText:     PLabel;

	MsgBoxType:  TMsgBoxType; {Audible alert needs to know type of message to select sound}

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

function MsgBox(const MsgText: string; MsgType: TMsgBoxType): Boolean;
begin
	New(WinMsgBox, Init(0, 0, NoParent));
	With WinMsgBox^ do
	begin
		Width := PrintW(MsgText) + 70;
		if Width < 270 then Width := 270;
		Height := PrintH(MsgText) + 54;
		if Height < 96 then Height := 96;
		Center(OrBoth);
		SaveBackdrop;
		OnDraw := WinMsgBoxDraw;
	end;

	New(ImgIcon, Init(7, 7, '', WinMsgBox));
	case MsgType of
		MsgInfo:  ImgIcon^.IconFile := 'MSGINFO';
		MsgWarn:  ImgIcon^.IconFile := 'MSGWARN';
		MsgError: ImgIcon^.IconFile := 'MSGERROR';
		MsgYesNo,
		MsgQuest: ImgIcon^.IconFile := 'MSGQUEST';
	end;
	MsgBoxType := MsgType;

	New(BtnFirst, Init(0, WinMsgBox^.Height - 41, '', WinMsgBox));
	BtnFirst^.AddHotkey(KeyEnter);
	BtnFirst^.OnClick := BtnClick;

	if MsgType = MsgYesNo then
	begin
		BtnFirst^.Caption := CAP_YES;
		BtnFirst^.Left := (WinMsgBox^.Width div 2) - 98 - WinMsgBox^.GetBorderWidth;
		BtnFirst^.AddHotkey(KeyAltY);

		New(BtnSecond, Init((WinMsgBox^.Width div 2) + 6 - WinMsgBox^.GetBorderWidth, WinMsgBox^.Height - 41, CAP_NO, WinMsgBox));
		With BtnSecond^ do
		begin
			AddHotkey(KeyAltN);
			AddHotkey(KeyEscape);
			OnClick := BtnClick;
		end;
	end
	else
	begin
		{Message, not a question, so only one button - center it}
		BtnFirst^.Caption := CAP_OK;
		BtnFirst^.Center(OrHorizontal);
		BtnFirst^.AddHotkey(KeyAltO);
	end;

	New(LblText, Init(52, 7, MsgText, WinMsgBox));

	WinMsgBox^.Run;
	Dispose(WinMsgBox, Done);
	WinMsgBox := nil;
	MsgBox := ReturnValue;
end;

end.