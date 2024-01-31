---
title:  "Icon Editor improved, new icon format introduced"
image: 2021-04-21.png
---
Over the past couple of weeks, I have been working to improve the Icon Editor. Visually, nothing has changed - but under the hood, three major improvements have been made!<!--more-->

### Flood fill

Until now, right-clicking a pixel has made that pixel transparent. But now, this will instead trigger a flood fill of the clicked area. This makes icon editing a breeze compared to the old method of having to paint each individual pixel.

### Major code cleanup and optimization

The underlying code has been massively cleaned up and optimized. No longer will you see the editor redraw the drawing area - only changed pixels will be redrawn, even on flood fill, loading and creating a new icon. Code that was reused in multiple places have also been put into reusable functions/subs - this doesn't improve the speed, but it makes the code much cleaner.

### New icon format

Another major improvement is a new format for icons. Until now, Costa has used the homebrewn BIF image format, which consisted of two elements:

* A header to identify the file as a Costa icon file
* A two-dimensional array of 16-bit integers, the smallest integer size available in the VBDOS language, each containing a number corresponding to one of the 16 available colors in the VGA palette, or -1 to indicate a transparent pixel

While this format worked fine, it had one downside: Since only 6 bits were needed to store each pixel in the icon, but the smallest available size was 16 bits, 10 bits were wasted for each pixel. If it had been possible to use an 8-bit integer, I would be able to save 1 kilobyte of space pr. icon. While this doesn't sound like much, bear in mind that Costa is designed to run on DOS-based systems, and to be transferred via floppy disk to such systems. At the moment, Costa comes with 118 icons - that means 118 kilobytes of wasted disk space. For a 1.44 megabyte floppy, this is a huge amount - 8,1 percent of maximum capacity! Actual saved space depends on sector size, of course, but that's another discussion entirely.

Anyway, to reduce size I looked into storing two values in one integer, and using [Assembly language](https://en.wikipedia.org/wiki/Assembly_language) to POKE/PEEK the data. This would certainly be possible, but would make saving/retrieving data more cumbersome.

So in the end, i opted for a much easier solution: Store each pixel as a string, with a length of one character. A single character in a string is 1 byte in length. To store a color, I simply use the CHAR$ function to convert the color into an [ASCII](https://en.wikipedia.org/wiki/ASCII) character, and to retrieve the color, I use the ASC function to convert the character back to an ASCII code. Since I use -1 to indicate transparency, and this value cannot be converted into an ASCII character, values are shifted by +1 before saving, and -1 after loading.

As an example, the color '0' in the [VGA](https://en.wikipedia.org/wiki/Video_Graphics_Array) palette is black. When saving this, it is shifted by +1 and ends up as '1', then converted to ASCII character 1 - which is the ASCII control character 'soh'. When loading the data back in, the ASCII character is converted back to it's ASCII character code, shifted by -1, giving us a 0 again.

So now, the icon format looks like this:

* A header to identify the file as a Costa icon file
* A two-dimensional array of 8-bit (1 character) strings

Say what you want about this solution, but it did save 120 kilobytes of disk space, at a very minor cost of performance. All existing icons have been converted to this new format - the Costa Image Format, or CIF for short.

In the future, I might look into optimizing even further - even this new solution will waste 3 bits per pixel, which amounts to 0,38 kilobytes per icon. With the current count of 118 icons, that's roughly 44 kilobytes.
