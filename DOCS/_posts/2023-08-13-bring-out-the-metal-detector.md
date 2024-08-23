---
title:  "Bring out the metal detector..."
image: 2023-08-13.png
---
...because it's time to clear the minefield in the classic PC game Minesweeper! After a couple of months of development when my free time allowed it, the game is finally tested and ready for release as part of Costa version 1.7.4.

<!--more-->

The game follows the same rules as the classic Windows implementation. Not because I wanted to copy Microsoft, but because it’s the version most of us grew up with in the 90’s and spent far too much time playing on our non-internet connected PCs. It features the simple graphics that characterize the game, as well as multiple difficulty levels to choose from and optional PC speaker sound.

### Screenshots

![Kaboom! Accidentally clicking a mine will trigger a chain reaction and blow all the mines]({{ site.baseURL }}/assets/img/blog/2023-08-13_kaboom.png)

![Feeling up for a REAL challenge, or just a quick game? Multiple difficulty levels allow variation]({{ site.baseURL }}/assets/img/blog/2023-08-13_difficulty.png)

### Coding with bitwise operations

It may sound weird, but I started coding Minesweeper not because I wanted to make that specific game, but because I wanted to test some new knowledge I got about bitwise operations and put it to the test.

Bitwise operations are a method of manipulating individual bits in a byte, allowing for some very powerful programming. The use I found in Minesweeper is that I can use a single integer variable to store multiple values. Each cell on the board is one integer variable, and the individual bits in it are used to hold different information. For example, one bit determines if the cell has a mine or not, another determines if it has been flagged. This saves a lot of memory (for a DOS computer that is).

In the game code, I have 6 different states for each cell. Some of these can be combined - for example, a field can be both mined and flagged. Rather than having 6 integer variables per cell, I can have just one. I also don't need separate lists to keep track of flags etc. since all information can be in one variable.

The different states are as follows - defined as their decimal values, with binary value shown in the comment after each line:

```vb
CONST FieldMined = 1     '00000001
CONST FieldFlagged = 2   '00000010
CONST FieldCleared = 4   '00000100
CONST FieldNumbered = 8  '00001000
CONST FieldExploded = 16 '00010000
CONST FieldMasked = 32   '00100000
```

As you can see, each value corresponds to a different bit in the byte, starting from the right and moving towards the left, as that is how you count in binary. I am aware that a 16-bit integer on MS-DOS is two bytes long, but I have left out some 0's for clarity.

Using this scheme, I can combine two states - lets say FieldMined and FieldFlagged - like so:

```vb
MineField(1,1) = FieldMined XOR FieldFlagged
```

This will combine the bits of the two constants, and leave the cell with a value of 00000011 - the same as the decimal number 3. Later in the code, I can check the state of the cell using the AND operator. For example, I can check if a cell is flagged like so:

```vb
IF MineField(1,1) And FieldFlagged THEN
    'Cell is flagged
END IF
```

As you can see this also helps produce readable code - it's easy to read from the IF statement what it is trying to accomplish.

These are just a few examples of how bitwise operations can be used, there's tons of things they can be used for. But for Costa, packing more data into fewer variables fits very well with the overall theme of making Costa as small and fast as I can. If you are in to software development and haven't used bitwise operations before, you should absolutely read more about them.

### Common about box for all apps

Historically, Costa could only be started via the desktop, and all apps had to be run from there. This was, however, an artificial limit to make everything seem more "connected". I decided that this was kind of pointless, and that the user should have the freedom to start each app as they wanted. Only the desktop included information about the author (yours truly), and so I wanted information about each app to be shown in the app itself. I also figured this would make it easier for others to get proper credit, should anyone decide to make an app for Costa in the future.

For that reason, I have now implemented a standard "About box" function, that can be called from all apps that use the Costa library and implemented it in all existing apps, including Minesweeper.

![The common about box allows others to make apps for Costa and get proper credit]({{ site.baseURL }}/assets/img/blog/2023-08-13_about.png)

### Coming soon

The Minesweeper game, and other goodies mentioned here, will be made available when Costa 1.7.4 releases - any day now.
