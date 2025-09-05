unit UIWINDOW;

interface

uses
	Costalib, Graph;

type
	TWindow = object(TUIObject)
		public
			constructor Init(X, Y, W, H: Integer);
			destructor  Done; virtual;
			procedure   AddObject(Obj: PBaseObject);
			procedure   Draw; virtual;
		private
			Objects:    PObjectNode;
	end;

implementation

constructor TWindow.Init(X, Y, W, H: Integer);
const
	DefaultW = 320;
	DefaultH = 175;
begin
	Self.SetSize(X, Y, W, H, DefaultW, DefaultH);
end;

procedure TWindow.AddObject(Obj: PBaseObject);
var
	NewNode, LastNode: PObjectNode;
begin
	New(NewNode);
	NewNode^.ObjectP := Obj;
	NewNode^.Next := nil;

	{If this is the first object, set it as head of the list,
	 otherwise, find the end of the list and add it there}
	if Objects = nil then
		Objects := NewNode
	else
	begin
		LastNode := Objects;
		while LastNode^.Next <> nil do
			LastNode := LastNode^.Next;
		LastNode^.Next := NewNode;
	end;
end;

procedure TWindow.Draw;
var
	X1, X2, Y1, Y2: Integer;
begin
	X1 := Left;
	Y1 := Top;
	X2 := X1 + Width;
	Y2 := Y1 + Height;
	SetFillStyle(SolidFill, Thm.Title);
	Bar(X1 + 2, Y1 + 2, X2 - 2, Y2 - 1);
	SetFillStyle(SolidFill, Thm.Win);
	Bar(X1 + 7, Y1 + 7, X2 - 7, Y2 - 7);
	SetColor(15);
	Line(X1, Y1, X2 - 1, Y1);
	Line(X1, Y1 + 1, X1, Y2 - 1);
	SetColor(0);
	Line(X2, Y1, X2, Y2);
	Line(X1, Y2, X2 - 1, Y2);
	SetColor(Thm.Shadow);
	Line(X2 - 1, Y1 + 1, X2 - 1, Y2 - 1);
	Line(X1 + 1, Y2 - 1, X2 - 2, Y2 - 1);
	SetColor(Thm.Light);
	Line(X1 + 1, Y1 + 1, X2 - 2, Y1 + 1);
	Line(X1 + 1, Y1 + 2, X1 + 1, Y2 - 2);
	SetColor(Thm.Shadow);
	Rectangle(X1 + 5, Y1 + 5, X2 - 5, Y2 - 5);
	SetColor(Thm.Light);
	Rectangle(X1 + 6, Y1 + 6, X2 - 6, Y2 - 6);
end;

destructor TWindow.Done;
var
	NextNode: PObjectNode;
begin
	{Dispose of all objects in the linked list}
	while Objects <> nil do
	begin
		NextNode := Objects^.Next;
		Dispose(Objects);
		Objects := NextNode;
	end;

	{Call ancestor destructor for properties that aren't specific to TWindow}
	inherited Done;
end;

end.