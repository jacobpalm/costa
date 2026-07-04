unit UIICON;

interface

uses
	Costalib, Graph;

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
const
	DefaultW = 31;
	DefaultH = 31;
begin
	TUIObject.Init;
	if Length(Icon) <= 8 then
		IconFile := Icon
	else
		IconFile := '';

	Left := X;
	Top := Y;
	Width := DefaultW;
	Height := DefaultH;

	Include(State, SBordered);
	SetParent(Parent);
end;

procedure TIcon.Draw;
var
	X, Y: Integer;
	IconPointer: Pointer;
	Size: Word;
	F: File;
	IconError: Boolean;
	Filename: String;
	BgColor: Byte;
begin
	if SHidden in State then
		exit;

	IconError := False;
	Filename := ProgramPath + 'ICONS\' + IconFile + '.BIN';
	if not FileExists(Filename) then
		IconError := True;

	Size := ImageSize(0, 0, 31, 31); {Coords don't matter, just size}

	{Get absolute position of the object}
	GetAbsPos(X, Y);

	{Icon border}
	if SBordered in State then
		DrawUIPrimitive(UIBorderUp, X - 2, Y - 2, X + 33, Y + 33, 0, True);

	{If no Icon file, draw an empty box}
	if Length(IconFile) = 0 then
	begin
		BgColor := GetBgColor;
		If BgColor = ColorDefault then
			BgColor := Thm.Txt;
		SetFillStyle(SolidFill, BgColor);
		Bar(X, Y, X + 31, Y + 31);
		TUIObject.Draw;
		Exit;
	end;

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
		GetMem(IconPointer, Size);
		BlockRead(F, IconPointer^, Size);
		Close(F);
		PutImage(X, Y, IconPointer^, CopyPut);
		FreeMem(IconPointer, Size);
		IconPointer := nil;
	end;

	if IconError then
	begin
		SetFillStyle(SolidFill, Red);
		Bar(X, Y, X + 31, Y + 31);
		Print('IMG' + #13 + 'ERR', X + 5, Y + 6, White);
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