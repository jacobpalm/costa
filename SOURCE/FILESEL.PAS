program FileSelector;

uses
  Costalib, DOS, Graph;

const
  MaxFiles = 50;   {Maximum number of files}
  MaxFolders = 50; {Maximum number of folders}
  MaxVisibleItems = 13;
  FileList = 0;
  FolderList = 1;

  DirectionUp = -1;
  DirectionDown = 1;

var
  txtFileList, txtFolderList: TextboxType;
  FolderCount, FileCount: Integer;
  SubFolders: array[1..MaxFolders] of String[12];
  SubFiles: array[1..MaxFiles] of String[12];
  FileListStartPos, FolderListStartPos: Integer;
  FileListSelection, FolderListSelection, ActiveList: Integer;
  Path, Pattern: String;
  TestOutput: String;

procedure GetChildFiles(Path: String; FilePattern: String);
var
  FileInfo: SearchRec;
begin
  FileCount := 0;

  FindFirst(Path + '\' + FilePattern, Archive, FileInfo);
  while DosError = 0 do
  begin
    if (FileInfo.Attr and Directory) = 0 then
    begin
      if FileCount <= MaxFiles then
      begin
        Inc(FileCount);
        SubFiles[FileCount] := FileInfo.Name;
      end
      else
        Break; {Stop if maximum file count is exceeded}
    end;
    FindNext(FileInfo);
  end;
end;

procedure GetChildFolders(Path: String);
var
  FolderInfo: SearchRec;
begin
  FolderCount := 0;

  {Add '..' for parent directory if not at root}
  if Length(Path) > 3 then
  begin
    Inc(FolderCount);
    SubFolders[FolderCount] := '..';
  end;

  FindFirst(Path + '\*.*', Directory, FolderInfo);
  while DosError = 0 do
  begin
    if (FolderInfo.Attr and Directory) <> 0 then
    begin
      if (FolderInfo.Name <> '.') and (FolderInfo.Name <> '..') then
      begin
        if FolderCount <= MaxFolders then
        begin
          Inc(FolderCount);
          SubFolders[FolderCount] := FolderInfo.Name
        end
        else
          Break; {Stop if maximum folder count is exceeded}
      end;
    end;
    FindNext(FolderInfo);
  end;
end;

procedure DrawFileList(var TargetList: TextboxType; HighLightActive, FullRedraw: Boolean);
var
  I, Counter, TotalItems, ListStartPos, ListSelection: Integer;
  x1, y1, x2, y2, YOffset: Integer;
  ItemText: String;
begin
  if TargetList.MaxLen = FileList then
  begin
    TotalItems := FileCount;
    ListStartPos := FileListStartPos;
    ListSelection := FileListSelection;
  end
  else
  begin
    TotalItems := FolderCount;
    ListStartPos := FolderListStartPos;
    ListSelection := FolderListSelection;
  end;

  x1 := TargetList.Pos.Left + 2;
  y1 := TargetList.Pos.Top + 3;
  x2 := TargetList.Pos.Left + TargetList.Pos.Width - 2;
  y2 := TargetList.Pos.Top + 15;
  YOffset := ((ListSelection - ListStartPos) * 12);

  {Full redraw}
  if FullRedraw then
  begin
    Counter := 0;
    for I := ListStartPos to ListStartPos + MaxVisibleItems do
    begin
      if I <= TotalItems then
      begin
        if TargetList.MaxLen = FileList then
          ItemText := SubFiles[I]
        else
          ItemText := SubFolders[I];

        {Highlight active selected item}
        if (I = ListSelection) and (ActiveList = TargetList.MaxLen) then
        begin
          {Draw highlighted item}
          SetFillStyle(SolidFill, Theme.Select);
          Bar(x1, y1 + (Counter * 12), x2, y2 + (Counter * 12));
          FontPrint(ItemText, x1 + 3, y1 + 2 + (Counter * 12), Theme.SelectText, FontHeading);
        end
        else
        begin
          {Draw normal item}
          FontPrint(ItemText, x1 + 3, y1 + 2 + (Counter * 12), Theme.TextboxText, FontHeading);
        end;

        Inc(Counter);
      end;
    end;
  end
  else
  begin
    {Not a full redraw, only draw the selected item}
    if HighLightActive and (ActiveList = TargetList.MaxLen) then
    begin
      SetFillStyle(SolidFill, Theme.Select);
      Bar(x1, y1 + YOffset, x2, y2 + YOffset);
      FontPrint(SubFiles[ListSelection], x1 + 3, y1 + 2 + YOffset, Theme.SelectText, FontHeading);
    end
    else
    begin
      SetFillStyle(SolidFill, Theme.Textbox);
      Bar(x1, y1 + YOffset, x2, y2 + YOffset);
      FontPrint(SubFiles[ListSelection], x1 + 3, y1 + 2 + YOffset, Theme.TextboxText, FontHeading);
    end;
  end;
end;

function FileSelect(DefaultPattern: string): string;
var
  winFileSelect: WindowType;
  txtDrive, txtPattern: TextboxType;
  btnSelect, btnCancel: ButtonType;
  btnFilePrev, btnFileNext: ButtonType;
  btnFolderPrev, btnFolderNext: ButtonType;
  txtPatternText, txtDriveText: string;
  Drive, OriginalPath, Path, Pattern: string;
  Counter, I: Integer;
  Key: string;
  ClickedX, ClickedY, ClickedItem, RedrawNeeded: Integer;
begin
  {Start out with contents of current directory}
  GetDir(0, OriginalPath);
  Path := OriginalPath;
  Drive := Copy(Path, 1, 1);
  Pattern := DefaultPattern;
  txtDriveText := Drive;
  txtPatternText := DefaultPattern;
  FolderListStartPos := 1;
  FileListStartPos := 1;

  {ObjSetSize(winFileSelect.Pos, sizeCenter, sizeCenter, 468, 265);}
  winFileSelect.Init(sizeCenter, sizeCenter, 468, 265);
  txtPattern.Init(101, winFileSelect.Pos.Top + 28, 150, sizeDefault);
  txtDrive.Init(272, winFileSelect.Pos.Top + 28, 150, sizeDefault);
  txtPattern.Init(101, winFileSelect.Pos.Top + 28, 150, sizeDefault);
  txtDrive.Init(272, winFileSelect.Pos.Top + 28, 150, sizeDefault);
  txtFileList.Init(101, winFileSelect.Pos.Top + 71, 150, 180);
  txtFolderList.Init(272, winFileSelect.Pos.Top + 71, 150, 180);
  btnSelect.Init(448, winFileSelect.Pos.Top + 28, sizeDefault, sizeDefault, HotkeySymbol + 'Select');
  btnCancel.Init(448, winFileSelect.Pos.Top + 58, sizeDefault, sizeDefault, HotkeySymbol + 'Cancel');
  btnFilePrev.Init(253, txtFileList.Pos.Top, 14, 89, '<');
  btnFileNext.Init(253, txtFileList.Pos.Top + 91, 14, 89, '>');
  btnFolderPrev.Init(424, txtFolderList.Pos.Top, 14, 89, '<');
  btnFolderNext.Init(424, txtFolderList.Pos.Top + 91, 14, 89, '>');

  {These are used in File.DrawList to differentiate lists... It's a dirty hack, but works}
  txtFileList.MaxLen := FileList;
  txtFolderList.MaxLen := FolderList;

  MouseHide;
  ObjDrawWin(winFileSelect);
  ObjDrawTxt(txtPattern, txtPatternText, False);
  ObjDrawTxt(txtDrive, txtDriveText, False);
  ObjDrawTxt(txtFileList, '', False);
  ObjDrawTxt(txtFolderList, '', False);
  ObjDrawBtn(btnSelect, False);
  ObjDrawBtn(btnCancel, False);
  ObjDrawBtn(btnFilePrev, False);
  ObjDrawBtn(btnFileNext, False);
  ObjDrawBtn(btnFolderPrev, False);
  ObjDrawBtn(btnFolderNext, False);
  FontPrint(HotkeySymbol + 'Pattern:', 101, winFileSelect.Pos.Top + 14, Theme.WindowText, FontNormal);
  FontPrint(HotkeySymbol + 'Drive:', 272, winFileSelect.Pos.Top + 14, Theme.WindowText, FontNormal);
  FontPrint(HotkeySymbol + 'Files:', 101, winFileSelect.Pos.Top + 57, Theme.WindowText, FontNormal);
  FontPrint('F' + HotkeySymbol + 'olders:', 272, winFileSelect.Pos.Top + 57, Theme.WindowText, FontNormal);
  MouseShow;

  GetChildFiles(Path, Pattern);
  GetChildFolders(Path);
  DrawFileList(txtFileList, True, True);
  DrawFileList(txtFolderList, False, True);

  repeat
    Key := GetKey;

    if ObjBtnClick(btnSelect) or (Key = KeyAltS) or (Key = KeyEnter) then
    begin
      FileSelect := '';
      Break;
    end;

    if ObjBtnClick(btnCancel) or (Key = KeyAltC) or (Key = KeyEscape) then
    begin
      FileSelect := '';
      Break;
    end;

  until False;
end;

begin
  TestOutput := FileSelect('*.txt');
  
  {Further logic for drawing lists, handling user input, etc.}
end.