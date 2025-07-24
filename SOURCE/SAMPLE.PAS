{
	The Costa GUI sample application
	By Jacob Palm

	This code demonstrates how to get started with a simple application using
	the Costa library, to create applications the have the look and feel of
	Costa.
}

program Sample;

uses
	{Any application utilizing the Costa library will have CostaLib added to
	 the 'uses' clause.}
	CostaLib, Crt, Graph;

const
	AppName    = 'Sample Application';
	AppVersion = '2.0';
	AppAuthor  = 'Jacob Palm';
	AppIcon    = 'PROGRAM';
	ExitText   = 'Are you sure you want to exit the sample' + #13 + 'application?';

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
	BtnExit.Init(545, 2, SizeDefault, SizeDefault, 'E' + HotkeySymbol + 'xit');
	{The HotkeySymbol character determines which letter on the button is
	 underlined.
	 This is actually handled by the Print procedure, and can be used
	 anywhere text is printed.}

	{About button}
	BtnAbout.Init(446, 2, SizeDefault, SizeDefault, HotkeySymbol + 'About');
				
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
	Print('Sample text, header font', WinSample.Left + 12, WinSample.Top + 70, Thm.WinText);
	Print('Sample text, normal font', WinSample.Left + 12, WinSample.Top + 85, Thm.WinText);
	MouseShow;

	ImgSample.Draw;

	repeat
		{Fetch any pressed key}
		Key := GetKey;       

		{ObjBtnClick will return True or False, and can be used to check
		 if a button is clicked. It will also take care of drawing the
		 button in pressed or unpressed state.}
		if ObjBtnClick(BtnExit) or (Key = KeyAltX) then
		begin
			{Show a messagebox, asking to confirm that the user wants to exit.
			  is a constant from the Costa library, used to indicate the
			 type of messagebox we want to show (question, error etc.).}
			if MsgBox('Exit sample application', ExitText, MsgQuest) then
			begin
				CloseGraph;
				Halt;
			end;
		end;

		{Use the built-in function for showing an about box - this ensures
		 consistency between all applications}
		if ObjBtnClick(BtnAbout) or (Key = KeyAltA) then
		  AboutBox(AppName, AppVersion, AppAuthor, AppIcon);
		
	until False;

end.