{The sole purpose of this unit is to link in the
 EGA/VGA graphics driver from an external OBJ file,
 so that it can be used by Costa without having to
 include the BGI file in the distrubution. It is
 only used by COSTALIB.PAS, other units/programs
 do not need to reference it.}

unit EGADriv;

interface

procedure EgaVgaDriverProc;

implementation

procedure EgaVgaDriverProc; external;
{$L EGAVGA.OBJ }

end.
