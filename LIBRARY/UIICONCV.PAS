unit UIIconCv;

interface

uses
	CostaLib, UIArea, UIIcon, Graph;

const
	IconSize      = 31;  {Size of icon in pixels (32x32 icon has coords 0..31)}
	PixelSize     =  9;  {Size of one 'pixel' on the canvas in screen pixels}
	OutOfBound    = -1;  {Value indicating out of bounds for X/Y coords}
	MaxColor      = 15;  {Maximum color index for drawing}

type
	TCanvasAction = (ActionMouse, ActionKeyboard);

	TCanvasTool   = (ToolPencil, ToolFloodFill);
	TCanvasDir    = (DirHide, DirStay, DirLeft, DirRight, DirUp, DirDown);

	PIconCanvas   = ^TIconCanvas;
	TIconCanvas   = object(TUIObject)
		public
			constructor  Init(X, Y: Integer; Parent: PContainer);
			destructor   Done; virtual;
			procedure    Draw; virtual;
			procedure    CheckEvent; virtual;

			procedure    NewIcon;
			procedure    LoadIcon(Filename: string);
			procedure    SaveIcon(Filename: string);

			procedure    SetTool(Tool: TCanvasTool);
			function     GetTool: TCanvasTool;

			procedure    SetDrawColor(Color: Byte);
			function     GetDrawColor: Byte;

			function     GetIconFile: string;
			function     IsChanged: Boolean;

			procedure    SetPreviewPos(RelativeX, RelativeY: Integer);
		private
			IndicatorX,
			IndicatorY:  Integer;   {Current position of keyboard indicator}
			IndicatorOn: Boolean;   {Indicator visibility}
			DrawCol:     Byte;      {Current drawing color}
			DrawTool:    TCanvasTool;     {Current drawing tool}
			Changed:     Boolean;   {Whether the icon has unsaved changes}
			IconFile:    string[8]; {Name of the icon file loaded}
			ImgPreview:  PIcon;     {Pointer to the preview icon object}

			{Array holding the icon pixel data}
			IconData:    array[0..IconSize, 0..IconSize] of Byte;

			procedure    DoCanvasAction(Action: TCanvasAction);
			procedure    DrawPixel(X, Y, Col: Integer);
			procedure    FloodFill(X, Y, FillColor: Integer);
			procedure    GetCursorPos(var X, Y: Integer);
			procedure    MoveIndicator(Direction: TCanvasDir);
	end;

implementation

constructor TIconCanvas.Init(X, Y: Integer; Parent: PContainer);
const
	DefaultW = 290;
	DefaultH = 290;
begin
	Inherited Init;
	SetParent(Parent);
	Left := X;
	Top := Y;
	Width := DefaultW;
	Height := DefaultH;
	SetBgColor(White);
	FillChar(IconData, SizeOf(IconData), White);

	New(ImgPreview, Init(X + DefaultW + 12, Y, '', Parent)); {Set preview icon position to right of canvas}
	ImgPreview^.SetBgColor(White);

	IndicatorX := 16;
	IndicatorY := 16;
	DrawCol    := Black;
	DrawTool   := ToolPencil;
	Changed    := false;
	IconFile   := '';
end;

destructor TIconCanvas.Done;
begin
	if Assigned(ImgPreview) then
		Dispose(ImgPreview, Done);

	Inherited Done;
end;

procedure TIconCanvas.Draw;
var
	X1, Y1, X2, Y2, I: Integer;
	BGColor: Byte;
