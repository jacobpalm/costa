unit CostaLib;

interface

uses
	Crt, Dos, Graph, Strings, EGADriv;

const
	LibName              = 'Costa UI Library';
	LibVersion           = '2.0';
	LibYear              = '2025';

	SizeRetain           = -255; {Used to retain current width/height on object resize}
	ColorDefault         = 255;  {Used to set default colors on objects}

	DoubleClickDelay     = 0.5;
	PrintLineH           = 12;   {Font dimensions - line height}
	PrintCharW           = 8;    {Width of a single character}

	MenuItemHeight       = 16;   {Height of a menu item in pixels}

	CharArrowUp:    Char = #24;  {Arrows symbols for fonts}
	CharArrowDown:  Char = #25;
	CharArrowRight: Char = #26;
	CharArrowLeft:  Char = #27;
	NewLine:        Char = #13;  {Wrap lines in Print, MsgBox, InputBox etc.}
	HotkeyChr:      Char = #127; {Marks hotkeys in object captions}
	Placeholder          = '%s'; {Placeholder in strings to replace with value}

	DecimalSign          = '.';  {Seperator signs - for localization}
	ThousandsSign        = ',';

	DosInt               = $21;   {MS-DOS API}
	DosFuncGetIntVector  = $35;   {Function: Get Interrupt Vector}

	MouseInt             = $33;   {Mouse drive interrupt}
	MouseFuncResetDriver = $0000; {Function: Reset driver and read status}
	MouseFuncSetHandler  = $000C; {Function: Set Mouse Handler Routine}
	MouseFuncExchSubRout = $0014; {Function: Swap Mouse Handler Routine}
	MbNone               = 0;     {Mouse button states}
	MbLeft               = 1;
	MbRight              = 2;

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
	PMenu        = ^TMenu;
	PMenuItem    = ^TMenuItem;

	{Event procedure type, to ensure all event procedures have the same signature}
	TEventProc   = procedure(Sender: PUIObject);

	{Object states - implemented as a set to be able to store multiple values in one
	 byte, and to allow one Get/Set method to handle multiple boolean properties}
	TState       = (SEnabled, SHidden, SActive, SSelected, STransparent, SBordered, SDirty);
	TStateSet    = set of TState;

	TOrientation = (OrHorizontal, OrVertical, OrBoth); {Orientation for centering objects}
	TAlign       = (AlLeft, AlCenter, AlRight);        {Text alignment}
	TUIPrimitive = (UIBorderUp, UIBorderDown);         {Styles for UI primitives used by all objects}

	{Menu types}
	TMenuStyle   = (MsPopup, MsMenuBar);

	{Linked list of hotkeys, to allow multiple hotkeys per object}
	THotkeyNode = record
		Hotkey: string;      {Hotkey as returned by GetKey}
		Next:   PHotkeyNode; {Pointer to next node in linked list}
	end;

	TKeyPress = string[2];
	TEventType = (evCleared, evClick, evRightClick, evKeyPress, evRedraw, evChange, evTimer);
	PEvent = ^TEvent;
	TEvent = record
		Sender:      PUIObject;
		Event:       TEventType;
		MouseX,
		MouseY,
		MouseButton: Word;
		Key:         TKeyPress;
	end;

	PEventNode = ^TEventNode;
	TEventNode = record
		EventData: PEvent;
		Next:      PEventNode;
	end;

	{Base object which all objects, visual or not, are based on}
	TUIObject = object
		public
			Left,
			Top,
			Width,
			Height:     Integer;     {Position relative to parent, and size}
			Colors:     Word;        {High byte = foreground, low byte = background}
			Hotkey:     PHotKeyNode; {Linked list of hotkeys}
			State:      TStateSet;   {State flags}
			OnClick:    TEventProc;  {Event procedure for mouse click or hotkey press}
			OnDraw:     TEventProc;  {Event procedure called at the end of Draw method, to allow custom drawing etc.}
			ParentObj:  PContainer;  {Parent object, if any}

			constructor Init;
			Destructor  Done; virtual;

			function    HotkeyPressed: boolean;
			function    IsMouseOver: Boolean;
			procedure   CheckEvent; virtual;

			procedure   AddHotkey(Key: string);
			function    GetHotkey: PHotkeyNode;
			procedure   RemoveHotkey(Key: string);

			procedure   SetParent(Parent: PContainer);

			procedure   AddState(S: TState);
			procedure   RemoveState(S: TState);

			procedure   Click;
			procedure   Draw; virtual;

			procedure   SetSize(W, H: Integer);

			procedure   SetPos(X, Y: Integer);
			procedure   GetPos(var X, Y: Integer; Absolute: Boolean);
			procedure   Center(Orientation: TOrientation);

			procedure   SetFGColor(Color: Byte);
			function    GetFGColor: Byte;
			procedure   SetBGColor(Color: Byte);
			function    GetBGColor: Byte;

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
			function    IsContainer: boolean; virtual;
		private
			Objects:    PObjectNode; {Linked list of objects in the container}
	end;

	{Window object}
	TWindow = object(TContainer)
		public
			OnRun:            TEventProc;
			OnClose:          TEventProc;

			constructor Init(X, Y: Integer; Parent: PContainer);
			destructor  Done; virtual;

			procedure   CheckEvent; virtual;
			procedure   Draw; virtual;

			procedure   QueueEvent(Sender: PUIObject; Event: TEventType; MouseX, MouseY, MouseButton: Word; Key: TKeyPress);
			procedure   GetEvent(var Event: TEvent);
			procedure   ClearEventQueue;

			procedure   Run;
			procedure   Close;

			procedure   SaveBackdrop;

			{procedure   SetMenuBar(MenuBar: PMenu);}
		private
			MenuObj:          PMenu;           {Menu bar object, if any}
			DoClose:          Boolean;         {Set to true to close the window by exiting Run loop}
			PreserveBackdrop: Boolean;         {If true, backdrop is preserved when window is drawn and restored when closed}
			BackdropP:        Pointer;         {Stores background image to restore when window is closed}
			BackdropS:        Word;            {Size of memory block used by BackdropP}
			EventQueue:       PEventNode;
			procedure         RestoreBackdrop;
	end;

	{Linked list of windows, to allow multiple windows to be added to an application}
	TWindowNode = record
		ObjectP: PWindow;
		Next:    PWindowNode;
	end;

	{Menu object, placed at the top of a window or displayed as a popup menu}
	TMenu = object(TContainer)
		public
			constructor Init(Style: TMenuStyle; Parent: PContainer);
			destructor  Done; virtual;
			procedure   Draw; virtual;
			procedure   AddMenuItem(Item: PMenuItem);
		private
			MenuStyle:  TMenuStyle;
	end;

	{Menu item object, to be added to a menu}
	TMenuItem = object(TUIObject)
		public
			constructor Init(Cap: string; AsSeperator: Boolean; Parent: PMenu);
			destructor  Done; virtual;
			procedure   CheckEvent; virtual;
			procedure   Draw; virtual;
		private
			Caption:   string;
			Seperator: Boolean;
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
			procedure   SaveSystemSettings;

			procedure   SetConfigFile(Filename: String; Ptr: pointer; MemSize: Integer);
			function    LoadSettings: boolean;
			function    SaveSettings: boolean;

			procedure   LoadTheme(Filename: string);

			procedure   OpenWindow(Win: PWindow);
			procedure   CloseWindow;

			procedure   Run;
			procedure   Terminate;
		private
			Window:     PWindowNode;
			ConfFile:   String[8];   {Filename without extension of apps config file, if any}
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
			PrevMouseHandlerSeg,
			PrevMouseHandlerOfs,
			PrevMouseHandlerMask: Word;
	end;

	{Settings for the library, saved to disk}
	PLibSetting = ^TLibSetting;
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
function  Valid8dot3(Filename: string): Boolean;

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

