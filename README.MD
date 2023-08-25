# The Costa GUI
Costa is a graphical user interface (GUI), designed to run on top of the
command line as a shell.

The low system requirements make Costa especially useful for older machines,
which are also the machines that typically run the MS-DOS operating system.

![The Costa GUI](https://costa.jacobpalm.dk/assets/img/screenshots/screen02.png)

## System requirements
Costa is designed for MS-DOS, but tested with PC-DOS, FreeDOS and DOSBox as
well. In theory it should run on any MS-DOS compatible operating system with:

  * A 286 or better CPU
  * EGA (256KB or more VRAM required) or VGA graphics (any compatible card
    should do)
  * A recommended minimum of 200 KB available memory

Although not required, a 386 or better CPU is recommended, as well as disk
caching software (SmartDrive or similar) when running on older machines,
since Costa uses the disk where it is located for temporary storage
(actually, Costa uses the TEMP path defined in AUTOEXEC.BAT, so it is
possible to use a RAM disk if desired).

## Further information
See the included documentation for more information, or visit the homepage
of Costa at
  http://costa.jacobpalm.dk
  
## Icons and themes always welcome!
If you have made any icons you would like to see included with Costa, or
perhaps a nifty theme, feel free to drop me a message. I am always looking
to add more to Costa, and credit will of course be given! 

## Using this code
When opening project files (.MAK), use the /L parameter for all project files
like so:

```
VBDOS.EXE DESKTOP.MAK /L
```

This will cause VBDOS to load the libraries neccesary for Costa to work.
If you get an error relating to "CALL ABSOLUTE" or "CALL INTERRUPT", you have 
probably not used this parameter when starting VBDOS.

The source code and build script assume the following:
  * That the source code has been extracted/cloned to C:\COSTA (this path is
    only required for development, once built Costa will run from any path)
  * That Visual Basic for DOS is installed to C:\VBDOS, in a flat structure -
    that is, all files placed in the folder directly, including libraries and
    include files

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
