unit CostaLib;

interface

uses
	Crt, Dos, Graph, Strings;

const
	LibName              = 'Costa UI Library';
	LibVersion           = '2.0';
	LibYear              = '2025';

	SizeDefault          = -1;   {Used to set default width/height on object init}
	SizeCenter           = -2;   {Used to center objects on screen}
 
	ColorDefault         = 255;  {Used to set default colors on objects}
  
	DoubleClickDelay     = 0.5;  
	PrintLineH           = 12;   {Font dimensions - line height}
	PrintCharW           = 8;    {Width of a single character}
 
	CharArrowUp:	Char = #24;  {Arrows symbols for fonts}
	CharArrowDown:  Char = #25;
	CharArrowRight: Char = #26;
	CharArrowLeft:  Char = #27;
	NewLine:        Char = #13;  {Wrap lines in Print, MsgBox, InputBox etc.}
	HotkeyChr:      Char = #127; {Marks hotkeys in object captions}

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
	PMenu        = ^TMenu;

	{Event procedure type, to ensure all event procedures have the same signature}
	TEventProc   = procedure(Sender: PUIObject);

	TState       = (Enabled, Hidden, Active, Selected);
	TStateSet    = set of TState;

	{Linked list of hotkeys, to allow multiple hotkeys per object}
	THotkeyNode = record
		Hotkey: string;      {Hotkey as returned by GetKey}
		Next:   PHotkeyNode; {Pointer to next node in linked list}
	end;

	{Base object which all objects, visual or not, are based on}
	TUIObject = object
		public
			Left,
			Top,
			Width,
			Height:     Integer;
			Hotkey:     PHotKeyNode; {Linked list of hotkeys}
			OnClick:    TEventProc;  {Event procedure for mouse click or hotkey press}
			OnDraw:     TEventProc;
			Parent:     PUIObject;   {Parent object, if any - should only use container types}
			constructor Init;
			Destructor  Done; virtual;
			function    GetState(S: TState): Boolean;
			function    HotkeyPressed: boolean;
			function    IsMouseOver: Boolean;
			procedure   AddHotkey(Key: string);
			procedure   AddState(S: TState);
			procedure   CheckEvent; virtual;
			procedure   Draw; virtual;
			procedure   RemoveState(S: TState);
			procedure   SetSize(X, Y, W, H, DefaultW, DefaultH: Integer);
		private
			State:      TStateSet;   {State flags}
	end;

	{Linked list of objects based on PUIObject, can contain objects of any descendant type}
	TObjectNode = record
		ObjectP: PUIObject;
		Next:    PObjectNode;
	end;

	{Non-visual object, used to assign hotkeys to actions without a UI object}
	THotkey = object(TUIObject)
		constructor Init(Key: String);
		procedure   CheckEvent; virtual;
	end;

	{Menu bar object, placed at the top of a window}
	TMenu = object(TUIObject)
		constructor Init;
		procedure   Draw; virtual;
	end;

	{Container object, which can contain multiple other objects via a linked list}
	TContainer = object(TUIObject)
		public
			constructor Init(X, Y, W, H: Integer);
			destructor  Done; virtual;
			procedure   AddObject(Obj: PUIObject);
		private
			Objects:    PObjectNode; {Linked list of objects in the container}
	end;
	
	{Window object}
	TWindow = object(TContainer)
		public
			Border:     Boolean;
			OnRun:      TEventProc;
			OnClose:    TEventProc;
			constructor Init(X, Y, W, H: Integer);
			procedure   CheckEvent; virtual;
			{procedure   SetMenu(Menu: PMenu);}
			procedure   Draw; virtual;
			procedure   Run;
			procedure   Close;
		private
			MenuObj:    PMenu;	     {Menu bar object, if any}
			DoClose:    Boolean;     {Set to true to close the window by exiting Run loop}
	end;

	{Linked list of windows, to allow multiple windows to be added to an application}
	TWindowNode = record
		ObjectP: PWindow;
		Next:    PWindowNode;
	end;

	{Main application object, to which windows can be added}
	TApplication = object
		public
			Name,
			Version,
			Author,
			Icon:       string;
			OnRun:      TEventProc;
			OnExit:     TEventProc;
			constructor Init;
			destructor  Done; virtual;
			function    Path: DirStr;
			procedure   CloseWindow;
			procedure   Exit;
			procedure   LoadSettings;
			procedure   LoadTheme(Filename: string);
			procedure   OpenWindow(Win: PWindow);
			procedure   Run;
			procedure   SaveSettings;
		private
			Window:     PWindowNode;
	end;

	{Mouse support is implemnted via custom object}
	TMouseButton  = (MbNone, MbLeft, MbRight, MbBoth);
	TMouse = object
		public
			constructor Init;
			function    Clicked: TMouseButton;
			function    Supported: Boolean;
			function    X: Integer;
			function    Y: Integer;
			procedure   Hide;
			procedure   Move(Left, Top: Integer);
			procedure   Poll;
			procedure   Show;
		private
			Visible,
			Support:    Boolean;
			XPos,
			YPos:       Integer;
	end;

	{Settings for the library, saved to disk}
	TLibSetting = record
		DeskID:      Integer;
		LinkCapt,
		LinkTarget,
		ConfLinkDel,
		ConfExit:    Boolean;
		ThmFile:     string[8];
	end;

	{Theme colors}
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
	Mouse:          TMouse;      {Global mouse object}
	Setting:        TLibSetting; {Global settings for the library}
	Thm:            TTheme;      {Colors for the interface}
	ProgramPath:    DirStr;      {Path of the executable, used to load resources}
	HotkeyInput:    String;      {Stores the last pressed hotkey, used in event loops}

