---
layout: develop
title: Developers Guide
---
**Important:** This guide is currently being written and is subject to change - some content may be missing or wrong.
{: .w3-panel .w3-red .w3-border}

## Introduction

Costa is written in Visual Basic for DOS. The name might mislead you to think that Visual Basic handles everything on the screen, like it does in Visual Basic for Windows - objects, drawing and such. However, Visual Basic for DOS (VBDOS) only supports text-mode user interfaces. When you take that part out, which I do because I'm not using any of it, all you have left is essentially QuickBASIC with a more modern user interface. All graphics have to be done by the developer, and no concept of objects exist. This makes software development a somewhat tedious task, as a lot of time and effort goes into the UI, rather than the actual program you want to write. It's also not easy to maintain consistency between programs, as each program has to implement a user interface for itself.

That's where the *Costa UI Library* originated from - I wanted to make development for Costa easier and more consistent. So I set out to create a library of procedures (FUNCTIONs and SUBs) that would make this task easier. Currently, the programs included in Costa utilize an older, somewhat cumbersome library. The plan is to gradually convert all programs to this new library, to simplify and align the programs. An added benefit is that it will be much easier for others to create programs using my library, regardless of wether they want to create a stand-alone program or an accessory for Costa.

### Downloading the Library

The library is still under development, and as such is not yet available for download. I am working on getting it ready as soon as possible.

I have chosen not to release it yet, because I am still changing things up a bit as I go along, while working out the right way for everything to work. It would not be fun to write a program using a library that's constantly changing! Once it has stabilized and is deemed ready to use, I will put it here and also inform about the release on the blog.

### Concepts

There are several concepts that are important to understand when working with the Costa UI Library. Developers familiar with programming for Windows or other graphical environments may have an understanding of some of these already.

#### Objects

VBDOS is not an object-oriented language. This makes programming something like a graphical user interface, which consists of many on-screen objects, somewhat challenging. To ease development, the Costa UI Library implements SUBs and FUNCTIONs that mimic object oriented programming. In reality, a bunch of arrays of custom TYPEs and strings contain all the "objects", but the developer cannot access these directly from their programs. Instead, all object manipulation is done through these procedures, which also implement some validation of the data passed to ensure smooth operation.

An example of an object is a button. The button is declared simply as an integer variable. This variable is then set to the return value of a function that creates an object. The value of the variable can then be considered a "handle". No matter how the internal arrays in the UI library change as objects are created and removed, this handle will remain valid for use until the object is removed. The handle can be used with procedures, for example to set the caption or enable/disable the button, and it can be used to determine when an object has been clicked, if it was this particular button that was clicked.

#### Contexts

A context can be seen as a collection of objects. Before creating any objects, a context should be created for them. Only one context can be active at any given time. For example, if your program has a main screen and a secondary screen, you should create a new context before showing the secondary screen. When you do so, buttons and other objects on the first screen are automatically disabled until the context in which they have been created becomes active again. This way you don't have to manually disable or remove objects that are not currently in use, if you need them again later.

Another benefit of contexts is that you can draw all objects in a context in one operation, and when you remove a context, all objects in it are removed automatically - which is both easier and helps to free up memory.

#### Events

The Costa UI Library uses events extensively. Every action the user takes is an event - a key press, a mouse click. Some events are also generated automatically, like a redraw event whenever an object is drawn, an object switches state (for example, a radio button is selected/deselected) and more.

Basically, events are everything you might want to act on in your program. Using the event system of the UI library, you don't have to check for button clicks, textboxes being edited or any other action - the library will inform you. All you need to do in your programs main loop is act on these events.

### Using the library

To use the library, you will need to run VBDOS with the `/L` parameter. This tells VBDOS to include the *VBDOS.QLB* QuickLibrary, which contains some functions that are required by the Costa UI Library.

```powershell
VBDOS.EXE /L
```

**Important!** Your program will only run from within the VBDOS IDE if you use the *Run > Modify COMMAND$* menu to set the command line options for your program to contain the parameter `/DEV`, and if you place your program code in *C:\COSTA*. This is due to the function that returns the path to the currently running program, when you run from the IDE this will return the path to VBDOS.EXE instead. The `/DEV` command line switch tells this function to always return *C:\COSTA*.
{: .w3-panel .w3-pale-yellow .w3-border}

Once you have started VBDOS, add the following code at the start of your program:

