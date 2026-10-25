unit CostaLib;

{DEFINE DEBUG}

interface

uses
	Dos, Graph;

const
	LibName              = 'Costa UI Library';
	LibVersion           = '2.0';
	LibYear              = '2026';

	DoubleClickDelay     = 0.5;
	PrintLineH           = 12;   {Font dimensions - line height}
	PrintCharW           = 8;    {Width of a single character}
	ScreenWidth          = 639;  {To avoid overhead of GetMaxX/GetMaxY functions}
	ScreenHeight         = 349;
	MaxColor             = 15;

	MenuBarHeight        = 28;   {Used when setting height of menu bar, and when calculating offset for
	                              other child objects in windows}

	CharArrowUp:    Char = #24;  {Arrows symbols for fonts}
	CharArrowDown:  Char = #25;
	CharArrowRight: Char = #26;
	CharArrowLeft:  Char = #27;
	NewLine:        Char = #13;  {Wrap lines in Print, MsgBox, InputBox etc.}
	HotkeyChr:      Char = #127; {Marks hotkeys in object captions}
	Placeholder          = '%s'; {Placeholder in strings to replace with value}

	DecimalSign          = '.';  {Seperator signs - for localization}
	ThousandsSign        = ',';

	DosInt               = $21;   {MS-DOS API interrupt}
	DosFuncGetIntVector  = $35;   {Function: Get Interrupt Vector}
	DosFuncStdInStatus   = $0B;   {Function: Check Standard Input Status}
	DosFuncConInpNoEcho  = $08;   {Function: Console Input Without Echo}

	MouseInt             = $33;   {Mouse drive interrupt}
	MouseFuncResetAll    = $0000; {Function: Reset mouse software + hardware and read status}
	MouseFuncResetDriver = $0021; {Function: Reset mouse software}
	MouseFuncSetHandler  = $000C; {Function: Set Mouse Handler Routine}
	MouseFuncShowCursor  = $0001; {Function: Move cursor to CX, DX}
	MouseFuncHideCursor  = $0002; {Function: Move cursor to CX, DX}
	MouseFuncPoll        = $0003;
	MouseFuncMoveCursor  = $0004; {Function: Move cursor to CX, DX}
	MbNone               = 0;     {Mouse button states}
	MbLeft               = 1;
	MbRight              = 2;

	FileRead             = 0;
	FileWrite            = 1;
	FileReadWrite        = 2;

	{Standard DOS error messages used by Turbo Pascal}
	MSG_DOSERROR_1       = 'Invalid function';
	MSG_DOSERROR_2       = 'File not found';
	MSG_DOSERROR_3       = 'Path not found';
	MSG_DOSERROR_4       = 'Too many open files';
	MSG_DOSERROR_5       = 'Access denied';
	MSG_DOSERROR_6       = 'Invalid handle';
	MSG_DOSERROR_12      = 'Invalid access mode';
	MSG_DOSERROR_15      = 'Invalid drive number';
	MSG_DOSERROR_16      = 'Cannot remove current directory';
	MSG_DOSERROR_17      = 'Cannot rename across drives';
	MSG_DOSERROR_150     = 'Disk is write protected';
	MSG_DOSERROR_152     = 'Drive not ready';
	MSG_DOSERROR_162     = 'Hardware failure';
	MSG_DOSERROR_UNKNOWN = 'Unknown error (DOS error code %s)';

	{$I KEYCODES.INC}

