---
title:  "Where's my file?"
image: 2022-09-30.png
---
One of the aims of Costa has always been to make it easier for the average person to launch their games and programs, on real DOS machines and in emulators such as [DOSBox](https://www.dosbox.com). This is accomplished by having easy access through links on the desktop. However, creating these links is a manual process, where the executable name and path must be known beforehand. Not a very user-friendly solution - but that's about to change.
<!--more-->

Coming soon, in version 1.7.0, is an **integrated file browser**, that will allow the user to visually select any file, on any drive, with the mouse or keyboard. This file browser is used when creating/modifying desktop links, and also in the Text Viewer when opening a file. The file browser supports [wildcard](https://en.wikipedia.org/wiki/Wildcard_character) patterns, so you can filter on for example all executables by typing "*.exe" in the pattern field. All standard DOS wildcards are allowed.

[Visual Basic for DOS](https://en.wikipedia.org/w/index.php?title=Visual_Basic_for_DOS), in which Costa is written, does not have any native method of retrieving folders - only files. Under the hood the file browser uses DOS [interrupt](https://en.wikipedia.org/wiki/Interrupt) calls to retrieve files and folders from the [DOS API](https://en.wikipedia.org/wiki/DOS_API). This was an exciting challenge, which gave me a good insight into how the DOS API works, and how interrupts and [processor registers](https://en.wikipedia.org/wiki/Processor_register) are used to communicate with it. A good, fun learning experience - for someone like me, at least!

Another way in which version 1.7.0 aims to make file operations easier, is by having the setup utility **automatically detect and suggest the path to Costa**. The setup utility must be run before starting Costa for the first time, or should the user decide to move Costa to another path. Now, the user can simply press Enter to accept the suggested path, rather than having to type it manually. Like the file browser, this also required the use of functionality not included in the programming language.

Here comes a hairy explanation for those interested in knowing how this is achieved - as a good example of how seemingly simple things can sometimes be a bit cumbersome to achieve when programming for old systems. Through old DOS documentation and example code, I learned that the path to the currently running program is stored after the environment variables in memory, separated from these by a four-byte gap. The environment variables themselves are stored at a memory location a certain amount of bytes after the program segment prefix.

![The Visual Basic for DOS editor, showing part of the code to retrieve the Program Segment Prefix location]({{ site.baseURL }}/assets/img/blog/2022-09-30_psp.png)

So, to find the program path, you have to:

- Retrieve the memory address of the [Program Segment Prefix](https://en.wikipedia.org/wiki/Program_Segment_Prefix) from the DOS API
- Calculate where in memory after the Program Segment Prefix the environment variables are stored
- Iterate through memory from the start location of the environment variables, until you find a two-byte gap, signaling the end of the environment variables
- From that point, you're only a couple of bytes from the start location of the path, so jump to that location and you've found the path
- The end of the path is marked by a NULL byte, so you retrieve the path byte-by-byte until a NULL byte is retrieved, and then you're done

As you can see it's not quite simple to achieve - at least not without reading through proper documentation and studying the architecture of the OS a bit!

Another goodie coming to 1.7.0 is the usage of the **default TEMP path, as defined by environment variable**. If this variable is set, Costa will now use that path for its temporary files. If it is not set, Costa will fall back to the DATA\TEMP directory as used in previous versions. The advantage of this is that it is now possible to point the TEMP environment variable to a RAM disk, greatly speeding up read/write operations on older computers with slow disks. On my old 486 PC, the difference is quite noticeable.

Other than that, a few bug fixes are coming, as well as the option to have an empty desktop. Previously, Costa would recreate the default desktop links if the last one was deleted. Now, Costa will give the user the choice, and remember it.
