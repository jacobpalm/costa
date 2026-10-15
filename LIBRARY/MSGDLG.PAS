unit MSGDLG;

interface

uses
	Costalib, UIIcon, UIButton, UILabel;

type
	TMsgBoxType = (MsgInfo, MsgWarn, MsgQuest, MsgError);
	TMsgBoxButton = 0..1;

	PMsgBox = ^TMsgBox;
	TMsgBox = Object
		public
			ReturnValue: Boolean;

			constructor Init;
			destructor  Done;

			procedure   SetType(MsgType: TMsgBoxType);
			function    GetType: TMsgBoxType;
			procedure   SetMessage(Message: String);

			procedure   SetButtonCaption(Button: TMsgBoxButton; Caption: String);
			procedure   AddButtonHotkey(Button: TMsgBoxButton; HotKey: String);

			procedure   Show;
			procedure   Close;
		private
			WinMsgBox:   PWindow;
			BtnChoice:   Array[0..1] of PButton;
			ImgIcon:     PIcon;
			LblMessage:  PLabel;
			MsgBoxType:  TMsgBoxType; {Audible alert needs to know type of message to select sound}
	end;

function MsgBox(const MsgText: string; MsgType: TMsgBoxType): Boolean;
function MsgChoice(const MsgText, FirstCaption, FirstHotkey, SecondCaption, SecondHotkey: string): Boolean;

implementation

const
	CAP_OK      = #127 + 'OK';
	CAP_YES     = #127 + 'Yes';
	CAP_NO      = #127 + 'No';

var
	MsgBoxObj:  PMsgBox;

