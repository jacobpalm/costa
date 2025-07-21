program ThemeEditor;

uses
	CostaLib, InputBox, Graph, DOS;

const
	AppName    = 'Theme Editor';
	AppVersion = '2.0';
	AppAuthor  = 'Jacob Palm';
	AppIcon    = 'THEMES';

var
	ThemeFile: string;
	ThemeName, ThemeAuthor: string;
	OriginalTheme: string;

	thmClrDesktop, thmClrDesktopText, thmClrWindow: integer;
	thmClrButton, thmClrTextbox, thmClrTextboxText: integer;
	thmClrWindowText, thmClrTitlebar, thmClrTitlebarText: integer;
	thmClr3DLight, thmClr3DShadow, thmClrSelect, thmClrSelectText: integer;

	SelectedColor: integer;
	SelectedObject: integer;

	{Objects used in mulitple procedures}
	btnColor: array[0..15] of ButtonType;

{Forward declarations}
procedure SelectColor(Color: integer); forward;
procedure SelectObject; forward;
procedure LoadTheme; forward;
procedure SaveTheme; forward;
procedure UpdatePreview; forward;


procedure SelectColor(Color: integer);
var
	i: integer;
	x1, y1, x2, y2: Integer;
begin
	if Color < 0 then
		Color := 15
	else if Color > 15 then
		Color := 0;
	
	MouseHide;
	{Erase previous selection}
	x1 := btnColor[SelectedColor].Pos.Left + 4;
	y1 := btnColor[SelectedColor].Pos.Top + 4;
	x2 := btnColor[SelectedColor].Pos.Left + btnColor[SelectedColor].Pos.Width - 4;
	y2 := btnColor[SelectedColor].Pos.Top + btnColor[SelectedColor].Pos.Height - 4;
	SetFillStyle(SolidFill, SelectedColor);
	Bar(x1, y1, x2, y2);

	{Change color and draw new selection}
	SelectedColor := Color;
	x1 := btnColor[SelectedColor].Pos.Left + 4;
	y1 := btnColor[SelectedColor].Pos.Top + 4;
	x2 := btnColor[SelectedColor].Pos.Left + btnColor[SelectedColor].Pos.Width - 4;
	y2 := btnColor[SelectedColor].Pos.Top + btnColor[SelectedColor].Pos.Height - 4;
	SetColor(DarkGray);
	Rectangle(x1, y1, x2, y2);
	SetColor(White);
	Rectangle(x1 + 1, y1 + 1, x2 - 1, y2 - 1);
	MouseShow;
end;

procedure UpdatePreview;
var
	frmPreview: FrameType;
	winPreview: WindowType;
	txtPreview: TextboxType;
	txtPreviewText: string;
	btnPreview1, btnPreview2, btnPreview3: ButtonType;
	imgPreview: ImageType;
	txtListPreview: TextboxType;