type
	{Linked list of hotkeys, to allow multiple hotkeys per object}

	PApplication = ^TApplication;
	PUIObject    = ^TUIObject;
	PObjectNode  = ^TObjectNode;
	PHotkey      = ^THotkey;
	PHotkeyNode  = ^THotkeyNode;
	PWindow      = ^TWindow;
	PWindowNode  = ^TWindowNode;
	PContainer   = ^TContainer;
	PMenuBar     = ^TMenuBar;

	{Event procedure type, to ensure all event procedures have the same signature}
	TEventProc   = procedure(Sender: PUIObject);

	{Object states - implemented as a set to be able to store multiple values in one
	 byte, and to allow one Get/Set method to handle multiple boolean properties}
	TState       = (SEnabled, SHidden, SActive, SSelected, SDirty);
	TStateSet    = set of TState;

	TBorderStyle = (BorNone, Bor3D, Bor3DSunken, BorFrame, BorDialog, BorHorSeparator, BorVerSeparator, Bor3DBottom);

	TOrientation = (OrHorizontal, OrVertical, OrBoth); {Orientation for centering objects}
	TAlign       = (AlLeft, AlCenter, AlRight);        {Text alignment}

	{Linked list of hotkeys, to allow multiple hotkeys per object}
	THotkeyNode = record
		Hotkey: string;      {Hotkey as returned by GetKey}
		Next:   PHotkeyNode; {Pointer to next node in linked list}
	end;

	{Base object which all objects, visual or not, are based on}
	TUIObject = object
		public
			Left,
			Top:         Integer;      {Position relative to parent (or screen, if no parent)}
			Width,
			Height:      Word;         {Size}
			FgColor,
			BgColor:     Byte;         {Foreground (usually text) and background color}
			Hotkey:      PHotKeyNode;  {Linked list of hotkeys}
			State:       TStateSet;    {State flags}
			BorderStyle: TBorderStyle; {Single, double, rounded etc. for border - empty equals no border}
			Transparent: Boolean;
			OnClick:     TEventProc;   {Event procedure for mouse click or hotkey press}
			OnDraw:      TEventProc;   {Event procedure called at the end of Draw method, to allow custom drawing etc.}
			ParentObj:   PContainer;   {Parent object, if any}

			constructor Init;
			destructor  Done; virtual;

			function    HotkeyPressed: boolean;
			function    IsMouseOver: Boolean;
			procedure   CheckEvent; virtual;

			procedure   AddHotkey(Key: string);
			function    GetHotkey: PHotkeyNode;
			procedure   RemoveHotkey(Key: string);

			procedure   SetParent(Parent: PContainer);

			procedure   AddState(S: TState);
			procedure   RemoveState(S: TState);

			procedure   SetTransparent(T: Boolean);

			procedure   SetBorderStyle(Style: TBorderStyle);
			function    GetBorderWidth: Word;
			procedure   DrawBorder;

			procedure   Click;
			procedure   Draw; virtual;

			procedure   Resize(W, H: Word);
			procedure   Move(X, Y: Integer);
			procedure   Center(Orientation: TOrientation);

			procedure   GetAbsPos(var X, Y: Integer);

			procedure   SetFGColor(Color: Byte);
			procedure   SetBGColor(Color: Byte);

			function    IsContainer: boolean; virtual;
	end;

	{Linked list of objects based on PUIObject, can contain objects of any descendant type}
	TObjectNode = record
		ObjectP: PUIObject;
		Next:    PObjectNode;
	end;

	{Non-visual object, used to assign hotkeys to actions without a UI object}
	THotkey = object(TUIObject)
		constructor Init(Key: String; Parent: PContainer);
		procedure   CheckEvent; virtual;
	end;

	{Container object, which can contain multiple other objects via a linked list}
	TContainer = object(TUIObject)
		public
			constructor Init(X, Y: Integer; Parent: PContainer);
			destructor  Done; virtual;
			procedure   AddObject(Obj: PUIObject);
			procedure   CheckEvent; virtual;
			procedure   Draw; virtual;
			procedure   DrawChildren;
			procedure   DrawDirtyObjects;
			procedure   GetClientArea(var X, Y: Integer; var W, H: Word);
			function    IsContainer: boolean; virtual;
		private
			Objects:    PObjectNode; {Linked list of objects in the container}
	end;

	{Window object}
	TWindow = object(TContainer)
		public
			OnRun:      TEventProc;
			OnClose:    TEventProc;

			constructor Init(X, Y: Integer; Parent: PContainer);
			destructor  Done; virtual;

			procedure   CheckEvent; virtual;
			procedure   Draw; virtual;

			procedure   Run;
			procedure   Close;

			function    EnableMenu: PMenuBar;
			procedure   DisableMenu;

			procedure   SaveBackdrop;
		private
			MenuBarObj:       PMenuBar;        {Menu bar - in effect just a container at top of window}
			DoClose:          Boolean;         {Set to true to close the window by exiting Run loop}
			PreserveBackdrop: Boolean;         {If true, backdrop is preserved when window is drawn and restored when closed}
			BackdropP:        Pointer;         {Stores background image to restore when window is closed}
			BackdropS:        Word;            {Size of memory block used by BackdropP}
			procedure         RestoreBackdrop;
	end;

	{Linked list of windows, to allow multiple windows to be added to an application}
	TWindowNode = record
		ObjectP: PWindow;
		Next:    PWindowNode;
	end;

	{Menu bar object, attached to top of a window to display command buttons}
	TMenuBar = object(TContainer)
		public
			constructor Init(Parent: PContainer);

			procedure   Draw; virtual;
	end;

	{Main application object, to which windows can be added}
	TApplication = object
		public
			Name,
			Version,
			Author:     string;
			Icon:       string[8];
			ExitCode:   byte;
			OnRun:      TEventProc;
			OnExit:     TEventProc;

			constructor Init;
			destructor  Done; virtual;

			function    Path: DirStr;

			procedure   LoadSystemSettings;
			function    SaveSystemSettings: boolean;

			procedure   SetConfigFile(FileName: String; Ptr: pointer; MemSize: Integer);
			function    LoadSettings: boolean;
			function    SaveSettings: boolean;

			procedure   LoadTheme(FileName: string);

			procedure   OpenWindow(Win: PWindow);
			procedure   CloseWindow;

			procedure   Run;
			procedure   Terminate;
		private
			Window:     PWindowNode;
			ConfFile:   String[8];   {FileName without extension of apps config file, if any}
			ConfPtr:    Pointer;     {Pointer to, and size off, app config - usually a Record type declared by user}
			ConfLen:    Integer;
	end;

	{Mouse support is implemnted via custom object}
	TMouse = object
		public
			X,
			Y:          Word;
			Clicked:    Word;

			constructor Init;
			destructor  Done;
			function    Supported: Boolean;
			procedure   Show;
			procedure   Hide;
			procedure   Move(Left, Top: Integer);
		private
			Visible,
			Support:    Boolean;
	end;

	{Settings for the library, saved to disk}
	TLibSetting = record
		Audio:       Boolean;
		ThmFile:     string[8];
	end;

	{Theme colors}
	PTheme = ^TTheme;
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

	TSystemSound = (sndError, sndAttention);