```vb
'$INCLUDE: 'LIBRARY\COSTALIB.BI'

DIM InitMessage$
IF NOT Init_Library(InitMessage$) THEN
  PRINT InitMessage$
  END
END IF
```

Then, add the *LIBRARY\COSTALIB.BAS* file to your program as well. The library does not come precompiled as a QuickLibrary at this time, but you could compile it yourself if you wanted to.

**Important!** Do not write any of your program code in *COSTALIB.BAS*, use a separate module for all your code and set it as the main module.
{: .w3-panel .w3-pale-yellow .w3-border}

The INCLUDE directive tells the compiler to include all definitions from *COSTALIB.BI* in your program. These definitions include constants, SUBs and FUNCTIONs from the library which you can use in your program.

The `Init_Library` function is used to initialize the library, and must always be called before you start using any other procedures. It will load fonts into memory, set the correct theme and initialize the display. It will return one of the constants `True` or `False`, telling you wether it succeeded in loading. If not, the error message will be stored in the string variable passed to the function. You should always terminate your program if `Init_Library` fails.

If the function returns `True`, you are good to go and can start using the library!

### File Structure

The recommended structure for your program is the following tree structure:

{: .w3-table-all .w3-responsive}
| Folder      | Description                                                                              |
|:------------|:-----------------------------------------------------------------------------------------|
| (root)      | Keep your project (.MAK) files here.                                                     |
| SOURCE      | Keep your own code here - .BAS and .BI files here.                                       |
| LIBRARY     | Keep the .BAS and .BI files of the Costa UI Library here.                                |
| DATA        | Place font data here.                                                                    |
| DATA\CONFIG | Config files should be placed here.                                                      |
| DATA\IMAGES | Image files, in the library's native .BSV format.                                        |
| DATA\TEMP   | Can be used instead of the TEMP location specified by environment variable, if desired.  |
| DATA\THEMES | Themes should be located here.                                                           |
| DOCS        | Documentation/help files.                                                                |

### Constants

Several useful constants are declared in the library and can be used in your program. Most of these are related to objects, events or other specific areas, and will be covered in respective sections later on.

There are a couple of boolean constants defined, which can be used to emulate the BOOLEAN datatype (true/false) that VBDOS lacks. All library functions that return a true/false value uses these.

They are declared as follows:

```vb
CONST True = -1
CONST False = 0
```

The `NOT` operator will work on these just fine - meaning `NOT TRUE = FALSE`. This can be useful in many situations to write clearer code.

### Conventions

The Costa UI Library uses a series of conventions for variable naming. Although this is completely optional to follow, it is recommended to do so to ensure that all programs made using the library follow the same pattern and are easily maintained and understood.

#### Naming

Object names should describe their function, prepended by a three letter abbreviation for the object type. The following abbreviations should be used:

{: .w3-table-all .w3-responsive}
| Abbreviation | Object type  | Example          |
|:-------------|:-------------|:-----------------|
| btn          | Button       | btnCancel%       |
| txt          | Textbox      | txtName%         |
| rad          | Radio button | radOption%(0)    |
| frm          | Frame        | frmUserinfo%     |
| img          | Image        | imgLogo%         |
| lbl          | Label        | lblWelcomeText%  |
| dlg          | Dialog       | dlgAboutbox%     |
| chk          | Checkbox     | chkShowFilename% |

It is recommended to follow the BASIC practice of declaring the data type of a variable using the identifier. In the table above, `%` is used to specify the integer data type. Describing data types are out of scope for this documentation, but make a note to remember that the library almost exclusively uses the integer data type.

## Working with Contexts

As previously described, contexts are used to group objects together for easier handling (drawing at once, removing at once) and to make sure only objects in the current context are active (for example, disabling all other objects when a dialog is showing).

### Creating a Context

Creating a context is easy, using the library function. To create a context, simply do the following:

```vb
'Declare variable for main context
DIM conMain%

'Create a context
conMain% = New_Context%
```

That's it. You will now have a new context, ready to use and already active. Any objects you create will now be created in this context, until you either switch to another, existing context, remove the context, or create a new context.

**Information:** The only memory required for a context is the memory used by your handle variable - 2 bytes (the size of an integer variable). Internally, the library also uses one integer variable to keep track of all contexts. This limits the total number of calls to New_Context during a run of your program to 32,767 - which should be more than adequate for most use cases.
{: .w3-panel .w3-pale-blue .w3-border}

