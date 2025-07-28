# The Costa GUI
Costa is a graphical user interface (GUI), designed to run on top of the
command line as a shell.

The low system requirements make Costa especially useful for older machines,
which are also the machines that typically run the MS-DOS operating system.

![The Costa GUI](https://costa.jacobpalm.dk/assets/img/screenshots/aboutbox.png)

## System requirements
Costa is designed for MS-DOS, but tested with PC-DOS, DR-DOS, FreeDOS, 
Novell DR Multiuser DOS and DOSBox as well. In theory it should run on any
IBM compatible system with at least:

  * An 8088 or better CPU (386 or better recommended).
  * EGA or VGA graphics supporting 640x350 pixels at 16 colors (most newer EGA
    cards, or any VGA compatible card, should do).
  * A recommended minimum of 200 KB available memory while running Costa.
    When running external programs or games, Costa will use about 8 KB RAM.
  * MS-DOS 4.0 or newer, or a compatible operating system.
  * A mouse is optional. If used, a mouse driver must be loaded (DOSBox
    has a built-in mouse driver).

Although not required, a 386 or better CPU is recommended, as well as disk
caching software (SmartDrive or similar) when running on older machines -
especially if running Costa from a floppy drive.

## Licensing
Costa if open source, and released under the MIT License. See the
[*LICENSE* file](https://github.com/jacobpalm/costa/blob/master/LICENSE)
for more information on how you may use the code, and what credits
should be given if you do.

## Further information
See the included documentation for more information, or visit the homepage
of Costa at http://costa.jacobpalm.dk
  
## Icons and themes always welcome!
If you have made any icons you would like to see included with Costa, or
perhaps a nifty theme, feel free to drop me a message. I am always looking
to add more to Costa, and credit will of course be given! 

## Using this code
Costa is written using Borland Turbo Pascal 7, but should be compatible
with Microsoft QuickPascal as well - although this has not been tested.
Free Pascal support has not been tested either.

All programs (except *COSTA.PAS*) are written using the **Costa UI Library**.
This library resides in the unit *COSTALIB.PAS*, which must be included
in the USES section of all programs. Some additional units are
included, such as *FILESEL.PAS* for implementing "Open" dialogs and
*INPUTDLG.PAS* for showing an input box to the user.

*COSTA.PAS* is the memory-resident part of Costa. It launches the desktop,
and when the desktop exits, it checks if it should terminate, or if the
desktop has instructed it to run another program. If it runs another
program, the desktop will be reloaded when that program exits. This is
to avoid keeping the entire desktop in memory when running programs,
and make as much memory as possible available for programs.

The source code and build script assume the following:
  * That the source code has been extracted/cloned to *C:\COSTA* (this path is
    only required for development, once built Costa will run from any path)
  * That Turbo Pascal is installed in *C:\TP* using default folder structure
    (compiler placed in the *BIN* subdirectory of that path).

## Building Costa
To build Costa, run the build script from the command line:

```
_BUILD.BAT
```

This will automatically build all .PAS files in the SOURCE directory, using
predefined switches which are documented in comments in the build script
itself.