function  FileExists(const FileName: string): Boolean;
function  Valid8dot3(Filename: string): Boolean;

procedure ClearInputBuffer;
function  GetKey: string;

function  Timer: Real;

procedure Print(Text: string; X, Y, Color: Integer);
function  PrintW(Text: String): Integer;
function  PrintH(Text: string): Integer;

function  UpperCase(s: string): string;
function  Replace(Input, OldSubStr, NewSubStr: String): String;
function  ReplaceMsg(const Msg, Value: String): String;

procedure SoundNote(Frequency, Duration: Integer);

implementation

const
	GlobalSettings = 'CONFIG\SETTINGS.BIN';

	{Message strings}
	MSG_SAVE_SETTING_ERROR_TITLE = 'Error saving settings';
	MSG_SAVE_SETTING_ERROR_TEXT  = 'Could not write to the settings file' + #13 + 
	                               '%s.' + #13 +
	                               'Verify that the path exists and isn''t read-only.';
	MSG_GRAPHICS_ERROR           = 'Graphics error:';



{----------------------------------------------------------------------------}
{ Base UI object implementation }
{----------------------------------------------------------------------------}

constructor TUIObject.Init;
begin
	State   := [Enabled];
	Hotkey  := nil;
	OnClick := nil;
	OnDraw  := nil;
	Left    := 0;
	Top     := 0;
	Width   := 0;
	Height  := 0;
end;

destructor TUIObject.Done;
var
	NextNode: PHotKeyNode;
begin
	{Free all hotkey nodes in the linked list}
	while Assigned(Hotkey) do
	begin
		NextNode := HotKey^.Next; {Store pointer to next node}
		Dispose(Hotkey);          {Free current node}
		Hotkey := NextNode;       {Move to next node}
	end;
end;

function TUIObject.GetState(S: TState): Boolean;
begin
	GetState := (S in State);
end;

{Check for hotkeys events assigned to the object}
function TUIObject.HotkeyPressed: boolean;
var
	CheckNode: PHotKeyNode;
begin
	HotkeyPressed := False;

	if not (Enabled in State) or (Length(HotkeyInput) = 0) then
		exit;
	
	CheckNode := Hotkey;
	while Assigned(CheckNode) do
	begin
		if CheckNode^.HotKey = HotkeyInput then
		begin
			HotkeyInput := ''; {Reset hotkey}
			HotkeyPressed := True;
			exit;
		end;
		CheckNode := CheckNode^.Next; {Move to next node in linked list}
	end;
end;

{Check if mouse is over the object}
function TUIObject.IsMouseOver: Boolean;
var
	X1, Y1, X2, Y2: Integer;
