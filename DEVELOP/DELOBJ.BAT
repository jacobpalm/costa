@ECHO OFF
REM Simply deletes leftover .OBJ files from the compilation process

DEL ..\*.OBJ >nul
DEL ..\SCRIPTER\*.OBJ >nul

DEL *.OBJ >nul
DEL SCRIPTER\*.OBJ >nul