{----------------------------------------------------------------------------}
{ Wrapper for standard MsgBox
{----------------------------------------------------------------------------}

function MsgBox(const MsgText: string; MsgType: TMsgBoxType): Boolean;
var
	ReturnValue: Boolean;
begin
	if MsgType = MsgQuest then
		Exit;

	if Assigned(MsgBoxObj) then
		Dispose(MsgBoxObj, Done);

	MsgBoxObj := New(PMsgBox, Init);
	MsgBoxObj^.SetType(MsgType);
	MsgBoxObj^.SetMessage(MsgText);
	MsgBoxObj^.Show;
	ReturnValue := MsgBoxObj^.ReturnValue;
	Dispose(MsgBoxObj, Done);
	MsgBoxObj := nil;

	MsgBox := ReturnValue;
end;

function MsgChoice(const MsgText, FirstCaption, FirstHotkey, SecondCaption, SecondHotkey: string): Boolean;
var
	ReturnValue: Boolean;
begin
	if Assigned(MsgBoxObj) then
		Dispose(MsgBoxObj, Done);

	MsgBoxObj := New(PMsgBox, Init);
	MsgBoxObj^.SetType(MsgQuest);
	MsgBoxObj^.SetButtonCaption(0, FirstCaption);
	MsgBoxObj^.SetButtonCaption(1, SecondCaption);
	MsgBoxObj^.AddButtonHotkey(0, FirstHotkey);
	MsgBoxObj^.AddButtonHotkey(1, SecondHotkey);
	MsgBoxObj^.SetMessage(MsgText);
	MsgBoxObj^.Show;
	ReturnValue := MsgBoxObj^.ReturnValue;
	Dispose(MsgBoxObj, Done);
	MsgBoxObj := nil;

	MsgChoice := ReturnValue;
end;


{----------------------------------------------------------------------------}
{ Event handlers
{----------------------------------------------------------------------------}

procedure BtnChoice0Click(Sender: PUIObject); far;
begin
	MsgBoxObj^.ReturnValue := True;
	MsgBoxObj^.Close;
end;

procedure BtnChoice1Click(Sender: PUIObject); far;
begin
	MsgBoxObj^.ReturnValue := False;
	MsgBoxObj^.Close;
end;

procedure WinMsgBoxDraw(Sender: PUIObject); far;
begin
	if MsgBoxObj^.GetType = MsgError then
		SystemSound(sndError)
	else
		SystemSound(sndAttention);
end;


{----------------------------------------------------------------------------}
{ TMsgBox methods
{----------------------------------------------------------------------------}

constructor TMsgBox.Init;
begin
	MsgBoxType  := MsgInfo;
	ReturnValue := False;

	{Initialize the UI - size, captions and hotkeys are handled when dialog is shown}
	New(WinMsgBox, Init(0, 0, NoParent));
	WinMsgBox^.SaveBackdrop;
	WinMsgBox^.OnDraw := WinMsgBoxDraw;

	New(ImgIcon, Init(7, 7, '', WinMsgBox));
	New(LblMessage, Init(52, 7, '', WinMsgBox));

	New(BtnChoice[0], Init(0, 0, '', WinMsgBox));
	BtnChoice[0]^.AddHotkey(KeyEnter);
	BtnChoice[0]^.OnClick := BtnChoice0Click;

	New(BtnChoice[1], Init(0, 0, '', WinMsgBox));
	BtnChoice[1]^.AddHotkey(KeyEscape);
	BtnChoice[1]^.OnClick := BtnChoice1Click;
end;

procedure TMsgBox.SetType(MsgType: TMsgBoxType);
begin
	MsgBoxType := MsgType;

	{Show second button if type is MsgQuest, otherwise show
	 only one button}
	if MsgType = MsgQuest then
	begin
		BtnChoice[1]^.RemoveState(SHidden);
		BtnChoice[1]^.AddState(SEnabled);
	end
	else
	begin
		BtnChoice[1]^.AddState(SHidden);
		BtnChoice[1]^.RemoveState(SEnabled);
	end;

	case MsgType of
		MsgInfo:  ImgIcon^.IconFile := 'MSGINFO';
		MsgWarn:  ImgIcon^.IconFile := 'MSGWARN';
		MsgError: ImgIcon^.IconFile := 'MSGERROR';
		MsgQuest: ImgIcon^.IconFile := 'MSGQUEST';
	end;

	case MsgType of
		MsgInfo,
		MsgWarn,
		MsgError:
			begin
				Self.SetButtonCaption(0, CAP_OK);
				Self.AddButtonHotkey(0, KeyAltO);
			end;
	end;
end;

function TMsgBox.GetType: TMsgBoxType;
begin
	GetType := MsgBoxType;
end;

procedure TMsgBox.SetMessage(Message: String);
begin
	LblMessage^.SetCaption(Message);
end;

procedure TMsgBox.SetButtonCaption(Button: TMsgBoxButton; Caption: String);
begin
	BtnChoice[Button]^.SetCaption(Caption);
end;

procedure TMsgBox.AddButtonHotkey(Button: TMsgBoxButton; HotKey: String);
begin
	BtnChoice[Button]^.AddHotkey(HotKey);
end;

procedure TMsgBox.Show;
var
	HorizCenter, ButtonWidth: Integer;
begin
	with WinMsgBox^ do
	begin
		Width := PrintW(LblMessage^.Caption) + 70;
		if Width < 270 then Width := 270;
		Height := PrintH(LblMessage^.Caption) + 54;
		if Height < 96 then Height := 96;
		Center(OrBoth);
	end;

	ButtonWidth := PrintW(BtnChoice[0]^.Caption);
	if PrintW(BtnChoice[1]^.Caption) > ButtonWidth then
		ButtonWidth := PrintW(BtnChoice[1]^.Caption);
	Inc(ButtonWidth, 14);
	if ButtonWidth < 92 then
		ButtonWidth := 92;
	BtnChoice[0]^.Width := ButtonWidth;
	BtnChoice[1]^.Width := ButtonWidth;

	{Center buttons - MsgQuest has two buttons so centering is slightly trickier}
	if MsgBoxType = MsgQuest then
	begin
		HorizCenter := (WinMsgBox^.Width div 2) - WinMsgBox^.GetBorderWidth;
		BtnChoice[0]^.Left := HorizCenter - BtnChoice[0]^.Width - 6;
		BtnChoice[1]^.Left := HorizCenter + 6;
	end
	else
		BtnChoice[0]^.Center(OrHorizontal);

	{Place buttons at the bottom of the dialog}
	BtnChoice[0]^.Top := WinMsgBox^.Height - 35 - WinMsgBox^.GetBorderWidth;
	BtnChoice[1]^.Top := BtnChoice[0]^.Top;

	WinMsgBox^.Run;
end;

procedure TMsgBox.Close;
begin
	WinMsgBox^.Close;
end;

destructor TMsgBox.Done;
begin
	Dispose(WinMsgBox, Done);
	WinMsgBox := nil;
end;

end.