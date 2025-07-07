program Textview;

uses
  CostaLib, Strings, Graph, Crt;

const
  AppName = 'Text Viewer';
  AppVersion = '2.0';
  AppAuthor = 'Jacob Palm';
  MaxLinesShown = 22;
  MaxLineLength = 78;

type
  TStringArray = array[0..100] of string;

var
  FileData: TStringArray;
  btnOpen, btnAbout, btnExit, btnPageUp, btnPageDown: ButtonType;
  txtEditor: TextboxType;
  Filename, NewFileName: string;
  StartLine: Integer;
  LineCount: Integer;
  FileOpened: Boolean;
  Key: String;

{ ========================================================================= }
{          NAME: DrawText                                                   }
{    PARAMETERS: StartLine - the array position of the first line to print  }
{       RETURNS: Nothing                                                    }
{       ASSUMES: That the array position exists                             }
{   CALLED FROM: Main                                                       }
{ ------------------------------------------------------------------------- }
{   DESCRIPTION: Writes file content to the main textbox                    }
{ ========================================================================= }
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
    if DrawnLines = MaxLinesShown then
      Break;

    {Clear line}
    Bar(7, (15 * (i - StartLine + 1)) + 22, 633, 15 * (i - StartLine + 1) + 36);
    if i <= High(FileData) then
    begin
      FontPrint(FileData[i], 9, (15 * (i - StartLine + 1)) + 24, Theme.TextboxText, FontNormal);
    end;
  end;
  MouseShow;
end;

{ ========================================================================= }
{          NAME: LoadFile                                                   }
{    PARAMETERS: TargetFile - filename of the file to load                  }
{       RETURNS: Boolean - True if file loaded successfully, False otherwise}
{       ASSUMES: Nothing                                                    }
{   CALLED FROM: Main                                                       }
{ ------------------------------------------------------------------------- }
{   DESCRIPTION: Loads the file into memory, in an array of strings         }
{ ========================================================================= }
function LoadFile(TargetFile: string): Boolean;
var
  f: Text;
  ReadData, Truncated: string;
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
  
  For LineCount := 0 to High(FileData) do
    FileData[LineCount] := '';  
  
  LineCount := -1;
  while not Eof(F) and (LineCount < High(FileData) - 1) do
  begin
    ReadLn(F, ReadData);

    {Blank lines}
    if Length(ReadData) = 0 then
    begin
      Inc(LineCount);
      FileData[LineCount] := '';
      Continue;
    end;

    {Add each line to the array, truncate at MaxLineLength if necessary}
    while Length(ReadData) > 0 do
    begin
      Inc(LineCount);
      if LineCount > High(FileData) - 1 then
        Break;

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

      FileData[LineCount] := Truncated;
    end;
  end;
  Close(F);

  FileData[LineCount + 1] := '* end of file *';
  LoadFile := True;
end;

begin
  ObjSetSize(btnOpen.Pos, 3, 2, 92, 22);
  ObjSetSize(btnPageUp.Pos, 102, 2, 92, 22);
  ObjSetSize(btnPageDown.Pos, 201, 2, 92, 22);
  ObjSetSize(btnAbout.Pos, 446, 2, 92, 22);
  ObjSetSize(btnExit.Pos, 545, 2, 92, 22);
  ObjSetSize(txtEditor.Pos, -2, 32, 644, 319);

  btnOpen.Caption := 'Open...';
  btnPageUp.Caption := 'Page up';
  btnPageDown.Caption := 'Page down';
  btnAbout.Caption := 'About...';
  btnExit.Caption := 'Exit';

  if ParamStr(1) <> '' then
  begin
    Filename := ParamStr(1);
    FileOpened := LoadFile(Filename);
    if not FileOpened then Filename := '';
  end;

  MouseHide;
  ObjDrawMenu;
  SetFillStyle(SolidFill, Theme.Window);
  Bar(0, 29, 639, 33);
  ObjDrawBtn(btnOpen, False);
  ObjDrawBtn(btnAbout, False);
  if FileOpened then
  begin
    ObjDrawBtn(btnPageUp, False);
    ObjDrawBtn(btnPageDown, False);
  end;
  ObjDrawBtn(btnExit, False);
  ObjDrawTxt(txtEditor, '', False);
  MouseShow;

  StartLine := 0;
  if FileOpened then
    DrawText;

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
          StartLine := 0;
          MouseHide;
          ObjDrawTxt(txtEditor, '', False);
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
      if ObjBtnClick(btnPageUp) or (Key = KeyPageUp) then
      begin
        if StartLine > 0 then
        begin
          Dec(StartLine, MaxLinesShown);
          if StartLine < 0 then
            StartLine := 0;
          MouseHide;
          DrawText;
          MouseShow;
        end;
      end;

      if ObjBtnClick(btnPageDown) or (Key = KeyPageDown) then
      begin
        if StartLine < LineCount then
        begin
          Inc(StartLine, MaxLinesShown);
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