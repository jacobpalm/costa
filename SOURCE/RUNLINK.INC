{Type for running an external program - used by desktop and costa.exe only}
TRunLink = record
	FileName:    PathStr;
	Path:        DirStr;
	Parameters:  ComStr;
	PauseOnExit: Boolean;
end;