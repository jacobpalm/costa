@ECHO OFF

REM This batch file replaces COSTA.EXE from previous versions of the GUI.
REM Instead of having a resident program in memory, occupying about 60 KB
REM RAM, this version only has the batch program in memory, conserving
REM a lot of conventional RAM.

REM This is where the path to Costa is defined.
SET COSTA120=C:\COSTA

IF NOT EXIST %COSTA120%\COSTA120.EXE GOTO ExeNotFound

REM Make sure a mouse driver is loaded. This driver will only load if
REM another mouse driver isn't present.
%COSTA120%\CTMOUSE.COM >NUL

REM Start by launching the desktop. The /BOOT parameter is simply there to
REM prevent the desktop from being launched outside of this batch program,
REM since it wouldn't work if it were (it would just exit whenever a link
REM on the desktop was clicked)
%COSTA120%\COSTA120.EXE /BOOT


:LoopStart

REM If errorlevel is 2 the user wants to run a program
IF ERRORLEVEL = 2 GOTO RunBat

REM If errorlevel is 1 the user wants to exit.
IF ERRORLEVEL = 1 GOTO Exit

REM If we make it here no errorlevel has been set and we can return to the
REM desktop. The /BOOT parameter is no longer neccesary, as Costa is already
REM running.
%COSTA120%\COSTA120.EXE
GOTO LoopStart


:RunBat
REM Run the batch file, delete it and return to the top of the loop. The
REM reason COSTA120.EXE is executed here is to prevent the errorlevel from
REM the external program affecting the errorlevel check above.
CALL %COSTA120%\DATA\TEMP\RUN.BAT
DEL %COSTA120%\DATA\TEMP\RUN.BAT
%COSTA120%\COSTA120.EXE
GOTO LoopStart

:ExeNotFound
ECHO.
ECHO COSTA120.EXE was not found in %COSTA120%.
ECHO.
ECHO Run SETUP.EXE to fix this issue.
ECHO.
SET COSTA120=
GOTO EndOfBAT

:Exit
SET COSTA120=
CD \
CLS
ECHO Thank you for using The Costa Graphical Shell.
ECHO.

:EndOfBAT
