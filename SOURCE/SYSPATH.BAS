'$INCLUDE: 'SOURCE\SYSPATH.BI'
'$INCLUDE: 'C:\VBDOS\VBDOS.BI'

FUNCTION Sys.Path () AS STRING

	'Uses the program segment prefix (PSP) to retrieve the path of the current
	'executable.
	'After the environment table, which is offset at &H2C, comes a four-byte
	'gap, immediately followed by a ASCIIZ string containing the program path
	'and filename of the currently running program.

	STATIC RetrievedPath$
	
	'If path has already been detected, return it and exit function
	IF LEN(RetrievedPath$) THEN
		Sys.Path = RetrievedPath$
		EXIT FUNCTION
	END IF

	'If running with /DEV parameter, set default path and exit
	IF COMMAND$ = "/DEV" THEN
		RetrievedPath$ = "C:\COSTA\"
		Sys.Path = RetrievedPath$
		EXIT FUNCTION
	END IF

	'Offset of environ in PSP
	CONST EnvOffInPsp = &H2C

	DIM InRegs AS RegType, OutRegs AS RegType

	'MS-DOS function call to retrieve PSP
	InRegs.ax = &H6200
	CALL INTERRUPT(&H21, InRegs, OutRegs)

	'Retrieve PSP segment from result
	PSPSeg% = OutRegs.bx
	EnvironSeg& = 0
	OffSet& = 0
	tmp$ = ""

	'Calculate offset of environment table in PSP
	DEF SEG = PSPSeg%
	EnvironSeg& = 256 * PEEK(EnvOffInPsp + 1) + PEEK(EnvOffInPsp)

	'Switch segment to environment table
	DEF SEG = EnvironSeg&
	
	'Run through environment table until a double null-byte is found, signalling
	'end of table
	WHILE (PEEK(OffSet&) <> 0 OR PEEK(OffSet& + 1) <> 0)
		OffSet& = OffSet& + 1
	WEND

	'Skip four byte gap between environment table and exe path
	OffSet& = OffSet& + 4

	'Retrieve one byte at a time until a NULL byte is found, signalling end of
	'file name and path
	WHILE PEEK(OffSet&) <> 0
		tmp$ = tmp$ + CHR$(PEEK(OffSet&))
		OffSet& = OffSet& + 1
	WEND

	'Reset segment
	DEF SEG

	'Get path up to the last backslash, to filter out the executable name
	DO WHILE INSTR(tmp$, "\")
		RetrievedPath$ = RetrievedPath$ + LEFT$(tmp$, INSTR(tmp$, "\"))
		tmp$ = RIGHT$(tmp$, LEN(tmp$) - INSTR(tmp$, "\"))
	LOOP

	IF NOT RIGHT$(RetrievedPath$, 1) = "\" THEN RetrievedPath$ = RetrievedPath$ + "\"
	Sys.Path = RetrievedPath$

END FUNCTION

