---
title:  "The desktop is complete!"
image: 2008-08-20.png
---
I've finished the "Customize desktop link" dialog, and I've also added a run dialog to the desktop. I've also tested the desktop for bugs, and so far I haven't found any. I've learned from my mistakes in the past and have taken a lot of measures to avoid a crash if an error should occur. Every single computer program probably has bugs in it, but I haven't found anything so far. I'll release a test version before version 1.0 to make sure anybody else doesn't come across a bug.

It took me less than seven days to make the desktop, thanks to my [GUI](https://en.wikipedia.org/wiki/Graphical_user_interface) toolkit which really simplified making buttons, dialogs and other UI related parts of the desktop.
<!--more-->
I've also finished the memory resident part of Costa, which acts as a program launcher. It's a concept borrowed from BETA 0.9.3. The idea is to always have a small program in memory which launches the desktop. Then, when the user wants to run a program, the desktop tells the program launcher which program to run and quits. The program launcher will then launch the program, and when the user closes the program the program launcher reloads the desktop. It's the same with all of Costa's accessories: COSTA.EXE (which is the program launcher) is always in memory, but only one of the accessories are loaded at a time.

The reason I use a program launcher is to reduce the memory usage during program execution. If I just had the desktop running in the background while running a game or something, Costa would take up about 100 KB of conventional RAM. Using the program launcher I've managed to reduce the memory usage to less than 50 KB RAM. It might not sound like much of a difference, but in DOS you only have [640 KB conventional memory](https://en.wikipedia.org/wiki/Conventional_memory) to play with (some of which are used by DOS itself and device drivers), so I think it makes all the effort worth it.

The next part of Costa I'm going to work on is the theme manager, which will be able to both browse and edit themes for Costa. I already have a few hand-made themes, but a graphical editor with preview would be a nice touch for the GUI.
