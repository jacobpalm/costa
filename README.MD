# The Costa GUI
Costa is a graphical user interface (GUI), designed to run on top of the
command line as a shell.

The low system requirements make Costa especially useful for older machines,
which are also the machines that typically run the MS-DOS operating system.

![The Costa GUI](https://costa.jacobpalm.dk/assets/img/screenshots/aboutbox.png)

## System requirements
Costa is designed for MS-DOS, but tested with PC-DOS, DR-DOS, FreeDOS, 
Novell DR Multiuser DOS and DOSBox as well. In theory it should run on any
IBM compatible system with:

  * A 286 or better CPU (386 recommended)
  * EGA (256KB or more VRAM required) or VGA graphics (any VGA compatible
    card should do)
  * A recommended minimum of 200 KB available memory while running Costa.
    When running external programs or games, Costa will exit first and then
    reload after, taking no memory from your other programs.
  * MS-DOS 4.0 or newer, or a compatible operating system

Although not required, a 386 or better CPU is recommended, as well as disk
caching software (SmartDrive or similar) when running on older machines.
Costa uses the path defined in the TEMP environment variable in AUTOEXEC.BAT
for temporary file storage, so it is possible to use a RAM disk if desired.
If TEMP is not defined, Costa will use the path where it is located.

## Further information
See the included documentation for more information, or visit the homepage
of Costa at
  http://costa.jacobpalm.dk
  
## Icons and themes always welcome!
If you have made any icons you would like to see included with Costa, or
perhaps a nifty theme, feel free to drop me a message. I am always looking
to add more to Costa, and credit will of course be given! 

## Using this code
Most of the code has been written using Visual Basic for DOS (VBDOS). One
exception is the main launcher which stays in memory when running external
programs (COSTA.EXE) - it is written in Pascal to keep the size to a minimum.

When opening project files (.MAK), use the /L parameter for all project files
like so:

```
VBDOS.EXE DESKTOP.MAK /L
```

This will cause VBDOS to load the libraries neccesary for Costa to work.
If you get an error relating to "CALL ABSOLUTE" or "CALL INTERRUPT", you have 
probably not used this parameter when starting VBDOS.

COSTA.PAS is written using Borland Turbo Pascal, but should be compatible
with Microsoft QuickPascal as well - although this has not been fully tested.

The source code and build script assume the following:
  * That the source code has been extracted/cloned to C:\COSTA (this path is
    only required for development, once built Costa will run from any path)
  * That Visual Basic for DOS is installed to C:\VBDOS, in a flat structure -
    that is, all files placed in the folder directly, including libraries and
    include files
  * That QuickPascal is installed in C:\TP using default folder structure
    (compiler placed in the BIN subdirectory of that path).

## Building Costa
To build Costa, run the build script from the command line:

```
_BUILD.BAT
```

This will compile all modules to object files, and call the linker for each
individual executable. In the source folder, a .LNK file exists for each
executable, with parameters for the linker. These can be modified as needed,
following the standard syntax for Microsofts Segmented Executable Linker.

When compiling directly from the IDE, make sure to turn on run-time error
checking, as well as 286 optimizations.
