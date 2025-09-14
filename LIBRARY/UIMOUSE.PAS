unit UIMouse;

interface

uses
	Dos, Graph;

type
	TMouseButton  = (MbNone, MbLeft, MbRight, MbBoth);

	TMouse = object
		public
			constructor Init;
			procedure   Poll;
			procedure   Move(Left, Top: Integer);
			function    Clicked: TMouseButton;
			function    Supported: Boolean;
			function    X: Integer;
			function    Y: Integer;
			procedure   Hide;
			procedure   Show;
		private
			Visible,
			Support:    Boolean;
			XPos, YPos: Integer;
	end;

implementation

constructor TMouse.Init;
var
	regs: registers;
begin
	Visible := False;

	{Check for mouse support}
	Intr($33, regs);
	Support := Regs.ax > 0;

	{Get initial mouse position}
	Self.Poll;
end;

function TMouse.Clicked: TMouseButton;
var
	regs: registers;
begin
	if not Support then
	begin
		Clicked := MbNone;
		exit;
	end;

	regs.ax := 3;
	Intr($33, regs);
	Clicked := TMouseButton(regs.bx);
end;

Procedure TMouse.Hide;
Var
	Regs: Registers;
Begin
	{Don't call interrupt if no mouse or already hidden}
	If Not Support Or Not Visible Then
		Exit;
	Regs.ax := 2;
	Intr($33, Regs);
	Visible := False;
End;

procedure TMouse.Poll;
var
	regs: registers;
begin
	if not Support then
		Exit;
	regs.ax := 3;
	Intr($33, regs);
	XPos := regs.cx;
	YPos := regs.dx;
end;

procedure TMouse.Move(Left, Top: Integer);
var
	regs: registers;
begin
	{Can't move mouse if no mouse support}
	if not Support then
		Exit;
	
	if (Left < 0) or (Left > GetMaxX) or 
	   (Top < 0) or (Top > GetMaxY) then
		Exit; {Out of bounds}

	regs.ax := 4;
	regs.cx := Left;
	regs.dx := Top;
	Intr($33, regs);
end;

Procedure TMouse.Show;
Var
	Regs: Registers;
Begin
	{Don't call interrupt if no mouse or already visible}
	If Not Support Then
		Exit;
	Regs.ax := 1;
	Intr($33, Regs);
	Visible := True;
End;

Function TMouse.Supported: Boolean;
Begin
	Supported := Support;
End;

Function TMouse.X: Integer;
Begin
	X := XPos;
End;

Function TMouse.Y: Integer;
Begin
	Y := YPos;
End;

end.