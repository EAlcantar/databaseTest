(*************************************************************************************

	Este programa genera una interfaz de conexión con una base de datos Microsoft
	SQL (probado con MSSQL Server 2016). Se utiliza el componente de mapp Database
	para facilitar la implementación de la conexión con la base de datos. 
	Como middleware, se utiliza un servidor HTTP que se levanta mediante un script
	de Python (probado con Python 3.8.2, ver archivo mappdatabaseconnector3_5_12.py).
	El servidor HTTP es el que se encarga de enviar los queries configurados en el
	componente de mapp Database.

	La conexión con la base de datos es utilizada para almacenar y extraer datos de
	producción mediante un comando de ejecución de query y definiendo cual tabla se
	quiere consultar.

	Versiones utilizadas: 

	Mapp Services 5.12

	Microsoft SQL Server 2016

	Python 3.8.2

	MySQL connector v8.0 32-bit (https://dev.mysql.com/downloads/connector/python/)

	MS SQL pyodbc connector v4.0 32- bit (instalado mediante el pip de Python ó se
	puede descargar de:
	https://docs.microsoft.com/en-us/sql/connect/python/python-driver-for-sql-server?view=sql-server-ver15&viewFallbackFrom=sql-server-2017

 *************************************************************************************)

PROGRAM _INIT
	(* Estructura global que contiene las estructuras de intercambio de datos con la
		base de datos Microsoft SQL  *)
	gDbStruct;
	(* Inicializando la máquina de estados *)
	gDbCtrl.state := DB_DISCONNECTED;	 
END_PROGRAM

PROGRAM _CYCLIC
	
	//Enlazando las estructuras de datos para almacenar la información de las consultas 
	gDbCtrl.param.dataStructure := ADR(gDbStruct);
	
	CASE gDbCtrl.state OF
		
		DB_DISCONNECTED:
			
			IF gDbCtrl.status.connectionCounter <= CONNECT_TRY_LIMIT THEN
				//Preparando bloque de mapp Database
				MpDatabaseCore_SQL.Enable  := TRUE;
				MpDatabaseCore_SQL.MpLink  := ADR(gDatabaseCore);
				//Transición a estado de conexión
				gDbCtrl.state 					 := DB_TRY_CONNECTION;	
				gDbCtrl.status.connectionCounter := gDbCtrl.status.connectionCounter + 1;
			ELSIF gDbCtrl.cmd.connectDb THEN
				//Preparando bloque de mapp Database
				MpDatabaseCore_SQL.Enable  := TRUE;
				MpDatabaseCore_SQL.MpLink  := ADR(gDatabaseCore);
				gDbCtrl.cmd.connectDb			 := FALSE;
				//Transición a estado de conexión
				gDbCtrl.state 					 := DB_TRY_CONNECTION;	
				gDbCtrl.status.connectionCounter := gDbCtrl.status.connectionCounter + 1;
			ELSE
				//Cuando los intentos de conexión son más de 3, se reinicia el contador
				gDbCtrl.status.connectionCounter := 0;
			END_IF;
		
		DB_TRY_CONNECTION:
			
			//Se envía el comando de conexión con SQL
			MpDatabaseCore_SQL.Connect := TRUE;
			
			IF MpDatabaseCore_SQL.CommandBusy THEN
				(* ESPERANDO A QUE EL BLOQUE ESTABLEZCA LA CONEXIÓN CON SQL *)
			ELSIF MpDatabaseCore_SQL.CommandDone AND MpDatabaseCore_SQL.Connected THEN
				gDbCtrl.status.dbConnectionActive := TRUE;
				gDbCtrl.status.connectionCounter  := 0; //Reset del contador de intentos de conexión
				gDbCtrl.state 					  := DB_WAIT_COMMAND;
			ELSIF gDbCtrl.cmd.cancel THEN
				MpDatabaseCore_SQL.Enable  		  := FALSE;
				MpDatabaseCore_SQL.Connect 		  := FALSE;
				gDbCtrl.state 			   		  := DB_DISCONNECTED;
			ELSIF MpDatabaseCore_SQL.Error THEN
				gDbCtrl.status.errorActive 		  := TRUE;
				gDbCtrl.status.errorState  		  := gDbCtrl.state;
				//Transición al estado de error activo
				gDbCtrl.state 			   		  := DB_ERROR_ACTIVE;
			END_IF;
		
		DB_WAIT_COMMAND:
			
			(* Selección de consulta por ejecutar *)
			
			IF gDbCtrl.cmd.excecuteQuery THEN
				gDbCtrl.cmd.excecuteQuery  := FALSE;
				BuildQuery; //Construyendo la consulta
				gDbCtrl.state 			   := DB_EXECUTE_QUERY;
			ELSIF gDbCtrl.cmd.refreshData THEN
				gDbCtrl.cmd.refreshData	   := FALSE;
				//El refresh de datos en pantalla equivale al query SELECT
				gDbCtrl.param.queryType    := QUERY_SELECT;
				BuildQuery; //Construyendo la consulta	
				gDbCtrl.state 			   := DB_EXECUTE_QUERY;
			END_IF;		
			
		DB_EXECUTE_QUERY:
			
			//Se ejecuta la consulta
			MpDatabase_SQL_Query.Execute := TRUE;
			MpDatabase_SQL_Query();
			
			IF MpDatabase_SQL_Query.CommandBusy THEN
				(* ESPERANDO A QUE EL BLOQUE DE CONSULTAS FINALICE SU EJECUCIÓN *)
				gDbCtrl.status.executingQuery := TRUE; // Se le vanta bandera que indica ejecución de consulta en proceso
			ELSIF MpDatabase_SQL_Query.CommandDone THEN
				gDbCtrl.status.executingQuery := FALSE; //Reset de bandera
				gDbCtrl.state 			      := DB_WAIT_COMMAND;
				MpDatabase_SQL_Query.Execute  := FALSE;
			ELSIF gDbCtrl.cmd.cancel THEN
				gDbCtrl.status.executingQuery := FALSE; //Reset de bandera
				//Se deshabilita el bloque para dejarlo disponible para próximas consultas
				MpDatabase_SQL_Query.Enable   := FALSE;
				MpDatabase_SQL_Query.Execute  := FALSE;
				MpDatabase_SQL_Query();
				//Validando que el bloque de consultas esté completamente deshabilitado
				IF NOT MpDatabase_SQL_Query.Active THEN
					//Transición al estado de espera de comandos
					gDbCtrl.state 			  := DB_WAIT_COMMAND;
				END_IF;
			ELSIF MpDatabase_SQL_Query.Error THEN
				gDbCtrl.status.errorActive    := TRUE;
				gDbCtrl.status.errorState     := gDbCtrl.state;
				//Transición al estado de error activo
				gDbCtrl.state 			      := DB_ERROR_ACTIVE;
			END_IF;
				
		DB_ERROR_ACTIVE:
			
			//Desactivando comandos
			gDbCtrl.cmd.connectDb     	  	  := FALSE;
			gDbCtrl.cmd.excecuteQuery 	  	  := FALSE;
			gDbCtrl.cmd.refreshData       	  := FALSE;
			//Desactivando banderas
			gDbCtrl.status.queryDone  	  	  := FALSE;
			gDbCtrl.status.executingQuery 	  := FALSE;
			gDbCtrl.status.dbConnectionActive := FALSE;
			
			MpDatabaseCore_SQL.ErrorReset     := gDbCtrl.cmd.resetError;
			MpDatabase_SQL_Query.ErrorReset   := gDbCtrl.cmd.resetError;
			MpDatabase_SQL_Query();
			
			IF NOT MpDatabaseCore_SQL.Error AND NOT MpDatabase_SQL_Query.Error THEN
				gDbCtrl.state 			   	  := DB_ERROR_RESET;
			END_IF;
		
		DB_ERROR_RESET:
						
			//Validando si la base de datos sigue conectada
			IF NOT MpDatabaseCore_SQL.Connected THEN
				gDbCtrl.cmd.resetError     		:= FALSE;
				gDbCtrl.status.errorActive 		:= FALSE;
				gDbCtrl.status.errorState  		:= DB_NO_ERROR;
				//Transición al estado que deshabilita los bloques para intentar una nueva conexión
				gDbCtrl.state 			   		:= DB_DISABLE_FB;
			ELSE
				gDbCtrl.cmd.resetError     		:= FALSE;
				gDbCtrl.status.errorActive 		:= FALSE;
				gDbCtrl.status.errorState  		:= DB_NO_ERROR;
				//Se libera al bloque de consultas
				MpDatabaseCore_SQL.ErrorReset   := FALSE;
				MpDatabase_SQL_Query.ErrorReset := FALSE;
				MpDatabase_SQL_Query.Enable  	:= FALSE;
				MpDatabase_SQL_Query.Execute 	:= FALSE;
				MpDatabase_SQL_Query();
				//Validando que el bloque de consultas esté completamente deshabilitado
				IF NOT MpDatabase_SQL_Query.Active THEN
					//Transición al estado de espera de comandos
					gDbCtrl.state 			    := DB_WAIT_COMMAND;
				END_IF;
			END_IF;
			
			IF MpDatabaseCore_SQL.Error AND MpDatabase_SQL_Query.Error THEN
				gDbCtrl.status.errorActive 		:= TRUE;
				gDbCtrl.state 			   		:= DB_ERROR_ACTIVE;
			END_IF;
			
		DB_DISABLE_FB:	
		
			MpDatabaseCore_SQL.Enable    := FALSE;
			MpDatabaseCore_SQL.Connect   := FALSE;
			MpDatabase_SQL_Query.Enable  := FALSE;
			MpDatabase_SQL_Query.Execute := FALSE;
			MpDatabase_SQL_Query();
			IF NOT MpDatabaseCore_SQL.Active AND NOT MpDatabase_SQL_Query.Active THEN
				//Transición al estado que indica desconexión
				gDbCtrl.state 			     := DB_DISCONNECTED;
			END_IF;
		
	END_CASE;
	 
	(* Ejecutando el bloque principal de conexión con SQL *)
	MpDatabaseCore_SQL();
	
END_PROGRAM

PROGRAM _EXIT
	
	(* Deshabilitando el bloque principal de manejo de comuincación con SQL
		para evitar errores después de transferir cambios al PLC            *)
	MpDatabaseCore_SQL.Enable := FALSE;
	MpDatabaseCore_SQL();
		 
END_PROGRAM

