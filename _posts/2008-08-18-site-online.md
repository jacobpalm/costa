---
title:  "Site online again"
image: 2008-08-18.png
---
I've had a long break from programming. Almost a year, in fact. But in the past three weeks I've been trying out several new design ideas for Costa. And I'm not just talking about the design of the interface - I'm talking about the underlying design, about how everything should work. I've come to a conclusion.<!--more-->

Although Costa has been in development for several years, version 1.0 still hasn't been released. Back in the good ol' days, I used to release a new version frequently. But ever since I switched to from single-tasking and hard coded programs to a single, task-swapping and scripting based program development has slowed down. This is all because of one thing: As every program for Costa was to be written in Costa's own scripting language, I had to define and code a parser for that scripting language first. This proved to be a huge task, and all my time went into the scripting language.

I got tired of programming because I didn't see any results. I spent a lot of time working on Costa, but when I launched it I couldn't really see any difference because it was all "under the hood".

So that's why I have decided to return to single-tasking and hard-coded programs. Even though the programs are hard-coded I'll make them very flexible, and easy to customize through plain-text configuration files.

In the past two weeks I've written a reasonably powerful [GUI](https://en.wikipedia.org/wiki/Graphical_user_interface) toolkit with routines to handle everything from updating the screen to reading configuration files. It already has support for buttons, textboxes, checkboxes, images and windows. Using this toolkit I've also made a working desktop, complete with right-click menu and moveable icons.

Unlike previous versions, a lot of things in the GUI will be animated (menus, windows and more).
