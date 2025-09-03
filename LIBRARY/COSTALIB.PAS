unit CostaLib;

interface

uses
	Crt, Dos, Graph, Strings;

const
	LibName              = 'Costa UI Library';
	LibVersion           = '2.0';
	LibYear              = '2025';

	SizeDefault          = -1; {Used to set default width/height on object init}
	sizeCenter           = -2; {Used to center objects on screen}

	DoubleClickDelay     = 0.5;
	PrintLineH           = 12; {Font dimensions - line height}
	PrintCharW           = 8;  {Width of a single character}

	CharArrowUp:	Char = #24; {Arrows symbols for fonts}
	CharArrowDown:  Char = #25;
	CharArrowRight: Char = #26;
	CharArrowLeft:  Char = #27;
	NewLine:        Char = #13;  {Wrap lines in Print, MsgBox, InputBox etc.}
	HotkeyChr:      Char = #127; {Marks hotkeys in object captions}

	{$I KEYCODES.INC}

type
	TMouseButton  = (MbNone, MbLeft, MbRight, MbBoth);
		
	PHotKeyNode = ^THotkeyNode;
	THotkeyNode = record
		HotKey: string; {Hotkey as returned by GetKey}
		Next: PHotKeyNode; {Pointer to next node in linked list}
	end;

	PUIObject = ^TUIObject;
	TUIObject = object
		public
			Left, Top, Width, Height: Integer;
			OnClick: Procedure(Sender: PUIObject);
			Hotkey: PHotKeyNode; {Linked list of hotkeys for object, to allow multiple hotkeys}
			constructor Init;
			procedure AddHotkey(Key: string);
			procedure CheckEvent;
			procedure CheckHotkeys;
			function IsMouseOver: Boolean;
			procedure SetSize(X, Y, W, H, DefaultW, DefaultH: Integer);
	end;

	THotkey = object(TUIObject)
		constructor Init(Key: String);
		procedure CheckEvent;
	end;

	TMenu = object(TUIObject)
		constructor Init;
		procedure Draw;
	end;

	TLibSetting = record
		DeskID: Integer;
		LinkCapt: Boolean;
		LinkTarget: Boolean;
		ConfLinkDel: Boolean;
		ConfExit: Boolean;
		ThmFile: string[8];
	end;

	TTheme = record
		Desk,
		DeskText,
		Win,
		Btn,
		Txt,
		TxtText,
		WinText,
		Title,
		TitleText,
		Light,
		Shadow,
		Sel,
		SelText: Integer;
	end;

var
	MenuBar: TMenu;
	Setting: TLibSetting;
	Thm: TTheme;
	HotkeyPressed: String; {Stores the last pressed hotkey, used in event loops}
	MouseVisible: Boolean;
	MouseSupport: Boolean;
	MouseX, MouseY: Integer;

function  FileExists(const FileName: string): Boolean;
function  Valid8dot3(Filename: string): Boolean;

procedure ClearInputBuffer;
function  GetKey: string;

function  MouseClicked: TMouseButton;
procedure MouseHide;
procedure MouseMove(X, Y: Integer);
procedure MousePoll;
procedure MouseShow;

function  ProgramPath: DirStr;
function  Timer: Real;

procedure Print(Text: string; X, Y, Color: Integer);
function  PrintW(Text: String): Integer;
function  PrintH(Text: string): Integer;

function  UpperCase(s: string): string;
function  Replace(Input, OldSubStr, NewSubStr: String): String;
function  ReplaceMsg(const Msg, Value: String): String;

procedure SoundNote(Frequency, Duration: Integer);

procedure SysLoadSettings;
procedure SysSaveSettings;

implementation

const
	GlobalSettings = 'CONFIG\SETTINGS.BIN';

	{Message strings}
	MSG_SAVE_SETTING_ERROR_TITLE = 'Error saving settings';
	MSG_SAVE_SETTING_ERROR_TEXT  = 'Could not write to the settings file' + #13 + 
	                               '%s.' + #13 +
	                               'Verify that the path exists and isn''t read-only.';
	MSG_GRAPHICS_ERROR           = 'Graphics error:';

