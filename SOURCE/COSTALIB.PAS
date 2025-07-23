unit CostaLib;

interface

uses
	Crt, Dos, Graph, Strings;

const
	LibName          = 'Costa UI Library';
	LibVersion       = '2.0';
	LibYear          = '2025';

	sizeDefault      = -1;
	sizeCenter       = -2;

	DoubleClickDelay = 0.5;

	CharArrowUp:    Char = #24; {Arrows symbols for fonts}
	CharArrowDown:  Char = #25;
	CharArrowRight: Char = #26;
	CharArrowLeft:  Char = #27;
	NewLine:        Char = #13;  {Wrap lines in msgbox, inputbox etc.}
	HotkeySymbol:   Char = #127; {Marks hotkeys in object captions}

	{$I KEYCODES.INC}

type
	TMouseButton  = (mbNone, mbLeft, mbRight, mbBoth);
	TButtonState  = (bsUp, bsDown);
	TTextboxState = (tsNormal, tsEditing);
	TMsgBoxType   = (msgInfo, msgWarn, msgQuest, msgError);

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
			procedure Draw;
		private
			State: TTextboxState;
	end;

	TWindow = object(TUIObject)
		constructor Init(X, Y, W, H: Integer);
		procedure Draw;
	end;

	TLibSetting = record
		DesktopID: Integer;
		ShowLinkDescriptions: Boolean;
		ShowLinkTargetFiles: Boolean;
		ConfirmLinkDelete: Boolean;
		ConfirmExit: Boolean;
		ThemeFile: string[8];
	end;

	TTheme = record
		Desktop,
		DesktopText,
		Window,
		Button,
		Textbox,
		TextboxText,
		WindowText,
		TitleBar,
		TitleBarText,
		Light,
		Shadow,
		Select,
		SelectText: Integer;
	end;

var
	MenuBar: TMenu;
	Setting: TLibSetting;
	Theme: TTheme;
	MouseVisible: Boolean;
	MouseSupport: Boolean;
	MouseX, MouseY: Integer;

function  ObjBtnClick(var TargetBtn: TButton): Boolean;
function  ObjTxtClick(const TargetTxt: TTextbox): Boolean;
procedure ObjChkClick(var TargetChk: TCheckbox);
function  ObjClick(const TargetObj: TUIObject): Boolean;
procedure ObjEditTxt(var TargetTxt: TTextbox; var Text: string);

function  MsgBox(const msgTitle, msgText: string; msgType: TMsgBoxType): Boolean;
procedure AboutBox(const ProgramName, ProgramVersion, ProgramAuthor, IconFile: string);

function  FileExists(const FileName: string): Boolean;
function  ValidDOSFilename(Filename: string): Boolean;

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
function  FontGetWidth(TargetText: String): Integer;

procedure SoundNote(Frequency, Duration: Integer);

procedure SysLoadSettings;
procedure SysLoadTheme(ThemeFile: String);
procedure SysSaveSettings;
procedure SysShowLoading;

implementation

const
	GlobalSettings = 'CONFIG\SETTINGS.BIN';

procedure TUIObject.SetSize(X, Y, W, H, DefaultW, DefaultH: Integer);
begin
	if W = sizeDefault then
		Width := DefaultW
	else
		Width := W;

	if H = sizeDefault then
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
	x1, y1, x2, y2: Integer;
begin
	MousePoll;
	x1 := Left;
	y1 := Top;
	x2 := x1 + Width;
	y2 := y1 + Height;
	IsMouseOver := (MouseX >= x1) and (MouseX <= x2) and (MouseY >= y1) and (MouseY <= y2);
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
	Self.State := bsUp;
	Self.Transparent := False;
end;

procedure TButton.Draw;
var
	x1, x2, y1, y2: Integer;
	Color1, Color2, Color3, Color4: Integer;
