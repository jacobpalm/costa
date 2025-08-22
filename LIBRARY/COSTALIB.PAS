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
	TButtonState  = (BsUp, BsDown);
	TTextboxState = (TsNormal, TsEditing);
	TMsgBox       = (MsgInfo, MsgWarn, MsgQuest, MsgError);

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
			procedure AddHotkey(Key: string);
			procedure CheckEvent;
			procedure CheckHotkeys;
			function IsMouseOver: Boolean;
			function Clicked: Boolean;
		private
			Hotkey: PHotKeyNode; {Linked list of hotkeys for object, to allow multiple hotkeys}
			procedure SetSize(X, Y, W, H, DefaultW, DefaultH: Integer);
	end;

	TArea = object(TUIObject)
		Transparent: Boolean;
		BGColor: Integer;
		constructor Init(X, Y, W, H: Integer);
		procedure Draw;
	end;

	TButton = object(TUIObject)
		Caption: string;
		Transparent: Boolean;
		State: TButtonState;
		constructor Init(X, Y, W, H: Integer; Cap: string);
		procedure CheckEvent;
		procedure Draw;
		function Clicked: Boolean;
	end;

	TCheckbox = object(TUIObject)
		Caption: string;
		Checked: Boolean;
		constructor Init(X, Y: Integer; Cap: String);
		procedure Draw;
		procedure Toggle;
	end;

	TFrame = object(TUIObject)
		LightColor,
		DarkColor,
		BGColor: Integer;
		Transparent: Boolean;
		constructor Init(X, Y, W, H: Integer);
		procedure Draw;
	end;

	THotkey = object(TUIObject)
		constructor Init(Key: String);
		procedure CheckEvent;
	end;

	TIcon = object(TUIObject)
		IconFile: string[8];
		constructor Init(X, Y: Integer; Icon: string);
		procedure Draw;
	end;

	TMenu = object(TUIObject)
		constructor Init;
		procedure Draw;
	end;

	TTextbox = object(TUIObject)
		public
			Caption,
			Text: string;
			MaxLen: Integer;
			constructor Init(X, Y, W, H: Integer; Cap: String);
			procedure Edit;
			procedure Draw;
		private
			State: TTextboxState;
	end;

	TWindow = object(TUIObject)
		constructor Init(X, Y, W, H: Integer);
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

function  MsgBox(const MsgTitle, MsgText: string; MsgType: TMsgBox): Boolean;
procedure AboutBox(const ProgramName, ProgramVersion, ProgramAuthor, IconFile: string);

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
procedure ShowLoading;

implementation

const
	GlobalSettings = 'CONFIG\SETTINGS.BIN';

	{Caption strings}
	CAP_LOADING = 'Loading...';
	CAP_OK      = #127 + 'OK';
	CAP_YES     = #127 + 'Yes';
	CAP_NO      = #127 + 'No';
	CAP_CLOSE   = #127 + 'Close';

	{Message strings}
	MSG_BY_TEXT                  = 'By %s';
	MSG_ABOUT_TEXT               = 'Made with the %s version' + #13 +
	                               '%s by Jacob Palm, 2004-%s.' + #13 +
	                               #13 +
	                               'May be freely distributed under the' + #13 +
	                               'terms of the MIT License. More details' + #13 +
	                               'can be found in the LICENSE file.' + #13 +
	                               #13 +
	                               'More information and news online at:' + #13 +
	                               'https://costa.jacobpalm.dk';
	MSG_SAVE_SETTING_ERROR_TITLE = 'Error saving settings';
	MSG_SAVE_SETTING_ERROR_TEXT  = 'Could not write to the settings file' + #13 + 
	                               '%s.' + #13 +
	                               'Verify that the path exists and isn''t read-only.';
	MSG_GRAPHICS_ERROR           = 'Graphics error:';

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
var
	CheckNode: PHotKeyNode;
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


{Detect mouse clicks on object}
function TUIObject.Clicked: Boolean;
begin
	Clicked := False;
	if (MouseClicked = MbLeft) and Self.IsMouseOver then
	begin
		repeat;	until MouseClicked = MbNone;
		Clicked := Self.IsMouseOver;
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