constructor TUIObject.Init;
begin
	Self.SetSize(0, 0, 0, 0, SizeDefault, SizeDefault);
	Hotkey := nil;
	OnClick := nil;
end;

{Used by each descendandt object to set its size and positon on init - DefaultW and DefaultH are
 constants from the object's Init method, used to set the default width and height if W or H is
 SizeDefault}
procedure TUIObject.SetSize(X, Y, W, H, DefaultW, DefaultH: Integer);
begin
	if W = SizeDefault then
		Width := DefaultW
	else
		Width := W;

	if H = SizeDefault then
		Height := DefaultH
	else
		Height := H;

	{Check if object needs to be centered horizontally or vertically}
	if X = sizeCenter then
		Left := (GetMaxX - Width) div 2
	else
		Left := X;

	if Y = sizeCenter then
		Top := (GetMaxY - Height) div 2 
	else
		Top := Y;

	Hotkey := nil;
	OnClick := nil;
end;

{Add a hotkey to an object - a linked list is used to allow multiple hotkeys}
procedure TUIObject.AddHotkey(Key: string);
var
	CheckNode: PHotKeyNode;
	NewNode: PHotKeyNode;
begin
	if (Length(Key) < 1) or (Length(Key) > 2) then
		exit; {Invalid hotkey, do nothing}

	New(NewNode);
	NewNode^.HotKey := Key;
	NewNode^.Next := Self.Hotkey;
	Self.Hotkey := NewNode;
end;


{Check for events on object}
procedure TUIObject.CheckEvent;
begin
	{Check if mouse is clicked on the object}
	if (MouseClicked = MbLeft) and Self.IsMouseOver then
	begin
		repeat;	until MouseClicked = MbNone;
		{Check if mouse is still over the object after release}
		if Self.IsMouseOver then
		begin
			{Trigger OnClick event, if assigned}
			if Assigned(OnClick) then
				OnClick(@Self);
			exit;
		end;
	end;

	Self.CheckHotkeys;
end;

{Check for hotkeys events assigned to the object}
procedure TUIObject.CheckHotkeys;
var
	CheckNode: PHotKeyNode;
begin
	if (Length(HotkeyPressed) > 0) then
	begin
		CheckNode := Hotkey;
		while Assigned(CheckNode) do
		begin
			if CheckNode^.HotKey = HotkeyPressed then
			begin
				HotkeyPressed := ''; {Reset hotkey}
				{Trigger OnClick event, if assigned}
				if Assigned(OnClick) then
					OnClick(@Self);
				exit;
			end;
			CheckNode := CheckNode^.Next; {Move to next node in linked list}
		end;
	end;
end;

{Check if mouse is over the object}
function TUIObject.IsMouseOver: Boolean;
var
	X1, Y1, X2, Y2: Integer;
begin
	MousePoll;
	X1 := Left;
	Y1 := Top;
	X2 := X1 + Width;
	Y2 := Y1 + Height;
	IsMouseOver := (MouseX >= X1) and (MouseX <= X2) and (MouseY >= Y1) and (MouseY <= Y2);
end;

constructor THotkey.Init(Key: String);
begin
	Self.SetSize(0, 0, 0, 0, SizeDefault, SizeDefault);
	Self.Hotkey := nil;
	Self.AddHotkey(Key);
end;

procedure THotkey.CheckEvent;
begin
	Self.CheckHotkeys;
end;

constructor TMenu.Init;
begin
	Left := 0;
	Top := 0;
	Width := GetMaxX;
	Height := 28;
end;

procedure TMenu.Draw;
begin
	{Background}
	SetFillStyle(SolidFill, Thm.Win);
	Bar(Left, Top, Left + Width, Top + Height - 1);

	{3D border below}
	SetColor(Thm.Shadow);
	Line(Left, Top + Height - 1, Left + Width, Top + Height - 1);
	SetColor(Black);
	Line(Left, Top + Height, Left + Width, Top + Height);
