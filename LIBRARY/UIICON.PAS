unit UIICON;

interface

uses
	Costalib, Graph;

const
	IconSize = 31; {0-31 = 32x32 pixels}

type
	PIcon = ^TIcon;
	TIcon = object(TUIObject)
		public
			IconFile:   string[8];

			constructor Init(X, Y: Integer; Icon: string; Parent: PContainer);
			procedure   Draw; virtual;

			procedure   SetIcon(Icon: string);
	end;

implementation

constructor TIcon.Init(X, Y: Integer; Icon: string; Parent: PContainer);
var
	BorderWidth: Word;
begin
	TUIObject.Init;
	Left        := X;
	Top         := Y;
	BorderStyle := Bor3D;
	IconFile    := Icon;
	BgColor     := White;

	BorderWidth := Self.GetBorderWidth;
	Self.Width  := IconSize + (2 * BorderWidth);
	Self.Height := IconSize + (2 * BorderWidth);

	SetParent(Parent);
end;

procedure TIcon.Draw;
var
	X, Y: Integer;
	IconPointer: Pointer;
	Size, BorderWidth: Word;
	F: File;
	IconError: Boolean;
	Filename: String;
begin
	if SHidden in State then
		exit;

	{Icons are fixed size, so make sure width/height is correct}
	BorderWidth := Self.GetBorderWidth;
	Self.Width := IconSize + (2 * BorderWidth);
	Self.Height := IconSize + (2 * BorderWidth);
	DrawBorder;

	if Length(IconFile) = 0 then
	begin
		TUIObject.Draw;
		Exit;
	end;

	IconError := False;
	Filename := ProgramPath + 'ICONS\' + IconFile + '.BIN';
	if not FileExists(Filename) then
		IconError := True;

	Size := ImageSize(0, 0, 31, 31); {Coords don't matter, just size}

	{Get absolute position of the object}
	GetAbsPos(X, Y);

	{DEBUG - icon position depending on border?}

	if not IconError then
	begin
		Assign(F, Filename);
		{$I-}
		Reset(F, 1);
		{$I+}
		if (IOResult <> 0) then
			IconError := True
		else if (FileSize(F) <> Size) then
			IconError := True;

		if IconError then
			Close(F);
	end;
	{DEBUG - verify getmem and BlockRead}

	if not IconError then
	begin
		{All good, load and display icon}
		GetMem(IconPointer, Size);
		BlockRead(F, IconPointer^, Size);
		Close(F);
		PutImage(X + BorderWidth, Y + BorderWidth, IconPointer^, CopyPut);
		FreeMem(IconPointer, Size);
		IconPointer := nil;
	end
	else
	begin
		{Couldn't load icon, show error message}
		SetFillStyle(SolidFill, Red);
		Bar(X + BorderWidth, Y + BorderWidth, X + BorderWidth + IconSize, Y + BorderWidth + IconSize);
		Print('IMG' + #13 + 'ERR', X + BorderWidth + 5, Y + BorderWidth + 6, White);
	end;

	TUIObject.Draw;
end;

procedure TIcon.SetIcon(Icon: string);
begin
	if IconFile <> Icon then
	begin
		IconFile := Icon;
		Include(State, SDirty);
	end;
end;

end.