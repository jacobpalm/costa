unit CostaLib;

interface

uses
	Crt, Dos, Graph, Strings;

const
	LibName          = 'Costa UI Library';
	LibVersion       = '2.0';
	LibYear          = '2025';

	SizeDefault      = -1;
	sizeCenter       = -2;

	DoubleClickDelay = 0.5;

	CharArrowUp:    Char = #24; {Arrows symbols for fonts}
	CharArrowDown:  Char = #25;
	CharArrowRight: Char = #26;
	CharArrowLeft:  Char = #27;
	NewLine:        Char = #13;  {Wrap lines in Print, MsgBox, InputBox etc.}
	Hotkey:   Char = #127; {Marks hotkeys in object captions}

	{$I KEYCODES.INC}

type
	TMouseButton  = (MbNone, MbLeft, MbRight, MbBoth);
	TButtonState  = (BsUp, BsDown);
	TTextboxState = (TsNormal, TsEditing);
	TMsgBox       = (MsgInfo, MsgWarn, MsgQuest, MsgError);

	TUIObject = object
		public
			Left, Top, Width, Height: Integer;
			function IsMouseOver: Boolean;
		private
			procedure SetSize(X, Y, W, H, DefaultW, DefaultH: Integer);
	end;

	TArea = object(TUIObject)
		constructor Init(X, Y, W, H: Integer);
	end;

	TButton = object(TUIObject)
		Caption: string;
		Transparent: Boolean;
		State: TButtonState;
		constructor Init(X, Y, W, H: Integer; CaptionS: string);
		procedure Draw;
	end;

	TCheckbox = object(TUIObject)
		Checked: Boolean;
		constructor Init(X, Y, W, H: Integer);
		procedure Draw;
	end;

	TFrame = object(TUIObject)
		LightColor, DarkColor: Integer;
		constructor Init(X, Y, W, H: Integer);
		procedure Draw;
	end;

	TIcon = object(TUIObject)
		ImageFile: string[8];
		constructor Init(X, Y: Integer; Image: string);
		procedure Draw;
	end;

	TMenu = object(TUIObject)
		constructor Init;
		procedure Draw;
	end;

	TTextbox = object(TUIObject)
		public
			MaxLen: Integer;
			Text: string;
			constructor Init(X, Y, W, H: Integer);
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
	MouseVisible: Boolean;
	MouseSupport: Boolean;
	MouseX, MouseY: Integer;

function  BtnClick(var TargetBtn: TButton): Boolean;
function  TxtClick(const TargetTxt: TTextbox): Boolean;
procedure ChkClick(var TargetChk: TCheckbox);
function  ObjClick(const TargetObj: TUIObject): Boolean;

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

function  UpperCase(s: string): string;
function  Replace(Input, OldSubStr, NewSubStr: String): String;

Function  ProgramPath: DirStr;
function  Timer: Real;

procedure Print(Text: string; X, Y, Color: Integer);
function  PrintW(TargetText: String): Integer;

procedure SoundNote(Frequency, Duration: Integer);

procedure SysLoadSettings;
procedure SysSaveSettings;
procedure ShowLoading;

implementation

const
	GlobalSettings = 'CONFIG\SETTINGS.BIN';

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

	if X = sizeCenter then
		Left := (GetMaxX - Width) div 2
	else
		Left := X;

	if Y = sizeCenter then
		Top := (GetMaxY - Height) div 2 
	else
		Top := Y;
end;

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
end;

constructor TButton.Init(X, Y, W, H: Integer; CaptionS: string);
const
	DefaultW = 92;
	DefaultH = 22;
begin
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	Self.Caption := CaptionS;
	Self.State := BsUp;
	Self.Transparent := False;
end;

procedure TButton.Draw;
var
	X1, X2, Y1, Y2: Integer;
	Color1, Color2, Color3, Color4: Integer;
begin
	X1 := Left;
	Y1 := Top;
	X2 := X1 + Width;
	Y2 := Y1 + Height;
	if State = BsUp then
	begin
		Color1 := White;
		Color2 := Thm.Btn;
		Color3 := Thm.Shadow;
		Color4 := Thm.WinText;
	end
	else
	begin
		Color1 := Black;
		Color2 := Thm.Shadow;
		Color3 := Thm.Light;
		Color4 := White;
	end;
	SetColor(Color2);
	if not Transparent then
	begin
		SetFillStyle(SolidFill, Color2);
		Bar(X1, Y1, X2-1, Y2-1)
	end
	else
		Rectangle(X1, Y1, X2-1, Y2-1);
	SetColor(Color1);
	Line(X1+1, Y1+1, X2-2, Y1+1);
	Line(X1+1, Y1+2, X1+1, Y2-2);
	SetColor(Color3);
	Line(X1, Y2, X2, Y2);
	Line(X2, Y1, X2, Y2-1);
	if Caption <> '' then
	begin
		X1 := (X2 - X1) div 2 + X1;
		Y1 := (Y2 - Y1) div 2 + Y1 - 3; {3 is the offset to center text vertically}
		X1 := X1 - PrintW(Caption) div 2;
		if State = BsDown then
		begin
			Inc(X1);
			Inc(Y1);
		end;
		Print(Caption, X1, Y1, Color4);
	end;
