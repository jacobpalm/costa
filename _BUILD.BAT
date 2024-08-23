@echo off
REM Costa GUI build batch file
REM Assumes:
REM   - Costa is located in C:\COSTA
REM   - VBDOS is located in C:\VBDOS in a flat structure (that is, all VBDOS
REM     libaries etc. are in that path directly
REM   - Turbo Pascal 7.0 is located in C:\TP\BIN

CD C:\COSTA

echo Building library object file...
C:\VBDOS\BC.EXE C:\COSTA\SOURCE\COSTALIB.BAS /E /X /D /G2 /O /T /C:512;
echo .
echo Building file selector object file...
C:\VBDOS\BC.EXE C:\COSTA\SOURCE\FILESEL.BAS /E /X /D /G2 /O /T /C:512;
echo.
echo Building system path object file...
C:\VBDOS\BC.EXE C:\COSTA\SOURCE\SYSPATH.BAS /E /X /D /G2 /O /T /C:512;
echo.
echo Building input box object file...
C:\VBDOS\BC.EXE C:\COSTA\SOURCE\INPUTBOX.BAS /E /X /D /G2 /O /T /C:512;
echo.
echo Building desktop object files (desktop)...
C:\VBDOS\BC.EXE C:\COSTA\SOURCE\DESKTOP.BAS /E /X /D /G2 /O /T /C:512;
echo.
echo Building config utility object files...
C:\VBDOS\BC.EXE C:\COSTA\SOURCE\CONFIG.BAS /E /X /D /G2 /O /T /C:512;
echo.
echo Building theme editor object files...
C:\VBDOS\BC.EXE C:\COSTA\SOURCE\THMEDIT.BAS /E /X /D /G2 /O /T /C:512;
echo.
echo Building Tic Tac Toe object files...
C:\VBDOS\BC.EXE C:\COSTA\SOURCE\TICTAC.BAS /E /X /D /G2 /O /T /C:512;
echo.
echo Building icon editor object files...
C:\VBDOS\BC.EXE C:\COSTA\SOURCE\ICONEDIT.BAS /E /X /D /G2 /O /T /C:512;
echo.
echo Building text viewer object files...
C:\VBDOS\BC.EXE C:\COSTA\SOURCE\TEXTVIEW.BAS /E /X /D /G2 /O /T /C:512;
echo.
echo Building calculator object files...
C:\VBDOS\BC.EXE C:\COSTA\SOURCE\CALC.BAS /E /X /D /G2 /O /T /C:512;
echo.
echo Building Minesweeper object files...
C:\VBDOS\BC.EXE C:\COSTA\SOURCE\MINES.BAS /E /X /D /G2 /O /T /C:512;
echo.
echo.
echo Linking calculator...
C:\VBDOS\LINK.EXE @SOURCE\CALC.LNK
echo.
echo Linking desktop...
C:\VBDOS\LINK.EXE @SOURCE\DESKTOP.LNK
echo.
echo Linking config utility...
C:\VBDOS\LINK.EXE @SOURCE\CONFIG.LNK
echo.
echo Linking icon editor...
C:\VBDOS\LINK.EXE @SOURCE\ICONEDIT.LNK
echo.
echo Linking text viewer...
C:\VBDOS\LINK.EXE @SOURCE\TEXTVIEW.LNK
echo.
echo Linking theme editor...
C:\VBDOS\LINK.EXE @SOURCE\THMEDIT.LNK
echo.
echo Linking tic tac toe...
C:\VBDOS\LINK.EXE @SOURCE\TICTAC.LNK
echo.
echo Linking minesweeper...
C:\VBDOS\LINK.EXE @SOURCE\MINES.LNK
echo.
echo Compiling launcher (COSTA.EXE)...
REM TPC switches
REM d- = disable debug
REM e- = disabel 80x87 emulation
REM i- = disable runtime io checking
REM l- = disable local debug symbols
REM s- = disable stack check     
C:\TP\BIN\TPC -$D- -$E- -$I- -$L- -$S- costa.pas

echo.
echo Removing object and debug files...
DEL C:\COSTA\*.OBJ
DEL C:\COSTA\*.BAK
DEL C:\COSTA\*.DSK
echo.
echo Build run finished.