constructor TArea.Init(X, Y, W, H: Integer);
const
	DefaultW = 50;
	DefaultH = 50;
begin
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	BGColor := Thm.Txt;
	Transparent := False;
end;

procedure TArea.Draw;
var
	X1, X2, Y1, Y2: Integer;
	BorderTLColor, BorderBRColor: Byte; {TL = top+left, BR = bottom+right}
begin
	X1 := Left;
	Y1 := Top;
	X2 := X1 + Width;
	Y2 := Y1 + Height;

	{Interior}
	If Not Transparent Then
	Begin
		SetFillStyle(SolidFill, BgColor);
		Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
	End;

	{Top + left border}
	SetColor(Black);
	Line(X1, Y1, X2, Y1);
	Line(X1, Y1 + 1, X1, Y2);
	SetColor(Thm.Shadow);
	Line(X1 + 1, Y1 + 1, X2 - 1, Y1 + 1);
	Line (X1 + 1, Y1 + 2, X1 + 1, Y2 - 1);

	{Bottom + right border}
	SetColor(White);
	Line(X2, Y1 + 1, X2, Y2);
	Line(X1 + 1, Y2, X2 - 1, Y2);
	SetColor(Thm.Light);
	Line(X2 - 1, Y1 + 2, X2 - 1, Y2 - 1);
	Line(X1 + 2, Y2 - 1, X2 - 2, Y2 - 1);
end;

constructor TButton.Init(X, Y, W, H: Integer; Cap: string);
const
	DefaultW = 92;
	DefaultH = 22;
begin
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	Self.Caption := Cap;
	Self.State := BsUp;
	Self.Transparent := False;
end;

procedure TButton.Draw;
var
	X1, X2, Y1, Y2: Integer;
	TLColor1, TLColor2, BRColor1, BRColor2: Byte; {TL = top+left, BR = bottom+right}
begin
	X1 := Left;
	Y1 := Top;
	X2 := X1 + Width;
	Y2 := Y1 + Height;

	{Interior}
	If Not Transparent Then
	Begin
		SetFillStyle(SolidFill, Thm.Btn);
		Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);
	End;
	
	{Invert border colors if pressed down}
	if State = BsUp then
	begin
		TLColor1 := White;
		TLColor2 := Thm.Light;
		BRColor1 := Black;
		BRColor2 := Thm.Shadow;
	end
	else
	begin
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

	if Caption <> '' then
	begin
		X1 := (X2 - X1) div 2 + X1;
		X1 := X1 - PrintW(Caption) div 2;
		Y1 := (Y2 - Y1) div 2 + Y1 - 4; {4 is the offset to center text vertically}
		if State = BsDown then
		begin
			Inc(X1);
			Inc(Y1);
		end;
		Print(Caption, X1, Y1, Thm.WinText);
	end;
end;

function TButton.Clicked: Boolean;
begin
	Clicked := False;
	if (MouseClicked = MbLeft) and Self.IsMouseOver then
	begin
		MouseHide;
		State := BsDown;
		Self.Draw;
		MouseShow;
		repeat
			if Self.IsMouseOver then
			begin
				if State = BsUp then
				begin
					State := BsDown;
					MouseHide;
					Self.Draw;
					MouseShow;
				end;
			end
			else
			begin
				if State = BsDown then
				begin
					State := BsUp;
					MouseHide;
					Self.Draw;
					MouseShow;
				end;
			end;
		until MouseClicked = MbNone;

		if State = BsDown then
		begin
			State := BsUp;
			MouseHide;
			Self.Draw;
			MouseShow;
		end;
		Clicked := Self.IsMouseOver;
	end;
end;

procedure TButton.CheckEvent;
var
	CheckNode: PHotKeyNode;
begin
	{Check for left click, while drawing button pressed while mouse is down and over
	 the button}
	if (MouseClicked = MbLeft) and Self.IsMouseOver then
	begin
		MouseHide;
		State := BsDown;
		Self.Draw;
		MouseShow;
		repeat
			if Self.IsMouseOver then
			begin
				if State = BsUp then
				begin
					State := BsDown;
					MouseHide;
					Self.Draw;
					MouseShow;
				end;
			end
			else
			begin
				if State = BsDown then
				begin
					State := BsUp;
					MouseHide;
					Self.Draw;
					MouseShow;
				end;
			end;
		until MouseClicked = MbNone;

		if State = BsDown then
		begin
			State := BsUp;
			MouseHide;
			Self.Draw;
			MouseShow;
		end;
		if Self.IsMouseOver then
		begin
			{Mouse was both clicked and released over the button, trigger OnClick event}
			if Assigned(OnClick) then
				OnClick(@Self);
			exit;
		end;
	end;

	Self.CheckHotkeys;
