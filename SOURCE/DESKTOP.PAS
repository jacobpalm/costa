program Desktop;

uses
    Costalib, FileSel, Graph, Crt, Strings;

const
    AppName    = 'Desktop';
    AppVersion = '2.0';
    AppAuthor  = 'Jacob Palm';
    AppIcon    = 'LOGO';

    GridSize   = 8;            {Size of grid in pixels, used for aligning icons}

type
    PLink = ^TLink;
    TLink = record
		Caption: String[25];
		FileName: String[50];
		Path: String[50];
		Parameters: String[50];
		ImageFile: String[8];
		PauseOnExit: Boolean;
		Left, Top: Integer;
	end;

    PLinkArray = ^TLinkArray;
	TLinkArray = Array[1..1] of PLink; {Flexible array to simulate dynamic sizing}

var
    DeskLink: PLinkArray;
    DeskLinkCount: Integer;
    btnAddLink, btnRunCmd, btnAboutCosta, btnExitCosta: ButtonType;
    btnPrevious, btnNext, btnTab: ButtonType;
    imgTab: ImageType;
    DeskLinkCheck, ClickedX, ClickedY: Integer;
    ClickedB: TMouseButton;
    CheckDesktopID, TabCheck: Integer;
    DidEdit, DoExit, DoDelete: boolean;
    Key: String;

{Forward declarations}
    procedure DeskDrawDesktop; forward;
    procedure DeskExecuteDialog; forward;
    procedure DeskLinkDialog(TargetLink: integer; DidEdit: boolean); forward;
    procedure DeskLinkLoad; forward;
    procedure DeskLinkMenu(TargetLink: integer); forward;
    procedure DeskLinkMove(TargetLink: integer); forward;
    procedure DeskLinkSave; forward;
    procedure DeskRun(TargetFile, TargetParameters, TargetPath: string; PauseOnExit: boolean); forward;

procedure DeskDrawDesktop;
var
	imgDeskLinkIcon: ImageType;
	TargetLink: integer;
	LinkTargetText: string;
