{ The Costa GUI sample application
  By Jacob Palm

  This code demonstrates how to get started with a simple application using
  the Costa library, to create applications the have the look and feel of
  Costa.

  Any application utilizing the Costa library will have COSTALIB.BAS added to
  the project (MAK) file, and will include the COSTALIB.BI file to add the
  neccessary declarations.}

program Sample;

uses
    CostaLib, Crt, Graph;

const
    AppName = 'Sample Application';
    AppVersion = '2.0';
    AppAuthor = 'Jacob Palm';
    ExitText = 'Are you sure you want to exit the sample' + #13 + 'application?';

var
   winSample: WindowType;
   btnAbout, btnExit: ButtonType;
   imgSample: ImageType;
   KeyStr: String;

begin
    {Set window size - center on screen}
    ObjSetSize(winSample.Pos, sizeCenter, sizeCenter, 244, 200);

    {Set button position and size - left, top, width, height}
    ObjSetSize(btnExit.Pos, 545, 2, 92, 22);
    btnExit.Caption := 'E?xit';
    {The ? character determines which letter on the button is underlined.
    This is actually handled by the font routine, and can be used anywhere
    text is printed.}

    {Another button}
    ObjSetSize(btnAbout.Pos, 446, 2, 92, 22);
    btnAbout.Caption := '?About...';
                
    {Create an icon. Only the filename, without extension or path, is set.
    This is because icons are always in the same folder. An icon does not
    use the width or height property, they are always 32x32 pixels.}
    
    imgSample.Pos.Top := winSample.Pos.Top + 34;
    imgSample.Pos.Left := winSample.Pos.Left + 200;
    imgSample.ImageFile := 'CONFIG';

    {Draw the elements on the screen. The mouse does not need to be hidden
    when drawing using Costa routines, they will take care of that
    automatically. You must, however, hide the cursor while using LINE, PSET
    and other built-in graphics statements.}
    
    ObjDrawMenu; {Top menu - default for all Costa apps}

    {App background - not drawn automatically, as some apps may wish to use
    a custom background}
    MouseHide;
    SetFillStyle(SolidFill, Theme.Window);
    Bar(0, 29, 639, 349);
    MouseShow;

    ObjDrawWin(winSample);
    ObjDrawBtn(btnAbout, False);
    ObjDrawBtn(btnExit, False);
    MouseHide;
    FontPrint('Sample text, header font', winSample.Pos.Left + 12, winSample.Pos.Top + 70, Theme.WindowText, FontHeading);
    FontPrint('Sample text, normal font', winSample.Pos.Left + 12, winSample.Pos.Top + 85, Theme.WindowText, FontNormal);
    MouseShow;
    ObjDrawImg(imgSample);

    repeat
        {Fetch any pressed key}
        if KeyPressed then
        begin
            KeyStr := ReadKey;
        end
        else
        begin
            KeyStr := '';
        end;

        {Obj.BtnClick will return True or False (constants declared in
        COSTALIB.BI), and can be used to check if a button is clicked. It
        will also take care of drawing the button in pressed or unpressed
        state.}
        IF ObjBtnClick(btnExit) or (KeyStr = 'x') THEN
        begin
            {Show a messagebox, asking to confirm that the user wants to exit.
            msgQuest is a constant from COSTALIB.BI, used to indicate the
            type of messagebox we want to show (question, error etc.).}
            if SysMsgBox('Exit sample application', ExitText, msgQuest) then
            begin
                CloseGraph;
                Halt;
            end;
        end;

        if ObjBtnClick(btnAbout) or (KeyStr = 'a') then
        begin
          {Use the built-in function for showing an about box - this ensures
          consistency between all applications}
          SysAboutBox(AppName, AppVersion, AppAuthor, 'PROGRAM');
        end;
        
    until False;

end.