PROGRAM costa_launcher;

{ The Costa GUI launcher
	Runs DESKTOP.EXE and any external programs requested by the desktop.
	This allows the desktop to exit and memory to be freed while external
	programs are run.
	Written using Borland Turbo Pascal 7.01
}

{ Set stack to minimal size }
{$M 1536, 0, 0}

USES
	DOS;

CONST
	costa_exe     = 'COSTA.EXE';
	desktop_exe   = 'DESKTOP.EXE';
	run_dat       = 'DATA\TEMP\RUN.DAT';

VAR
	current_dir   : PathStr;
	sresults      : SearchRec;
	file_name     : TEXT;
	run_command   : ComStr;
	run_path      : PathStr;
	run_params    : ComStr;
	run_pause     : CHAR;

{ Run an external program - handle errors }
PROCEDURE RunProgram(command, params: ComStr; path: PathStr; pause: CHAR);
BEGIN

	chdir(path);

	SwapVectors;
	Exec(command, params);
	SwapVectors;

	{ Low memory condition }
	IF DosError = 8 THEN
	BEGIN
		Writeln('Out of memory.');
		pause := '1';
		{ If desktop can't be launched, exit }
		IF command = desktop_exe THEN
			Halt(1);

	END;

	{ Wait for keypress before returning? }
	IF pause = '1' THEN
	BEGIN
		Writeln;
		Write('Press Enter to continue...');
		Readln;
	END;
END; { RunProgram }


BEGIN
	{ Low byte of DosVersion contains major DOS version.
		This program will actually run on DOS 3.0, but the other
		included programs won't, so might as well check here }
	IF Lo(DosVersion) < 4 THEN
	BEGIN
		Writeln('DOS 4+ required.');
		Halt(1);
	END;

	{ Retrieve path of self from paramstr, used later on to find relative paths regardless
		of current path when this program was executed }
	current_dir := ParamStr(0);

	{ Remove last backslash and name of this executable, leaving only path }
	{ 13 = max 8.3 filename lenght 12 including the dot, plus a backslash }
	Delete(current_dir, pos('\' + costa_exe, current_dir), 13);

	{ Verify that desktop exe exists in same path as this executable }
	FindFirst(current_dir + '\' + desktop_exe, Archive, sresults);
	IF DosError > 0 THEN
	BEGIN
		Writeln(desktop_exe + ' not found.');
		Halt(1);
	END;

	WHILE True DO
	BEGIN

		{ Run the desktop }
		RunProgram(desktop_exe, current_dir, '', '0');
		{ Exit code 1 means exit }
		IF DosExitCode = 1 THEN
			halt(0);

		{ If run.dat exists, run it and delete it }
		FindFirst(current_dir + '\' + run_dat, Archive, sresults);
		IF DosError = 0 THEN
		BEGIN
			{ Open file, read data and delete file }
			Assign(file_name, current_dir + '\' + run_dat);
			Reset(file_name);
			Readln(file_name, run_path);
			Readln(file_name, run_command);
			Readln(file_name, run_params);
			Read(file_name, run_pause);
			Erase(file_name);
			Close(file_name);

			{ Run program - obviously }
			RunProgram(run_command, run_path, run_params, run_pause)
		END;

	END; { main loop }

END.