end;

function FileExists(const FileName: string): Boolean;
var
	sResults: SearchRec;
begin
	FindFirst(FileName, Archive, sresults);
	FileExists := (DosError = 0);
end;

function Valid8dot3(Filename: string): Boolean;
var
	DotPos, NameLen, ExtLen, i: Integer;
begin
	Valid8dot3 := false;

	if Length(Filename) = 0 then
		exit;

	DotPos := Pos('.', Filename);
	if DotPos = 0 then
	begin
		{Filename does not include extension}
		NameLen := Length(Filename);
		if (NameLen > 8) then
		exit;
	end
	else
	begin
		{Filename includes extension}
		NameLen := DotPos - 1;
		ExtLen := Length(Filename) - DotPos;

		if (NameLen > 8) or (ExtLen > 3) then
			exit;
	end;

	{Check for invalid characters}
	for i := 1 to Length(Filename) do
		if not (Filename[i] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '~',
		                        '!', '@', '#', '$', '%', '^', '&', '(',
		                        ')', '-', '{', '}', '''', '.']) then
			exit;

	Valid8dot3 := true;
end;

function PrintW(Text: String): Integer;
var
	TextLine: String;
	MaxWidth, LineWidth, NewLinePos: Integer;
begin
	MaxWidth := 0;
	while length(Text) > 0 do
	begin
		NewLinePos := Pos(NewLine, Text);
		if NewLinePos > 0 then
		begin
			{Extract the line up to newline, print it, and remove it from Text}
			TextLine := Copy(Text, 1, NewLinePos - 1);
			LineWidth := Length(TextLine);
			if Pos(HotkeyChr, TextLine) > 0 then
				Dec(LineWidth); {Don't count the hotkey symbol}
			if LineWidth > MaxWidth then
				MaxWidth := LineWidth;
			Delete(Text, 1, NewLinePos); {Remove the processed line}
		end
		else
		begin
			{Last/only line}
			LineWidth := Length(Text);
			if Pos(HotkeyChr, Text) > 0 then
				Dec(LineWidth); {Don't count the hotkey symbol}
			if LineWidth > MaxWidth then
				MaxWidth := LineWidth;
			break;
		end;
	end;
	PrintW := MaxWidth * PrintCharW; {Each character is 8 pixels wide}
end;

function PrintH(Text: string): Integer;
var
	Lines, i: Integer;
begin
	Lines := 0;

	if Text <> '' then
		Lines := 1; {At least one line}

	{Count the number of NewLines to determine additional lines}
	for i := 1 to Length(Text) do
		if Text[i] = NewLine then
			Inc(Lines);

	PrintH := Lines * PrintLineH;
end;

procedure Print(Text: string; X, Y, Color: Integer);
var
	HotkeyPos, NewLinePos: Integer;
	TextLine: String;

	{Helper procedure - if the text contains a hotkey symbol, remove it
	 and draw an underline under the next character}
	procedure HandleHotkey(X, Y: Integer; var LineStr: String);
	begin
		HotkeyPos := Pos(HotkeyChr, LineStr);
		if HotkeyPos > 0 then
		begin
			Delete(LineStr, HotkeyPos, 1);
			Line(X + HotkeyPos * PrintCharW - 9, Y + 9, X + HotkeyPos * PrintCharW - 1, Y + 9);
		end;
	end;
begin
	SetTextJustify(LeftText, TopText);
	SetColor(Color);

	while length(Text) > 0 do
	begin
		NewLinePos := Pos(NewLine, Text);
		if NewLinePos > 0 then
		begin
			{Extract the line up to newline, print it, and remove it from Text}
			TextLine := Copy(Text, 1, NewLinePos - 1);
			HandleHotkey(X, Y, TextLine);
			OutTextXY(X, Y, TextLine);
			Delete(Text, 1, NewLinePos);
		end
		else
		begin
			{Last/only line}
			HandleHotkey(X, Y, Text);
			OutTextXY(X, Y, Text);
			break;
		end;
		Y := Y + PrintLineH; {Move down one line}
	end;
end;

function MouseClicked: TMouseButton;
var
	regs: registers;
begin
	if not MouseSupport then
	begin
		MouseClicked := MbNone;
		exit;
	end;
	regs.ax := 3;
	Intr($33, regs);
	MouseClicked := TMouseButton(regs.bx);
end;

Procedure MouseHide;
Var
	Regs: Registers;
Begin
	If Not MouseSupport Or Not MouseVisible Then Exit; {Don't call interrupt if no mouse or already hidden}
	Regs.ax := 2;
	Intr($33, Regs);
	MouseVisible := False;
End;

procedure MousePoll;
var
	regs: registers;
begin
	if not MouseSupport then Exit;
	regs.ax := 3;
	Intr($33, regs);
	MouseX := regs.cx;
	MouseY := regs.dx;
end;

procedure MouseMove(X, Y: Integer);
var
	regs: registers;
begin
	if not MouseSupport then Exit;
	regs.ax := 4;
	regs.cx := X;
	regs.dx := Y;
	Intr($33, regs);
end;

Procedure MouseShow;
Var
	Regs: Registers;
Begin
	If Not MouseSupport Then Exit; {Don't call interrupt if no mouse or already visible}
	Regs.ax := 1;
	Intr($33, Regs);
	MouseVisible := True;
End;

procedure SoundNote(Frequency, Duration: Integer);
begin
  Sound(Frequency);
  Delay(Duration);
  NoSound;
end;

function ReplaceMsg(const Msg, Value: String): String;
var
	Output: String;
	PosVal: Integer;
begin
	Output := Msg;
	PosVal := Pos('%s', Output); {Find the position of the %S placeholder}
	if PosVal > 0 then
	begin
		Delete(Output, PosVal, 2); {Remove %S}
		Insert(Value, Output, PosVal); {Insert value instead}
	end;
	ReplaceMsg := Output;
end;

function Replace(Input, OldSubStr, NewSubStr: String): String;
var
	PosStart: Integer;
begin
	PosStart := Pos(OldSubStr, Input); {Find the position of the substring}
	while PosStart > 0 do
	begin
		{Replace the substring}
		Delete(Input, PosStart, Length(OldSubStr)); {Remove the old substring}
		Insert(NewSubStr, Input, PosStart); {Insert the new substring}
		PosStart := Pos(OldSubStr, Input); {Find the next occurrence}
	end;
	Replace := Input;
end;

procedure SysLoadSettings;
var
	F: file;
	LoadError: Boolean;
begin
	LoadError := False;
	
	{Set defaults - will be overwritten if settings file loads successfully}
	Setting.DeskID := 1;
	Setting.LinkCapt := True;
	Setting.LinkTarget := False;
	Setting.ConfLinkDel := True;
	Setting.ConfExit := False;
	Setting.ThmFile := 'DEFAULT';
	
	if not FileExists(ProgramPath + GlobalSettings) then
		exit;
	
	Assign(F, ProgramPath + GlobalSettings);
	{$I-}
	Reset(F, 1);
	{$I+}
	if IOResult <> 0 then
		LoadError := True
	else if FileSize(F) <> SizeOf(TLibSetting) then
		LoadError := True;

	if LoadError then
	begin
		Close(F);
		exit;
	end;

	BlockRead(F, Setting, SizeOf(TLibSetting));
	Close(F);
end;

procedure LoadTheme(ThemeFile: String);
var
	F: file;
	ExpectedSize: LongInt;
begin
	{Default colors - will be overwritten if theme file loads successfully}
	Thm.Desk	  := Cyan;
	Thm.DeskText  := Black;
	Thm.Win	   := LightGray;
	Thm.Btn	   := LightGray;
	Thm.Txt	   := White;
	Thm.TxtText   := Black;
	Thm.WinText   := Black;
	Thm.Title	 := Blue;
	Thm.TitleText := White;
	Thm.Light	 := LightGray;
	Thm.Shadow	:= DarkGray;
	Thm.Sel	   := Blue;
	Thm.SelText   := White;

	{The end of the file contains 21 bytes for theme name, and 21	 for theme
	 author, so the total size should be 40 bytes more than the theme type}
	ExpectedSize := SizeOf(TTheme) + 42;

	if not FileExists('THEMES\' + ThemeFile + '.BIN') then
		exit;

	Assign(F, 'THEMES\' + ThemeFile + '.BIN');
	{$I-}
	Reset(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		Close(F);
		Exit;
	end;

	if FileSize(F) = ExpectedSize then
		BlockRead(F, Thm, SizeOf(TTheme));
	Close(F);
end;

function ProgramPath: DirStr;
var
	FullPath: PathStr;
	FPath: DirStr;
	FName: NameStr;
	FExt: ExtStr;
begin
	FullPath := ParamStr(0); {Full path of the executable}
	FSplit(FullPath, FPath, FName, FExt); 
	ProgramPath := FPath;
end;

procedure SysSaveSettings;
var
	F: file;
begin
	Assign(F, ProgramPath + GlobalSettings);
	{$I-}
	Rewrite(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		{MsgBox(MSG_SAVE_SETTING_ERROR_TITLE, MSG_SAVE_SETTING_ERROR_TEXT, MsgError);}
		{DEBUG - this must be handled alternatively, MsgBox can't be included int the library}
		Close(F);
		Exit;
	end;
	BlockWrite(F, Setting, SizeOf(TLibSetting));
	Close(F);
end;

function Timer: Real;
var
	Hour, Minute, Second, Hundredth: Word;
	Year, Month, Day, DayOfWeek: Word;
begin
	GetDate(Year, Month, Day, DayOfWeek);
	GetTime(Hour, Minute, Second, Hundredth);
	Timer := Day * 86400 + Hour * 3600 + Minute * 60 + Second + Hundredth / 100.0;
end;

function UpperCase(s: string): string;
var
	i: Integer;
begin
	for i := 1 to Length(s) do
		s[i] := UpCase(s[i]);
	UpperCase := s;
end;

function GetKey: string;
var
	OutString: String;
begin
	if not KeyPressed then
	begin
		GetKey := '';
		Exit;
	end;

	{ Read the key pressed }
	OutString := ReadKey;
	if OutString = #0 then
	begin
		OutString := OutString + ReadKey; {Read the next key for special keys}
	end;

	GetKey := OutString;
end;

procedure ClearInputBuffer;
begin
	repeat
		if KeyPressed then
			ReadKey;
	until (MouseClicked = MbNone) and not KeyPressed; {Wait until mouse is released and no keys are pressed}
end;

var
	regs: registers;
	GraphDriver: Integer;
	GraphMode: Integer;
	ErrorCode: Integer;
begin
	{Initialize EGA 640x350 mode}
	GraphDriver := EGA;
	GraphMode := EGAHI;
	InitGraph(GraphDriver, GraphMode, ProgramPath);
	ErrorCode := GraphResult;
	If ErrorCode <> GrOk Then
	Begin
		CloseGraph;
		Writeln(MSG_GRAPHICS_ERROR, GraphErrorMsg(ErrorCode));
		Halt(1);
	End;

	{Load settings and theme}
	SysLoadSettings;
	LoadTheme(Setting.ThmFile);

	{Initialize menu bar so app can use it right away}
	MenuBar.Init;

	{Check for mouse support}
	Intr($33, regs);
	MouseSupport := Regs.ax > 0;

	ClearInputBuffer; {DOSBox tends to leave keys in the buffer, so clear it}
	MouseShow;
end.