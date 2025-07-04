unit CostaLib;

interface

uses
  Crt, Dos, Graph, Strings;

const
  MaxFontID    = 2;
  FontHeading  = 1;
  FontNormal   = 2;
  sizeRetain   = -1;
  sizeCenter   = -2;
  mbLeft       = 1;
  mbRight      = 2;
  mbBoth       = 3;
  msgInfo      = 1;
  msgWarn      = 2;
  msgQuest     = 3;
  msgError     = 4;
  {$I APPINFO.INC}

type
  IconDataType = record
    Pixel: array[0..31, 0..31] of Integer;
  end;

  PosType = record
    Left, Top, Width, Height: Integer;
  end;

  ButtonType = record
    Pos: PosType;
    Caption: string[32];
    Transparent: Boolean;
  end;

  CheckBoxType = record
    Pos: PosType;
    Checked: Boolean;
  end;

  ImageType = record
    Pos: PosType;
    ImageFile: string[64];
  end;

  WindowType = record
    Pos: PosType;
  end;

  FrameType = record
    Pos: PosType;
  end;

  TextboxType = record
    Pos: PosType;
    MaxLen: Integer;
  end;

  FileAssociationType = record
    FileType: string[8];
    Command: string[128];
  end;

  SettingType = record
    DesktopID           : Integer;
    ShowLinkDescriptions: Boolean;
    ShowLinkTargetFiles : Boolean;
    ConfirmLinkDelete   : Boolean;
    ConfirmExit         : Boolean;
    AssignFileTypes     : Boolean;
    ThemeFile           : string[32];
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
  FontData: array[1..2, 32..127] of string[54];
  FontWidth: array[1..2, 32..127] of Integer;
  MouseVisible: Boolean;
  MouseSupport: Boolean;
  MouseX, MouseY: Integer;
  Setting: SettingType;
  Theme: ThemeType;

function FileExists(const FileName: string): Boolean;
function FileGetAssociation(const FileType: string): string;
function FontGetWidth(const TargetText: string; FontID: Integer): Integer;
function LowCase(c: Char): Char;
function LowerCase(s: string): string;
function LTrim(s: string): string;
function MouseClicked: Integer;
function MouseInArea(const TargetArea: PosType): Boolean;
function ObjBtnClick(var TargetBtn: ButtonType): Boolean;
function ObjTxtClick(const TargetTxt: TextboxType): Boolean;
function RTrim(s: string): string;
function SysMsgBox(const msgTitle, msgText: string; msgType: Integer): Boolean;
Function SysPath: DirStr;
function Trim(s: string): string;
function UpperCase(s: string): string;
procedure FontPrint(const Text: string; X, Y, Col, FontID: Integer);
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
procedure SysLoadTheme;
procedure SysSaveSettings;
procedure SysShowLoading;
implementation

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
  AssociationFile := 'DATA\CONFIG\FILETYPE.DAT';
  FileExistsResult := FileExists(AssociationFile);
  if not FileExistsResult then
  begin
    FileExistsResult := FileExists('DATA\CONFIG\FILETYPE.DEF');
    if FileExistsResult then
      AssociationFile := 'DATA\CONFIG\FILETYPE.DEF'
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


function FontGetWidth(const TargetText: string; FontID: Integer): Integer;
var
  TotalWidth, StrPos, Ch: Integer;
begin
  TotalWidth := 0;
  if (TargetText = '') or ((FontID <> FontHeading) and (FontID <> FontNormal)) then
  begin
    FontGetWidth := 0;
    Exit;
  end;
  for StrPos := 1 to Length(TargetText) do
  begin
    Ch := Ord(TargetText[StrPos]);
    if (Ch >= 32) and (Ch <= 126) then
      TotalWidth := TotalWidth + 8
  end;
  FontGetWidth := TotalWidth - 2;
end;

procedure FontPrint(const Text: string; X, Y, Col, FontID: Integer);
begin
  SetTextJustify(LeftText, TopText);
  SetColor(Col);
  OutTextXY(X, Y, Text);
