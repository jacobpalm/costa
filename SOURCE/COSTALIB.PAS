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
	TMouseButton = (mbNone, mbLeft, mbRight, mbBoth);
	TButtonState = (bsUp, bsDown);
	TMsgBoxType  = (msgInfo, msgWarn, msgQuest, msgError);

	PosType = record
		Left, Top, Width, Height: Integer;
	end;

	TUIObject = object
		public
			Pos: PosType;
		private
			procedure SetSize(Left, Top, Width, Height, DefaultWidth, DefaultHight: Integer);
	end;

	TArea = object(TUIObject)
		constructor Init(Left, Top, Width, Height: Integer);
	end;

	ButtonType = object(TUIObject)
		Caption: string;
		Transparent: Boolean;
		State: TButtonState;
		constructor Init(Left, Top, Width, Height: Integer; CaptionS: string);
		procedure Draw;
	end;

	CheckBoxType = object(TUIObject)
		Checked: Boolean;
		constructor Init(Left, Top, Width, Height: Integer);
	end;

	FrameType = object(TUIObject)
		constructor Init(Left, Top, Width, Height: Integer);
	end;

	ImageType = object(TUIObject)
		ImageFile: string[8];
		constructor Init(Left, Top: Integer; Image: string);
	end;

	TextboxType = object(TUIObject)
		MaxLen: Integer;
		constructor Init(Left, Top, Width, Height: Integer);
	end;

	WindowType = object(TUIObject)
		constructor Init(Left, Top, Width, Height: Integer);
	end;

	SettingType = record
		DesktopID: Integer;
		ShowLinkDescriptions: Boolean;
		ShowLinkTargetFiles: Boolean;
		ConfirmLinkDelete: Boolean;
		ConfirmExit: Boolean;
		ThemeFile: string[8];
	end;

	ThemeType = record
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
	MouseVisible: Boolean;
	MouseSupport: Boolean;
	MouseX, MouseY: Integer;
	Setting: SettingType;
	Theme: ThemeType;

function FileExists(const FileName: string): Boolean;
function FontGetWidth(TargetText: String): Integer;
function GetKey: string;
function LowerCase(s: string): string;
function LTrim(s: string): string;
function MouseClicked: TMouseButton;
function MouseInArea(const TargetArea: PosType): Boolean;
function ObjBtnClick(var TargetBtn: ButtonType): Boolean;
function ObjTxtClick(const TargetTxt: TextboxType): Boolean;
function ObjClick(const TargetArea: PosType): Boolean;
function Replace(Input, OldSubStr, NewSubStr: String): String;
function RTrim(s: string): string;
function SysMsgBox(const msgTitle, msgText: string; msgType: TMsgBoxType): Boolean;
Function SysPath: DirStr;
function Timer: Real;
function Trim(s: string): string;
function UpperCase(s: string): string;
procedure ClearKeyBuffer;
procedure FontPrint(Text: string; X, Y, Col: Integer);
procedure MouseHide;
procedure MousePoll;
procedure MouseSetPos(XPos, YPos: Integer);
procedure MouseShow;
procedure ObjChkClick(var TargetChk: CheckBoxType);
procedure ObjDrawChk(var TargetChk: CheckBoxType);
procedure ObjDrawFrm(const TargetFrm: FrameType; LightColor, DarkColor: Integer);
procedure ObjDrawImg(var TargetImg: ImageType);
procedure ObjDrawMenu;
procedure ObjDrawTxt(var TargetTxt: TextboxType; const Text: string; IsEditing: Boolean);
procedure ObjDrawWin(var TargetWin: WindowType);
procedure ObjEditTxt(var TargetTxt: TextboxType; var Text: string);
procedure SoundNote(Frequency, Duration: Integer);
procedure SysAboutBox(const ProgramName, ProgramVersion, ProgramAuthor, IconFile: string);
procedure SysLoad;
procedure SysLoadSettings;
procedure SysLoadTheme(ThemeFile: String);
procedure SysSaveSettings;
procedure SysShowLoading;
function ValidDOSFilename(Filename: string): Boolean;