begin
	ObjSetSize(frmPreview.Pos, 12, 42, 410, 293);
	MouseHide;
	ObjDrawFrm(frmPreview, 15, Theme.Shadow);
	MouseShow;

	if Length(ThemeFile) <> 0 then
	begin
		SysLoadTheme(ThemeFile);
		thmClrDesktop := Theme.Desktop;
		thmClrDesktopText := Theme.DesktopText;
		thmClrWindow := Theme.Window;
		thmClrButton := Theme.Button;
		thmClrTextbox := Theme.Textbox;
		thmClrTextboxText := Theme.TextboxText;
		thmClrWindowText := Theme.WindowText;
		thmClrTitlebar := Theme.TitleBar;
		thmClrTitlebarText := Theme.TitleBarText;
		thmClr3DLight := Theme.Light;
		thmClr3DShadow := Theme.Shadow;
		thmClrSelect := Theme.Select;
		thmClrSelectText := Theme.SelectText;
	end
	else
	begin
		Theme.Desktop := thmClrDesktop;
		Theme.DesktopText := thmClrDesktopText;
		Theme.Window := thmClrWindow;
		Theme.Button := thmClrButton;
		Theme.Textbox := thmClrTextbox;
		Theme.TextboxText := thmClrTextboxText;
		Theme.WindowText := thmClrWindowText;
		Theme.TitleBar := thmClrTitlebar;
		Theme.TitleBarText := thmClrTitlebarText;
		Theme.Light := thmClr3DLight;
		Theme.Shadow := thmClr3DShadow;
		Theme.Select := thmClrSelect;
		Theme.SelectText := thmClrSelectText;
	end;

	winPreview.Init(frmPreview.Pos.Left + ((frmPreview.Pos.Width - 260) div 2),
		frmPreview.Pos.Top + 65, 260, 127);
	txtPreview.Init(winPreview.Pos.Left + 12, winPreview.Pos.Top + 56, 236, 19);
	btnPreview1.Init(winPreview.Pos.Left + 14, winPreview.Pos.Top + 93, 111, 22, 'Button up');
	btnPreview2.Init(winPreview.Pos.Left + 133, winPreview.Pos.Top + 93, 111, 22, 'Button down');
	btnPreview3.Init(frmPreview.Pos.Left + frmPreview.Pos.Width - 96, frmPreview.Pos.Top + 3, 92, 22, 'Menu button');
	txtListPreview.Init(frmPreview.Pos.Left + frmPreview.Pos.Width - 182,
		frmPreview.Pos.Top + frmPreview.Pos.Height - 82, 166, 66);
	txtPreviewText := 'Textbox contents';
	ObjSetSize(imgPreview.Pos, frmPreview.Pos.Left + 16, frmPreview.Pos.Top +
		frmPreview.Pos.Height - 48, sizeRetain, sizeRetain);
	imgPreview.ImageFile := 'LOGO';

	MouseHide;
	SetFillStyle(SolidFill, Theme.Desktop);
	Bar(frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2,
		frmPreview.Pos.Left + frmPreview.Pos.Width - 2, frmPreview.Pos.Top + frmPreview.Pos.Height - 2);
	SetFillStyle(SolidFill, Theme.Window);
	Bar(frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 2, frmPreview.Pos.Left + frmPreview.Pos.Width - 2,
		frmPreview.Pos.Top + 27);
	SetColor(Theme.Shadow);
	Line(frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 28, frmPreview.Pos.Left + frmPreview.Pos.Width - 2,
		frmPreview.Pos.Top + 28);
	SetColor(Black);
	Line(frmPreview.Pos.Left + 2, frmPreview.Pos.Top + 29, frmPreview.Pos.Left + frmPreview.Pos.Width - 2,
		frmPreview.Pos.Top + 29);

	ObjDrawWin(winPreview);
	ObjDrawTxt(txtPreview, txtPreviewText, True);
	ObjDrawBtn(btnPreview1, False);
	ObjDrawBtn(btnPreview2, True);
	ObjDrawBtn(btnPreview3, False);
	ObjDrawImg(imgPreview);
	ObjDrawTxt(txtListPreview, '', False);

	FontPrint('This is a preview of the theme', winPreview.Pos.Left + 12, winPreview.Pos.Top + 14,
		Theme.WindowText, FontHeading);
	FontPrint('you are editing.', winPreview.Pos.Left + 12, winPreview.Pos.Top + 30,
		Theme.WindowText, FontNormal);
	FontPrint('Preview link', imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 4, Theme.DesktopText, FontHeading);
	FontPrint('preview.exe', imgPreview.Pos.Left + 38, imgPreview.Pos.Top + 18, Theme.DesktopText, FontNormal);

	SetFillStyle(SolidFill, Theme.Select);
	Bar(txtListPreview.Pos.Left + 2, txtListPreview.Pos.Top + 15, txtListPreview.Pos.Left + txtListPreview.Pos.Width - 2,
		txtListPreview.Pos.Top + 27);
	FontPrint('List item', txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5, Theme.TextboxText, FontHeading);
	FontPrint('Selected item', txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 12, Theme.SelectText, FontHeading);
	FontPrint('List item', txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 24, Theme.TextboxText, FontHeading);
	FontPrint('List item', txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 36, Theme.TextboxText, FontHeading);
	FontPrint('List item', txtListPreview.Pos.Left + 5, txtListPreview.Pos.Top + 5 + 48, Theme.TextboxText, FontHeading);
	MouseShow;

	SysLoadTheme(Setting.ThemeFile);
