---
title:  "Graphics modes - EGA and VGA"
image: 2022-05-18.png
---
Since its inception in 2004, Costa has always used [VGA](https://en.wikipedia.org/wiki/Video_Graphics_Array) graphics. More specifically, it used the standard VGA 640x480 pixels resolution, with 16 colors. I chose this resolution, because I liked the relatively sharp graphics it can produce, and the amount of screen real estate it provides. But, this graphics mode has a couple of drawbacks.<!--more-->

Most importantly, it doesn't support screen pages. This means that there is no off-screen buffer I can use to store graphics. Everything is drawn directly to the screen, erasing what was there before. This results in having to redraw the entire screen when a window or dialog is closed, slowing down Costa significantly on older machines like the one from 1987 I am testing on.

So, for a long time I was thinking about using another graphics mode. And I chose to go with [EGA](https://en.wikipedia.org/wiki/Enhanced_Graphics_Adapter) graphics, 640x350 with 16 colors. This is still a fairly high resolution, and it provides two screen pages for me to draw on. It is also fully compatible with VGA adapters. This gives me the ability to preserve the screen before a window was shown, and instantly restore it when the window is closed, speeding up Costa significantly. This also allows Costa to run on machines with only an EGA graphics card (provided that the card has at least 64 KB memory), allowing Costa to work on older and lower specification machines than previously possible.

Below is a screenshot comparing the icon editor in VGA and EGA resolution. When running in the smaller EGA resolution, the grid is resized to be smaller, and the buttons are moved around to fit the screen better.

![The icon editor in VGA and EGA resolution]({{ site.baseURL }}/assets/img/blog/2022-05-18_egavga.png)

Wether you prefer the EGA or the VGA resolution is a matter of taste, and on any computer that can run it just fine, I would say that the VGA resolution is the way to go. So, to make Costa as flexible as possible, I have made an option in the configuration dialog to change resolution. You can do this on the fly, it's not necessary to exit and restart Costa. Pretty nifty, I think.

To sum up, I'll list some of the differences between the EGA and VGA resolution.

#### EGA

- 640x350 pixels, 16 colors
- Lower resolution, thus less space for objects on the screen
- Supports screen pages, resulting in significant speed increases in some drawing operations
- When running on a [CRT](https://en.wikipedia.org/wiki/Cathode-ray_tube) display, this resolution has horizontal [scan lines](https://en.wikipedia.org/wiki/Scan_line). Which looks super cool, in my opinion.
- Works on both EGA and VGA adapters, provided the EGA adapter has at least 64 KB memory. Better compatibility with old systems.

#### VGA

- 640x480 pixels, 16 colors
- Higher resolution, more space for objects on the screen
- Much slower for some graphics operations
- The "universal" standard of the 1990s, supported by almost every PC
