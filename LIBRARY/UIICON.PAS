unit UIICON;

interface

uses
	Costalib, Graph;

type
	PIcon = ^TIcon;
	TIcon = object(TUIObject)
		public
			constructor Init(X, Y: Integer; Icon: string; Parent: PContainer);
			procedure   Draw; virtual;

			procedure   SetIcon(Icon: string);
			function	  GetIcon: string;
		private
			IconFile:   string[8];
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

	AddState(SBordered);
	SetParent(Parent);
	SetPos(X, Y);
	SetSize(DefaultW, DefaultH);
	SetBgColor(Thm.Txt);
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
	if GetState(SHidden) then
		exit;

	IconError := False;
	Filename := ProgramPath + 'ICONS\' + IconFile + '.BIN';
	if not FileExists(Filename) then
		IconError := True;

	Size := ImageSize(0, 0, 31, 31); {Coords don't matter, just size}

	{Get absolute position of the object}
	GetPos(X, Y, True);

	{Icon border}
	if Self.GetState(SBordered) then
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
		AddState(SDirty);
	end;
end;

function TIcon.GetIcon: string;
begin
	GetIcon := IconFile;
end;

end.