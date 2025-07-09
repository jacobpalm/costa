unit CostaLib;

interface

uses
  Crt, Dos, Graph, Strings;

const
  FontHeading  = 1;
  FontNormal   = 2;

  sizeDefault  = -1;
  sizeRetain   = -2;
  sizeCenter   = -3;

  DoubleClickDelay = 0.5;

  CharArrowUp:    Char = #24;  {Arrows symbols for fonts}
  CharArrowDown:  Char = #25;
  CharArrowRight: Char = #26;
  CharArrowLeft:  Char = #27;
  NewLine:        Char = #13;  {Wrap lines in msgbox, inputbox etc.}
  HotkeySymbol:   Char = #127; {Marks hotkeys in object captions}

  {$I KEYCODES.INC}
  {$I APPINFO.INC}

type
  TMouseButton = (mbNone, mbLeft, mbRight, mbBoth);
  TMsgBoxType  = (msgInfo, msgWarn, msgQuest, msgError);

  IconDataType = record
    Pixel: array[0..31, 0..31] of Integer;
  end;

  PosType = record
    Left, Top, Width, Height: Integer;
  end;

  ButtonType = object
    Pos: PosType;
    Caption: string;
    Transparent: Boolean;
    constructor Init(Left, Top, Width, Height: Integer; CaptionS: string);
  end;

  CheckBoxType = record
    Pos: PosType;
    Checked: Boolean;
  end;

  ImageType = record
    Pos: PosType;
    ImageFile: string[64];
  end;

  WindowType = object
    Pos: PosType;
    constructor Init(Left, Top, Width, Height: Integer);
  end;

  FrameType = record
    Pos: PosType;
  end;

  TextboxType = object
    Pos: PosType;
    MaxLen: Integer;
    constructor Init(Left, Top, Width, Height: Integer);
  end;

  FileAssociationType = record
    FileType: string[3];
    Command: string[128];
  end;

  SettingType = record
    DesktopID           : Integer;
    ShowLinkDescriptions: Boolean;
    ShowLinkTargetFiles : Boolean;
    ConfirmLinkDelete   : Boolean;
    ConfirmExit         : Boolean;
    AssignFileTypes     : Boolean;
    ThemeFile           : string[8];
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
function FileGetAssociation(const FileType: string): string;
function FontGetWidth(TargetText: String; FontID: Integer): Integer;
function GetKey: string;
function LowerCase(s: string): string;
function LTrim(s: string): string;
function MouseClicked: TMouseButton;
function MouseInArea(const TargetArea: PosType): Boolean;
function ObjBtnClick(var TargetBtn: ButtonType): Boolean;
function ObjTxtClick(const TargetTxt: TextboxType): Boolean;
function Replace(Input, OldSubStr, NewSubStr: String): String;
function RTrim(s: string): string;
function SysMsgBox(const msgTitle, msgText: string; msgType: TMsgBoxType): Boolean;
Function SysPath: DirStr;
function Timer: Real;
function Trim(s: string): string;
function UpperCase(s: string): string;
procedure ClearKeyBuffer;
procedure FontPrint(Text: string; X, Y, Col, FontID: Integer);
procedure MouseHide;
procedure MousePoll;
procedure MouseSetPos(XPos, YPos: Integer);
procedure MouseShow;
procedure ObjChkClick(var TargetChk: CheckBoxType);
procedure ObjDrawBtn(var TargetBtn: ButtonType; Pressed: Boolean);
procedure ObjDrawChk(var TargetChk: CheckBoxType);
procedure ObjDrawFrm(const TargetFrm: FrameType; LightColor, DarkColor: Integer);
procedure ObjDrawImg(var TargetImg: ImageType);
procedure ObjDrawMenu;
procedure ObjDrawTxt(var TargetTxt: TextboxType; const Text: string; IsEditing: Boolean);
procedure ObjDrawWin(var TargetWin: WindowType);
procedure ObjEditTxt(var TargetTxt: TextboxType; var Text: string);
procedure ObjSetSize(var TargetArea: PosType; TargetLeft, TargetTop, TargetWidth, TargetHeight: Integer);
procedure SysAboutBox(const ProgramName, ProgramVersion, ProgramAuthor, IconFile: string);
procedure SysLoad;
procedure SysLoadSettings;
procedure SysLoadTheme(ThemeFile: String);
procedure SysSaveSettings;
procedure SysShowLoading;