begin
	if SHidden in State then
		exit;

	{Get absolute position and size of the object}
	Self.GetAbsPos(X1, Y1);
	X2 := X1 + Width;
	Y2 := Y1 + Height;

	BgColor := GetBgColor;

	DrawUIPrimitive(UIBorderDown, X1, Y1, X2, Y2, BgColor, False);

	{The canvas is divided into pixels by horizontal and vertical lines in a grid. These lines
 	 are dotted in alternate colors to make them visible on any background.}
	SetWriteMode(CopyPut);
	for I := 0 to IconSize do
	begin
		{Gray background part}
		SetLineStyle(SolidLn, 0, NormWidth);
		SetColor(DarkGray);
		Line(X1 + 2, Y1 + 1 + (I * PixelSize), X2 - 2, Y1 + 1 + (I * PixelSize)); {Horizontal}
		Line(X1 + 1 + (I * PixelSize), Y1 + 2, X1 + 1 + (I * PixelSize), Y2 - 2); {Vertical}

		{Black dotted foreground part}
		SetLineStyle(UserBitLn, $AAAA, NormWidth);
		SetColor(Black);
		Line(X1 + 2, Y1 + 1 + (I * PixelSize), X2 - 2, Y1 + 1 + (I * PixelSize)); {Horizontal}
		Line(X1 + 1 + (I * PixelSize), Y1 + 2, X1 + 1 + (I * PixelSize), Y2 - 2); {Vertical}
	end;
	SetLineStyle(SolidLn, 0, NormWidth);

	ImgPreview^.Draw;

	{If theres data in the icon, redraw it on the canvas and preview area}
	If Changed or (Length(IconFile) > 0) then
	begin
		for X1 := 0 to IconSize do
		begin
			for Y1 := 0 to IconSize do
			begin
				DrawPixel(X1, Y1, IconData[X1, Y1]);
			end;
		end;
	end;

	{If keyboard indicater on, draw it as well}
	if IndicatorOn then
		MoveIndicator(DirStay);

	{Clearing of dirty flag etc. handled by parent}
	Inherited Draw;
end;

