---
title:  "Get a move on!"
image: 2024-01-27.png
---
Recently, a Github user named Axle sent me a feature request for the next version of Costa: The ability to move icons between desktops.
<!--more-->

It's one of those features that as soon as someone suggests it, you think to your self "Of course! Why haven't I made this already?". So, since it made so much sense, and I wanted to do something for a fellow coder who has previously expressed gratitude for the work I've done on Costa, I set out to make this feature.

### Designing the solution

So, the request was quite simple. It took a bit of time to figure out how to do it right, though. Previously, Costa restricted the mouse movement during icon move, so that only the desktop was accessible - excluding a 16 pixel border, half of an icons width, to make sure the mouse never came too close to the border and made the icon go out of bounds. The GET and PUT graphics functions of QBASIC/VBDOS will throw an error if this happens. So, this had to be changed to allow the mouse to travel to the top of the screen where the menu buttons are. An easy fix, and I just made sure that if the mouse location was less than what was possible for the icon, the icon would stay further down on the screen, just underneath the menu.

Then I implemented buttons to switch between desktops. On the desktop, when not moving an icon, the left and right arrow keys can be used to switch between desktops. However, when moving an icon, the arrow keys could already be used to move the icon around, so another solution had to be thought of for those who use Costa without a mouse. The solution I chose was to allow the 1-5 keys on the keyboard to be used to switch to another desktop directly. As soon as I tried this out, I figured it would be a great little feature for the desktop itself, and implemented it there as well. So, now it's also possible when not moving an icon to switch between desktops directly without cycling through them, which is faster and easier if you know what desktop you're looking for.

Lastly, I implemented the logic to actually move the icon to another desktop behind the scenes. It's quite simple - delete the icon from the current desktop and save the desktop data file, load the new desktop data file and add the icon, then save the new desktop data file. For very old machines, or users running Costa off of a floppy disk, this might be a tad on the slower side due to the loading/saving of data files, but it's still a lot faster than deleting and recreating the data files.

### The result

I am quite pleased with how the feature turned out. I think it turned out both simple and elegant - take a look and judge for yourself:

![Screenshot of icon being moved between desktops]({{ site.baseURL }}/assets/img/blog/2024-01-27_moveicon.gif)

The feature will be released as part of the minor 1.7.5 update. The date is yet to be determined.