implementation

constructor ButtonType.Init(Left, Top, Width, Height: Integer; CaptionS: string);
begin
  Pos.Left := Left;
  Pos.Top := Top;
  if Width = sizeDefault then
    Pos.Width := 92
  else
    Pos.Width := Width;
  if Height = sizeDefault then
    Pos.Height := 22
  else
    Pos.Height := Height;
  Self.Caption := CaptionS;
  Self.Transparent := False;
end;

constructor TextboxType.Init(Left, Top, Width, Height: Integer);
begin
  Pos.Left := Left;
  Pos.Top := Top;
  if Width = sizeDefault then
    Pos.Width := 120
  else
    Pos.Width := Width;
  if Height = sizeDefault then
    Pos.Height := 19
  else
    Pos.Height := Height;
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
    Pos.Left := (640 - Pos.Width) div 2 {640 is horizontal resolution}
  else
    Pos.Left := Left;

  if Top = sizeCenter then
    Pos.Top := (350 - Pos.Height) div 2 {350 is vertical resolution}
  else
    Pos.Top := Top;
end;

function FileExists(const FileName: string): Boolean;
var
  f: file;
  exists: Boolean;
begin
  Assign(f, FileName);
  {$I-}
  Reset(f);
  {$I+}
  exists := IOResult = 0;
  if exists then Close(f);
  FileExists := exists;
end;

function FileGetAssociation(const FileType: string): string;
var
  AssociationFile: string;
  f: file of FileAssociationType;
  FA: FileAssociationType;
  OpenWith: string;
  UpperFileType: string;
  FileExistsResult: Boolean;
begin
  UpperFileType := UpperCase(FileType);
  if (UpperFileType = 'EXE') or (UpperFileType = 'COM') then
  begin
    FileGetAssociation := '';
    Exit;
  end;
  if UpperFileType = 'BAT' then
  begin
    FileGetAssociation := GetEnv('COMSPEC');
    Exit;
  end;
  AssociationFile := 'CONFIG\FILETYPE.DAT';
  FileExistsResult := FileExists(AssociationFile);
  if not FileExistsResult then
  begin
    FileExistsResult := FileExists('CONFIG\FILETYPE.DEF');
    if FileExistsResult then
      AssociationFile := 'CONFIG\FILETYPE.DEF'
    else
    begin
      FileGetAssociation := '';
      Exit;
    end;
  end;
  Assign(f, AssociationFile);
  {$I-}
  Reset(f);
  {$I+}
  if IOResult <> 0 then 
  begin
    FileGetAssociation := '';
    Exit;
  end;
  OpenWith := '';
  while not Eof(f) do
  begin
    Read(f, FA);
    if UpperFileType = UpperCase(Trim(FA.FileType)) then
    begin
      OpenWith := Trim(FA.Command);
      Break;
    end;
  end;
  Close(f);
  FileGetAssociation := OpenWith;
end;


function FontGetWidth(TargetText: String; FontID: Integer): Integer;
var
  Width: Integer;