### Removing a Context

Removing a context is as easy as creating one - there's a SUB for that:

```vb
'Assume we have the handle we got when creating the context
'stored in conMain%

Remove_Context conMain%
```

When you remove a context, the library will go through all objects and check if they belong to the context being removed. If they do, they will be removed as well, freeing up memory for objects that are no longer needed.

**Information:** If you remove the active context, the library will choose the most recently created context with objects in it, and make it the new active context.
{: .w3-panel .w3-pale-blue .w3-border}

### Switching Context

There may be situations when you want to switch to a certain context. As mentioned earlier, creating a new context will automatically make it active, so you don't need to switch to it. However, once a context is no longer needed and removed, you may want to choose a specific context to switch to. Other use cases may also arise.

Switching context can be done like so:

```vb
'Save current context to be restored on exit sub
conCurrent% = Get_Context%

'Create new context for aboutbox
conAbout% = New_Context%

'(program code here)

'Remove aboutbox context
Remove_Context conAbout%

'Restore previous context
Set_Context conCurrent%
```

## Working with Objects

Simply put, objects are representations of what you see on the screen - buttons, textboxes, etcetera. Common for all objects are that they have some properties (size, location, caption and more) that can be defined, and that they can be interacted with using the mouse or keyboard. There are however a few special, non-visible objects too.

Whenever you want to show something on screen or interact with the user, you should use an object to do so. It is of course possible to draw whatever you want on screen using built-in VBDOS graphics functions, but if you choose to do so, you should do it in an event handling routine - more on that later. For now, just remember that objects are the way to do things when using the library.

### Object Types

{: .w3-table-all .w3-responsive}
| Object type  | Description                                                                          | Constant used to create |
|:-------------|:-------------------------------------------------------------------------------------|:------------------------|
| Button       | Clickable button.                                                                    | objButton               |
| Textbox      | Box for text input.                                                                  | objTextbox              |
| Radio button | Radio button - group of selection boxes of which only one can be selected at a time. | objRadio                |
| Frame        | Frame used to visually group other objects together.                                 | objFrame                |
| Image        | 32x32 pixel icon                                                                     | objImage                |
| Label        | Text - can be single or multiple lines.                                              | objLabel                |
| Dialog       | Dialog window.                                                                       | objDialog               |
| Checkbox     | Checkbox that can be checked or unchecked.                                           | objCheckbox             |
| Screen       | Special object used only in events, cannot be created or modified.                   | -                       |
| Keyboard     | Special object used only in events, cannot be created or modified.                   | -                       |
| Mouse        | Special object used only in events, cannot be created or modified.                   | -                       |

#### Buttons

Buttons are simply that - a button that can be clicked. Examples could be an "OK" or a "Cancel" button.

![Screenshot of buttons in various states]({{ site.baseURL }}/develop/img/obj_button.png)

Triggered events:

- **eventClick** on click
- **eventRightClick** on right-click
- **eventRedraw** whenever the object is drawn

#### Textboxes

Textboxes are used to get input from the user. For example, when saving a file, a textbox can be used to let the user enter a filename. Textboxes can also be used to show the user data, if desired. In that case, the textbox can be disabled if the user should not be able to edit the value.

Triggered events:

- **eventClick** on click
- **eventRightClick** on right-click
- **eventEdit** when user edits the value of the textbox
- **eventRedraw** whenever the object is drawn

#### Radio buttons

Radio buttons are used to present the user with a number of choices, of which they can choose only one. One example could be a setting where the user can choose if text is display above, below, to the left or to the right of an icon. There's four choices, but naturally only one can be selected at a time. In this case, radio buttons make sense as there's no chance the user ends up selecting more than one.

Triggered events:

- **eventClick** on click
- **eventRightClick** on right-click
- **eventToggle** when selected or unselected
- **eventRedraw** whenever the object is drawn

#### Frames

Frames are a mostly visual object - their purpose is to group other objects together visually, by drawing a border around them. This can be useful if your program displays a lot of options on screen, to show which objects are related to each other.

An example could be a form on screen for entering information about a car, and the user to which the car belongs. You could group the name, address and other information about the user together in a frame, and have another frame containing maker, model and build year of the car. This can help keep your app user friendly.

Triggered events:

- **eventClick** on click
- **eventRightClick** on right-click
- **eventRedraw** whenever the object is drawn

#### Images

