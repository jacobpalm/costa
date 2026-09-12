program Textview;

uses
	Costalib, UIButton, UITxtbox, MsgDlg, AboutDlg, FileDlg, Graph;

const
	AppName              = 'Text Viewer';
	AppVersion           = '2.0';
	AppAuthor            = 'Jacob Palm';
	AppIcon              = 'DOCUMENT';

	InitialCap           = 100; {Initial capacity for the line array}
	MaxLinesShown        = 27;
	MaxLineLength        = 78;

	CAP_OPEN             = #127 + 'Open...';
	CAP_PAGE_UP          = 'Page ' + #127 + 'up';
	CAP_PAGE_DOWN        = 'Page ' + #127 + 'down';
	CAP_ABOUT            = #127 + 'About...';
	CAP_EXIT             = 'E' + #127 + 'xit';
	CAP_LOADING          = 'Loading...';

	MSG_OPEN_ERROR_TITLE = 'Error opening file';
	MSG_FILE_NOT_FOUND   = 'File not found: ' + #13;
	MSG_READ_ERROR       = '%s. Cannot open ' + #13;
	MSG_MEMORY_TEXT      = 'Not enough memory to open this file.';
	MSG_END_OF_FILE      = '* end of file *';

type
	{String type for storing lines of text}
	PLine      = ^LineStr;
	LineStr    = String[MaxLineLength];

	{Flexible array to simulate dynamic sizing}
	PLineArray = ^LineArray;
	LineArray  = Array[1..1] of PLine;

	{Scrolling directions}
	TDirection = (LineUp, LineDown, PageUp, PageDown, Top, Bottom);

