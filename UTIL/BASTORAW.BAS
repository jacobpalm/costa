OPTION EXPLICIT
DEFINT A-Z

TYPE ThemeType
  Name AS STRING * 25
  Author AS STRING * 25
  Desktop AS INTEGER
  DesktopText AS INTEGER
  Window AS INTEGER
  WindowText AS INTEGER
  Button AS INTEGER
  Textbox AS INTEGER
  TextboxText AS INTEGER
  Light AS INTEGER
  Shadow AS INTEGER
  TitleBar AS INTEGER
  TitleBarText AS INTEGER
  Select AS INTEGER
  SelectText AS INTEGER
END TYPE

DIM TargetFile$, FoundFile$, Key$
DIM X, Y
DIM scrBuffer(260)
DIM Theme AS ThemeType

PRINT "Costa 2.0 and newer uses different file formats than previous versions."
PRINT
PRINT "This utility will convert all data files (images, themes, and desktop configs)"
PRINT "from older versions to a raw, plain text format. This format can then be"
PRINT "imported into the new version of Costa."
PRINT
PRINT "Do you wish to continue (Y/N)?"
DO
    Key$ = LCASE$(INKEY$)
    IF Key$ = "y" THEN EXIT DO
    IF Key$ = "n" THEN END
LOOP

CLS
PRINT "Converting DAT themes to raw string and integer data, please wait."

FoundFile$ = DIR$("DATA\THEMES\*.DAT")
DO WHILE NOT FoundFile$ = ""
    TargetFile$ = LEFT$(FoundFile$, LEN(FoundFile$) - 4)

    LOCATE 2, 1: PRINT STRING$(8, " ")
    LOCATE 2, 1: PRINT TargetFile$

    'Load theme
    OPEN "DATA\THEMES\" + TargetFile$ + ".DAT" FOR BINARY AS #1
    GET #1, , Theme
    CLOSE #1

    'Output name/author and integer color values to file
    OPEN "DATA\THEMES\" + TargetFile$ + ".RAW" FOR OUTPUT AS #1
    PRINT #1, RTRIM$(Theme.Name)
    PRINT #1, RTRIM$(Theme.Author)
    PRINT #1, Theme.Desktop
    PRINT #1, Theme.DesktopText
    PRINT #1, Theme.Window
    PRINT #1, Theme.WindowText
    PRINT #1, Theme.Button
    PRINT #1, Theme.Textbox
    PRINT #1, Theme.TextboxText
    PRINT #1, Theme.Light
    PRINT #1, Theme.Shadow
    PRINT #1, Theme.TitleBar
    PRINT #1, Theme.TitleBarText
    PRINT #1, Theme.Select
    PRINT #1, Theme.SelectText
    CLOSE #1

    'Get next file, if any
    FoundFile$ = DIR$
LOOP

END

SCREEN 9
PRINT "Themes converted."
PRINT
PRINT "Converting BSV images to raw integer data, please wait."

FoundFile$ = DIR$("DATA\IMAGES\*.BSV")
DO WHILE NOT FoundFile$ = ""
    TargetFile$ = LEFT$(FoundFile$, LEN(FoundFile$) - 4)

    LOCATE 4, 1: PRINT STRING$(8, " ")
    LOCATE 4, 1: PRINT TargetFile$

    'Load image and put on screen
    DEF SEG = VARSEG(scrBuffer(0))
    BLOAD "DATA\IMAGES\" + TargetFile$ + ".BSV", VARPTR(scrBuffer(0))
    DEF SEG
    PUT (50, 50), scrBuffer, PSET

    'Read each pixel and output to RAW file as integer color values
    OPEN "DATA\IMAGES\" + TargetFile$ + ".RAW" FOR OUTPUT AS #1
    FOR X = 0 TO 31
        FOR Y = 0 TO 31
            PRINT #1, POINT(X + 50, Y + 50)
        NEXT
    NEXT
    CLOSE #1

    'Get next file, if any
    FoundFile$ = DIR$
LOOP

SCREEN 0
PRINT "All images converted."

'DEBUG - run Pascal program to output converted files

'DEBUG - after Pascal program, delete RAW files from directories