var
	Mouse:          TMouse;      {Global mouse object}
	Setting:        TLibSetting; {Global settings for the library}
	Thm:            TTheme;      {Colors for the interface}
	ProgramPath:    DirStr;      {Path of the executable, used to load resources}
	HotkeyInput:    String;      {Stores the last pressed hotkey, used in event loops}
	NoParent:       PContainer;  {Null parent pointer, used when creating top-level windows}

function  FileExists(const FileName: string): Boolean;
function  Valid8dot3(FileName: string): Boolean;

procedure ClearInputBuffer;
function  GetKey: string;

function  Timer: Real;

procedure Print(Text: string; X, Y, Color: Integer);
function  PrintW(Text: String): Integer;
function  PrintH(Text: string): Integer;

function  GetDosErrorMsg(ErrorCode: Integer): String;
procedure DosPrint(Text: String);

function  UpperCase(s: string): string;
function  Replace(Input, OldSubStr, NewSubStr: String): String;

procedure Sleep(Milliseconds: Word);
procedure SoundNote(Frequency, Duration: Word);
procedure SystemSound(SoundType: TSystemSound);

implementation

const
	GlobalSettings      = 'CONFIG\SYSTEM.BIN';

	StackMark:     Char = #143; {Used in debugging to fill the stack with a known character, so that run-time stack usage can be
	                             measured}

	MSG_GRAPHICS_ERROR  = 'Graphics error: ';

{$IFDEF DEBUG}
var
	StartingSP: Word; {When debugging, holds the offset where the stack pointer was when program started}
{$ENDIF}


