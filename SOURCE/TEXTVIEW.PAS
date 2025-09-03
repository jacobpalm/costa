program Textview;

uses
	Costalib, UIButton, UITxtbox, MsgDlg, AboutDlg, FileDlg, Strings, Graph, Crt;

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
	MSG_READ_ERROR       = 'Error reading file, make sure it is accessible: ' + #13;
	MSG_MEMORY_TEXT      = 'Not enough memory to open this file.';
	MSG_END_OF_FILE      = '* end of file *';

type
	PLine = ^LineStr;
	LineStr = String[MaxLineLength];

	PLineArray = ^LineArray;
	LineArray = Array[1..1] of PLine; {Flexible array to simulate dynamic sizing}

	TDirection = (LineUp, LineDown, PageUp, PageDown, Top, Bottom);

var
	Lines: PLineArray;
	StartLine,
	Capacity,
	LineCount: Integer;
	FileOpened: Boolean;

	DefaultHeapError: Pointer; {We'll be taking care of heap errors ourselves}

	BtnOpen, BtnPageUp, BtnPageDown, BtnAbout, BtnExit: TButton;
	HkUp, HkDown, HkHome, HkEnd: THotkey;

procedure DrawText; forward;
procedure FreeLines; forward;

function CustomHeapError(Size: Word): Integer; far;
begin
	if Size = 0 then
	begin
		CustomHeapError := 0;
		Exit;
	end;

	FreeLines; {Free any previously allocated lines}
	FileOpened := False;
	MouseHide;
	SetFillStyle(SolidFill, Thm.Txt);
	Bar(0, 29, 639, 349);
	MouseShow;
	MsgBox(MSG_OPEN_ERROR_TITLE, MSG_MEMORY_TEXT, MsgError);
	CustomHeapError := 1; {Make GetMem return a nil pointer}
end;

procedure ShowLoading;
var
	BtnLoading: TButton;
begin
	MouseHide;
	BtnLoading.Init(sizeCenter, sizeCenter, 110, 34, CAP_LOADING);
	BtnLoading.Draw;
	MouseShow;
end;

function InitLines(InitialSize: Integer): Boolean;
begin
	Capacity := InitialSize;
	LineCount := 0;
	HeapError := @CustomHeapError;
	GetMem(Lines, Capacity * SizeOf(PLine));
	HeapError := DefaultHeapError;
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
	{Only resize if the lines array has been initialized}
	if not Assigned(Lines) then
	begin
		ResizeLines := False;
		Exit;
	end;

	{Allocate new memory for the resized array}
	HeapError := @CustomHeapError;
	GetMem(NewLines, NewCap * SizeOf(PLine));
	HeapError := DefaultHeapError;

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
	{Dispose all lines in the array}
	for i := 1 to LineCount do
		Dispose(Lines^[i]);

	{Free the memory allocated for the array itself}
	FreeMem(Lines, Capacity * SizeOf(PLine));

	Capacity := 0;
	LineCount := 0;
	StartLine := 1;
end;

procedure AddLine(S: String);
var
	NewLine: PLine;
begin
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
begin
	if FileName = '' then
		Exit;
	
	if not FileExists(FileName) then
	begin
		MsgBox(MSG_OPEN_ERROR_TITLE, MSG_FILE_NOT_FOUND + FileName, MsgError);
		Exit;
	end;

	Assign(F, FileName);
	{$I-}
	Reset(F);
	{$I+}
	if IOResult <> 0 then
	begin
		MsgBox(MSG_OPEN_ERROR_TITLE, MSG_READ_ERROR + FileName, MsgError);
		Exit;
	end;

	ShowLoading;
	
	if FileOpened then
		FreeLines; {Free previously loaded lines}
	 
	{Initialize with default capacity, exit if failed} 
	if not InitLines(InitialCap) then
	begin
		FileOpened := False;
		DrawText;
		Exit;
	end;

	while not Eof(F) do
	begin
		ReadLn(F, ReadData);

		{Blank lines won't work for loop below, so add and continue}
		if Length(ReadData) = 0 then
		begin
			AddLine('');
			Continue;
		end;

		{Replace TAB with two spaces}
		ReadData := Replace(ReadData, #9, '  '); 

		{Add each line to the array, truncate at MaxLineLength if necessary}
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
		MouseHide;
		BtnPageUp.Draw;
		BtnPageDown.Draw;
		MouseShow;
	end;
	DrawText;
end;

procedure DrawText;
var
	i, DrawnLines: Integer;
begin
	MouseHide;
	SetFillStyle(SolidFill, Thm.Txt);

	{If no file is opened, clear the entire text area}
	if not FileOpened then
	begin
		Bar(0, 29, 639, 349);
		MouseShow;
		Exit;
	end;

	DrawnLines := 0;
	for i := StartLine to StartLine + MaxLinesShown do
	begin
		Inc(DrawnLines);
		
		{Clear line}
		Bar(7, (PrintLineH * (i - StartLine + 1)) + 22, 633, PrintLineH * (i - StartLine + 1) + 36);

		if (DrawnLines < MaxLinesShown) and (i <= LineCount) then
			{Dereference the line pointer and print the text}
			Print(Lines^[i]^, 9, (PrintLineH * (i - StartLine + 1)) + 24, Thm.TxtText);

	end;
	MouseShow;
end;

procedure ScrollText(Direction: TDirection);
var
	PrevStartLine: Integer;
begin
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
	AboutBox(AppName, AppVersion, AppAuthor, AppIcon);
end;

procedure BtnOpenClick(Sender: PUIObject); far;
var
	FileName: String;
begin
	FileName := FileSelect('*.TXT', '', False);
	if FileName <> '' then
		LoadFile(FileName);
end;

procedure PageScrollEvent(Sender: PUIObject); far;
begin
	if not FileOpened then
		Exit;

	if Sender = @BtnPageUp then
		ScrollText(PageUp)
	else if Sender = @BtnPageDown then
		ScrollText(PageDown)
	else if Sender = @HkUp then
		ScrollText(LineUp)
	else if Sender = @HkDown then
		ScrollText(LineDown)
	else if Sender = @HkHome then
		ScrollText(Top)
	else if Sender = @HkEnd then
		ScrollText(Bottom);
end;

procedure BtnExitClick(Sender: PUIObject); far;
begin
	CloseGraph;
	Halt(0);
end;

procedure UIInit;
begin
	BtnOpen.Init(3, 2, SizeDefault, SizeDefault, CAP_OPEN);
	BtnOpen.OnClick := BtnOpenClick;
	BtnOpen.AddHotkey(KeyAltO);
	BtnPageUp.Init(102, 2, SizeDefault, SizeDefault, CAP_PAGE_UP);
	BtnPageUp.OnClick := PageScrollEvent;
	BtnPageUp.AddHotkey(KeyAltU);
	BtnPageUp.AddHotkey(KeyPageUp);
	BtnPageDown.Init(201, 2, SizeDefault, SizeDefault, CAP_PAGE_DOWN);
	BtnPageDown.OnClick := PageScrollEvent;
	BtnPageDown.AddHotkey(KeyAltD);
	BtnPageDown.AddHotkey(KeyPageDown);
	BtnAbout.Init(446, 2, SizeDefault, SizeDefault, CAP_ABOUT);
	BtnAbout.OnClick := BtnAboutClick;
	BtnAbout.AddHotkey(KeyAltA);
	BtnExit.Init(545, 2, SizeDefault, SizeDefault, CAP_EXIT);
	BtnExit.OnClick := BtnExitClick;
	BtnExit.AddHotkey(KeyAltX);
	BtnExit.AddHotkey(KeyAltF4);
	HkUp.Init(KeyUp);
	HkUp.OnClick := PageScrollEvent;
	HkDown.Init(KeyDown);
	HkDown.OnClick := PageScrollEvent;
	HkHome.Init(KeyHome);
	HkHome.OnClick := PageScrollEvent;
	HkEnd.Init(KeyEnd);
	HkEnd.OnClick := PageScrollEvent;
end;

var
	FileName: String;
	Key: String;
begin
	{Store default heap error handler for later restoration}
	DefaultHeapError := HeapError;

	UIInit;

	{DEBUG - disable page nav buttons until a file is opened}

	MouseHide;
	MenuBar.Draw;
	SetFillStyle(SolidFill, Thm.Txt);
	Bar(0, 29, 639, 349);
	BtnOpen.Draw;
	BtnAbout.Draw;
	BtnExit.Draw;
	MouseShow;
	
	{Pass first command line argument as file name, LoadFile will ignore it if empty}
	LoadFile(ParamStr(1));

	repeat
		Key := GetKey;
		HotkeyPressed := Key; {DEBUG - move to event loop later}
		
		BtnAbout.CheckEvent;
		BtnOpen.CheckEvent;
		BtnExit.CheckEvent;

		HkUp.CheckEvent;
		HkDown.CheckEvent;
		HkHome.CheckEvent;
		HkEnd.CheckEvent;

		if FileOpened then
		begin
			BtnPageUp.CheckEvent;
			BtnPageDown.CheckEvent;
		end;
	until False;
end.