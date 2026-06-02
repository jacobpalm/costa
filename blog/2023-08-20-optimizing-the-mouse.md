---
title:  "Optimizing the mouse"
image: 2023-08-20.png
---
One of the goals when developing Costa is to include full - but optional - mouse support. Everything should be accessible via keyboard only, even the icon editor can be used with the arrow keys for drawing. But for those with a mouse, certain operations are easier. Now, how can something like the mouse be optimized, you might ask?

<!--more-->

On MS-DOS and compatible systems, there is no built-in mouse support. A mouse driver must be loaded before programs can use the mouse. The mouse driver is a small [background program](https://en.wikipedia.org/wiki/Terminate-and-stay-resident_program) which handles all the mouse related functions - including showing and hiding the [mouse cursor](https://en.wikipedia.org/wiki/Cursor_(user_interface)#Pointer). The cursor is not drawn by hardware, but by software, and because of this the mouse cursor is "imprinted" onto whatever is shown on screen. So, if your program draws something on screen, let's say a button, where the mouse cursor is, your drawing will overwrite the mouse cursor, leaving a strange visual artifact or glitch. This is demonstrated in the following screenshots, where the mouse was located where text was printed, which leaves a visual artifact once the mouse is moved:

![Visual artifact produced by not hiding mouse cursor before drawing]({{ site.baseURL }}/assets/img/blog/2023-08-20_mouseglitch.png)

To overcome this, the mouse cursor needs to be hidden before drawing, and then shown again afterwards. To do this, the mouse driver must be contacted and told to do so. This is done via a [software interrupt](https://en.wikipedia.org/wiki/Interrupt#Software_interrupts) - a way to tell the operating system to hand over control to the program hooked onto that software interrupt (there's a little more to it than that, but I'll keep it simple here). The program can then do what it needs to do, and hand control back.

The mouse driver included with Costa, and most if not all other mouse drivers, are hooked to interrupt 33 (33 being the hexadecimal number, to which the decimal equivalent is 51). The value of the ax [CPU register](https://en.wikipedia.org/wiki/Processor_register) determines the operation the driver needs to perform - 1 being "show cursor", and 2 being "hide cursor".

The following code hides and shows the mouse, respectively:

```vb
SUB Mouse.Hide ()

  IF NOT MouseHidden THEN
    DIM regs AS RegType
    regs.ax = 2
    INTERRUPT 51, regs, regs
    MouseHidden = True
  END IF

END SUB
```

```vb
SUB Mouse.Show ()

    IF MouseHidden THEN
    DIM regs AS RegType
    regs.ax = 1
    INTERRUPT 51, regs, regs
    MouseHidden = False
  END IF

END SUB
```

That's all well - we hide the cursor before drawing by calling Mouse.Hide, and then show it again by calling Mouse.Show. But, every time we do so, there's a performance penalty:

* The respective function has to be called, with all the work that implies in the background for the [stack](https://en.wikipedia.org/wiki/Call_stack) etc.
* Control has to be handed over to the mouse driver
* The mouse driver does its thing
* Control is handed back over to Costa

So, to optimize, we have to reduce the number of times the mouse driver is called. Previously, Costa automatically hid the mouse cursor when necessary, as all of Costa's functions took care of this. But the downside to this was, that for every button, textbox, icon or other object drawn on screen, Costa would hide the cursor, draw the object, show the cursor - and then repeat for every single object. While this made coding easier, it did no good for performance. So what I've done now, is leave it up to the developer to hide the cursor before starting any drawing operation, and then showing it again once all drawing is done. This gives the developer of apps for Costa the power and responsibility for handling the mouse cursor.

So, what impact has this had? Well, before optimizing, I built in some simple logging that recorded how many times the mouse driver was called. I then ran all accessories, and immediately exited them, to have some comparable data. Then I modified the code, made all optimizations and ran the accessories again. The gain was substantial. The number of times the mouse driver was called was reduced from 407 to 87. That's a **78.6 percent** decrease, and that's just from launching the accessories without actually doing anything with them. I've included a screenshot from Microsoft Excel below, where you can see how many times each accessory hid and showed the mouse cursor, both before and after the optimizations. As you can see it's quite an improvement.

![Screenshot from Excel showing massive improvements in number of times the mouse driver is invoked]({{ site.baseURL }}/assets/img/blog/2023-08-20_numbers.png)

I could maybe optimize further by only hiding and showing the cursor if the drawing is taking place where the cursor is, but I frankly don't think that there would be much gained this, given the overhead in code this would produce and the inherently slow nature of the BASIC language. I think it may end up actually worsening performance, or make no notable difference at all.

I hope this post gives some insight into the many small things I am doing to improve the overall performance of Costa. Without any numbers at hand to back it up, I can confidently say that over the past year the performance when running Costa on my old 16 MHz Intel 386 based computer has improved tremendously.
