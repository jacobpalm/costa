# The Costa Graphical Shell
Costa is a graphical user interface (GUI), designed to run on top of the
command line as a shell.

It is designed for MS-DOS, but tested with FreeDOS and DOSBox as well. In
theory it should run on any MS-DOS compatible operating system.

The low system requirements make Costa especially useful for older machines,
which are also the machines that typically run the MS-DOS operating system.

See the included documentation for more information, or visit the homepage
of Costa at
  http://costa.jacobpalm.dk
  
## Icons and themes always welcome!
If you have made any icons you would like to see included with Costa, or
perhaps a nifty theme, feel free to drop me a message. I am always looking
to add more to Costa, and credit will of course be given! 

## Using this code
When opening project files (.MAK), use the /L parameter - as such:

VBDOS.EXE COSTA120.MAK /L

This will cause VBDOS to load the libraries neccesary for Costa to work.
If you get an error relating to "CALL ABSOLUTE", you have probably not
used this parameter when starting VBDOS.

**Note** - the only exception is with SETUP.MAK. This is a command line
tool, and as such does not need any special libraries. It can be opened
directly.