{----------------------------------------------------------------------------}
{ Helper functions used by library, objects and user applications
{----------------------------------------------------------------------------}

{TMouse hooks the mouse driver to this procedure, which the mouse driver calls every time the mouse is moved or clicked. This
 procedure then updates mouse variables, which the TMouse object returns when asked. This allows the mouse to work without
 polling}
procedure MouseHandler; far; assembler;
asm
	push ds                 {Ensure correct DS when mouse driver calls this procedure}
	mov ax, seg Mouse.X
	mov ds, ax

	mov ax, MouseFuncPoll  {Poll mouse state}
	int MouseInt

	mov Mouse.Clicked, bx  {Save mouse state to variables}
	mov Mouse.X, cx
	mov Mouse.Y, dx

	pop ds                 {Restore DS}
end;

{$IFDEF DEBUG}
	procedure DebugMarkStackStart;
	var
		P: ^Char;
		I: Word;
	begin
		StartingSP := SPtr;
		{Leave 256 bytes before SPtr untouched, just for safety}
		for I := 0 to StartingSP - 256 do
		begin
			P := Ptr(SSeg, I); {Move pointer to stack segment, offset I}
			P^ := StackMark;   {Set byte at pointer to the stack mark}
		end;
	end;

	function DebugGetStackUsed: Word;
	var
		P: ^Char;
		I: Word;
	begin
		I := 0;
		while I < StartingSP do
		begin
			P := Ptr(SSeg, I); {Move pointer to stack segment, offset I}
			{If byte at pointer isn't our stack mark, it has been modified}
			if P^ <> StackMark then
				break;
			Inc(I);
		end;
		DebugGetStackUsed := StartingSP - I;
	end;
{$ENDIF}

{----------------------------------------------------------------------------}
{ Base UI object implementation }
{----------------------------------------------------------------------------}
{$I UIOBJECT.INC}

{----------------------------------------------------------------------------}
{ Hotkey object implementation }
{----------------------------------------------------------------------------}

constructor THotkey.Init(Key: String; Parent: PContainer);
begin
	Inherited Init;
	SetParent(Parent);
	Self.AddHotkey(Key);
end;

procedure THotkey.CheckEvent;
begin
	if not (SEnabled in State) then
		exit;

	if Self.HotkeyPressed then
		{Trigger OnClick event, if assigned}
		Self.Click;
end;

{----------------------------------------------------------------------------}
{ Application object implementation }
{----------------------------------------------------------------------------}

constructor TApplication.Init;
var
	FullPath: PathStr;
	FPath: DirStr;
	FName: NameStr;
	FExt: ExtStr;
	GraphDriver,
	GraphMode,
	ErrorCode: Integer;
begin
	Name     := '';
	Version  := '';
	Author   := '';
	Icon     := '';
	ConfFile := '';
	ConfPtr  := nil;
	ConfLen  := 0;
	ExitCode := 0;
	Window   := nil;
	OnRun    := nil;
	OnExit   := nil;

	{$IFDEF DEBUG}
		{If debugging, fill the stack with an identifiable mark so
		 stack usage can be measured at program exit}
		DebugMarkStackStart;
	{$ENDIF}

	{Retrieve full path of the executable}
	FullPath := ParamStr(0);
	FSplit(FullPath, FPath, FName, FExt);
	ProgramPath := FPath;

	{Initialize EGA 640x350 mode}
	GraphDriver := EGA;
	GraphMode := EGAHI;
	InitGraph(GraphDriver, GraphMode, ProgramPath); {EGAVGA.BGI must be in EXE directory}
	ErrorCode := GraphResult;
	If ErrorCode <> GrOk Then
	Begin
		CloseGraph;
		DosPrint(MSG_GRAPHICS_ERROR);
		DosPrint(GraphErrorMsg(ErrorCode));
		Halt(1);
	End;

	{Make sure library directories exists to avoid apps crashing when trying to read
	 from them}
	{$I-}
	MkDir('CONFIG');
	MkDir('ICONS');
	MkDir('THEMES');
	{$I+}
	{Clear IOResult}
	ErrorCode := IOResult;

	{Load settings and theme}
	Self.LoadSystemSettings;
	Self.LoadTheme(Setting.ThmFile);

	{Initialize mouse and hook event handler}
	Mouse.Init;
end;

destructor TApplication.Done;
var
	NextNode: PWindowNode;
begin
	{Free all object nodes in the linked list}
	while Assigned(Window) do
	begin
		NextNode := Window^.Next; {Store pointer to next node}

		{Call the destructor of the window, which in turn calls destructor of each object in it}
		if Assigned(Window^.ObjectP) then
			Dispose(Window^.ObjectP, Done);
		{Free current node}
		Dispose(Window);

		{Move to next node}
		Window := NextNode;
	end;

	{Must be called to remove the mouse handler procedure hook in the mouse driver}
	Mouse.Done;
end;

procedure TApplication.OpenWindow(Win: PWindow);
var
	NewNode: PWindowNode;
begin
	{Create a new node and add it to the start of the linked list, which
	 allows multiple windows to be stacked}
	New(NewNode);
	NewNode^.ObjectP := Win;
	NewNode^.Next := Self.Window;
	Self.Window := NewNode;
end;

procedure TApplication.CloseWindow;
var
	RemoveNode: PWindowNode;
begin
	if not Assigned(Window) then
		exit;

	RemoveNode := Window;
	Window := Window^.Next;

	{Remove the window from the linked list. The window is not disposed of, as
	 the application may want to reuse it later}
	Dispose(RemoveNode);
end;

procedure TApplication.Terminate;
begin
	{Any windows are not closed "nicely" - the application must perform its pre-exit routines before calling Terminate}
	if Assigned(OnExit) then
		OnExit(@Self);

	Self.Done; {Call destructor, in case any descendant objects have additional cleanup code}

	CloseGraph;

	{$IFDEF DEBUG}
		WriteLn('Stack used during runtime: ', DebugGetStackUsed, ' bytes');
	{$ENDIF}

	Halt(ExitCode);
end;

procedure TApplication.Run;
begin
	ClearInputBuffer; {DOSBox tends to leave keys in the buffer, so clear it}
	Mouse.Show;

	{Trigger OnRun event, if assigned}
	If Assigned(OnRun) then
		OnRun(@Self);

	{As long as the application has at least one window, run that window}
	while Assigned(Window) do
		Window^.ObjectP^.Run;

	Self.Terminate; {No more windows, exit the application}
end;

function TApplication.Path: DirStr;
begin
	Path := ProgramPath;
end;

procedure TApplication.LoadTheme(FileName: String);
var
	ThemeFile: string;
	F: file;
	ExpectedSize: LongInt;
begin
	{Default colors - will be overwritten if theme file loads successfully}
	Thm.Desk      := LightBlue;
	Thm.DeskText  := Black;
	Thm.Win       := Cyan;
	Thm.Btn       := Cyan;
	Thm.Txt       := White;
	Thm.TxtText   := Black;
	Thm.WinText   := Black;
	Thm.Title     := Blue;
	Thm.TitleText := White;
	Thm.Light     := LightGray;
	Thm.Shadow    := DarkGray;
	Thm.Sel       := Blue;
	Thm.SelText   := White;

	{The end of the file contains 21 bytes for theme name, and 21 for theme
	 author, so the total size should be 42 bytes more than the theme type}
	ExpectedSize := SizeOf(TTheme) + 42;

	{If no filename specified, use default theme}
	if Length(FileName) = 0 then
		FileName := 'DEFAULT';

	ThemeFile := Self.Path + 'THEMES\' + FileName + '.BIN';
	if FileExists(ThemeFile) then
	begin
		Assign(F, ThemeFile);
		FileMode := FileRead;
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
end;

procedure TApplication.LoadSystemSettings;
var
	F: file;
	FileName: String;
begin
	FileName := Self.Path + GlobalSettings;
	if not FileExists(FileName) then
		Exit;

	Assign(F, FileName);
	{$I-}
	Reset(F, 1);
	{$I+}

	{If file couldn't be opened for read, exit procedure}
	if IOResult <> 0 then
		Exit;

	{If filesize matches expectation, load settings from it}
	if FileSize(F) = SizeOf(Setting) then
		BlockRead(F, Setting, SizeOf(Setting));

	Close(F);
end;

function TApplication.SaveSystemSettings: Boolean;
var
	F: file;
begin
	Assign(F, Self.Path + GlobalSettings);
	{$I-}
	Rewrite(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		SaveSystemSettings := False;
		exit;
	end;
	BlockWrite(F, Setting, SizeOf(TLibSetting));
	Close(F);
	SaveSystemSettings := True;
end;

procedure TApplication.SetConfigFile(FileName: String; Ptr: pointer; MemSize: Integer);
begin
	{Input validation - anything off? Then clear everything to be safe}
	if (Length(FileName) > 8) or (Length(FileName) < 1) or
		 (Ptr = nil) or (MemSize < 1) then
	begin
		ConfFile := '';
		ConfPtr := nil;
		ConfLen := 0;
		exit;
	end;

	ConfFile := FileName;
	ConfPtr := Ptr;
	ConfLen := MemSize;
end;

function TApplication.LoadSettings: boolean;
var
	F: file;
	FileName: String;
begin
	{Validate config vars before attempting load}
	if (ConfPtr = nil) or (Length(ConfFile) = 0) or (ConfLen < 1) then
	begin
		LoadSettings := false;
		Exit;
	end;

	FileName := Self.Path + 'CONFIG\' + ConfFile + '.BIN';

	if not FileExists(FileName) then
	begin
		LoadSettings := false;
		Exit;
	end;

	Assign(F, FileName);
	FileMode := FileRead;
	{$I-}
	Reset(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		LoadSettings := false;
		Exit;
	end;

	if FileSize(F) <> ConfLen then
	begin
		Close(F);
		LoadSettings := false;
		exit;
	end;

	BlockRead(F, ConfPtr^, ConfLen);
	Close(F);
	LoadSettings := true;
end;

function TApplication.SaveSettings: boolean;
var
	F: file;
	FileName: String;
begin
	{Validate config vars before attempting load}
	if (ConfPtr = nil) or (Length(ConfFile) = 0) or (ConfLen < 1) then
	begin
		SaveSettings := false;
		Exit;
	end;

	FileName := Self.Path + 'CONFIG\' + ConfFile + '.BIN';

	Assign(F, FileName);
	{$I-}
	Rewrite(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		SaveSettings := false;
		Exit;
	end;
	BlockWrite(F, ConfPtr^, ConfLen);
	Close(F);
	SaveSettings := true;
end;

{----------------------------------------------------------------------------}
{ Container object implementation }
{----------------------------------------------------------------------------}
{$I UICONT.INC}

{----------------------------------------------------------------------------}
{ Window object implementation }
{----------------------------------------------------------------------------}
{$I UIWINDOW.INC}

{----------------------------------------------------------------------------}
{ Menu bar object implementation }
{----------------------------------------------------------------------------}
{$I UIMENU.INC}

{----------------------------------------------------------------------------}
{ Mouse object implementation }
{----------------------------------------------------------------------------}

constructor TMouse.Init;
var
	Regs: registers;
begin
	Visible := False;
	X       := 0;
	Y       := 0;
	Clicked := MbNone;
	Support := false;

	{Check that mouse interrupt is assigned. If it isn't, calling it could hang the system}
	Regs.ah := DosFuncGetIntVector;
	Regs.al := MouseInt;
	Intr(DosInt, Regs);
	if (Regs.es = 0) or (Regs.bx = 0) then
		exit;

	{Mouse interrupt OK, call it and verify that mouse is available}
	Regs.ax := MouseFuncResetAll;
	Intr(MouseInt, Regs);
	Support := Regs.ax > 0;
	if not Support then
		exit;

	{If mouse is available, install MouseHandler in the driver so that is is called whenever mouse is moved or clicked}
	Regs.AX := MouseFuncSetHandler;
	Regs.CX := $FFFF;                 {FFFF = all mouse events}
	Regs.ES := Seg(MouseHandler);
	Regs.DX := Ofs(MouseHandler);
	Intr(MouseInt, Regs);
end;

procedure TMouse.Hide;
begin
	{Don't call interrupt if no mouse or already hidden}
	If Not Support Or Not Visible Then
		Exit;

	asm
		mov AX, MouseFuncHideCursor;
		int 33h;
	end;

	Visible := False;
end;

procedure TMouse.Move(Left, Top: Integer);
begin
	if (Left < 0) or (Left > ScreenWidth) or
	   (Top < 0) or (Top > ScreenHeight) then
		Exit; {Out of bounds}

	Self.X := Left;
	Self.Y := Top;

	{Can't move mouse if no mouse support, but variables are set above anyway
	 in case something depends on being able to control mouse pos}
	if not Support then
		Exit;

	asm
		mov AX, MouseFuncMoveCursor;
		mov CX, Left;
		mov DX, Top;
		int MouseInt;
	end;
end;

procedure TMouse.Show;
Begin
	{Don't call interrupt if no mouse or already visible}
	If Not Support Then
		Exit;

	asm
		mov AX, MouseFuncShowCursor;
		int 33H;
	end;

	Visible := True;
End;

Function TMouse.Supported: Boolean;
Begin
	Supported := Support;
End;

destructor TMouse.Done;
begin
	if not Support then
		exit;

	asm
		{CX = 0 removes mouse event handler. This should be done automatically by
		 MouseFuncResetDriver, but doesn't always seem to be the case}
		mov AX, MouseFuncSetHandler
		xor CX, CX
		int MouseInt

		{Reset mouse driver}
		mov AX, MouseFuncResetDriver
		int MouseInt
	end;
end;

{----------------------------------------------------------------------------}
{ Generic functions/procedures that fall outside any object }
{----------------------------------------------------------------------------}

function FileExists(const FileName: string): Boolean;
var
	sResults: SearchRec;
begin
	FindFirst(FileName, Archive, sResults);
	FileExists := (DosError = 0);
end;

function Valid8dot3(FileName: string): Boolean;
var
	DotPos, NameLen, ExtLen, i: Integer;
begin
	Valid8dot3 := false;

	if Length(FileName) = 0 then
		exit;

	DotPos := Pos('.', FileName);
	if DotPos = 0 then
	begin
		{FileName does not include extension}
		NameLen := Length(FileName);
		if (NameLen > 8) then
		exit;
	end
	else
	begin
		{FileName includes extension}
		NameLen := DotPos - 1;
		ExtLen := Length(FileName) - DotPos;

		if (NameLen > 8) or (ExtLen > 3) then
			exit;
	end;

	{Check for invalid characters}
	for i := 1 to Length(FileName) do
		if not (FileName[i] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '~',
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

{DosPrint outputs console text. This is to avoid linking WriteLn and all of the special formatting code it contains}
procedure DosPrint(Text: string);
var
	EscapedText: String;
	Regs: Registers;
begin
	if Length(Text) = 0 then
		exit;

	EscapedText := Text;
	if (EscapedText[Length(EscapedText)] <> '$') then
		EscapedText := EscapedText + '$';

	FillChar(Regs, SizeOf(Regs), $0);
	Regs.Ah := 9;
	Regs.Ds := Seg(EscapedText[1]); {Use segment/offset of first char, to avoid the length byte being printed}
	Regs.Dx := Ofs(EscapedText[1]);
	Intr(DosInt, Regs);
end;

procedure SoundNote(Frequency, Duration: Word);
var
	Divisor: Word;
begin
	if (Frequency = 0) or (Duration = 0) then
	  Exit;

	Divisor   := 1193180 div Frequency;  {Set PIT base frequency}
	Port[$43] := $B6;                    {Set PIT channel 2}
	Port[$42] := Lo(Divisor);            {Output frequency to port}
	Port[$42] := Hi(Divisor);
	Port[$61] := Port[$61] or $03;       {Enable speaker}
  Sleep(Duration);
  Port[$61] := Port[$61] and $FC;      {Disable speaker}
end;

procedure SystemSound(SoundType: TSystemSound);
begin
	if not Setting.Audio then
		exit;

	case SoundType of
		sndError:     SoundNote(440, 45);
		sndAttention: SoundNote(960, 25);
	end;
end;

function Replace(Input, OldSubStr, NewSubStr: String): String;
var
	PosStart: Integer;
begin
	PosStart := Pos(OldSubStr, Input); {Find the position of the substring}
	if PosStart > 0 then
	begin
		{Replace the substring}
		Delete(Input, PosStart, Length(OldSubStr)); {Remove the old substring}
		Insert(NewSubStr, Input, PosStart); {Insert the new substring}
		PosStart := Pos(OldSubStr, Input); {Find the next occurrence}
	end;
	Replace := Input;
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

procedure Sleep(Milliseconds: Word);
var
	Start, Now, Duration: LongInt;
begin
	Duration := Milliseconds div 55; {55 ms per tick}
	if Duration = 0 then
		Duration := 1;

	asm
		mov ah, 0
		int 1Ah
		mov word ptr Start, dx
		mov word ptr Start+2, cx
	end;

	repeat
		asm
			mov ah, 0
			int 1Ah
			mov word ptr Now, dx
			mov word ptr Now+2, cx
		end;
	until (now - start) >= Duration;
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
	Regs: Registers;
begin
	{Check if keyboard buffer contains anything}
	Regs.AH := DosFuncStdInStatus;
	Intr(DosInt, Regs);
	if Regs.AL = $0 then
	begin
		GetKey := '';
		Exit;
	end;

	{Read scan code from keyboard buffer}
	Regs.AH := DosFuncConInpNoEcho;
	Intr(DosInt, Regs);

	{If scan code is null, an extended key was pressed and we must read the next scan code as well}
	if Regs.AL = $0 then
	begin
		Regs.AH := DosFuncConInpNoEcho;
		Intr(DosInt, Regs);
		GetKey := Chr(0) + Chr(Regs.AL); {Return both scan codes combined}
	end
	else
		GetKey := Chr(Regs.AL);
end;

procedure ClearInputBuffer;
var
	KeyStatus: Boolean;
	Regs: Registers;
begin
	{Check if keyboard buffer contains anything}
	Regs.AH := DosFuncStdInStatus;
	Intr(DosInt, Regs);

	{As long as keyboard buffer contains something, read it - thus clearing it}
	while Regs.AL <> 0 do
	begin
		Regs.AH := DosFuncConInpNoEcho;
		Intr(DosInt, Regs);

		Regs.AH := DosFuncStdInStatus;
		Intr(DosInt, Regs);
	end;

	{Keyboard buffer empty, wait for mouse to be released}
	while (Mouse.Clicked <> MbNone) do;
end;

function GetDosErrorMsg(ErrorCode: Integer): String;
var
	ErrorCodeStr: String;
begin
	case ErrorCode of
		  1:  GetDosErrorMsg := MSG_DOSERROR_1;
		  2:  GetDosErrorMsg := MSG_DOSERROR_2;
		  3:  GetDosErrorMsg := MSG_DOSERROR_3;
		  4:  GetDosErrorMsg := MSG_DOSERROR_4;
		  5:  GetDosErrorMsg := MSG_DOSERROR_5;
		  6:  GetDosErrorMsg := MSG_DOSERROR_6;
		 12:  GetDosErrorMsg := MSG_DOSERROR_12;
		 15:  GetDosErrorMsg := MSG_DOSERROR_15;
		 16:  GetDosErrorMsg := MSG_DOSERROR_16;
		 17:  GetDosErrorMsg := MSG_DOSERROR_17;
		150:  GetDosErrorMsg := MSG_DOSERROR_150;
		152:  GetDosErrorMsg := MSG_DOSERROR_152;
		162:  GetDosErrorMsg := MSG_DOSERROR_162;

		else
			begin
				Str(ErrorCode, ErrorCodeStr);
				GetDosErrorMsg := Replace(MSG_DOSERROR_UNKNOWN, Placeholder, ErrorCodeStr);
			end;
	end;
end;

end.