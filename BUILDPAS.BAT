@echo off
if "%1"=="" goto noparams

del %1.exe
tpc -m source\%1.pas -E. -USOURCE -ISOURCE -OSOURCE
goto end

:noparams
echo You must specify the name of the file to compile, without path or extension.

:end
echo.