begin
	Mouse.Poll;
	X1 := Left;
	Y1 := Top;
	X2 := X1 + Width;
	Y2 := Y1 + Height;
	IsMouseOver := (Mouse.X >= X1) and (Mouse.X <= X2) and (Mouse.Y >= Y1) and (Mouse.Y <= Y2);
end;

{Add a hotkey to an object - a linked list is used to allow multiple hotkeys}
procedure TUIObject.AddHotkey(Key: string);
var
	CheckNode, NewNode: PHotKeyNode;
begin
	if (Length(Key) < 1) or (Length(Key) > 2) then
		exit; {Invalid hotkey, do nothing}

	New(NewNode);
	NewNode^.HotKey := Key;
	NewNode^.Next := Self.Hotkey;
	Self.Hotkey := NewNode;
end;

procedure TUIObject.AddState(S: TState);
begin
	Include(State, S);
end;

{Check for events on object}
procedure TUIObject.CheckEvent;
var
	Clicked: boolean;
begin
	if not GetState(Enabled) then
		exit;
	
	Clicked := False;
	{Check if mouse is clicked on the object}
	if (Mouse.Clicked = MbLeft) and Self.IsMouseOver then
	begin
		repeat;	until Mouse.Clicked = MbNone;
		{Check if mouse is still over the object after release}
		if Self.IsMouseOver then
			Clicked := True;
	end;

	if Clicked or Self.HotkeyPressed then
		{Trigger OnClick event, if assigned}
		if Assigned(OnClick) then
			OnClick(@Self);
end;

{Dummy procedure, descandants should implement their own versions}
procedure TUIObject.Draw;
begin
end;

procedure TUIObject.RemoveState(S: TState);
begin
	Exclude(State, S);
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
end;

{----------------------------------------------------------------------------}
{ Hotkey object implementation }
{----------------------------------------------------------------------------}

constructor THotkey.Init(Key: String);
begin
	Inherited Init;
	Self.SetSize(0, 0, 0, 0, SizeDefault, SizeDefault);
	Self.Hotkey := nil;
	Self.AddHotkey(Key);
end;

procedure THotkey.CheckEvent;
begin
	if not GetState(Enabled) then
		exit;
	
	if Self.HotkeyPressed then
		{Trigger OnClick event, if assigned}
		if Assigned(OnClick) then
			OnClick(@Self);
end;

{----------------------------------------------------------------------------}
{ Menu object implementation }
{----------------------------------------------------------------------------}

