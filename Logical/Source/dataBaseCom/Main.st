
PROGRAM _INIT
	
	gDbStruct;
	
	MpDatabaseCore_0.Enable := TRUE;
	MpDatabaseCore_0.MpLink := ADR(gDatabaseCore);
	 
END_PROGRAM

PROGRAM _CYCLIC
	
	MpDatabaseQuery_0(MpLink := ADR(gDatabaseCore), Enable := TRUE, Name := ADR('createTable'));
	MpDatabaseQuery_1(MpLink := ADR(gDatabaseCore), Enable := TRUE, Name := ADR('insertData'));
	MpDatabaseQuery_2(MpLink := ADR(gDatabaseCore), Enable := TRUE, Name := ADR('extractData'));

	MpDatabaseCore_0();
	
	 
END_PROGRAM

PROGRAM _EXIT
	
	MpDatabaseCore_0.Enable := FALSE;
	MpDatabaseCore_0();
	
	MpDatabaseQuery_0.Enable := FALSE;
	MpDatabaseQuery_0();
	
	 
END_PROGRAM

