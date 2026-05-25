{Desktop settings - in separate file since both desktop and config util uses the record}

TDeskSetting = record
	DeskID:      Integer;
	LinkCapt,
	LinkTarget,
	ConfLinkDel,
	ConfExit:    Boolean;
end;