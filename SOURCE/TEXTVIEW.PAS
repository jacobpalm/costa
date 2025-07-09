program Textview;

uses
  Costalib, Filesel, Strings, Graph, Crt;

const
  AppName = 'Text Viewer';
  AppVersion = '2.0';
  AppAuthor = 'Jacob Palm';
  InitialCap = 100;  {Initial capacity for the line array}
  MaxLinesShown = 22;
  MaxLineLength = 78;

type
  PLine = ^LineStr;
  LineStr = String[MaxLineLength];

  PLineArray = ^LineArray;
  LineArray = Array[1..1] of PLine;  {Flexible array to simulate dynamic sizing}

var
  Lines: PLineArray;
  BtnOpen, BtnAbout, BtnExit, BtnPageUp, BtnPageDown: ButtonType;
  Filename, NewFileName: String;
  StartLine, PrevStartLine: Integer;
  Capacity: Integer;
  LineCount: Integer;
  FileOpened: Boolean;
  Key: String;
  DefaultHeapError: Pointer; {We'll be taking care of heap errors ourselves}

procedure FreeLines; forward;

function CustomHeapError(Size: Word): Integer; far;
var
  MsgResult: Boolean;
  SizeStr: String;
begin
  if Size = 0 then
  begin
    CustomHeapError := 0;
    Exit;
  end;

  FreeLines;  {Free any previously allocated lines}
  Filename := '';
  FileOpened := False;
  MouseHide;
  SetFillStyle(SolidFill, Theme.Textbox);
  Bar(0, 29, 639, 349);
  MouseShow;
  Str(Size, SizeStr);
  MsgResult := SysMsgBox('Out of memory', 'Not enough memory to open this file.', msgError);
  CustomHeapError := 1;  {Make GetMem return a nil pointer}
end;

function InitLines(InitialSize: Integer): Boolean;
begin
  Capacity := InitialSize;
  LineCount := 0;
  HeapError := @CustomHeapError;
  GetMem(Lines, Capacity * SizeOf(PLine));
  HeapError := DefaultHeapError;
  if Lines = nil then
  begin
    InitLines := False;
    Exit;
  end;
end;

function ResizeLines(var Lines: PLineArray; OldCap, NewCap: Integer): Boolean;
var
  NewLines: PLineArray;
  i: Integer;
begin

  {Only resize if the lines array has been initialized}
  if Lines = nil then
  begin
    ResizeLines := False;
    Exit;
  end;

  {Allocate new memory for the resized array}
  HeapError := @CustomHeapError;
  GetMem(NewLines, NewCap * SizeOf(PLine));
  HeapError := DefaultHeapError;

  if NewLines = nil then
  begin
    ResizeLines := False;
    Exit;
  end;

  {Copy existing lines to the new array}
  Move(Lines^[1], NewLines^[1], OldCap * SizeOf(PLine));
  {for i := 1 to OldCap do
    NewLines^[i] := Lines^[i];
}
  {Free memory of the old array}
  FreeMem(Lines, OldCap * SizeOf(PLine));

  {Update the pointer to the new array}
  Lines := NewLines;
end;

procedure FreeLines;
var
  i: Integer;
begin
  {Dispose all lines in the array}
  for i := 1 to LineCount do
    Dispose(Lines^[i]);

  {Free the memory allocated for the array itself}
  FreeMem(Lines, Capacity * SizeOf(PLine));

  Capacity := 0;
  LineCount := 0;
  StartLine := 1;
  PrevStartLine := 1;
end;

procedure AddLine(S: String);
var
  NewLine: PLine;
begin
  if LineCount >= Capacity then
  begin
    {Reallocate space for more lines, exit if it fails}
    if not ResizeLines(Lines, Capacity, Capacity + 10) then
      Exit;
    Capacity := Capacity + 10;
  end;

  New(NewLine);
  NewLine^ := S;
  Inc(LineCount);
  Lines^[LineCount] := NewLine;
end;

function LoadFile(TargetFile: String): Boolean;
var
  f: Text;
  ReadData, Truncated: String;
begin
  if not FileExists(TargetFile) then
  begin
    SysMsgBox('File not found', 'Error while trying to find the file:' + NewLine + TargetFile, msgError);
    LoadFile := False;
    Exit;
  end;

  Assign(f, TargetFile);
  {$I-}
  Reset(f);
  {$I+}
  if IOResult <> 0 then
  begin
    SysMsgBox('File error', 'Error while opening the file: ' + NewLine + TargetFile, msgError);
    LoadFile := False;
    Exit;
  end;

  SysShowLoading;
  
  if FileOpened then
    FreeLines;  {Free previously loaded lines}
   
  {Initialize with default capacity, exit if failed} 
  if not InitLines(InitialCap) then
    Exit;  

  StartLine := 1;
  PrevStartLine := 1;

  while not Eof(F) do
  begin
    ReadLn(F, ReadData);

    {Blank lines}
    if Length(ReadData) = 0 then
    begin
      AddLine('');
      Continue;
    end;

    {Replace TAB with two spaces}
    ReadData := Replace(ReadData, #9, '  '); 

    {Add each line to the array, truncate at MaxLineLength if necessary}
    while Length(ReadData) > 0 do
    begin
      if Length(ReadData) > MaxLineLength then
      begin
        Truncated := Copy(ReadData, 1, MaxLineLength);
        Delete(ReadData, 1, MaxLineLength);
      end
      else
      begin
        Truncated := ReadData;
        ReadData := '';
      end;

      AddLine(Truncated);
    end;

    {Exit if lines array has been freed due to memory error}
    if LineCount = 0 then
    begin
      LoadFile := False;
      Close(F);
      Exit;
    end;
  end;
  Close(F);

  AddLine('* end of file *');
  if LineCount > 0 then
    LoadFile := True
  else
    LoadFile := False;
end;

procedure DrawText;
var
  i, DrawnLines: Integer;
begin
  MouseHide;
  SetFillStyle(SolidFill, Theme.Textbox);
  DrawnLines := 0;
  for i := StartLine to StartLine + MaxLinesShown do
  begin
    Inc(DrawnLines);
    
    {Clear line}
    Bar(7, (15 * (i - StartLine + 1)) + 22, 633, 15 * (i - StartLine + 1) + 36);

    {No text to display, skip}
    if (DrawnLines < MaxLinesShown) and (i <= LineCount) then
      {Dereference the line pointer and print the text}
      FontPrint(Lines^[i]^, 9, (15 * (i - StartLine + 1)) + 24, Theme.TextboxText, FontNormal);

  end;
  MouseShow;
end;

begin
  {Store default heap error handler for later restoration}
  DefaultHeapError := HeapError;

  BtnOpen.Init(3, 2, SizeDefault, SizeDefault, HotkeySymbol + 'Open...');
  BtnPageUp.Init(102, 2, SizeDefault, SizeDefault, 'Page ' + HotkeySymbol + 'up');
  BtnPageDown.Init(201, 2, SizeDefault, SizeDefault, 'Page ' + HotkeySymbol + 'down');
  BtnAbout.Init(446, 2, SizeDefault, SizeDefault, HotkeySymbol + 'About...');
  BtnExit.Init(545, 2, SizeDefault, SizeDefault, 'E' + HotkeySymbol + 'xit');

  MouseHide;
  ObjDrawMenu;
  SetFillStyle(SolidFill, Theme.Textbox);
  Bar(0, 29, 639, 349);
  ObjDrawBtn(BtnOpen, False);
  ObjDrawBtn(BtnPageUp, False);
  ObjDrawBtn(BtnPageDown, False);
  ObjDrawBtn(BtnAbout, False);
  ObjDrawBtn(BtnExit, False);
  MouseShow;
  
  if ParamStr(1) <> '' then
  begin
    Filename := ParamStr(1);
    FileOpened := LoadFile(Filename);
    if FileOpened then
      DrawText
    else
      Filename := '';
  end;

  repeat
    Key := GetKey;
    
    if ObjBtnClick(BtnAbout) or (Key = KeyAltA) then
      SysAboutBox(AppName, AppVersion, AppAuthor, 'DOCUMENT');

    if ObjBtnClick(BtnOpen) or (Key = KeyAltO) then
    begin
      NewFileName := FileSelect('*.txt');
      if Length(NewFilename) > 0 then
      begin
        if LoadFile(NewFilename) then
        begin
          Filename := NewFilename;
          FileOpened := True;
          MouseHide;
          ObjDrawBtn(BtnPageUp, False);
          ObjDrawBtn(BtnPageDown, False);
          MouseShow;
          DrawText;
        end;
      end;
    end;
    
    if ObjBtnClick(BtnExit) or (Key = KeyAltX) or (Key = KeyAltF4) then
      break;

    if FileOpened then
    begin
      if ObjBtnClick(BtnPageUp) or (Key = KeyPageUp) or (Key = KeyUp) or (Key = KeyAltU) then
      begin
        if StartLine > 1 then
        begin
          if Key = KeyUp then
            Dec(StartLine) {One line up}
          else
            Dec(StartLine, MaxLinesShown); {One page up}

          if StartLine < 1 then
            StartLine := 1;
        end;
      end;

      if ObjBtnClick(BtnPageDown) or (Key = KeyPageDown) or (Key = KeyDown) or (Key = KeyAltD) then
      begin
        if StartLine < LineCount then
        begin
          if Key = KeyDown then
            Inc(StartLine) {One line down}
          else
            Inc(StartLine, MaxLinesShown); {One page down}
          
          {Don't scroll further than the last line of the file being the last on screen}
          if StartLine > LineCount - MaxLinesShown + 2 then
            StartLine := LineCount - MaxLinesShown + 2;
          
          if StartLine < 1 then
            StartLine := 1;
        end;
      end;

      If Key = KeyHome then
        StartLine := 1;

      if Key = KeyEnd then
      begin
        StartLine := LineCount - MaxLinesShown + 2;
        If StartLine > LineCount then
          StartLine := LineCount;
      end;

      If StartLine <> PrevStartLine then
      begin
        MouseHide;
        DrawText;
        MouseShow;
        PrevStartLine := StartLine;
      end;
    end;
    
  until False;
  
  CloseGraph;
end.