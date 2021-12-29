DECLARE SUB Conf.SaveAssoc (FileType AS STRING, Command AS STRING)
DEFINT A-Z
'$INCLUDE: 'SOURCE\COSTALIB.BI'

Sys.Load

SCREEN 0
COLOR 7, 1
CLS

DIM c AS STRING

DO
INPUT "cmd (r, w, u, a, x)? ", c

SELECT CASE c
  CASE "r"

    PRINT "Get TXT: ";
    PRINT File.GetAssociation("TXT")

    PRINT "Get THM: ";
    PRINT File.GetAssociation("THM")

    PRINT "Get INI: ";
    PRINT File.GetAssociation("INI")

    PRINT "Get CFG: ";
    PRINT File.GetAssociation("CFG")

    PRINT "Get 1ST: ";
    PRINT File.GetAssociation("1ST")

    PRINT "Get ME: ";
    PRINT File.GetAssociation("ME")

    PRINT "Get JPA: ";
    PRINT File.GetAssociation("JPA")

    PRINT "Get JPC: ";
    PRINT File.GetAssociation("JPC")

    PRINT "Get KAS: ";
    PRINT File.GetAssociation("KAS")


  CASE "u"

    PRINT "Set CFG"
    Conf.SaveAssoc "CFG", "JACOB"

    PRINT "Get CFG: ";
    PRINT File.GetAssociation("CFG")

  CASE "w"

    DIM f
    DIM l
    DIM t(0 TO 6) AS FileAssociationType

    ON ERROR RESUME NEXT
    KILL Sys.Path + "\DATA\CONFIG\FILETYPE.DAT"
    ON ERROR GOTO 0

    f = FREEFILE
    OPEN Sys.Path + "\DATA\CONFIG\FILETYPE.DAT" FOR BINARY AS #f


    t(0).FileType = "TXT"
    t(0).Command = "TEXTVIEW.EXE"
    PUT #f, , t(0)

    t(1).FileType = "INI"
    t(1).Command = "TEXTVIEW.EXE"
    PUT #f, , t(1)
    t(2).FileType = "THM"
    t(2).Command = "THMEDIT.EXE"
    PUT #f, , t(2)

    t(3).FileType = "DOC"
    t(3).Command = "TEXTVIEW.EXE"
    PUT #f, , t(3)
    t(4).FileType = "ME"
    t(4).Command = "TEXTEDIT.EXE"
    PUT #f, , t(4)
    t(5).FileType = "1ST"
    t(5).Command = "TEXTEDIT.EXE"
    PUT #f, , t(5)

    t(5).FileType = "CFG"
    t(5).Command = "TEXTEDIT.EXE"
    PUT #f, , t(5)


    CLOSE #f

  CASE "a"
    DIM ext AS STRING, cmd AS STRING
    INPUT "FileType? ", ext
    INPUT "Command? ", cmd
    Conf.SaveAssoc ext, cmd

  CASE "x"
    END

END SELECT
LOOP

SUB Conf.SaveAssoc (FileType AS STRING, Command AS STRING)

  DIM FileAssociation AS FileAssociationType
  DIM FileHandle, FilePos, AssocSaved

  IF File.Exists(Sys.Path + "\DATA\CONFIG\FILETYPE.DAT") THEN
    FileHandle = FREEFILE
    OPEN Sys.Path + "\DATA\CONFIG\FILETYPE.DAT" FOR BINARY AS #FileHandle

    'ON LOCAL ERROR RESUME NEXT
    DO WHILE NOT EOF(FileHandle)

      FilePos = LOC(FileHandle)
      GET #FileHandle, , FileAssociation

      'See if extension is already known, update command if so
      IF UCASE$(FileType) = RTRIM$(FileAssociation.FileType) THEN
        FileAssociation.Command = UCASE$(Command)
        'SEEK #FileHandle, FilePos
        PUT #FileHandle, FilePos + 1, FileAssociation
        AssocSaved = True
        EXIT DO
      END IF

    LOOP

    'Extension was not in file, add it
    IF NOT AssocSaved THEN
      FileAssociation.FileType = UCASE$(FileType)
      FileAssociation.Command = UCASE$(Command)
      PUT #FileHandle, , FileAssociation
    END IF

    CLOSE #FileHandle
    ON LOCAL ERROR GOTO 0

  END IF

END SUB

