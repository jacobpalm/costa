{
	The Costa GUI sample program
	By Jacob Palm

	This code demonstrates how to get started with a simple program using
	the Costa library, to create programs the have the look and feel of
	Costa.
}

program Sample;

uses
	{Any program utilizing the Costa library will have CostaLib added to
	 the 'uses' clause.}
	CostaLib, Crt, Graph;

const
	AppName         = 'Sample program';
	AppVersion      = '2.0';
	AppAuthor       = 'Jacob Palm';
	AppIcon         = 'PROGRAM';

	CAP_ABOUT       = 'A' + #127 + 'bout...';
	CAP_EXIT        = 'E' + #127 + 'xit';

	MSG_SAMPLE_TEXT = 'Sample text for the program,' + #13 +
	                  'on multiple lines.';
	MSG_EXIT_TITLE  = 'Exit sample program';
	MSG_EXIT_PROMPT = 'Are you sure you want to exit the sample' + #13 + 'program?';

var
	{Objects are just variables you can declare like any other}
	WinSample: TWindow;
	BtnAbout, BtnExit: TButton;
	ImgSample: TIcon;

	{We'll use this to hold user key input, so we can check what to do with it}
	Key: String;

begin
	{Set window size - center on screen via sizeCenter}
	WinSample.Init(sizeCenter, sizeCenter, 244, 200);

	{Set Exit button position and size - left, top, width, height}
	BtnExit.Init(545, 2, SizeDefault, SizeDefault, CAP_EXIT);

	{About button}
	BtnAbout.Init(446, 2, SizeDefault, SizeDefault, CAP_ABOUT);
				
	{Create an icon. Only the filename, without extension or path, is set.
	 This is because icons are always in the same directory. An icon does
	 not use the width or height property, they are always 32x32 pixels.}
	ImgSample.Init(WinSample.Top + 34, WinSample.Left + 200, 'SAMPLE');
	
	{Remember to hide/show the mouse when drawing!}
	MouseHide;

	{Top menu - default for all Costa apps, holds buttons like about,
	 exit etc.}
	MenuBar.Draw; 

	{App background - not drawn automatically, as some apps may wish to use
	 a custom background.}
	SetFillStyle(SolidFill, Thm.Win);
	Bar(0, 29, 639, 349);
	
	WinSample.Draw;
	BtnAbout.Draw;
	BtnExit.Draw;
	Print(MSG_SAMPLE_TEXT, WinSample.Left + 12, WinSample.Top + 70, Thm.WinText);
	MouseShow;

	ImgSample.Draw;

	repeat
		{Fetch any pressed key}
		Key := GetKey;       

		{BtnClick will return True or False, and can be used to check
		 if a button is clicked. It will also take care of drawing the
		 button in pressed or unpressed state.}
		if BtnExit.Clicked or (Key = KeyAltX) then
		begin
			{Show a messagebox, asking to confirm that the user wants to exit.
			  is a constant from the Costa library, used to indicate the
			 type of messagebox we want to show (question, error etc.).}
			if MsgBox(MSG_EXIT_TITLE, MSG_EXIT_PROMPT, MsgQuest) then
			begin
				CloseGraph;
				Halt;
			end;
		end;

		{Use the built-in function for showing an about box - this ensures
		 consistency between all programs}
		if BtnAbout.Clicked or (Key = KeyAltA) then
		  AboutBox(AppName, AppVersion, AppAuthor, AppIcon);
		
	until False;

end.