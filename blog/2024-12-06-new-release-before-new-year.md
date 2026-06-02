---
title:  "A new release before a new year - Costa 1.8.0"
image: 2024-12-06.png
---
Today, I'm rounding up the year with one final release of Costa in 2024, version 1.8.0.
<!--more-->

A minor release, 1.8.0 is focused on optimizations and bugfixes.

For some time now, Costa has relied on the SETUP.EXE program to create COSTA.BAT, the latter of which was then tailored to the specific path in which Costa was installed. This has now been replaced by code that automatically finds the location of the EXE files using the MS-DOS Program Segment Prefix. In short, paths are no longer an issue, and SETUP.EXE is no longer required and has been removed. COSTA.BAT has been replaced with a new launcher, COSTA.EXE, written in Turbo Pascal. The reason for this is size - it needs to be as small as possible, to not use up precious conventional memory required by programs and games. I've managed to squeeze the EXE down to under 5 KB, with a run-time memory requirement of 9 KB. Which is pretty decent, I think!

The mouse code has been optimized to only call the mouse driver if one is loaded, resulting in better performance on systems without a mouse. The code to check if a file exists on disk before attempting to open it, has been rewritten to use MS-DOS system interrupts, resulting in quicker execution and preventing errors on write-protected disks.

Costa 1.8.0 is expected to be the last release in the 1.x.x series. I'm working on a new library, that will probably form the base of an upcomming 2.x.x series.

### Download Costa 1.8.0

[Head on over to the download section]({{ site.baseURL }}/index.html#downloads) to obtain this new version.