begin
  Width := Length(TargetText) * 8; {Each character is 8 pixels wide}
  
  if Pos(HotkeySymbol, TargetText) > 0 then
    Width := Width - 8; {Don't count the hotkey symbol}

  FontGetWidth := Width;
end;

procedure FontPrint(Text: String; X, Y, Col, FontID: Integer);
var
  HotkeyPos: Integer;
begin
  SetTextJustify(LeftText, TopText);
  SetColor(Col);

  {If the text contains a hotkey symbol, remove it and draw an underline under
   the next character}
  HotkeyPos := Pos(HotkeySymbol, Text);
  if HotkeyPos > 0 then
  begin
    Delete(Text, HotkeyPos, 1);
    Rectangle(X + HotkeyPos * 8 - 9, Y + 9, X + HotkeyPos * 8 - 1, Y + 9);
  end;

  OutTextXY(X, Y, Text);
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
var
  IsUp: Integer;
begin
  ObjBtnClick := False;
  IsUp := 0;
  if (MouseClicked = mbLeft) and MouseInArea(TargetBtn.Pos) then
  begin
    MouseHide;
    ObjDrawBtn(TargetBtn, True);
    MouseShow;
    repeat
      if MouseInArea(TargetBtn.Pos) then
      begin
        if IsUp = 1 then
        begin
          IsUp := 0;
          MouseHide;
          ObjDrawBtn(TargetBtn, True);
          MouseShow;
        end;
      end
      else
      begin
        if IsUp = 0 then
        begin
          IsUp := 1;
          MouseHide;
          ObjDrawBtn(TargetBtn, False);
          MouseShow;
        end;
      end;
    until MouseClicked = mbNone;
    if IsUp = 0 then
    begin
      MouseHide;
      ObjDrawBtn(TargetBtn, False);
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

procedure ObjDrawBtn(var TargetBtn: ButtonType; Pressed: Boolean);
var
  x1, x2, y1, y2: Integer;
  Color1, Color2, Color3, Color4: Integer;
begin
  x1 := TargetBtn.Pos.Left;
  y1 := TargetBtn.Pos.Top;
  if TargetBtn.Pos.Width = 0 then TargetBtn.Pos.Width := 92;
  if TargetBtn.Pos.Height = 0 then TargetBtn.Pos.Height := 22;
  x2 := x1 + TargetBtn.Pos.Width;
  y2 := y1 + TargetBtn.Pos.Height;
  if not Pressed then
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
  if not TargetBtn.Transparent then
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
  if RTrim(TargetBtn.Caption) <> '' then
  begin
    x1 := (x2 - x1) div 2 + x1;
    y1 := (y2 - y1) div 2 + y1 - 3; {3 is the offset to center text vertically}
    x1 := x1 - FontGetWidth(TargetBtn.Caption, FontHeading) div 2;
    if Pressed then
    begin
      Inc(x1);
      Inc(y1);
    end;
    FontPrint(TargetBtn.Caption, x1, y1, Color4, FontHeading);
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
begin
  X := TargetImg.Pos.Left;
  Y := TargetImg.Pos.Top;
  TargetImg.Pos.Width := 31;  {Width/height are set here to make sure they match icon size in click detection etc.}
  TargetImg.Pos.Height := 31;

  {Image border}
  SetColor(Theme.Light);
  Line(X-1, Y-1, X+32, Y-1);
  Line(X-1, Y, X-1, Y+32);
  SetColor(Theme.Shadow);
  Line(X, Y+32, X+32, Y+32);
  Line(X+32, Y, X+32, Y+31);

  Size := ImageSize(0, 0, 31, 31); {Coords don't matter, just size}
  Assign(ImageFile, 'IMAGES\' + TargetImg.ImageFile + '.BIN');
  {$I-}
  Reset(ImageFile, 1);
  {$I+}
  if (IOResult <> 0) or (FileSize(ImageFile) <> Size) then
  begin
    SetFillStyle(SolidFill, Red);
    Bar(X, Y, X+31, Y+31);
    FontPrint('IMG', X+5, Y+6, 15, FontNormal);
    FontPrint('ERR', X+5, Y+19, 15, FontNormal);
    Exit;
  end;
  GetMem(ImagePointer, Size);
  BlockRead(ImageFile, ImagePointer^, Size);
  Close(ImageFile);
  PutImage(x, y, ImagePointer^, CopyPut);
  FreeMem(ImagePointer, Size);
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
    while FontGetWidth(S, FontHeading) >= MaxShow do
      Delete(S, 1, 1);
    FontPrint(S, x1+5, y1+5, Theme.TextboxText, FontHeading);
  end;
  if IsEditing then
  begin
    x1 := x1 + 7 + FontGetWidth(S, FontHeading);
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

  if FontGetWidth(TempTxt, FontHeading) + 2 < MaxShow then
  begin
		LineX1 := x1 + FontGetWidth(Text, FontHeading) + 2;
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
              if FontGetWidth(TempTxt, FontHeading) + 2 < MaxShow then
              begin
                {Erase only the last char}
                LineX1 := x1 + FontGetWidth(TempTxt, FontHeading);
                SetFillStyle(SolidFill, Theme.Textbox);
                Bar(LineX1 + 2, y1 - 2, LineX1 - 8, y1 + 11);
                TempTxt := Copy(TempTxt, 1, Length(TempTxt) - 1);
                LineX1 := x1 + FontGetWidth(TempTxt, FontHeading) + 2;
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
            LineX1 := x1 + FontGetWidth(Text, FontHeading) + 2;
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
              if FontGetWidth(TempTxt + Key, FontHeading) + 2 < MaxShow then
              begin
                LineX1 := x1 + FontGetWidth(TempTxt, FontHeading) + 2;
                SetColor(Theme.Textbox);
                Line(LineX1, y1 - 1, LineX1, y1 + 10);
                TempTxt := TempTxt + Key;
                FontPrint(TempTxt, x1, y1, Theme.TextboxText, FontHeading);
                LineX1 := x1 + FontGetWidth(TempTxt, FontHeading) + 2;
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

procedure ObjSetSize(var TargetArea: PosType; TargetLeft, TargetTop, TargetWidth, TargetHeight: Integer);
begin
  if TargetWidth <> sizeRetain then TargetArea.Width := TargetWidth;
  if TargetHeight <> sizeRetain then TargetArea.Height := TargetHeight;
  if TargetLeft <> sizeRetain then
    if TargetLeft = sizeCenter then
      TargetArea.Left := (640 - TargetArea.Width) div 2
    else
      TargetArea.Left := TargetLeft;
  if TargetTop <> sizeRetain then
    if TargetTop = sizeCenter then
      TargetArea.Top := (322 - TargetArea.Height) div 2 + 28
    else
      TargetArea.Top := TargetTop;
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
  ObjSetSize(winAboutBox.Pos, sizeCenter, sizeCenter, 329, 216);
  ObjSetSize(imgLogo.Pos, 168, winAboutBox.Pos.Top + 11, sizeRetain, sizeRetain);
  ObjSetSize(btnClose.Pos, 274, winAboutBox.Pos.Top + winAboutBox.Pos.Height-34, 92, 22);
  btnClose.Caption := HotkeySymbol + 'Close';
  btnClose.Transparent := False;
  imgLogo.ImageFile := IconFile;
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
  ObjDrawBtn(btnClose, False);
  ObjDrawImg(imgLogo);
  FontPrint(ProgramName + ' ' + ProgramVersion, 212, winAboutBox.Pos.Top + 17, 0, 1);
  FontPrint('By ' + ProgramAuthor, 212, winAboutBox.Pos.Top + 31, 0, 2);
  FontPrint('Made with the ' + LibraryName + ' version', 168, winAboutBox.Pos.Top + 53, 0, 2);
  FontPrint(LibraryVersion + ' by Jacob Palm, 2004-' + LibraryYear + '.', 168, winAboutBox.Pos.Top + 67, 0, 2);
  FontPrint('May be freely distributed under the', 168, winAboutBox.Pos.Top + 95, 0, 2);
  FontPrint('terms of the MIT License. More details', 168, winAboutBox.Pos.Top + 109, 0, 2);
  FontPrint('can be found in the LICENSE file.', 168, winAboutBox.Pos.Top + 123, 0, 2);
  FontPrint('More information and news online at:', 168, winAboutBox.Pos.Top + 151, 0, 2);
  FontPrint('https://costa.jacobpalm.dk', 168, winAboutBox.Pos.Top + 165, 0, 2);
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
  SysLoadTheme('DEFAULT'); {Debugging: Use default theme for now}

  Intr($33, regs);
  MouseSupport := Regs.ax > 0;

  repeat until MouseClicked = mbNone;
  while KeyPressed do ReadKey;
  MouseShow;
end;

procedure SysLoadSettings;
var
  f: file of SettingType;
begin
  Exit; {Debugging: Disable settings loading for now}
  if not FileExists('CONFIG\SETTING.DAT') then
  begin
    {Use defaults}
    Setting.DesktopID := 1;
    Setting.ShowLinkDescriptions := True;
    Setting.ShowLinkTargetFiles := False;
    Setting.ConfirmLinkDelete := True;
    Setting.ConfirmExit := True;
    Setting.AssignFileTypes := True;
    Setting.ThemeFile := 'DEFAULT';
    Exit;
  end;

  Assign(f, 'CONFIG\SETTING.DAT');
  {$I-}
  Reset(f);
  {$I+}
  if IOResult <> 0 then
  begin
    {Use defaults}
    Setting.DesktopID := 1;
    Setting.ShowLinkDescriptions := True;
    Setting.ShowLinkTargetFiles := False;
    Setting.ConfirmLinkDelete := True;
    Setting.ConfirmExit := True;
    Setting.AssignFileTypes := True;
    Setting.ThemeFile := 'DEFAULT';
    Exit;
  end;
  Read(f, Setting);
  Close(f);
  if (Setting.DesktopID < 1) or (Setting.DesktopID > 5) then
    Setting.DesktopID := 1;
end;

procedure SysLoadTheme(ThemeFile: String);
var
  f: file;
begin
  if FileExists('THEMES\' + ThemeFile + '.BIN') then
  begin
    Assign(f, 'THEMES\' + ThemeFile + '.BIN');
    {$I-}
    Reset(f, SizeOf(ThemeType));
    {$I+}
    if IOResult = 0 then
      BlockRead(f, Theme, 1);
    Close(f);
    Exit;
  end;
  
  {If file didn't exist or colors couldn't be read, use default theme}
  Theme.Desktop := LightGray;
  Theme.DesktopText := Black;
  Theme.Window := LightGray;
  Theme.Button := LightGray;
  Theme.Textbox := White;
  Theme.TextboxText := Black;
  Theme.WindowText := Black;
  Theme.TitleBar := Cyan;
  Theme.TitleBarText := Black;
  Theme.Light := LightGray;
  Theme.Shadow := DarkGray;
  Theme.Select := DarkGray;
  Theme.SelectText := White;
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
      if FontGetWidth(S, FontNormal) > msgTextWidth then
        msgTextWidth := FontGetWidth(S, FontNormal);
      Break;
    end
    else
    begin
      Inc(msgLineCount);
      msgLines[msgLineCount] := Copy(S, 1, P-1);
      if FontGetWidth(msgLines[msgLineCount], FontNormal) > msgTextWidth then
        msgTextWidth := FontGetWidth(msgLines[msgLineCount], FontNormal);
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
  ObjSetSize(winMsgBox.Pos, sizeCenter, sizeCenter, sizeRetain, msgLineCount*15+78);
  ObjSetSize(imgIcon.Pos, winMsgBox.Pos.Left+13, winMsgBox.Pos.Top+15, sizeRetain, sizeRetain);
  case msgType of
    msgInfo: imgIcon.ImageFile := 'MSGINFO';
    msgWarn: imgIcon.ImageFile := 'MSGWARN';
    msgQuest: imgIcon.ImageFile := 'MSGQUEST';
    msgError: imgIcon.ImageFile := 'MSGERROR';
  end;
  ObjSetSize(btnFirst.Pos, sizeRetain, winMsgBox.Pos.Top+42+(15*msgLineCount), 80, 22);
  if msgType = msgQuest then
  begin
    btnFirst.Caption := HotkeySymbol + 'Yes';
    btnFirst.Pos.Left := 320 - 86;
  end
  else
  begin
    btnFirst.Caption := HotkeySymbol + 'OK';
    btnFirst.Pos.Left := (640 - btnFirst.Pos.Width) div 2;
  end;
  ObjSetSize(btnSecond.Pos, 326, btnFirst.Pos.Top, 80, 22);
  btnSecond.Caption := HotkeySymbol + 'No';

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
  ObjDrawBtn(btnFirst, False);
  if msgType = msgQuest then ObjDrawBtn(btnSecond, False);
  ObjDrawImg(imgIcon);
  FontPrint(msgTitle, winMsgBox.Pos.Left+56, winMsgBox.Pos.Top+15, Theme.WindowText, 1);
  for i := 1 to msgLineCount do
    FontPrint(msgLines[i], winMsgBox.Pos.Left+56, winMsgBox.Pos.Top+17+(15*i), Theme.WindowText, 2);
  MouseShow;
  repeat
    Key := '';
    if KeyPressed then
      Key := ReadKey;
      
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
    Key := #0;
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
  f: file of SettingType;
begin
  Exit; {Debugging: Disable settings saving for now}
  Assign(f, 'CONFIG\SETTING.DAT');
  {$I-}
  Rewrite(f);
  Write(f, Setting);
  Close(f);
  {$I+}
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
    OutString := OutString + ReadKey;  { Read the next key for special keys }
  end;

  GetKey := OutString;
end;

procedure ClearKeyBuffer;
var
  k: char;
begin
  while KeyPressed do
  begin
    k := ReadKey;  {Read and discard any keys in the buffer}
  end;
end;

procedure SysShowLoading;
var
  btnLoading: ButtonType;
begin
  ObjSetSize(btnLoading.Pos, sizeCenter, sizeCenter, 110, 34);
  btnLoading.Caption := 'Loading...';
  btnLoading.Transparent := False;
  MouseHide;
  ObjDrawBtn(btnLoading, False);
  MouseShow;
end;

begin
  SysLoad;
end.