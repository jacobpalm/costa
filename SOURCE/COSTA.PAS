program CostaLauncher;

{The Costa GUI launcher
 Runs DESKTOP.EXE and any external programs requested by the desktop.
 This allows the desktop to exit and memory to be freed while external
 programs are run.
}

{Set stack to minimal size}
{$M 1536, 0, 0}

uses
	DOS;

const
	CostaExe    = 'COSTA.EXE';
	DesktopExe  = 'DESKTOP.EXE';
	RunFile     = 'DATA\RUN.DAT';
	ContinueStr = 'Press Enter to continue...';

type
	TLink = record
		Caption: String[20];
		FileName: PathStr;
		Path: DirStr;
		Parameters: ComStr;
		ImageFile: String[8];
		PauseOnExit: Boolean;
		Left, Top: Integer;
	end;

var
	CostaPath: DirStr;
	RunLink:   TLink;

{Run an external program, handle errors if it fails}
procedure RunProgram;
var
	PauseOnExit: Boolean;
begin
	{$IFDEF DEBUG}
		Writeln('Changing path to ', RunLink.Path);
		Writeln('Running program ', RunLink.FileName);
		Writeln('With parameters ', RunLink.Parameters);
		Write(ContinueStr);
		Readln;
	{$ENDIF}

	if Length(RunLink.Path) > 0 then
		ChDir(RunLink.Path)
	else
		ChDir(CostaPath);
	PauseOnExit := RunLink.PauseOnExit;

	SwapVectors;
	Exec(RunLink.FileName, RunLink.Parameters);
	SwapVectors;

	{Low memory condition}
	if DosError = 8 then
	begin
		Writeln('Out of memory.');
		PauseOnExit := True;
		{If desktop can't be launched, exit}
		if RunLink.FileName = DesktopExe then
			Halt(1);
	end;

	{Wait for keypress before returning?}
	if PauseOnExit then
	begin
		Writeln;
		Write(ContinueStr);
		Readln;
	end;
end; {RunProgram}

{Main program}
var
	SResult: SearchRec;
	f: file;
begin
	{Low byte of DosVersion contains major DOS version.
		This program will actually run on DOS 3.0, but the other
		included programs won't, so might as well check here}
	if Lo(DosVersion) < 4 then
	begin
		Writeln('DOS 4+ required.');
		Halt(1);
	end;

	{Retrieve path of self from paramstr, used later on to find relative paths regardless
		of current path when this program was executed}
	CostaPath := ParamStr(0);

	{Remove last backslash and name of this executable, leaving only path}
	{13 = max 8.3 filename lenght 12 including the dot, plus a backslash}
	Delete(CostaPath, pos('\' + CostaExe, CostaPath), 13);

	{$IFDEF DEBUG}
		Writeln('Path to Costa is ', CostaPath);
		Write(ContinueStr);
		Readln;
	{$ENDIF}

	{Verify that desktop exe exists in same path as this executable}
	FindFirst(CostaPath + '\' + DesktopExe, Archive, SResult);
	if DosError > 0 then
	begin
		Writeln(DesktopExe + ' not found.');
		Halt(1);
	end;

	while True do
	begin
		{Run the desktop}
		FillChar(RunLink, SizeOf(RunLink), 0);
		RunLink.FileName := DesktopExe;
		RunProgram;

		{Exit code 1 from desktop means exit}
		if DosExitCode = 1 then
			halt(0);

		{If RunFile exists, read it, delete it and run the program specified in it}
		FindFirst(CostaPath + '\' + RunFile, Archive, SResult);
		if DosError > 0 then
			Continue;

		{Open file, read data and delete file}
		Assign(f, CostaPath + '\' + RunFile);
		{$I-}
		Reset(f, 1);
		{$I+}

		{If there was an error or size doesn't match, continue to next iteration}
		if (IOResult <> 0) or (FileSize(f) <> SizeOf(RunLink)) then
		begin
			{$IFDEF DEBUG}
				Writeln('Error reading run file: ', RunFile);
				WriteLine('File size: ', FileSize(f), ' bytes, expected: ', SizeOf(RunLink), ' bytes.');
			{$ENDIF}
			Close(f);
			Continue;
		end;
		BlockRead(f, RunLink, SizeOf(RunLink));
		Erase(f);
		Close(f);

		RunProgram;
	end; {main loop}

end.
