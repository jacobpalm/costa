unit UIICON;

interface

uses
	Costalib, Graph;

type
	TIcon = object(TUIObject)
		public
			constructor Init(X, Y: Integer; Icon: string);
			procedure   Draw; virtual;
			procedure   SetIcon(Icon: string);
		private
			IconFile:   string[8];
	end;

implementation

constructor TIcon.Init(X, Y: Integer; Icon: string);
const
	DefaultW = 31;
	DefaultH = 31;
begin
	Self.SetSize(X, Y, SizeDefault, SizeDefault, DefaultW, DefaultH);
	IconFile := Icon;
end;

procedure TIcon.Draw;
var
	X, Y: Integer;
	IconPointer: Pointer;
	Size: Word;
	F: File;
	IconError: Boolean;
	Filename: String;
begin
	IconError := False;
	
	Filename := ProgramPath + 'ICONS\' + IconFile + '.BIN';
	if not FileExists(Filename) then
		IconError := True;

	Size := ImageSize(0, 0, 31, 31); {Coords don't matter, just size}
	
	X := Left;
	Y := Top;

	{Icon border}
	SetColor(Thm.Light);
	Line(X - 1, Y - 1, X + 32, Y - 1);
	Line(X - 1, Y, X - 1, Y + 32);
	SetColor(Thm.Shadow);
	Line(X, Y + 32, X + 32, Y + 32);
	Line(X + 32, Y, X + 32, Y + 31);

	{If no Icon file, draw an empty box}
	if Length(IconFile) = 0 then
	begin
		SetFillStyle(SolidFill, White);
		Bar(X, Y, X + 31, Y + 31);
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
	end;

	if IconError then
	begin
		SetFillStyle(SolidFill, Red);
		Bar(X, Y, X + 31, Y + 31);
		Print('IMG' + #13 + 'ERR', X + 5, Y + 6, White);
	end;
end;

procedure TIcon.SetIcon(Icon: string);
begin
	IconFile := Icon;
	MouseHide;
	Self.Draw;
	MouseShow;
end;

end.