Images are always 32x32 pixels, and drawn with a slim border. Image objects use the native format used by the Costa UI Library. This means that you cannot load a .BMP or .JPG image and display using the library, for that you will have to write your own code. Images can be created or edited using the Icon Editor that comes with the Costa Graphical Shell, available at [https://costa.jacobpalm.dk](https://costa.jacobpalm.dk).

Triggered events:

- **eventClick** on click
- **eventRightClick** on right-click
- **eventRedraw** whenever the object is drawn

#### Labels

Labels are simply text to be displayed on screen, in one of three available fonts. You could print text directly to the screen if you desired so, but it is recommended to use label objects when possible as this will allow you to redraw the screen without having to manually re-print text.

Labels can be multiline, and will line break automatically whenever a carriage return character (`CHR$(13)`) is encountered.

Triggered events:

- **eventClick** on click
- **eventRightClick** on right-click
- **eventRedraw** whenever the object is drawn

#### Dialogs

A dialog is meant to be used as a pop-up window. For example, an aboutbox shown in the middle of the screen, on top of your program, could be implemented using a dialog. Other objects have no real relation to a dialog, so drawing the dialog won't draw other objects, but visually it gives the appearance of a separate window.

Triggered events:

- **eventClick** on click
- **eventRightClick** on right-click
- **eventRedraw** whenever the object is drawn

#### Checkboxes

Checkboxes are somewhat similar to radio buttons, with the exception that they are individual. A checkbox can be checked or unchecked, independently of other check boxes.

Triggered events:

- **eventClick** on click
- **eventRightClick** on right-click
- **eventToggle** when checked or unchecked
- **eventRedraw** whenever the object is drawn

### Object Properties

All objects have a range of properties. These define where to object is placed on screen, how it looks, and how it can be interacted with. Properties cannot be modified directly, you have to use the procedures provided by the library. This ensures that properties remain valid, and that nothing breaks the internal workings of the library.

The following table lists all properties of objects and their use:

{: .w3-table-all .w3-responsive}
| Property | Description | Can be used with | Set | Retrieve |
|:---------|:------------|:-----------------|:----|:---------|
| Caption | The text shown on next to an object, depending on the type of object. Used to describe the object. Examples could include "OK" for an OK-button, or "Name" for a textbox for the user to enter their name into. | All object types | Set_Caption | - |
| Value | The value of an object. For textboxes, the value entered by the user. For images, the filename (without extension or filetype) of the image file to display. | Textboxes, images | Set_Value | Get_Value$ |
| Size | Size specified as four values, measured in pixels: Left, Top, Width and Height. Together, these specify the location and size of the object on screen. | All object types | Set_Size | - |
| Enabled | An object can only be interacted with by the user if it is enabled. A disabled object will not trigger any events. | All objects | Set_Enabled | Get_Enabled% |
| Transparent | If set to `True`, the object will not draw a background color. For instance, a button or textbox will only have its border drawn, but the middle will remain whatever was already drawn there. |  | Set_Transparent | - |
| Background color | Unless the object has "Transparent" set to `True`, this color will be used to draw the background of the object. Can be set to the colorDefault constant to restore default background color if needed. |  | Set_Background | - |
| Selected | For checkboxes or radio buttons, this property indicates if the object has been checked (for checkboxes) or is the currently selected radio button in a group of radio buttons. | Checkboxes, radio buttons | Set_Selected | Get_Selected% |
| Radio Group | Specifies which radio group, created using the New_RadioGroup% function, a radio button belongs to. Only one radio button in each radio group can be selected at a time. | Radio buttons | Set_RadioGroup | - |
| Font | The font with which to draw the text in the label. Use one of the three font constants fontNormal, fontHeading or fontSystem. | Labels | Set_Font | - |
| Max Length | The maximum length of user input in a textbox. Default is 255. | Textboxes | Set_MaxLength | - |
| Hotkey | The hotkey is used to trigger an object by keyboard, for example a button. Hotkey will be set automatically to the character following an ampersand (&) character. It can also be set manually using the Set_Hotkey SUB. | All objects types | Set_Hotkey | Get_Hotkey$ |

### Creating an Object

Creating an object is easy - there's a simple function for that:

```vb
DIM btnCancel%
btnCancel% = New_Object(objButton)
```

You call the `New_Object` function, with a constant defining which type of object you want. See the *Object types* section for a list of constants.

**Information:** Each object you create will use 42 bytes of memory internally in the library, plus 2 bytes for your handle variables (size of an integer). In addition, one byte is used for each character added to the caption or value of an object. The maximum number of simultaneous objects is 32,768 in theory, but you will run out of memory before reaching this limit.
{: .w3-panel .w3-pale-blue .w3-border}

### Removing an Object

Removing an object is equally simple:

```vb
'Assume we have the handle of the button stored in btnCancel%

Remove_Object btnCancel%
```

**Information:** If you remove a context, you don't need to remove each object in it. The library will handle that for you.
{: .w3-panel .w3-pale-blue .w3-border}

### Modifying an Object

As underlined earlier, you cannot by default modify objects directly - nor should you ever try to do so. Instead, the Costa UI Library provides a variety of procedures for this purpose. Once you have created an object, use the handle you got from `Create_Object` to call these procedures and modify the properties of the object, or to retrieve certain properties.

See the table in the *Object Properties* section for an overview of properties, and which procedures can be used to set/retrieve them. Full description of each procedures can be found in the *Procedure References* section.

## Drawing

Objects can be drawn in one of two ways: Individually, or as part of a context.

To draw an object individually:

```vb
'Create object and set properties
btnClose% = New_Object(objButton)
Set_Size btnClose%, 274, 249, 92, 22
Set_Caption btnClose%, "&Close"

'Draw object
Draw_Object btnClose%
```

To draw an entire context - meaning any object associated with the context:

```vb
conAboutbox% = New_Context%

'Create two objects and set properties
btnClose% = New_Object(objButton)
Set_Size btnClose%, 274, 249, 92, 22
Set_Caption btnClose%, "&Close"

lblAppName% = New_Object(objLabel)
Set_Size lblAppName%, 210, 82, 1, 1
Set_Caption lblAppName%, "My Demo App"
Set_Font lblAppName%, FontHeading

'Draw entire context, including both objects
Draw_Context conAboutbox%
```

Whenever an object is drawn, a redraw event for that object will be triggered. This can be useful if you want to draw something manually on an object, like drawing an icon on a button instead of text. In that case, put your drawing code inside the event handling code of your program to ensure that whatever you draw will be redrawn when the object is redrawn.

**Important!** When you draw manually, you must hide the mouse cursor while doing so. Unlike modern platforms, the DOS mouse drivers will not take care of this for you. So, before drawing call `Mouse_Hide`, and when you're done, call `Mouse_Show`. This way you will avoid some nasty graphical glitches.
{: .w3-panel .w3-pale-yellow .w3-border}

## Working with the Mouse

Assuming that a mouse driver is loaded before your program is run, the mouse will work straight away once you initialize the library. If needed, you can show/hide the cursor manually using the provided SUBs:

```vb
'Hide the mouse cursor
Hide_Mouse

'(program code here)

'Show the mouse cursor again
Show_Mouse
```

## Working with Events

Events are the heart of the Costa UI Library. Contexts and objects design your interface, but it's the events that tie it all together and makes stuff happen. Whenever the user interacts with your program, events are triggered which you can then act upon. Some events are triggered by the library itself, for instance any object that is drawn will trigger a redraw event.

All events are added to the event queue, which can hold up to 100 events. Every time you query the event queue for an event, you will be returned to oldest triggered event, which will then be removed from the queue. Many events may be triggered that you don't really care about. In that case, you can simply ignore the event and it will disappear from the queue. Acting upon events is optional.

### Event Types

There are a few different event types. CONSTANTs are declared to help you identify these in your code.

{: .w3-table-all .w3-responsive}
| Event       | Description                                                 | Constant        |
|:------------|:------------------------------------------------------------|:----------------|
| Click       | Mouse click, left button                                    | eventClick      |
| Right-click | Mouse click, right button                                   | eventRightClick |
| Key Press   | Key pressed on keyboard                                     | eventKeyPress   |
| Toggle      | Radiobutton selected/unselected, checkbox checked/unchecked | eventToggle     |
| Edit        | Value (text) of textbox edited by user                      | eventEdit       |
| Redraw      | Object drawn or redrawn                                     | eventRedraw     |

In your code, you can use the handle of the object the event pertains to, and the constants above, to determine what has happened and what action to take.

### Catching Events

You catch events by putting a call to the Get_Event SUB in your programs main loop. You can choose to have the function return only if an event has been triggered, effectively pausing your code until that is the case - or you can have it return no event if nothing has happened. If you need to have your code still running while checking for events, if for instance you need to display a running timer on screen, this can be useful. If your program doesn't need to perform any actions until an event is triggered, you can choose to let the library take the reigns until that happens.

Events are returned as a variable of the user defined TYPE `EventType`. You must declare a variable of this type, and pass it to the `Get_Event` SUB. You can then use `SELECT CASE` or `IF` statements to check the variable and determine what event was triggered.

The `EventType` user defined TYPE will have these elements:

{: .w3-table-all .w3-responsive}
| Element | Description |
|:--------|:------------|
| ID      | ID (handle) of the object the user interacted with. Use the value returned by Create_Object to compare. For mouse clicks outside any object, the constant objMouse will be returned. For key presses unrelated to any object, the constant objKeyboard will be returned. For context redraws, the constant objScreen will be returned. |
| Event   | The triggered event - see previous  section for a list. |
| X       | The X (horizontal) coordinate of the mouse when event was triggered. |
| Y       | The Y (vertical) coordinate of the mouse when event was triggered.   |
| Key     | The key, if any, that was pressed on the keyboard. Notice that this will always be two characters, to allow for special keys. |

An example of how you can catch events follows here:

```vb
'This example assumes three objects (btnClose%, lblWelcomeMessage% and txtName%)
'have already been created

'Create variable for storing event
DIM EventObject AS EventType

DO
    'Get oldest event in queue, True means wait for event if queue is empty
    Get_Event EventObject, True

    'Check for mouse clicks
    IF EventObject.Event = eventClick THEN
        'Mouse was clicked, check if "Close" button was clicked
        IF EventObject.ID = btnClose% THEN EXIT DO
    END IF

    'Check for keyboard key press
    IF EventObject.Event = eventKeyPress THEN
        'Check if key pressed was enter (13) or escape (27)
        IF LEFT$(EventObject.Key, 1) = CHR$(13) OR LEFT$(EventObject.Key, 1) = CHR$(27) THEN EXIT DO
    END IF

    'Check for textbox edit
    IF EventObject.Event = eventEdit THEN
        'Is txtName% was edited, change label to show greeting message
        IF EventObject.ID = txtName% Then
            Set_Caption lblWelcomeMessage%, "Hello, " + Get_Value(txtName%)
            Draw_Object lblWelcomeMessage%
        END IF
    END IF
LOOP
```

### Triggering Events

It is possible to manually add an event to the queue. This can be useful in some scenarios. For instance, it might be that you in your code want to perform the same task as when a "Save" button is pressed. Rather than having the same code twice, or splitting it out in a separate SUB, you could just add a button click for the "Save" button to the event queue, which will then be picked up by your regular event handling code.

Events are queued using the `Queue_Event` SUB. For full reference, see the *Procedure References* section.

```vb
'Add a click event for the button btnSave% to the event queue
Queue_Event btnSave%, eventClick, 0, 0, ""

'Add an edit event for the textbox txtFilename% to the event queue
Queue_Event txtFilename%, eventEdit, 0,0, ""
```

## Files and Paths

The Costa UI Library, while focused on user interfaces, provides a few helper functions commonly used in programs.

The `Get_AppPath$` FUNCTION returns the path to the current program. This path is retrieved from DOS, and will always point to the location where the EXE file is stored, including a trailing backslash. This is useful if you want to open a file relative to the path of your program:

```vb
FileHandle% = FREEFILE

'Get_AppPath$ will return C:\COSTA\ or a similar path to your exe file
OPEN Get_AppPath$ + "DOCS\HELP.TXT" FOR INPUT AS #FileHandle%
CLOSE #FileHandle%
```

**Important!** This function does not work correctly when run inside VBDOS. The issue is that DOS will not return the path of your program, as it does not exist yet. It will instead return the path to VBDOS.EXE. To overcome this, run your program with the "/DEV" command line switch from within VBDOS using the *Run > Modify COMMAND$* menu, and the default path *C:\COSTA* will be used instead.
{: .w3-panel .w3-pale-yellow .w3-border}

The function `Test_Path%`, can be used to determine wether or not a file exists. It will return `True` if it does, or `False` if it doesn't. This can be useful to check if a file exists before opening, avoiding run-time errors if it doesn't.

```vb
'Check if file exists before opening
IF Test_Path%("C:\MYFILE.TXT") THEN
    'File exists, open it
    FileHandle% = FREEFILE
    OPEN "C:\MYFILE.TXT" FOR INPUT AS #FileHandle%
    '(program code here)
    CLOSE #FileHandle%
END IF
```

## Themes

The Costa UI Library can use color themes for the interface. These can be loaded using the `Set_Theme` SUB. If the chosen theme does not exist, default colors will be used. If you are fine with the default colors of the interface, you do not need to worry about themes at all. But if you want to use custom colors, themes allow you to easily do so.

Theme files can be edited using the Theme Editor included with the Costa Graphical Shell, available at [https://costa.jacobpalm.dk](https://costa.jacobpalm.dk). Themes must be placed in the *DATA\THEMES* subdirectory of your program.

## Procedure References

Yet to be written, stay tuned.

### Init_Library%

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Message$

Return value:

- Integer value `True` or `False`, indicating wether or not the library was initialized successfully.
- The Message$ variable passed to the function will contain an error message if initialization failed.

Example:

```vb
'Code example
```

### Get_AppPath$

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- None.

Return value:

- A string containing the path of your program.

Example:

```vb
'Code example
```

### Show_Aboutbox

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- AppName$ - the name of your program.
- Author$ - your name (author of the program).
- IconFile$ - filename without path or extension of an image file to show in the dialog

Return value:

- None.

Example:

```vb
'Code example
```

### Get_Event

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- EventObject
- WaitForEvent%

Return value:

- **INSERT TEXT**

### Queue_Event

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.
- EventID%
- X%
- Y%
- Key$

Return value:

- None

Example:

```vb
'Code example
```

### New_Context%

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- None.

Return value:

- Integer handle of the new context.

Example:

```vb
'Code example
```

### Set_Context

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Context% - handle of a context

Return value:

- None.

Example:

```vb
'Code example
```

### Get_Context%

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- None.

Return value:

- Integer handle of currently active context.

Example:

```vb
'Code example
```

### Remove_Context

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Context% - handle of context to remove.

Return value:

- None

Example:

```vb
'Code example
```

### New_RadioGroup%

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- None.

Return value:

- Integer handle of the new radio group.

Example:

```vb
'Code example
```

### New_Object%

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- ObjectType% - integer value defining which type of object to create. Use of predefined constants is recommended for code readability.

Return value:

- Integer handle of the new object.

Example:

```vb
'Code example
```

### Get_Enabled%

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object. - handle of object to return enabled/disabled state of

Return value:

- Integer value `True` or `False` indicating wether the object is enabled

Example:

```vb
'Code example
```

### Get_Hotkey$

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.

Return value:

- String containing the hotkey of the specified object

Example:

```vb
'Code example
```

### Get_Selected%

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Get_Value$

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Set_Background

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.
- Background%

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Set_Caption

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.
- Caption$

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Set_Enabled

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.
- Enabled%

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Set_Font

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.
- Font%

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Set_Hotkey

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.
- Hotkey$

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Set_MaxLength

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.
- MaxLength%

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Set_Selected

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.
- Selected%
- TriggerToggleEvent%

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Set_Size

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.
- X%
- Y%
- Length%
- Height%

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Set_RadioGroup

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.
- RadioGroup%

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Set_Transparent

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.
- Transparent%

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Set_Value

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.
- Value$

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Remove_Object

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Draw_Context

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Context%

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Draw_Object

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Handle% - Integer handle of an object.

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Draw_Text

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Text$
- X%
- Y%
- TextColor%
- Font%

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Show_Mouse

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- None.

Return value:

- None.

Example:

```vb
'Code example
```

### Hide_Mouse

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- None.

Return value:

- None.

Example:

```vb
'Code example
```

### Get_Mouse

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Button%
- X%
- Y%

Return value:

- **ADD TEXT**

Example:

```vb
'Code example
```

### Get_TextWidth%

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Text$
- Font%

Return value:

- Integer value corresponding to the width of the text, in pixels.

Example:

```vb
'Code example
```

### Test_FileExists%

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Filename$

Return value:

- Integer value `True` or `False` indicating wether the file exists.

Example:

```vb
'Code example
```

### Set_Theme

Description:

**INSERT DESCRIPTION HERE**.

Definition:

`A% = FUNCTION(PARAM1%, PARAM2%)`

Parameters:

- Filename$ - the filename without path or extension of the theme to load.

Return value:

- None.

Example:

```vb
'Code example
```
