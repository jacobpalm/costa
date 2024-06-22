---
title:  "Celebrating 20 years of Costa"
image: 2024-02-01.png
---
Today marks a special occasion. On the 1st of February 2004, I released the first BETA version of Costa to the public. Its version was numbered [0.0.1]({{ site.baseURL }}/archive/001.html#versioninfo), and it came as a successor to another DOS shell project of mine - JEM Systems. Over the years much has changed, both with Costa and the world of IT, but I still find time occasionally to work on Costa. In this post, I'll take a brisk walk down memory lane and talk about the roots and evolution of Costa.
<!--more-->

### Roots

Before Costa there was JEM Systems. It was a simple [TUI](https://en.wikipedia.org/wiki/Text-based_user_interface) that I started working on in 2001, when I was 12 years old. It had no mouse support to begin with, was purely text based, and had little functionality. It also bundled a bunch of non-free software, such as small commercial MS-DOS games, which is why I have never made it available online. I started working on this little project after I got my first computer that same year - an old Intel [486](https://en.wikipedia.org/wiki/I486) DOS PC. It was meant as a replacement for the system of [batch-files](https://en.wikipedia.org/wiki/Batch_file) I used up until that point for launching my programs.

![Screenshot of unnamed shell version BETA 3]({{ site.baseURL }}/assets/img/blog/2024-02-01-shell.png)

A later version featured some better looks, optional text-based wallpaper, and a keyboard controlled "mouse" cursor. This was the final version before I started working on Costa.

![Screenshot of JEM Systems 3.0]({{ site.baseURL }}/assets/img/blog/2024-02-01-jemsys.png)

### Humble beginnings

In 2004 I began to get a better grasp on developing software, and taught myself how to do [VGA graphics](https://en.wikipedia.org/wiki/Video_Graphics_Array) and to use the mouse using [software interrupts](https://en.wikipedia.org/wiki/Interrupt#Software_interrupts). My learnings came from the built-in documentation in [QuickBASIC](https://en.wikipedia.org/wiki/QuickBASIC), which to date is still some of the best built-in documentation I have seen. Hats off to Microsoft for that! At this point in time, DOS was of course dead for any home use, so looking at needs and demand, Costa really had no basis for being created. But I had so much fun programming for DOS that I kept on with the project, and I really liked how nothing was served to me as a software developer. Want a button on the screen? Well, then you have to write everything that makes a button yourself - graphics, click detection, nothing came "out of the box". It was a great challenge to do, while also keeping the code small enough to run on any computer. Even today I like the challenges involved with developing for DOS - and the freedom it gives the developer.

And so, 20 years ago today, I released [BETA 0.0.1]({{ site.baseURL }}/archive/001.html#versioninfo) of Costa. It had almost accessories, all it could do was launch a full-screen DOS prompt and run external programs using a Run-dialog. The only accessory was a simple Paint program. But it had some features and ideas that have carried over to all later versions. Most notably a mouse is completely optional, and everything can be done by keyboard alone. This is still one of the goals of Costa. The look for Costa 0.0.1 was clearly inspired by Windows XP, the dominant PC operating system of the time.

![Screenshot of Costa 0.0.1]({{ site.baseURL }}/assets/img/blog/2024-02-01-costa-001.png)

With version [0.3.0]({{ site.baseURL }}/archive/030.html#versioninfo) and [0.3.3]({{ site.baseURL }}/archive/033.html#versioninfo) from late 2004 and early 2005 things started to look better. A "real" desktop was implemented, with icons being stored in individual files, sort of like how Windows stores shortcuts in .lnk files. Graphically, Costa got an overhaul and a new font, and looked much better than the first couple of versions. Costa also had some basic script capabilities, but not something that could really be used for any practical purposes at this time.

![Screenshot of Costa 0.3.3]({{ site.baseURL }}/assets/img/blog/2024-02-01-costa-033.png)

### A couple of fresh starts

With version [0.8.0]({{ site.baseURL }}/archive/080.html#versioninfo) from the summer of 2005 came some major changes. Everything was rewritten from scratch, and a simple UI library was made for the purpose. The interface had four skins to choose from - Costa, MacOS 1.1, Windows 3.11 and Windows 95. It also featured multi-user support.

![Screenshot of Costa 0.8.0]({{ site.baseURL }}/assets/img/blog/2024-02-01-costa-080.png)

Versions [0.9.0]({{ site.baseURL }}/archive/090.html#versioninfo) to [0.9.4]({{ site.baseURL }}/archive/094.html#versioninfo) were - once more - a complete rewrite of Costa. I wanted to make Costa into a fully scriptable system, with support for running 10 apps at a time. I implemented a [windowing system](https://en.wikipedia.org/wiki/Windowing_system) for this purpose, which made these versions of Costa the first - and only - versions to feature moveable windows and switching between multiple apps without exiting any of them. It could even run multiple instances of the same app. Progress was slow, however, as I spent all the time on making a script engine, so between these versions, not much progress was visible on the surface. For this reason, and because I reverted to the idea of a simple, small and faster software, I pulled the plug on this version.

![Screenshot of Costa 0.9.4]({{ site.baseURL }}/assets/img/blog/2024-02-01-costa-094.png)

### The long road to version 1.0.0

Since its beginning in 2004 and up to the 0.9.4 release in 2008, Costa had never reached version 1.0.0. All versions had been BETAs - for several reasons. One of the reasons being that I just wanted to try out different things and concepts. Another reason being that I continually learned more about programming, and started over because I realized I had done things ineffectively or in a way that wasted resources or hindered performance. So, once again I rewrote Costa from scratch, this time focused on getting things done and releasing something finished and polished.

The result was Costa [0.9.8]({{ site.baseURL }}/archive/098.html#versioninfo) from the end of 2009. It featured a complete desktop, a bunch of accessories such as the new icon editor, and an overall consistent and clean interface. I had intentions of releasing version 1.0.0 that same year, but life has a way of getting in the way of plans. Version [0.9.9]({{ site.baseURL }}/archive/099.html#versioninfo) wouldn't be released until 2011, followed at long last by version [1.0.0]({{ site.baseURL }}/archive/100.html#versioninfo) in May of 2012. **After 8 years, the first full release of Costa was out!**

![Screenshot of Costa 1.0.0]({{ site.baseURL }}/assets/img/blog/2024-02-01-costa-100.png)

### Fine-tuning and expanding

Since version 1.0.0, I have continually fine-tuned and optimized Costa. This has resulted in a bunch of versions, some minor and some bigger. But the core from 1.0.0 remains. Among things added or changed since 1.0.0 are the theme editor, the minesweeper game, massive performance improvements, multiple desktops and more.

The latest addition to Costa, coming soon in version 1.7.5, will be ability to move icons between desktops. A small, but usable feature - and at this point, small adjustments are what's in scope for Costa. After so many rewrites, Costa has reached a mature state where I don't want to spend more time rewriting stuff. Looking at the code, there are many things I would do differently today - right from the language it is written in being something object-oriented instead of BASIC, to the way many things are not following modern practices or even best practices of the day. But keeping in mind that Costa is written for old PCs or DOSBox, and that the code traces all the way back to my early teens, I am quite pleased with how well everything works, how stable it is and how good it looks.

![Screenshot of Costa 1.7.5]({{ site.baseURL }}/assets/img/blog/2024-02-01-costa-175.png)

I hope this trip down memory lane has been interesting to read. If nothing else, it has been a joy for me to look back at some of my old work and the code behind it. There have been many more versions of Costa than can be listed here, so if you're interested in reading more about these, head over to [the archive]({{ site.baseURL }}/archive.html) on this site and have a look - all versions are listed there, and almost all of them are downloadable too!