end;

constructor TCheckbox.Init(X, Y: Integer; Cap: String);
const
	DefaultW = 15;
	DefaultH = 15;
begin
	Self.SetSize(X, Y, DefaultW, DefaultH, DefaultW, DefaultH);
	Caption := Cap;
	Checked := False;
end;

procedure TCheckbox.Draw;
var
	X1, X2, Y1, Y2, ChkColor: Integer;
begin
	X1 := Left;
	Y1 := Top;
	X2 := X1 + 15;
	Y2 := Y1 + 15;

	{Interior}
	SetFillStyle(SolidFill, Thm.Txt);
	Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);

	{Top + left border}
	SetColor(Black);
	Line(X1, Y1, X2, Y1);
	Line(X1, Y1 + 1, X1, Y2);
	SetColor(Thm.Shadow);
	Line(X1 + 1, Y1 + 1, X2 - 1, Y1 + 1);
	Line (X1 + 1, Y1 + 2, X1 + 1, Y2 - 1);

	{Bottom + right border}
	SetColor(White);
	Line(X2, Y1 + 1, X2, Y2);
	Line(X1 + 1, Y2, X2 - 1, Y2);
	SetColor(Thm.Light);
	Line(X2 - 1, Y1 + 2, X2 - 1, Y2 - 1);
	Line(X1 + 2, Y2 - 1, X2 - 2, Y2 - 1);

	if Checked then
	begin
		SetColor(Thm.TxtText);
		Line(X1 + 5, Y1 + 8, X1 + 7, Y1 + 10);
		Line(X1 + 5, Y1 + 9, X1 + 7, Y1 + 11);
		Line(X1 + 8, Y1 + 9, X1 + 11, Y1 + 6);
		Line(X1 + 8, Y1 + 10, X1 + 11, Y1 + 7);
		SetColor(Thm.Shadow);
		Line(X1 + 5, Y1 + 7, X1 + 7, Y1 + 9);
		Line(X1 + 8, Y1 + 8, X1 + 11, Y1 + 5);
		SetColor(Thm.Light);
		Line(X1 + 5, Y1 + 10, X1 + 6, Y1 + 11);
		Line(X1 + 8, Y1 + 11, X1 + 11, Y1 + 8);
	end;
	if Length(Caption) > 0 then
		Print (Caption, X1 + 22, Y1 + 4, Thm.WinText);
end;

procedure TCheckbox.Toggle;
begin
	Checked := not Checked;
	MouseHide;
	Self.Draw;
	MouseShow;
end;

constructor TFrame.Init(X, Y, W, H: Integer);
const
	DefaultW = 100;
	DefaultH = 100;
begin
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	LightColor := Thm.Light;
	DarkColor := Thm.Shadow;
	BGColor := Thm.Win;
	Transparent := True;
end;

procedure TFrame.Draw;
begin
	{Interior}
	if not Transparent then
	begin
		SetFillStyle(SolidFill, BGColor);
		Bar(Left + 2, Top + 2, Left + Width - 2, Top + Height - 2);
	end;

	{Borders}
	SetColor(LightColor);
	Rectangle(Left + 1, Top + 1, Left + Width - 1, Top + Height);
	SetColor(DarkColor);
	Rectangle(Left, Top, Left + Width - 1, Top + Height - 1);
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

constructor TIcon.Init(X, Y: Integer; Icon: string);
const
	DefaultW = 31;
	DefaultH = 31;
begin
	Self.SetSize(X, Y, SizeDefault, SizeDefault, DefaultW, DefaultH);
	IconFile := Icon;
end;

procedure TIcon.Draw;
var
	X, Y: Integer;
	IconPointer: Pointer;
	Size: Word;
	F: File;
	IconError: Boolean;
	Filename: String;