implementation

const
	GlobalSettings = 'CONFIG\SETTINGS.BIN';

procedure TUIObject.SetSize(Left, Top, Width, Height, DefaultWidth, DefaultHight: Integer);
begin
	if Width = sizeDefault then
		Pos.Width := DefaultWidth
	else
		Pos.Width := Width;

	if Height = sizeDefault then
		Pos.Height := DefaultHight
	else
		Pos.Height := Height;

	if Left = sizeCenter then
		Pos.Left := (GetMaxX - Pos.Width) div 2
	else
		Pos.Left := Left;

	if Top = sizeCenter then
		Pos.Top := (GetMaxY - Pos.Height) div 2 
	else
		Pos.Top := Top;
end;

constructor TArea.Init(Left, Top, Width, Height: Integer);
const
	DefaultWidth = 50;
	DefaultHeight = 50;
begin
	Self.SetSize(Left, Top, Width, Height, DefaultWidth, DefaultHeight);
end;

constructor ButtonType.Init(Left, Top, Width, Height: Integer; CaptionS: string);
const
	DefaultWidth = 92;
	DefaultHeight = 22;
begin
	Self.SetSize(Left, Top, Width, Height, DefaultWidth, DefaultHeight);
	Self.Caption := CaptionS;
	Self.Transparent := False;
end;

procedure ButtonType.Draw;
var
	x1, x2, y1, y2: Integer;
	Color1, Color2, Color3, Color4: Integer;
begin
	x1 := Pos.Left;
	y1 := Pos.Top;
	x2 := x1 + Pos.Width;
	y2 := y1 + Pos.Height;
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
		FontPrint(Caption, x1, y1, Color4);
	end;
end;

constructor CheckBoxType.Init(Left, Top, Width, Height: Integer);
const
	DefaultWidth = 15;
	DefaultHeight = 15;
begin
	Self.SetSize(Left, Top, Width, Height, DefaultWidth, DefaultHeight);
	Self.Checked := False;
end;

constructor FrameType.Init(Left, Top, Width, Height: Integer);
const
	DefaultWidth = 100;
	DefaultHeight = 100;
begin
	Self.SetSize(Left, Top, Width, Height, DefaultWidth, DefaultHeight);
end;

constructor ImageType.Init(Left, Top: Integer; Image: string);
const
	DefaultWidth = 31;
	DefaultHeight = 31;
begin
	Self.SetSize(Left, Top, sizeDefault, sizeDefault, DefaultWidth, DefaultHeight);
	Self.ImageFile := Image;
end;

constructor TextboxType.Init(Left, Top, Width, Height: Integer);
const
	DefaultWidth = 120;
	DefaultHeight = 19;
begin
	Self.SetSize(Left, Top, Width, Height, DefaultWidth, DefaultHeight);
	Self.MaxLen := 255;
end;

constructor WindowType.Init(Left, Top, Width, Height: Integer);
begin
	if Width = sizeDefault then
		Pos.Width := 320
	else
		Pos.Width := Width;
	if Height = sizeDefault then
		Pos.Height := 175
	else
		Pos.Height := Height;

	if Left = sizeCenter then
		Pos.Left := (GetMaxX - Pos.Width) div 2
	else
		Pos.Left := Left;

	if Top = sizeCenter then
		Pos.Top := (GetMaxY - Pos.Height) div 2 
	else
		Pos.Top := Top;
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

procedure FontPrint(Text: string; X, Y, Col: Integer);
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
	SetColor(Col);

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

function LowerCase(s: string): string;
var
	i: Integer;
begin
	for i := 1 to Length(s) do
	begin
		if (s[i] >= 'A') and (s[i] <= 'Z') then
			s[i] := Chr(Ord(s[i]) + 32); (* Convert char to lowercase ASCII *)
	end;
	LowerCase := s;
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

function MouseInArea(const TargetArea: PosType): Boolean;
var
	regs: registers;
