unit DeskMenu;

interface

uses
	UIDesk, DOS;

type
	TLinkAction = (laNone, laOpen, laEdit, laMove, laRemove);

function LinkMenu(Link: PLink): TLinkAction;


implementation

uses
	CostaLib, UIButton, UIIcon, UILabel, MsgDlg, DeskEdit;

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


procedure ButtonClick(Sender: PUIObject); far;
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

procedure WinLinkMenuDraw(Sender: PUIObject); far;
const
	MaxSLength = 43; {Filename label max length}
	MaxLLength = 36; {Path + parameters max length}
var
	Filename,
	Parameters: string;
	Path: DirStr;
	FName: NameStr;
	FExt: ExtStr;
begin
	Filename := TargetLink^.FileName;
	Path := TargetLink^.Path;
	Parameters := TargetLink^.Parameters;

	{If path or parameters are empty, show "Unspecified" or "None" respectively}
	if Length(Path) = 0 then
	begin
		{Try getting path from filename}
		FSplit(Filename, Path, FName, FExt);
		{If still empty, show "Unspecified"}
		if Length(Path) = 0 then
			Path := CAP_UNSPECIFIED
		else
			{If we took path from filename, just show filename and extension without path}
			Filename := FName + FExt;
	end;

	if Length(Parameters) = 0 then
		Parameters := CAP_NONE;

	{Truncate if too long}
	if Length(FileName) > MaxSLength then
		FileName := '...' + Copy(FileName, Length(FileName) - (MaxSLength - 3) + 1, MaxSLength - 3);
	if Length(Path) > MaxLLength then
		Path := Copy(Path, 1, MaxLLength - 3) + '...';
	if Length(Parameters) > MaxLLength then
		Parameters := Copy(Parameters, 1, MaxLLength - 3) + '...';

	LblLinkInfo^.SetCaption(TargetLink^.Caption + #13 + Filename);
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
		OnDraw := WinLinkMenuDraw;
		SaveBackdrop;
	end;
	New(BtnOpen, Init(12, 101, CAP_OPEN, WinLinkMenu));
	with BtnOpen^ do
	begin
		SetSize(389, SizeRetain);
		AddHotkey(KeyAltO);
		AddHotkey(KeyEnter);
		OnClick := ButtonClick;
	end;
	New(BtnEdit, Init(12, 131, CAP_EDIT, WinLinkMenu));
	with BtnEdit^ do
	begin
		AddHotkey(KeyAltE);
		OnClick := ButtonClick;
	end;
	New(BtnMove, Init(111, 131, CAP_MOVE, WinLinkMenu));
	with BtnMove^ do
	begin
		AddHotkey(KeyAltM);
		OnClick := ButtonClick;
	end;
	New(BtnRemove, Init(210, 131, CAP_REMOVE, WinLinkMenu));
	with BtnRemove^ do
	begin
		AddHotkey(KeyAltR);
		OnClick := ButtonClick;
	end;
	New(BtnCancel, Init(309, 131, CAP_CANCEL, WinLinkMenu));
	with BtnCancel^ do
	begin
		AddHotkey(KeyAltC);
		AddHotkey(KeyEscape);
		OnClick := ButtonClick;
	end;
	New(ImgIcon, Init(12, 11, TargetLink^.IconFile, WinLinkMenu));

	New(LblLinkInfo, Init(54, 17, '', WinLinkMenu));
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