unit UILOG;

interface

uses
	Costalib, UIArea, Graph;

type
	PLogEntry = ^String;

	PLogArea = ^TLogArea;
	TLogArea = Object(TArea)
		public
			constructor Init(X, Y: Integer; Parent: PContainer);
			destructor  Done; virtual;

			procedure   Draw; virtual;

			procedure   AddEntry(Text: string);
			procedure   Clear;

			procedure   SetAlign(Val: TAlign);
			function    GetAlign: TAlign;
		private
			LineCount,           {Number of lines added to log}
			MaxLines,            {Number of lines that will fit visually in log}
			MaxLength:  Integer; {Characters that will fit per line}
			Entries:    array[0..99] of PLogEntry;
			Align:      TAlign;

			procedure   SetLimits;
			procedure   DrawLine(Index: Integer);
	end;

implementation

const
	LogPadding = 4;

constructor TLogArea.Init(X, Y: Integer; Parent: PContainer);
const
	DefaultW = 350;
	DefaultH = 200;
begin
	TUIObject.Init;
	MaxLength := 0;
	MaxLines := 0;
	LineCount := 0;
	Align := AlLeft;
	FillChar(Entries, SizeOf(Entries), 0);

	SetParent(Parent);
	SetSize(DefaultW, DefaultH);
	SetPos(X, Y);
end;

procedure TLogArea.Draw;
var
	X1, X2, Y1, Y2: Integer;
	FgColor, BgColor: Byte;
	TestStr: String;
begin
	if GetState(SHidden) then
		exit;

	{Get absolute position and size of the object}
	GetPos(X1, Y1, True);
	GetSize(X2, Y2);
	Inc(X2, X1);
	Inc(Y2, Y1);

	{Draw the area using ancestor TArea}
	TArea.Draw;

	if GetState(SDirty) then
	begin
		AddEntry('Still dirty');
		RemoveState(SDirty);
	end;
	{Draw log lines}
	{DEBUG}
end;

procedure TLogArea.AddEntry(Text: string);
begin
	{If first entry added, let's make sure max length and lines match size}
	if LineCount = 0 then
		SetLimits;

	if LineCount = MaxLines then
		Self.Clear; {Debug - carry a couple of lines over instead of just clearing}

	{Truncate text if too wide}
	if Length(Text) > MaxLength then
		Text := Copy(Text, 1, MaxLength);

	Inc(LineCount);
	New(Entries[LineCount - 1]);
	Entries[LineCount - 1]^ := Text;

	Mouse.Hide;
	Self.DrawLine(LineCount - 1);
	Mouse.Show;
end;

procedure TLogArea.Clear;
var
	i: integer;
begin
	for i := 0 to High(Entries) do
		if Entries[i] <> nil then
			Dispose(Entries[i]);

	FillChar(Entries, SizeOf(Entries), 0);

	LineCount := 0;

	AddState(SDirty);
end;

procedure TLogArea.DrawLine(Index: Integer);
var
	X1, X2, Y1, Y2: Integer;
	PrintX, PrintY: Integer;
	FgColor: Byte;
begin
	if GetState(SHidden) then
		exit;

	{Validate index}
	if (Index > MaxLines) or (Index > High(Entries)) then
		exit;
	if Entries[Index] = nil then
		exit;

	FgColor := GetFgColor;
	if FGColor = ColorDefault then
		FGColor := Thm.TxtText;

	{Get absolute position and size of the object}
	GetPos(X1, Y1, True);
	GetSize(X2, Y2);

	PrintY := Y1 + LogPadding + ((LineCount - 1) * PrintLineH);
	case Align of
		AlCenter:
			PrintX := (X2 - PrintW(Entries[Index]^)) div 2 + X1;
		AlRight:
			PrintX := X1 + X2 - LogPadding - PrintW(Entries[Index]^);
		else
			PrintX := X1 + LogPadding;
	end;

	Print(Entries[Index]^, PrintX, PrintY, FgColor);
end;

procedure TLogArea.SetLimits;
var
	X2, Y2: Integer;
begin
	GetSize(X2, Y2);
	Dec(X2, LogPadding * 2);
	Dec(Y2, LogPadding * 2);
	MaxLength := X2 div PrintCharW;
	MaxLines := (Y2 + 4) div PrintLineH; {Minus 4 since we don't need line spacing on last line}
end;

procedure TLogArea.SetAlign(Val: TAlign);
begin
	Align := Val;
	AddState(SDirty);
end;

function TLogArea.GetAlign: TAlign;
begin
	GetAlign := Align;
end;

destructor TLogArea.Done;
begin
	Self.Clear; {Free memory used by Entries array}
end;

end.