end;

constructor TCheckbox.Init(X, Y, W, H: Integer);
const
	DefaultW = 15;
	DefaultH = 15;
begin
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	Self.Checked := False;
end;

procedure TCheckbox.Draw;
var
	X1, X2, Y1, Y2, ChkColor: Integer;
begin
	X1 := Left;
	Y1 := Top;
	X2 := X1 + 15;
	Y2 := Y1 + 15;
	if Width = 0 then Width := 14;
	if Height = 0 then Height := 14;
	SetFillStyle(SolidFill, Thm.Txt);
	Bar(X1 + 2, Y1 + 2, X2 - 2, Y2 - 2);
	if Thm.Win = 0 then
		ChkColor := 15
	else
		ChkColor := 0;
	SetColor(ChkColor);
	Rectangle(X1 + 1, Y1 + 1, X2, Y2);
	Line(X2 - 1, Y1 + 2, X2 - 1, Y2 - 1);
	Line(X1 + 2, Y2 - 1, X2 - 2, Y2 - 1);
	SetColor(Thm.Shadow);
	Line(X1, Y1, X1, Y2);
	Line(X1 + 1, Y1, X2, Y1);
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
end;

constructor TFrame.Init(X, Y, W, H: Integer);
const
	DefaultW = 100;
	DefaultH = 100;
begin
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	Self.LightColor := 15;
	Self.DarkColor := Thm.Shadow;
end;

procedure TFrame.Draw;
begin
	SetColor(LightColor);
	Rectangle(Left + 1, Top + 1, Left + Width - 1, Top + Height);
	SetColor(DarkColor);
	Rectangle(Left, Top, Left + Width - 1, Top + Height - 1);
end;

constructor TIcon.Init(X, Y: Integer; Image: string);
const
	DefaultW = 31;
	DefaultH = 31;
begin
	Self.SetSize(X, Y, SizeDefault, SizeDefault, DefaultW, DefaultH);
	Self.ImageFile := Image;
end;

procedure TIcon.Draw;
var
	X, Y: Integer;
	ImagePointer: Pointer;
	Size: Word;
	F: File;
	IconError: Boolean;
	Filename: String;
