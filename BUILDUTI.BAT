@echo off

cd UTIL

echo Building BASTORAW object file...
C:\VBDOS\BC.EXE BASTORAW.BAS /E /X /D /G2 /O /T /C:512;
echo.
echo Linking BASTORAW...
C:\VBDOS\LINK.EXE @BASTORAW.LNK

del RAWTOPAS.EXE
tpc -m RAWTOPAS.pas
echo.

del *.obj

cd..
