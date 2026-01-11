unit UITHMPRW;

{Theme preview object for Costa UI library.
 Allows loading a theme from a file or from memory, and previewing it
 by drawing a sample window with various UI elements using the theme colors.}

interface

uses
	CostaLib, UIFrame, UIIcon, UITxtbox, UIButton, UILabel, MsgDlg;

type
	PThemePreview = ^TThemePreview;
	TThemePreview = Object(TFrame)
		public
			constructor  Init(X, Y: Integer; Parent: PContainer);
			procedure    Draw; virtual;

			procedure    LoadFile(Filename: string);
			procedure    LoadMem(ThemePtr: PTheme);
			
			procedure    Preview;

		private
			ThemeAuthor:    string[20];
			ThemeName:      string[20];
			ThemeData:      TTheme;
			OrigTheme:      TTheme;
			ThemeLoaded:    Boolean;

			WinPreview:     PWindow;
			ImgPreview,
			ImgPreviewLink: PIcon;
			TxtPreview:     PTextbox;
			BtnPreview1,
			BtnPreview2:    PButton;
			LblPreviewInfo: PLabel;
			LblPreviewLink: PLabel;
	end;

implementation

const
	CAP_BUTTON           = 'Button';
	CAP_TEXTBOX          = 'Textbox';
	CAP_PREVIEW          = 'This is a preview of' + #13 + 'the theme.';
	CAP_PREVIEW_LINK     = 'Preview link';
	CAP_PREVIEW_EXE      = 'preview.exe';

	MSG_LOAD_ERROR_TITLE = 'Error loading';
	MSG_LOAD_ERROR_TEXT  = '%s. The theme file %s.BIN' + #13 +
	                       'could not be loaded.';

constructor TThemePreview.Init(X, Y: Integer; Parent: PContainer);
const
	DefaultW = 310;
	DefaultH = 192;
begin
	Inherited Init(X, Y, Parent);
	SetSize(DefaultW, DefaultH);

	ThemeName := '';
	ThemeAuthor := '';
	ThemeLoaded := false;
	FillChar(ThemeData, SizeOf(ThemeData), 0);
	FillChar(OrigTheme, SizeOf(OrigTheme), 0);
	
	{Initialize objects in preview frame - size and position are set on draw to allow
	 for resizing of the preview frame}

	{Preview window and its contents}
	New(WinPreview, Init(10, 0, @Self));
	New(ImgPreview, Init(0, 0, 'LOGO', WinPreview));
	New(LblPreviewInfo, Init(0, 0, CAP_PREVIEW, WinPreview));
	New(TxtPreview, Init(0, 0, '', WinPreview));
	TxtPreview^.SetText(CAP_TEXTBOX);
	New(BtnPreview1, Init(0, 0, CAP_BUTTON, WinPreview));
	New(BtnPreview2, Init(0, 0, CAP_BUTTON, WinPreview));
	BtnPreview2^.AddState(SActive);

	{Preview desktop link}
	New(ImgPreviewLink, Init(0, 0, 'PAINT', @Self));
	New(LblPreviewLink, Init(0, 0, CAP_PREVIEW_LINK + #13 + CAP_PREVIEW_EXE, @Self));
end;

procedure TThemePreview.Draw;
var
	W, H: Integer;
	OldTheme: String[8];
begin
	{Set positions and sizes of preview objects based on current size of preview frame}
	Self.GetSize(W, H);
	ImgPreviewLink^.SetPos(14, H - 42);
	LblPreviewLink^.SetPos(52, H - 38);
	WinPreview^.SetPos(14, 12);
	WinPreview^.SetSize(W - 28, 123);
	ImgPreview^.SetPos(12, 12);
	LblPreviewInfo^.SetPos(54, 16);
	
	WinPreview^.GetSize(W, H);
	TxtPreview^.SetPos(12, 57);
	TxtPreview^.SetSize(W - 23, SizeRetain);
	BtnPreview1^.SetPos(12, H - 34);
	BtnPreview2^.SetPos(W - 104, H - 34);

	{If a theme file is loaded, apply it for preview}
	if ThemeLoaded then
		Thm := ThemeData;

	{Set frame background color}
	Self.SetBGColor(Thm.Desk);

	{Draw the container, which will also draw and its children}
	Inherited Draw;

	{Restore original theme}
	if ThemeLoaded then
		Thm := OrigTheme;
end;

procedure TThemePreview.LoadFile(Filename: string);
var
	F: File;
	ErrorCode: Integer;
	ErrorText: string;
begin
	{Load the specified theme file}

	OrigTheme := Thm; {Store original theme to restore later}

	Assign(F, ProgramPath + 'THEMES\' + Filename + '.BIN');
	{$I-}
	Reset(F, 1);
	{$I+}
	ErrorCode := IOResult;
	if ErrorCode = 0 then
	begin
		{DEBUG - verify file size before loading}
		BlockRead(F, ThemeData, SizeOf(ThemeData));
		BlockRead(F, ThemeName, SizeOf(ThemeName));
		BlockRead(F, ThemeAuthor, SizeOf(ThemeAuthor));
		ThemeLoaded := true;
		Close(F);
	end
	else
	begin
		ThemeData := OrigTheme; {Restore original theme}
		ThemeAuthor := '';
		ThemeName := '';
		ErrorText := ReplaceMsg(MSG_LOAD_ERROR_TEXT, GetDosErrorMsg(ErrorCode));
		ErrorText := ReplaceMsg(ErrorText, FileName);
		MsgBox(MSG_LOAD_ERROR_TITLE, ErrorText, MsgError);
	end;

	{Update preview info label to show theme name and author}
	LblPreviewInfo^.SetCaption(ThemeName + #13 + ThemeAuthor);
end;

procedure TThemePreview.LoadMem(ThemePtr: PTheme);
begin
	{Preview the specified theme from memory and redraw the object}
	if ThemePtr = nil then
		exit;

	OrigTheme := Thm; {Store original theme to restore later}
	ThemeData := ThemePtr^;
	ThemeLoaded := true;

	{Update preview info label to show default text, since author and name are unknown}
	LblPreviewInfo^.SetCaption(CAP_PREVIEW);
end;

procedure TThemePreview.Preview;
begin
	Mouse.Hide;
	Self.Draw;
	Mouse.Show;
end;

end.