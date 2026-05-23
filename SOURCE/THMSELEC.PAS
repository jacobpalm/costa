{Theme object selection dialog used by THMEDIT.PAS}
unit THMSELEC;

interface

const
	CAP_OBJECT: array[0..12] of string = (
		'Desktop', 'Desktop text', 'Window', 'Window border', 'Window title',
		'Window text', 'Button', 'Textbox', 'Textbox text', '3D light',
		'3D Shadow', 'Selection', 'Selection text');

type
	TThemeObject = (Desk, DeskText, Win, Title, TitleText,
	                WinText, Btn, Txt, TxtText, Light, Shadow,
	                Sel, SelText);

function SelectThemeObject(CurrentSelection: TThemeObject): TThemeObject;

implementation

uses
	CostaLib, UIButton, Graph, DOS;

const
	Up   = 0;
	Down = 1;

var
	WinSelectObject:   PWindow;
	BtnObject:         Array[0..12] of PButton;
	HkArrow:           Array[0..1] of PHotkey;
	HkEnter,
	HkEscape:          PHotkey;

	OriginalSelection,
	ActiveSelection:   TThemeObject;

{Buttons in object selection dialog}
procedure BtnObjectClick(Sender: PUIObject); far;
var
	i: integer;
begin
	{Check which button was pressed}
	for i := 0 to High(BtnObject) do
	begin
		if Sender = PUIObject(BtnObject[i]) then
		begin
			ActiveSelection := TThemeObject(i);
			WinSelectObject^.Close;
			Exit;
		end;
	end;
end;

procedure HkEnterClick(Sender: PUIObject); far;
begin
	{ActiveSelection already contains right value, so just close window}
	WinSelectObject^.Close;
end;

procedure HkEscClick(Sender: PUIObject); far;
begin
	ActiveSelection := OriginalSelection;
	WinSelectObject^.Close;
end;

procedure HkArrowClick(Sender: PUIObject); far;
var
	NextSelection: integer;
begin
	BtnObject[Ord(ActiveSelection)]^.RemoveState(SActive);
	if Sender = PUIObject(HkArrow[Up]) then
		NextSelection := Ord(ActiveSelection) - 1
	else
		NextSelection := Ord(ActiveSelection) + 1;

	if NextSelection < 0 then
		NextSelection := High(BtnObject)
	else if NextSelection > High(BtnObject) then
		NextSelection := 0;

	ActiveSelection := TThemeObject(NextSelection);
	BtnObject[Ord(ActiveSelection)]^.AddState(sActive);
end;

procedure InitUI;
var
	i: integer;
	X1, Y1, X2, Y2: Integer;
begin
	{Object selection window}
	New(WinSelectObject, Init(0, 0, nil));
	With WinSelectObject^ do
	begin
		SetSize(226, 326);
		SaveBackdrop;
		Center(OrBoth);
	end;

	for i := 0 to High(BtnObject) do
	begin
		New(BtnObject[I], Init(13, I * 23 + 15, CAP_OBJECT[I], WinSelectObject));
		BtnObject[I]^.SetSize(200, SizeRetain);
		BtnObject[I]^.SetOnClick(BtnObjectClick);
	end;
	BtnObject[Ord(ActiveSelection)]^.AddState(SActive);

	New(HkArrow[Up], Init(KeyUp, WinSelectObject));
	HkArrow[Up]^.SetOnClick(HkArrowClick);
	New(HkArrow[Down], Init(KeyDown, WinSelectObject));
	HkArrow[Down]^.SetOnClick(HkArrowClick);
	New(HkEnter, Init(KeyEnter, WinSelectObject));
	HkEnter^.SetOnClick(HkEnterClick);
	New(HkEscape, Init(KeyEscape, WinSelectObject));
	HkEscape^.SetOnClick(HkEscClick);
end;

function SelectThemeObject(CurrentSelection: TThemeObject): TThemeObject;
begin
	ActiveSelection := CurrentSelection;
	OriginalSelection := CurrentSelection;

	InitUI;
	WinSelectObject^.Run;
	Dispose(WinSelectObject, Done);
	WinSelectObject := nil;

	SelectThemeObject := ActiveSelection;
end;

end.