begin
	if not MouseSupport then
	begin
		MouseInArea := False;
		Exit;
	end;
	regs.ax := 3;
	Intr($33, regs);
	MouseInArea := (regs.cx >= TargetArea.Left) and (regs.cx <= TargetArea.Left+TargetArea.Width) and
		(regs.dx >= TargetArea.Top) and (regs.dx <= TargetArea.Top+TargetArea.Height);
end;

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

procedure MouseSetPos(XPos, YPos: Integer);
var
	regs: registers;
begin
	if not MouseSupport then Exit;
	regs.ax := 4;
	regs.cx := XPos;
	regs.dx := YPos;
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

function ObjBtnClick(var TargetBtn: ButtonType): Boolean;
begin
	ObjBtnClick := False;
	if (MouseClicked = mbLeft) and MouseInArea(TargetBtn.Pos) then
	begin
		MouseHide;
		TargetBtn.State := bsDown;
		TargetBtn.Draw;
		MouseShow;
		repeat
			if MouseInArea(TargetBtn.Pos) then
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
		if MouseInArea(TargetBtn.Pos) then
			ObjBtnClick := True;
	end;
end;

procedure ObjChkClick(var TargetChk: CheckBoxType);
begin
	if (MouseClicked = mbLeft) and MouseInArea(TargetChk.Pos) then
	begin
		repeat until MouseClicked = mbNone;
		if MouseInArea(TargetChk.Pos) then
		begin
			TargetChk.Checked := not TargetChk.Checked;
			MouseHide;
			ObjDrawChk(TargetChk);
			MouseShow;
		end;
	end;
end;

function ObjClick(const TargetArea: PosType): Boolean;
begin
	ObjClick := false;
	if (MouseClicked = mbLeft) and MouseInArea(TargetArea) then
	begin
		repeat until MouseClicked = mbNone;
		if MouseInArea(TargetArea) then
			ObjClick := true;
	end;
end;

procedure ObjDrawChk(var TargetChk: CheckBoxType);
var
	x1, x2, y1, y2, chkColor: Integer;
begin
	x1 := TargetChk.Pos.Left;
	y1 := TargetChk.Pos.Top;
	x2 := x1 + 15;
	y2 := y1 + 15;
	if TargetChk.Pos.Width = 0 then TargetChk.Pos.Width := 14;
	if TargetChk.Pos.Height = 0 then TargetChk.Pos.Height := 14;
	SetFillStyle(SolidFill, Theme.Textbox);
	Bar(x1+2, y1+2, x2-2, y2-2);
	if Theme.Window = 0 then
		chkColor := 15
	else
		chkColor := 0;
	SetColor(chkColor);
	Rectangle(x1+1, y1+1, x2, y2);
	Line(x2-1, y1+2, x2-1, y2-1);
	Line(x1+2, y2-1, x2-2, y2-1);
	SetColor(Theme.Shadow);
	Line(x1, y1, x1, y2);
	Line(x1+1, y1, x2, y1);
	if TargetChk.Checked then
	begin
		SetColor(Theme.TextboxText);
		Line(x1+5, y1+8, x1+7, y1+10);
		Line(x1+5, y1+9, x1+7, y1+11);
		Line(x1+8, y1+9, x1+11, y1+6);
		Line(x1+8, y1+10, x1+11, y1+7);
		SetColor(Theme.Shadow);
		Line(x1+5, y1+7, x1+7, y1+9);
		Line(x1+8, y1+8, x1+11, y1+5);
		SetColor(Theme.Light);
		Line(x1+5, y1+10, x1+6, y1+11);
		Line(x1+8, y1+11, x1+11, y1+8);
	end;
end;

procedure ObjDrawFrm(const TargetFrm: FrameType; LightColor, DarkColor: Integer);
var
	x1, x2, y1, y2: Integer;
begin
	x1 := TargetFrm.Pos.Left;
	y1 := TargetFrm.Pos.Top;
	x2 := x1 + TargetFrm.Pos.Width;
	y2 := y1 + TargetFrm.Pos.Height;
	SetColor(LightColor);
	Rectangle(x1+1, y1+1, x2, y2);
	SetColor(DarkColor);
	Rectangle(x1, y1, x2-1, y2-1);
