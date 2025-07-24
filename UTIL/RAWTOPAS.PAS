program RAWTOBIN;

uses
	Graph, Crt, Dos;

type
	TTheme = record
		Desktop,
		DeskText,
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
	FDir: DirStr;
	FName: NameStr;
	FExt: ExtStr;
begin
	GraphDriver := EGA;
	GraphMode := EGAHI;
	InitGraph(GraphDriver, GraphMode, '..');
	ErrorCode := GraphResult;
	if ErrorCode <> GrOk then
	begin
		CloseGraph;
		Writeln('Graphics error: ', GraphErrorMsg(ErrorCode));
		Halt(1);
	end;

	Size := ImageSize(0, 0, 31, 31);
	GetMem(P, Size);

	FindFirst('..\DATA\IMAGES\*.RAW', Archive, DirInfo);
	while DosError = 0 do
	begin
		FSplit(DirInfo.Name, FDir, FName, FExt);

		Assign(f, '..\DATA\IMAGES\' + DirInfo.Name);
		{$I-}
		Reset(f);
		{$I+}
		if IOResult <> 0 then
		begin
			CloseGraph;
			Writeln('Error reading raw file: ', '..\DATA\IMAGES\' + DirInfo.Name);
			Halt(1);
		end;

		for x := 0 to 31 do
		begin
			for y := 0 to 31 do
			begin
				Read(f, col);
				PutPixel(x, y, col);
			end;
		end;

		Close(f);

		GetImage(0, 0, 31, 31, P^);

		Assign(outputfile, '..\ICONS\'+FName+'.BIN');
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
			Assign(outputfile, '..\ICONS\'+FName+'.BIN');
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
			FreeMem(TestP, Size);
		{ENDIF}
		FindNext(DirInfo);
	end;
	FreeMem(P, Size);
	CloseGraph;
end;

procedure ThemeConvert;
var
	f: Text;
	OutputFile: File;
	ThemeName: String[20];
	ThemeAuthor: String[20];
	TempRead: string;
	Theme: TTheme;
	DirInfo: SearchRec;
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

		FillChar(ThemeAuthor, SizeOf(ThemeAuthor), 0);
		FillChar(ThemeName, SizeOf(ThemeName), 0);
		FillChar(Theme, SizeOf(Theme), 0);
		TempRead := '';
		
		{Author}
		ReadLn(f, TempRead);
		if Length(TempRead) > SizeOf(ThemeAuthor) then
			ThemeAuthor := Copy(TempRead, 1, SizeOf(ThemeAuthor))
		else
			ThemeAuthor := TempRead;

		{Name}
		ReadLn(f, TempRead);
		if Length(TempRead) > SizeOf(ThemeName) then
			ThemeName := Copy(TempRead, 1, SizeOf(ThemeName))
		else
			ThemeName := TempRead;
		
		ReadLn(f, Thm.Desk);
		ReadLn(f, Thm.DeskText);
		ReadLn(f, Thm.Win);
		ReadLn(f, Thm.WinText);
		ReadLn(f, Thm.Btn);
		ReadLn(f, Thm.Txt);
		ReadLn(f, Thm.TxtText);
		ReadLn(f, Thm.Light);
		ReadLn(f, Thm.Shadow);
		ReadLn(f, Thm.Title);
		ReadLn(f, Thm.TitleText);
		ReadLn(f, Thm.Sel);
		ReadLn(f, Thm.SelText);

		Close(f);

		Assign(OutputFile, '..\THEMES\'+FName+'.BIN');
		{$I-}
		Rewrite(OutputFile, 1);
		{$I+}
		if IOResult <> 0 then
		begin
			Writeln('Error creating output file.');
			Halt(1);
		end;
		BlockWrite(OutputFile, Theme, SizeOf(TTheme));
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
		
		Assign(OutputFile, '..\CONFIG\'+FName+'.BIN');
		Writeln('..\CONFIG\'+FName+'.BIN');
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
	ImageConvert;
	ThemeConvert;
	DeskLinkConvert;
end.