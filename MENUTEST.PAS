program MenuTest;

uses
	CostaLib, Graph;

var
	App: PApplication;
	Win: PWindow;
	Menu: PMenu;
	Item1, Item2, Item3: PMenuItem;
	HkExit: PHotkey;

procedure HkExitClick(Sender: PUIObject); far;
var
	X, Y: Integer;
begin
	App^.Terminate;
end;

procedure Item3Click(Sender: PUIObject); far;
begin
	App^.Terminate;
end;

begin
	New(App, Init);

	New(Win, Init(0, 0, nil));
	with Win^ do
	begin
		SetSize(300, 200);
		Center(OrBoth);
	end;

	New(Menu, Init(MSMenuBar, Win));
	with Menu^ do
	begin
		SetPos(6, 6);
		SetSize(288, 16);
	end;

	New(Item1, Init('Item ' + HotkeyChr + '1', False, Menu));
	New(Item2, Init('Itemq 2', False, Menu));
	New(Item3, Init('E' + HotkeyChr + 'xit', False, Menu));
	Item3^.OnClick := Item3Click;
	Item3^.AddHotkey(KeyAltX);

	New(HkExit, Init(KeyEscape, Win));
	HkExit^.OnClick := HkExitClick;

	App^.OpenWindow(Win);
	App^.Run;
	App^.Terminate;
end.