end;

procedure ObjDrawImg(var TargetImg: ImageType);
var
	X, Y: Integer;
	ImagePointer: Pointer;
	Size: Word;
	ImageFile: File;
	IconError: Boolean;
	Filename: String;
begin
	IconError := False;
	
	Filename := SysPath + 'ICONS\' + TargetImg.ImageFile + '.BIN';
	if not FileExists(Filename) then
		IconError := True;

	Size := ImageSize(0, 0, 31, 31); {Coords don't matter, just size}
	
	X := TargetImg.Pos.Left;
	Y := TargetImg.Pos.Top;

	{Image border}
	SetColor(Theme.Light);
	Line(X-1, Y-1, X+32, Y-1);
	Line(X-1, Y, X-1, Y+32);
	SetColor(Theme.Shadow);
	Line(X, Y+32, X+32, Y+32);
	Line(X+32, Y, X+32, Y+31);

	{If no image file, draw an empty box}
	if Length(TargetImg.ImageFile) = 0 then
	begin
		SetFillStyle(SolidFill, White);
		Bar(X, Y, X + 31, Y + 31);
		Exit;
	end;

	if not IconError then
	begin
		Assign(ImageFile, Filename);
		{$I-}
		Reset(ImageFile, 1);
		{$I+}
		if (IOResult <> 0) then 
			IconError := True
		else if (FileSize(ImageFile) <> Size) then
			IconError := True;
			
		if IconError then
			Close(ImageFile);
	end;
	{DEBUG - verify getmem and BlockRead}

	if not IconError then
	begin
		GetMem(ImagePointer, Size);
		BlockRead(ImageFile, ImagePointer^, Size);
		Close(ImageFile);
		PutImage(x, y, ImagePointer^, CopyPut);
		FreeMem(ImagePointer, Size);
	end;

	if IconError then
	begin
		SetFillStyle(SolidFill, Red);
		Bar(X, Y, X+31, Y+31);
		FontPrint('IMG', X+5, Y+6, 15);
		FontPrint('ERR', X+5, Y+19, 15);
	end;
end;

procedure ObjDrawMenu;
begin
	SetFillStyle(SolidFill, Theme.Window);
	Bar(0, 0, 639, 26);
	SetColor(Theme.Shadow);
	Line(0, 27, 639, 27);
	SetColor(0);
	Line(0, 28, 639, 28);
end;

procedure ObjDrawTxt(var TargetTxt: TextboxType; const Text: string; IsEditing: Boolean);
var
	x1, x2, y1, y2, MaxShow: Integer;
	S: string;
begin
	x1 := TargetTxt.Pos.Left;
	y1 := TargetTxt.Pos.Top;
	if TargetTxt.Pos.Width = 0 then TargetTxt.Pos.Width := 120;
	if TargetTxt.Pos.Height = 0 then TargetTxt.Pos.Height := 19;
	x2 := x1 + TargetTxt.Pos.Width;
	y2 := y1 + TargetTxt.Pos.Height;
	SetFillStyle(SolidFill, Theme.Textbox);
	Bar(x1+2, y1+2, x2-2, y2-2);
	SetColor(Theme.Light);
	Rectangle(x1, y1, x2-1, y2-1);
	SetColor(Theme.Shadow);
	Rectangle(x1+1, y1+1, x2, y2);
	S := Text;
	if S <> '' then
	begin
		MaxShow := TargetTxt.Pos.Width - 10;
		while FontGetWidth(S) >= MaxShow do
			Delete(S, 1, 1);
		FontPrint(S, x1+5, y1+5, Theme.TextboxText);
	end;
	if IsEditing then
	begin
		x1 := x1 + 7 + FontGetWidth(S);
		Line(x1, y1+4, x1, y1+15);
	end;
end;

procedure ObjDrawWin(var TargetWin: WindowType);
var
	x1, x2, y1, y2: Integer;
begin
	x1 := TargetWin.Pos.Left;
	y1 := TargetWin.Pos.Top;
	x2 := x1 + TargetWin.Pos.Width;
	y2 := y1 + TargetWin.Pos.Height;
	SetFillStyle(SolidFill, Theme.TitleBar);
	Bar(x1+2, y1+2, x2-2, y2-1);
	SetFillStyle(SolidFill, Theme.Window);
	Bar(x1+7, y1+7, x2-7, y2-7);
	SetColor(15);
	Line(x1, y1, x2-1, y1);
	Line(x1, y1+1, x1, y2-1);
	SetColor(0);
	Line(x2, y1, x2, y2);
	Line(x1, y2, x2-1, y2);
	SetColor(Theme.Shadow);
	Line(x2-1, y1+1, x2-1, y2-1);
	Line(x1+1, y2-1, x2-2, y2-1);
	SetColor(Theme.Light);
	Line(x1+1, y1+1, x2-2, y1+1);
	Line(x1+1, y1+2, x1+1, y2-2);
	SetColor(Theme.Shadow);
	Rectangle(x1+5, y1+5, x2-5, y2-5);
	SetColor(Theme.Light);
	Rectangle(x1+6, y1+6, x2-6, y2-6);
end;

procedure ObjEditTxt(var TargetTxt: TextboxType; var Text: string);
var
	OrigTxt, TempTxt, Key: string;
	x1, y1, LineX1, MaxLen, MaxShow: Integer;
	Ch: Char;
begin
	x1 := TargetTxt.Pos.Left + 5;
	y1 := TargetTxt.Pos.Top + 5;
	MaxLen := TargetTxt.MaxLen;
	if MaxLen > 255 then MaxLen := 255;
	MaxShow := TargetTxt.Pos.Width - 10;
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
		ObjDrawTxt(TargetTxt, TempTxt, True);
		MouseShow;
	end;

	{Clear keybuffer}
	while KeyPressed do Ch := ReadKey;

	repeat
		Key := GetKey;

		if (MouseClicked > mbNone) and (not MouseInArea(TargetTxt.Pos)) then
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
								ObjDrawTxt(TargetTxt, TempTxt, True);
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
								FontPrint(TempTxt, x1, y1, Theme.TextboxText);
								LineX1 := x1 + FontGetWidth(TempTxt) + 2;
								SetColor(Theme.TextboxText);
								Line(LineX1, y1 - 1, LineX1, y1 + 10);
							end
							else
							begin
								TempTxt := TempTxt + Key;
								ObjDrawTxt(TargetTxt, TempTxt, True);
							end;
							MouseShow;
						end;
					end;

				27: {Escape}
					begin
						Text := OrigTxt;
						MouseHide;
						ObjDrawTxt(TargetTxt, Text, False);
						MouseShow;
						Exit;
					end;
			end;
		end;
	until False;
end;

function ObjTxtClick(const TargetTxt: TextboxType): Boolean;
begin
	ObjTxtClick := False;
	if (MouseClicked = mbLeft) and MouseInArea(TargetTxt.Pos) then
	begin
		repeat until MouseClicked = mbNone;
		if MouseInArea(TargetTxt.Pos) then
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

procedure SysAboutBox(const ProgramName, ProgramVersion, ProgramAuthor, IconFile: string);
var
	winAboutBox: WindowType;
	btnClose: ButtonType;
	imgLogo: ImageType;
	x1, y1, x2, y2: Integer;
	BackgroundSize: Word;
	BackgroundP: Pointer;
	Key: String;
begin
	winAboutBox.Init(sizeCenter, sizeCenter, 329, 216);
	imgLogo.Init(168, winAboutBox.Pos.Top + 11, IconFile);
	btnClose.Init(274, winAboutBox.Pos.Top + winAboutBox.Pos.Height - 34, sizeDefault, sizeDefault, HotkeySymbol + 'Close');
	MouseHide;

	{Save background to restore when window is closed}
	x1 := winAboutBox.Pos.Left;
	y1 := winAboutBox.Pos.Top;
	x2 := winAboutBox.Pos.Left + winAboutBox.Pos.Width;
	y2 := winAboutBox.Pos.Top + winAboutBox.Pos.Height;
	BackgroundSize := ImageSize(x1, y1, x2, y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(x1, y1, x2, y2, BackgroundP^);

	ObjDrawWin(winAboutBox);
	btnClose.Draw;
	ObjDrawImg(imgLogo);
	FontPrint(ProgramName + ' ' + ProgramVersion, 212, winAboutBox.Pos.Top + 17, Theme.WindowText);
	FontPrint('By ' + ProgramAuthor, 212, winAboutBox.Pos.Top + 31, Theme.WindowText);
	FontPrint('Made with the ' + LibName + ' version', 168, winAboutBox.Pos.Top + 53, Theme.WindowText);
	FontPrint(LibVersion + ' by Jacob Palm, 2004-' + LibYear + '.', 168, winAboutBox.Pos.Top + 67, Theme.WindowText);
	FontPrint('May be freely distributed under the', 168, winAboutBox.Pos.Top + 95, Theme.WindowText);
	FontPrint('terms of the MIT License. More details', 168, winAboutBox.Pos.Top + 109, Theme.WindowText);
	FontPrint('can be found in the LICENSE file.', 168, winAboutBox.Pos.Top + 123, Theme.WindowText);
	FontPrint('More information and news online at:', 168, winAboutBox.Pos.Top + 151, Theme.WindowText);
	FontPrint('https://costa.jacobpalm.dk', 168, winAboutBox.Pos.Top + 165, Theme.WindowText);
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

procedure SysLoad;
var
	regs: registers;
	GraphDriver: Integer;
	GraphMode: Integer;
	ErrorCode: Integer;
begin
	GraphDriver := EGA;
	GraphMode := EGAHI;
	InitGraph(GraphDriver, GraphMode, SysPath);
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

	Intr($33, regs);
	MouseSupport := Regs.ax > 0;

	repeat until MouseClicked = mbNone;
	while KeyPressed do ReadKey;
	MouseShow;
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
	
	if not FileExists(SysPath + GlobalSettings) then
		exit;
	
	Assign(f, SysPath + GlobalSettings);
	{$I-}
	Reset(f, 1);
	{$I+}
	if IOResult <> 0 then
		LoadError := True
	else if FileSize(f) <> SizeOf(SettingType) then
		LoadError := True;

	if LoadError then
	begin
		Close(f);
		exit;
	end;

	BlockRead(f, Setting, SizeOf(SettingType));
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
	ExpectedSize := SizeOf(ThemeType) + 42;

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
		BlockRead(f, Theme, SizeOf(ThemeType));
	Close(f);
end;

function SysMsgBox(const msgTitle, msgText: string; msgType: TMsgBoxType): Boolean;
var
	msgLines: array[1..16] of string;
	msgLineCount, msgTextWidth, i: Integer;
	btnFirst, btnSecond: ButtonType;
	imgIcon: ImageType;
	winMsgBox: WindowType;
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
	winMsgBox.Pos.Width := msgTextWidth + 68;
	if msgType = msgQuest then
	begin
		if winMsgBox.Pos.Width < 194 then winMsgBox.Pos.Width := 194;
	end
	else
	begin
		if winMsgBox.Pos.Width < 102 then winMsgBox.Pos.Width := 102;
	end;
	winMsgBox.Init(sizeCenter, sizeCenter, winMsgBox.Pos.Width, msgLineCount * 15 + 78);
	imgIcon.Init(winMsgBox.Pos.Left + 13, winMsgBox.Pos.Top + 15, '');
	case msgType of
		msgInfo: imgIcon.ImageFile := 'MSGINFO';
		msgWarn: imgIcon.ImageFile := 'MSGWARN';
		msgQuest: imgIcon.ImageFile := 'MSGQUEST';
		msgError: imgIcon.ImageFile := 'MSGERROR';
	end;
	btnFirst.Init(sizeCenter, winMsgBox.Pos.Top + 42 + (15 * msgLineCount), 80, sizeDefault, HotKeySymbol + 'OK');
	if msgType = msgQuest then
	begin
		btnFirst.Caption := HotkeySymbol + 'Yes';
		btnFirst.Pos.Left := 320 - 86;
	end;
	btnSecond.Init(326, btnFirst.Pos.Top, 80, sizeDefault, HotkeySymbol + 'No');

	MouseHide;

	{Save background to restore when window is closed}
	x1 := winMsgBox.Pos.Left;
	y1 := winMsgBox.Pos.Top;
	x2 := winMsgBox.Pos.Left + winMsgBox.Pos.Width;
	y2 := winMsgBox.Pos.Top + winMsgBox.Pos.Height;
	BackgroundSize := ImageSize(x1, y1, x2, y2);
	GetMem(BackgroundP, BackgroundSize);
	GetImage(x1, y1, x2, y2, BackgroundP^);

	ObjDrawWin(winMsgBox);
	btnFirst.Draw;
	if msgType = msgQuest then
		btnSecond.Draw;
	ObjDrawImg(imgIcon);
	FontPrint(msgTitle, winMsgBox.Pos.Left+56, winMsgBox.Pos.Top+15, Theme.WindowText);
	for i := 1 to msgLineCount do
		FontPrint(msgLines[i], winMsgBox.Pos.Left+56, winMsgBox.Pos.Top+17+(15*i), Theme.WindowText);
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
					SysMsgBox := True;
					Break;
				end
				else if (Key = KeyAltN) or (Key = KeyEscape) then
				begin
					SysMsgBox := False;
					Break;
				end;
			end
			else
			begin
				if (Key = KeyEnter) or (Key = KeyEscape) or (Key = KeySpace) or (Key = KeyAltO) then
				begin
					SysMsgBox := True;
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
Function SysPath: DirStr;
Var
	FullPath: PathStr;
	FPath: DirStr;
	FName: NameStr;
	FExt: ExtStr;
Begin
	FullPath := ParamStr(0); { Full path of the executable to be split }
	FSplit(FullPath, FPath, FName, FExt); 
	SysPath := FPath;
End;

procedure SysSaveSettings;
var
	f: file;
	mbVoid: Boolean;
begin
	Assign(f, SysPath + GlobalSettings);
	{$I-}
	Rewrite(f, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		mbVoid := SysMsgBox('Could not save settings',
			'Could not write to the configuration file' + NewLine + 
			GlobalSettings + '.' + NewLine +
			'Verify that the path exists and isn''t read-only.', msgError);
		Close(f);
		Exit;
	end;
	BlockWrite(f, Setting, SizeOf(SettingType));
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

function Trim(s: string): string;
var
	startIdx, endIdx: Integer;
begin
	startIdx := 1;
	{ Find first non-space character }
	while (startIdx <= Length(s)) and (s[startIdx] = ' ') do
		Inc(startIdx);

	endIdx := Length(s);
	{Find last non-space character}
	while (endIdx >= startIdx) and (s[endIdx] = ' ') do
		Dec(endIdx);

	{Copy the trimmed substring}
	Trim := Copy(s, startIdx, endIdx - startIdx + 1);
end;

function LTrim(s: string): string;
var
	startIdx: Integer;
begin
	startIdx := 1;
	while (startIdx <= Length(s)) and (s[startIdx] = ' ') do
		Inc(startIdx);
	LTrim := Copy(s, startIdx, Length(s) - startIdx + 1);
end;

function RTrim(s: string): string;
var
	endIdx: Integer;
begin
	endIdx := Length(s);
	while (endIdx > 0) and (s[endIdx] = ' ') do
		Dec(endIdx);
	RTrim := Copy(s, 1, endIdx);
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

procedure ClearKeyBuffer;
var
	k: char;
begin
	while KeyPressed do
	begin
		k := ReadKey; {Read and discard any keys in the buffer}
	end;
end;

procedure SysShowLoading;
var
	btnLoading: ButtonType;
begin
	btnLoading.Init(sizeCenter, sizeCenter, 110, 34, 'Loading...');
	MouseHide;
	btnLoading.Draw;
	MouseShow;
end;

begin
	SysLoad;
end.