begin
	x1 := Left;
	y1 := Top;
	x2 := x1 + Width;
	y2 := y1 + Height;
	if State = bsUp then
	begin
		Color1 := White;
		Color2 := Theme.Button;
		Color3 := Theme.Shadow;
		Color4 := Theme.WindowText;
	end
	else
	begin
		Color1 := Black;
		Color2 := Theme.Shadow;
		Color3 := Theme.Light;
		Color4 := White;
	end;
	SetColor(Color2);
	if not Transparent then
	begin
		SetFillStyle(SolidFill, Color2);
		Bar(x1, y1, x2-1, y2-1)
	end
	else
		Rectangle(x1, y1, x2-1, y2-1);
	SetColor(Color1);
	Line(x1+1, y1+1, x2-2, y1+1);
	Line(x1+1, y1+2, x1+1, y2-2);
	SetColor(Color3);
	Line(x1, y2, x2, y2);
	Line(x2, y1, x2, y2-1);
	if Caption <> '' then
	begin
		x1 := (x2 - x1) div 2 + x1;
		y1 := (y2 - y1) div 2 + y1 - 3; {3 is the offset to center text vertically}
		x1 := x1 - FontGetWidth(Caption) div 2;
		if State = bsDown then
		begin
			Inc(x1);
			Inc(y1);
		end;
		Print(Caption, x1, y1, Color4);
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
	x1, x2, y1, y2, chkColor: Integer;
begin
	x1 := Left;
	y1 := Top;
	x2 := x1 + 15;
	y2 := y1 + 15;
	if Width = 0 then Width := 14;
	if Height = 0 then Height := 14;
	SetFillStyle(SolidFill, Theme.Textbox);
	Bar(x1 + 2, y1 + 2, x2 - 2, y2 - 2);
	if Theme.Window = 0 then
		chkColor := 15
	else
		chkColor := 0;
	SetColor(chkColor);
	Rectangle(x1 + 1, y1 + 1, x2, y2);
	Line(x2 - 1, y1 + 2, x2 - 1, y2 - 1);
	Line(x1 + 2, y2 - 1, x2 - 2, y2 - 1);
	SetColor(Theme.Shadow);
	Line(x1, y1, x1, y2);
	Line(x1 + 1, y1, x2, y1);
	if Checked then
	begin
		SetColor(Theme.TextboxText);
		Line(x1 + 5, y1 + 8, x1 + 7, y1 + 10);
		Line(x1 + 5, y1 + 9, x1 + 7, y1 + 11);
		Line(x1 + 8, y1 + 9, x1 + 11, y1 + 6);
		Line(x1 + 8, y1 + 10, x1 + 11, y1 + 7);
		SetColor(Theme.Shadow);
		Line(x1 + 5, y1 + 7, x1 + 7, y1 + 9);
		Line(x1 + 8, y1 + 8, x1 + 11, y1 + 5);
		SetColor(Theme.Light);
		Line(x1 + 5, y1 + 10, x1 + 6, y1 + 11);
		Line(x1 + 8, y1 + 11, x1 + 11, y1 + 8);
	end;
end;

constructor TFrame.Init(X, Y, W, H: Integer);
const
	DefaultW = 100;
	DefaultH = 100;
begin
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
	Self.LightColor := 15;
	Self.DarkColor := Theme.Shadow;
end;

procedure TFrame.Draw;
begin
	SetColor(LightColor);
	Rectangle(Left + 1, Top + 1, Left + Width - 1, Top + Height);
	SetColor(DarkColor);
	Rectangle(Left, Top, Left + Width - 1, Top + Height - 1);
end;

constructor TIcon.Init(x, y: Integer; Image: string);
const
	DefaultW = 31;
	DefaultH = 31;
begin
	Self.SetSize(x, y, sizeDefault, sizeDefault, DefaultW, DefaultH);
	Self.ImageFile := Image;
end;

