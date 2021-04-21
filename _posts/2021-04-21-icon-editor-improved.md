---
layout: post
title:  "Icon Editor improved, new icon format introduced"
excerpt_separator: <!--more-->
---
Over the past couple of weeks, I have been working to improve the Icon Editor. Visually, nothing has changed - but under the hood, three major improvements have been made.<!--more-->

***Flood fill***
Until now, right-clicking a pixel has made that pixel transparent. But now, this will instead trigger a flood fill of the clicked area. This makes icon editing a breeze compared to the old method of having to paint each individual pixel.

***Major code cleanup and optimization***
The underlying code has been massively cleaned up and optimized. No longer will you see the editor redraw the drawing area - only changing pixels will be redrawn, even on flood fill. Code that was reused in multiple places have also been put into reusable functions/subs - this doesn't improve the speed, but it makes the code much cleaner.

***New icon format***
Another major improvement is a new format for icons. Until now, Costa has used the homebrewn BIF image format, which consisted of two elements:
*A header to identify the file as a Costa icon file
*A two-dimensional array of 16-bit integers, the smallest integer size available in the VBDOS language, each containing a number corresponding to one of the 16 available colors in the VGA palette, or -1 to indicate a transparent pixel

While this format worked fine, it had one downside: Since only 5 bits were needed to store each pixel in the icon, but the smallest available size was 16 bits, 11 bits were wasted for each pixel. If it had been possible to use an 8-bit integer, I would be able to save 1 kilobyte of space pr. icon. While this doesn't sound like much, bear in mind that Costa is designed to run on DOS-based systems, and to be transferred via floppy disk to such systems. At the moment, Costa comes with 120 icons - that means 120 KB of wasted disk space. For a 1.44 MB floppy, this is a huge amount!

So, I looked into storing two values in one integer, and using Assembly language to POKE/PEEK the data. But in the end, i opted for a much easier solution: Store each pixel as a string, with a length of one character. A single character in a string iz 1 byte in lenght. To store a color, I simply use the CHAR$ function to convert the color an ASCII character, and to retrive the color, i use ASC to convert the character back to an ASCII code.
As an example, the color '0' in the VGA palette is black. When saving this, it is converted to ASCII character 0 - which is a NUL symbol. When loading it back it, the NUL character is converted to it's ASCII character code, giving us a 0 again.

Say what you want about this solution, but it did save 120 kilobytes of disk space, at a very minor cost of performance.

![Note from 2004]({{ site.baseURL }}/assets/img/blog/2021-04-06.jpg "Note from 2004"){:class="img-responsive"}

So, there you have it. I do of course realize that Costa isn't, an never was, and an operating system. But I was quite young at the time, so bear with me on that. And maybe there should have been a "you" or something at the end of that sentence, but that would have ruined the acronym.

And how's it pronounced? Well, best I can describe it in writing would probably be a contraction of the words "the **cost** of **a** house".