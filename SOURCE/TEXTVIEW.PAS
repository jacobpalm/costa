program Textview;

uses
  CostaLib, Strings, Graph, Crt;

const
  AppName = 'Text Viewer';
  AppVersion = '2.0';
  AppAuthor = 'Jacob Palm';
  InitialCap = 100;  { Initial capacity for the line array }
  MaxLinesShown = 22;
  MaxLineLength = 78;

type
  PLine = ^LineStr;
  LineStr = string[MaxLineLength];

  PLineArray = ^LineArray;
  LineArray = array[1..1] of PLine;  { flexible array, simulate dynamic sizing }

var
  Lines: PLineArray;
  btnOpen, btnAbout, btnExit, btnPageUp, btnPageDown: ButtonType;
  Filename, NewFileName: string;
  StartLine: Integer;
  Capacity: Integer;
  LineCount: Integer;
  FileOpened: Boolean;
  Key: String;
  DefaultHeapError: Pointer; { We'll be taking care of heap errors ourselves }

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

  FreeLines;  { Free any previously allocated lines }
  Filename := '';
  FileOpened := False;
  MouseHide;
  SetFillStyle(SolidFill, Theme.Textbox);
  Bar(0, 29, 639, 349);
  MouseShow
  Str(Size, SizeStr);
  MsgResult := SysMsgBox('Out of memory', 'Not enough memory to open this file.', msgError);
  CloseGraph;
  Halt(1);  { gracefully exit }
  CustomHeapError := 1;  { technically unreachable }
end;

procedure InitLines(InitialSize: Integer);
begin
  Capacity := InitialSize;
  LineCount := 0;
  HeapError := @CustomHeapError;
  GetMem(Lines, Capacity * SizeOf(PLine));
  HeapError := DefaultHeapError;
end;

procedure ResizeLines(var Lines: PLineArray; OldCap, NewCap: Integer);
var
  NewLines: PLineArray;
  i: Integer;
begin

  HeapError := @CustomHeapError;  {Set custom heap error handler} 

  {Allocate new memory for the resized array}
  GetMem(NewLines, NewCap * SizeOf(PLine));

  {Copy existing lines to the new array}
  for i := 1 to OldCap do
    NewLines^[i] := Lines^[i];

  {Free memory of the old array}
  FreeMem(Lines, OldCap * SizeOf(PLine));

  HeapError := DefaultHeapError; {Restore default heap error handler}

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
end;

procedure AddLine(S: string);
var
  NewLine: PLine;
begin
  if LineCount >= Capacity then
  begin
    { Reallocate space for more lines }
    ResizeLines(Lines, Capacity, Capacity + 10);
    Capacity := Capacity + 10;
  end;

  New(NewLine);
  NewLine^ := S;
  Inc(LineCount);
  Lines^[LineCount] := NewLine;
end;

function LoadFile(TargetFile: string): Boolean;
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
    FreeLines;  { Free previously loaded lines }
  
  InitLines(InitialCap);  { Initialize with default capacity } 
  StartLine := 1;

  while not Eof(F) do
  begin
    ReadLn(F, ReadData);

    {Blank lines}
    if Length(ReadData) = 0 then
    begin
      AddLine('');
      Continue;
    end;

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
  end;
  Close(F);

  AddLine('* end of file *');
  LoadFile := True;
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

  ObjSetSize(btnOpen.Pos, 3, 2, 92, 22);
  ObjSetSize(btnPageUp.Pos, 102, 2, 92, 22);
  ObjSetSize(btnPageDown.Pos, 201, 2, 92, 22);
  ObjSetSize(btnAbout.Pos, 446, 2, 92, 22);
  ObjSetSize(btnExit.Pos, 545, 2, 92, 22);

  btnOpen.Caption := 'Open...';
  btnPageUp.Caption := 'Page up';
  btnPageDown.Caption := 'Page down';
  btnAbout.Caption := 'About...';
  btnExit.Caption := 'Exit';

  MouseHide;
  ObjDrawMenu;
  SetFillStyle(SolidFill, Theme.Textbox);
  Bar(0, 29, 639, 349);
  ObjDrawBtn(btnOpen, False);
  ObjDrawBtn(btnAbout, False);
  ObjDrawBtn(btnExit, False);
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

  if FileOpened then
  begin
    MouseHide;
    ObjDrawBtn(btnPageUp, False);
    ObjDrawBtn(btnPageDown, False);
    MouseShow;
  end;

  repeat
    Key := GetKey;
    
    if ObjBtnClick(btnAbout) or (Key = KeyAltA) then
      SysAboutBox(AppName, AppVersion, AppAuthor, 'DOCUMENT');

    if ObjBtnClick(btnOpen) or (Key = KeyAltO) then
    begin
      Readln(NewFilename);
      if Length(NewFilename) > 0 then
      begin
        if LoadFile(NewFilename) then
        begin
          Filename := NewFilename;
          FileOpened := True;
          MouseHide;
          ObjDrawBtn(btnPageUp, False);
          ObjDrawBtn(btnPageDown, False);
          MouseShow;
          DrawText;
        end;
      end;
    end;
    
    if ObjBtnClick(btnExit) or (Key = KeyAltX) or (Key = KeyAltF4) then
      break;

    if FileOpened then
    begin
      if ObjBtnClick(btnPageUp) or (Key = KeyPageUp) or (Key = KeyUp) then
      begin
        if StartLine > 1 then
        begin
          if Key = KeyUp then
            Dec(StartLine) {One line up}
          else
            Dec(StartLine, MaxLinesShown); {One page up}
          if StartLine < 1 then
            StartLine := 1;
          MouseHide;
          DrawText;
          MouseShow;
        end;
      end;

      if ObjBtnClick(btnPageDown) or (Key = KeyPageDown) or (Key = KeyDown) then
      begin
        if StartLine < LineCount then
        begin
          if Key = KeyDown then
            Inc(StartLine) {One line down}
          else
            Inc(StartLine, MaxLinesShown); {One page down}
          if StartLine > LineCount then
            StartLine := LineCount;
          MouseHide;
          DrawText;
          MouseShow;
        end;
      end;
    end;
    
  until False;
  
  CloseGraph;
end.