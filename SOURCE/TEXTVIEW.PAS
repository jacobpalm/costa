program Textview;

uses
  CostaLib, Strings, Graph, Crt;
const
  MaxLinesShown = 19;

type
  TStringArray = array[0..49] of string;

var
  FileData: TStringArray;
  btnOpen, btnAbout, btnExit, btnPageUp, btnPageDown: ButtonType;
  txtEditor: TextboxType;
  Filename, OldFileName: string;
  StartLine, OldStartLine: Integer;
  FileOpened, OldFileOpened: Boolean;
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
procedure DrawText(StartLine: Integer);
var
  LineCount: Integer;
begin
  MouseHide;
  for LineCount := StartLine to StartLine + MaxLinesShown do
  begin
    if LineCount <= High(FileData) then
    begin
      SetFillStyle(SolidFill, Theme.Textbox);
      Bar(7, (15 * (LineCount - StartLine + 1)) + 22, 633, 15 * (LineCount - StartLine + 1) + 36);
      FontPrint(FileData[LineCount], 9, (15 * (LineCount - StartLine + 1)) + 24, Theme.TextboxText, FontNormal);
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
  FileHandle: Text;
  Line: string;
  TrimLine, LoadedLines: Integer;
begin
  if not FileExists(TargetFile) then
  begin
    SysMsgBox('File not found', 'Textviewer could not find the file you are trying to load.', msgError);
    LoadFile := False;
    Exit;
  end;

  SysShowLoading;

  Assign(FileHandle, TargetFile);
  {$I-}
  Reset(FileHandle);
  {$I+}
  if IOResult <> 0 then
  begin
    SysMsgBox('File error', 'An error occurred while trying to open the file: ' + TargetFile, msgError);
    LoadFile := False;
    Exit;
  end;

  LoadedLines := 0;
  
  while not EOF(FileHandle) do
  begin
    ReadLn(FileHandle, Line);
    LoadedLines := LoadedLines + 1;
    FileData[LoadedLines] := Line;
  end;

  FileData[LoadedLines + 1] := '* end of file *';
  Close(FileHandle);
  LoadFile := True;
end;

begin
  ObjSetSize(btnOpen.Pos, 3, 2, 92, 22);
  ObjSetSize(btnPageUp.Pos, 102, 2, 92, 22);
  ObjSetSize(btnPageDown.Pos, 201, 2, 92, 22);
  ObjSetSize(btnAbout.Pos, 446, 2, 92, 22);
  ObjSetSize(btnExit.Pos, 545, 2, 92, 22);
  ObjSetSize(txtEditor.Pos, 2, 32, 635, 314);

  btnOpen.Caption := 'Open...';
  btnPageUp.Caption := 'Page up';
  btnPageDown.Caption := 'Page down';
  btnAbout.Caption := 'About...';
  btnExit.Caption := 'Exit';

  if ParamStr(1) <> '' then
  begin
    Filename := ParamStr(1);
    if not FileExists(Filename) then
    begin
      SysMsgBox('File not found', Filename + #13 + 'Textviewer could not find the file you are trying to load.', msgError);
      CloseGraph;
      Halt;
    end
    else
    begin
      FileOpened := LoadFile(Filename);
    end;
  end;

  MouseHide;
  ObjDrawMenu;
  SetFillStyle(SolidFill, Theme.Window);
  Bar(0, 29, 639, 349);
  ObjDrawBtn(btnOpen, False);
  ObjDrawBtn(btnAbout, False);
  ObjDrawBtn(btnExit, False);
  ObjDrawTxt(txtEditor, '', False);
  MouseShow;

  StartLine := 1;
  if FileOpened then
    DrawText(StartLine);

  repeat
    if KeyPressed then
      Key := ReadKey
    else
      Key := '';
    
    if ObjBtnClick(btnAbout) or (Key = 'a') then
      SysAboutBox('Text Viewer', '2.0', 'Jacob Palm', 'DOCUMENT');

    if ObjBtnClick(btnOpen) or (Key = 'o') then
    begin
      Readln(Filename);
      if Length(Filename) > 0 then
      begin
        if LoadFile(Filename) then
        begin
          FileOpened := True;
          StartLine := 1;
          DrawText(StartLine);
        end;
      end;
    end;
    
    if ObjBtnClick(btnExit) or (Key = 'x') or (Key = #27) then
      Break;
    
  until False;
  
  CloseGraph;
end.