procedure SoundNote(Frequency, Duration: Integer);
procedure SystemSound(SoundType: TSystemSound);

procedure DrawUIPrimitive(Style: TUIPrimitive; X1, Y1, X2, Y2: Integer; BgColor: Byte; Transparent: Boolean);

implementation

const
	GlobalSettings               = 'CONFIG\SYSTEM.BIN';

	{Message strings}
	MSG_SAVE_SETTING_ERROR_TITLE = 'Error saving settings';
	MSG_SAVE_SETTING_ERROR_TEXT  = 'Could not write to the settings file' + #13 +
	                               '%s.' + #13 +
	                               'Verify that the path exists and isn''t read-only.';
	MSG_GRAPHICS_ERROR           = 'Graphics error:';


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

	mov ax, 3               {Poll mouse state}
	int 33h

	mov Mouse.Clicked, bx  {Save mouse state to variables}
	mov Mouse.X, cx
	mov Mouse.Y, dx

	pop ds                 {Restore DS}
end;

{Used for drawing objects, in order to reduce redundant drawing code and to ensure similarity of objects}
procedure DrawUIPrimitive(Style: TUIPrimitive; X1, Y1, X2, Y2: Integer; BgColor: Byte; Transparent: Boolean);
var
	TLColor1, TLColor2, BRColor1, BRColor2: Byte; {TL = top+left, BR = bottom+right}
begin
	if (Style = UIBorderUp) or (Style = UIBorderDown) then
	begin
		{Interior}
		If Not Transparent Then
		begin
			SetFillStyle(SolidFill, BgColor);
			Bar(X1 + 2, Y1 + 2, X2 - 2, Y2 - 2);
		end;

		{Invert border colors if pressed down}
		if Style = UIBorderUp then
		begin
			{Border is up}
			TLColor1 := White;
			TLColor2 := Thm.Light;
			BRColor1 := Black;
			BRColor2 := Thm.Shadow;
		end
		else
		begin
			{Border is down}
			TLColor1 := Black;
			TLColor2 := Thm.Shadow;
			BRColor1 := White;
			BRColor2 := Thm.Light;
		end;

		{Top + left outer border}
		SetColor(TLColor1);
		Line(X1, Y1, X2, Y1);
		Line(X1, Y1 + 1, X1, Y2);
		{Inner border}
		SetColor(TLColor2);
		Line(X1 + 1, Y1 + 1, X2 - 1, Y1 + 1);
		Line (X1 + 1, Y1 + 2, X1 + 1, Y2 - 1);

		{Bottom + right outer border}
		SetColor(BRColor1);
		Line(X2, Y1 + 1, X2, Y2);
		Line(X1 + 1, Y2, X2 - 1, Y2);
		{Inner border}
		SetColor(BRColor2);
		Line(X2 - 1, Y1 + 2, X2 - 1, Y2 - 1);
		Line(X1 + 2, Y2 - 1, X2 - 2, Y2 - 1);
	end;

