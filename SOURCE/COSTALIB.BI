'Procedure declarations
  DECLARE FUNCTION File.Exists% (TargetFile AS STRING)
  DECLARE FUNCTION File.GetAssociation (FileType AS STRING) AS STRING
  DECLARE FUNCTION File.Select (Pattern AS STRING) AS STRING

  DECLARE FUNCTION Font.GetWidth% (TargetText AS STRING, FontID%)
  DECLARE SUB Font.Print (BYVAL Text AS STRING, X%, Y%, Col%, FontID%)

  DECLARE FUNCTION Mouse.Clicked% ()
  DECLARE FUNCTION Mouse.InArea% (TargetArea AS ANY)
  DECLARE SUB Mouse.Hide ()
  DECLARE SUB Mouse.Poll ()
  DECLARE SUB Mouse.SetBounds (MinX%, MinY%, MaxX%, MaxY%)
  DECLARE SUB Mouse.SetPos (XPos%, YPos%)
  DECLARE SUB Mouse.Show ()

  DECLARE FUNCTION Obj.BtnClick% (TargetBtn AS ANY)
  DECLARE FUNCTION Obj.TxtClick% (TargetTxt AS ANY)
  DECLARE SUB Obj.ChkClick (chkCheck AS ANY)
  DECLARE SUB Obj.SetSize (TargetArea AS ANY, TargetLeft%, TargetTop%, TargetWidth%, TargetHeight%)
  DECLARE SUB Obj.EditTxt (TargetTxt AS ANY, Text AS STRING)
  DECLARE SUB Obj.DrawBtn (TargetBtn AS ANY, Pressed AS INTEGER)
  DECLARE SUB Obj.DrawChk (TargetChk AS ANY)
  DECLARE SUB Obj.DrawFrm (TargetFrm AS ANY, LightColor%, DarkColor%)
  DECLARE SUB Obj.DrawImg (TargetImg AS ANY)
  DECLARE SUB Obj.DrawMenu ()
  DECLARE SUB Obj.DrawTxt (TargetTxt AS ANY, BYVAL Text AS STRING, IsEditing AS INTEGER)
  DECLARE SUB Obj.DrawWin (TargetWin AS ANY)

  DECLARE FUNCTION Sys.InputBox (msgTitle AS STRING, BYVAL msgText AS STRING, msgIcon AS STRING, msgDefault AS STRING) AS STRING
  DECLARE FUNCTION Sys.MsgBox% (msgTitle AS STRING, BYVAL msgText AS STRING, msgType%)
  DECLARE FUNCTION Sys.Path () AS STRING
  DECLARE SUB Sys.AboutBox (ProgramName AS STRING, ProgramAuthor AS STRING, ImageFile AS STRING)
  DECLARE SUB Sys.Delay (Seconds AS SINGLE)
  DECLARE SUB Sys.Load ()
  DECLARE SUB Sys.LoadProfile (ProfileNum%)
  DECLARE SUB Sys.LoadSettings ()
  DECLARE SUB Sys.LoadTheme ()
  DECLARE SUB Sys.SaveProfile (ProfileNum%)
  DECLARE SUB Sys.SaveSettings ()
  DECLARE SUB Sys.ShowLoading ()

  DECLARE FUNCTION Temp.Path () AS STRING

'App name, version etc.
  '$INCLUDE: 'C:\COSTA\SOURCE\APPINFO.BI'

'Boolean constants
  CONST False = 0
  CONST True = NOT False

'Mouse constants
  CONST mbLeft = 1
  CONST mbRight = 2
  CONST mbBoth = 3

'Font type constants
  CONST FontHeading = 1
  CONST FontNormal = 2
  CONST FontSystem = 3

'Messagebox constants
  CONST msgInfo = 1
  CONST msgWarn = 2
  CONST msgQuest = 3
  CONST msgError = 4
  CONST msgTip = 5

'Size/position constants
  CONST sizeRetain = -1
  CONST sizeCenter = -2

'Type declarations
  TYPE PosType
    Left AS INTEGER
    Top AS INTEGER
    Width AS INTEGER
    Height AS INTEGER
  END TYPE

  TYPE ButtonType
    Pos AS PosType
    Caption AS STRING * 25
    Transparent AS INTEGER
  END TYPE

  'The textbox doesn't have a TEXT property. Uses a string variable instead.
  'This is to avoid fixed-length strings
  TYPE TextboxType
    Pos AS PosType
    MaxLen AS INTEGER
  END TYPE

  TYPE FrameType
    Pos AS PosType
  END TYPE

  TYPE ImageType
    Pos AS PosType
    ImageFile AS STRING * 8
  END TYPE
  
  TYPE WindowType
    Pos AS PosType
  END TYPE

  TYPE CheckBoxType
    Pos AS PosType
    Checked AS INTEGER
  END TYPE

  TYPE SettingType
    DesktopID AS INTEGER
    ShowLinkDescriptions AS INTEGER
    ShowLinkTargetFiles AS INTEGER
    ConfirmLinkDelete AS INTEGER
    ConfirmExit AS INTEGER
    AssignFileTypes AS INTEGER
    ThemeFile AS STRING * 8
  END TYPE

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

  TYPE FileAssociationType
    FileType AS STRING * 3
    Command AS STRING * 50
  END TYPE

'Common shared variables
  COMMON SHARED Setting AS SettingType
  COMMON SHARED Theme AS ThemeType

  COMMON SHARED MouseX AS INTEGER
  COMMON SHARED MouseY AS INTEGER

