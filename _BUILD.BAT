@ECHO OFF
REM The Costa Shell build batch file
REM Assumes:
REM   - Costa source is located in C:\COSTA
REM   - Turbo Pascal 7.x is located in C:\TP\BIN

REM Turbo Pascal compiler switches used:
REM -B            = full build, including units
REM -$D-          = disable debug
REM -$E-          = disable 80x87 emulation
REM -$L-          = disable local debug symbols
REM -U, -I and -O = specify path to source files
REM -E            = specify path to produced EXE/TPU

CD C:\COSTA
DEL *.TPU
FOR %%F IN (SOURCE\*.PAS) DO C:\TP\BIN\TPC -B -$D- -$E- -$L- %%F -USOURCE -ISOURCE -OSOURCE -EC:\COSTA

ECHO.
