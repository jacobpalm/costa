'Procedure declarations
    DECLARE FUNCTION File.CfgRead (BYVAL CfgFile AS STRING, Setting AS STRING, DefaultValue AS STRING) AS STRING
    DECLARE FUNCTION File.Exists% (TargetFile AS STRING)
    DECLARE SUB File.CfgWrite (BYVAL CfgFile AS STRING, Setting AS STRING, Value AS STRING)
    DECLARE SUB File.Run (BYVAL TargetFile AS STRING, BYVAL TargetParameters AS STRING, BYVAL TargetPath AS STRING, PauseOnExit AS INTEGER)

    DECLARE FUNCTION Font.GetWidth% (TargetText AS STRING, FontID%)
    DECLARE SUB Font.Print (BYVAL Text AS STRING, X%, Y%, Col%, FontID%)

    DECLARE FUNCTION Mouse.Clicked% ()
    DECLARE FUNCTION Mouse.InArea% (TargetArea AS ANY)
    DECLARE FUNCTION Mouse.X% ()
    DECLARE FUNCTION Mouse.Y% ()
    DECLARE SUB Mouse.Driver (M0%, M1%, M2%, M3%)
    DECLARE SUB Mouse.Hide ()
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
    DECLARE SUB Obj.DrawTxt (TargetTxt AS ANY, BYVAL Text AS STRING, IsEditing AS INTEGER)
    DECLARE SUB Obj.DrawWin (TargetWin AS ANY)

    DECLARE FUNCTION Sys.InputBox (msgTitle AS STRING, BYVAL msgText AS STRING, msgIcon AS STRING, msgDefault AS STRING) AS STRING
    DECLARE FUNCTION Sys.MsgBox% (msgTitle AS STRING, BYVAL msgText AS STRING, msgType%)
    DECLARE FUNCTION Sys.Path () AS STRING
    DECLARE SUB Sys.Delay (Seconds AS SINGLE)
    DECLARE SUB Sys.Load ()
    DECLARE SUB Sys.LoadProfile (ProfileNum%)
    DECLARE SUB Sys.LoadSettings ()
    DECLARE SUB Sys.LoadTheme ()
    DECLARE SUB Sys.SaveProfile (ProfileNum%)
    DECLARE SUB Sys.SaveSettings ()
    DECLARE SUB Sys.VGALoad (TargetFile AS STRING)
    DECLARE SUB Sys.VGASave (TargetFile AS STRING)

'App name, version etc.
    '$INCLUDE: 'C:\COSTA\SOURCE\APPINFO.BI'

'Boolean constants
    CONST False = 0
    CONST True = NOT False

'Mouse constants
    CONST mbLeft = -1
    CONST mbRight = -2
    CONST mbBoth = -3

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
    HotKey AS INTEGER
    Transparent AS INTEGER
  END TYPE

  'The textbox doesn't have a TEXT property. Uses a string variable instead.
  'This is to avoid fixed-lenght strings
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
    Caption AS STRING * 40
  END TYPE

  TYPE CheckBoxType
    Pos AS PosType
    Checked AS INTEGER
  END TYPE

  TYPE SystemSettingsType
    UseLastProfile AS INTEGER
    LastUsedProfile AS INTEGER
  END TYPE

  TYPE UserSettingsType
    ProfileName AS STRING * 25
    ProfileImage AS STRING * 8
    Animations AS INTEGER
    ShowLinkDescriptions AS INTEGER
    ShowLinkTargetFiles AS INTEGER
    LinkMenuOnLeftClick AS INTEGER
    ConfirmLinkDelete AS INTEGER
    ConfirmExit AS INTEGER
    TipOfTheDay AS INTEGER
    TipLastShown AS INTEGER
    AssignFileTypes AS INTEGER
    GreyoutOnMsgBox AS INTEGER
    ThemeFile AS STRING * 8
  END TYPE

'Common shared variables
  COMMON SHARED ProfileID AS STRING

  COMMON SHARED SystemSettings AS SystemSettingsType
  COMMON SHARED UserSettings AS UserSettingsType

  COMMON SHARED ClrThemeFile AS STRING

  COMMON SHARED ClrDesktop AS INTEGER
  COMMON SHARED ClrDesktopText AS INTEGER
  COMMON SHARED ClrWindow AS INTEGER
  COMMON SHARED ClrWindowText AS INTEGER
  COMMON SHARED ClrButton AS INTEGER
  COMMON SHARED ClrTextbox AS INTEGER
  COMMON SHARED ClrTextboxText AS INTEGER
  COMMON SHARED Clr3DLight AS INTEGER
  COMMON SHARED Clr3DShadow AS INTEGER
  COMMON SHARED ClrTitleBar AS INTEGER
  COMMON SHARED ClrTitleBarText AS INTEGER
  COMMON SHARED ClrSelect AS INTEGER
  COMMON SHARED ClrSelectText AS INTEGER

