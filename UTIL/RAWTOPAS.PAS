program RAWTOBIN;

uses
    Graph, Crt, Dos;

type
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

    DeskLinkType = record
        Caption: String[25];
        FileName: String[50];
        Path: String[50];
        Parameters: String[50];
        ImageFile: String[8];
        PauseOnExit: Boolean;
        Left, Top: Integer;
    end;

procedure ImageConvert;
var
    f: Text;
    outputfile: file;
    col, x, y: Integer;
    GraphDriver: Integer;
    GraphMode: Integer;
    ErrorCode: Integer;
    FileName: String;
    Size: Word;
    P, TestP: Pointer;
    DirInfo: SearchRec;
    FPath: PathStr;
    FDir: DirStr;
    FName: NameStr;
    FExt: ExtStr;
begin
    GraphDriver := EGA;
    GraphMode := EGAHI;
    InitGraph(GraphDriver, GraphMode, 'C:\COSTA');
    ErrorCode := GraphResult;
    if ErrorCode <> GrOk then
    begin
        CloseGraph;
        Writeln('Graphics error: ', GraphErrorMsg(ErrorCode));
        Halt(1);
    end;

    FindFirst('..\DATA\IMAGES\*.RAW', Archive, DirInfo);    
    while DosError = 0 do
    begin
        FSplit(DirInfo.Name, FDir, FName, FExt);

        Assign(f, '..\DATA\IMAGES\' + DirInfo.Name);
        {$I-}
        Reset(f);
        {$I+}

        for x := 0 to 31 do
        begin
            for y := 0 to 31 do
            begin
                Read(f, col);
                PutPixel(x, y, col);
            end;
        end;

        Close(f);

        Size := ImageSize(0, 0, 31, 31);
        GetMem(P, Size);
        GetImage(0, 0, 31, 31, P^);

        Assign(outputfile, '..\DATA\IMAGES\'+FName+'.BIN');
        {$I-}
        Rewrite(outputfile, 1);
        {$I+}
        if IOResult <> 0 then
        begin
            Writeln('Error creating output file.');
            CloseGraph;
            Halt(1);
        end;
        BlockWrite(outputfile, P^, Size);
        Close(outputfile);

        {IFDEF DEBUG}
            {Test reading the image back}
            Assign(outputfile, '..\DATA\IMAGES\'+FName+'.BIN');
            {$I-}
            Reset(outputfile, 1);
            {$I+}
            if IOResult <> 0 then
            begin
                Writeln('Error opening output file for reading.');
                CloseGraph;
                Halt(1);
            end;
            Size := ImageSize(0, 0, 31, 31);
            GetMem(TestP, Size);
            BlockRead(outputfile, TestP^, Size);
            Close(outputfile);

            {Display the image to verify it was written correctly}
            PutImage(100, 100, TestP^, CopyPut);
        {ENDIF}

        FindNext(DirInfo);
    end;

    CloseGraph;
end;

procedure ThemeConvert;
var
    f: Text;
    OutputFile: File;
    ThemeName: String[25];
    ThemeAuthor: String[25];
    Theme: ThemeType;
    DirInfo: SearchRec;
    FPath: PathStr;
    FDir: DirStr;
    FName: NameStr;
    FExt: ExtStr;
begin
    FindFirst('..\DATA\THEMES\*.RAW', Archive, DirInfo);    
    while DosError = 0 do
    begin
        Write('Processing theme: ', DirInfo.Name, '... ');
        FSplit(DirInfo.Name, FDir, FName, FExt);

        Assign(f, '..\DATA\THEMES\' + DirInfo.Name);
        {$I-}
        Reset(f);
        {$I+}

        FillChar(ThemeAuthor, SizeOf(ThemeAuthor), #32);
        FillChar(ThemeName, SizeOf(ThemeAuthor), #32);
        ReadLn(f, ThemeAuthor);
        ReadLn(f, ThemeName);
        ReadLn(f, Theme.Desktop);
        ReadLn(f, Theme.DesktopText);
        ReadLn(f, Theme.Window);
        ReadLn(f, Theme.WindowText);
        ReadLn(f, Theme.Button);
        ReadLn(f, Theme.Textbox);
        ReadLn(f, Theme.TextboxText);
        ReadLn(f, Theme.Light);
        ReadLn(f, Theme.Shadow);
        ReadLn(f, Theme.TitleBar);
        ReadLn(f, Theme.TitleBarText);
        ReadLn(f, Theme.Select);
        ReadLn(f, Theme.SelectText);

        Close(f);

        Assign(OutputFile, '..\DATA\THEMES\'+FName+'.BIN');
        {$I-}
        Rewrite(OutputFile, 1);
        {$I+}
        if IOResult <> 0 then
        begin
            Writeln('Error creating output file.');
            Halt(1);
        end;
        BlockWrite(OutputFile, Theme, SizeOf(ThemeType));
        BlockWrite(OutputFile, ThemeAuthor, SizeOf(ThemeAuthor));
        BlockWrite(OutputFile, ThemeName, SizeOf(ThemeName));
        Close(OutputFile);

        Writeln('[OK]');

        FindNext(DirInfo);
    end;
end;

procedure DesklinkConvert;
var
    f: Text;
    OutputFile: File;
    DeskLink: DeskLinkType;
    DesklinkCount: Integer;
    i: Integer;
    PauseValue: Integer;
    DirInfo: SearchRec;
    FPath: PathStr;
    FDir: DirStr;
    FName: NameStr;
    FExt: ExtStr;
begin
    FindFirst('..\DATA\CONFIG\DESKLNK?.DAT', Archive, DirInfo);    
    while DosError = 0 do
    begin
        Write('Processing desktop file: ', DirInfo.Name, '... ');
        FSplit(DirInfo.Name, FDir, FName, FExt);

        Assign(f, '..\DATA\CONFIG\'+FName+'.RAW');
        {$I-}
        Reset(f);
        {$I+}
        if IOResult <> 0 then
        begin
            Writeln('Error reading raw file.');
            Halt(1);
        end;
        
        Assign(OutputFile, '..\DATA\CONFIG\'+FName+'.BIN');
        Writeln('..\DATA\CONFIG\'+FName+'.BIN');
        {$I-}
        Rewrite(OutputFile, 1);
        {$I+}
        if IOResult <> 0 then
        begin
            Writeln('Error writing to output file.');
            Halt(1);
        end;

        ReadLn(f, DesklinkCount);
        Writeln('There are ', DesklinkCount, ' desklinks in this file.');
        BlockWrite(OutputFile, DesklinkCount, SizeOf(DesklinkCount));
        if DesklinkCount > 0 then
        begin
            for i := 1 to DesklinkCount do
            begin
                Writeln('Processing desklink ', i, '...');
                FillChar(DeskLink, SizeOf(DeskLinkType), 0);
                ReadLn(f, DeskLink.Caption);
                ReadLn(f, DeskLink.FileName);
                ReadLn(f, DeskLink.Path);
                ReadLn(f, DeskLink.Parameters);
                ReadLn(f, DeskLink.ImageFile);
                ReadLn(f, PauseValue);
                DeskLink.PauseOnExit := PauseValue <> 0;
                ReadLn(f, DeskLink.Left);
                ReadLn(f, DeskLink.Top);
                
                BlockWrite(OutputFile, DeskLink, SizeOf(DeskLink));
            end;
        end;
        
        Close(f);
        Close(OutputFile);

        Writeln('[OK]');

        FindNext(DirInfo);
    end;
end;

begin
    DeskLinkConvert;
end.