procedure TIcon.Draw;
var
	X, Y: Integer;
	ImagePointer: Pointer;
	Size: Word;
	f: File;
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
	SetColor(Theme.Light);
	Line(X - 1, Y - 1, X + 32, Y - 1);
	Line(X - 1, Y, X - 1, Y + 32);
	SetColor(Theme.Shadow);
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
		Assign(f, Filename);
		{$I-}
		Reset(f, 1);
		{$I+}
		if (IOResult <> 0) then 
			IconError := True
		else if (FileSize(f) <> Size) then
			IconError := True;
			
		if IconError then
			Close(f);
	end;
	{DEBUG - verify getmem and BlockRead}

	if not IconError then
	begin
		GetMem(ImagePointer, Size);
		BlockRead(f, ImagePointer^, Size);
		Close(f);
		PutImage(x, y, ImagePointer^, CopyPut);
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
	SetFillStyle(SolidFill, Theme.Window);
	Bar(Left, Top, Left + Width, Height - 2);

	SetColor(Theme.Shadow);
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
	Self.State := tsNormal;
	Self.Text := '';
end;

procedure TTextbox.Draw;
var
	x1, x2, y1, y2, MaxShow: Integer;
	S: string;
begin
	x1 := Left;
	y1 := Top;
	if Width = 0 then Width := 120;
	if Height = 0 then Height := 19;
	x2 := x1 + Width;
	y2 := y1 + Height;
	SetFillStyle(SolidFill, Theme.Textbox);
	Bar(x1 + 2, y1 + 2, x2 - 2, y2 - 2);
	SetColor(Theme.Light);
	Rectangle(x1, y1, x2 - 1, y2 - 1);
	SetColor(Theme.Shadow);
	Rectangle(x1 + 1, y1 + 1, x2, y2);
	S := Text;
	if S <> '' then
	begin
		MaxShow := Width - 10;
		while FontGetWidth(S) >= MaxShow do
			Delete(S, 1, 1);
		Print(S, x1 + 5, y1 + 5, Theme.TextboxText);
	end;
	if State = tsEditing then
	begin
		x1 := x1 + 7 + FontGetWidth(S);
		Line(x1, y1 + 4, x1, y1 + 15);
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
	x1, x2, y1, y2: Integer;
begin
	x1 := Left;
	y1 := Top;
	x2 := x1 + Width;
	y2 := y1 + Height;
	SetFillStyle(SolidFill, Theme.TitleBar);
	Bar(x1 + 2, y1 + 2, x2 - 2, y2 - 1);
	SetFillStyle(SolidFill, Theme.Window);
	Bar(x1 + 7, y1 + 7, x2 - 7, y2 - 7);
	SetColor(15);
	Line(x1, y1, x2 - 1, y1);
	Line(x1, y1 + 1, x1, y2 - 1);
	SetColor(0);
	Line(x2, y1, x2, y2);
	Line(x1, y2, x2 - 1, y2);
	SetColor(Theme.Shadow);
	Line(x2 - 1, y1 + 1, x2 - 1, y2 - 1);
	Line(x1 + 1, y2 - 1, x2 - 2, y2 - 1);
	SetColor(Theme.Light);
	Line(x1 + 1, y1 + 1, x2 - 2, y1 + 1);
	Line(x1 + 1, y1 + 2, x1 + 1, y2 - 2);
	SetColor(Theme.Shadow);
	Rectangle(x1 + 5, y1 + 5, x2 - 5, y2 - 5);
	SetColor(Theme.Light);
	Rectangle(x1 + 6, y1 + 6, x2 - 6, y2 - 6);
end;

function FileExists(const FileName: string): Boolean;
var
	sResults: SearchRec;
begin
	FindFirst(FileName, Archive, sresults);
	FileExists := (DosError = 0);
end;

function ValidDOSFilename(Filename: string): Boolean;
var
	DotPos, NameLen, ExtLen, i: Integer;
begin
	ValidDOSFilename := false;

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

	ValidDOSFilename := true;
end;

function FontGetWidth(TargetText: String): Integer;
var
	Width: Integer;
