' The Costa GUI sample application
' By Jacob Palm
'
' This code demonstrates how to get started with a simple application using
' the Costa library, to create applications the have the look and feel of
' Costa.
'
' Any application utilizing the Costa library will have COSTALIB.BAS added to
' the project (MAK) file, and will include the COSTALIB.BI file to add the
' neccessary declarations.


'Require variable declaration - not needed, but used throughout Costa modules
OPTION EXPLICIT

'Declare SUBs and Functions used in this application
DECLARE SUB App.Main ()

'Include declarations (SUBs, functions, constants and shared variables) from
'the Costa library.
'$INCLUDE: 'SOURCE\COSTALIB.BI'

'Initialize Costa - this loads font files, user settings and theme colors,
'and sets the correct screen mode.
Sys.Load

'Call the main SUB of this application
App.Main

SUB App.Main ()

    'Create a new window, and set size - center on screen
    DIM winSample AS WindowType
    Obj.SetSize winSample.Pos, sizeCenter, sizeCenter, 244, 200

    'Create a button
    DIM btnExit AS ButtonType
    btnExit.Pos.Left = winSample.Pos.Left + 12
    btnExit.Pos.Top = winSample.Pos.Top + 34
    btnExit.Caption = "Eõxit"
    'The õ character determines which letter on the button is underlined.
    'This is actually handled by the font routine, and can be used anywhere
    'text is printed.
    
    'Create an icon. Only the filename, without extension or path, is set.
    'This is because icons are always in the same folder. An icon does not
    'use the width or height property, they are always 32x32 pixels.
    DIM imgSample AS ImageType
    imgSample.Pos.Top = winSample.Pos.Top + 34
    imgSample.Pos.Left = winSample.Pos.Left + 200
    imgSample.ImageFile = "CONFIG"

    'Draw the elements on the screen. The mouse does not need to be hidden
    'when drawing using Costa routines, they will take care of that
    'automatically. You must, however, hide the cursor while using LINE, PSET
    'and other built-in graphics statements.
    Obj.DrawWin winSample
    Obj.DrawBtn btnExit, False
    Font.Print "Sample text, header font", winSample.Pos.Left + 12, winSample.Pos.Top + 70, SystemTheme.WindowText, FontHeading
    Font.Print "Sample text, normal font", winSample.Pos.Left + 12, winSample.Pos.Top + 85, SystemTheme.WindowText, FontNormal
    Font.Print "Sample text, system font", winSample.Pos.Left + 12, winSample.Pos.Top + 100, SystemTheme.WindowText, FontSystem
    Obj.DrawImg imgSample

    'A variable to store keypresses
    DIM Key$

    DO

        'Fetch any pressed key, and convert to lowercase for easier
        'comparison later on
        Key$ = LCASE$(INKEY$)

        'Obj.BtnClick will return True or False (constants declared in
        'COSTALIB.BI), and can be used to check if a button is clicked. It
        'will also take care of drawing the button in pressed or unpressed
        'state.
        IF Obj.BtnClick(btnExit) OR Key$ = "x" THEN

            'Show a messagebox, asking to confirm that the user wants to exit.
            'msgQuest is a constant from COSTALIB.BI, used to indicate the
            'type of messagebox we want to show (question, error etc.).
            IF Sys.MsgBox("Exit sample application", "Are you sure you want to exit the sample" + CHR$(13) + "application?", msgQuest) = True THEN
                END
            END IF

        END IF
        
    LOOP

END SUB