end;

{----------------------------------------------------------------------------}
{ Base UI object implementation }
{----------------------------------------------------------------------------}

constructor TUIObject.Init;
begin
	State     := [SEnabled, SDirty];
	Hotkey    := nil;
	OnClick   := nil;
	OnDraw    := nil;
	ParentObj := nil;
	Left      := 0;
	Top       := 0;
	Width     := 0;
	Height    := 0;
	SetFgColor(ColorDefault);
	SetBgColor(ColorDefault);
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

	{If object was visible and has a parent, that parent needs to be redrawn}
	if not (SHidden in State) and (ParentObj <> nil) then
		ParentObj^.AddState(SDirty);
end;

{Check for hotkeys events assigned to the object}
function TUIObject.HotkeyPressed: boolean;
var
	CheckNode: PHotKeyNode;
begin
	HotkeyPressed := False;

	if not (SEnabled in State) or (Length(HotkeyInput) = 0) then
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
	{Get absolute position and size of the object}
	Self.GetPos(X1, Y1, True);
	X2 := X1 + Self.Width;
	Y2 := Y1 + Self.Height;

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

function TUIObject.GetHotkey: PHotkeyNode;
begin
	GetHotkey := Hotkey;
end;

procedure TUIObject.RemoveHotkey(Key: string);
var
	PrevNode, CheckNode: PHotKeyNode;
begin
	if not Assigned(Hotkey) then
		exit; {No hotkeys assigned}

	CheckNode := Hotkey;
	PrevNode := nil;

	{Check if the first node is the one to remove}
	if Hotkey^.HotKey = Key then
	begin
		CheckNode := Hotkey;
		Hotkey := Hotkey^.Next;
		Dispose(CheckNode);
		exit;
	end;

	{Search the linked list for the key to remove}
	while Assigned(CheckNode) do
	begin
		if CheckNode^.HotKey = Key then
		begin
			PrevNode^.Next := CheckNode^.Next;
			Dispose(CheckNode);
			exit;
		end;
		PrevNode := CheckNode;
		CheckNode := CheckNode^.Next;
	end;
end;

procedure TUIObject.AddState(S: TState);
begin
	{Do nothing is state is already there}
	if S in State then
		exit;

	Include(State, S);

	{Any state change should trigger redraw}
	Include(State, SDirty);

	{If state added is SHidden, parent must be redrawn to hide the object}
	if (s = SHidden) and (ParentObj <> nil) then
		ParentObj^.AddState(SDirty);
end;


procedure TUIObject.RemoveState(S: TState);
begin
	{Do nothing if state not present}
	if not (S in State) then
		exit;

	Exclude(State, S);

	{State change should trigger redraw - unless of course SDirty is being cleared because of redraw}
	if s <> SDirty then
		Include(State, SDirty);
end;

{Check for events on object}
procedure TUIObject.CheckEvent;
var
	Clicked: boolean;
