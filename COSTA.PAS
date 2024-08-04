program CostaLauncher;
{$M 1200, 0, 0}
uses
	DOS;
const
	costa_exe     = 'COSTA.EXE';
	desktop_exe   = 'DESKTOP.EXE';
	run_dat       = 'DATA\TEMP\RUN.DAT';
	current_drive = 0;                   { current drive }
var
	current_dir   : STRING;
	sresults      : SearchRec;
	file_name     : TEXT;
	run_command   : STRING;
	run_path      : STRING;
	run_params    : STRING;
	run_pause     : CHAR;

begin
	{GetDir(current_drive, current_dir);}
	current_dir := paramstr(0);
	delete(current_dir, pos('\' + costa_exe, current_dir), 11); { 11 = max 8.3 filename lenght 10 + backslash }
	writeln(current_dir);


	FindFirst(desktop_exe, Archive, sresults);
	if DosError > 0 then
		begin
			writeln(desktop_exe, ' could not be found in the current directory.');
			writeln('Make sure to run Costa from its installation directory.');
			halt(0);
		end;

	while true do
	begin

		{ Run the desktop }
		{I-}
		chdir(current_dir);
		{I+}
		SwapVectors;
		Exec(current_dir + '\' + desktop_exe, '');
		SwapVectors;
		{ Exit code 1 means exit }
		if DosExitCode = 1 Then
			halt(0);

		{ Low memory condition }
		if DosError = 8 then
			begin
				writeln('Not enough memory to run desktop.');
				halt(0);
			end;

		{ If run.dat exists, run it and delete it }
		FindFirst(current_dir + '\' + run_dat, Archive, sresults);
		if DosError = 0 then
			begin
				{ Open file, read data and delete file }
				assign(file_name, current_dir + '\' + run_dat);
				reset(file_name);
				readln(file_name, run_path);
				readln(file_name, run_command);
				readln(file_name, run_params);
				read(file_name, run_pause);
				erase(file_name);

				{$I-}
				chdir(run_path);
				{$I+}
				SwapVectors;
				exec(run_command, run_params);
				SwapVectors;

				if run_pause = '1' then
					begin
						writeln;
						write('Press Enter to continue...');
						readln;
					end;


			end;
	end;

end.