begin
	IconError := False;
	
	Filename := ProgramPath + 'ICONS\' + ImageFile + '.BIN';
	if not FileExists(Filename) then
		IconError := True;

	Size := ImageSize(0, 0, 31, 31); {Coords don't matter, just size}
	
	X := Left;
	Y := Top;

	{Image border}
	SetColor(Thm.Light);
	Line(X - 1, Y - 1, X + 32, Y - 1);
	Line(X - 1, Y, X - 1, Y + 32);
	SetColor(Thm.Shadow);
	Line(X, Y + 32, X + 32, Y + 32);
	Line(X + 32, Y, X + 32, Y + 31);

	{If no image file, draw an empty box}
	if Length(ImageFile) = 0 then
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
		GetMem(ImagePointer, Size);
		BlockRead(F, ImagePointer^, Size);
		Close(F);
		PutImage(X, Y, ImagePointer^, CopyPut);
		FreeMem(ImagePointer, Size);
	end;

	if IconError then
	begin
		SetFillStyle(SolidFill, Red);
		Bar(X, Y, X + 31, Y + 31);
		Print('IMG', X + 5, Y + 6, White);
		Print('ERR', X + 5, Y + 19, White);
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
	SetFillStyle(SolidFill, Thm.Win);
	Bar(Left, Top, Left + Width, Height - 2);

	SetColor(Thm.Shadow);
	Line(Top, Top + Height - 1, Left + Width, Top + Height - 1);

	SetColor(Black);
	Line(Top, Top + Height, Left + Width, Top + Height);
end;

constructor TTextbox.Init(X, Y, W, H: Integer);
const
	DefaultW = 120;
	DefaultH = 19;
begin
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	Self.MaxLen := 255;
	Self.State := TsNormal;
	Self.Text := '';
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
	SetFillStyle(SolidFill, Thm.Txt);
	Bar(X1 + 2, Y1 + 2, X2 - 2, Y2 - 2);
	SetColor(Thm.Light);
	Rectangle(X1, Y1, X2 - 1, Y2 - 1);
	SetColor(Thm.Shadow);
	Rectangle(X1 + 1, Y1 + 1, X2, Y2);
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

function PrintW(TargetText: String): Integer;
var
	Width: Integer;
begin
	Width := Length(TargetText) * 8; {Each character is 8 pixels wide}

	if Pos(Hotkey, TargetText) > 0 then
		Width := Width - 8; {Don't count the hotkey symbol}

	PrintW := Width;
end;

procedure Print(Text: string; X, Y, Color: Integer);
var
	HotkeyPos, NewLinePos: Integer;
	TextLine: String;

	{Helper procedure - if the text contains a hotkey symbol, remove it
	 and draw an underline under the next character}
	procedure HandleHotkey(X, Y: Integer; var LineStr: String);
	begin
		HotkeyPos := Pos(Hotkey, LineStr);
		if HotkeyPos > 0 then
		begin
			Delete(LineStr, HotkeyPos, 1);
			Line(X + HotkeyPos * 8 - 9, Y + 9, X + HotkeyPos * 8 - 1, Y + 9);
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
			HotkeyPos := Pos(Hotkey, Text);
			HandleHotkey(X, Y, Text);
			OutTextXY(X, Y, Text);
			break;
		end;
		Y := Y + 12; {Move down one line}
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

function BtnClick(var TargetBtn: TButton): Boolean;
begin
	BtnClick := False;
	if (MouseClicked = MbLeft) and TargetBtn.IsMouseOver then
	begin
		MouseHide;
		TargetBtn.State := BsDown;
		TargetBtn.Draw;
		MouseShow;
		repeat
			if TargetBtn.IsMouseOver then
			begin
				if TargetBtn.State = BsUp then
				begin
					TargetBtn.State := BsDown;
					MouseHide;
					TargetBtn.Draw;
					MouseShow;
				end;
			end
			else
			begin
				if TargetBtn.State = BsDown then
				begin
					TargetBtn.State := BsUp;
					MouseHide;
					TargetBtn.Draw;
					MouseShow;
				end;
			end;
		until MouseClicked = MbNone;
		if TargetBtn.State = BsDown then
		begin
			TargetBtn.State := BsUp;
			MouseHide;
			TargetBtn.Draw;
			MouseShow;
		end;
		if TargetBtn.IsMouseOver then
			BtnClick := True;
	end;
end;

procedure ChkClick(var TargetChk: TCheckbox);
begin
	if (MouseClicked = MbLeft) and TargetChk.IsMouseOver then
	begin
		repeat until MouseClicked = MbNone;
		if TargetChk.IsMouseOver then
		begin
			TargetChk.Checked := not TargetChk.Checked;
			MouseHide;
			TargetChk.Draw;
			MouseShow;
		end;
	end;
end;

function ObjClick(const TargetObj: TUIObject): Boolean;
begin
	ObjClick := false;
	if (MouseClicked = MbLeft) and Targetobj.IsMouseOver then
	begin
		repeat until MouseClicked = MbNone;
		if TargetObj.IsMouseOver then
			ObjClick := true;
	end;
end;

function TxtClick(const TargetTxt: TTextbox): Boolean;
begin
	TxtClick := False;
	if (MouseClicked = MbLeft) and TargetTxt.IsMouseOver then
	begin
		repeat until MouseClicked = MbNone;
		if TargetTxt.IsMouseOver then
			TxtClick := True;
	end;
end;

procedure SoundNote(Frequency, Duration: Integer);
begin
  Sound(Frequency);
  Delay(Duration);
  NoSound;
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
	Key: String;
begin
	WinAboutBox.Init(sizeCenter, sizeCenter, 329, 216);
	ImgLogo.Init(168, WinAboutBox.Top + 11, IconFile);
	BtnClose.Init(274, WinAboutBox.Top + WinAboutBox.Height - 34, SizeDefault, SizeDefault, Hotkey + 'Close');
	MouseHide;

	{Save background to restore when Window is closed}
	X1 := WinAboutBox.Left;
	Y1 := WinAboutBox.Top;
	X2 := WinAboutBox.Left + WinAboutBox.Width;
	Y2 := WinAboutBox.Top + WinAboutBox.Height;
	BackgroundSize := ImageSize(X1, Y1, X2, Y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(X1, Y1, X2, Y2, BackgroundP^);

	WinAboutBox.Draw;
	BtnClose.Draw;
	ImgLogo.Draw;
	Print(ProgramName + ' ' + ProgramVersion, 212, WinAboutBox.Top + 17, Thm.WinText);
	Print('By ' + ProgramAuthor, 212, WinAboutBox.Top + 31, Thm.WinText);
	Print('Made with the ' + LibName + ' version', 168, WinAboutBox.Top + 53, Thm.WinText);
	Print(LibVersion + ' by Jacob Palm, 2004-' + LibYear + '.', 168, WinAboutBox.Top + 67, Thm.WinText);
	Print('May be freely distributed under the', 168, WinAboutBox.Top + 95, Thm.WinText);
	Print('terms of the MIT License. More details', 168, WinAboutBox.Top + 109, Thm.WinText);
	Print('can be found in the LICENSE file.', 168, WinAboutBox.Top + 123, Thm.WinText);
	Print('More information and news online at:', 168, WinAboutBox.Top + 151, Thm.WinText);
	Print('https://costa.jacobpalm.dk', 168, WinAboutBox.Top + 165, Thm.WinText);
	MouseShow;
	repeat
		Key := GetKey;
		if BtnClick(BtnClose) or (Key = KeyEnter) or (Key = KeyEscape) or (Key = KeyAltC) then Break;
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
	MsgLines: array[1..16] of string;
	MsgLinesCount, MsgTextWidth, i: Integer;
	BtnFirst, BtnSecond: TButton;
	ImgIcon: TIcon;
	WinMsgBox: TWindow;
	S, T: string;
	Key: String;
	P, L: Integer;
	X1, Y1, X2, Y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
begin
	S := MsgText;
	if (S <> '') and (S[Length(S)] = NewLine) then
		Delete(S, Length(S), 1);
	MsgLinesCount := 0;
	MsgTextWidth := 0;
	repeat
		P := Pos(NewLine, S);
		if P = 0 then
		begin
			Inc(MsgLinesCount);
			MsgLines[MsgLinesCount] := S;
			if PrintW(S) > MsgTextWidth then
				MsgTextWidth := PrintW(S);
			Break;
		end
		else
		begin
			Inc(MsgLinesCount);
			MsgLines[MsgLinesCount] := Copy(S, 1, P-1);
			if PrintW(MsgLines[MsgLinesCount]) > MsgTextWidth then
				MsgTextWidth := PrintW(MsgLines[MsgLinesCount]);
			Delete(S, 1, P);
		end;
	until S = '';
	WinMsgBox.Width := MsgTextWidth + 68;
	if MsgType = MsgQuest then
	begin
		if WinMsgBox.Width < 194 then WinMsgBox.Width := 194;
	end
	else
	begin
		if WinMsgBox.Width < 102 then WinMsgBox.Width := 102;
	end;
	WinMsgBox.Init(sizeCenter, sizeCenter, WinMsgBox.Width, MsgLinesCount * 15 + 78);
	ImgIcon.Init(WinMsgBox.Left + 13, WinMsgBox.Top + 15, '');
	case MsgType of
		MsgInfo:  ImgIcon.ImageFile := 'MSGINFO';
		MsgWarn:  ImgIcon.ImageFile := 'MSGWARN';
		MsgQuest: ImgIcon.ImageFile := 'MSGQUEST';
		MsgError: ImgIcon.ImageFile := 'MSGERROR';
	end;
	BtnFirst.Init(sizeCenter, WinMsgBox.Top + WinMsgBox.Height - 36, SizeDefault, SizeDefault, Hotkey + 'OK');
	if MsgType = MsgQuest then
	begin
		BtnFirst.Caption := Hotkey + 'Yes';
		BtnFirst.Left := 224;
	end;
	BtnSecond.Init(324, BtnFirst.Top, SizeDefault, SizeDefault, Hotkey + 'No');

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
	for i := 1 to MsgLinesCount do
		Print(MsgLines[i], WinMsgBox.Left+56, WinMsgBox.Top+17+(15*i), Thm.WinText);
	MouseShow;
	repeat
		Key := GetKey;
			
		if BtnClick(BtnFirst) then Key := KeyEnter;
		if MsgType = MsgQuest then
		begin
			if BtnClick(BtnSecond) then Key := KeyEscape;
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
		MsgBox('Could not save settings',
			'Could not write to the configuration file' + NewLine + 
			GlobalSettings + '.' + NewLine +
			'Verify that the path exists and isn''t read-only.', MsgError);
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
	BtnLoading.Init(sizeCenter, sizeCenter, 110, 34, 'Loading...');
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
		Writeln('Graphics error: ', GraphErrorMsg(ErrorCode));
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