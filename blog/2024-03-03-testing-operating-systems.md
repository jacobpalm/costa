---
title:  "Testing on different operating systems"
image: 2024-03-03.png
---
I've spent a good part of today testing Costa on a whole slew of operating systems - everything from MS-DOS 3.31 up to PC-DOS 2000. Costa worked perfectly on most of them, but I did have to update the system requirements.
<!--more-->

In theory, Costa doesn't use anything that should prevent it from running on MS-DOS 3 and up. But in reality, MS-DOS 3.31 which I tested with proved troublesome. The interrupt calls I use to retrieve paths from MS-DOS consistently result in overflow errors. So, I've updated the system requirements to MS-DOS 4.0 and up.

Costa has now been tested to work on the following DOS versions:

- Microsoft MS-DOS 4.0 through 6.22
- Microsoft MS-DOS 7 and 8 (the ones included with Windows 9x)
- NTVDM (on Windows 2000 and XP)
- FreeDOS (all versions)
- IBM PC-DOS 4.0 through 2000
- Multiuser DR DOS 5.10

It was kind of cool to see Costa running on Multiuser DR-DOS. I made a short recording of it. In it, I launch Costa, then launch the Icon Editor. I then switch to another user session, where the desktop is already running. Lastly, I switch to a new user session and end up on the command line. In this instance, Costa is running on two sessions simultaneously.

![Screen recording of Costa on Multiuser DR DOS]({{ site.baseURL }}/assets/img/blog/2024-03-03_multiuserdos.gif)

While it works perfectly, I suspect that editing the desktop or changing settings could have some weird side effects, since Costa caches some of these things in memory and only writes to disk when something has changed. So I think the right label for Multiuser DR DOS support would be "Supported, but use with care".