constructor TMenu.Init;
begin
	TUIObject.Init;
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
	Name    := '';
	Version := '';
	Author  := '';
	Icon    := '';
	Window  := nil;
	OnRun   := nil;
	OnExit  := nil;
	{Retrieve full path of the executable}
	FullPath := ParamStr(0); 
	FSplit(FullPath, FPath, FName, FExt); 
	ProgramPath := FPath;

	{Initialize EGA 640x350 mode}
	GraphDriver := EGA;
	GraphMode := EGAHI;
	InitGraph(GraphDriver, GraphMode, Self.Path);
	ErrorCode := GraphResult;
	If ErrorCode <> GrOk Then
	Begin
		CloseGraph;
		Writeln(MSG_GRAPHICS_ERROR, GraphErrorMsg(ErrorCode));
		Halt(1);
	End;

	{Load settings and theme}
	Self.LoadSettings;
	Self.LoadTheme(Setting.ThmFile);

	{Initialize mouse}
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
		Window^.ObjectP^.Done;

		Dispose(Window^.ObjectP);
		Dispose(Window);

		{Move to next node}
		Window := NextNode;
	end;
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

	{Set the window's parent to the application}
	Win^.Parent := @Self;
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

procedure TApplication.Exit;
begin
	If Assigned(OnExit) then
		OnExit(@Self);

	Self.Done; {Call destructor, in case any descendant objects have additional cleanup code}
	
	CloseGraph;
	Halt(0);
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

	Self.Exit; {No more windows, exit the application}
end;

function TApplication.Path: DirStr;
begin
	Path := ProgramPath;
end;

procedure TApplication.LoadTheme(Filename: String);
var
	ThemeFile: string;
	F: file;
	ExpectedSize: LongInt;
begin
	{Default colors - will be overwritten if theme file loads successfully}
	Thm.Desk      := Cyan;
	Thm.DeskText  := Black;
	Thm.Win       := LightGray;
	Thm.Btn       := LightGray;
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
	if Length(Filename) = 0 then
		Filename := 'DEFAULT';

	ThemeFile := Self.Path + 'THEMES\' + Filename + '.BIN';
	if FileExists(ThemeFile) then
	begin
		Assign(F, ThemeFile);
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

procedure TApplication.LoadSettings;
var
	F: file;
	LoadError: Boolean;
begin
	LoadError := False;
	
	{Set defaults - will be overwritten if settings file loads successfully}
	Setting.DeskID      := 1;
	Setting.LinkCapt    := True;
	Setting.LinkTarget  := False;
	Setting.ConfLinkDel := True;
	Setting.ConfExit    := False;
	Setting.ThmFile     := 'DEFAULT';
	
	if not FileExists(Self.Path + GlobalSettings) then
		exit;
	
	Assign(F, Self.Path + GlobalSettings);
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

procedure TApplication.SaveSettings;
var
	F: file;
begin
	Assign(F, Self.Path + GlobalSettings);
	{$I-}
	Rewrite(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		{MsgBox(MSG_SAVE_SETTING_ERROR_TITLE, MSG_SAVE_SETTING_ERROR_TEXT, MsgError);}
		{DEBUG - this must be handled alternatively, MsgBox can't be included in the library}
		Close(F);
		Exit;
	end;
	BlockWrite(F, Setting, SizeOf(TLibSetting));
	Close(F);
end;

{----------------------------------------------------------------------------}
{ Container object implementation }
{----------------------------------------------------------------------------}

constructor TContainer.Init(X, Y, W, H: Integer);
const
	DefaultW = 320;
	DefaultH = 175;
begin
	TUIObject.Init;
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	Objects := nil;
end;

procedure TContainer.AddObject(Obj: PUIObject);
var
	NewNode, LastNode: PObjectNode;
begin
	Obj^.Parent := @Self; {Set the object's parent to this container}

	New(NewNode);
	NewNode^.ObjectP := Obj;
	NewNode^.Next := nil;

	{If this is the first object, set it as head of the list,
	 otherwise, find the end of the list and add it there}
	if Objects = nil then
		Objects := NewNode
	else
	begin
		LastNode := Objects;
		while LastNode^.Next <> nil do
			LastNode := LastNode^.Next;
		LastNode^.Next := NewNode;
	end;
end;

destructor TContainer.Done;
var
	NextNode: PObjectNode;
begin
	{Dispose of all objects in the linked list}
	while Objects <> nil do
	begin
		NextNode := Objects^.Next;
		Dispose(Objects^.ObjectP, Done); {Call the destructor of the object}
		Dispose(Objects);
		Objects := NextNode;
	end;

	{Call ancestor destructor for properties that aren't specific to TWindow}
	inherited Done;
end;

{----------------------------------------------------------------------------}
{ Window object implementation }
{----------------------------------------------------------------------------}

constructor TWindow.Init(X, Y, W, H: Integer);
const
	DefaultW = 320;
	DefaultH = 175;
begin
	TUIObject.Init;
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	Border  := True;
	DoClose := False;
	OnRun   := nil;
	Objects := nil;
	MenuObj := nil;
	Parent  := nil;
end;

procedure TWindow.Draw;
var
	X1, X2, Y1, Y2: Integer;
begin
	X1 := Left;
	Y1 := Top;
	X2 := X1 + Width;
	Y2 := Y1 + Height;
	if Border then
	begin
		SetFillStyle(SolidFill, Thm.Title);
		Bar(X1 + 2, Y1 + 2, X2 - 2, Y2 - 1);
		SetFillStyle(SolidFill, Thm.Win);
		Bar(X1 + 7, Y1 + 7, X2 - 7, Y2 - 7);
		SetColor(15);
		Line(X1, Y1, X2 - 1, Y1);
		Line(X1, Y1 + 1, X1, Y2 - 1);
		SetColor(0);
		Line(X2, Y1, X2, Y2);
		Line(X1, Y2, X2 - 1, Y2);
		SetColor(Thm.Shadow);
		Line(X2 - 1, Y1 + 1, X2 - 1, Y2 - 1);
		Line(X1 + 1, Y2 - 1, X2 - 2, Y2 - 1);
		SetColor(Thm.Light);
		Line(X1 + 1, Y1 + 1, X2 - 2, Y1 + 1);
		Line(X1 + 1, Y1 + 2, X1 + 1, Y2 - 2);
		SetColor(Thm.Shadow);
		Rectangle(X1 + 5, Y1 + 5, X2 - 5, Y2 - 5);
		SetColor(Thm.Light);
		Rectangle(X1 + 6, Y1 + 6, X2 - 6, Y2 - 6);
	end
	else
	begin
		SetFillStyle(SolidFill, Thm.Win);
		Bar(X1, Y1, X2, Y2);
	end;

	if Assigned(OnDraw) then
		OnDraw(@Self);
end;

procedure TWindow.Run;
var
	CurrObj: PObjectNode;
begin
	if not Assigned(Objects) then
		exit;

	Self.DoClose := False;

	{Draw window and all objects in the window}
	Mouse.Hide;
	Self.Draw;
	CurrObj := Objects;
	repeat
		CurrObj^.ObjectP^.Draw;
		CurrObj := CurrObj^.Next;
	until CurrObj = nil;
	Mouse.Show;

	if Assigned(OnRun) then
		OnRun(@Self);

	while not Self.DoClose do
		Self.CheckEvent;

	if Assigned(OnClose) then
		OnClose(@Self);
end;

procedure TWindow.CheckEvent;
var
	CurrObj: PObjectNode;
begin
	HotkeyInput := GetKey;
	CurrObj := Objects;
	while Assigned(CurrObj) do
	begin
		CurrObj^.ObjectP^.CheckEvent;

		{If the window was closed by an event, exit the loop}
		if Self.DoClose then
			exit;

		CurrObj := CurrObj^.Next;
	end;
end;

procedure TWindow.Close;
begin
	Self.DoClose := True;

	{if Assigned(Parent) then
		Parent^.CloseWindow;} {DEBUG}
end;

{----------------------------------------------------------------------------}
{ Mouse object implementation }
{----------------------------------------------------------------------------}

constructor TMouse.Init;
var
	regs: registers;
begin
	Visible := False;

	{Check for mouse support}
	Intr($33, regs);
	Support := Regs.ax > 0;

	{Get initial mouse position}
	Self.Poll;
end;

function TMouse.Clicked: TMouseButton;
var
	regs: registers;
begin
	if not Support then
	begin
		Clicked := MbNone;
		exit;
	end;

	regs.ax := 3;
	Intr($33, regs);
	Clicked := TMouseButton(regs.bx);
end;

Procedure TMouse.Hide;
Var
	Regs: Registers;
Begin
	{Don't call interrupt if no mouse or already hidden}
	If Not Support Or Not Visible Then
		Exit;
	Regs.ax := 2;
	Intr($33, Regs);
	Visible := False;
End;

procedure TMouse.Poll;
var
	regs: registers;
begin
	if not Support then
		Exit;
	regs.ax := 3;
	Intr($33, regs);
	XPos := regs.cx;
	YPos := regs.dx;
end;

procedure TMouse.Move(Left, Top: Integer);
var
	regs: registers;
begin
	{Can't move mouse if no mouse support}
	if not Support then
		Exit;
	
	if (Left < 0) or (Left > GetMaxX) or 
	   (Top < 0) or (Top > GetMaxY) then
		Exit; {Out of bounds}

	regs.ax := 4;
	regs.cx := Left;
	regs.dx := Top;
	Intr($33, regs);
end;

Procedure TMouse.Show;
Var
	Regs: Registers;
Begin
	{Don't call interrupt if no mouse or already visible}
	If Not Support Then
		Exit;
	Regs.ax := 1;
	Intr($33, Regs);
	Visible := True;
End;

Function TMouse.Supported: Boolean;
Begin
	Supported := Support;
End;

Function TMouse.X: Integer;
Begin
	X := XPos;
End;

Function TMouse.Y: Integer;
Begin
	Y := YPos;
End;

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
	until (Mouse.Clicked = MbNone) and not KeyPressed; {Wait until mouse is released and no keys are pressed}
end;

end.