begin
	Width := Length(TargetText) * 8; {Each character is 8 pixels wide}

	if Pos(HotkeySymbol, TargetText) > 0 then
		Width := Width - 8; {Don't count the hotkey symbol}

	FontGetWidth := Width;
end;

procedure Print(Text: string; X, Y, Color: Integer);
var
	HotkeyPos, NewLinePos: Integer;
	TextLine: String;

	{Helper procedure - if the text contains a hotkey symbol, remove it
	 and draw an underline under the next character}
	procedure HandleHotkey(X, Y: Integer; var LineStr: String);
	begin
		HotkeyPos := Pos(HotkeySymbol, LineStr);
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
			HotkeyPos := Pos(HotkeySymbol, Text);
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
		MouseClicked := mbNone;
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
	MouseVisible :=True;
End;

function ObjBtnClick(var TargetBtn: TButton): Boolean;
begin
	ObjBtnClick := False;
	if (MouseClicked = mbLeft) and TargetBtn.IsMouseOver then
	begin
		MouseHide;
		TargetBtn.State := bsDown;
		TargetBtn.Draw;
		MouseShow;
		repeat
			if TargetBtn.IsMouseOver then
			begin
				if TargetBtn.State = bsUp then
				begin
					TargetBtn.State := bsDown;
					MouseHide;
					TargetBtn.Draw;
					MouseShow;
				end;
			end
			else
			begin
				if TargetBtn.State = bsDown then
				begin
					TargetBtn.State := bsUp;
					MouseHide;
					TargetBtn.Draw;
					MouseShow;
				end;
			end;
		until MouseClicked = mbNone;
		if TargetBtn.State = bsDown then
		begin
			TargetBtn.State := bsUp;
			MouseHide;
			TargetBtn.Draw;
			MouseShow;
		end;
		if TargetBtn.IsMouseOver then
			ObjBtnClick := True;
	end;
end;

procedure ObjChkClick(var TargetChk: TCheckbox);
begin
	if (MouseClicked = mbLeft) and TargetChk.IsMouseOver then
	begin
		repeat until MouseClicked = mbNone;
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
	if (MouseClicked = mbLeft) and Targetobj.IsMouseOver then
	begin
		repeat until MouseClicked = mbNone;
		if TargetObj.IsMouseOver then
			ObjClick := true;
	end;
end;

procedure ObjEditTxt(var TargetTxt: TTextbox; var Text: string);
var
	OrigTxt, TempTxt, Key: string;
	x1, y1, LineX1, MaxLen, MaxShow: Integer;
	Ch: Char;
begin
	x1 := TargetTxt.Left + 5;
	y1 := TargetTxt.Top + 5;
	MaxLen := TargetTxt.MaxLen;
	if MaxLen > 255 then MaxLen := 255;
	MaxShow := TargetTxt.Width - 10;
	OrigTxt := Text;
	TempTxt := Text;

	if FontGetWidth(TempTxt) + 2 < MaxShow then
	begin
		LineX1 := x1 + FontGetWidth(Text) + 2;
		MouseHide;
		SetColor(Theme.TextboxText);
		Line(LineX1, y1 - 1, LineX1, y1 + 10);
		MouseShow;
	end
	else
	begin
		MouseHide;
		TargetTxt.Draw; {DEBUG - broken}
		MouseShow;
	end;

	{Clear keybuffer}
	while KeyPressed do Ch := ReadKey;

	repeat
		Key := GetKey;

		if (MouseClicked > mbNone) and not TargetTxt.IsMouseOver then
			Key := KeyEnter; {If mouse is clicked outside the textbox, stop editing}
		
		if Length(Key) > 0 then
		begin
			case Ord(Key[1]) of
				8: {Backspace}
					begin
						if Length(TempTxt) > 0 then
						begin
							MouseHide;
							if FontGetWidth(TempTxt) + 2 < MaxShow then
							begin
								{Erase only the last char}
								LineX1 := x1 + FontGetWidth(TempTxt);
								SetFillStyle(SolidFill, Theme.Textbox);
								Bar(LineX1 + 2, y1 - 2, LineX1 - 8, y1 + 11);
								TempTxt := Copy(TempTxt, 1, Length(TempTxt) - 1);
								LineX1 := x1 + FontGetWidth(TempTxt) + 2;
								SetColor(Theme.TextboxText);
								Line(LineX1, y1 - 1, LineX1, y1 + 10);
							end
							else
							begin
								{There's more text that's not shown, so we'll have to redraw the entire textbox}
								TempTxt := Copy(TempTxt, 1, Length(TempTxt) - 1);
								TargetTxt.Draw; {DEBUG - broken}
							end;
							MouseShow;
						end;
					end;

				13: {Enter}
					begin
						Text := TempTxt;
						LineX1 := x1 + FontGetWidth(Text) + 2;
						MouseHide;
						SetColor(Theme.Textbox);
						Line(LineX1, y1 - 1, LineX1, y1 + 10);
						MouseShow;
						Exit;
					end;

				32..126: {Any printable character}
					begin
						if Length(TempTxt) <> MaxLen then
						begin
							MouseHide;
							if FontGetWidth(TempTxt + Key) + 2 < MaxShow then
							begin
								LineX1 := x1 + FontGetWidth(TempTxt) + 2;
								SetColor(Theme.Textbox);
								Line(LineX1, y1 - 1, LineX1, y1 + 10);
								TempTxt := TempTxt + Key;
								Print(TempTxt, x1, y1, Theme.TextboxText);
								LineX1 := x1 + FontGetWidth(TempTxt) + 2;
								SetColor(Theme.TextboxText);
								Line(LineX1, y1 - 1, LineX1, y1 + 10);
							end
							else
							begin
								TempTxt := TempTxt + Key;
								TargetTxt.Draw;
							end;
							MouseShow;
						end;
					end;

				27: {Escape}
					begin
						Text := OrigTxt;
						MouseHide;
						TargetTxt.Draw; {DEBUG - broken}
						MouseShow;
						Exit;
					end;
			end;
		end;
	until False;
end;

function ObjTxtClick(const TargetTxt: TTextbox): Boolean;
begin
	ObjTxtClick := False;
	if (MouseClicked = mbLeft) and TargetTxt.IsMouseOver then
	begin
		repeat until MouseClicked = mbNone;
		if TargetTxt.IsMouseOver then
			ObjTxtClick := True;
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
	winAboutBox: TWindow;
	btnClose: TButton;
	imgLogo: TIcon;
	x1, y1, x2, y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Key: String;
begin
	winAboutBox.Init(sizeCenter, sizeCenter, 329, 216);
	imgLogo.Init(168, winAboutBox.Top + 11, IconFile);
	btnClose.Init(274, winAboutBox.Top + winAboutBox.Height - 34, sizeDefault, sizeDefault, HotkeySymbol + 'Close');
	MouseHide;

	{Save background to restore when window is closed}
	x1 := winAboutBox.Left;
	y1 := winAboutBox.Top;
	x2 := winAboutBox.Left + winAboutBox.Width;
	y2 := winAboutBox.Top + winAboutBox.Height;
	BackgroundSize := ImageSize(x1, y1, x2, y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(x1, y1, x2, y2, BackgroundP^);

	winAboutBox.Draw;
	btnClose.Draw;
	imgLogo.Draw;
	Print(ProgramName + ' ' + ProgramVersion, 212, winAboutBox.Top + 17, Theme.WindowText);
	Print('By ' + ProgramAuthor, 212, winAboutBox.Top + 31, Theme.WindowText);
	Print('Made with the ' + LibName + ' version', 168, winAboutBox.Top + 53, Theme.WindowText);
	Print(LibVersion + ' by Jacob Palm, 2004-' + LibYear + '.', 168, winAboutBox.Top + 67, Theme.WindowText);
	Print('May be freely distributed under the', 168, winAboutBox.Top + 95, Theme.WindowText);
	Print('terms of the MIT License. More details', 168, winAboutBox.Top + 109, Theme.WindowText);
	Print('can be found in the LICENSE file.', 168, winAboutBox.Top + 123, Theme.WindowText);
	Print('More information and news online at:', 168, winAboutBox.Top + 151, Theme.WindowText);
	Print('https://costa.jacobpalm.dk', 168, winAboutBox.Top + 165, Theme.WindowText);
	MouseShow;
	repeat
		Key := GetKey;
		if ObjBtnClick(btnClose) or (Key = KeyEnter) or (Key = KeyEscape) or (Key = KeyAltC) then Break;
	until False;
	MouseHide;
	PutImage(x1, y1, BackgroundP^, NormalPut);
	MouseShow;
	FreeMem(BackgroundP, BackgroundSize);
end;

procedure SysLoadSettings;
var
	f: file;
	LoadError: Boolean;
begin
	LoadError := False;
	
	{Set defaults - will be overwritten if settings file loads successfully}
	Setting.DesktopID := 1;
	Setting.ShowLinkDescriptions := True;
	Setting.ShowLinkTargetFiles := False;
	Setting.ConfirmLinkDelete := True;
	Setting.ConfirmExit := False;
	Setting.ThemeFile := 'DEFAULT';
	
	if not FileExists(ProgramPath + GlobalSettings) then
		exit;
	
	Assign(f, ProgramPath + GlobalSettings);
	{$I-}
	Reset(f, 1);
	{$I+}
	if IOResult <> 0 then
		LoadError := True
	else if FileSize(f) <> SizeOf(TLibSetting) then
		LoadError := True;

	if LoadError then
	begin
		Close(f);
		exit;
	end;

	BlockRead(f, Setting, SizeOf(TLibSetting));
	Close(f);
end;

procedure SysLoadTheme(ThemeFile: String);
var
	f: file;
	ExpectedSize: LongInt;
begin
	{Default colors - will be overwritten if theme file loads successfully}
	Theme.Desktop := Cyan;
	Theme.DesktopText := Black;
	Theme.Window := LightGray;
	Theme.Button := LightGray;
	Theme.Textbox := White;
	Theme.TextboxText := Black;
	Theme.WindowText := Black;
	Theme.TitleBar := Blue;
	Theme.TitleBarText := White;
	Theme.Light := LightGray;
	Theme.Shadow := DarkGray;
	Theme.Select := Blue;
	Theme.SelectText := White;

	{The end of the file contains 21 bytes for theme name, and 21	 for theme
	 author, so the total size should be 40 bytes more than the theme type}
	ExpectedSize := SizeOf(TTheme) + 42;

	if not FileExists('THEMES\' + ThemeFile + '.BIN') then
		exit;

	Assign(f, 'THEMES\' + ThemeFile + '.BIN');
	{$I-}
	Reset(f, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		Close(f);
		Exit;
	end;

	if FileSize(f) = ExpectedSize then
		BlockRead(f, Theme, SizeOf(TTheme));
	Close(f);
end;

function MsgBox(const msgTitle, msgText: string; msgType: TMsgBoxType): Boolean;
var
	msgLines: array[1..16] of string;
	msgLineCount, msgTextWidth, i: Integer;
	btnFirst, btnSecond: TButton;
	imgIcon: TIcon;
	winMsgBox: TWindow;
	S, T: string;
	Key: String;
	P, L: Integer;
	x1, y1, x2, y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
begin
	S := msgText;
	if (S <> '') and (S[Length(S)] = NewLine) then
		Delete(S, Length(S), 1);
	msgLineCount := 0;
	msgTextWidth := 0;
	repeat
		P := Pos(NewLine, S);
		if P = 0 then
		begin
			Inc(msgLineCount);
			msgLines[msgLineCount] := S;
			if FontGetWidth(S) > msgTextWidth then
				msgTextWidth := FontGetWidth(S);
			Break;
		end
		else
		begin
			Inc(msgLineCount);
			msgLines[msgLineCount] := Copy(S, 1, P-1);
			if FontGetWidth(msgLines[msgLineCount]) > msgTextWidth then
				msgTextWidth := FontGetWidth(msgLines[msgLineCount]);
			Delete(S, 1, P);
		end;
	until S = '';
	winMsgBox.Width := msgTextWidth + 68;
	if msgType = msgQuest then
	begin
		if winMsgBox.Width < 194 then winMsgBox.Width := 194;
	end
	else
	begin
		if winMsgBox.Width < 102 then winMsgBox.Width := 102;
	end;
	winMsgBox.Init(sizeCenter, sizeCenter, winMsgBox.Width, msgLineCount * 15 + 78);
	imgIcon.Init(winMsgBox.Left + 13, winMsgBox.Top + 15, '');
	case msgType of
		msgInfo: imgIcon.ImageFile := 'MSGINFO';
		msgWarn: imgIcon.ImageFile := 'MSGWARN';
		msgQuest: imgIcon.ImageFile := 'MSGQUEST';
		msgError: imgIcon.ImageFile := 'MSGERROR';
	end;
	btnFirst.Init(sizeCenter, winMsgBox.Top + 42 + (15 * msgLineCount), 80, sizeDefault, HotKeySymbol + 'OK');
	if msgType = msgQuest then
	begin
		btnFirst.Caption := HotkeySymbol + 'Yes';
		btnFirst.Left := 320 - 86;
	end;
	btnSecond.Init(326, btnFirst.Top, 80, sizeDefault, HotkeySymbol + 'No');

	MouseHide;

	{Save background to restore when window is closed}
	x1 := winMsgBox.Left;
	y1 := winMsgBox.Top;
	x2 := winMsgBox.Left + winMsgBox.Width;
	y2 := winMsgBox.Top + winMsgBox.Height;
	BackgroundSize := ImageSize(x1, y1, x2, y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(x1, y1, x2, y2, BackgroundP^);

	winMsgBox.Draw;
	btnFirst.Draw;
	if msgType = msgQuest then
		btnSecond.Draw;
	imgIcon.Draw;
	Print(msgTitle, winMsgBox.Left+56, winMsgBox.Top+15, Theme.WindowText);
	for i := 1 to msgLineCount do
		Print(msgLines[i], winMsgBox.Left+56, winMsgBox.Top+17+(15*i), Theme.WindowText);
	MouseShow;
	repeat
		Key := GetKey;
			
		if ObjBtnClick(btnFirst) then Key := KeyEnter;
		if msgType = msgQuest then
		begin
			if ObjBtnClick(btnSecond) then Key := KeyEscape;
		end;
		if Key <> '' then
		begin
			if msgType = msgQuest then
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
	PutImage(x1, y1, BackgroundP^, NormalPut);
	FreeMem(BackgroundP, BackgroundSize);
	MouseShow;
end;

{ Returns the path of the application executable }
Function ProgramPath: DirStr;
Var
	FullPath: PathStr;
	FPath: DirStr;
	FName: NameStr;
	FExt: ExtStr;
Begin
	FullPath := ParamStr(0); { Full path of the executable to be split }
	FSplit(FullPath, FPath, FName, FExt); 
	ProgramPath := FPath;
End;

procedure SysSaveSettings;
var
	f: file;
begin
	Assign(f, ProgramPath + GlobalSettings);
	{$I-}
	Rewrite(f, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		MsgBox('Could not save settings',
			'Could not write to the configuration file' + NewLine + 
			GlobalSettings + '.' + NewLine +
			'Verify that the path exists and isn''t read-only.', msgError);
		Close(f);
		Exit;
	end;
	BlockWrite(f, Setting, SizeOf(TLibSetting));
	Close(f);
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
var
	k: char;
begin
	repeat
		if KeyPressed then
			ReadKey;
	until (MouseClicked = mbNone) and not KeyPressed; {Wait until mouse is released and no keys are pressed}
end;

procedure SysShowLoading;
var
	btnLoading: TButton;
begin
	btnLoading.Init(sizeCenter, sizeCenter, 110, 34, 'Loading...');
	MouseHide;
	btnLoading.Draw;
	MouseShow;
end;

var
	regs: registers;
	GraphDriver: Integer;
	GraphMode: Integer;
	ErrorCode: Integer;
begin
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
	SysLoadSettings;
	SysLoadTheme(Setting.ThemeFile);
	if Setting.DesktopID < 1 then Setting.DesktopID := 1;
	if Setting.DesktopID > 5 then Setting.DesktopID := 5;
	MenuBar.Init;

	Intr($33, regs);
	MouseSupport := Regs.ax > 0;

	repeat until MouseClicked = mbNone;
	while KeyPressed do ReadKey;
	MouseShow;
end.