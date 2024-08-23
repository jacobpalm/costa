---
title:  "1.7.1 released - speed and size is key"
image: 2023-04-10.png
---
For once, a new version of Costa - version 1.7.1 - does not bring any new features. Instead, focus has been on improving performance, and on reducing the size of Costa on disk.
<!--more-->

### New icon format

Costa is now using a new icon format, which does away with transparency. All icons now have a solid background color. The reason for this is that the old format was slow. Icons were drawn on the screen 1 pixel at a time, which meant that for each 32x32 pixel icon, 1024 draw operations were called. Given the [planar graphics](https://en.wikipedia.org/wiki/Planar_(computer_graphics)) involved with high resolution EGA and VGA, this took far too long on real hardware.

So, Costa now uses a much simpler format. The icon editor simply captures a chunk of video memory and saves it to disk, and the icon drawing routine then loads this chunk of puts it back in to video memory. In my testing on an IBM PS/2 55SX equipped with a 16 MHz [Intel i386 CPU](https://en.wikipedia.org/wiki/I386), I found the new routine to be somewhere around 6 times as fast.

As a bonus, icon size has been reduced from 2.055 bytes to 527 bytes - almost 75% saved space per icon.

### Code optimization - for speed

A lot of work has been put into optimizing the code. A few examples follow.

Every time Costa needs to check the location of the mouse cursor on the screen, it calls a [software interrupt](https://en.wikipedia.org/wiki/Interrupt#Software_interrupts) to make the CPU hand over control to the resident mouse driver, which then puts the values in to CPU registers and hands over control to Costa again. This process naturally eats up some CPU cycles. The code has been optimized to do this as few times as possible. For example, Costa used to call the mouse interrupt once to get the vertical position of the mouse cursor, and then again to get the horizontal position. This has been streamlined into one call to get both positions. And, in loops, the mouse position is now only polled once per iteration and stored in variables during subsequent checks in the code.

Static variables are now used in functions that only need to perform their task once. For example, the Sys.Path function which returns the path where Costa is located used to query the MS-DOS Program Segment Prefix for this information every time it was called. Now, this is only done once, and the value is stored in a static variable. All subsequent calls to the function will just return the static variable, without any queries being done. To read more about how Costa finds the path from the Program Segment Prefix, [read the blog post "Where's my file?"]({{ site.baseURL }}//2022/09/30/wheres-my-file.html).

Every time Costa or one of its accessories starts, a function called "Sys.Load" is called. This function takes care of loading fonts into memory, loading user settings and theme, and various other things. This function has been greatly optimized and reduced, to help each program start faster. Also, code to make sure the programs could only be started from within the desktop has been removed, because why not just let users run whatever they want, however they want?

### Code optimization - for size

The inputbox function (containing the dialog that can, for instance, be seen when clicking the "Execute" button on the desktop) was only used in a couple of programs but took up some space in all programs. This has been moved to a separate code module, which is only included where needed. This helped save 14 KB in total.

The "Tip of the Day" dialog has been removed. Instead, all tips have been written into the manual. The code which loaded the tips and selected a random one has been cleaned up.

VGA support has been removed. Costa will still run on any VGA adapter, but now uses the high-resolution EGA 640x350 with 16-colors mode exclusively. I found that this mode works perfectly on both CRT monitors and modern flat panel displays - on a CRT monitor with 4:3 aspect ratio, the picture is interlaced which, in my opinion, looks super cool. And, and modern 16:9 widescreen flat panel displays, the aspect ratio fits nicely. This saved 49 KB on the size of Costa, and as a bonus the EGA resolution is vastly faster than VGA, since it has an off-screen page I can use as a [screen buffer](https://en.wikipedia.org/wiki/Framebuffer). I no longer use temporary files on disk for this purpose.

The theme editor had two previews of themes - one for selecting the theme you wanted to edit, and one to show a preview of the theme while editing. This code was highly redundant, so it has been merged into one function, saving almost 4 KB.

Profiles have been removed - the feature that allowed 5 different profiles, with different settings, themes and desktop icons. It was not really being used but took up a lot of space and added complexity to Costa. With the concept of profiles gone, the desktop has instead been fitted with 5 pages. Using buttons at the top of the screen, or the left and right arrow keys, the user can now switch between 5 desktops with ease. Other than being a better implementation than profiles was, this also saved 49 KB disk space. Win-win, if you ask me.

In total, **Costa 1.7.1 takes up 186 kilobytes less space** than version 1.7.0 - **a saving of 18%**! Quite impressive, and certainly something that can be felt on vintage DOS machines.

### Configuration program rewritten from scratch

The configuration program has been rewritten from scratch. Not to add new functionality, but because the existing one was kind of a mess, code-wise. The new version is a lot simpler, and easier to use. It shows all options on the screen at the same time, and all changes are applied instantly - no need to apply or save settings. I'm quite pleased with the look and feel of it.

### Improvements to Tic Tac Toe

While watching my brother play Tic Tac Toe, I noticed he had some difficulties seeing whether he was starting a single player or multiplayer game. The UI was not clear on this. So, now I've cleaned it up a bit, and added a status bar.

While I was at it, I cleaned up the code a bit too. There were some quick gains to be found, for example in the code that changes the player turn to the other player:

```vb
CONST PlayerX = 0
CONST PlayerO = 1

...

IF PlayerTurn = PlayerX THEN
    PlayerTurn = PlayerO
ELSE
    PlayerTurn = PlayerX
END IF
```

What this does, is that it checks if it is currently PlayerX's turn. If it is, then it switches the turn to PlayerO. If not, then it must be PlayerO's turn, and the turn is switched to PlayerX. PlayerX and PlayerO have been predefined as [constants](https://en.wikipedia.org/wiki/Constant_(computer_programming)).

There's nothing wrong with this approach, but a much simpler and shorter version can be used - using [bitwise operators](https://en.wikipedia.org/wiki/Bitwise_operation):

```vb
CONST PlayerX = 0
CONST PlayerO = NOT PlayerX

...

PlayerTurn = NOT PlayerTurn
```

Now, PlayerX is still a constant with the value 0. But PlayerO is not assigned a number - it is assigned the opposite value of PlayerX, on a bit-by-bit basis. This in itself does not change much, but it gives us the ability to change player turn with one single line of code - by setting PlayerTurn to the opposite value using the "NOT" operator.

A long description of a simple change to the code, I know, but bitwise operations really are a powerful concept all developers should familiarize themselves with. I didn't fully grasp the concept years ago when I started developing Costa, but I now know that it would have helped me out in many situations.

### Download Costa 1.7.1

[Head on over to the download section]({{ site.baseURL }}/index.html#downloads) to get a copy of Costa 1.7.1 today!
