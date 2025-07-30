@echo off
if "%1"=="" goto noparams

call buildlib.bat

del %1.exe
tpc -m source\%1.pas -E. -USOURCE -ISOURCE -OSOURCE
if errorlevel 1 goto end
echo.
goto afterbuild

:noparams
echo You must specify the name of the file to compile, without path or extension.
goto end

:afterbuild
choice /C:YN Run %1 now?
if errorlevel 2 goto end
%1.exe

:end
echo.