begin
	MouseHide;
    SetFillStyle(SolidFill, Theme.Desktop);
	Bar(0, 29, 639, 349);
	
	{All desklinks will always have an imagefile. Use this to check if any
	 desklinks exist}
	{if RTrim(DeskLink(0).ImageFile) = '' or DeskLink(0).Caption = STRING$(25, 0) then
    begin
		MouseShow;
		exit;
	end;}

	{Draw desklinks one by one, using imgDeskLinkIcon to draw the imagefile of
	 each desklink}
	{for TargetLink = 0 to UBOUND(DeskLink)
    begin}

		{For compatibility - old versions used higher vertical resolution, icons
		 may be out of view if old data file is carried over}
		{if DeskLink(TargetLink).Top > 318 then DeskLink(TargetLink).Top = 318
	
		imgDeskLinkIcon.ImageFile = DeskLink(TargetLink).ImageFile
		imgDeskLinkIcon.Pos.Left = DeskLink(TargetLink).Left
		imgDeskLinkIcon.Pos.Top = DeskLink(TargetLink).Top
	
		ObjDrawImg(imgDeskLinkIcon
	end;

	if not Setting.ShowLinkDescriptions then
        exit;}

	{Next, draw icon captions}
	{for TargetLink = 0 to UBOUND(DeskLink)
    begin}
		{Description (caption) and target file}
		
		{FontPrint(DeskLink(TargetLink).Caption, DeskLink(TargetLink).Left + 38, DeskLink(TargetLink).Top + 4, Theme.DesktopText, 1);

		if Setting.ShowLinkTargetFiles then
        begin
			LinkTargetText := LCASE$(DeskLink(TargetLink).Filename);}

			{Remove path from string, if present}
			{DO WHILE INSTR(LinkTargetText, '\')
				LinkTargetText := RIGHT$(LinkTargetText, Length(LinkTargetText) - INSTR(LinkTargetText, '\'));
			LOOP

			FontPrint(LinkTargetText, DeskLink(TargetLink).Left + 38, DeskLink(TargetLink).Top + 18, Theme.DesktopText, 2);
		end;
		
	end;}
	
	MouseShow;

end;

procedure DeskExecuteDialog;
var
	winExecute: WindowType;
	txtProgram, txtParameters: TextboxType;
    txtProgramText, txtParametersText: string;
	btnOK, btnCancel, btnBrowse: ButtonType;
	imgIcon: ImageType;
    Key: string;
    SelectedFile, Path: string;
    x1, y1, x2, y2: integer;
    BackgroundSize: Word;
	BackgroundP: Pointer;
begin

    txtProgramText := '';
    txtParametersText := '';

    winExecute.Init(sizeCenter, sizeCenter, 342, 196);
    txtProgram.Init(winExecute.Pos.Left + 12, winExecute.Pos.Top + 86, winExecute.Pos.Width - 54, sizeDefault);
    txtParameters.Init(txtProgram.Pos.Left, txtProgram.Pos.Top + 46, winExecute.Pos.Width - 26, sizeDefault);
    btnBrowse.Init(txtProgram.Pos.Left + txtProgram.Pos.Width + 9, txtProgram.Pos.Top, 19, 19, '...');
    btnOK.Init(winExecute.Pos.Left + winExecute.Pos.Width - 184, txtParameters.Pos.Top + 30, 80, 22, HotkeySymbol + 'OK');
    btnCancel.Init(winExecute.Pos.Left + winExecute.Pos.Width - 94, btnOK.Pos.Top, 80, 22, HotkeySymbol + 'Cancel');
    ObjSetSize(imgIcon.Pos, winExecute.Pos.Left + 12, winExecute.Pos.Top + 20, sizeDefault, sizeDefault);
	imgIcon.ImageFile := 'RUNPROG';
	
	MouseHide;

    x1 := winExecute.Pos.Left;
    y1 := winExecute.Pos.Top;
    x2 := winExecute.Pos.Left + winExecute.Pos.Width;
    y2 := winExecute.Pos.Top + winExecute.Pos.Height;
    BackgroundSize := ImageSize(x1, y1, x2, y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(x1, y1, x2, y2, BackgroundP^);

	ObjDrawWin(winExecute);
	ObjDrawBtn(btnOK, false);
	ObjDrawBtn(btnCancel, false);
	ObjDrawTxt(txtProgram, txtProgramText, false);
	ObjDrawTxt(txtParameters, txtParametersText, false);
	ObjDrawBtn(btnBrowse, false);
	
	ObjDrawImg(imgIcon);

    x2 := winExecute.Pos.Left + 53;
    y2 := winExecute.Pos.Top + 17;
	FontPrint('Execute program', x2, winExecute.Pos.Top + 15, Theme.WindowText, FontHeading);
	FontPrint('You can also use this dialog to open any file', x2, y2 + 15, Theme.WindowText, FontNormal);
	FontPrint('associated with a program (like README.TXT).', x2, y2 + 30, Theme.WindowText, FontNormal);
    y2 := txtProgram.Pos.Top - 16;
	FontPrint(HotkeySymbol + 'Program:', txtProgram.Pos.Left, y2, Theme.WindowText, FontHeading);
    y2 := txtParameters.Pos.Top - 16;
	FontPrint('Pa' + HotkeySymbol + 'rameters:', txtParameters.Pos.Left, y2, Theme.WindowText, FontHeading);
	MouseShow;

	repeat

		Key := GetKey;

		if ObjBtnClick(btnOK) or (Key = KeyAltO) or (Key = KeyEnter) then
        begin
			if Length(txtProgramText) > 0 then
            begin
				{DO WHILE INSTR(txtProgramText, '\')
					path = path + LEFT$(txtProgramText, INSTR(txtProgramText, '\'))
					txtProgramText = RIGHT$(txtProgramText, Length(txtProgramText) - INSTR(txtProgramText, '\'))
				LOOP}
				DeskRun(txtProgramText, txtParametersText, path, true);
			end;
			break;
		end;

		if ObjBtnClick(btnCancel) or (Key = KeyAltC) or (Key = KeyEscape) then
			break;

		if ObjBtnClick(btnBrowse) or ObjTxtClick(txtProgram) or (Key = '.') or (Key = KeyAltP) then
        begin
			SelectedFile := FileSelect('*.exe');
			if Length(SelectedFile) > 0 then
            begin
                txtProgramText := SelectedFile;
                MouseHide;
                ObjDrawTxt(txtProgram, txtProgramText, false);
                MouseShow;
            end;
		end;

		if ObjTxtClick(txtParameters) or (Key = KeyAltR) then
			ObjEditTxt(txtParameters, txtParametersText);

	until false;

    {Restore background}
    MouseHide;
    PutImage(x1, y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
    MouseShow;		
end;

procedure DeskLinkDialog(TargetLink: integer; DidEdit: boolean);
var
	ConfWin: WindowType;
	txtLinkCapt, txtFilename, txtParams, txtPath: TextboxType;
	txtLinkCaptText, txtFileNameText, txtParamsText, txtPathText: string;
	btnIconNext, btnIconPrev: ButtonType;
	btnOK, btnCancel, btnBrowse: ButtonType;
	frmIconFrame: FrameType;
	imgIcon: ImageType;
	chkPauseOnExit: CheckBoxType;
    Key: string;
	AllIcons: array[1..1] of string;
	SelectedFile, ExtractPath, IconFile: string;
	IconCount, CurrentIcon: integer;
begin

	{SysShowLoading

	IconFile = DIR$('DATA\IMAGES\*.BSV')
	IconCount = 0

	REDIM PRESERVE AllIcons(0) AS STRING
	if not IconFile = '' then
		DO
            REDIM PRESERVE AllIcons(0 to IconCount) AS STRING
            AllIcons(IconCount) = LEFT$(IconFile, Length(IconFile) - 4)
            
            if AllIcons(IconCount) = RTrim(DeskLink(TargetLink).ImageFile) then CurrentIcon = IconCount

            IconCount = IconCount + 1
            IconFile = DIR$
		LOOP UNTIL IconFile = ''
	else
	IconFile = 'UNKNOWN'
	AllIcons(0) = 'UNKNOWN'
	end;

	ObjSetSize(ConfWin.Pos, 210, 35, 220, 312

	ObjSetSize(frmIconFrame.Pos, 296, ConfWin.Pos.Top + 12, 48, 48
	ObjSetSize(imgIcon.Pos, 304, frmIconFrame.Pos.Top + 8, 32, 32
	ObjSetSize(btnIconPrev.Pos, 262, frmIconFrame.Pos.Top + 13, 22, 22
	ObjSetSize(btnIconNext.Pos, 356, frmIconFrame.Pos.Top + 13, 22, 22

	ObjSetSize(txtLinkCapt.Pos, 222, frmIconFrame.Pos.Top + 73, 196, 19
	ObjSetSize(txtFilename.Pos, 222, txtLinkCapt.Pos.Top + 44, 173, 19
	ObjSetSize(btnBrowse.Pos, 399, txtFilename.Pos.Top, 19, 19
	ObjSetSize(txtParams.Pos, 222, txtFilename.Pos.Top + 44, 196, 19
	ObjSetSize(txtPath.Pos, 222, txtParams.Pos.Top + 44, 196, 19
	ObjSetSize(chkPauseOnExit.Pos, 222, txtPath.Pos.Top + 32, sizeRetain, sizeRetain
	ObjSetSize(btnOK.Pos, 229, chkPauseOnExit.Pos.Top + 28, 84, 22
	ObjSetSize(btnCancel.Pos, 326, btnOK.Pos.Top, 84, 22

	txtLinkCapt.MaxLen = 25
	txtFilename.MaxLen = 50
	txtParams.MaxLen = 50
	txtPath.MaxLen = 50
	txtFileNameText = RTrim(DeskLink(TargetLink).Filename)
	txtParamsText = RTrim(DeskLink(TargetLink).Parameters)
	txtPathText = RTrim(DeskLink(TargetLink).Path)
	txtLinkCaptText = RTrim(DeskLink(TargetLink).Caption)
	imgIcon.ImageFile = DeskLink(TargetLink).ImageFile
	chkPauseOnExit.Checked = DeskLink(TargetLink).PauseOnExit
	btnBrowse.Caption = '...'
	btnIconPrev.Caption = '<'
	btnIconNext.Caption = '>'
	btnOK.Caption = HotkeySymbol + 'Save'
	btnCancel.Caption = HotkeySymbol + 'Cancel'

LinkDialogDraw:
	MouseHide;
	ObjDrawWin(ConfWin);
	ObjDrawTxt(txtLinkCapt, txtLinkCaptText, false);
	ObjDrawBtn(btnIconPrev, false);
	ObjDrawFrm(frmIconFrame, 15, Theme.Shadow);
	ObjDrawBtn(btnIconNext, false);
	ObjDrawTxt(txtFilename, txtFileNameText, false);
	ObjDrawBtn(btnBrowse, false);
	ObjDrawTxt(txtParams, txtParamsText, false);
	ObjDrawTxt(txtPath, txtPathText, false);
	ObjDrawChk(chkPauseOnExit);
	ObjDrawBtn(btnOK, false);
	ObjDrawBtn(btnCancel, false);
	FontPrint(HotkeySymbol + 'Description (caption):', 222, txtLinkCapt.Pos.Top - 15, Theme.WindowText, 1);
	FontPrint(HotkeySymbol + 'Program:', 222, txtFilename.Pos.Top - 15, Theme.WindowText, 1);
	FontPrint('Pa' + HotkeySymbol + 'rameters:', 222, txtParams.Pos.Top - 15, Theme.WindowText, 1);
	FontPrint('Pa' + HotkeySymbol + 'th (including drive):', 222, txtPath.Pos.Top - 15, Theme.WindowText, 1);
	FontPrint('Pause after e' + HotkeySymbol + 'xecution', 242, chkPauseOnExit.Pos.Top + 3, Theme.WindowText, 2);
	SetFillStyle(SolidFill, Theme.Desktop);
    Bar(frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2, frmIconFrame.Pos.Left +
        frmIconFrame.Pos.Width - 2, frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2);
	ObjDrawImg(imgIcon
	MouseShow;

	DO
		Key = GetKey;

		if ObjBtnClick(btnOK) or Key = KeyEnter or Key = 's' then
			if RTrim(txtLinkCaptText) = '' then txtLinkCaptText = 'Unnamed'
			DeskLink(TargetLink).Caption = RTrim(txtLinkCaptText)
			DeskLink(TargetLink).Filename = RTrim(txtFileNameText)
			DeskLink(TargetLink).Path = RTrim(txtPathText)
			DeskLink(TargetLink).Parameters = RTrim(txtParamsText)
			DeskLink(TargetLink).PauseOnExit = chkPauseOnExit.Checked
			DeskLink(TargetLink).ImageFile = AllIcons(CurrentIcon)
			
			DeskLinkSave
			DidEdit = -1

			exit;
		end;

		if ObjBtnClick(btnCancel) or Key = KeyEscape or Key = 'c' then
			DidEdit = 0
			exit;
		end;

		if ObjBtnClick(btnIconPrev) or Key = KeyLeft then
			CurrentIcon = CurrentIcon - 1
			if CurrentIcon < 0 then CurrentIcon = UBOUND(AllIcons)
			MouseHide;
			SetFillStyle(SolidFill, Theme.Desktop);
            Bar(frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2, frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2,
                frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2);
			imgIcon.ImageFile = AllIcons(CurrentIcon)
			ObjDrawImg(imgIcon
			MouseShow;
		end;

		if ObjBtnClick(btnIconNext) or Key = KeyRight then
			CurrentIcon = CurrentIcon + 1
			if CurrentIcon > UBOUND(AllIcons) then CurrentIcon = 0
			MouseHide;
            SetFillStyle(SolidFill, Theme.Desktop);
			Bar(frmIconFrame.Pos.Left + 2, frmIconFrame.Pos.Top + 2, frmIconFrame.Pos.Left + frmIconFrame.Pos.Width - 2,
                frmIconFrame.Pos.Top + frmIconFrame.Pos.Height - 2);
			imgIcon.ImageFile = AllIcons(CurrentIcon)
			ObjDrawImg(imgIcon);
			MouseShow;
		end;

		if ObjBtnClick(btnBrowse) or Key = '.' then
			SelectedFile = FileSelect('*.exe')
			if not SelectedFile = '' then
				txtPathText = ''Abou
				DO WHILE INSTR(SelectedFile, '\')
					txtPathText = txtPathText + LEFT$(SelectedFile, INSTR(SelectedFile, '\'))
					SelectedFile = RIGHT$(SelectedFile, Length(SelectedFile) - INSTR(SelectedFile, '\'))
				LOOP
				txtFileNameText = SelectedFile
			end;
			DeskDrawDesktop
			GOTO LinkDialogDraw
		end;
	
		if ObjTxtClick(txtLinkCapt) or Key = 'd' then ObjEditTxt(txtLinkCapt, txtLinkCaptText
		if ObjTxtClick(txtFilename) or Key = 'p' then ObjEditTxt(txtFilename, txtFileNameText
		if ObjTxtClick(txtParams) or Key = 'r' then ObjEditTxt(txtParams, txtParamsText
		if ObjTxtClick(txtPath) or Key = 't' then
			ObjEditTxt(txtPath, txtPathText
			if Length(txtPathText) and not RIGHT$(txtPathText, 1) = '\' then
				txtPathText = txtPathText + '\'
				MouseHide;
				ObjDrawTxt(txtPath, txtPathText, false
				MouseShow;
			end;
		end;

		ObjChkClick chkPauseOnExit
		if Key = 'x' then
			chkPauseOnExit.Checked = not chkPauseOnExit.Checked
			MouseHide;
			ObjDrawChk(chkPauseOnExit
			MouseShow;
		end;
			
	LOOP}

end;

procedure DeskLinkLoad;
var
	i: integer;
    f: file;
    DeskLinkFile: string;
    ReadLink: TLink;
	ReadBytes: Integer;
begin
    DeskLinkCount := 0;

    Str(Setting.DesktopID, DeskLinkFile);
	DeskLinkFile := 'CONFIG\DESKLNK' + DeskLinkFile + '.BIN';
	
	if not FileExists(DeskLinkFile) then
    begin
		if FileExists('CONFIG\DESKDEF.BIN') and (Setting.DesktopID = 1) then
			DeskLinkFile := 'CONFIG\DESKDEF.BIN'
		else
        begin
			{DEBUG - clear DeskLink array}
			exit;
		end;
	end;

    Assign(f, DeskLinkFile);
    {$I-}
    Reset(f, 1);
    {$I+}
    if IOResult <> 0 then
    begin
        {DEBUG}
        CloseGraph;
        Writeln('Error reading raw file. File: ', DeskLinkFile);
        Halt(1);
    end;

    {Read the number of links in the file}
    BlockRead(f, DeskLinkCount, SizeOf(DeskLinkCount), ReadBytes);
    {None, exit}
    if DeskLinkCount = 0 then
    begin
        Close(f);
        {DEBUG - clear DeskLink array}
        DeskLink := nil;
        exit;
    end;

    {Load all links from file}
    for i := 0 to DeskLinkCount - 1 do
    begin
        BlockRead(f, ReadLink, SizeOf(ReadLink), ReadBytes);
        if ReadBytes <> SizeOf(ReadLink) then
        begin
            {DEBUG}
            CloseGraph;
            Writeln('Mismatch in size, possible file corruption. File: ', DeskLinkFile);
            Halt(1);
        end;
    end;
    Close(f);
end;

procedure DeskLinkMenu(TargetLink: integer);
var
	winLinkMenu: WindowType;
	btnOpen, btnCustomize, btnMove, btnRemove, btnCancel: ButtonType;
	imgIcon: ImageType;
	
	DidEdit, RedrawNeeded: boolean;
	Key, CroppedText: string;
begin
    winLinkMenu.Init(sizeCenter, sizeCenter, 413, 165);
    btnOpen.Init(winLinkMenu.Pos.Left + 12, winLinkMenu.Pos.Top + winLinkMenu.Pos.Height - 64, 389, 22, HotkeySymbol + 'Open');
    btnCustomize.Init(btnOpen.Pos.Left, btnOpen.Pos.Top + 30, 92, 22, 'C' + HotkeySymbol + 'ustomize');
    btnMove.Init(btnCustomize.Pos.Left + 99, btnCustomize.Pos.Top, 92, 22, HotkeySymbol + 'Move');
    btnRemove.Init(btnMove.Pos.Left + 99, btnCustomize.Pos.Top, 92, 22, HotkeySymbol + 'Remove');
    btnCancel.Init(btnRemove.Pos.Left + 99, btnCustomize.Pos.Top, 92, 22, HotkeySymbol + 'Cancel');
	
	ObjSetSize(imgIcon.Pos, winLinkMenu.Pos.Left + 12, winLinkMenu.Pos.Top + 11, sizeRetain, sizeRetain);
	{imgIcon.ImageFile = DeskLink(TargetLink).ImageFile}

	MouseHide;
	{PCOPY 0, 1} {DEBUG}
	
	ObjDrawWin(winLinkMenu);
	ObjDrawBtn(btnOpen, false);
	ObjDrawBtn(btnCustomize, false);
	ObjDrawBtn(btnMove, false);
	ObjDrawBtn(btnRemove, false);
	ObjDrawBtn(btnCancel, false);
	ObjDrawImg(imgIcon);

	{FontPrint(DeskLink(TargetLink).Caption, winLinkMenu.Pos.Left + 54, winLinkMenu.Pos.Top + 17, 0, FontHeading);
	FontPrint(DeskLink(TargetLink).Filename, winLinkMenu.Pos.Left + 54, winLinkMenu.Pos.Top + 31, 0, FontNormal);}
	FontPrint('Path:', winLinkMenu.Pos.Left + 12, winLinkMenu.Pos.Top + 59, 0, FontNormal);
	FontPrint('Parameters:', winLinkMenu.Pos.Left + 12, winLinkMenu.Pos.Top + 76, 0, FontNormal);
	
	{VIEW SCREEN (winLinkMenu.Pos.Left + 90, winLinkMenu.Pos.Top + 55,
        winLinkMenu.Pos.Left + winLinkMenu.Pos.Width - 12, winLinkMenu.Pos.Top + 90)
	if Length(RTrim(DeskLink(TargetLink).Path)) then
		FontPrint(DeskLink(TargetLink).Path, winLinkMenu.Pos.Left + 92, winLinkMenu.Pos.Top + 59, Theme.WindowText, FontNormal);
	else
		FontPrint('Unspecified', winLinkMenu.Pos.Left + 92, winLinkMenu.Pos.Top + 59, Theme.WindowText, FontNormal);
	end;
	if Length(RTrim(DeskLink(TargetLink).Parameters)) then
		FontPrint(DeskLink(TargetLink).Parameters, winLinkMenu.Pos.Left + 92,
            winLinkMenu.Pos.Top + 76, Theme.WindowText, FontNormal);
	else
		FontPrint('None', winLinkMenu.Pos.Left + 92, winLinkMenu.Pos.Top + 76, Theme.WindowText, FontNormal);
	end;
	VIEW}
	MouseShow;

	{Clear buffers, sometimes needed on DOSBox}
	{repeat; until MouseClicked = mbNone;
	repeat; while Length(GetKey) <> 0;
}
	repeat

		Key := GetKey;
	
		{Cancel, or Escape key}
		if ObjBtnClick(btnCancel) or (Key = 'c') or (Key = KeyEscape) then
			break;
	
		{Open/run, or Enter key}
		if ObjBtnClick(btnOpen) or (Key = 'o') or (Key = KeyEnter) then
        begin
			{DeskRun(RTrim(DeskLink(TargetLink).Filename), RTrim(DeskLink(TargetLink).Parameters),
                RTrim(DeskLink(TargetLink).Path), DeskLink(TargetLink).PauseOnExit}
			RedrawNeeded := true;
			break;
		end;

		{Configure}
		if ObjBtnClick(btnCustomize) or (Key = 'u') then
        begin
			DeskLinkDialog(TargetLink, DidEdit);
			if DidEdit then
                RedrawNeeded := true;
			break;
		end;

		{Move}
		if ObjBtnClick(btnMove) or (Key = 'm') then
        begin
			if RedrawNeeded then
				DeskDrawDesktop
			else
            begin
				MouseHide;
				{PCOPY 1, 0} {DEBUG}
				MouseShow;
			end;

			DeskLinkMove(TargetLink);
			DeskDrawDesktop;
			exit;
		end;

		{Remove}
		if ObjBtnClick(btnRemove) or (Key = 'r') then
        begin
			RedrawNeeded := true;
			if Setting.ConfirmLinkDelete then
				DoDelete := SysMsgBox('Remove desktop link', 'This will permanently delete this' +
                    NewLine + 'desktop link. Are you sure?', msgQuest)
			else
				DoDelete := true;

			if DoDelete then
            begin
				{DeskLink(TargetLink).Caption := '';}
				DeskLinkSave;
				DeskLinkLoad;
				DeskDrawDesktop;
				repeat; until MouseClicked = mbNone;
				exit;
			end;
		end;

	until False;

	if RedrawNeeded then
		DeskDrawDesktop
	else
    begin
		MouseHide;
		{PCOPY 1, 0} {DEBUG}
		MouseShow;
	end;
			 
end;

procedure DeskLinkMove(TargetLink: integer);
var
    btnPrevious, btnNext: ButtonType;
	{LinkIcon(257), Backdrop(257): replace;}
    DrawX, DrawY: integer;
    CurGridX, CurGridY, LastGridX, LastGridY: integer;
    OriginalDesktop, NewDesktop, Desktops: integer;
    IconToMove: TLink;
    Key: String;
begin
	repeat; until MouseClicked = mbNone;

	OriginalDesktop := Setting.DesktopID;
	NewDesktop := Setting.DesktopID;
	{DrawX = DeskLink(TargetLink).Left
	DrawY = DeskLink(TargetLink).Top
	IconToMove = DeskLink(TargetLink)}

	{Delete current icon - it will be recreated after move to same or other
	 desktop}
	{DeskLink(TargetLink).Caption = ''}
	DeskLinkSave;

    btnPrevious.Init(255, 2, 42, 22, '<');
    btnNext.Init(343, 2, 42, 22, '>');

	ObjDrawMenu;
	ObjDrawBtn(btnPrevious, false);
	ObjDrawBtn(btnNext, false);
	MouseHide;
	{FontPrint(LTrim(STR$(Setting.DesktopID)) + '/5', 310, 8, Theme.WindowText, FontHeading);}
	{GET (DrawX, DrawY, DrawX + 31, DrawY + 31), LinkIcon
	GET (DrawX, DrawY, DrawX + 31, DrawY + 31), Backdrop}
	MouseShow;

	{Center mouse on icon}
	MouseSetPos(DrawX + 16, DrawY + 16);

	if not MouseSupport then
    begin
		{Set mouse pos variables manually to make the rest of the code work
		 if no mouse is present}
		MouseX := DrawX + 16;
		MouseY := DrawY + 16;
	end;

	MousePoll;
	CurGridX := MouseX div GridSize;
	CurGridY := MouseY div GridSize;

	repeat
		Key := GetKey;
		
		{Escape}
		if Key = KeyEscape then
            exit;
		
		{Enter}
		if Key = KeyEnter then
            break;

		MousePoll;

		{Arrow keys - move mouse cursor in direction pressed}
		if Key = KeyLeft then {Left arrow}
			MouseX := MouseX - GridSize;
		if Key = KeyRight then {Right arrow}
			MouseX := MouseX + GridSize - 1;
		if Key = KeyUp then {Up arrow}
			MouseY := MouseY - GridSize;
		if Key = KeyDown then {Down arrow}
			MouseY := MouseY + GridSize - 1;
		
		{Make sure we're within boundaries}
		if MouseX < 0 then MouseX := 0;
		if MouseX > 624 then MouseX := 624;
		if MouseY < 48 then MouseY := 48;
		if MouseY > 334 then MouseY := 334;

		{If an arrow key was pressed earlier, move cursor accordingly}
		if Key[0] = #0 then
			MouseSetPos(MouseX, MouseY);

		{Calculate grid position}
		CurGridX := (MouseX - 16) div GridSize;
		if CurGridX < 0 then
            CurGridX := 0;
		CurGridY := (MouseY - 16) div GridSize;
		if CurGridY < 4 then
            CurGridY := 4;

		if (not CurGridX = LastGridX) or (not CurGridY = LastGridY) then
        begin
			MouseHide;
			{Restore backdrop}
			{PUT (DrawX, DrawY), Backdrop, PSET}
			DrawX := CurGridX * GridSize;
			DrawY := CurGridY * GridSize;
			if DrawY > 318 then
                DrawY := 318;
		
			{Save backdrop, plot icon in its place}
			{GET (DrawX, DrawY, DrawX + 31, DrawY + 31), Backdrop
			PUT (DrawX, DrawY), LinkIcon, PSET}
			MouseShow;
			LastGridX := CurGridX;
			LastGridY := CurGridY;

			{Reduce flicker}
			{SysDelay .01
			WAIT &H3DA, 8}
		end;

		for Desktops := 1 to 5 do
        begin
			{if Key = LTrim(STR$(Desktops)) then
				if not Desktops = Setting.DesktopID then
					NewDesktop = Desktops
				end;
			end;}
		end;

		if ObjBtnClick(btnPrevious) then
        begin
			Dec(NewDesktop);
			if NewDesktop = 0 then
                NewDesktop := 5;
		end;

		if ObjBtnClick(btnNext) then
        begin
			Inc(NewDesktop);
			if NewDesktop > 5 then
                NewDesktop := 1;
		end;

		if not Setting.DesktopID = NewDesktop then
        begin
			Setting.DesktopID := NewDesktop;
			DeskLinkLoad;
			MouseHide;
            SetFillStyle(SolidFill, Theme.Window);
			Bar(310, 7, 330, 16);
			{FontPrint(LTrim(STR$(Setting.DesktopID)) + '/5', 310, 8, Theme.WindowText, FontHeading);}
			DeskDrawDesktop;
			MouseHide;
			{GET (DrawX, DrawY, DrawX + 31, DrawY + 31), Backdrop
			PUT (DrawX, DrawY), LinkIcon, PSET}
			MouseShow;
		end;

	until (MouseClicked = mbNone) and (MouseY > 28);

	Setting.DesktopID := NewDesktop;
	DeskLinkLoad;
	{if not DeskLink(UBOUND(DeskLink)).Caption = STRING$(25, 0) then
    begin}
		{Only add a new item to DeskLink array if the last item isn't empty
		 or icon move will fail when there's no icons on target desktop}
		{REDIM PRESERVE DeskLink(0 to UBOUND(DeskLink) + 1) AS TLink
	end;
	DeskLink(UBOUND(DeskLink)) = IconToMove
	DeskLink(UBOUND(DeskLink)).Left = DrawX
	DeskLink(UBOUND(DeskLink)).Top = DrawY
	DeskLinkSave
	
	repeat; until MouseClicked = mbNone;}

end;

procedure DeskLinkSave;
var
    SortCount, CheckLink, AddNext: integer;
    LinkCount, LinkSave, FileHandle: integer;
    {SortedLinks(0 to UBOUND(DeskLink)): TLink;}
begin
	{Sort before saving if array contains more than one item - this
	 enables TAB cycling from left to right, top to bottom}
	{if UBOUND(DeskLink) > 0 then
		DO

			AddNext = LBOUND(DeskLink)
			for CheckLink = 0 to UBOUND(DeskLink)
				if DeskLink(CheckLink).Left <= DeskLink(AddNext).Left then
					if DeskLink(CheckLink).Left = DeskLink(AddNext).Left then
						if DeskLink(CheckLink).Top < DeskLink(AddNext).Top then
							AddNext = CheckLink
						end;
					else
						AddNext = CheckLink
					end;
				end;
			end;

			SortedLinks(SortCount) = DeskLink(AddNext)
			DeskLink(AddNext).Left = 999
			DeskLink(AddNext).Top = 999
			SortCount = SortCount + 1

		LOOP UNTIL SortCount = UBOUND(DeskLink) + 1

		for SortCount = 0 to UBOUND(DeskLink)
			DeskLink(SortCount) = SortedLinks(SortCount)
		end;
	end;}

	{If there's only one link, and it has no caption or path, clear it as
	 that means that the last link has been removed from the desktop}
	{if UBOUND(DeskLink) = 0 and RTrim(DeskLink(0).Caption) = '' then
		DeskLink(0).Filename = ''
		DeskLink(0).Path = ''
		DeskLink(0).Parameters = ''
		DeskLink(0).ImageFile = ''
		DeskLink(0).PauseOnExit = 0
		DeskLink(0).Left = 0
		DeskLink(0).Top = 0
	end;}

	{Save}
	{for LinkSave = 0 to UBOUND(DeskLink)
		if not RTrim(DeskLink(LinkSave).Caption) = '' and not DeskLink(LinkSave).Caption = STRING$(25, 0) then
			LinkCount = LinkCount + 1
		end;
	end;
	
	FileHandle = FREEFILE
	if FileExists('DATA\CONFIG\DESKLNK' + LTrim(STR$(Setting.DesktopID)) + '.DAT') then
        KILL 'DATA\CONFIG\DESKLNK' + LTrim(STR$(Setting.DesktopID)) + '.DAT'
	OPEN 'DATA\CONFIG\DESKLNK' + LTrim(STR$(Setting.DesktopID)) + '.DAT' for BINARY AS #FileHandle
	PUT #FileHandle, , LinkCount

	if LinkCount = 0 then CLOSE #FileHandle: exit;

	for LinkSave = 0 to UBOUND(DeskLink)

		if not RTrim(DeskLink(LinkSave).Caption) = '' and not DeskLink(LinkSave).Caption = STRING$(25, 0) then

			PUT #FileHandle, , DeskLink(LinkSave)

		end;
	end;

	CLOSE #FileHandle}

end;

procedure DeskRun(TargetFile, TargetParameters, TargetPath: string; PauseOnExit: boolean);
var
    RunHandle, I: integer;
    ShowErr: boolean;
    FileType, OpenWith: String;
begin
	
	TargetFile := Trim(TargetFile);
	TargetParameters := Trim(TargetParameters);

	{Remove trailing \ from path, if any}
	{if Length(TargetPath) > 1 then
		if RIGHT$(TargetPath, 1) = '\' then TargetPath = LEFT$(TargetPath, Length(TargetPath) - 1)}

	{Get the file extension for file association check}
	if Length(TargetFile) > 1 then
    begin
		{for I = Length(TargetFile) to 1 STEP -1

			{If backslash is found before a dot, then any dot would be part of
			 path and should be ignored}
			{if MID$(TargetFile, I, 1) = '\' then EXIT FOR

			if MID$(TargetFile, I, 1) = '.' then
				FileType = UpperCase(RIGHT$(TargetFile, Length(TargetFile) - I))
				EXIT FOR
			end;
		end;}
	end;

	{if Length(FileType) then
		OpenWith = FileGetAssociation(FileType)
		if Length(OpenWith) then
			if Length(TargetPath) then
				TargetParameters = TargetPath + '\' + TargetFile + ' ' + TargetParameters
				TargetPath = ''
			else
				TargetParameters = TargetFile
			end;
			if FileType = 'BAT' then TargetParameters = '/c ' + TargetParameters
			TargetFile = OpenWith
		end;
	end;

	if TargetPath = '' then
		if not FileExists(TargetFile) then ShowErr = true
	else
		if not FileExists(TargetPath + '\' + TargetFile) then ShowErr = true
	end;

	if ShowErr = true then
		ShowErr = SysMsgBox('File not found',
            'The program you are trying to run (' + TargetFile + ') does not exist' +
                NewLine + 'in the specified path.', msgError)
		exit;
	end;}
	
	{Print the filename, parameters, path and wether to pause on exit to
	 RUN.DAT, and exit. COSTA.EXE will detect that file and run it, and then
	 relaunch the desktop}
	{RunHandle = FREEFILE

	OPEN 'DATA\RUN.DAT' for OUTPUT AS #RunHandle
	PRINT #RunHandle, TargetFile
	PRINT #RunHandle, TargetParameters
	PRINT #RunHandle, TargetPath
	if PauseOnExit then
		PRINT #RunHandle, '1'
	else
		PRINT #RunHandle, '0'
	end;
	CLOSE #RunHandle

	SysSaveSettings

	repeat; while Length(GetKey) <> 0;
	END}

end;

{Main program}
begin
    btnAddLink.Init(3, 2, 92, 22, 'Add ' + HotkeySymbol + 'icon');
    btnRunCmd.Init(102, 2, 92, 22, HotkeySymbol + 'Execute');
    btnPrevious.Init(255, 2, 42, 22, HotkeySymbol + '<');
    btnNext.Init(343, 2, 42, 22, HotkeySymbol + '>');
    btnAboutCosta.Init(446, 2, 92, 22, HotkeySymbol + 'About...');
    btnExitCosta.Init(545, 2, 92, 22, 'E' + HotkeySymbol + 'xit');
	
	DeskLinkLoad;

	TabCheck := -1;
	CheckDesktopID := Setting.DesktopID;

	MouseHide;
	ObjDrawMenu;
	ObjDrawBtn(btnAddLink, false);
	ObjDrawBtn(btnRunCmd, false);
	ObjDrawBtn(btnPrevious, false);
	ObjDrawBtn(btnNext, false);
	ObjDrawBtn(btnAboutCosta, false);
	ObjDrawBtn(btnExitCosta, false);
	{FontPrint(LTrim(STR$(Setting.DesktopID)) + '/5', 310, 8, Theme.WindowText, FontHeading);}
	MouseShow;

	DeskDrawDesktop;
	
	repeat
        Key := GetKey;

		MousePoll;
		if (MouseClicked <> mbNone) and (MouseY > 32) then
        begin
			ClickedB := MouseClicked;
            ClickedX := MouseX;
            ClickedY := MouseY;
		
			{The mouse was clicked. Before checking if a desktop link was clicked,
			 check to see if any desktop links are present}
			{if not RTrim(DeskLink(0).Caption) = '' then
                for DeskLinkCheck = UBOUND(DeskLink) to 0 STEP -1}

                    {Check if the mouse was within the coordinates of the link}
                    {if ClickedX >= DeskLink(DeskLinkCheck).Left and ClickedX <= DeskLink(DeskLinkCheck).Left + 31 then
                        if ClickedY >= DeskLink(DeskLinkCheck).Top and ClickedY <= DeskLink(DeskLinkCheck).Top + 31 then}
                            {If we reach this point, the link was clicked}
                            {DeskLinkMenu(DeskLinkCheck);}
                            {After menu has been shown, buttons might be missing from
                            top bar due to DeskLinkMove(hiding them}
                            {CheckDesktopID = Setting.DesktopID
                            MouseHide;
                            ObjDrawBtn(btnAddLink, false);
                            ObjDrawBtn(btnRunCmd, false);
                            ObjDrawBtn(btnPrevious, false);
                            ObjDrawBtn(btnNext, false);
                            ObjDrawBtn(btnAboutCosta, false);
                            ObjDrawBtn(btnExitCosta, false);
                            MouseShow;}

                            {Exit FOR, otherwise overlapping icons will also be clicked}
                            {break;

                        end;
                    end;

                end;
			end;}
		end;


        if ObjBtnClick(btnAddLink) or (Key = 'i') then
        begin
            {REDIM PRESERVE DeskLink(0 to UBOUND(DeskLink) + 1) AS TLink
        
            DeskLink(UBOUND(DeskLink)).Caption = 'Unnamed'
            DeskLink(UBOUND(DeskLink)).Filename = ''
            DeskLink(UBOUND(DeskLink)).Path = ''
            DeskLink(UBOUND(DeskLink)).Parameters = ''
            DeskLink(UBOUND(DeskLink)).ImageFile = 'PROGRAM'
            DeskLink(UBOUND(DeskLink)).Left = 16
            DeskLink(UBOUND(DeskLink)).Top = 40}

            MouseHide;
            {PCOPY 0, 1} {DEBUG}
            MouseShow;

            {DeskLinkDialog(UBOUND(DeskLink), DidEdit);}

            if DidEdit then
            begin
                TabCheck := -1;
                DeskLinkLoad;
                MouseHide;
                DeskDrawDesktop;
                MouseShow;
            end
            else
            begin
                {REDIM PRESERVE DeskLink(0 to UBOUND(DeskLink) - 1) AS TLink}
                MouseHide;
                {PCOPY 1, 0}
                MouseShow;
            end;

        end;

        if ObjBtnClick(btnRunCmd) or (Key = KeyAltE) then
            DeskExecuteDialog;

        if ObjBtnClick(btnAboutCosta) or (Key = KeyAltA) then
            SysAboutBox(AppName, AppVersion, AppAuthor, AppIcon);
        
        if ObjBtnClick(btnPrevious) or (Key = KeyLeft) then
            Dec(Setting.DesktopID);;

        if ObjBtnClick(btnNext) or (Key = KeyRight) then
            Inc(Setting.DesktopID);
        
        if Setting.DesktopID < 1 then
            Setting.DesktopID := 5;
        if Setting.DesktopID > 5 then
            Setting.DesktopID := 1;

        if Key = '1' then Setting.DesktopID := 1;
        if Key = '2' then Setting.DesktopID := 2;
        if Key = '3' then Setting.DesktopID := 3;
        if Key = '4' then Setting.DesktopID := 4;
        if Key = '5' then Setting.DesktopID := 5;

        if CheckDesktopID <> Setting.DesktopID then
        begin
            MouseHide;
            SetFillStyle(SolidFill, Theme.Window);
            Bar(310, 7, 330, 16);
            {FontPrint(LTrim(STR$(Setting.DesktopID)) + '/5', 310, 8, Theme.WindowText, FontHeading);}
            MouseShow;
            DeskLinkLoad;
            DeskDrawDesktop;
            TabCheck := -1;
            CheckDesktopID := Setting.DesktopID;
        end;
        
        if ObjBtnClick(btnExitCosta) or (Key = KeyAltX) or (Key = KeyAltF4) then
        begin
            if Setting.ConfirmExit then
                DoExit := SysMsgBox('Exit ' + appName, 'This will exit Costa and return you to the DOS'
                    + NewLine + 'prompt. Are you sure?', msgQuest)
            else
                DoExit := true;

            if DoExit then
                break;
        end;

        if (Key = KeyTab) or (Key = KeyShiftTab) then
        begin
            {If there's only one item in the DESKLINK array, and it has no caption
                then there are no desktop links to cycle}
            {if not (UBOUND(DeskLink) = 0 and RTrim(DeskLink(0).Caption) = '') then
                if TabCheck > -1 then
                    MouseHide;
                    SetFillStyle(SolidFill, Theme.Desktop);
                    Bar(DeskLink(TabCheck).Left - 3, DeskLink(TabCheck).Top - 3,
                        DeskLink(TabCheck).Left + 35, DeskLink(TabCheck).Top + 35);
                    ObjDrawImg(imgTab);
                    MouseShow;
                end;

                if Key = KeyTab then
                    Inc(TabCheck);
                else
                    Dec(TabCheck);
                
                if TabCheck > UBOUND(DeskLink) then
                    TabCheck = 0;
                if TabCheck < 0 then
                    TabCheck = UBOUND(DeskLink);
        
                if DeskLink(TabCheck).ImageFile = STRING$(8, 0) then
                    TabCheck = -1
                else
                begin
                    imgTab.ImageFile = DeskLink(TabCheck).ImageFile
                    imgTab.Pos.Left = DeskLink(TabCheck).Left: imgTab.Pos.Top = DeskLink(TabCheck).Top;
                    btnTab.Pos.Left = DeskLink(TabCheck).Left - 3: btnTab.Pos.Top = DeskLink(TabCheck).Top - 3;
                    btnTab.Pos.Width = 37: btnTab.Pos.Height = 37;
                    MouseHide;
                    ObjDrawBtn(btnTab, false);
                    ObjDrawImg(imgTab);
                    MouseShow;
                end;
            end;}
        end;

        if ((Key = KeyEnter) or (Key = KeySpace)) and (TabCheck > -1) then
        begin
            MouseHide;
            SetFillStyle(SolidFill, Theme.Desktop);
            {Bar(DeskLink(TabCheck).Left - 3, DeskLink(TabCheck).Top - 3,
                DeskLink(TabCheck).Left + 35, DeskLink(TabCheck).Top + 35);}
            ObjDrawImg(imgTab);
            MouseShow;
            
            if Key = KeyEnter then
            begin
                DeskLinkMenu(TabCheck);
                CheckDesktopID := Setting.DesktopID;
                MouseHide;
                ObjDrawBtn(btnAddLink, false);
                ObjDrawBtn(btnRunCmd, false);
                ObjDrawBtn(btnPrevious, false);
                ObjDrawBtn(btnNext, false);
                ObjDrawBtn(btnAboutCosta, false);
                ObjDrawBtn(btnExitCosta, false);
                MouseShow;
            end;
            TabCheck := -1;
        end;
	
	until False;

    CloseGraph;
end.