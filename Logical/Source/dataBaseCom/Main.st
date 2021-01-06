
PROGRAM _INIT
	MpDatabaseCore_0.Enable := TRUE;
	MpDatabaseCore_0.MpLink := ADR(gDatabaseCore);
	 
END_PROGRAM

PROGRAM _CYCLIC
	
	
	MpDatabaseCore_0();
	
	 
END_PROGRAM

PROGRAM _EXIT
	
	MpDatabaseCore_0.Enable := FALSE;
	MpDatabaseCore_0();
	 
END_PROGRAM

