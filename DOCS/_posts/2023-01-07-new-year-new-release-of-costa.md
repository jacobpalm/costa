---
title:  "New year, new release of Costa"
image: 2023-01-07.png
---
2023 has arrived, and with it comes a new release of Costa - version 1.7.0. This version brings a lot of small improvements, but also one major new feature: A file
selection dialog. Gone are the days when users would have to enter paths and filenames when adding links to the desktop. Now, users can visually select the file they want to open.
<!--more-->

Apart from the huge improvement in user experience brought on by the file selection dialog, there are some other noteworthy changes and additions to Costa.

The UI has been overhauled. Costa is single tasking, meaning only one program is active at any time. This essentially made windows pointless - because why would a program
need to display a window, if it can't be moved, manipulated or switched to/from? With this limitation in mind, all programs that come with Costa now use the full screen
for their content. This has resulted in some changes to the programs. For instance, the extra space gained in the calculator program is used to show a history of the
calculations that have been made. Dialogs, such as confirmation dialogs or inputboxes, are shown as modal dialogs on top of content, but no longer have titlebars. I actually really like this new design, and look forward to improving it further.

The setup utility has been improved with automatic path detection, meaning it is no longer necessary to input the path to Costa on first run. The option is still available, but creation of COSTA.BAT is now fully automated, making it easier for novice users to get started.

Costa has always used a TEMP folder located along with its program files for storing temporary data. This is still used, but now, if the TEMP environment variable is set,
Costa will use that path instead. On one of my older machines, which has a very slow hard drive but plenty of RAM, I have created a RAM disk and pointed the TEMP
environment variable to it, resulting in a noticeable increase in execution speed of Costa.

Lastly, work has been done to reduce the size of Costas EXE files. Not by means of compression, but by stripping out unused features from the libraries used. In total, this has saved 52 kilobytes of disk space - a 6 percent reduction.

Of course, there are also many minor bug fixes and improvements not worthy of mention here. [Grab a copy of Costa now]({{ site.baseURL }}/index.html#downloads) to experience all the new things for yourself!
