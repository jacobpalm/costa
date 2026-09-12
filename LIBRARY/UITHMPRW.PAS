unit UITHMPRW;

{Theme preview object for Costa UI library.
 Allows loading a theme from a file or from memory, and previewing it
 by drawing a sample window with various UI elements using the theme colors.}

interface

uses
	CostaLib, UIFrame, UIIcon, UITxtbox, UIButton, UILabel, MsgDlg;

type
	PThemePreview = ^TThemePreview;
	{Note - no destructor as it inherits PContainer destructor which cleans up child objects}
	TThemePreview = Object(TFrame)
		public
			constructor  Init(X, Y: Integer; Parent: PContainer);
			procedure    Draw; virtual;

			procedure    LoadFile(Filename: string);
			procedure    LoadMem(ThemePtr: PTheme; Name, Author: String);

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
	Width := DefaultW;
	Height := DefaultH;

	ThemeName := '';
	ThemeAuthor := '';
	ThemeLoaded := false;
	FillChar(ThemeData, SizeOf(ThemeData), 0);
	FillChar(OrigTheme, SizeOf(OrigTheme), 0);
	OrigTheme := Thm;

	{Initialize objects in preview frame - size and position are set on draw to allow
	 for resizing of the preview frame}

	{Preview window and its contents}
	New(WinPreview, Init(8, 0, @Self));
	New(ImgPreview, Init(0, 0, 'LOGO', WinPreview));
	New(LblPreviewInfo, Init(0, 0, CAP_PREVIEW, WinPreview));
	New(TxtPreview, Init(0, 0, '', WinPreview));
	TxtPreview^.Text := CAP_TEXTBOX;
	New(BtnPreview1, Init(0, 0, CAP_BUTTON, WinPreview));
	New(BtnPreview2, Init(0, 0, CAP_BUTTON, WinPreview));
	Include(BtnPreview2^.State, SActive);

	{Preview desktop link}
	New(ImgPreviewLink, Init(0, 0, 'PAINT', @Self));
	New(LblPreviewLink, Init(0, 0, CAP_PREVIEW_LINK + #13 + CAP_PREVIEW_EXE, @Self));
end;

procedure TThemePreview.Draw;
var
	OldTheme: String[8];
begin
	{Set positions and sizes of preview objects based on current size of preview frame}
	ImgPreviewLink^.Move(12, Height - 48);
	LblPreviewLink^.Move(56, Height - 41);
	WinPreview^.Move(12, 10);
	WinPreview^.Resize(Width - 28, 121);
	ImgPreview^.Move(6, 6);
	LblPreviewInfo^.Move(50, 13);

	TxtPreview^.Move(6, 51);
	TxtPreview^.Resize(WinPreview^.Width - 23, TxtPreview^.Height);
	BtnPreview1^.Move(6, WinPreview^.Height - 40);
	BtnPreview2^.Move(WinPreview^.Width - 110, WinPreview^.Height - 40);

	{If a theme file is loaded, apply it for preview}
	if ThemeLoaded then
		Thm := ThemeData;

	{Set frame background color}
	Self.BGColor := Thm.Desk;

	{Draw the container, which will also draw its children}
	Inherited Draw;

	{Restore original theme}
	if ThemeLoaded then
		Thm := OrigTheme;
end;

procedure TThemePreview.LoadFile(Filename: string);
var
	F: File;
	ExpectedSize: Integer;
	ErrorCode: Integer;
	ErrorText: string;
begin
	{Load the specified theme file}
	ThemeLoaded := False;
	Assign(F, ProgramPath + 'THEMES\' + Filename + '.BIN');
	FileMode := FileRead;
	{$I-}
	Reset(F, 1);
	{$I+}
	ErrorCode := IOResult;
	if ErrorCode = 0 then
	begin
		ExpectedSize := SizeOf(ThemeData) + SizeOf(ThemeName) + SizeOf(ThemeAuthor);
		if FileSize(F) = ExpectedSize then
		begin
			BlockRead(F, ThemeData, SizeOf(ThemeData));
			BlockRead(F, ThemeName, SizeOf(ThemeName));
			BlockRead(F, ThemeAuthor, SizeOf(ThemeAuthor));
			ThemeLoaded := true;
			Close(F);
		end;
	end;

	{If loading failed for any reason, restore original theme}
	if not ThemeLoaded then
	begin
		ThemeData := OrigTheme; {Restore original theme}
		ThemeAuthor := '';
		ThemeName := '';
		ErrorText := Replace(MSG_LOAD_ERROR_TEXT, Placeholder, GetDosErrorMsg(ErrorCode));
		ErrorText := Replace(ErrorText, Placeholder, FileName);
		MsgBox(MSG_LOAD_ERROR_TITLE, ErrorText, MsgError);
	end;

	{Update preview info label to show theme name and author}
	LblPreviewInfo^.SetCaption(ThemeName + #13 + ThemeAuthor);

	Include(State, SDirty);
end;

procedure TThemePreview.LoadMem(ThemePtr: PTheme; Name, Author: String);
begin
	{Preview the specified theme from memory and redraw the object}
	if ThemePtr = nil then
		exit;

	ThemeData   := ThemePtr^;
	ThemeLoaded := true;
	ThemeName   := Name;
	ThemeAuthor := Author;

	If (Length(ThemeName) > 0) or (Length(ThemeAuthor) > 0) then
		LblPreviewInfo^.SetCaption(ThemeName + #13 + ThemeAuthor)
	else
		LblPreviewInfo^.SetCaption(CAP_PREVIEW);

	Include(State, SDirty);
end;

end.