procedure TIconCanvas.CheckEvent;
begin
	{Don't process events if disabled or hidden}
	if not (SEnabled in State) or (SHidden in State) then
		exit;

	{Check for mouse click in canvas area}
	if Self.IsMouseOver and (Mouse.Clicked = MbLeft) then
	begin
		DoCanvasAction(ActionMouse);
		Self.Click;
	end;

	{Check for hotkey presses for keyboard drawing}
	if (HotkeyInput = KeyEnter) or (HotkeyInput = KeySpace) then
	begin
		HotkeyInput := '';
		DoCanvasAction(ActionKeyboard);
		Self.Click;
	end;

	if HotkeyInput = KeyUp then
		MoveIndicator(DirUp)
	else if HotkeyInput = KeyDown then
		MoveIndicator(DirDown)
	else if HotkeyInput = KeyLeft then
		MoveIndicator(DirLeft)
	else if HotkeyInput = KeyRight then
		MoveIndicator(DirRight)
	else
		exit;

	{If we're still here, a cursor key was pressed and HotkeyInput needs to be cleared
	 to avoid repeated movement}
	HotkeyInput := '';
end;

procedure TIconCanvas.NewIcon;
begin
	{Fill icon data with the default color (white) and reset variables}
	FillChar(IconData, SizeOf(IconData), White);
	IconFile := '';
	Changed := false;

	{Redraw the canvas}
	Include(State, SDirty);
end;

procedure TIconCanvas.LoadIcon(Filename: string);
var
	PreviewX, PreviewY, X, Y, PixelCol: Integer;
begin
	{Clear IconData with invalid values - this makes sure color 0 will also be drawn,
	 since DrawPixel checks if the color is different before drawing}
	FillChar(IconData, SizeOf(IconData), 255);
	ImgPreview^.SetIcon(Filename);

	Mouse.Hide;
	ImgPreview^.Draw;
	ImgPreview^.GetAbsPos(PreviewX, PreviewY);
	{Get color of each pixel from the preview icon and draw it on the canvas}
	for X := 0 to IconSize do
	begin
		for Y := 0 to IconSize do
		begin
			PixelCol := GetPixel(PreviewX + X, PreviewY + Y);
			DrawPixel(X, Y, PixelCol);
		end;
	end;
	Mouse.Show;

	{If keyboard indicator was visible before load, redraw it}
	if IndicatorOn then
		MoveIndicator(DirStay);

	{Update icon file name and mark it as not changed}
	IconFile := Filename;
	Changed := false;
end;

procedure TIconCanvas.SaveIcon(Filename: string);
var
	F: file;
	Size: Word;
	p: Pointer;
	X1, Y1, X2, Y2: Integer;
begin
	{Allocate memory and get the icon data}
	ImgPreview^.GetAbsPos(X1, Y1);
	X2 := X1 + IconSize;
	Y2 := Y1 + IconSize;
	Size := ImageSize(X1, Y1, X2, Y2);
	GetMem(p, Size);
	Mouse.Hide;
	GetImage(X1, Y1, X2, Y2, p^);
	Mouse.Show;

	{Open the file and output the data}
	Assign(F, Filename);
	{$I-}
	Rewrite(F, 1);
	{$I+}
	if IOResult <> 0 then
	begin
		FreeMem(p, Size);
		p := nil;
		exit;
	end;
	{Output the icon data, p^, to the file}
	BlockWrite(F, p^, Size);
	Close(F);
	FreeMem(p, Size);
	p := nil;

	{If save was successful, update the icon file name and mark it as not changed}
	IconFile := Filename;
	Changed := false;
end;

procedure TIconCanvas.SetTool(Tool: TCanvasTool);
begin
	DrawTool := Tool;
end;

function TIconCanvas.GetTool: TCanvasTool;
begin
	GetTool := DrawTool;
end;

procedure TIconCanvas.SetDrawColor(Color: Byte);
begin
	{Prevent color outside range by wrapping around, allowing color cycling by
	 incrementing/decrementing beyond limits}
	if Color < 0 then
		DrawCol := MaxColor
	else if Color > MaxColor then
		DrawCol := 0
	else
		DrawCol := Color;
end;

function TIconCanvas.GetDrawColor: Byte;
begin
	GetDrawColor := DrawCol;
end;

function TIconCanvas.GetIconFile: string;
begin
	GetIconFile := IconFile;
end;

function TIconCanvas.IsChanged: Boolean;
begin
	IsChanged := Changed;
end;

{Positions the preview icon at the specified coordinates relative to the canvas -
 the reason for it being relative is that it is not a child of the object of which
 the canvas object might be, and so an absolute postion on screen is required}
procedure TIconCanvas.SetPreviewPos(RelativeX, RelativeY: Integer);
var
	X, Y: Integer;
begin
	Self.GetAbsPos(X, Y);
	Inc(X, RelativeX);
	Inc(Y, RelativeY);
	ImgPreview^.Move(X, Y);
end;

{Procedures below are private methods for internal use only}


{DoCanvasAction is called when the mouse is clicked in the canvas area, or when
 the user presses Enter/Space to draw the currently selected pixel}
procedure TIconCanvas.DoCanvasAction(Action: TCanvasAction);
var
	CanvasX, CanvasY: Integer;
begin
	{If keyboard action was taken but indicator is hidden, just show it without
	 drawing}
	if (Action = ActionKeyboard) and (not IndicatorOn) then
	begin
		IndicatorOn := true;
		MoveIndicator(DirStay);
		exit;
	end;

	{Set CanvasX/Y to mouse position, or to indicator position if
	 keyboard action was taken}
	if Action = ActionMouse then
	begin
		if IndicatorOn then
			MoveIndicator(DirHide);
		GetCursorPos(CanvasX, CanvasY);
	end
	else
	begin
		CanvasX := IndicatorX;
		CanvasY := IndicatorY;
	end;

	{If outside bounds, do nothing}
	if (CanvasX < 0) or (CanvasY < 0) or (CanvasX > IconSize) or (CanvasY > IconSize) then
		exit;

	case DrawTool of
		ToolPencil:
			begin
				{Keep drawing until mouse is released - if keyboard action, loop will
				 exit after drawing one pixel}
				repeat
					if CanvasX <> OutOfBound then
					begin
						{Plot the current pixel if color is different}
						if IconData[CanvasX, CanvasY] <> DrawCol then
						begin
							Mouse.Hide;
							DrawPixel(CanvasX, CanvasY, DrawCol);
							Mouse.Show;
						end;
					end;

					if Action = ActionKeyboard then
						break;

					GetCursorPos(CanvasX, CanvasY);

				until Mouse.Clicked = MbNone;
			end;

		ToolFloodFill:
			begin
				Mouse.Hide;
				FloodFill(CanvasX, CanvasY, DrawCol);
				Mouse.Show;
				{After flood fill, switch back to the pencil tool}
				SetTool(ToolPencil);
			end;
	end;

	{Make sure indicator will appear where mouse was lifted}
	if Action = ActionMouse then
	begin
		if CanvasX <> OutOfBound then
		begin
			IndicatorX := CanvasX;
			IndicatorY := CanvasY;
		end;
	end;

	{Redraw keyboard indicator if it was visible}
	if Action = ActionKeyboard then
		MoveIndicator(DirStay);
end;



{DrawPixel draws a pixel at the specified coordinates on the canvas and updates the
 IconData array. It also updates the ImgPreview icon}
procedure TIconCanvas.DrawPixel(X, Y, Col: Integer);
var
	CanvasX, CanvasY, OffsetX, OffsetY: Integer;
	PreviewX, PreviewY: Integer;
begin
	{Offset variables are the coords for the top-left corner of
	 the drawing area, and each 'pixel' in it is PixelSize times
	 PixelSize pixels in size}
	Self.GetAbsPos(OffsetX, OffsetY);
	Inc(OffsetX, 2);
	Inc(OffsetY, 2);

	CanvasX := OffsetX + (X * PixelSize);
	CanvasY := OffsetY + (Y * PixelSize);

	Changed := true;
	IconData[X, Y] := Col;

	SetFillStyle(SolidFill, Col);
	{Draw on canvas}
	Bar(CanvasX, CanvasY, CanvasX + PixelSize - 2, CanvasY + PixelSize - 2);

	{Update preview}
	ImgPreview^.GetAbsPos(PreviewX, PreviewY);
	PutPixel(PreviewX + X, PreviewY + Y, Col);
end;



{Floodfill fils an area of the canvas with the specified color. When a pixel is filled
 its neighbors are pushed to the stack. The neighbors are then checked by popping them
 from the stack and filling them if they match the original color. This continues until
 no more pixels are left in the stack. A stack is used to avoid recursion, as that
 would quickly lead to a stack overflow for large areas.}
procedure TIconCanvas.FloodFill(X, Y, FillColor: Integer);
type
	{Pointer and record type for a node in the stack}
	PNode = ^TNode;
	TNode = record
		X, Y: Integer;
		Next: PNode;
	end;
var
	Stack: PNode; {Pointer to the first item in the stack}
	ReplaceColor: Integer; {The color to replace, which is the color of the pixel clicked on}

	{Pushes a pixel onto the stack for checking later}
	procedure Push(X, Y: Integer);
	var
		NewNode: PNode;
	begin
		{Allocate a new node and set its values}
		New(NewNode);
		NewNode^.X := X;
		NewNode^.Y := Y;
		{Point new nodes Next to the current stack, and set it as
		 the new stack head}
		NewNode^.Next := Stack;
		Stack := NewNode;
	end;

	{Retrieves a pixel from the stack for processing}
	function Pop(var X, Y: Integer): Boolean;
	var
		TempNode: PNode;
	begin
		if Assigned(Stack) then
		begin
			X := Stack^.X;
			Y := Stack^.Y;
			{Retrieve the top item from the stack and set its Next as the new head}
			TempNode := Stack;
			Stack := Stack^.Next;
			Dispose(TempNode); {Dispose the TNode element that was popped}
			Pop := true;
		end
		else
			Pop := false;
	end;

begin
	{Only adjacent pixels of this color will be filled}
	ReplaceColor := IconData[X, Y];

	{No point in filling area with the color it already has}
	if ReplaceColor = FillColor then
		exit;

	{Initialize stack and push clicked pixel to it}
	Stack := nil;
	Push(X, Y);

	{As long as there are pixels in the stack, retrieve and check them}
	while Pop(X, Y) do
	begin
		{Check bounds}
		if (X < 0) or (Y < 0) or (X > IconSize) or (Y > IconSize) then
			continue;

		{If pixel has the right color, fill it and mark its neighbours for checking by
		 pushing them onto the stack}
		if IconData[X, Y] = ReplaceColor then
		begin
			DrawPixel(X, Y, FillColor);
			Push(X - 1, Y);
			Push(X + 1, Y);
			Push(X, Y - 1);
			Push(X, Y + 1);
		end;
	end;

	{Wait for mouse release to avoid unintended drawing}
	repeat until Mouse.Clicked = MbNone;
end;


{GetCursorPos retrieves the pixel in the canvas which the mouse is currently over.
 Values are returned in X and Y. If the mouse is not over the canvas, OutOfBound is
 returned for both X and Y.}
procedure TIconCanvas.GetCursorPos(var X, Y: Integer);
var
	OffsetX, OffsetY: Integer;
begin
	{Get absolute position of the canvas area}
	Self.GetAbsPos(OffsetX, OffsetY);
	Inc(OffsetX, 2);
	Inc(OffsetY, 2);

	if Self.IsMouseOver then
	begin
		X := (Mouse.X - OffsetX) div PixelSize;
		Y := (Mouse.Y - OffsetY) div PixelSize;

		{Ensure X and Y are within bounds}
		if X < 0 then X := 0;
		if Y < 0 then Y := 0;
		if X > IconSize then X := IconSize;
		if Y > IconSize then Y := IconSize;
	end
	else
	begin
		{Out of bounds}
		X := OutOfBound;
		Y := OutOfBound;
	end;
end;


{MoveIndicator moves the keyboard indicator in the specified direction,
 or hides/shows it.}
procedure TIconCanvas.MoveIndicator(Direction: TCanvasDir);
var
	OffsetX, OffsetY: Integer;
	CanvasX, CanvasY: Integer;
begin
	{Get absolute position of the canvas area}
	Self.GetAbsPos(OffsetX, OffsetY);
	Inc(OffsetX, 2);
	Inc(OffsetY, 2);

	if (IndicatorOn) or (Direction = DirHide) then
	begin
		{Remove indicator from previous pixel}
		if (IndicatorX > OutOfBound) and (IndicatorY > OutOfBound) then
		begin
			CanvasX := OffsetX + (IndicatorX * PixelSize);
			CanvasY := OffsetY + (IndicatorY * PixelSize);
			Mouse.Hide;
			SetFillStyle(SolidFill, IconData[IndicatorX, IndicatorY]);
			Bar(CanvasX, CanvasY, CanvasX + PixelSize - 2, CanvasY + PixelSize - 2);
			Mouse.Show;
		end;
	end;

	if Direction = DirHide then
	begin
		IndicatorOn := false;
		exit;
	end
	else
		IndicatorOn := true;

	{No need to handle DirStay, all it does is ensure the indicator is visible}
	case Direction of
		DirUp:    Dec(IndicatorY);
		DirDown:  Inc(IndicatorY);
		DirLeft:  Dec(IndicatorX);
		DirRight: Inc(IndicatorX);
	end;

	{Prevent out of bounds}
	if IndicatorY < 0 then IndicatorY := 0;
	if IndicatorY > IconSize then IndicatorY := IconSize;
	if IndicatorX < 0 then IndicatorX := 0;
	if IndicatorX > IconSize then IndicatorX := IconSize;

	{Draw indicator}
	CanvasX := OffsetX + (IndicatorX * PixelSize);
	CanvasY := OffsetY + (IndicatorY * PixelSize);
	Mouse.Hide;
	SetColor(DarkGray);
	Rectangle(CanvasX + 1, CanvasY + 1, CanvasX + 6, CanvasY + 6);
	SetColor(White);
	Rectangle(CanvasX + 2, CanvasY + 2, CanvasX + 5, CanvasY + 5);
	Mouse.Show;
end;

end.