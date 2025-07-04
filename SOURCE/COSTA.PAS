program costa_launcher;

{ The Costa GUI launcher
	Runs DESKTOP.EXE and any external programs requested by the desktop.
	This allows the desktop to exit and memory to be freed while external
	programs are run.
	Written using Borland Turbo Pascal 7.01
}

{ Set stack to minimal size }
{$M 1536, 0, 0}

uses
	DOS;

const
	costa_exe     = 'COSTA.EXE';
	desktop_exe   = 'DESKTOP.EXE';
	run_dat       = 'DATA\RUN.DAT';
	continuestr   = 'Press Enter to continue...';

var
	current_dir   : DirStr;
	sresults      : SearchRec;
	file_name     : TEXT;
	run_command   : ComStr;
	run_path      : DirStr;
	run_params    : ComStr;
	run_pause     : CHAR;

{ Run an external program - handle errors }
procedure RunProgram(command, params: ComStr; path: DirStr; pause: Char);
begin

	{$IFDEF DEBUG}
		Writeln('Changing path to ', path);
		Writeln('Running program ', command);
		Writeln('With parameters ', path);
		Write(continuestr);
		Readln;
	{$ENDIF}

	if Length(path) > 0 then
	begin
		chdir(path);
	end
	else
	begin
		chdir(current_dir);
	end;

	SwapVectors;
	Exec(command, params);
	SwapVectors;

	{ Low memory condition }
	if DosError = 8 then
	begin
		Writeln('Out of memory.');
		pause := '1';
		{ If desktop can't be launched, exit }
		if command = desktop_exe then
			Halt(1);
	end;

	{ Wait for keypress before returning? }
	if pause = '1' then
	begin
		Writeln;
		Write(continuestr);
		Readln;
	end;
end; { RunProgram }


begin
	{ Low byte of DosVersion contains major DOS version.
		This program will actually run on DOS 3.0, but the other
		included programs won't, so might as well check here }
	if Lo(DosVersion) < 4 then
	begin
		Writeln('DOS 4+ required.');
		Halt(1);
	end;

	{ Retrieve path of self from paramstr, used later on to find relative paths regardless
		of current path when this program was executed }
	current_dir := ParamStr(0);

	{ Remove last backslash and name of this executable, leaving only path }
	{ 13 = max 8.3 filename lenght 12 including the dot, plus a backslash }
	Delete(current_dir, pos('\' + costa_exe, current_dir), 13);

	{$IFDEF DEBUG}
		Writeln('Path to Costa is ', current_dir);
		Write(continuestr);
		Readln;
	{$ENDIF}

	{ Verify that desktop exe exists in same path as this executable }
	FindFirst(current_dir + '\' + desktop_exe, Archive, sresults);
	if DosError > 0 then
	begin
		Writeln(desktop_exe + ' not found.');
		Halt(1);
	end;

	while True do
	begin

		{ Run the desktop }
		RunProgram(desktop_exe, current_dir, '', '0');
		{ Exit code 1 means exit }
		if DosExitCode = 1 then
			halt(0);

		{ If run.dat exists, run it and delete it }
		FindFirst(current_dir + '\' + run_dat, Archive, sresults);
		if DosError > 0 then
			Continue;

		{ Open file, read data and delete file }
		Assign(file_name, current_dir + '\' + run_dat);
		Reset(file_name);
		Readln(file_name, run_command);
		Readln(file_name, run_params);
		Readln(file_name, run_path);
		Read(file_name, run_pause);
		Erase(file_name);
		Close(file_name);

		{ Run program - obviously }
		RunProgram(run_command, run_params, run_path, run_pause)

	end; { main loop }

end.
