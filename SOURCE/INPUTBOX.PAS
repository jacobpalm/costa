
unit Inputbox;

interface

uses
  Costalib, Strings, Graph, Crt;

function SysInputBox(msgTitle, msgText, msgIcon, msgDefault: string): string;

implementation

function SysInputBox(msgTitle, msgText, msgIcon, msgDefault: string): string;
var
  msgLines: array[1..16] of string;
  msgLineCount, msgTextWidth, i: Integer;
  winInputBox: WindowType;
  txtInput: TextboxType;
  txtInputText: string;
  btnOK, btnCancel: ButtonType;
  imgIcon: ImageType;
  Key: String;
  printLine: Integer;
  tmpStr: string;
  x1, y1, x2, y2: Integer;
  BackgroundSize: Word;
  BackgroundP: Pointer;
begin
  {Strip trailing carriage return}
  if (Length(msgText) > 0) and (msgText[Length(msgText)] = NewLine) then
    Delete(msgText, Length(msgText), 1);

  msgLineCount := 0;
  msgTextWidth := 0;

  {Parse msgText into lines}
  if Pos(NewLine, msgText) = 0 then
  begin
    msgLineCount := 1;
    msgLines[1] := msgText;
    msgTextWidth := FontGetWidth(msgText, FontNormal);
  end
  else
  begin
    while Pos(NewLine, msgText) > 0 do
    begin
      Inc(msgLineCount);
      tmpStr := Copy(msgText, 1, Pos(NewLine, msgText) - 1);
      msgLines[msgLineCount] := tmpStr;

      if FontGetWidth(tmpStr, FontNormal) > msgTextWidth then
        msgTextWidth := FontGetWidth(tmpStr, FontNormal);

      Delete(msgText, 1, Pos(NewLine, msgText));
    end;
    {Remaining text}
    Inc(msgLineCount);
    msgLines[msgLineCount - 1] := msgText;
    if FontGetWidth(msgText, FontNormal) > msgTextWidth then
      msgTextWidth := FontGetWidth(msgText, FontNormal);
  end;


  winInputBox.Pos.Width := msgTextWidth + 76;
  if winInputBox.Pos.Width < 194 then
    winInputBox.Pos.Width := 194;
  ObjSetSize(winInputBox.Pos, sizeCenter, sizeCenter, sizeRetain, msgLineCount * 15 + 120);

  ObjSetSize(txtInput.Pos,
              winInputBox.Pos.Left + 12,
              winInputBox.Pos.Top + 56 + (15 * msgLineCount),
              winInputBox.Pos.Width - 24,
              22);
  txtInputText := msgDefault;

  ObjSetSize(btnOK.Pos, winInputBox.Pos.Left + winInputBox.Pos.Width - 182, txtInput.Pos.Top + 30, 80, 22);
  btnOK.Caption := HotkeySymbol + 'OK';

  ObjSetSize(btnCancel.Pos, winInputBox.Pos.Left + winInputBox.Pos.Width - 92, btnOK.Pos.Top, 80, 22);
  btnCancel.Caption := HotkeySymbol + 'Cancel';

  if Length(msgIcon) > 0 then
  begin
    imgIcon.Pos.Left := winInputBox.Pos.Left + 12;
    imgIcon.Pos.Top := winInputBox.Pos.Top + 15;
    imgIcon.ImageFile := msgIcon;
    if msgLineCount > 1 then
      Inc(imgIcon.Pos.Top, 5);
  end;

  MouseHide;
  x1 := winInputBox.Pos.Left;
  y1 := winInputBox.Pos.Top;
  x2 := winInputBox.Pos.Left + winInputBox.Pos.Width;
  y2 := winInputBox.Pos.Top + winInputBox.Pos.Height;
  BackgroundSize := ImageSize(x1, y1, x2, y2);
  GetMem(BackgroundP, BackgroundSize);
  GetImage(x1, y1, x2, y2, BackgroundP^);

  ObjDrawWin(winInputBox);
  ObjDrawBtn(btnOK, False);
  ObjDrawBtn(btnCancel, False);
  ObjDrawTxt(txtInput, txtInputText, False);

  if Length(msgIcon) > 0 then
    FontPrint(msgTitle, winInputBox.Pos.Left + 53, winInputBox.Pos.Top + 15, Theme.WindowText, 1)
  else
    FontPrint(msgTitle, winInputBox.Pos.Left + 12, winInputBox.Pos.Top + 15, Theme.WindowText, 1);

  y2 := winInputBox.Pos.Top + 17;
  for printLine := 1 to msgLineCount do
  begin
    if (printLine < 2) and (Length(msgIcon) > 0) then
      FontPrint(msgLines[printLine], winInputBox.Pos.Left + 53, y2 + (15 * printLine), Theme.WindowText, 2)
    else
      FontPrint(msgLines[printLine], winInputBox.Pos.Left + 12, y2 + (15 * printLine), Theme.WindowText, 2);
  end;

  FontPrint('I' + HotkeySymbol + 'nput:', txtInput.Pos.Left, txtInput.Pos.Top - 16, Theme.WindowText, FontHeading);

  if Length(msgIcon) > 0 then
    ObjDrawImg(imgIcon);

  MouseShow;

  repeat
    Key := GetKey;

    if ObjBtnClick(btnOK) or (Key = KeyAltO) or (Key = KeyEnter) then
    begin
      SysInputBox := txtInputText;
      Break;
    end;

    if ObjBtnClick(btnCancel) or (Key = KeyAltC) or (Key = KeyEscape) then
    begin
      SysInputBox := '';
      Break;
    end;

    if ObjTxtClick(txtInput) or (Key = KeyAltN) then
      ObjEditTxt(txtInput, txtInputText);

  until False;

  ClearKeyBuffer;
  MouseHide;
  PutImage(x1, y1, BackgroundP^, NormalPut);
  FreeMem(BackgroundP, BackgroundSize);
  MouseShow;
end;

end.