end;

function LowerCase(s: string): string;
var
  i: Integer;
begin
  for i := 1 to Length(s) do
    s[i] := LowCase(s[i]);
  LowerCase := s;
end;

function MouseClicked: Integer;
var
  regs: registers;
begin
  if not MouseSupport then
  begin
    MouseClicked := 0;
    Exit;
  end;
  regs.ax := 3;
  Intr($33, regs);
  MouseClicked := regs.bx;
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
    until MouseClicked = 0;
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
    repeat until MouseClicked = 0;
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
    y1 := (y2 - y1) div 2 + y1;
    if Pressed then
    begin
      Inc(x1);
      Inc(y1);
    end;
    SetTextJustify(CenterText, CenterText);
    SetColor(Color4);
    OutTextXY(x1, y1, TargetBtn.Caption);
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
  Assign(ImageFile, 'DATA\IMAGES\' + TargetImg.ImageFile + '.BIN');
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
  MouseHide;
  PutImage(x, y, ImagePointer^, CopyPut);
  MouseShow;
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
  if TargetTxt.Pos.Top = 0 then TargetTxt.Pos.Top := 120;
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
  if MaxLen = 0 then MaxLen := 256;
  MaxShow := TargetTxt.Pos.Width - 10;
  OrigTxt := Text;
  TempTxt := Text;
  while KeyPressed do Ch := ReadKey;
  repeat
    if FontGetWidth(TempTxt+Key, FontHeading) + 2 < MaxShow then
    begin
      LineX1 := x1 + FontGetWidth(Text, FontHeading) + 2;
      MouseHide;
      Line(LineX1, y1-1, LineX1, y1+10);
      MouseShow;
    end
    else
    begin
      MouseHide;
      ObjDrawTxt(TargetTxt, TempTxt, True);
      MouseShow;
    end;
    Key := '';
    if KeyPressed then
    begin
      Ch := ReadKey;
      if Ch = #8 then
      begin
        if Length(TempTxt) > 0 then
        begin
          MouseHide;
          if FontGetWidth(TempTxt, FontHeading) + 2 < MaxShow then
          begin
            LineX1 := x1 + FontGetWidth(TempTxt, FontHeading);
            SetFillStyle(SolidFill, Theme.Textbox);
            Bar(LineX1+2, y1-2, LineX1-FontGetWidth(Copy(TempTxt, Length(TempTxt), 1), FontHeading), y1+11);
            Delete(TempTxt, Length(TempTxt), 1);
            LineX1 := x1 + FontGetWidth(TempTxt, FontHeading) + 2;
            Line(LineX1, y1-1, LineX1, y1+10);
          end
          else
          begin
            Delete(TempTxt, Length(TempTxt), 1);
            ObjDrawTxt(TargetTxt, TempTxt, True);
          end;
          MouseShow;
        end;
      end
      else if Ch = #13 then
      begin
        Text := TempTxt;
        LineX1 := x1 + FontGetWidth(Text, FontHeading) + 2;
        MouseHide;
        Line(LineX1, y1-1, LineX1, y1+10);
        MouseShow;
        Exit;
      end
      else if (Ch >= #32) and (Ch <= #126) then
      begin
        if Length(TempTxt) < MaxLen then
        begin
          MouseHide;
          if FontGetWidth(TempTxt + Ch, FontHeading) + 2 < MaxShow then
          begin
            LineX1 := x1 + FontGetWidth(TempTxt, FontHeading) + 2;
            Line(LineX1, y1-1, LineX1, y1+10);
            TempTxt := TempTxt + Ch;
            FontPrint(TempTxt, x1, y1, Theme.TextboxText, FontHeading);
            LineX1 := x1 + FontGetWidth(TempTxt, FontHeading) + 2;
            Line(LineX1, y1-1, LineX1, y1+10);
          end
          else
          begin
            TempTxt := TempTxt + Ch;
            ObjDrawTxt(TargetTxt, TempTxt, True);
          end;
          MouseShow;
        end;
      end
      else if Ch = #27 then
      begin
        Text := OrigTxt;
        MouseHide;
        ObjDrawTxt(TargetTxt, Text, False);
        MouseShow;
        Exit;
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
    repeat until MouseClicked = 0;
    if MouseInArea(TargetTxt.Pos) then
      ObjTxtClick := True;
  end;
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
  btnClose.Caption := 'Close';
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
  repeat until MouseClicked = 0;
  repeat
    Key := '';
    if KeyPressed then
      Key := ReadKey;

    if ObjBtnClick(btnClose) or (Key = #13) or (Key = #27) or (Key = 'c') then Break;
  until False;
  MouseHide;
  PutImage(x1, y1, BackgroundP^, NormalPut);
  FreeMem(BackgroundP, BackgroundSize);
  MouseShow;
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
  SysLoadTheme;

  Intr($33, regs);
  MouseSupport := Regs.ax > 0;

  repeat until MouseClicked = 0;
  while KeyPressed do ReadKey;
  MouseShow;
end;

procedure SysLoadSettings;
var
  f: file of SettingType;
begin
  Exit; {Debugging: Disable settings loading for now}
  if not FileExists('DATA\CONFIG\SETTING.DAT') then
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

  Assign(f, 'DATA\CONFIG\SETTING.DAT');
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

procedure SysLoadTheme;
var
  ThemeFile: string;
  f: file of ThemeType;
begin
  {ThemeFile := RTrim(Setting.ThemeFile);
  if FileExists('DATA\THEMES\' + ThemeFile + '.DAT') then
  begin
    Assign(f, 'DATA\THEMES\' + ThemeFile + '.DAT');
    Reset(f);
    Read(f, Theme);
    Close(f);
  end
  else
  begin}
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
  {end;}
end;

function SysMsgBox(const msgTitle, msgText: string; msgType: Integer): Boolean;
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
  if (S <> '') and (S[Length(S)] = #13) then
    Delete(S, Length(S), 1);
  msgLineCount := 0;
  msgTextWidth := 0;
  repeat
    P := Pos(#13, S);
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
    btnFirst.Caption := '?Yes';
    btnFirst.Pos.Left := 320 - 86;
  end
  else
  begin
    btnFirst.Caption := '?OK';
    btnFirst.Pos.Left := (640 - btnFirst.Pos.Width) div 2;
  end;
  ObjSetSize(btnSecond.Pos, 326, btnFirst.Pos.Top, 80, 22);
  btnSecond.Caption := '?No';

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
      
    if ObjBtnClick(btnFirst) then Key := #13;
    if msgType = msgQuest then
    begin
      if ObjBtnClick(btnSecond) then Key := #27;
    end;
    if Key <> '' then
    begin
      if msgType = msgQuest then
      begin
        if (Key = 'y') or (Key = #13) then
        begin
          SysMsgBox := True;
          Break;
        end
        else if (Key = 'n') or (Key = #27) then
        begin
          SysMsgBox := False;
          Break;
        end;
      end
      else
      begin
        if (Key = #13) or (Key = #27) or (Key = #32) or (Key = 'o') then
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
  Assign(f, 'DATA\CONFIG\SETTING.DAT');
  {$I-}
  Rewrite(f);
  Write(f, Setting);
  Close(f);
  {$I+}
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

function LowCase(c: Char): Char;
begin
  if (c >= 'A') and (c <= 'Z') then
    LowCase := Chr(Ord(c) + 32)  (* Convert to lowercase ASCII *)
  else
    LowCase := c;  (* Leave it unchanged if it's not uppercase *)
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

procedure SysShowLoading;
var
  btnLoading: ButtonType;
begin
  ObjSetSize(btnLoading.Pos, sizeCenter, sizeCenter, 110, 34);
  btnLoading.Caption := 'Loading...';
  MouseHide;
  ObjDrawBtn(btnLoading, False);
  MouseShow;
end;

begin
  SysLoad;
end.