unit UILOG;

interface

uses
	Costalib, UIArea, Graph;

type
	PLogEntry = ^String;

	PLogArea = ^TLogArea;
	TLogArea = Object(TUIObject)
		public
			Align:      TAlign;

			constructor Init(X, Y: Integer; Parent: PContainer);
			destructor  Done; virtual;

			procedure   Draw; virtual;

			procedure   AddEntry(Text: string);
			procedure   Clear;

			procedure   SetAlign(Val: TAlign);
		private
			LineCount,           {Number of lines added to log}
			MaxLines,            {Number of lines that will fit visually in log}
			MaxLength:  Integer; {Characters that will fit per line}
			Entries:    array[0..99] of PLogEntry;

			procedure   SetLimits;
			procedure   Scroll;
			procedure   DrawLine(Index: Integer);
	end;

implementation

const
	LogPadding        = 4;
	KeepLinesOnScroll = 3;

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
	Left := X;
	Top := Y;
	Width := DefaultW;
	Height := DefaultH;
	SetParent(Parent);
end;

procedure TLogArea.Draw;
var
	X1, X2, Y1, Y2: Integer;
	I: Integer;
	FgColor, BgColor: Byte;
	TestStr: String;
begin
	if SHidden in State then
		exit;

	{Get absolute position and size of the object}
	GetAbsPos(X1, Y1);
	X2 := X1 + Width;
	Y2 := Y1 + Height;

	BgColor := GetBgColor;
	if BgColor = ColorDefault then
		BgColor := Thm.Txt;

	{Draw the area using ancestor TArea}
	DrawUIPrimitive(UIBorderDown, X1, Y1, X2, Y2, BgColor, (STransparent in State));

	{Draw log lines}
	if LineCount > 0 then
		for I := 0 to LineCount - 1 do
			DrawLine(I);

	Inherited Draw;
end;

procedure TLogArea.AddEntry(Text: string);
begin
	{If first entry added, let's make sure max length and lines match size}
	if LineCount = 0 then
		SetLimits;

	if LineCount = MaxLines then
		Self.Scroll;

	{Truncate text if too wide}
	if Length(Text) > MaxLength then
		Text := Copy(Text, 1, MaxLength);

	Inc(LineCount);
	New(Entries[LineCount - 1]);
	Entries[LineCount - 1]^ := Text;

	{Draw the entry, unless entire object is going to be redrawn}
	if not (SDirty in State) then
	begin
		Mouse.Hide;
		Self.DrawLine(LineCount - 1);
		Mouse.Show;
	end;
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

	{Trigger redraw}
	Include(State, SDirty);
end;

procedure TLogArea.Scroll;
var
	i: integer;
begin
	{Move KeepLinesOnScroll items to beginning of Entries}
	for i := 0 to KeepLinesOnScroll - 1 do
	begin
		{Dispose existing strings before overwriting pointers}
		if Entries[i] <> nil then
			Dispose(Entries[i]);

		{Copy pointer from end to beginning}
		Entries[i] := Entries[LineCount - KeepLinesOnScroll + i];

		{Set pointer of copied item to nil so it doesn't get cleared below}
		Entries[LineCount - KeepLinesOnScroll + i] := nil;
	end;

	{Clear the rest of the lines}
	for i := KeepLinesOnScroll to High(Entries) do
	begin
		if Entries[i] <> nil then
		begin
			Dispose(Entries[i]);
			Entries[i] := nil;
		end;
	end;

	LineCount := KeepLinesOnScroll;
	Self.AddState(SDirty);
end;

procedure TLogArea.DrawLine(Index: Integer);
var
	X1, X2, Y1: Integer;
	PrintX, PrintY: Integer;
	FgColor: Byte;
begin
	if SHidden in State then
		exit;

	{Validate index}
	if (Index > MaxLines) or (Index > High(Entries)) or (Index < 0) then
		exit;
	if Entries[Index] = nil then
		exit;

	FgColor := GetFgColor;
	if FGColor = ColorDefault then
		FGColor := Thm.TxtText;

	{Get absolute position and size of the object}
	GetAbsPos(X1, Y1);
	X2 := Width;

	PrintY := Y1 + LogPadding + (Index * PrintLineH);
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
	X2 := Self.Width;
	Y2 := Self.Height;
	Dec(X2, LogPadding * 2);
	Dec(Y2, LogPadding * 2);
	MaxLength := X2 div PrintCharW;
	MaxLines := (Y2 + 4) div PrintLineH; {Minus 4 since we don't need line spacing on last line}
end;

procedure TLogArea.SetAlign(Val: TAlign);
begin
	Align := Val;
	Include(State, SDirty);
end;

destructor TLogArea.Done;
begin
	Self.Clear; {Free memory used by Entries array}

	Inherited Done;
end;

end.