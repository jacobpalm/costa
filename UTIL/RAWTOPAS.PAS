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
		IconFile: String[8];
		PauseOnExit: Boolean;
		Left, Top: Integer;
	end;

procedure ImageConvert;
var
	F: Text;
	outputfile: file;
	Col, X, Y: Integer;
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
	if MaxAvail < ImageSize then
	begin
			CloseGraph;
			Writeln('Out of memory');
			Halt(1);
	end;
	GetMem(P, Size);

	FindFirst('..\DATA\IMAGES\*.RAW', Archive, DirInfo);
	while DosError = 0 do
	begin
		FSplit(DirInfo.Name, FDir, FName, FExt);

		Assign(F, '..\DATA\IMAGES\' + DirInfo.Name);
		FileMode := 0;
		{$I-}
		Reset(F);
		{$I+}
		if IOResult <> 0 then
		begin
			CloseGraph;
			Writeln('Error reading raw file: ', '..\DATA\IMAGES\' + DirInfo.Name);
			Halt(1);
		end;

		for X := 0 to 31 do
		begin
			for Y := 0 to 31 do
			begin
				Read(F, Col);
				PutPixel(X, Y, Col);
			end;
		end;

		Close(F);

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
			FileMode := 0;
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
	F: Text;
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

		Assign(F, '..\DATA\THEMES\' + DirInfo.Name);
		FileMode := 0;
		{$I-}
		Reset(F);
		{$I+}

		FillChar(ThemeAuthor, SizeOf(ThemeAuthor), 0);
		FillChar(ThemeName, SizeOf(ThemeName), 0);
		FillChar(Theme, SizeOf(Theme), 0);
		TempRead := '';

		{Author}
		ReadLn(F, TempRead);
		if Length(TempRead) > SizeOf(ThemeAuthor) then
			ThemeAuthor := Copy(TempRead, 1, SizeOf(ThemeAuthor))
		else
			ThemeAuthor := TempRead;

		{Name}
		ReadLn(F, TempRead);
		if Length(TempRead) > SizeOf(ThemeName) then
			ThemeName := Copy(TempRead, 1, SizeOf(ThemeName))
		else
			ThemeName := TempRead;

		ReadLn(F, Thm.Desk);
		ReadLn(F, Thm.DeskText);
		ReadLn(F, Thm.Win);
		ReadLn(F, Thm.WinText);
		ReadLn(F, Thm.Btn);
		ReadLn(F, Thm.Txt);
		ReadLn(F, Thm.TxtText);
		ReadLn(F, Thm.Light);
		ReadLn(F, Thm.Shadow);
		ReadLn(F, Thm.Title);
		ReadLn(F, Thm.TitleText);
		ReadLn(F, Thm.Sel);
		ReadLn(F, Thm.SelText);

		Close(F);

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
	F: Text;
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

		Assign(F, '..\DATA\CONFIG\'+FName+'.RAW');
		FileMode := 0;
		{$I-}
		Reset(F);
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

		ReadLn(F, DesklinkCount);
		Writeln('There are ', DesklinkCount, ' desklinks in this file.');
		BlockWrite(OutputFile, DesklinkCount, SizeOf(DesklinkCount));
		if DesklinkCount > 0 then
		begin
			for i := 1 to DesklinkCount do
			begin
				Writeln('Processing desklink ', i, '...');
				FillChar(DeskLink, SizeOf(DeskLinkType), 0);
				ReadLn(F, DeskLink.Caption);
				ReadLn(F, DeskLink.FileName);
				ReadLn(F, DeskLink.Path);
				ReadLn(F, DeskLink.Parameters);
				ReadLn(F, DeskLink.IconFile);
				ReadLn(F, PauseValue);
				DeskLink.PauseOnExit := PauseValue <> 0;
				ReadLn(F, DeskLink.Left);
				ReadLn(F, DeskLink.Top);

				BlockWrite(OutputFile, DeskLink, SizeOf(DeskLink));
			end;
		end;

		Close(F);
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