
TYPE
	Db_ctrl_type : 	STRUCT 
		cmd : Db_cmd_type;
		param : Db_param_type;
		status : Db_status_type;
		state : Db_state_enum;
	END_STRUCT;
	Db_cmd_type : 	STRUCT 
		connectDb : BOOL;
		cancel : BOOL;
		refreshData : BOOL;
		excecuteQuery : BOOL;
		resetError : BOOL;
	END_STRUCT;
	Db_param_type : 	STRUCT 
		table : STRING[20];
		queryType : STRING[10];
		dataStructure : REFERENCE TO ProductionData_Db_table_type;
	END_STRUCT;
	Db_status_type : 	STRUCT 
		executingQuery : BOOL;
		queryDone : BOOL;
		errorActive : BOOL;
		connectionCounter : USINT;
		dbConnectionActive : BOOL;
		errorState : Db_states_enum;
	END_STRUCT;
	Db_state_enum :Db_states_enum;
	Db_states_enum : 
		(
		DB_NO_ERROR := 0,
		DB_DISCONNECTED := 10,
		DB_TRY_CONNECTION := 20,
		DB_WAIT_COMMAND := 30,
		DB_EXECUTE_QUERY := 40,
		DB_ERROR_ACTIVE := 100,
		DB_ERROR_RESET := 101,
		DB_DISABLE_FB := 102
		);
END_TYPE