begin
	IconError := False;
	
	Filename := ProgramPath + 'ICONS\' + IconFile + '.BIN';
	if not FileExists(Filename) then
		IconError := True;

	Size := ImageSize(0, 0, 31, 31); {Coords don't matter, just size}
	
	X := Left;
	Y := Top;

	{Icon border}
	SetColor(Thm.Light);
	Line(X - 1, Y - 1, X + 32, Y - 1);
	Line(X - 1, Y, X - 1, Y + 32);
	SetColor(Thm.Shadow);
	Line(X, Y + 32, X + 32, Y + 32);
	Line(X + 32, Y, X + 32, Y + 31);

	{If no Icon file, draw an empty box}
	if Length(IconFile) = 0 then
	begin
		SetFillStyle(SolidFill, White);
		Bar(X, Y, X + 31, Y + 31);
		Exit;
	end;

	if not IconError then
	begin
		Assign(F, Filename);
		{$I-}
		Reset(F, 1);
		{$I+}
		if (IOResult <> 0) then 
			IconError := True
		else if (FileSize(F) <> Size) then
			IconError := True;
			
		if IconError then
			Close(F);
	end;
	{DEBUG - verify getmem and BlockRead}

	if not IconError then
	begin
		GetMem(IconPointer, Size);
		BlockRead(F, IconPointer^, Size);
		Close(F);
		PutImage(X, Y, IconPointer^, CopyPut);
		FreeMem(IconPointer, Size);
	end;

	if IconError then
	begin
		SetFillStyle(SolidFill, Red);
		Bar(X, Y, X + 31, Y + 31);
		Print('IMG' + #13 + 'ERR', X + 5, Y + 6, White);
	end;
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

constructor TTextbox.Init(X, Y, W, H: Integer; Cap: String);
const
	DefaultW = 120;
	DefaultH = 19;
begin
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	Caption := Cap;
	MaxLen := 255;
	State := TsNormal;
	Text := '';
end;

procedure TTextbox.Edit;
var
	OrigTxt, Key: string;
	X1, Y1, CursorX, MaxShow: integer;
begin
	X1 := Left + 5;
	Y1 := Top + 5;
	if MaxLen > 255 then MaxLen := 255;
	MaxShow := Width - 10;
	OrigTxt := Text;

	{Redraw the textbox to show the editing state}
	MouseHide;
	State := TsEditing;
	Self.Draw;
	MouseShow;

	ClearInputBuffer;
	repeat
		Key := GetKey;

		{If mouse is clicked outside the textbox, stop editing}
		if (MouseClicked > MbNone) and not Self.IsMouseOver then
			break;
		
		if Key = KeyBackspace then
		begin
			if Length(Text) > 0 then
			begin
				MouseHide;
				if PrintW(Text) + 2 < MaxShow then
				begin
					{Erase only the last char}
					CursorX := X1 + PrintW(Text);
					SetFillStyle(SolidFill, Thm.Txt);
					Bar(CursorX + 2, Y1 - 2, CursorX - 8, Y1 + 11);
					Text := Copy(Text, 1, Length(Text) - 1);
					CursorX := X1 + PrintW(Text) + 2;
					SetColor(Thm.TxtText);
					Line(CursorX, Y1 - 1, CursorX, Y1 + 10);
				end
				else
				begin
					{There's more text that's not shown, so we'll have to redraw the entire textbox}
					Text := Copy(Text, 1, Length(Text) - 1);
					Self.Draw;
				end;
				MouseShow;
			end;
		end;

		If Key = KeyEnter then
			break;

		if Key = KeyEscape then
		begin
			Text := OrigTxt;
			State := TsNormal;
			MouseHide;
			Self.Draw;
			MouseShow;
			exit;
		end;

		{Any printable character}
		if (Length(Key) = 1) and (Length(Text) < MaxLen) then
		begin
			if (Ord(Key[1]) < 32) or (Ord(Key[1]) > 126) then
				continue;

			MouseHide;
			if PrintW(Text + Key) + 2 < MaxShow then
			begin
				CursorX := X1 + PrintW(Text) + 2;
				SetColor(Thm.Txt);
				Line(CursorX, Y1 - 1, CursorX, Y1 + 10);
				Text := Text + Key;
				Print(Text, X1, Y1, Thm.TxtText);
				CursorX := X1 + PrintW(Text) + 2;
				SetColor(Thm.TxtText);
				Line(CursorX, Y1 - 1, CursorX, Y1 + 10);
			end
			else
			begin
				Text := Text + Key;
				Self.Draw;
			end;
			MouseShow;
		end;

	until False;

	State := TsNormal;
	MouseHide;
	if PrintW(Text) + 2 < MaxShow then
	begin
		{Erase only the cursor}
		CursorX := X1 + PrintW(Text) + 2;
		SetColor(Thm.Txt);
		Line(CursorX, Y1 - 1, CursorX, Y1 + 10);
	end
	else
		{There's more text than fits, so we'll have to redraw the entire textbox}
		Self.Draw;
	MouseShow;
	ClearInputBuffer;
end;

procedure TTextbox.Draw;
var
	X1, X2, Y1, Y2, MaxShow: Integer;
	S: string;
begin
	X1 := Left;
	Y1 := Top;
	X2 := X1 + Width;
	Y2 := Y1 + Height;

	{Interior}
	SetFillStyle(SolidFill, Thm.Txt);
	Bar(X1 + 1, Y1 + 1, X2 - 1, Y2 - 1);

	{Top + left border}
	SetColor(Thm.Shadow);
	Line(X1, Y1, X2, Y1);
	Line(X1, Y1 + 1, X1, Y2);
	SetColor(Black);
	Line(X1 + 1, Y1 + 1, X2 - 1, Y1 + 1);
	Line (X1 + 1, Y1 + 2, X1 + 1, Y2 - 1);

	{Bottom + right border}
	SetColor(White);
	Line(X2, Y1 + 1, X2, Y2);
	Line(X1 + 1, Y2, X2 - 1, Y2);
	SetColor(Thm.Light);
	Line(X2 - 1, Y1 + 2, X2 - 1, Y2 - 1);
	Line(X1 + 2, Y2 - 1, X2 - 2, Y2 - 1);

	{Draw caption if set}
	if Length(Caption) > 0 then
	Print(Caption, X1, Y1 - 15, Thm.WinText);

	{Draw text inside the textbox}
	S := Text;
	if S <> '' then
	begin
		MaxShow := Width - 10;
		while PrintW(S) >= MaxShow do
			Delete(S, 1, 1);
		Print(S, X1 + 5, Y1 + 5, Thm.TxtText);
	end;
	if State = TsEditing then
	begin
		X1 := X1 + 7 + PrintW(S);
		Line(X1, Y1 + 4, X1, Y1 + 15);
	end;
end;

constructor TWindow.Init(X, Y, W, H: Integer);
const
	DefaultW = 320;
	DefaultH = 175;
begin
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
end;

procedure TWindow.Draw;
var
	X1, X2, Y1, Y2: Integer;
begin
	X1 := Left;
	Y1 := Top;
	X2 := X1 + Width;
	Y2 := Y1 + Height;
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

procedure AboutBox(const ProgramName, ProgramVersion, ProgramAuthor, IconFile: string);
var
	WinAboutBox: TWindow;
	BtnClose: TButton;
	ImgLogo: TIcon;
	X1, Y1, X2, Y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Text, Key: String;
begin
	Text := ReplaceMsg(MSG_ABOUT_TEXT, LibName);
	Text := ReplaceMsg(Text, LibVersion);
	Text := ReplaceMsg(Text, LibYear);

	WinAboutBox.Init(sizeCenter, sizeCenter, PrintW(Text) + 29, PrintH(Text) + 95);
	X1 := WinAboutBox.Left;
	Y1 := WinAboutBox.Top;
	X2 := WinAboutBox.Left + WinAboutBox.Width;
	Y2 := WinAboutBox.Top + WinAboutBox.Height;
	ImgLogo.Init(X1 + 13, Y1 + 15, IconFile);
	BtnClose.Init(SizeCenter, Y2 - 34, SizeDefault, SizeDefault, CAP_CLOSE);
	MouseHide;

	{Save background to restore when Window is closed}
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);

	WinAboutBox.Draw;
	BtnClose.Draw;
	ImgLogo.Draw;
	Print(ProgramName + ' ' + ProgramVersion, X1 + 56, Y1 + 21, Thm.WinText);
	Print(ReplaceMsg(MSG_BY_TEXT, ProgramAuthor), X1 + 56, Y1 + 33, Thm.WinText);
	
	Print(Text, X1 + 15, Y1 + 53, Thm.WinText);
	
	MouseShow;
	repeat
		Key := GetKey;
		if BtnClose.Clicked or (Key = KeyEnter) or (Key = KeyEscape) or (Key = KeyAltC) then Break;
	until False;
	MouseHide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	MouseShow;
	FreeMem(BackgroundP, BackgroundSize);
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

function MsgBox(const MsgTitle, MsgText: string; MsgType: TMsgBox): Boolean;
var
	WinMsgBox: TWindow;
	BtnFirst, BtnSecond: TButton;
	ImgIcon: TIcon;
	BoxW, BoxH: Integer;
	X1, Y1, X2, Y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Key: String;
begin
	BoxW := PrintW(MsgText) + 68;
	BoxH := PrintH(MsgText) + 78;
	if BoxW < 270 then
		BoxW := 270;

	WinMsgBox.Init(sizeCenter, sizeCenter, BoxW, BoxH);
	ImgIcon.Init(WinMsgBox.Left + 13, WinMsgBox.Top + 15, '');
	case MsgType of
		MsgInfo:  ImgIcon.IconFile := 'MSGINFO';
		MsgWarn:  ImgIcon.IconFile := 'MSGWARN';
		MsgQuest: ImgIcon.IconFile := 'MSGQUEST';
		MsgError: ImgIcon.IconFile := 'MSGERROR';
	end;
	BtnFirst.Init(sizeCenter, WinMsgBox.Top + WinMsgBox.Height - 36, SizeDefault, SizeDefault, CAP_OK);
	if MsgType = MsgQuest then
	begin
		BtnFirst.Caption := CAP_YES;
		BtnFirst.Left := 224;
	end;
	BtnSecond.Init(324, BtnFirst.Top, SizeDefault, SizeDefault, CAP_NO);

	MouseHide;

	{Save background to restore when Window is closed}
	X1 := WinMsgBox.Left;
	Y1 := WinMsgBox.Top;
	X2 := WinMsgBox.Left + WinMsgBox.Width;
	Y2 := WinMsgBox.Top + WinMsgBox.Height;
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);

	WinMsgBox.Draw;
	BtnFirst.Draw;
	if MsgType = MsgQuest then
		BtnSecond.Draw;
	ImgIcon.Draw;
	Print(MsgTitle, WinMsgBox.Left+56, WinMsgBox.Top+15, Thm.WinText);
	Print(MsgText, WinMsgBox.Left+56, WinMsgBox.Top+31, Thm.WinText);
	MouseShow;

	repeat
		Key := GetKey;
			
		if BtnFirst.Clicked then Key := KeyEnter;
		if MsgType = MsgQuest then
		begin
			if BtnSecond.Clicked then Key := KeyEscape;
		end;
		if Key <> '' then
		begin
			if MsgType = MsgQuest then
			begin
				if (Key = KeyAltY) or (Key = KeyEnter) then
				begin
					MsgBox := True;
					Break;
				end
				else if (Key = KeyAltN) or (Key = KeyEscape) then
				begin
					MsgBox := False;
					Break;
				end;
			end
			else
			begin
				if (Key = KeyEnter) or (Key = KeyEscape) or (Key = KeySpace) or (Key = KeyAltO) then
				begin
					MsgBox := True;
					Break;
				end;
			end;
		end;
	until False;
	MouseHide;
	PutImage(X1, Y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;
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
		MsgBox(MSG_SAVE_SETTING_ERROR_TITLE, MSG_SAVE_SETTING_ERROR_TEXT, MsgError);
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

procedure ShowLoading;
var
	BtnLoading: TButton;
begin
	BtnLoading.Init(sizeCenter, sizeCenter, 110, 34, CAP_LOADING);
	MouseHide;
	BtnLoading.Draw;
	MouseShow;
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