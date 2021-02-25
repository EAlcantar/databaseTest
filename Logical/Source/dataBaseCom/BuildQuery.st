
ACTION BuildQuery: 
	
	(* Se arma el string que determina cual será
		 la consula que se ejecutará en la base de datos SQL *)	
	brsmemset(ADR(queryStr),0,SIZEOF(queryStr));
	brsstrcat(ADR(queryStr),ADR(gDbCtrl.param.queryType));
	brsstrcat(ADR(queryStr),ADR(gDbCtrl.param.table));
	
	(* Preparando el bloque de mapp para ejecutar la consulta *)
	MpDatabase_SQL_Query.MpLink := ADR(gDatabaseCore);
	MpDatabase_SQL_Query.Enable := TRUE;
	MpDatabase_SQL_Query.Name   := ADR(queryStr);
	MpDatabase_SQL_Query();

END_ACTION
