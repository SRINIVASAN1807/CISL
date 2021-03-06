/*
	CSIL - Columnstore Indexes Scripts Library for SQL Server 2012: 
	Extended Events Setup Script for Index Creation events 'clustered_columnstore_index_rebuild', 'column_store_index_build_low_memory', 'column_store_index_build_throttle', 'column_store_index_build_process_segment'
	Version: 1.4.0, September 2016

	Copyright 2015-2016 Niko Neugebauer, OH22 IS (http://www.nikoport.com/columnstore/), (http://www.oh22.is/)

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/


/* Stop Session if it already exists */
IF EXISTS(SELECT *
				FROM sys.server_event_sessions sess
				INNER JOIN sys.dm_xe_sessions actSess
					on sess.NAME = actSess.NAME
				WHERE sess.NAME = 'cstore_XE_IndexCreation')
BEGIN
	ALTER EVENT SESSION cstore_XE_IndexCreation
		ON SERVER 
			STATE = STOP;
END

/* Drop the definition of the currently configured XE session */
IF EXISTS
    (SELECT * FROM sys.server_event_sessions sess
        WHERE name = 'cstore_XE_IndexCreation')
BEGIN

    DROP EVENT SESSION cstore_XE_IndexCreation
        ON SERVER;
	
END

/* Create a new default session */
CREATE EVENT SESSION [cstore_XE_IndexCreation] ON SERVER 
	ADD EVENT sqlserver.clustered_columnstore_index_rebuild(
		ACTION(sqlserver.database_name,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
	ADD EVENT sqlserver.column_store_index_build_low_memory(
		ACTION(sqlserver.database_name,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
	ADD EVENT sqlserver.column_store_index_build_throttle(
		ACTION(sqlserver.database_name,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)),
	ADD EVENT sqlserver.column_store_index_build_process_segment(
		ACTION(sqlserver.database_name,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))
	--ADD EVENT sqlserver.column_store_code_coverage(
	--	ACTION(sqlserver.database_name,sqlserver.query_plan_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username))
	ADD TARGET package0.ring_buffer(SET max_memory=(51200))
	WITH (MAX_MEMORY=51200 KB)
