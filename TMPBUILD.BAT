@echo off
del calc.exe
echo.
tpc -m source\calc.pas -E. -USOURCE -ISOURCE -OSOURCES
