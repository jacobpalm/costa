# The Costa Graphical Shell
Costa is a graphical user interface (GUI), designed to run on top of the
command line as a shell.

It is designed for MS-DOS, but tested with PC-DOS, FreeDOS and DOSBox as
well. In theory it should run on any MS-DOS compatible operating system with
a 286 or better CPU, VGA graphics and a recommended minimum of 250 KB RAM.

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

VBDOS.EXE DESKTOP.MAK /L

This will cause VBDOS to load the libraries neccesary for Costa to work.
If you get an error relating to "CALL ABSOLUTE" or "CALL INTERRUPT", you have 
probably not used this parameter when starting VBDOS.
