---
title:  "Building a better feature"
image: 2022-10-27.png
---
When I started developing for DOS some 20+ years ago, I knew nothing about code versioning systems like [Git](https://en.wikipedia.org/wiki/Git), nor did I have any idea about [automating builds](https://en.wikipedia.org/wiki/Build_automation). I just did everything manually, building each separate program from within the [IDE](https://en.wikipedia.org/wiki/Integrated_development_environment) before loading the next. Obviously, I have learned a lot since then, but I never really changed the way I did things when it came to Costa. But now I've made some changes to make things easier for myself.
<!--more-->

Some years ago now, I started using Git to store, version and track all the code and files for Costa. This has been great, it's so much easier to keep track of everything when you have a complete log of all changes that have been made. But, building the programs from the source code has still been done entirely manually per program.

So, now I've taken some steps to ease this process for myself. I've created a [batch file](https://en.wikipedia.org/wiki/Batch_file), _BUILD.BAT, which will compile every single module into [objects](https://en.wikipedia.org/wiki/Relocatable_Object_Module_Format) automatically, and then [link](https://en.wikipedia.org/wiki/Linker_(computing)) each individual EXE file by combining these object files as needed. For each EXE file, I've created a small file with instructions for the linker, which it will use to generate the EXE file out of all the required parts. Now, I can compile and build all of Costa, by issuing a single command. A huge time saver, and really something I should have done years ago!

While I was at it, I started looking closely at how each EXE file was being linked and determined that I could make two improvements: Use [memory overlays](https://en.wikipedia.org/wiki/Overlay_(programming)) for the desktop, and include stub files in the link process to reduce EXE size.

**Use overlays for the desktop:** Overlays is a technique for reducing the amount of memory used by a program, and speeding up program startup time, by only loading the parts of it that are required to always be in memory. Other parts can then be loaded from disk as needed, or not at all if never required.

I have taken advantage of this for the desktop, where the desktop itself is now always loaded, but the Configuration window, which is not used in every session, is only loaded from disk when needed. The same goes for the file selection window. By doing this, the part of the desktop that must load on startup and when returning from an external program, has been decreased, improving speed.

**Include stub files:** Programs compiled with [Visual Basic for DOS](https://en.wikipedia.org/w/index.php?title=Visual_Basic_for_DOS) contain a run-time library, containing many common functions that can be used in the program created with it. For example, text input/output, graphics routines, serial port communication and much more. This run-time library is included in all programs, but Visual Basic for DOS takes steps to only include needed parts, in order to reduce EXE size.

However, there are additional steps that can be taken to further reduce EXE size. One of these is linking in stub files. A stub file in this case is an object file, that removes unused code from the run-time library during linking of the EXE file. For Costa, I could remove several things, such as serial/parallel port communication, ISAM database functionality, and advanced input editing, none of which was used.

Just by including these stub files in the linking process, I managed to save a total of 52 kilobytes in the EXE files - that's 6% of the size, reduced with hardly any work!

At this point, all that remains before Costa 1.7.0 is ready for release, is some additional testing under [DOSBox](https://www.dosbox.com) and on real hardware. A lot has changed under the hood, and I want to make sure everything runs smooth and stable.
