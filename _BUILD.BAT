@echo off
REM Costa GUI build batch file
REM Assumes:
REM   - Costa is located in C:\COSTA
REM   - VBDOS is located in C:\VBDOS in a flat structure (that is, all VBDOS
REM     libaries etc. are in that path directly
REM that path)

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
echo Building desktop object files (desktop)...
C:\VBDOS\BC.EXE C:\COSTA\SOURCE\DESKTOP.BAS /E /X /D /G2 /O /T /C:512;
echo.
echo echo Building desktop object files (config)...
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
echo Building setup object files...
C:\VBDOS\BC.EXE C:\COSTA\SOURCE\SETUP.BAS /E /X /D /G2 /O /T /C:512;
echo.
echo Building calculator object files...
C:\VBDOS\BC.EXE C:\COSTA\SOURCE\CALC.BAS /E /X /D /G2 /O /T /C:512;
echo.
echo.
echo Linking setup...
C:\VBDOS\LINK.EXE @SOURCE\SETUP.LNK
echo.
echo Linking calculator...
C:\VBDOS\LINK.EXE @SOURCE\CALC.LNK
echo.
echo Linking desktop...
C:\VBDOS\LINK.EXE @SOURCE\DESKTOP.LNK
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
echo Removing object files...
DEL C:\COSTA\*.OBJ
echo.
echo Build run finished.