begin
	{Don't check for events if object is disabled or hidden}
	if not (SEnabled in State) or (SHidden in State) then
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
		Self.Click;
end;

{Descendants can call this method to trigger OnClick event}
procedure TUIObject.Click;
begin
	if Assigned(OnClick) then
		OnClick(@Self);
end;

{Descandants should implement their own versions with drawing code, but should call
 this version at the end to clear SDirty and trigger any custom drawing code assigned
 to OnDraw}
procedure TUIObject.Draw;
begin
	{Don't draw or trigger event if object is hidden}
	if SHidden in State then
		exit;

	Exclude(State, SDirty);

	if Assigned(OnDraw) then
		OnDraw(@Self);
end;

procedure TUIObject.SetPos(X, Y: Integer);
begin
	if X <> SizeRetain then
		Left := X;
	if Y <> SizeRetain then
		Top := Y;

	Include(State, SDirty);

	{If the object is currently visible, the parent will need to be redrawn or the object will show twice
	 when it is redrawn in new position}
	if not (SHidden in State) and (ParentObj <> nil) then
		ParentObj^.AddState(SDirty);
end;

procedure TUIObject.GetPos(var X, Y: Integer; Absolute: Boolean);
var
	RelX, RelY: Integer;
begin
	X := Left;
	Y := Top;

	if Absolute and Assigned(ParentObj) then
	begin
		ParentObj^.GetPos(RelX, RelY, True);
		X := X + RelX;
		Y := Y + RelY;
	end;
end;

procedure TUIObject.Center(Orientation: TOrientation);
var
	ParentW, ParentH: Integer;
begin
	if not Assigned(ParentObj) then
	begin
		{If no parent, use full screen dimensions}
		ParentW := GetMaxX;
		ParentH := GetMaxY;
	end
	else
	begin
		{Get parent dimensions}
		ParentW := ParentObj^.Width;
		ParentH := ParentObj^.Height;
	end;

	{To center, the size of the object is subtracted from the size of the parent.
	 The remaining space is the additional width the parent has, and dividing this by
	 2 will give the left/top position to center the object. Position is relative to
	 the parent so we don't need to add the parent's position here.}
	if Orientation in [OrHorizontal, OrBoth] then
		Left := (ParentW - Width) div 2;
	if Orientation in [OrVertical, OrBoth] then
		Top := (ParentH - Height) div 2;

	Include(State, SDirty);

	{If the object is currently visible, the parent will need to be redrawn or the object will show twice
	 when it is redrawn in new position}
	if not (SHidden in State) and (ParentObj <> nil) then
		ParentObj^.AddState(SDirty);
end;

procedure TUIObject.SetParent(Parent: PContainer);
begin
	{Debug - test when RemoveObject has been implemented}
	{if Assigned(Parent) then
		Parent^.RemoveObject(@Self);}

	ParentObj := Parent;

	{Add object to its parent, unless Parent passed is nil}
	if Assigned(ParentObj) then
		ParentObj^.AddObject(@Self);
end;


procedure TUIObject.SetSize(W, H: Integer);
begin
	if W <> SizeRetain then
		Width := W;

	if H <> SizeRetain then
		Height := H;

	Include(State, SDirty);

	{If the object is currently visible, the parent will need to be redrawn or the object will be drawn with new size
	 on top of the previous draw}
	if not (SHidden in State) and (ParentObj <> nil) then
		ParentObj^.AddState(SDirty);
end;

procedure TUIObject.SetFGColor(Color: Byte);
begin
	if (Color < 0) or (Color > GetMaxColor) then
		Color := ColorDefault; {Invalid color, use default}

	{Set the high byte of Colors to the foreground color}
	Colors := (Colors and $00FF) or (Color shl 8);

	Include(State, SDirty);
end;

procedure TUIObject.SetBGColor(Color: Byte);
begin
	if (Color < 0) or (Color > GetMaxColor) then
		Color := ColorDefault; {Invalid color, use default}

	{Set the low byte of Colors to the background color}
	Colors := (Colors and $FF00) or Color;

	Include(State, SDirty);
end;

function TUIObject.GetFGColor: Byte;
begin
	{Return the high byte of Colors}
	GetFGColor := (Colors and $FF00) shr 8;
end;

function TUIObject.GetBGColor: Byte;
begin
	{Return the low byte of Colors}
	GetBGColor := Colors and $00FF;
end;

{TContainer overrides this function with one that returns true - used in event/draw loops
 to determine if an object can have children, since Turbo Pascal doesn't have a built-in
 way to determine inheritance at runtime}
function TUIObject.IsContainer: boolean;
begin
	IsContainer := false;
end;

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
{ Menu object implementation }
{----------------------------------------------------------------------------}

constructor TMenu.Init(Style: TMenuStyle; Parent: PContainer);
begin
	Inherited Init(0, 0, Parent);
	SetSize(10, 10); {Will be resized when menu items are added or when added to a window}
	MenuStyle := Style;
end;

procedure TMenu.Draw;
var
	X1, Y1, X2, Y2: Integer;
	BgColor: Byte;
begin
	{Don't draw or trigger event if menu is hidden}
	if SHidden in State then
		exit;

	{Get colors}
	BgColor := GetBGColor;
	if BgColor = ColorDefault then
		BgColor := Thm.Win;

	if MenuStyle = MsPopup then
	begin
		{Interior}
		SetFillStyle(SolidFill, BgColor);
		Bar(X1 + 2, Y1 + 2, X2 - 2, Y2 - 2);
		{Top + left outer border}
		SetColor(White);
		Line(X1, Y1, X2, Y1);
		Line(X1, Y1 + 1, X1, Y2);
		{Inner border}
		SetColor(Thm.Light);
		Line(X1 + 1, Y1 + 1, X2 - 1, Y1 + 1);
		Line (X1 + 1, Y1 + 2, X1 + 1, Y2 - 1);
		{Bottom + right outer border}
		SetColor(Black);
		Line(X2, Y1 + 1, X2, Y2);
		Line(X1 + 1, Y2, X2 - 1, Y2);
		{Inner border}
		SetColor(Thm.Shadow);
		Line(X2 - 1, Y1 + 2, X2 - 1, Y2 - 1);
		Line(X1 + 2, Y2 - 1, X2 - 2, Y2 - 1);
	end
	else
	begin
		{Get absolute position and size of the object}
		GetPos(X1, Y1, True);
		X2 := X1 + Self.Width;
		Y2 := Y1 + Self.Height;

		{Interior}
		SetFillStyle(SolidFill, BgColor);
		Bar(X1, Y1, X2, Y2 - 2);

		{3D border below}
		SetColor(Thm.Shadow);
		Line(X1, Y2 - 1, X2, Y2 - 1);
		SetColor(Black);
		Line(X1, Y2, X2, Y2);
	end;

	DrawChildren; {Draw all menu items}
end;

procedure TMenu.AddMenuItem(Item: PMenuItem);
var
	X, Y, W, H: Integer;
	OffsetX, OffsetY, OffsetW, OffsetH: Integer;
	OffsetNode: PObjectNode;
begin
	OffsetX := 0;
	OffsetY := 0;
	OffsetW := 0;
	OffsetH := 0;

	{Item will be placed after the last existing item, and since items are added
	 to the start of the linked list, the first item in the list is the last added item}
	if Assigned(Objects) then
	begin
		OffsetNode := Objects;
		while Assigned(OffsetNode^.Next) do
			OffsetNode := OffsetNode^.Next;
		OffsetNode^.ObjectP^.GetPos(OffsetX, OffsetY, False);
		OffSetW := OffsetNode^.ObjectP^.Width;
		OffSetH := OffsetNode^.ObjectP^.Height;
		OffsetX := OffsetX + OffsetW + 1;
		OffsetY := OffsetY + OffsetH + 1;
	end;

	if MenuStyle = MsPopup then
	begin
		X := 2;
		Y := OffsetY;
		W := 10; {Width will be set later when menu is show}
	end
	else
	begin
		{Menu bar}
		X := OffsetX;
		Y := 0;
		W := PrintW(Item^.Caption) + 9; {Width based on caption length, plus spacing}
	end;
	H := MenuItemHeight;

	{Set position and size of the new menu item}
	Item^.SetPos(X, Y);
	Item^.SetSize(W, H);

	{Add item to the menu's linked list of objects}
	Item^.SetParent(@Self);
end;

destructor TMenu.Done;
begin
	Inherited Done;
end;

{----------------------------------------------------------------------------}
{ Menu item object implementation }
{----------------------------------------------------------------------------}

constructor TMenuItem.Init(Cap: string; AsSeperator: Boolean; Parent: PMenu);
begin
	Inherited Init;
	Caption   := Cap;
	Seperator := AsSeperator;
	if Assigned(Parent) then
		Parent^.AddMenuItem(@Self);
end;

procedure TMenuItem.CheckEvent;
begin
	{Don't check for events if item is disabled or hidden}
	if not (SEnabled in State) or (SHidden in State) then
		exit;

	{Todo - if menu is a popup menu, only allow interaction when visible}

	if IsMouseOver then
	begin
		{Make sure item is highlighted when mouse is over}
		if not (SActive in State) then
			AddState(SActive);

		if Mouse.Clicked = MbLeft then
		begin
			repeat;	until Mouse.Clicked = MbNone;
			{Check if mouse is still over the item after release}
			if Self.IsMouseOver then
			begin
				RemoveState(SActive);
				Self.Click;
			end;
		end;
	end
	else
	begin
		{If mouse is not over the item, remove highlight}
		if SActive in State then
			RemoveState(SActive);
	end;

	if Self.HotkeyPressed then
		{Trigger OnClick event, if assigned}
		Self.Click;
end;

procedure TMenuItem.Draw;
var
	X1, Y1, X2, Y2: Integer;
	FgColor, BgColor: Byte;
begin
	{Get absolute position and size of the object}
	GetPos(X1, Y1, True);
	X2 := X1 + Width;
	Y2 := Y1 + Height;

	if SActive in State then
	begin
		FGColor := Thm.SelText;
		BgColor := Thm.Sel;
	end
	else
	begin
		{Get colors}
		FgColor := GetFGColor;
		BgColor := GetBGColor;
		{Set default colors if needed}
		if BgColor = ColorDefault then
			BgColor := Thm.Win;
		if FgColor = ColorDefault then
			FgColor := Thm.WinText;
	end;

	{Interior}
	SetFillStyle(SolidFill, BgColor);
	Bar(X1, Y1, X2, Y2 - 2);
	Print(Caption, X1 + 5, Y1 + 3, FgColor);
end;

destructor TMenuItem.Done;
begin
	Inherited Done;
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

	{Retrieve full path of the executable}
	FullPath := ParamStr(0);
	FSplit(FullPath, FPath, FName, FExt);
	ProgramPath := FPath;

	{Initialize EGA 640x350 mode}
	RegisterBGIdriver(@EGAVGADriverProc);
	GraphDriver := EGA;
	GraphMode := EGAHI;
	InitGraph(GraphDriver, GraphMode, '');
	ErrorCode := GraphResult;
	If ErrorCode <> GrOk Then
	Begin
		CloseGraph;
		DosPrint(MSG_GRAPHICS_ERROR);
		DosPrint(GraphErrorMsg(ErrorCode));
		Halt(1);
	End;

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
	{Debug - close windows nicely?}

	If Assigned(OnExit) then
		OnExit(@Self);

	Self.Done; {Call destructor, in case any descendant objects have additional cleanup code}

	CloseGraph;
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

procedure TApplication.LoadSystemSettings;
var
	F: file;
begin

	{Set defaults - will be overwritten if settings file loads successfully}
	FillChar(Setting, SizeOf(TLibSetting), 0);
	Setting.Audio       := False;
	Setting.ThmFile     := 'DEFAULT';

	if not FileExists(Self.Path + GlobalSettings) then
		exit;

	Assign(F, Self.Path + GlobalSettings);
	{$I-}
	Reset(F, 1);
	{$I+}
	if IOResult <> 0 then
		exit;

	if FileSize(F) <> SizeOf(TLibSetting) then
	begin
		Close(F);
		exit;
	end;

	BlockRead(F, Setting, SizeOf(TLibSetting));
	Close(F);
end;

procedure TApplication.SaveSystemSettings;
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
		Exit;
	end;
	BlockWrite(F, Setting, SizeOf(TLibSetting));
	Close(F);
end;

procedure TApplication.SetConfigFile(Filename: String; Ptr: pointer; MemSize: Integer);
begin
	{Input validation - anything off? Then clear everything to be safe}
	if (Length(Filename) > 8) or (Length(FileName) < 1) or
		 (Ptr = nil) or (MemSize < 1) then
	begin
		ConfFile := '';
		ConfPtr := nil;
		ConfLen := 0;
		exit;
	end;

	ConfFile := Filename;
	ConfPtr := Ptr;
	ConfLen := MemSize;
end;

function TApplication.LoadSettings: boolean;
var
	F: file;
	Filename: String;
begin
	{Validate config vars before attempting load}
	if (ConfPtr = nil) or (Length(ConfFile) = 0) or (ConfLen < 1) then
	begin
		LoadSettings := false;
		Exit;
	end;

	Filename := Self.Path + 'CONFIG\' + ConfFile + '.BIN';

	if not FileExists(Filename) then
	begin
		LoadSettings := false;
		Exit;
	end;

	Assign(F, Filename);
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
	Filename: String;
begin
	{Validate config vars before attempting load}
	if (ConfPtr = nil) or (Length(ConfFile) = 0) or (ConfLen < 1) then
	begin
		SaveSettings := false;
		Exit;
	end;

	Filename := Self.Path + 'CONFIG\' + ConfFile + '.BIN';

	Assign(F, Filename);
	{$I-}
	Rewrite(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		{MsgBox(MSG_SAVE_SETTING_ERROR_TITLE, MSG_SAVE_SETTING_ERROR_TEXT, MsgError);}
		{DEBUG - this must be handled alternatively, MsgBox can't be included in the library}
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

constructor TContainer.Init(X, Y: Integer; Parent: PContainer);
const
	DefaultW = 320;
	DefaultH = 175;
begin
	TUIObject.Init;
	Objects := nil;
	SetParent(Parent);
	Self.SetPos(X, Y);
	Self.SetSize(DefaultW, DefaultH);
end;

procedure TContainer.AddObject(Obj: PUIObject);
var
	NewNode, LastNode: PObjectNode;
begin
	if not Assigned(Obj) then
		exit;

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

	{Since object has just been added, a draw is needed}
	Obj^.AddState(SDirty);
end;

procedure TContainer.Draw;
begin
	if SHidden in State then
		exit;

	{TContainer has no visible element, so just draw its children}
	DrawChildren;

	{Call inherited Draw to handle state etc.}
	TUIObject.Draw;
end;

procedure TContainer.CheckEvent;
var
	CurrObj: PObjectNode;
begin
	{Don't check for events if container is disabled or hidden}
	if not (SEnabled in State) or (SHidden in State) then
		exit;

	CurrObj := Objects;
	while Assigned(CurrObj) do
	begin
		CurrObj^.ObjectP^.CheckEvent;
		CurrObj := CurrObj^.Next;
	end;
end;

procedure TContainer.DrawChildren;
var
	CurrObj: PObjectNode;
begin
	{Don't draw if container is hidden or has no objects}
	if (SHidden in State) or not Assigned(Objects) then
		exit;

	{Draw all objects in the linked list}
	CurrObj := Objects;
	CurrObj^.ObjectP^.Draw;
	while Assigned(CurrObj^.Next) do
	begin
		CurrObj := CurrObj^.Next;
		CurrObj^.ObjectP^.Draw;
	end;

	{OnDraw is not triggered by the container, as it is not a visual object -
	 descendants should implement their own Draw method and trigger OnDraw there}
end;

{Any objects in container that have queued a redraw is taken care of in this proc}
procedure TContainer.DrawDirtyObjects;
var
	CurrObj: PObjectNode;
	ContainerObj: PContainer;
	MouseHidden: Boolean;
begin
	{Keep track of mouse state - we don't want it to flicker if nothing is redrawn}
	{DEBUG - maybe only hide mouse if near a redrawn object?}
	MouseHidden := False;

	{If the window itself is dirty, EVERYTHING in it needs redraw - so just call Draw}
	if SDirty in State then
	begin
		Mouse.Hide;
		Self.Draw;
		Mouse.Show;
		Exit;
	end;

	{Window clean, so iterate through Objects in window to find dirty ones}
	CurrObj := Objects;
	while Assigned(CurrObj) do
	begin
		{Draw dirty objects}
		if (SDirty in CurrObj^.ObjectP^.State) and
		    not (SHidden in CurrObj^.ObjectP^.State) then
		begin
			if not MouseHidden then
			begin
				Mouse.Hide;
				MouseHidden := true;
			end;
			CurrObj^.ObjectP^.Draw; {TUIObject.Draw removes dirty state}
		end;

		{If we have descendant containers, trigger DrawDirtyObjects on them too}
		if CurrObj^.ObjectP^.IsContainer then
			PContainer(CurrObj^.ObjectP)^.DrawDirtyObjects;

		CurrObj := CurrObj^.Next;
	end;

	if MouseHidden then
		Mouse.Show;
end;

function TContainer.IsContainer: boolean;
begin
	IsContainer := true;
end;

destructor TContainer.Done;
var
	NextNode: PObjectNode;
	PrevNode, LastNode: PObjectNode;
begin
	{Dispose of all objects in the linked list}
	while Assigned(Objects) do
	begin
		NextNode := Objects^.Next;
		{Call the destructor of the object}
		if Assigned(Objects^.ObjectP) then
			Dispose(Objects^.ObjectP, Done);
		{Dispose of the node}
		Dispose(Objects);
		Objects := NextNode;
	end;

	{Call ancestor destructor for properties that aren't specific to TContainer}
	inherited Done;
end;

{----------------------------------------------------------------------------}
{ Window object implementation }
{----------------------------------------------------------------------------}

constructor TWindow.Init(X, Y: Integer; Parent: PContainer);
const
	DefaultW = 320;
	DefaultH = 175;
begin
	Inherited Init(X, Y, Parent);
	SetSize(DefaultW, DefaultH);
	AddState(SBordered);
	DoClose   := False;
	OnRun     := nil;
	OnClose   := nil;
	MenuObj   := nil;
	BackdropP := nil;
	BackdropS := 0;
	EventQueue := nil;
	PreserveBackdrop := False;
end;

procedure TWindow.Draw;
var
	X1, X2, Y1, Y2: Integer;
	BgColor: Byte;
begin
	{Don't draw or trigger event if window is hidden}
	if SHidden in State then
		exit;

	{Get absolute position and size of the window}
	Self.GetPos(X1, Y1, True);
	X2 := X1 + Width;
	Y2 := Y1 + Height;
	BgColor := GetBGColor;
	if BgColor = ColorDefault then
		BgColor := Thm.Win;

	{If background preservation is enabled, and background hasn't been
	 captured yet, capture it now before drawing anything}
	if PreserveBackdrop and not Assigned(BackdropP) then
	begin
		{DEBUG - out of bounds check}
		{Calculate size of memory block required to store background image}
		BackdropS := ImageSize(X1, Y1, X2, Y2);

		{Allocate memory required to store the background image}
		GetMem(BackdropP, BackdropS);

		{Capture background image}
		GetImage(X1, Y1, X2, Y2, BackdropP^);
	end;

	if SBordered in State then
	begin
		{Draw the window border and interior}
		SetFillStyle(SolidFill, Thm.Title);
		Bar(X1 + 2, Y1 + 2, X2 - 2, Y2 - 1);
		SetFillStyle(SolidFill, BgColor);
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
		{Draw window interior without border}
		SetFillStyle(SolidFill, BgColor);
		Bar(X1, Y1, X2, Y2);
	end;

	{Trigger ondraw event via TUIObject, allowing apps to draw custom background etc. before
	 drawing child objects}
	TUIObject.Draw;
	DrawChildren;
end;

procedure TWindow.QueueEvent(Sender: PUIObject; Event: TEventType; MouseX, MouseY, MouseButton: Word; Key: TKeyPress);
var
	NewEvent: PEvent;
	NewEventNode, CheckEventNode: PEventNode;
begin
	{Create a new event record in memory and assign its data}
	NewEvent := New(PEvent);
	NewEvent^.Sender := Sender;
	NewEvent^.Event := Event;
	NewEvent^.MouseX := MouseX;
	NewEvent^.MouseY := MouseY;
	NewEvent^.MouseButton := MouseButton;
	NewEvent^.Key := Key;

	{Create a new node for the event queue and point it to the event record}
	NewEventNode := New(PEventNode);
	NewEventNode^.EventData := NewEvent;
	NewEventNode^.Next := nil;

	{If there is no queue, set new node as queue}
	if Self.EventQueue = nil then
	begin
		Self.EventQueue := NewEventNode;
		Exit;
	end;

	{If there is an existing queue, iterate through each item until a node with no
	 Next node is found}
	CheckEventNode := Self.EventQueue;
	while Assigned(CheckEventNode^.Next) do
		CheckEventNode := CheckEventNode^.Next;

	{Set Next of last node to the new node}
	CheckEventNode^.Next := NewEventNode;
end;

procedure TWindow.GetEvent(var Event: TEvent);
var
	TempNode: PEventNode;
begin
	if not (Assigned(Self.EventQueue)) then
	begin
		{Debug - this is where to check for user events}
		FillChar(Event, SizeOf(Event), 0);
		Exit;
	end;

	Event := Self.EventQueue^.EventData^;

	{Save event node pointer, and remove it from the queue by setting queue header to next event node}
	TempNode := Self.EventQueue;
	Self.EventQueue := Self.EventQueue^.Next;

	{Dispose of the event itself and the event node that held it}
	Dispose(TempNode^.EventData);
	Dispose(TempNode);
end;

procedure TWindow.ClearEventQueue;
var
	TempNode: PEventNode;
begin
	while Assigned(Self.EventQueue) do
	begin
		TempNode := Self.EventQueue;
		Self.EventQueue := Self.EventQueue^.Next;
		Dispose(TempNode^.EventData);
		Dispose(TempNode);
	end;
end;

procedure TWindow.Run;
var
	CurrObj: PObjectNode;
begin
	Self.DoClose := False;

	{OnRun can be used for initialization code before the window is drawn}
	if Assigned(OnRun) then
		OnRun(@Self);

	{Draw window and all objects in the window}
	Mouse.Hide;
	Self.Draw;
	Mouse.Show;

	while not Self.DoClose and Assigned(Objects) do
	begin
		HotkeyInput := GetKey;
		Self.CheckEvent;
		Self.DrawDirtyObjects;
	end;

	if Assigned(OnClose) then
		OnClose(@Self);

	{Restore background behind window, if it was saved}
	Self.RestoreBackdrop;
end;

procedure TWindow.CheckEvent;
var
	CurrObj: PObjectNode;
begin
	{Don't check for events if window is disabled or hidden}
	if not (SEnabled in State) or (SHidden in State) then
		exit;

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

procedure TWindow.RestoreBackdrop;
var
	X1, Y1: Integer;
begin
	if not Assigned(BackdropP) then
		exit;

	{DEBUG - out of bounds check}
	{Get absolute position of the window}
	Self.GetPos(X1, Y1, True);

	{Restore background}
	Mouse.Hide;
	PutImage(X1, Y1, BackdropP^, NormalPut);
	Mouse.Show;

	{Free memory used to store background image}
	FreeMem(BackdropP, BackdropS);
	BackdropP := nil;
	BackdropS := 0;
end;

procedure TWindow.SaveBackdrop;
begin
	PreserveBackdrop := True;
end;

procedure TWindow.Close;
begin
	Self.DoClose := True;
end;

destructor TWindow.Done;
begin
	if Assigned(BackdropP) then
		FreeMem(BackdropP, BackdropS);

	Self.ClearEventQueue;

	{Call ancestor destructor for properties that aren't specific to TWindow}
	inherited Done;
end;

{----------------------------------------------------------------------------}
{ Mouse object implementation }
{----------------------------------------------------------------------------}

constructor TMouse.Init;
var
	regs: registers;
begin
	Visible := False;
	X := 0;
	Y := 0;
	Clicked := MbNone;
	Support := false;

	{Check that mouse interrupt is assigned. If it isn't, calling it could hang the system}
	regs.ah := DosFuncGetIntVector;
	regs.al := MouseInt;
	Intr(DosInt, regs);
	if (regs.es = 0) or (regs.bx = 0) then
		exit;

	{Mouse interrupt OK, call it and verify that mouse is available}
	regs.ax := MouseFuncResetDriver;
	Intr(MouseInt, regs);
	Support := Regs.ax > 0;
	if not Support then
		exit;

	{If mouse is available, install MouseHandler in the driver so that is is called whenever mouse is moved or clicked
	 We use MouseFuncExchSubRout instead of MouseFuncSetHandler, since this one returns the current values so we Can
	 restore them on exit.}
	Regs.AX := MouseFuncExchSubRout;
	Regs.CX := $FFFF;
	Regs.ES := Seg(MouseHandler);
	Regs.DX := Ofs(MouseHandler);
	Intr(MouseInt, Regs);

	{In case a previous handler was installed before starting appplication, save it to be restored on exit to avoid
	 breaking other apps on the system}
	PrevMouseHandlerMask := Regs.CX;
	PrevMouseHandlerSeg := Regs.ES;
	PrevMouseHandlerOfs := Regs.DX;
end;

procedure TMouse.Hide;
var
	Regs: Registers;
begin
	{Don't call interrupt if no mouse or already hidden}
	If Not Support Or Not Visible Then
		Exit;
	Regs.ax := 2;
	Intr(MouseInt, Regs);
	Visible := False;
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
	Intr(MouseInt, regs);
end;

procedure TMouse.Show;
Var
	Regs: Registers;
Begin
	{Don't call interrupt if no mouse or already visible}
	If Not Support Then
		Exit;
	Regs.ax := 1;
	Intr(MouseInt, Regs);
	Visible := True;
End;

Function TMouse.Supported: Boolean;
Begin
	Supported := Support;
End;

destructor TMouse.Done;
var
	Regs: Registers;
begin
	if not Support then
		exit;

	{Reset mouse driver}
	Regs.AX := MouseFuncResetDriver;
	Intr(MouseInt, Regs);

	{Restore the event handler, if any, that was set before we installed our own handler}
	Regs.AX := MouseFuncSetHandler;  {Set mouse event handler function}
	Regs.CX := PrevMouseHandlerMask;
	Regs.ES := PrevMouseHandlerSeg;
	Regs.DX := PrevMouseHandlerOfs;
	Intr(MouseInt, Regs);
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

procedure SoundNote(Frequency, Duration: Integer);
begin
  Sound(Frequency);
  Delay(Duration);
  NoSound;
end;

procedure SystemSound(SoundType: TSystemSound);
begin
	if not Setting.Audio then
		exit;

	case SoundType of
		sndError:
			begin
				Sound(440);
				Delay(45);
			end;
		sndAttention:
			begin
				Sound(960);
				Delay(25);
			end;
	end;
	NoSound;
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