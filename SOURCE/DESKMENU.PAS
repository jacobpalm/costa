unit DeskMenu;

interface

uses
	UIDesk;

type
	TLinkAction = (laNone, laOpen, laEdit, laMove, laRemove);

function LinkMenu(Link: PLink): TLinkAction;


implementation

uses
	CostaLib, UIButton, UIIcon, UILabel, MsgDlg, DeskEdit, Strings;

const
	CAP_OPEN                  = #127 + 'Open';
	CAP_EDIT                  = #127 + 'Edit...';
	CAP_MOVE                  = #127 + 'Move';
	CAP_REMOVE                = #127 + 'Remove';
	CAP_CANCEL                = #127 + 'Cancel';
	CAP_PATH                  = 'Path:';
	CAP_UNSPECIFIED           = 'Unspecified';
	CAP_PARAMETERS            = 'Parameters:';
	CAP_NONE                  = 'None';

var
	WinLinkMenu:        PWindow;
	BtnOpen,
	BtnEdit,
	BtnMove,
	BtnRemove,
	BtnCancel:          PButton;
	ImgIcon:            PIcon;
	LblLinkInfo,
	LblPath,
	LblParameters,
	LblPathValue,
	LblParametersValue: PLabel;

	TargetLink:         PLink;
	LinkAction:         TLinkAction;


procedure Button_Click(Sender: PUIObject); far;
begin
	if Sender = PUIObject(BtnOpen) then
		LinkAction := laOpen
	else if Sender = PUIObject(BtnEdit) then
		LinkAction := laEdit
	else if Sender = PUIObject(BtnMove) then
		LinkAction := laMove
	else if Sender = PUIObject(BtnRemove) then
		LinkAction := laRemove
	else
		LinkAction := laNone;
	
	WinLinkMenu^.Close;
end;

procedure WinLinkMenu_Draw(Sender: PUIObject); far;
var
	Path,
	Parameters: string;
begin
	Path := TargetLink^.Path;
	Parameters := TargetLink^.Parameters;

	{If path or parameters are empty, show "Unspecified" or "None" respectively}
	if Length(Path) = 0 then
		Path := CAP_UNSPECIFIED;
	if Length(Parameters) = 0 then
		Parameters := CAP_NONE;

	{Truncate if too long}
	if Length(Path) > 36 then
		Path := Copy(Path, 1, 33) + '...';
	if Length(Parameters) > 36 then
		Parameters := Copy(Parameters, 1, 33) + '...';
	
	LblPathValue^.SetCaption(Path);
	LblParametersValue^.SetCaption(Parameters);
end;

procedure InitUI;
begin
	New(WinLinkMenu, Init(0, 0, WinLinkMenu));
	with WinLinkMenu^ do
	begin
		SetSize(413, 165);
		Center(OrBoth);
		SetOnDraw(WinLinkMenu_Draw);
		SaveBackdrop;
	end;
	New(BtnOpen, Init(12, 101, CAP_OPEN, WinLinkMenu));
	with BtnOpen^ do
	begin
		SetSize(389, SizeRetain);
		AddHotkey(KeyAltO);
		AddHotkey(KeyEnter);
		SetOnClick(Button_Click);
	end;
	New(BtnEdit, Init(12, 131, CAP_EDIT, WinLinkMenu));
	with BtnEdit^ do
	begin
		AddHotkey(KeyAltE);
		SetOnClick(Button_Click);
	end;
	New(BtnMove, Init(111, 131, CAP_MOVE, WinLinkMenu));
	with BtnMove^ do
	begin
		AddHotkey(KeyAltM);
		SetOnClick(Button_Click);
	end;
	New(BtnRemove, Init(210, 131, CAP_REMOVE, WinLinkMenu));
	with BtnRemove^ do
	begin
		AddHotkey(KeyAltR);
		SetOnClick(Button_Click);
	end;
	New(BtnCancel, Init(309, 131, CAP_CANCEL, WinLinkMenu));
	with BtnCancel^ do
	begin
		AddHotkey(KeyAltC);
		AddHotkey(KeyEscape);
		SetOnClick(Button_Click);
	end;
	New(ImgIcon, Init(12, 11, TargetLink^.IconFile, WinLinkMenu));

	New(LblLinkInfo, Init(54, 17, TargetLink^.Caption + #13 + TargetLink^.Filename, WinLinkMenu));
	New(LblPath, Init(12, 59, CAP_PATH, WinLinkMenu));
	New(LblPathValue, Init(108, 59, '', WinLinkMenu));
	New(LblParameters, Init(12, 76, CAP_PARAMETERS, WinLinkMenu));
	New(LblParametersValue, Init(108, 76, '', WinLinkMenu));
end;

function LinkMenu(Link: PLink): TLinkAction;
begin
	{Can't show menu for a link that doesn't exist}
	if not Assigned(Link) then
	begin
		LinkMenu := laNone;
		Exit;
	end;

	TargetLink := Link;
	
	InitUI;
	WinLinkMenu^.Run;
	Dispose(WinLinkMenu, Done);
	WinLinkMenu := nil;
	TargetLink := nil;
	LinkMenu := LinkAction;
end;

end.