var
	Lines:      PLineArray;    {Array of pointers to lines of text}

	StartLine,                 {Index of first line currently shown on screen}
	Capacity,                  {Current capacity of the Lines array}
	LineCount:  Integer;       {Number of lines currently stored in Lines array}
	FileOpened: Boolean;

	StdHeapErr: Pointer;       {We'll be taking care of heap errors ourselves}

	App:        PApplication;
	WinMain:    PWindow;

	BtnOpen, BtnPageUp, BtnPageDown, BtnAbout, BtnExit: PButton;
	HkUp, HkDown, HkHome, HkEnd: PHotkey;

procedure DrawText; forward;
procedure FreeLines; forward;

function CustomHeapError(Size: Word): Integer; far;
begin
	{Custom heap error handler to deal with out of memory situations without
	 crashing the program. If GetMem fails, free any previously allocated
	 lines and show an error message.}
	if Size = 0 then
	begin
		CustomHeapError := 0;
		Exit;
	end;

	FreeLines; {Free any previously allocated lines}
	FileOpened := False;
	WinMain^.AddState(SDirty);
	MsgBox(MSG_OPEN_ERROR_TITLE, MSG_MEMORY_TEXT, MsgError);
	CustomHeapError := 1; {Make GetMem return a nil pointer}
end;

procedure ShowLoading;
var
	BtnLoading: PButton;
begin
	{Show a loading indicator centered on the screen while loading a file}
	Mouse.Hide;
	New(BtnLoading, Init(110, 34, CAP_LOADING, nil));
	BtnLoading^.Center(OrBoth);
	BtnLoading^.Draw;
	Mouse.Show;
	Dispose(BtnLoading, Done);
end;

function InitLines(InitialSize: Integer): Boolean;
begin
	{Initialize the lines array with a given initial capacity}
	Capacity := InitialSize;
	LineCount := 0;
	HeapError := @CustomHeapError;
	GetMem(Lines, Capacity * SizeOf(PLine));
	HeapError := StdHeapErr;
	if not Assigned(Lines) then
		InitLines := false
	else
		InitLines := true;
end;

function ResizeLines(var Lines: PLineArray; OldCap, NewCap: Integer): Boolean;
var
	NewLines: PLineArray;
	i: Integer;
begin
	{Resize the lines array to a new capacity, by creating a new array,
	 copying existing lines to it, and freeing the old array.}

	{Only resize if the lines array has been initialized}
	if not Assigned(Lines) then
	begin
		ResizeLines := False;
		Exit;
	end;

	{Allocate new memory for the resized array}
	HeapError := @CustomHeapError;
	GetMem(NewLines, NewCap * SizeOf(PLine));
	HeapError := StdHeapErr;

	if not Assigned(NewLines) then
	begin
		ResizeLines := False;
		Exit;
	end;

	{Copy existing lines to the new array}
	Move(Lines^[1], NewLines^[1], OldCap * SizeOf(PLine));

	{Free memory of the old array}
	FreeMem(Lines, OldCap * SizeOf(PLine));

	{Update the pointer to the new array}
	Lines := NewLines;
end;

procedure FreeLines;
var
	i: Integer;
begin
	{Free all allocated lines and the lines array itself}

	{Dispose all lines in the array}
	for i := 1 to LineCount do
		Dispose(Lines^[i]);

	{Free the memory allocated for the array itself}
	FreeMem(Lines, Capacity * SizeOf(PLine));
	Lines := nil;

	Capacity := 0;
	LineCount := 0;
	StartLine := 1;
end;

procedure AddLine(S: String);
var
	NewLine: PLine;
begin
	{Add a new line to the lines array, resizing it if necessary}

	if LineCount >= Capacity then
	begin
		{Reallocate space for more lines, exit if it fails}
		if not ResizeLines(Lines, Capacity, Capacity + 10) then
			Exit;
		Capacity := Capacity + 10;
	end;

	New(NewLine);
	NewLine^ := S;
	Inc(LineCount);
	Lines^[LineCount] := NewLine;
end;

procedure LoadFile(FileName: String);
var
	F: Text;
	ReadData, Truncated: String;
	ErrorCode: Integer;
begin
	{Load a text file into the lines array, splitting long lines as necessary}

	if FileName = '' then
		Exit;

	{Check if file exists}
	if not FileExists(FileName) then
	begin
		MsgBox(MSG_OPEN_ERROR_TITLE, MSG_FILE_NOT_FOUND + FileName, MsgError);
		Exit;
	end;

	{Open the file for reading}
	Assign(F, FileName);
	FileMode := FileRead;
	{$I-}
	Reset(F);
	{$I+}
	ErrorCode := IOResult;
	if ErrorCode <> 0 then
	begin
		MsgBox(MSG_OPEN_ERROR_TITLE, Replace(MSG_READ_ERROR, Placeholder, GetDosErrorMsg(ErrorCode)) + FileName, MsgError);
		Exit;
	end;

	ShowLoading;

	if FileOpened then
		FreeLines; {Free previously loaded lines}

	{Initialize Lines array with default capacity, exit if failed}
	if not InitLines(InitialCap) then
	begin
		FileOpened := False;
		DrawText;
		Exit;
	end;

	{Read lines from the file}
	while not Eof(F) do
	begin
		ReadLn(F, ReadData);

		{Blank lines won't work for loop below, so add it and skip the loop}
		if Length(ReadData) = 0 then
		begin
			AddLine('');
			Continue;
		end;

		{Replace TAB with two spaces}
		ReadData := Replace(ReadData, #9, '  ');

		{Add each line to the array, truncate at MaxLineLength if necessary by
		 splitting into multiple lines}
		while Length(ReadData) > 0 do
		begin
			if Length(ReadData) > MaxLineLength then
			begin
				Truncated := Copy(ReadData, 1, MaxLineLength);
				Delete(ReadData, 1, MaxLineLength);
			end
			else
			begin
				Truncated := ReadData;
				ReadData := '';
			end;

			AddLine(Truncated);
		end;

		{Exit if lines array has been freed due to memory error}
		if LineCount = 0 then
		begin
			FileOpened := False;
			DrawText;
			Exit;
		end;
	end;
	Close(F);

	{Add end of file indicator, since the textbox doesn't have scrollbars to indicate
	 position}
	AddLine('');
	AddLine(MSG_END_OF_FILE);

	StartLine := 1;
	if not FileOpened then
	begin
		{If a file wasn't previously opened, scroll buttons won't be visible}
		FileOpened := True;
		BtnPageUp^.RemoveState(SHidden);
		BtnPageDown^.RemoveState(SHidden);
	end;
	DrawText;
end;

procedure DrawText;
var
	i, DrawnLines: Integer;
begin
	Mouse.Hide;
	SetFillStyle(SolidFill, Thm.Txt);

	{If no file is opened, clear the entire text area}
	if not FileOpened then
	begin
		Bar(0, 29, 639, 349);
		Mouse.Show;
		Exit;
	end;

	{Draw MaxLinesShown lines, starting from StartLine}
	DrawnLines := 0;
	for i := StartLine to StartLine + MaxLinesShown do
	begin
		Inc(DrawnLines);

		{Clear line}
		Bar(7, (PrintLineH * (i - StartLine + 1)) + 22, 633, PrintLineH * (i - StartLine + 1) + 36);

		{Draw line unless we've drawn the maximum number of lines or reached the end of the file}
		if (DrawnLines < MaxLinesShown) and (i <= LineCount) then
			{Dereference the line pointer and print the text}
			Print(Lines^[i]^, 9, (PrintLineH * (i - StartLine + 1)) + 24, Thm.TxtText);
	end;
	Mouse.Show;
end;

procedure ScrollText(Direction: TDirection);
var
	PrevStartLine: Integer;
begin
	{Scroll the text in the given direction - doesn't draw the text, only updates StartLine}

	if not FileOpened then
		Exit;

	PrevStartLine := StartLine;
	case Direction of
		LineUp: Dec(StartLine);
		LineDown: Inc(StartLine);
		PageUp: Dec(StartLine, MaxLinesShown);
		PageDown: Inc(StartLine, MaxLinesShown);
		Top: StartLine := 1;
		Bottom: StartLine := LineCount - MaxLinesShown + 2;
	end;

	if StartLine > LineCount - MaxLinesShown + 2 then
		StartLine := LineCount - MaxLinesShown + 2;

	if StartLine < 1 then
		StartLine := 1;

	{Redraw text only if the start line has changed}
	if StartLine <> PrevStartLine then
		DrawText;
end;

procedure BtnAboutClick(Sender: PUIObject); far;
begin
	AboutBox(App);
end;

procedure BtnOpenClick(Sender: PUIObject); far;
var
	FileName: String;
begin
	FileName := FileSelect('*.TXT', '');
	if FileName <> '' then
		LoadFile(FileName);
end;

procedure PageScrollEvent(Sender: PUIObject); far;
begin
	if not FileOpened then
		Exit;

	if PButton(Sender) = BtnPageUp then
		ScrollText(PageUp)
	else if PButton(Sender) = BtnPageDown then
		ScrollText(PageDown)
	else if PHotkey(Sender) = HkUp then
		ScrollText(LineUp)
	else if PHotkey(Sender) = HkDown then
		ScrollText(LineDown)
	else if PHotkey(Sender) = HkHome then
		ScrollText(Top)
	else if PHotkey(Sender) = HkEnd then
		ScrollText(Bottom);
end;

procedure BtnExitClick(Sender: PUIObject); far;
begin
	App^.Terminate;
end;

procedure WinMainDraw(Sender: PUIObject); far;
begin
	{Draw empty text area when main window is first drawn}
	SetFillStyle(SolidFill, Thm.Txt);
	Bar(0, 29, ScreenWidth, ScreenHeight);

	if not FileOpened then
		{Pass first command line argument as file name, LoadFile will ignore it if empty}
		LoadFile(ParamStr(1));
end;

procedure InitUI;
begin
	{Main window}
	New(WinMain, Init(0, 0, nil));
	with WinMain^ do
	begin
		Width := ScreenWidth;
		Height := ScreenHeight;
		OnDraw := WinMainDraw;
		BorderStyle := BorNone;
	end;

	New(BtnOpen, Init(3, 2, CAP_OPEN, WinMain));
	with BtnOpen^ do
	begin
		OnClick := BtnOpenClick;
		AddHotkey(KeyAltO);
	end;

	New(BtnPageUp, Init(102, 2, CAP_PAGE_UP, WinMain));
	with BtnPageUp^ do
	begin
		OnClick := PageScrollEvent;
		Include(State, SHidden); {Hidden until a file is opened}
		AddHotkey(KeyAltU);
		AddHotkey(KeyPageUp);
	end;

	New(BtnPageDown, Init(201, 2, CAP_PAGE_DOWN, WinMain));
	with BtnPageDown^ do
	begin
		OnClick := PageScrollEvent;
		Include(State, SHidden);
		AddHotkey(KeyAltD);
		AddHotkey(KeyPageDown);
	end;

	New(BtnAbout, Init(446, 2, CAP_ABOUT, WinMain));
	with BtnAbout^ do
	begin
		OnClick := BtnAboutClick;
		AddHotkey(KeyAltA);
	end;

	New(BtnExit, Init(545, 2, CAP_EXIT, WinMain));
	with BtnExit^ do
	begin
		OnClick := BtnExitClick;
		AddHotkey(KeyAltX);
		AddHotkey(KeyAltF4);
	end;

	{Hotkeys for scrolling}
	New(HkUp, Init(KeyUp, WinMain));
	HkUp^.OnClick := PageScrollEvent;
	New(HkDown, Init(KeyDown, WinMain));
	HkDown^.OnClick := PageScrollEvent;
	New(HkHome, Init(KeyHome, WinMain));
	HkHome^.OnClick := PageScrollEvent;
	New(HkEnd, Init(KeyEnd, WinMain));
	HkEnd^.OnClick := PageScrollEvent;
end;

begin
	{Store default heap error handler for later restoration}
	StdHeapErr := HeapError;

	New(App, Init);
	With App^ do
	begin
		Name := AppName;
		Version := AppVersion;
		Author := AppAuthor;
		Icon := AppIcon;
	end;

	InitUI;

	App^.OpenWindow(WinMain);
	App^.Run;
end.