end;

procedure SelectObject;
var
	winSelectObject: WindowType;
	btnObject: array[1..13] of ButtonType;
	i, ActiveSelection: integer;
	Key: string;
	x1, y1, x2, y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
begin
	winSelectObject.Init(sizeCenter, sizeCenter, 226, 326);
	for i := 1 to 13 do
		btnObject[I].Init(winSelectObject.Pos.Left + 13, winSelectObject.Pos.Top + (I * 23) - 8, 200, 22, '');
	
	btnObject[1].Caption := 'Desktop';
	btnObject[2].Caption := 'Desktop text';
	btnObject[3].Caption := 'Window';
	btnObject[4].Caption := 'Window border';
	btnObject[5].Caption := 'Window text';
	btnObject[6].Caption := 'Button';
	btnObject[7].Caption := 'Textbox';
	btnObject[8].Caption := 'Textbox text';
	btnObject[9].Caption := '3D light';
	btnObject[10].Caption := '3D Shadow';
	btnObject[11].Caption := 'Selection';
	btnObject[12].Caption := 'Selection text';
	btnObject[13].Caption := 'Titlebar text';

	MouseHide;
	x1 := winSelectObject.Pos.Left;
	y1 := winSelectObject.Pos.Top;
	x2 := winSelectObject.Pos.Left + winSelectObject.Pos.Width;
	y2 := winSelectObject.Pos.Top + winSelectObject.Pos.Height;
	BackgroundSize := ImageSize(x1, y1, x2, y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(x1, y1, x2, y2, BackgroundP^);
	
	ObjDrawWin(winSelectObject);
	ActiveSelection := SelectedObject;
	for i := 1 to 13 do
		ObjDrawBtn(btnObject[i], (i = ActiveSelection));
	MouseShow;

	repeat
		Key := GetKey;

		if Key = KeyEnter then
		begin
			SelectedObject := ActiveSelection;
			break;
		end;

		if Key = KeyEscape then
		begin
			break;
		end;

		{DEBUG - broken}
		if MouseClicked <> mbNone then
		begin
			for i := 1 to 12 do
			begin
				if ObjBtnClick(btnObject[i]) then
				begin
					SelectedObject := i;
					break;
				end;
			end;
		end;

		if Key = KeyUp then
		begin
			MouseHide;
			ObjDrawBtn(btnObject[ActiveSelection], False);
			if ActiveSelection > 1 then
				Dec(ActiveSelection)
			else
				ActiveSelection := 13;
			ObjDrawBtn(btnObject[ActiveSelection], True);
			MouseShow;
		end;

		if Key = KeyDown then
		begin
			MouseHide;
			ObjDrawBtn(btnObject[ActiveSelection], False);
			if ActiveSelection < 13 then
				Inc(ActiveSelection)
			else
				ActiveSelection := 1;
			ObjDrawBtn(btnObject[ActiveSelection], True);
			MouseShow;
		end;

	until false;
	MouseHide;
	PutImage(x1, y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;	
end;

procedure LoadTheme;
var
	f: File;
begin
	{Debug - to be implemented}
end;

procedure SaveTheme;
var	
	ThemeToSave: ThemeType;
begin
	{TargetFile = 'DATA\THEMES\' + ThemeFile + '.DAT'

	ThemeToSave.Desktop = thmClrDesktop
	ThemeToSave.DesktopText = thmClrDesktopText
	ThemeToSave.Window = thmClrWindow
	ThemeToSave.Button = thmClrButton
	ThemeToSave.Textbox = thmClrTextbox
	ThemeToSave.TextboxText = thmClrTextboxText
	ThemeToSave.WindowText = thmClrWindowText
	ThemeToSave.TitleBar = thmClrTitlebar
	ThemeToSave.TitleBarText = thmClrTitlebarText
	ThemeToSave.Light = thmClr3DLight
	ThemeToSave.Shadow = thmClr3DShadow
	ThemeToSave.Select = thmClrSelect
	ThemeToSave.SelectText = thmClrSelectText}
	{ThemeName
	ThemeAuthor}
	
	{ThemeToSaveHandle = FREEFILE
	OPEN TargetFile for BINARY: #ThemeToSaveHandle
	PUT #ThemeToSaveHandle, , ThemeToSave
	CLOSE #ThemeToSaveHandle}

end;

var
	btnSave, btnSaveAs, btnAbout: ButtonType;
	btnExit, btnObject: ButtonType;
	txtThemeName, txtThemeAuthor: TextboxType;

	i, YPos, XPos: integer;
	ThemeChanged: Boolean;
	TargetFile, OriginalText: string;
	Key: string;
begin
	MouseHide;
	ObjDrawMenu;
	SetFillStyle(SolidFill, Theme.Window);
	Bar(0, 29, 639, 349);

	btnSave.Init(3, 2, 92, 22, HotkeySymbol + 'Save');
	btnSaveAs.Init(102, 2, 92, 22, 'Sa' + HotkeySymbol + 've as');
	btnAbout.Init(446, 2, 92, 22, HotkeySymbol + 'About...');
	btnExit.Init(545, 2, 92, 22, 'E' + HotkeySymbol + 'xit');
	txtThemeName.Init(434, 59, 194, 0);
	txtThemeAuthor.Init(434, txtThemeName.Pos.Top + 48, 194, 0);
	btnObject.Init(434, txtThemeAuthor.Pos.Top + 48, 194, 0, 'Desktop');

	txtThemeName.MaxLen := 20;
	txtThemeAuthor.MaxLen := 20;

	YPos := 0;
	XPos := 0;
	for I := 0 to 15 do
	begin
		if I = 8 then
		begin
			YPos := 25;
			XPos := 0;
		end;
		ObjSetSize(btnColor[i].Pos, txtThemeAuthor.Pos.Left + XPos, txtThemeAuthor.Pos.Top + 98 + YPos, 19, 19);
		btnColor[i].Transparent := True;
		Inc(XPos, 25);
	end;

	MouseHide;
	ObjDrawBtn(btnSaveAs, False);
	ObjDrawBtn(btnSave, False);
	ObjDrawBtn(btnAbout, False);
	ObjDrawBtn(btnExit, False);
	ObjDrawTxt(txtThemeName, ThemeName, False);
	ObjDrawTxt(txtThemeAuthor, ThemeAuthor, False);
	ObjDrawBtn(btnObject, False);
	for i := 0 to 15 do
	begin
		ObjDrawBtn(btnColor[i], True);
		SetFillStyle(SolidFill, i);
		Bar(btnColor[i].Pos.Left + 2, btnColor[i].Pos.Top + 2, btnColor[i].Pos.Left + btnColor[i].Pos.Width - 2,
			btnColor[i].Pos.Top + btnColor[i].Pos.Height - 2);
	end;

	FontPrint('Theme ' + HotkeySymbol + 'name:', txtThemeName.Pos.Left, txtThemeName.Pos.Top - 16,
		Theme.WindowText, FontHeading);
	FontPrint('Theme a' + HotkeySymbol + 'uthor:', txtThemeAuthor.Pos.Left, txtThemeAuthor.Pos.Top - 16,
		Theme.WindowText, FontHeading);
	FontPrint(HotkeySymbol + 'Object selected:', 434, btnObject.Pos.Top - 16, Theme.WindowText, FontHeading);
	FontPrint(HotkeySymbol + 'Color for object:', 434, btnColor[0].Pos.Top - 16, Theme.WindowText, FontHeading);

	ThemeFile := Setting.ThemeFile;
	UpdatePreview;
	SelectedObject := 1;
	SelectColor(thmClrDesktop);
	
	repeat
		Key := GetKey;

		for I := 0 to 15 do
		begin
			if ObjClick(btnColor[i].Pos) then
			begin
				ThemeChanged := True;
				case SelectedObject of
					1:  thmClrDesktop := i;
					2:  thmClrDesktopText := i;
					3:  thmClrWindow := i;
					4:  thmClrTitlebar := i;
					5:  thmClrWindowText := i;
					6:  thmClrButton := i;
					7:  thmClrTextbox := i;
					8:  thmClrTextboxText := i;
					9:  thmClr3DLight := i;
					10: thmClr3DShadow := i;
					11: thmClrSelect := i;
					12: thmClrSelectText := i;
					13: thmClrTitlebarText := i;
				end;
				SelectColor(i);
				UpdatePreview;
			end;
		end;

		if Key = KeyAltC then
		begin

			{case SelectedObject
				CASE 1
					thmClrDesktop = thmClrDesktop + 1
					if thmClrDesktop > 15 then thmClrDesktop = 0
					SelectColor(thmClrDesktop
				CASE 2
					thmClrDesktopText = thmClrDesktopText + 1
					if thmClrDesktopText > 15 then thmClrDesktopText = 0
					SelectColor(thmClrDesktopText
				CASE 3
					thmClrWindow = thmClrWindow + 1
					if thmClrWindow > 15 then thmClrWindow = 0
					SelectColor(thmClrWindow
				CASE 4
					thmClrTitlebar = thmClrTitlebar + 1
					if thmClrTitlebar > 15 then thmClrTitlebar = 0
					SelectColor(thmClrTitlebar
				CASE 5
					thmClrWindowText = thmClrWindowText + 1
					if thmClrWindowText > 15 then thmClrWindowText = 0
					SelectColor(thmClrWindowText
				CASE 6
					thmClrButton = thmClrButton + 1
					if thmClrButton > 15 then thmClrButton = 0
					SelectColor(thmClrButton
				CASE 7
					thmClrTextbox = thmClrTextbox + 1
					if thmClrTextbox > 15 then thmClrTextbox = 0
					SelectColor(thmClrTextbox
				CASE 8
					thmClrTextboxText = thmClrTextboxText + 1
					if thmClrTextboxText > 15 then thmClrTextboxText = 0
					SelectColor(thmClrTextboxText
				CASE 9
					thmClr3DLight = thmClr3DLight + 1
					if thmClr3DLight > 15 then thmClr3DLight = 0
					SelectColor(thmClr3DLight
				CASE 10
					thmClr3DShadow = thmClr3DShadow + 1
					if thmClr3DShadow > 15 then thmClr3DShadow = 0
					SelectColor(thmClr3DShadow
				CASE 11
					thmClrSelect = thmClrSelect + 1
					if thmClrSelect > 15 then thmClrSelect = 0
					SelectColor(thmClrSelect
				CASE 12
					thmClrSelectText = thmClrSelectText + 1
					if thmClrSelectText > 15 then thmClrSelectText = 0
					SelectColor(thmClrSelectText
				CASE 13
					thmClrTitlebarText = thmClrTitlebarText + 1
					if thmClrTitlebarText > 15 then thmClrTitlebarText = 0
					SelectColor(thmClrTitlebarText
			end;
			ThemeChanged = True
			UpdatePreview}
		end;

		if ObjBtnClick(btnObject) or (Key = KeyAltO) then
		begin
			SelectObject;
			case SelectedObject of
				1:
					begin
						btnObject.Caption := 'Desktop';
						SelectColor(thmClrDesktop);
					end;
				2:
					begin
						btnObject.Caption := 'Desktop text';
						SelectColor(thmClrDesktopText);
					end;
				3:
					begin
						btnObject.Caption := 'Window';
						SelectColor(thmClrWindow);
					end;
				4:
					begin
						btnObject.Caption := 'Window border';
						SelectColor(thmClrTitlebar);
					end;
				5:
					begin
						btnObject.Caption := 'Window text';
						SelectColor(thmClrWindowText);
					end;
				6:
					begin
						btnObject.Caption := 'Button';
						SelectColor(thmClrButton);
					end;
				7:
					begin
						btnObject.Caption := 'Textbox';
						SelectColor(thmClrTextbox);
					end;
				8:
					begin
						btnObject.Caption := 'Textbox text';
						SelectColor(thmClrTextboxText);
					end;
				9:
					begin
						btnObject.Caption := '3D light';
						SelectColor(thmClr3DLight);
					end;
				10:
					begin
						btnObject.Caption := '3D Shadow';
						SelectColor(thmClr3DShadow);
					end;
				11:
					begin
						btnObject.Caption := 'Selection';
						SelectColor(thmClrSelect);
					end;
				12:
					begin
						btnObject.Caption := 'Selection text';
						SelectColor(thmClrSelectText);
					end;
				13:
					begin
						btnObject.Caption := 'Titlebar text';
						SelectColor(thmClrTitlebarText);
					end;
			end;
			MouseHide;
			ObjDrawBtn(btnObject, False);
			MouseShow;
		end;

		{if ObjTxtClick(txtThemeName) or (Key = KeyAltN) then
		begin
			OriginalText := ThemeName;
			ObjEditTxt(txtThemeName, ThemeName);
			if not ThemeName = OriginalText then
				ThemeChanged := True;
		end;

		if ObjTxtClick(txtThemeAuthor) or (Key = KeyAltU) then
		begin
			OriginalText := ThemeAuthor;
			ObjEditTxt(txtThemeAuthor, ThemeAuthor);
			if not ThemeAuthor = OriginalText then
				ThemeChanged := True;
		end;}

		if ObjBtnClick(btnAbout) or (Key = KeyAltA) then
			SysAboutBox(AppName, AppVersion, AppAuthor, AppIcon);

		if ObjBtnClick(btnSaveAs) or (Key = KeyAltV) then
		begin
			{TargetFile = SysInputBox('Save theme', 'Type a name for the theme file below, without path or' + NewLine
				+ 'extension (8 letters max, for example: MYTHEME).', 'THEMES', ThemeFile)
			if TargetFile = '' then GOTO TopOfLoop

			if LEN(TargetFile) > 8 then
					I = SysMsgBox('Invalid file name', 'The filename you specified was too long.' + NewLine 
						'Do not type a path or extension, only a filename' + NewLine +
						'with a maximun lenght of 8 characters.', msgError)
					GOTO TopOfLoop
			end;

			if File.Exists('DATA\THEMES\' + TargetFile + '.DAT') then
				if not UCASE$(TargetFile) = ThemeFile then
					DIM DoSave
					DoSave = SysMsgBox('File already exists', 'The specified theme file already exists. Do you want'
						+ NewLine + 'to owerwrite it with this theme?', msgQuest)
					if DoSave = False then GOTO TopOfLoop
				end;

				'Make sure we start with a clean file
				KILL 'DATA\THEMES\' + TargetFile + '.DAT'
			end;

			'Output to file
			ThemeFile = UCASE$(TargetFile)
			SaveTheme}
		end;

		if ObjBtnClick(btnSave) or (Key = KeyAltS) then
		begin
			if ThemeChanged then
			begin
				SaveTheme;
				ThemeChanged := False;
			end;
		end;

		if ObjBtnClick(btnExit) or (Key = KeyAltX) or (Key = KeyEscape) then
		begin
			if ThemeChanged = False then
				break;

			if SysMsgBox('Theme has been modified', 'This theme contains unsaved changes. Do you' + NewLine
			+ 'want to save before you exit?', msgQuest) then
				SaveTheme;
			
			break;
			{Debug - if not saved and user said they wanted to, then cancel}
		end;
					
	until false;
	CloseGraph;
end.