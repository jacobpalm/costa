program RAWTOBIN;

uses
    Graph, Crt, Dos;

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
    If ErrorCode <> GrOk Then
    Begin
        CloseGraph;
        Writeln('Graphics error: ', GraphErrorMsg(ErrorCode));
        Halt(1);
    End;


    FindFirst('DATA\IMAGES\*.RAW', Archive, DirInfo);    
    while DosError = 0 do
    begin
        FSplit(DirInfo.Name, FDir, FName, FExt);

        Assign(f, 'DATA\IMAGES\' + DirInfo.Name);
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

        Assign(outputfile, 'DATA\IMAGES\'+FName+'.BIN');
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

        {Test reading the image back}
        Assign(outputfile, 'DATA\IMAGES\'+FName+'.BIN');
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

        FindNext(DirInfo);
    end;

    ReadKey;
    CloseGraph;
End.