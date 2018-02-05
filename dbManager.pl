use DBI; 
use Tk;
use Tk::HList;
use Tk::DialogBox;
use Tk::NoteBook;
use Tk::LabEntry;
use Tk::ErrorDialog; 
use Win32; 
use Win32::API;
use Win32::Process;
use Switch;
use Tk::Toplevel;
use Tk::ItemStyle;
use Tk::Balloon; 
use Tk::Graph;
use DBD::Chart;


$tlChart ="tlSharedPoolChart";
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ 	 
#                     Declare global variables 
#  All global variables are prefixed with "g", except the variables for
# widgets which must be necessarily accessible anywhere in the program
$gDEBUG = 0;
$gdbhPasswordDB = "";
$gdbSessions = "";
$gdbhSessionDB = "";
$gUserName = "";
$gCurrentSQLWindow = "";
$gTotalSessions = "Total sessions: 0";
$gSQL = "";
$gOracleVersion = "0";
$gSDEVersion = "0";

# Message types
$gERROR = "error";
$gINFO  = "info";

# Window types
$gPARENT = 0;
$gCHILD  =1;

#  Build the data structure for the programs that are used as editors
# The id field is used for clarity in identifying an editor's hash.
$gNOTEPAD = 0;
$gSQL_DEV = 1;
$gEXCEL =   2;
$gSQL_PLUS = 3;

@gOutput = ( {'id' => $gNOTEPAD,
              'name' => "Notepad",
              'exePath' => "C:\\Windows\\notepad.exe",
	      'command' =>  "notepad  varOutputFile"
             },
             {'id' => $gSQL_DEV,
              'name' => "SQL Developer",
              'exePath' =>   "C:\\sqldeveloper\\sqldeveloper.exe",
	      'command' =>  "sqldeveloper varOutputFile"
             },
	     {'id' => $gEXCEL,
              'name' => "MS Excel",
              'exePath' => "C:\\Program Files\\Microsoft Office\\OFFICE11\\EXCEL.EXE",
	      'command' =>  "excel  varOutputFile"
             },
	     {'id' => $gSQL_PLUS,
              'name' => "SQL Plus",
              'exePath' => "C:\\Oracle11g\\product\\11.2.0\\dbhome_1\\BIN\\sqlplus.exe",
	      'command' =>  "sqlplusw  varLogin"
             }
	    );
	    
# Column IDs 
$gCOL_SID_BLOCKED = 5; #  This column corresponds to the SID_WAITING column
                       # of the V$LOCK table in the hlstLocks HList query.
                       # It's referenced in the sub getLockedObject.
#  The following two variables are determined in the sub getLockedObject 
# and are used to dynamically build the SQL query for the hlstLockedObject
# HList.
$gLockedTable = "";
@gLockedColumns = ();

@gTotalRows =();


#-----------------------------------------------------------------------------   	
#               Build the HList widgets' data structure. 
#-----------------------------------------------------------------------------	 
#   The big idea behind creating an HList data structure was to minimize the 
# duplication of code, i.e. maximize code reuse. There's just one sub to create 
# the HLists, one sub to display the HList, one sub to sort the HList data, etc. 
# To add a new HList display requires only that you add the appropriate elements 
# to the data structure and a menu item to invoke its display. It then "inherits" 
# all the functionality of the other HLists displays.


#                     HList IDs
#  Keep these values in sync with the order in which
# they appear in the HList data structure below.

$gSESSIONS        = 0;
$gSESS_LONGOPS    = 1;
$gSESS_EVENTS     = 2;
$gSYS_EVENTS      = 3;
$gSYS_EVENTS_PERCENTAGES = 4;
$gSESS_WAITS             = 5;
$gDML_LOCKS       = 6;
$gBLOCKING_LOCKS  = 7;
$gLOCKED_OBJECT   = 8;
$gSQL_TEMP_SEGS  = 9;
$gTEMP_SEGS_HWM   = 10;
$gSESS_STATS      = 11;
$gSYS_ACTIVE_SQL  = 12;
$gSQL             = 13;
$gPREV_SQL        = 14;
$gSQL_TEXT        = 15;
$gOPEN_CURSORS    = 16;
$gTOP_10_SQL      = 17;
$gSESS_IO         = 18;
$gJOBS            = 19;
$gRUNNING_JOBS    = 20;
$gALERT_LOG       = 21;
$gALERT_LOG_ERRORS = 22;
$gSHARED_POOL     = 23;
$gSHARED_POOL_RESERVED  = 24;
$gUSERS           = 25;
$gFAILED_LOGONS   = 26;
$gINVALID_LOGONS  = 27;
$gUSER_PRIVS      = 28;
$gROLES           = 29;
$gROLE_PRIVS      = 30;
$gROLE_USERS      = 31;
$gSESS_TIME_MODEL = 32;
$gSESS_HISTORY    = 33;
$gTABLESPACES     = 34;
$gFREE_SPACE      = 35;
$gDATA_FILES      = 36;
$gTBLSPC_OBJS     = 37;
$gDATAFILE_OBJS   = 38;
$gUSER_OBJS       = 39;
$gDATABASE_OBJS   = 40;
$gOBJECT_ACCESS   = 41;
$gOBJECT_DEFINITION = 42;
$gDBA_OBJECTS     = 43;
$gSDE_SESSIONS    = 44;
$gSDE_TABLES      = 45;
$gSDE_VERSION     = 46;
$gSDE_DBTUNE      = 47;
$gSDE_TABLE_REGISTRY = 48;
$gSDE_SERVER_CONFIG  = 49;
$gDB_PARAMETERS    = 50;
$gDB_HIDDEN_PARAMS = 51;
$gDB_OBJECT_CACHE  = 52;
$gLIBRARY_CACHE    = 53;
$gSGA              = 54;
$gDB_LINKS         = 55;
$gUSER_SCRIPT      = 56;
$gUSER_TABLE_PRIVS = 57;
$gTEMP_SEGS_USAGE  = 58;
$gSQL_FULL_TEXT    = 59;
$gSESS_OBJECT      = 60;
$gTBLSPC_USER_USAGE = 61;
$gLAYERS            = 62;
$gDISPLAY_TABLE     = 63;
$gTABLE_COLUMNS     = 64;
$gDBA_REGISTRY      = 65;

#   The varOrderBy string in the query hash is dynamically changed whenever the user
#  clicks a column header. Similarly, varSIDs in the child window's query is 
#  programmatically altered depending upon what selections are made in the parent
#  window.
#  NOTE: The id field isn't actually referenced anywhere in the program but
#       was put there to easily identify which particular HList the hash 
#       is a member of.  
@gHLists = ( 
	       { 'id' => $gSESSIONS,
		 'windowType' => $gPARENT,
		 'name' => "hlstSessions",
		 'parent' => "winMain",
		 'title' => "User Sessions ",
		 'columns' => ["osuser",
			       "username", 
			       "sid",
			       "serial#", 
			       "os_pid",
			       "aud_sid",
			       "machine",
			       "terminal", 
			       "status",
			       "command",
			       "logon_time",
			       "program",
			       "duration_min",
			       "latchwait",
			       "latchspin",
			       "pga_used_mem",
			       "pga_alloc_mem",
			       "pga_max_mem",
			       "pga_freeable_mem"
			       ], 
		 'headers' => ["OSUser",
			       "Username",
			       "SID",
			       "Serial #",
			       "OS PID",
			       "Audit SID",
			       "Machine",
			       "Terminal",
			       "Status",
			       "Command",
			       "Logon Time",
			       "Program",
			       "Duration (Mins)",
			       "Latch Wait",
			       "Latch Spin",
			       "PGA Memory Used (KB)",
			       "PGA Memory Allocated (KB)",
			       "PGA Memory Maximum (KB)",
			       "PGA Memory Freeable (KB)" 
			       ],
		 'query' => qq{ SELECT s.osuser osuser,
				       s.username username,
				       s.sid sid,
				       s.serial\# serial\#,
				       p.spid os_pid,
				       s.audsid aud_sid,
				       s.machine machine,
				       s.terminal terminal,
				       s.status status,
				       DECODE(s.command,
						0,'No command',
						1,'Create table' ,
						2,'Insert',
						3,'Select' ,
						6,'Update',
						7,'Delete' ,
						9,'Create index',
						10,'Drop index' ,
						11,'Alter index',
						12,'Drop table' ,
						13,'Create seq',
						14,'Alter sequence' ,
						15,'Alter table',
						16,'Drop sequ.' ,
						17,'Grant',
						19,'Create synonym' ,
						20,'Drop synonym',
						21,'Create view' ,
						22,'Drop view',
						23,'Validate index' ,
						24,'Create procedure',
						25,'Alter procedure' ,
						26,'Lock table',
						42,'Alter session' ,
						44,'Commit',
						45,'Rollback' ,
						46,'Savepoint',
						47,'PL/SQL Exec' ,
						48,'Set Transaction',
						60,'Alter trigger' ,
						62,'Analyze Table',
						63,'Analyze index' ,
						71,'Create Snapshot Log',
						72,'Alter Snapshot Log' ,
						73,'Drop Snapshot Log',
						74,'Create Snapshot' ,
						75,'Alter Snapshot',
						76,'drop Snapshot' ,
						85,'Truncate table',
						 '? : '||s.command) command,
				       TO_CHAR(s.logon_time,' Mon-DD-YYYY HH24:MI ') logon_time,
				       s.program  program,
				       ROUND((s.last_call_et/60),2) duration_min,
                                       latchwait,
                                       latchspin,
                                       ROUND(pga_used_mem / 1024 ) pga_used_mem,
                                       ROUND(pga_alloc_mem / 1024) pga_alloc_mem,
                                       ROUND(pga_max_mem / 1024) pga_max_mem,
                                       ROUND(pga_freeable_mem / 1024) pga_freeable_mem
				  FROM v\$session s,
				       v\$process p,
				       v\$transaction t,
				       v\$rollstat r,
				       v\$rollname n
				  WHERE s.paddr = p.addr
				    AND s.taddr = t.addr (+)
				    AND t.xidusn = r.usn (+)
				    AND r.usn = n.usn (+) 
				  ORDER BY varOrderBy 
			       },
		 'orderBy' => "osuser",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "sessions.txt",
		 'outputColumns' => [0 .. 9]
	       },  
	       { 'id' => $gSESS_LONGOPS,
		 'windowType' => $gPARENT,
		 'name' => "hlstSessLongOps",
		 'parent' => "tlSessLongOps",
		 'title' => "Operations Taking Longer Than 6 Seconds", 
		 'columns' => ["osuser",
			       "username", 
			       "sid",
			       "opname", 
			       "target", 
			       "target_desc",
			       "sofar",
			       "totalwork",
			       "units",
			       "start_time",
			       "last_update_time",
			       "time_remaining",
			       "elapsed_seconds",
			       "message"
			       ], 
		 'headers' => ["OSUser",
			       "Username",
			       "SID",
			       "Operation Description",
			       "Target Object",
			       "Target Description",
			       "Work Done So Far",
			       "Total Work To Do",
			       "Units",
			       "Start Time",
			       "Last Update Time",
			       "Estimated Time Remaining",
			       "Elapsed Seconds",
			       "Statistics Summary Message"
			       ],
		 'query' => qq{ SELECT sess.osuser,
				       sess.username,
				       sess.sid,
				       sl.opname,
				       sl.target,
				       sl.target_desc,
				       sl.sofar,
				       sl.totalwork,
				       sl.units,
				       TO_CHAR(sl.start_time,'Mon-dd-yyyy hh24:mi') start_time,
				       TO_CHAR(sl.last_update_time,'Mon-dd-yyyy hh24:mi') last_update_time,
				       sl.time_remaining,
				       sl.elapsed_seconds,
				       sl.message 
				  FROM v\$session_longops sl,
				       v\$session sess
				 WHERE sess.sid = sl.sid
				   AND sess.serial\# = sl.serial\#
				   AND sl.time_remaining >0 
				  ORDER BY varOrderBy
			       },
		 'orderBy' => "osuser",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "sessions.txt",
		 'outputColumns' => [0 .. 13]
	       },   
	       { 'id' => $gSESS_EVENTS,
		 'windowType' => $gCHILD,
		 'name' => "hlstSessEvents",
		 'parent' => "tlSessEvents",
		 'title' => "Session Events",
		 'columns' => ["osuser",
			       "username",
			       "sid",
			       "event",
			       "total_waits",
			       "total_timeouts",
			       "time_waited",
			       "average_wait",
			       "max_wait",
			       "time_waited_micro"
			       ],
		 'headers' => ["OSUser",
			       "Username",
			       "SID",
			       "Event",
			       "Total Waits",
			       "Total Timeouts",
			       "Time Waited (Secs)",
			       "Average Wait (Secs)",
			       "Max Wait (Secs)",
			       "Time Waited (Micro Secs)"
			       ],
		 'query' => qq{ SELECT s.osuser,
				       s.username,
				       s.sid,                                                                                                                                                                                                                      
				       e.event,                                                                                                                                                                                                               
				       e.total_waits,                                                                                                                                                                                                                
				       e.total_timeouts,    
                                       TO_CHAR((e.time_waited/100),'999,999,999.999') time_waited,                                                                                                                                                                                                                
				       TO_CHAR((e.average_wait/100),'999,999,999.999') average_wait,                                                                                                                                                                                                                
				       TO_CHAR((e.max_wait/100),'999,999,999.999') max_wait,                                                                                                                                                                                                                   
				       TO_CHAR(e.time_waited_micro,'999,999,999,999,999') time_waited_micro        
				  FROM  v\$session s,
					v\$session_event e
				  WHERE s.sid in (varSIDs)
				    AND s.sid = e.sid
				  ORDER BY varOrderBy
			       } ,
		 'orderBy' => "event",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gSESSIONS,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "events.txt",
		 'outputColumns' => [0 .. 9]
	       },  
	       { 'id' => $gSYS_EVENTS,
		 'windowType' => $gPARENT,
		 'name' => "hlstSysEvents",
		 'parent' => "tlSysEvents",
		 'title' => "All System Events",
		 'columns' => ["event",
			       "total_waits",
			       "total_timeouts",
			       "time_waited",
			       "average_wait",
			       "startup_time"
			       ],
		 'headers' => ["Event",
			       "Total Waits",
			       "Total Timeouts",
			       "Time Waited (Secs)",
			       "Average Wait (Secs)",
			       "Startup Time"
			       ],
		 'query' => qq{ SELECT e.event,
				       e.total_waits,
				       e.total_timeouts,
				       TO_CHAR((e.time_waited/100),'999,999,999.999') time_waited,
				       TO_CHAR((e.average_wait/100),'999,999,999.999')average_wait,
				       TO_CHAR(i.startup_time,' Mon-DD-YYYY HH24:MI ')startup_time
				FROM v\$system_event e,
				     v\$instance i  
				ORDER BY varOrderBy
			       } ,
		 'orderBy' => "event",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gEXCEL,
		 'outputFile' => "events.xls",
		 'outputColumns' => [0 .. 5]
	       },  	
	        #         System Event Percentages
                # The following query was taken from 
		#  http://www.oracle.com/technology/pub/articles/schumacher_10gwait.html
		#
		#  Exploring the Oracle Database 10g Release 1 Wait Interface
		#     by Robin Schumacher 
		#
	       { 'id' => $gSYS_EVENTS_PERCENTAGES,
		 'windowType' => $gPARENT,
		 'name' => "hlstSysEventsPercentages",
		 'parent' => "tlSysEventsPercentages",
		 'title' => "System Events Percentages",
		 'columns' => ["event",
			       "total_waits",
			       "pct_waits",
			       "time_wait_sec",
			       "pct_time_waited",
			       "total_timeouts",
			       "pct_timeouts",
                               "average_wait_sec"
			       ],
		 'headers' => ["Event",
			       "Total Waits",
			       "Pct Waits",
			       "Time Waited Sec",
			       "Pct Time Waited",
			       "Total Timeouts",
			       "Pct Timeouts",
                               "Average Wait Sec"
			       ],
		 'query' => qq{SELECT event,
				  total_waits,
				  ROUND(100 *(total_waits / sum_waits),   2) pct_waits,
				  time_wait_sec,
				  ROUND(100 *(time_wait_sec / GREATEST(sum_time_waited,   1)),   2) pct_time_waited,
				  total_timeouts,
				  ROUND(100 *(total_timeouts / GREATEST(sum_timeouts,   1)),   2) pct_timeouts,
				  average_wait_sec
				FROM
				  (SELECT event,
				          total_waits,
				          ROUND((time_waited / 100), 2) time_wait_sec,
				          total_timeouts,
				          ROUND((average_wait / 100), 2) average_wait_sec
				   FROM sys.v_\$system_event
				   WHERE event NOT IN('dispatcher timer',     
						      'i/o slave wait',    
				                      'jobq slave wait',  
						      'lock element cleanup',   
						      'Null event',      
						      'parallel query dequeue wait',    
						      'parallel query idle wait - Slaves',    
						      'pipe get', 
						      'PL/SQL lock timer',      
						      'pmon timer',       
						      'rdbms ipc message',   
						      'smon timer',       
						      'SQL*Net break/reset to client',
						      'SQL*Net message from client',     
						      'SQL*Net message to client',    
						      'SQL*Net more data from client', 
						      'virtual circuit status',   
						      'WMON goes to sleep')
				     AND event NOT LIKE '%Streams AQ:%'
				     AND event NOT LIKE '%done%'
				     AND event NOT LIKE '%Idle%' 
				     AND event NOT LIKE 'DFS%'
				     AND event NOT LIKE 'KXFX%'
				   ),
				  (SELECT SUM(total_waits) sum_waits,
					  SUM(total_timeouts) sum_timeouts,
					  SUM(ROUND((time_waited / 100),    2)) sum_time_waited
				   FROM sys.v_\$system_event
				   WHERE event NOT IN('dispatcher timer', 
						      'i/o slave wait',     
				                      'jobq slave wait',  
						      'lock element cleanup',   
						      'Null event',      
						      'parallel query dequeue wait',    
						      'parallel query idle wait - Slaves',    
					              'pipe get', 
						      'PL/SQL lock timer',      
						      'pmon timer',       
						      'rdbms ipc message',   
						      'smon timer',       
						      'SQL*Net break/reset to client',
						      'SQL*Net message from client',     
						      'SQL*Net message to client',    
						      'SQL*Net more data from client', 
						      'virtual circuit status',   
						      'WMON goes to sleep')
				     AND event NOT LIKE '%Streams AQ:%'
				     AND event NOT LIKE '%done%'
				     AND event NOT LIKE '%Idle%' 
				     AND event NOT LIKE 'DFS%'
				     AND event NOT LIKE 'KXFX%'
				  )
				ORDER BY varOrderBy 
	                       },
		 'orderBy' => "event",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gEXCEL,
		 'outputFile' => "events_summary.xls",
		 'outputColumns' => [0 .. 7]
	       },        
	       { 'id' => $gSESS_WAITS,
		 'windowType' => $gCHILD,
		 'name' => "hlstWaits",
		 'parent' => "tlWaits",
		 'title' => "Waits",
		 'columns' => ["osuser",
			       "username",
			       "sid",
			       "event",
			       "wait_time",
			       "seconds_in_wait",
			       "state",
			       "seq#",
			       "p1text",
			       "p1",
			       "p1raw",
			       "p2text",
			       "p2",
			       "p2raw",
			       "p3text",
			       "p3",
			       "p3raw"
			       ],
		 'headers' => ["OSUser",
			       "Username",
			       "SID",
			       "Event",
			       "Wait Time",
			       "Seconds in Wait",
			       "State",
			       "Seq#",
			       "P1 Text",
			       "P1",
			       "P1 Raw",
			       "P2 Text",
			       "P2",
			       "P2 Raw",
			       "P3 Text",
			       "P3",
			       "P3 Raw"
			       ],
		 'query' => qq{ SELECT s.osuser,
				       s.username,
				       s.sid,                                                                                                                                                                                                                      
				       w.event,
				       w.wait_time,
				       w.seconds_in_wait,
				       w.state,  
				       w.seq\#,
				       w.p1text,
				       w.p1,
				       w.p1raw,
				       w.p2text,
				       w.p2,
				       w.p2raw,
				       w.p3text,
				       w.p3,
				       w.p3raw
				  FROM  v\$session s,
					v\$session_wait w
				  WHERE s.sid in (varSIDs)
				    AND s.sid = w.sid
				  ORDER BY varOrderBy
			       } ,
		 'orderBy' => "event",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gSESSIONS,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "waits.txt",
		 'outputColumns' => [0 .. 15]
	       },  
	       { 'id' => $gDML_LOCKS,
		 'windowType' => $gPARENT,
		 'name' => "hlstLocks",
		 'parent' => "tlLocks",
		 'title' => "DML Locks",
		 'columns' => ["osuser",
			       "username",
			       "sid", 
			       "serial#",
			       "terminal",
			       "tbl",
			       "lmode",
			       "ctime",
			       "request",
			       "type"
			       ],
		 'headers' => ["OSUser",
			       "Username",
			       "SID",
			       "Serial#",
			       "Terminal",
			       "Object Locked",
			       "Lock Mode Held",
			       "Time Locked (Mins)",
			       "Lock Mode Requested" ,
			       "Lock Type"
			       ],
		 'query' => qq{SELECT ses.osuser,
				      NVL(ses.username,'Internal') username, 
				      lck.sid sid,
				      ses.serial\# serial\#, 
				      NVL(ses.terminal,'None') terminal,
				      usr.name||'.'||SUBSTR(obj.name,1,30) tbl, 
				      DECODE(lck.lmode,1,'No Lock', 
				   		       2,'Row Share', 
						       3,'Row Exclusive', 
						       4,'Share', 
						       5,'Share Row Exclusive', 
						       6,'Exclusive',
						       NULL) lmode, 
				      ROUND(lck.ctime / 60,   2) ctime,
				      DECODE(lck.request,1,'No Lock', 
						         2,'Row Share', 
						         3,'Row Exclusive', 
						         4,'Share', 
						         5,'Share Row Exclusive', 
						         6,'Exclusive',
							 NULL) request  ,
				      DECODE(lck.TYPE,'BL','Buffer hash table', 
						      'CF','Control File Transaction', 
						      'CI','Cross Instance Call', 
						      'CS','Control File Schema', 
						      'CU','Bind Enqueue', 
						      'DF','Data File', 
						      'DL','Direct-loader index-creation', 
						      'DM','Mount/startup db primary/secondary instance', 
						      'DR','Distributed Recovery Process', 
						      'DX','Distributed Transaction Entry', 
						      'FI','SGA Open-File Information', 
						      'FS','File Set', 
						      'IN','Instance Number', 
						      'IR','Instance Recovery Serialization', 
						      'IS','Instance State', 
						      'IV','Library Cache InValidation', 
						      'JQ','Job Queue', 
						      'KK','Redo Log "Kick"', 
						      'LS','Log Start/Log Switch', 
						      'MB','Master Buffer hash table', 
						      'MM','Mount Definition', 
						      'MR','Media Recovery', 
						      'PF','Password File', 
						      'PI','Parallel Slaves', 
						      'PR','Process Startup', 
						      'PS','Parallel Slaves Synchronization', 
						      'RE','USE_ROW_ENQUEUE Enforcement', 
						      'RT','Redo Thread', 
						      'RW','Row Wait', 
						      'SC','System Commit Number', 
						      'SH','System Commit Number HWM', 
						      'SM','SMON', 
						      'SQ','Sequence Number', 
						      'SR','Synchronized Replication', 
						      'SS','Sort Segment', 
						      'ST','Space Transaction', 
						      'SV','Sequence Number Value', 
						      'TA','Transaction Recovery', 
						      'TD','DDL enqueue', 
						      'TE','Extend-segment enqueue', 
						      'TM','DML enqueue', 
						      'TS','Temporary Segment', 
						      'TT','Temporary Table', 
						      'TX','Transaction', 
						      'UL','User-defined Lock', 
						      'UN','User Name', 
						      'US','Undo Segment Serialization', 
						      'WL','Being-written redo log instance', 
						      'WS','Write-atomic-log-switch global enqueue', 
						      'XA','Instance Attribute', 
						      'XI','Instance Registration') as type
			      FROM v\$lock    lck,  
				   v\$session ses, 
				   sys.user\$ usr, 
				   sys.obj\$  obj 
			      WHERE lck.sid = ses.sid 
			        AND obj.OBJ\# = DECODE(lck.id2,0,lck.id1,lck.id2)  
			        AND usr.user\# = obj.owner\# 
			        AND ses.type != 'BACKGROUND' 
			     ORDER BY varOrderBy
				} ,
		 'orderBy' => "osuser",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "blocking_locks.txt",
		 'outputColumns' => [0 .. 7]
	       }, 
	       { 'id' => $gBLOCKING_LOCKS,
		 'windowType' => $gPARENT,
		 'name' => "hlstBlockingLocks",
		 'parent' => "tlBlockingLocks",
		 'title' => "Blocking Locks",
		 'columns' => ["osuser_blocking",
			       "username_blocking",
			       "sid_blocking", 
			       "osuser_waiting",
			       "username_waiting",
			       "sid_waiting" ,
			       "locked_object_id",
			       "locked_object_name",
			       "locked_object_type"
			       ],
		 'headers' => ["OSUser Blocking",
			       "Username Blocking",
			       "SID Blocking",
			       "OSUser Waiting",
			       "Username Waiting",
			       "SID Waiting",
			       "Locked Object ID",
			       "Locked Object Name",
			       "Locked Object Type"
			       ],
		 'query' => qq{ SELECT sb.osuser   as osuser_blocking,
				       sb.username as username_blocking,   
				       sb.sid      as sid_blocking, 
				       sb.osuser   as osuser_waiting,
				       sw.username as username_waiting, 
				       sw.sid      as sid_waiting  ,
				       lb.id1      as locked_object_id,
				       dbo.object_name as locked_object_name,
				       dbo.object_type as locked_object_type
				FROM v\$lock lb,
				     v\$session sb,
				     v\$lock lw,
				     v\$session sw,
				     dba_objects dbo
				WHERE sb.sid = lb.sid
				  AND sw.sid = lw.sid
				  AND lb.block = 1
				  AND lw.request > 0
				  AND lb.id1 = lw.id1
				  AND lw.id2 = lw.id2
				  AND dbo.object_id = lb.id1 
				} ,
		 'orderBy' => "osuser_blocking",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "getLockedObject",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "locks.txt",
		 'outputColumns' => [0 .. 5]
	       },  	       
	       { 'id' => $gLOCKED_OBJECT,
		 'windowType' => $gCHILD,
		 'name' => "hlstLockedObject",
		 'parent' => "tlLockedObject",
		 'title' => "Locked rows in table varTable",
		 'columns' => \@gLockedColumns ,
		 'headers' => \@gLockedColumns,
		 'query' => "Dynamically constructed in the sub getLockedObject" ,
		 'orderBy' => 1,
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "lockedObject.txt",
		 'outputColumns' => \@gLockedColumns 
	       },  
	       { 'id' => $gSQL_TEMP_SEGS,
		 'windowType' => $gPARENT,
		 'name' => "hlstSQLTempSegs",
		 'parent' => "tlSQLTempSegs",
		 'title' => "SQL in Temp Segments",
		 'columns' => ["osuser",
			       "username",
		               "sid",
			       "serialNo", 
			       "mb_used",
			       "tablespace",
			       "sql_text",
			       "address",
			       "hash_value"
			       ],
		 'headers' => ["OS User",
			       "Username",
		               "SID",
			       "Serial \#", 
			       "MB Used",
			       "Tablespace",
			       "SQL Text" ,
			       "SQL Address",
			       "SQL Hash Value"
			       ],
		 'query' => qq{ SELECT s.osuser,
				       s.username, 
		                       s.sid,
				       s.serial\# AS serialNo,
				       t.blocks * tbs.block_size / 1024 / 1024  AS mb_used,
				       t.tablespace,
				       q.sql_text,
				       q.hash_value,
				       q.address
				FROM v\$sort_usage t,
				     v\$session s,
				     v\$sqlarea q,
				     dba_tablespaces tbs
				WHERE t.session_addr = s.saddr
				  AND t.sqladdr = q.address
				  AND t.sqlhash = q.hash_value
				  AND t.TABLESPACE = tbs.tablespace_name
				ORDER BY varOrderBy
			       },
		 'orderBy' => "osuser",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "getSQLText",
		 'outputProgram' => $gEXCEL ,
		 'outputFile' => "SQLTempSegs.xls",
		 'outputColumns' => [0 .. 8]
	       },     
	       { 'id' => $gTEMP_SEGS_HWM,
		 'windowType' => $gPARENT,
		 'name' => "hlstTempSegsHWM",
		 'parent' => "tlTempSegsHWM",
		 'title' => "Temp Segments High Water Mark",
		 'columns' => ["segs_sort",
			       "segs_hwm" 
			       ],
		 'headers' => ["MB in sort segments",
			       "MB High Water Mark"
			       ],
		 'query' => qq{SELECT SUM(u.blocks * p.VALUE) / 1024 / 1024 segs_sort,
                                     (hwm.MAX * p.value) / 1024 / 1024 segs_hwm
				 FROM v\$sort_usage u,
				      v\$parameter p,
				    (SELECT segblk\# + blocks MAX
				       FROM v\$sort_usage
				      WHERE segblk\# = (SELECT MAX(segblk\#)
							FROM v\$sort_usage)
				    ) hwm
			       WHERE p.name = 'db_block_size'
			       GROUP BY hwm.MAX *p.value / 1024 / 1024
		              },
		 'orderBy' => "segs_sort",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD ,
		 'outputFile' => "segsHighWaterMark.txt",
		 'outputColumns' => [0,1]
	       },  
	       { 'id' => $gSESS_STATS,
		 'windowType' => $gCHILD,
		 'name' => "hlstSessStats",
		 'parent' => "tlSessStats",
		 'title' => "Session Statistics",
		 'columns' => ["osuser",
			       "username",
			       "sid",
			       "stat",
			       "value"
			       ],
		 'headers' => ["OSUser",
			       "Username",
			       "SID",
			       "Statistic",
			       "Value" 
			       ],
		 'query' => qq{ SELECT c.osuser,
                                       c.username,
                                       c.sid,
                                       b.name stat,
                                       a.value
                                  FROM v\$sesstat a,
                                       v\$statname b,
                                       v\$session c
                                 WHERE a.statistic\# = b.statistic\#
                                   AND a.sid = c.sid
				   AND c.sid in (varSIDs) 
				 ORDER BY varOrderBy
			       } ,
		 'orderBy' => "sid",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gSESSIONS,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gEXCEL,
		 'outputFile' => "stats.xls",
		 'outputColumns' => [0 .. 5]
	       },        
	       { 'id' => $gSYS_ACTIVE_SQL,
		 'windowType' => $gPARENT,
		 'name' => "hlstActiveSQL",
		 'parent' => "tlActiveSQL",
		 'title' => "SQL",
		 'columns' => ["osuser",
			       "username",
			       "sid", 
			       "micro_secs_elapsed_time",
			       "sql_text",
			       "program",
			       "process",
			       "address",
			       "hash_value"
			       ],
		 'headers' => ["OSUser",
			       "Username",
			       "SID", 
			       "Elapsed Time (Micro Secs)",
			       "SQL Text",
			       "Program",
			       "Process",
			       "SQL Address",
			       "SQL Hash Value"
			       ],
		 'query' => qq{ SELECT sess.osuser,
				       sess.username,
				       sess.SID,
				       TO_CHAR(elapsed_time,'999,999,999,999') micro_secs_elapsed_time,
				       sqla.sql_text,
				       sess.program,
				       sess.process,
				       sqla.address,
				       sqla.hash_value
				FROM v\$sqlarea sqla,
				     v\$session sess 
				WHERE sqla.hash_value = sess.sql_hash_value
				 AND sqla.address = sess.sql_address 
				 AND sess.status = 'ACTIVE'
				ORDER BY varOrderBy
			       },
		 'orderBy' => "osuser",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "getSQLFullText",
		 'outputProgram' => $gSQL_DEV ,
		 'outputFile' => "SQL.sql",
		 'outputColumns' => [4]
	       },     
	       { 'id' => $gSQL,
		 'windowType' => $gCHILD,
		 'name' => "hlstSQL",
		 'parent' => "tlSQL",
		 'title' => "SQL",
		 'columns' => ["osuser",
			       "username",
			       "sid", 
			       "micro_secs_elapsed_time",
			       "sql_text",
			       "address",
			       "hash_value"
			       ],
		 'headers' => ["OSUser",
			       "Username",
			       "SID", 
			       "Elapsed Time (Micro Secs)",
			       "SQL Text",
			       "SQL Address",
			       "SQL Hash Value"
			       ],
		 'query' => qq{ SELECT sess.osuser,
				       sess.username,
				       sess.sid, 
				       TO_CHAR(elapsed_time,'999,999,999,999') micro_secs_elapsed_time,
				       sql_text,
				       address,
				       hash_value
				FROM v\$sqlarea sqla,
				     v\$session sess
				WHERE sess.sid IN (varSIDs)
				  AND sqla.address(+) = sess.sql_address
				  AND sqla.hash_value(+) = sess.sql_hash_value  
				ORDER BY varOrderBy
			       },
		 'orderBy' => "osuser",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gSESSIONS,
		 'selectMode' => "extended",
		 'command' => "getSQLFullText",
		 'outputProgram' => $gSQL_DEV ,
		 'outputFile' => "SQL.sql",
		 'outputColumns' => [4]
	       },    
	       { 'id' => $gPREV_SQL,
		 'windowType' => $gCHILD,
		 'name' => "hlstPreviousSQL",
		 'parent' => "tlPreviousSQL",
		 'title' => "SQL Previously Ran",
		 'columns' => ["osuser",
			       "username",
			       "sid",
			       "micro_secs_elapsed_time",
			       "sql_text",
			       "address",
			       "hash_value"
			       ],
		 'headers' => ["OSUser",
			       "Username",
			       "SID",
			       "Elapsed Time (Micro Secs)",
			       "SQL Text", 
			       "SQL Address",
			       "SQL Hash Value"
			       ],
		 'query' => qq{ SELECT sess.osuser,
				       sess.username,
				       sess.sid,
				       TO_CHAR(elapsed_time,'999,999,999,999') micro_secs_elapsed_time,
				       sql_text,
				       address,
				       hash_value
				FROM v\$sqlarea sqla,
					  v\$session sess
				WHERE sess.sid IN (varSIDs)
				  AND sqla.address(+) = sess.prev_sql_addr
				  AND sqla.hash_value(+) = sess.prev_hash_value  
				ORDER BY varOrderBy
			       },
		 'orderBy' => "osuser",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gSESSIONS,
		 'selectMode' => "extended",
		 'command' => "getSQLFullText",
		 'outputProgram' =>  $gSQL_DEV,
		 'outputFile' => "SQL.sql",
		 'outputColumns' => [4]
	       },      
	       { 'id' => $gSQL_TEXT,
		 'windowType' => $gCHILD,
		 'name' => "hlstSQLText",
		 'parent' => "tlSQLText",
		 'title' => "SQL Text",
		 'columns' => ["osuser",
			       "username",
			       "sid",
			       "piece",
			       "sql_text"
			       ],
		 'headers' => ["OSUser",
			       "Username",
			       "SID",
			       "Piece",
			       "SQL Text", 
			       ],
		 'query' => "Dynamically constructed",
		 'orderBy' => "piece",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gSQL,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' =>  $gSQL_DEV ,
		 'outputFile' => "SQL.sql",
		 'outputColumns' => [4]
	       },  
	       { 'id' => $gOPEN_CURSORS,
		 'windowType' => $gCHILD,
		 'name' => "hlstOpenCursors",
		 'parent' => "tlOpenCursors",
		 'title' => "View v\$open_cursor",
		 'columns' => ["osuser",
			       "username",
			       "sid",
			       "sql_text",
			       "address",
			       "hash_value"
			       ],
		 'headers' => ["OSUser",
			       "Username",
			       "SID",
			       "SQL Text",
			       "Address",
			       "Hash Value"
			       ],
		 'query' => qq{ SELECT b.osuser,
				       a.user_name,  
				       a.sid sid,
				       c.sql_text,
				       c.address,
				       c.hash_value
				FROM v\$open_cursor a,
				     v\$session b,
				     v\$sqlarea c
				WHERE  a.sid in (varSIDs)
				  AND a.sid = b.sid
				  AND a.address = c.address
				  AND a.hash_value = c.hash_value 
				ORDER BY varOrderBy
			       } ,
		 'orderBy' => "sid",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gSESSIONS,
		 'selectMode' => "extended",
		 'command' => "getSQLFullText",
		 'outputProgram' => $gSQL_DEV,
		 'outputFile' => "open_cursors.sql",
		 'outputColumns' => [3]
	       },  
	       { 'id' => $gTOP_10_SQL,
		 'windowType' => $gPARENT,
		 'name' => "hlstTop10SQL",
		 'parent' => "tlTop10SQL",
		 'title' => "Top 10 SQL",
		 'columns' => ["executions",
			       "elapsed_time",
			       "cpu_time",
			       "disk_reads",
			       "buffer_gets",
			       "sql_text",
			       "Address"
			       ],
		 'headers' => ["Executions",
			       "Elapsed Seconds",
			       "CPU Seconds",
			       "Disk Reads",
			       "Buffer Gets",
			       "SQL Text",
			       "Address"
			       ],
		 'query' => qq{ SELECT executions,
				       ROUND(elapsed_time/1000000,2) elapsed_time,
				       ROUND(cpu_time/1000000,2) cpu_time,
				       disk_reads,
				       buffer_gets,
				       sql_text,
				       address
				 FROM  (SELECT *
					  FROM v\$sql
					ORDER BY elapsed_time DESC)   
				 WHERE rownum <11

			       } ,
		 'orderBy' => "elapsed_time",
		 'sortOrder' => "DESC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gSQL_DEV,
		 'outputFile' => "top10SQL.sql",
		 'outputColumns' => [5]
	       },     
	       { 'id' => $gSESS_IO,
		 'windowType' => $gCHILD,
		 'name' => "hlstSessIO",
		 'parent' => "tlSessIO",
		 'title' => "Session IO",
		 'columns' => ["osuser",
			       "username",
			       "sid", 
			       "block_gets",
			       "consistent_gets",
			       "physical_reads",
			       "block_changes",
			       "consistent_changes" 
			       ],
		 'headers' => ["OSUser",
			       "Username",
			       "SID", 
			       "Block Gets",
			       "Consistent Gets",
			       "Physical Reads",
			       "Block Changes",
			       "Consistent Changes"  
			       ],
		 'query' => qq{ SELECT sess.osuser,
				       sess.username,
				       sess.sid,  
				       sio.block_gets,
				       sio.consistent_gets,
				       sio.physical_reads,
				       sio.block_changes,
				       sio.consistent_changes
				FROM v\$sess_io sio,
				     v\$session sess
				WHERE sess.sid IN (varSIDs)
				  AND sess.sid = sio.sid 
				ORDER BY varOrderBy
			       },
		 'orderBy' => "osuser",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gSESSIONS,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD ,
		 'outputFile' => "Sess_IO.txt",
		 'outputColumns' => [0 .. 7]
	       },            
	       { 'id' => $gJOBS,
		 'windowType' => $gPARENT,
		 'name' => "hlstJobs",
		 'parent' => "tlJobs",
		 'title' => "DBA Jobs",
		 'columns' => ["job",                      
			       "schema_user",                       
			       "priv_user",                     
			       "broken",                    
			       "failures",                          
			       "last_date", 
			       "last_sec",
			       "next_date",   
			       "next_sec",
			       "what",                         
			       "interval",                            
			       "log_user",                      
			       "this_date",     
			       "this_sec",
			       "total_time",                   
			       "nls_env",                       
			       "misc_env",                      
			       "instance" 
			      ],
		 'headers' => ["Job #",                       
			       "Executed in Schema",                     
			       "User Privileges Applied",                         
			       "Broken",                        
			       "Failures",                 
			       "Last Date",   
			       "Last Time",
			       "Next Date", 
			       "Next Time",
			       "What",                         
			       "Interval",                            
			       "Submitted By",                  
			       "This Date",   
			       "This Time",
			       "Total Time (Seconds)",                 
			       "NLS Env",                       
			       "Misc Env",                      
			       "Instance" ],
		 'query' => qq{ SELECT job,                      
				       schema_user,                       
				       priv_user,                      
				       broken,                     
				       failures,                          
				       last_date,
				       last_sec ,                       
				       next_date,
				       next_sec,                          
				       what,                        
				       interval,                            
				       log_user,                      
				       this_date,
				       this_sec,                       
				       ROUND(total_time,4) total_time,                     
				       nls_env,                        
				       misc_env,                       
				       instance
				FROM dba_jobs
				ORDER BY varOrderBy
			      },
		 'orderBy' => "job",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "confirmExecuteJob",
		 'outputProgram' => $gEXCEL,
		 'outputFile' => "jobs.xls",
		 'outputColumns' => [0 .. 14]
	       },   
	       { 'id' => $gRUNNING_JOBS,
		 'windowType' => $gPARENT,
		 'name' => "hlstRunningJobs",
		 'parent' => "tlRunningJobs",
		 'title' => "Running Jobs",
		 'columns' => ["sid",                      
			       "log_user",                       
			       "job",                    
			       "broken",                  
			       "failures",                            
			       "last_date",                     
			       "this_date",                       
			       "next_date",                        
			       "interval",                  
			       "what" 
			      ],
		 'headers' => ["SID",                       
			       "Log User",                     
			       "Job #",                         
			       "Broken",                       
			       "Failures",                  
			       "Last Date",                       
			       "This Date",                     
			       "Next Date",                       
			       "Interval",                       
			       "What"  ],
		 'query' => qq{ SELECT j.sid sid,
				       j.log_user log_user,
				       j.job job,
				       j.broken broken,
				       j.failures failures,
				       j.last_date || ':' || j.last_sec last_date,
				       j.this_date || ':' || j.this_sec this_date,
				       j.next_date || ':' || j.next_sec next_date,
				       j.next_date -j.last_date INTERVAL,
				       j.what
				  FROM
				      (SELECT djr.sid,
					 dj.log_user,
					 dj.job,
					 dj.broken,
					 dj.failures,
					 dj.last_date,
					 dj.last_sec,
					 dj.this_date,
					 dj.this_sec,
					 dj.next_date,
					 dj.next_sec,
					 dj.INTERVAL,
					 dj.what
				       FROM dba_jobs dj,
					 dba_jobs_running djr
				       WHERE dj.job = djr.job) j
				  ORDER BY varOrderBy
			      },
		 'orderBy' => "job",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gEXCEL,
		 'outputFile' => "runningJobs.xls",
		 'outputColumns' => [0 .. 8]
	       }, 
	       { 'id' => $gALERT_LOG,
		 'windowType' => $gPARENT,
		 'name' => "hlstAlertLog",
		 'parent' => "tlAlertLog",
		 'title' => "Alert Log",
		 'columns' => ["rownum",
		               "msg_line" 
			      ],
		 'headers' => ["Line #",
		               "Log Text" ],
		 'query' => qq{ SELECT rownum,
		                       msg_line
				  FROM alert_log_xtbl   
			      },
		 'orderBy' => "",
		 'sortOrder' => "",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "alert.log",
		 'outputColumns' => [1]
	       }, 
	       { 'id' => $gALERT_LOG_ERRORS,
		 'windowType' => $gPARENT,
		 'name' => "hlstAlertLogErrors",
		 'parent' => "tlAlertLogErrors",
		 'title' => "Alert Log Errors",
		 'columns' => ["lineno",
		               "msg_line",
			       "thedate",
			       "ora_error"
			      ],
		 'headers' => ["Line #",
		               "Log Text",
			       "Time Stamp",
			       "Oracle Error"],
		 'query' => qq{ SELECT lineno,
		                       msg_line,
				       thedate,
				       ora_error
				  FROM alert_log_errors   
			      },
		 'orderBy' => "lineno",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "alertLogErrors.txt",
		 'outputColumns' => [0 .. 3]
	       }, 
	       { 'id' => $gSHARED_POOL,
		 'windowType' => $gPARENT,
		 'name' => "hlstSharedPool",
		 'parent' => "tlSharedPool",
		 'title' => "Shared Pool Components",
		 'columns' => [ "name",
		                "mb"
			      ],
		 'headers' => ["Name",
		               "MB" ],
		 'query' => qq{ SELECT name,
		                       mb
		                  FROM (SELECT NAME, 
					       ROUND(BYTES/(1024*1024),3) MB
					  FROM v\$sgastat
					WHERE POOL = 'shared pool'
					ORDER BY varOrderBy) 
			       },
		 'orderBy' => "bytes",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "sharedPool.txt",
		 'outputColumns' => [0,1]
	       },
	       { 'id' => $gSHARED_POOL_RESERVED,
		 'windowType' => $gPARENT,
		 'name' => "hlstSharedPoolReserved",
		 'parent' => "tlSharedPoolReserved",
		 'title' => "Shared Pool Reserved Stats",
		 'columns' => [ "free_space",  
				"avg_free_size",  
				"free_count",  
				"max_free_size",  
				"used_space",  
				"avg_used_size",  
				"used_count",  
				"max_used_size",  
				"requests",  
				"request_misses",  
				"last_miss_size",  
				"max_miss_size",  
				"request_failures",  
				"last_failure_size",  
				"aborted_request_threshold",  
				"aborted_requests",  
				"last_aborted_size"
			      ],
		 'headers' => [ "Free Space",  
				"Avg Free Size",  
				"Free Count",  
				"Max Free Size",  
				"Used Space",  
				"Avg Used Size",  
				"Used Count",  
				"Max Used Size",  
				"Requests",  
				"Request Misses",  
				"Last Miss Size",  
				"Max Miss Size",  
				"Request Failures",  
				"Last Failure Size",  
				"Aborted Request Threshold",  
				"Aborted Requests",  
				"Last Aborted Size"],
		 'query' => qq{ SELECT TO_CHAR(free_space,'999,999,999') free_space,      
				       TO_CHAR(avg_free_size,'999,999,999') free_size,      
				       free_count,      
				       TO_CHAR(max_free_size,'999,999,999') max_free_size,      
				       TO_CHAR(used_space,'999,999,999') used_space,       
				       TO_CHAR(avg_used_size,'999,999,999') avg_used_size,     
				       used_count,      
				       TO_CHAR(max_used_size,'999,999,999') max_used_size,        
				       requests,      
				       request_misses,      
				       last_miss_size,      
				       max_miss_size ,      
				       request_failures,      
				       last_failure_size,      
				       TO_CHAR(aborted_request_threshold,'999,999,999,999') aborted_request_threshold,      
				       aborted_requests,      
				       TO_CHAR(last_aborted_size,'999,999,999,999') last_aborted_size  
				FROM v\$shared_pool_reserved
			       },
		 'orderBy' => "free_space",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "sharedPoolReserved.txt",
		 'outputColumns' => [0 .. 16]
	       },
	       { 'id' => $gUSERS,
		 'windowType' => $gPARENT,
		 'name' => "hlstUsers",
		 'parent' => "tlUsers",
		 'title' => "Database Users",
		 'columns' => [ "username",
		                "account_status",
				"last_name",
				"first_name",
				"default_tablespace",
				"temporary_tablespace",
				"profile",
				"ptime",
				"expiry_date",
				"lock_time",
				"initial_rsrc_consumer_group"
			      ],
		 'headers' => ["Oracle User",
		               "Account Status" ,
			       "Last Name",
			       "First Name",
			       "Default Tablespace",
			       "Temporary Tablespace",
			       "Resource Profile",
			       "Password Last Changed",
			       "Password Expires",
			       "Password Last Locked",
			       "Initial Consumer Group"
			       ],
		 'query' => qq{ SELECT u.username,
				       u.account_status,
				       INITCAP(r.last_name) last_name,
				       INITCAP(r.first_name) first_name,
				       default_tablespace,
				       temporary_tablespace,
				       profile,
                                       su.ptime,
				       u.expiry_date,
                                       TO_CHAR(su.ltime,'MON DD YYYY hh:miAM') lock_time,
				       initial_rsrc_consumer_group
				FROM dba_users u,
				     resources r,
                                     sys.user\$ su
				WHERE u.username=r.oracle_id_fk(+) 
				  AND u.username = su.name
				ORDER BY varOrderBy
			       },
		 'orderBy' => "username",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "getUserObjects",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "dbUsers.txt",
		 'outputColumns' => [0,1]
	       },
	       { 'id' => $gFAILED_LOGONS,
		 'windowType' => $gPARENT,
		 'name' => "hlstFailedLogons",
		 'parent' => "tlFailedLogons",
		 'title' => "Failed Logon Attempts",
		 'columns' => [ "failures",
		                "username",
				"terminal",
				"logon_time"
			      ],
		 'headers' => ["# of Failures",
		               "User Name" ,
			       "Terminal",
			       "Logon Time"],
		 'query' => qq{ SELECT COUNT(*) failures,
				       username,
				       SUBSTR(terminal,1,50) terminal,
				       TO_CHAR(timestamp, 'DD-MON-YYYY Day HH24:MI:SS') logon_time
				FROM dba_audit_session
				WHERE returncode <> 0
				  AND timestamp > sysdate -7
				GROUP BY username,
				             terminal,
				             TO_CHAR(timestamp, 'DD-MON-YYYY Day HH24:MI:SS')
				ORDER BY varOrderBy
			       },
		 'orderBy' => "username",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gEXCEL,
		 'outputFile' => "failed_logons.xls",
		 'outputColumns' => [0-3]
	       },
	       { 'id' => $gINVALID_LOGONS,
		 'windowType' => $gPARENT,
		 'name' => "hlstInvalidLogons",
		 'parent' => "tlInvalidLogons",
		 'title' => "Invalid User Logon Attempts",
		 'columns' => [ "username",
				"terminal",
				"logon_time"
			      ],
		 'headers' => ["User Name" ,
			       "Terminal",
			       "Logon Time"],
		 'query' => qq{ SELECT username,
				       SUBSTR(terminal,1,50) terminal,
				       TO_CHAR(timestamp,  'DD-MON-YYYY Day HH24:MI:SS') logon_time
				FROM dba_audit_session
				WHERE returncode <> 0
				  AND timestamp > sysdate -7
				  AND NOT EXISTS
				        (SELECT 'x'
				         FROM dba_users
				         WHERE dba_users.username = dba_audit_session.username)
				ORDER BY varOrderBy
			       },
		 'orderBy' => "username",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gEXCEL,
		 'outputFile' => "invalid_logons.xls",
		 'outputColumns' => [0-2]
	       }, 
	       { 'id' => $gUSER_PRIVS,
		 'windowType' => $gCHILD,
		 'name' => "hlstUserRoles",
		 'parent' => "tlUserRoles",
		 'title' => "Roles List",
		 'columns' => [ "userprivs"],
		 'headers' => ["Roles and System Privileges"],
		 'query' => qq{ DECLARE 
				    lv_tabs NUMBER := 0;
				    user_to_find VARCHAR2(30) :=  'varUser';
				
				    PROCEDURE write_op(pv_str IN VARCHAR2) IS
				    BEGIN
				      DBMS_OUTPUT.PUT_LINE(pv_str);
				    
				    EXCEPTION
				    WHEN others THEN
				      DBMS_OUTPUT.PUT_LINE('ERROR (write_op) => ' || SQLCODE);
				      DBMS_OUTPUT.PUT_LINE('MSG (write_op) => ' || sqlerrm);
				    
				    END write_op;
				    --
				    PROCEDURE get_privs(pv_grantee IN VARCHAR2,   lv_tabstop IN OUT NUMBER) IS
				    --
				    lv_tab VARCHAR2(50) := '';
				    lv_loop NUMBER;
				    --
				    CURSOR c_main(cp_grantee IN VARCHAR2) IS
				    SELECT 'ROLE' typ,
				      grantee grantee,
				      granted_role priv,
				      admin_option ad,
				      '--' tabnm,
				      '--' colnm,
				      '--' owner
				    FROM dba_role_privs
				    WHERE grantee = cp_grantee
				    UNION
				    SELECT 'SYSTEM' typ,
				      grantee grantee,
				      privilege priv,
				      admin_option ad,
				      '--' tabnm,
				      '--' colnm,
				      '--' owner
				    FROM dba_sys_privs
				    WHERE grantee = cp_grantee
				    ORDER BY 1;
				BEGIN
				  lv_tabstop := lv_tabstop + 1;
				  FOR lv_loop IN 1 .. lv_tabstop
				  LOOP
				    lv_tab := lv_tab || CHR(9);
				  END LOOP;
				
				  FOR lv_main IN c_main(pv_grantee)
				  LOOP
				
				    IF lv_main.typ = 'ROLE' THEN
				      write_op(lv_tab || 'ROLE => ' || lv_main.priv || ' which contains =>');
				      get_privs(lv_main.priv,   lv_tabstop);
				      ELSIF lv_main.typ = 'SYSTEM' THEN
					write_op(lv_tab || 'SYS PRIV => ' || lv_main.priv || ' grantable => ' || lv_main.ad);
				      END IF;
				
				    END LOOP;
				
				    lv_tabstop := lv_tabstop -1;
				    lv_tab := '';
				
				  EXCEPTION
				  WHEN others THEN
				    DBMS_OUTPUT.PUT_LINE('ERROR (get_privs) => ' || SQLCODE);
				    DBMS_OUTPUT.PUT_LINE('MSG (get_privs) => ' || sqlerrm);
				  END get_privs;
			      BEGIN
				write_op('User => ' || UPPER( user_to_find ) || ' has been granted the following privileges');
				write_op('====================================================================');
				get_privs(UPPER( user_to_find ),   lv_tabs);
			    
			      EXCEPTION
			      WHEN others THEN
				DBMS_OUTPUT.PUT_LINE('ERROR (main) => ' || SQLCODE);
				DBMS_OUTPUT.PUT_LINE('MSG (main) => ' || sqlerrm);
			    
			      END;
			  },
		 'orderBy' => "1",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gUSERS,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "roles.xls",
		 'outputColumns' => [0]
	       },
	       { 'id' => $gROLES,
		 'windowType' => $gPARENT,
		 'name' => "hlstRoles",
		 'parent' => "tlRoles",
		 'title' => "Roles",
		 'columns' => [ "role"],
		 'headers' => ["Role"],
		 'query' => qq{ SELECT role
				FROM dba_roles  
				ORDER BY role
			       },
		 'orderBy' => "role",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "single",
		 'command' => "getUsersGrantedRole",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "roles.txt",
		 'outputColumns' => [0]
	       }, 
	       { 'id' => $gROLE_PRIVS,
		 'windowType' => $gCHILD,
		 'name' => "hlstRolePrivs",
		 'parent' => "tlRolePrivs",
		 'title' => "Roles Privileges",
		 'columns' => [ "roleprivs"],
		 'headers' => ["Roles, System and Table Privileges"],
		 'query' => qq{ DECLARE 
				    lv_tabs NUMBER := 0;
				    user_to_find VARCHAR2(30) :=  'varUser';
				
				    PROCEDURE write_op(pv_str IN VARCHAR2) IS
				    BEGIN
				      DBMS_OUTPUT.PUT_LINE(pv_str);
				    
				    EXCEPTION
				    WHEN others THEN
				      DBMS_OUTPUT.PUT_LINE('ERROR (write_op) => ' || SQLCODE);
				      DBMS_OUTPUT.PUT_LINE('MSG (write_op) => ' || sqlerrm);
				    
				    END write_op;
				    --
				    PROCEDURE get_privs(pv_grantee IN VARCHAR2,   lv_tabstop IN OUT NUMBER) IS
				    --
				    lv_tab VARCHAR2(50) := '';
				    lv_loop NUMBER;
				    --
				    CURSOR c_main(cp_grantee IN VARCHAR2) IS
				    SELECT 'ROLE' typ,
				      grantee grantee,
				      granted_role priv,
				      admin_option ad,
				      '--' tabnm,
				      '--' colnm,
				      '--' owner
				    FROM dba_role_privs
				    WHERE grantee = cp_grantee
				    UNION
				    SELECT 'SYSTEM' typ,
				      grantee grantee,
				      privilege priv,
				      admin_option ad,
				      '--' tabnm,
				      '--' colnm,
				      '--' owner
				    FROM dba_sys_privs
				    WHERE grantee = cp_grantee 
				    UNION
				    SELECT 'TABLE' typ,
				      grantee grantee,
				      privilege priv,
				      grantable ad,
				      TABLE_NAME tabnm,
				      '--' colnm,
				      owner owner
				    FROM dba_tab_privs
				    WHERE grantee = cp_grantee
				    UNION
				    SELECT 'COLUMN' typ,
				      grantee grantee,
				      privilege priv,
				      grantable ad,
				      TABLE_NAME tabnm,
				      column_name colnm,
				      owner owner
				    FROM dba_col_privs
				    WHERE grantee = cp_grantee
				    ORDER BY 1;
				BEGIN
				  lv_tabstop := lv_tabstop + 1;
				  FOR lv_loop IN 1 .. lv_tabstop
				  LOOP
				    lv_tab := lv_tab || CHR(9);
				  END LOOP;
				
				  FOR lv_main IN c_main(pv_grantee)
				  LOOP 
				IF lv_main.typ = 'ROLE' THEN
				  write_op(lv_tab || 'ROLE => ' || lv_main.priv || ' which contains =>');
				  get_privs(lv_main.priv,   lv_tabstop);
				  ELSIF lv_main.typ = 'SYSTEM' THEN
				    write_op(lv_tab || 'SYS PRIV => ' || lv_main.priv || ' grantable => ' || lv_main.ad);
				    ELSIF lv_main.typ = 'TABLE' THEN
				      write_op(lv_tab || 'TABLE PRIV => ' || lv_main.priv || ' object => ' || lv_main.owner || '.' || lv_main.tabnm || ' grantable => ' || lv_main.ad);
				      ELSIF lv_main.typ = 'COLUMN' THEN
					write_op(lv_tab || 'COL PRIV => ' || lv_main.priv || ' object => ' || lv_main.tabnm || ' column_name => ' || lv_main.owner || '.' || lv_main.colnm || ' grantable => ' || lv_main.ad);
				      END IF;
			    
				    END LOOP;
				
				    lv_tabstop := lv_tabstop -1;
				    lv_tab := '';
				
				  EXCEPTION
				  WHEN others THEN
				    DBMS_OUTPUT.PUT_LINE('ERROR (get_privs) => ' || SQLCODE);
				    DBMS_OUTPUT.PUT_LINE('MSG (get_privs) => ' || sqlerrm);
				  END get_privs;
			      BEGIN
				write_op('User => ' || UPPER( user_to_find ) || ' has been granted the following privileges');
				write_op('====================================================================');
				get_privs(UPPER( user_to_find ),   lv_tabs);
			    
			      EXCEPTION
			      WHEN others THEN
				DBMS_OUTPUT.PUT_LINE('ERROR (main) => ' || SQLCODE);
				DBMS_OUTPUT.PUT_LINE('MSG (main) => ' || sqlerrm);
			    
			      END;
			  },
		 'orderBy' => "1",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gROLES,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "rolePrivs.xls",
		 'outputColumns' => [0]
	       },    
	       { 'id' => $gROLE_USERS,
		 'windowType' => $gPARENT,
		 'name' => "hlstRoleUsers",
		 'parent' => "tlRoleUsers",
		 'title' => "Role Users",
		 'columns' => ["grantee",
		               "default_role",
			       "admin_option" 
			       ],
		 'headers' => ["Grantee",
		               "Default Role",
			       "Admin Option" 
			       ],
		 'query' => "Dynamically constructed in the sub getUsersGrantedRole",
		 'orderBy' => "grantee",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gROLES,
		 'selectMode' => "single",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "role_users.txt",
		 'outputColumns' => [0 .. 2]
	       },  
	       { 'id' => $gSESS_TIME_MODEL,
		 'windowType' => $gCHILD,
		 'name' => "hlstSessTimeModel",
		 'parent' => "tlSessTimeModel",
		 'title' => "Session Time Model Statistics",
		 'columns' => ["osuser",
			       "username",
			       "sid",
			       "stat_id",
			       "stat_name",
			       "value"
			       ],
		 'headers' => ["OSUser",
			       "Username",
			       "SID",
			       "Statistic ID",
			       "Statistic Name",
			       "Value" 
			       ],
		 'query' => qq{ SELECT b.osuser,
                                       b.username,
                                       b.sid,
                                       a.stat_id,
                                       a.stat_name,
                                       a.value
                                  FROM v\$sess_time_model a,
                                       v\$session b
                                 WHERE a.sid = b.sid
				   AND a.sid in (varSIDs) 
				 ORDER BY varOrderBy
			       } ,
		 'orderBy' => "sid",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gSESSIONS,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gEXCEL,
		 'outputFile' => "sess_time_model_stats.xls",
		 'outputColumns' => [0 .. 5]
	       },  
	       { 'id' => $gSESS_HISTORY,
		 'windowType' => $gCHILD,
		 'name' => "hlstSessHistory",
		 'parent' => "tlSessHistory",
		 'title' => "Active Session History",
		 'columns' => ["osuser",
			       "username",
			       "sid",
			       "sample_time",
			       "session_state",
			       "wait_time",
			       "time_waited",
			       "event",
			       "sql_text"
			       ],
		 'headers' => ["OSUser",
			       "Username",
			       "SID",
			       "Sample Time",
			       "Session State",
			       "Wait Time",
			       "Time Waited",
			       "Event",
			       "SQL Text"
			       ],
		 'query' => qq{ SELECT b.osuser,
				       b.username,
				       b.sid,
				       a.sample_time,
				       a.session_state,
				       a.wait_time,
				       a.time_waited,
				       a.event,
				       c.sql_text
				FROM v\$active_session_history a,
				     v\$session b,
				     v\$sqlarea c
				WHERE a.session_id = b.sid 
				  AND a.sql_id = c.sql_id 
				  AND a.session_id in (varSIDs) 
				ORDER BY varOrderBy
			       } ,
		 'orderBy' => "sample_time",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gSESSIONS,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gSQL_DEV,
		 'outputFile' => "active_session_history.sql",
		 'outputColumns' => [8]
	       },    
	       { 'id' => $gTABLESPACES,
		 'windowType' => $gPARENT,
		 'name' => "hlstTablespaces",
		 'parent' => "tlTablespaces",
		 'title' => "Tablespaces",
		 'columns' => ["tablespace_name",
		               "block_size",
			       "initial_extent",
			       "next_extent",
			       "min_extents",
			       "max_extents",
			       "pct_increase",
			       "contents",
			       "extent_management",
			       "segment_space_management"
			       ],
		 'headers' => ["Tablespace Name",
		               "Block Size",
			       "Initial Extent",
			       "Next Extent",
			       "Min Extents",
			       "Maximum Extents",
			       "% Increase",
			       "Contents",
			       "Extent Management",
			       "Segment Space Management"
			       ],
		 'query' => qq{ SELECT tablespace_name,
                                       block_size,
                                       initial_extent,
                                       next_extent,
                                       min_extents,
                                       max_extents,
                                       pct_increase,
                                       contents,
                                       extent_management,
                                       segment_space_management
                                FROM dba_tablespaces
				ORDER BY varOrderBy
			       } ,
		 'orderBy' => "tablespace_name",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gTABLESPACES,
		 'selectMode' => "single",
		 'command' => "getTablespaceDataFiles",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "tablespaces.txt",
		 'outputColumns' => [0 .. 9]
	       },  
	       { 'id' => $gFREE_SPACE,
		 'windowType' => $gPARENT,
		 'name' => "hlstFreeSpace",
		 'parent' => "tlFreeSpace",
		 'title' => "Tablespace Free Space",
		 'columns' => ["tablespace_name",
		               "tblspc_size",
			       "mbytes_free",
			       "percent_used",
			       "largest_chunk",
			        "max_extents",
				"extent_management",
			       "object_count"
			       ],
		 'headers' => ["Tablespace Name",
		               "Size (MB)",
			       "Free Space (MB)",
			       "% Space Used",
			       "Largest Free Chunk (MB)",
			       "Maximum Extents",
			       "Extent Management",
			       "Objects in Tablespace"
			       ],
		 'query' => qq{ SELECT fs.tablespace_name,
                                       df.tblspc_size,
				       fs.mbytes_free,
  				       ROUND((1-fs.mbytes_free/df.tblspc_size)*100,2) percent_used,
				       fs.largest_chunk,
                                       dt.max_extents,
                                       dt.extent_management,
				       DECODE(dt.object_count,NULL,0,dt.object_count) object_count
				FROM (SELECT  tablespace_name, 
					      ROUND(SUM(bytes) \/ 1024 \/ 1024,   2) mbytes_free,
					      ROUND(MAX(bytes) \/ 1024 \/ 1024,   2) largest_chunk
				      FROM dba_free_space
				      GROUP BY tablespace_name ) fs,
				     (SELECT tablespace_name,
					     SUM(bytes)\/1024\/1024 tblspc_size
				      FROM sys.dba_data_files 
				      GROUP BY tablespace_name) df,
                                     (SELECT t.tablespace_name,
                                             s.object_count,
                                             max_extents,
                                             extent_management
                                      FROM dba_tablespaces t,
                                          (SELECT tablespace_name,
                                                  COUNT(*)  object_count
                                           FROM dba_segments    
                                           GROUP BY tablespace_name) s
                                     WHERE t.tablespace_name= s.tablespace_name(+)
                                     GROUP BY t.tablespace_name,
                                              s.object_count,
                                              max_extents,
                                             extent_management) dt
				WHERE fs.tablespace_name=df.tablespace_name
				  AND dt.tablespace_name = df.tablespace_name 
				ORDER BY varOrderBy
			       } ,
		 'orderBy' => "tablespace_name",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gFREE_SPACE,
		 'selectMode' => "single",
		 'command' => "getTablespaceDataFiles",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "free_space.txt",
		 'outputColumns' => [0 .. 6]
	       },  
	       { 'id' => $gDATA_FILES,
		 'windowType' => $gPARENT,
		 'name' => "hlstDataFiles",
		 'parent' => "tlDataFiles",
		 'title' => "Data Files",
		 'columns' => ["tablespace_name",
		               "file_name",
			       "file_id",
		               "bytes",
			       "maxbytes",
			       "autoextensible"
			       ],
		 'headers' => ["Tablespace Name",
		               "Filename",
			       "File ID",
		               "Size (MB)",
		               "Max Size (MB)",
			       "Auto Extensible" 
			       ],
		 'query' => "Dynamically constructed in the sub getTablespaceDataFiles",
		 'orderBy' => "file_name",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gFREE_SPACE,
		 'selectMode' => "single",
		 'command' => "getDatafileObjects",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "data_files.txt",
		 'outputColumns' => [0 .. 3]
	       },  
	       { 'id' => $gTBLSPC_OBJS,
		 'windowType' => $gPARENT,
		 'name' => "hlstTablespaceObjects",
		 'parent' => "tlTablespaceObjects",
		 'title' => "Tablespace Objects",
		 'columns' => ["owner",
		               "obj_name",
			       "segment_type",
		               "mbytes",
			       "kbytes" 
			       ],
		 'headers' => ["Owner",
		               "Object Name",
			       "Object Type",
		               "Size (MB)",
			       "Size (KB)" 
			       ],
		 'query' => "Dynamically constructed in the sub getTablespaceDataFiles",
		 'orderBy' => "obj_name",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gTBLSPC_OBJS,
		 'selectMode' => "extended",
		 'command' => "getObjectAccessPrivileges",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "tablespace_objects.txt",
		 'outputColumns' => [0 .. 3]
	       },  
	       { 'id' => $gDATAFILE_OBJS,
		 'windowType' => $gPARENT,
		 'name' => "hlstDatafileObjects",
		 'parent' => "tlDatafileObjects",
		 'title' => "Datafile Objects",
		 'columns' => ["owner",
		               "obj_name",
			       "segment_type",
			       "file_id",
			       "block_id",
		               "mbytes",
			       "kbytes" 
			       ],
		 'headers' => ["Owner",
		               "Object Name",
			       "Object Type",
			       "File ID",
			       "Block ID",
		               "Size (MB)",
			       "Size (KB)" 
			       ],
		 'query' => "Dynamically constructed in the sub getDatafileObjects",
		 'orderBy' => "obj_name",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gDATAFILE_OBJS,
		 'selectMode' => "extended",
		 'command' => "getObjectAccessPrivileges",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "datafile_objects.txt",
		 'outputColumns' => [0 .. 3]
	       },
	       { 'id' => $gUSER_OBJS,
		 'windowType' => $gPARENT,
		 'name' => "hlstUserObjects",
		 'parent' => "tlUserObjects",
		 'title' => "User Objects",
		 'columns' => ["owner",
		               "obj_name",
			       "segment_type", 
		               "mbytes",
			       "kbytes",
			       "tablespace_name"
			       ],
		 'headers' => ["Owner",
		               "Object Name",
			       "Object Type",
		               "Size (MB)",
			       "Size (KB)",
			       "Tablespace"
			       ],
		 'query' => "Dynamically constructed in the sub getUserObjects",
		 'orderBy' => "obj_name",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gUSER_OBJS,
		 'selectMode' => "extended",
		 'command' => "getObjectAccessPrivileges",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "user_objects.txt",
		 'outputColumns' => [0 .. 3]
	       },  
	       { 'id' => $gDATABASE_OBJS,
		 'windowType' => $gPARENT,
		 'name' => "hlstDatabaseObjects",
		 'parent' => "tlDatabaseObjects",
		 'title' => "Database Objects",
		 'columns' => ["owner",
		               "obj_name",
			       "segment_type",
		               "mbytes",
			       "kbytes",
			       "tablespace_name"
			       ],
		 'headers' => ["Owner",
		               "Object Name",
			       "Object Type",
		               "Size (MB)",
			       "Size (KB)" ,
			       "Tablespace"
			       ],
		 'query' => qq{SELECT SUBSTR(owner, 1, 32) owner,
	 				     SUBSTR(segment_name, 1, 32) obj_name,
					     segment_type,
					     ROUND(bytes / 1024 /1024, 2) mbytes,
					     ROUND(bytes / 1024 , 2) kbytes,
                                             tablespace_name
				FROM dba_segments 
		                ORDER BY varOrderBy
		                },
		 'orderBy' => "obj_name",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gDATABASE_OBJS,
		 'selectMode' => "extended",
		 'command' => "getObjectAccessPrivileges",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "database_objects.txt",
		 'outputColumns' => [0 .. 5]
	       },
	       { 'id' => $gOBJECT_ACCESS,
		 'windowType' => $gPARENT,
		 'name' => "hlstObjectAccess",
		 'parent' => "tlObjectAccess",
		 'title' => "Access Privileges on Objects",
		 'columns' => ["owner",
		               "table_name",
			       "grantee", 
		               "privilege",
			       "grantable" 
			       ],
		 'headers' => ["Owner",
		               "Object Name",
			       "Grantee",
		               "Privilege",
			       "Grantable" 
			       ],
		 'query' =>"Dynamically constructed in the sub getObjectAccessPrivileges",
		 'orderBy' => "grantee",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "object_privileges.txt",
		 'outputColumns' => [0 .. 4]
	       },
	       { 'id' => $gOBJECT_DEFINITION,
		 'windowType' => $gPARENT,
		 'name' => "hlstObjectDefinition",
		 'parent' => "tlObjectDefinitions",
		 'title' => "Object Definitions",
		 'columns' => ["objectdef"],
		 'headers' => ["Object Definition"],
		 'query' =>"Dynamically constructed in the sub getObjectDefinition",
		 'orderBy' => "i",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "object_definition.txt",
		 'outputColumns' => [0]
	       },
	       { 'id' => $gDBA_OBJECTS,
		 'windowType' => $gPARENT,
		 'name' => "hlstDBAObjects",
		 'parent' => "tlDBAObjects",
		 'title' => "Access Privileges on Objects",
		 'columns' => ["owner",
		               "object_name",
			       "object_id", 
		               "object_type",
			       "status",
			       "created",
			       "last_ddl_time",
			       "timestamp"
			       ],
		 'headers' => ["Owner",
		               "Object Name",
			       "Object ID",
		               "Object Type",
			       "Status",
			       "Created",
			       "Last DDL Time",
			       "Timestamp"
			       ],
		 'query' =>"Dynamically constructed in the sub getDBAObjects",
		 'orderBy' => "object_name",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gDBA_OBJECTS,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "dba_objects.txt",
		 'outputColumns' => [0 .. 7]
	       },
	       { 'id' => $gSDE_SESSIONS,
		 'windowType' => $gPARENT,
		 'name' => "hlstSDESessions",
		 'parent' => "tlSDESessions",
		 'title' => "SDE Sessions",
		 'columns' => ["owner",
		               "sid",
			       "server_id",
			       "nodename",
		               "start_time",
			       "rcount",
			       "wcount",
			       "opcount",
			       "numlocks"
			       ],
		 'headers' => ["Owner",
		               "SDE ID",
			       "OS PID",
		               "Terminal",
			       "Start Time",
			       "Reads",
			       "Writes",
			       "Operations",
			       "Locks"
			       ],
		 'query' =>"Constructed by the sub getSDESessions based upon the ArcSDE version",
		 'orderBy' => "owner",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gSDE_SESSIONS,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "SDE_sessions.txt",
		 'outputColumns' => [0 .. 8]
	       },
	       { 'id' => $gSDE_TABLES,
		 'windowType' => $gCHILD,
		 'name' => "hlstSDETables",
		 'parent' => "tlSDETables",
		 'title' => "SDE Tables",
		 'columns' => ["owner",
		               "registration_id",
			       "table_name", 
		               "sid",
			       "server_id" 
			       ],
		 'headers' => ["Owner",
		               "Registration ID",
			       "Table Name",
		               "SDE ID",
			       "OS ID" 
			       ],
		 'query' =>qq{SELECT c.owner,
			             a.registration_id,
				     a.table_name,
	 			     b.sde_id as sid,
				     c.server_id 
				FROM sde.table_registry a,
				     sde.table_locks b,
				     sde.process_information c
				WHERE a.registration_id = b.registration_id
				  AND b.sde_id = c.sde_id
				  AND b.sde_id IN (varSIDs)
		                ORDER BY varOrderBy
		                },
		 'orderBy' => "table_name",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gSDE_SESSIONS,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "SDE_Tables.txt",
		 'outputColumns' => [0 .. 4]
	       },
	       { 'id' => $gSDE_VERSION,
		 'windowType' => $gPARENT,
		 'name' => "hlstSDEVersion",
		 'parent' => "tlSDEVersion",
		 'title' => "SDE Version",
		 'columns' => ["version",
		               "bugfix",
			       "description",
			       "release",
		               "sdesvr_rel_low"
			       ],
		 'headers' => ["Version",
		               "Bug Fix",
			       "Description",
		               "Release",
			       "Lowest Server Version"
			       ],
		 'query' =>qq{SELECT major||'.'||minor version,
	 			     bugfix,
				     description,
				     release, 
				     sdesvr_rel_low
				FROM sde.version 
		                },
		 'orderBy' => "version",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gSDE_SESSIONS,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "SDE_version.txt",
		 'outputColumns' => [0 .. 4]
	       },
	       { 'id' => $gSDE_DBTUNE,
		 'windowType' => $gPARENT,
		 'name' => "hlstSDEDBTune",
		 'parent' => "tlSDEDBTune",
		 'title' => "SDE DBTune",
		 'columns' => ["keyword",
		               "parameter_name",
			       "config_string" 
			       ],
		 'headers' => ["Keyword",
		               "Parameter Name",
			       "Config string" 
			       ],
		 'query' =>qq{SELECT keyword,
	 			     parameter_name,
				     config_string 
				FROM sde.dbtune 
		                ORDER BY varOrderBy
		                },
		 'orderBy' => "keyword",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gSDE_SESSIONS,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "SDE_dbtune.txt",
		 'outputColumns' => [0 .. 2]
	       },
	       { 'id' => $gSDE_TABLE_REGISTRY,
		 'windowType' => $gPARENT,
		 'name' => "hlstSDERegistry",
		 'parent' => "tlSDERegistry",
		 'title' => "SDE Table Registry",
		 'columns' => ["registration_id",
	 		       "table_name",
			       "owner",
			       "rowid_column",
			       "description",
			       "object_flags",
			       "registration_date",
		               "config_keyword",
			       "minimum_id",
			       "imv_view_name"
			       ],
		 'headers' => ["Registration ID",
	 		       "Table Name",
			       "Owner",
			       "Rowid Column",
			       "Description",
			       "Object Flags",
			       "Registration Date",
		               "Config Keyword",
			       "Minimum_ ID",
			       "Multiversioned View"
			       ],
		 'query' =>qq{SELECT registration_id,
	 			     table_name,
				     owner,
				     rowid_column,
				     description,
				     object_flags,
				     TO_CHAR(NEW_TIME(TO_DATE('01-JAN-70'),'GMT','CDT') + registration_date / 86400.0, 'Mon DD, YYYY HH:MI:SS am') registration_date,
				     config_keyword,
				     minimum_id,
				     imv_view_name
				FROM sde.table_registry
		                ORDER BY varOrderBy
		                },
		 'orderBy' => "table_name",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "SDE_dbtune.txt",
		 'outputColumns' => [0 .. 2]
	       },
	       { 'id' => $gSDE_SERVER_CONFIG,
		 'windowType' => $gPARENT,
		 'name' => "hlstSDEServerConfig",
		 'parent' => "tlSDEServerConfig",
		 'title' => "SDE Server Config",
		 'columns' => ["prop_name",
		               "char_prop_value",
			       "num_prop_value" 
			       ],
		 'headers' => ["Parameter Name",
		               "Character Value",
			       "Number Value" 
			       ],
		 'query' =>qq{SELECT prop_name,
	 			     char_prop_value,
				     num_prop_value 
				FROM sde.server_config
		                ORDER BY varOrderBy
		                },
		 'orderBy' => "prop_name",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "SDE_server_config.txt",
		 'outputColumns' => [0 .. 2]
	       },
	       { 'id' => $gDB_PARAMETERS,
		 'windowType' => $gPARENT,
		 'name' => "hlstDBParameters",
		 'parent' => "tlDBParameters",
		 'title' => "DB Paramters",
		 'columns' => ["name",
		               "value",
			       "description",
			       "isdefault",
			       "isses_modifiable",
			       "issys_modifiable",
			       "ismodified",
			       "isadjusted"
			       ],
		 'headers' => ["Parameter Name",
		               "Parameter Value",
			       "Description",
			       "Default Value",
			       "Session Modifiable",
			       "System Modifiable",
			       "Modified Since Startup", 
			       "Adjusted by Oracle"
			       ],
		 'query' =>qq{SELECT name,
	 			     value,
				     description,
				     isdefault,
				     isses_modifiable,
				     issys_modifiable,
				     ismodified,
				     isadjusted
				FROM v\$parameter
		                ORDER BY varOrderBy
		                },
		 'orderBy' => "name",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "db_parameters.",
		 'outputColumns' => [0 .. 7]
	       },
	       { 'id' => $gDB_HIDDEN_PARAMS,
		 'windowType' => $gPARENT,
		 'name' => "hlstDBHiddenParams",
		 'parent' => "tlDBHiddenParams",
		 'title' => "DB Paramters",
		 'columns' => ["name",
		               "value",
			       "description",
			       "isdefault",
			       "isses_modifiable",
			       "issys_modifiable",
			       "ismodified",
			       "isadjusted"
			       ],
		 'headers' => ["Parameter Name",
		               "Parameter Value",
			       "Description",
			       "Default Value",
			       "Session Modifiable",
			       "System Modifiable",
			       "Modified Since Startup", 
			       "Adjusted by Oracle"
			       ],
		 'query' =>qq{SELECT name,
				     value,
				     description,
				     isdefault, 
				     isses_modifiable,
				     issys_modifiable,
				     ismodified,
				     isadjusted 
		               FROM(SELECT x.inst_id AS instance,  
					    x.indx + 1,   
					    ksppinm AS name,   
					    ksppity,   
					    ksppstvl AS VALUE,   
					    ksppstdf AS isdefault,   
					    DECODE(BITAND(ksppiflg / 256,   1),    1,   'TRUE',   'FALSE') AS isses_modifiable,   
					    DECODE(BITAND(ksppiflg / 65536,   3),   1,   'IMMEDIATE',   2,   'DEFERRED',   'FALSE') AS  issys_modifiable,   
					    DECODE(BITAND(ksppstvf,   7),   1,   'MODIFIED',   'FALSE') AS ismodified,   
					    DECODE(BITAND(ksppstvf,   2),   2,   'TRUE',   'FALSE') AS isadjusted,  
					    ksppdesc AS description
				      FROM x\$ksppi x,   x\$ksppsv y
				      WHERE x.indx = y.indx
					AND SUBSTR(ksppinm,   1,   1) = '_'
					AND x.inst_id = USERENV('Instance')) 
		                ORDER BY varOrderBy
		                },
		 'orderBy' => "name",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "db_hidden_params.txt",
		 'outputColumns' => [0 .. 7]
	       },
	       { 'id' => $gDB_OBJECT_CACHE,
		 'windowType' => $gPARENT,
		 'name' => "hlstDBObjectCache",
		 'parent' => "tlDBObjectCache",
		 'title' => "DB Objects in Library Cache",
		 'columns' => ["owner",
		               "name",
			       "db_link",
			       "type",
			       "sharable_mem",
			       "loads",
			       "executions",
			       "locks",
			       "pins"
			       ],
		 'headers' => ["Owner",
		               "Name",
			       "Database Link",
			       "Type",
			       "Sharable Memory",
			       "Loads",
			       "Executions",
			       "Locks", 
			       "Pins"
			       ],
		 'query' =>"Constructed by the sub getCachedObject",
		 'orderBy' => "name",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "cached_objects.txt",
		 'outputColumns' => [0 .. 8]
	       },
	       { 'id' => $gLIBRARY_CACHE,
		 'windowType' => $gPARENT,
		 'name' => "hlstLibraryCache",
		 'parent' => "tlLibraryCache",
		 'title' => "Library Cache Statistics",
		 'columns' => ["namespace",
		               "gets",
			       "gethits",
			       "gethitratio",
			       "pins",
			       "pinhits",
			       "pinhitratio",
			       "reloads",
			        "reloads_percent",
			       "invalidations"
			       ],
		 'headers' => ["Namespace",
		               "Gets",
			       "Get Hits",
			       "Get Hits Ratio",
			       "Pins",
			       "Pin Hits",
			       "Pin Hits Ratio",
			       "Reloads", 
			       "Reloads Percent",
			       "Invalidations"
			       ],
		 'query' =>qq{SELECT namespace,
                                     TO_CHAR(gets, '999,999,999,999') gets,
                                     TO_CHAR(gethits, '999,999,999,999') gethits,
                                     ROUND(gethitratio,4) gethitratio,
                                     TO_CHAR(pins, '999,999,999,999') pins,
                                     TO_CHAR(pinhits, '999,999,999,999') pinhits,
                                     ROUND(pinhitratio,4) pinhitratio,
                                     TO_CHAR(reloads, '999,999,999,999') reloads, 
                                     CASE  
                                        WHEN reloads > 0
                                          THEN LPAD(ROUND((reloads/pins),4)*100||'%' ,7)
                                        ELSE
                                          LPAD('0%',7)
                                     END reloads_percent,
                                     TO_CHAR(invalidations, '999,999,999,999') invalidations
                                     FROM v\$librarycache
		                ORDER BY varOrderBy
		                },
		 'orderBy' => "namespace",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "db_library_cache.txt",
		 'outputColumns' => [0 .. 8]
	       },
	       { 'id' => $gSGA,
		 'windowType' => $gPARENT,
		 'name' => "hlstSGA",
		 'parent' => "tlSGA",
		 'title' => "SGA ",
		 'columns' => ["name",
		               "value",
			       "MB" 
			       ],
		 'headers' => ["Name",
		               "Size (MB)",
			       "Size (Bytes)"
			       ],
		 'query' =>"Constructed by the sub getSGAInfo",
		 'orderBy' => "name",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "SGA.txt",
		 'outputColumns' => [0 .. 2]
	       },
	       { 'id' => $gDB_LINKS,
		 'windowType' => $gPARENT,
		 'name' => "hlstDBLinks",
		 'parent' => "tlDBLinks",
		 'title' => "Database Links ",
		 'columns' => ["owner",
		               "db_link",
			       "username",
			       "host",
			       "created"
			       ],
		 'headers' => ["Owner",
		               "Database Link",
			       "Username",
			       "Host",
			       "Date Created"
			       ],
		 'query' =>qq{SELECT owner,
	 			     db_link,
				     username,
				     host,
				     created
				FROM dba_db_links
		                ORDER BY varOrderBy
		                },
		 'orderBy' => "owner",
		 'sortOrder' => "ASC",
		 'selectionSource' => undef,
		 'selectMode' => "extended",
		 'command' => "getObjectDefinition",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "DBLinks.txt",
		 'outputColumns' => [0 .. 4]
	       },    
	       { 'id' => $gUSER_SCRIPT,
		 'windowType' => $gPARENT,
		 'name' => "hlstUserScript",
		 'parent' => "tlUserScript",
		 'title' => "Create User Script",
		 'columns' => ["user_text"],
		 'headers' => ["User Text"],
		 'query' => "Dynamically constructed in the sub getUsersGrantedRole",
		 'orderBy' => "user_text",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gUSERS,
		 'selectMode' => "single",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "createUser.txt",
		 'outputColumns' => [0]
	       },    
	       { 'id' => $gUSER_TABLE_PRIVS,
		 'windowType' => $gPARENT,
		 'name' => "hlstUserTablePrivs",
		 'parent' => "tlUserTablePrivs",
		 'title' => "Create User Table Privs Script",
		 'columns' => ["user_text"],
		 'headers' => ["User Text"],
		 'query' => "Dynamically constructed in the sub getUsersGrantedRole",
		 'orderBy' => "user_text",
		 'sortOrder' => "ASC",
		 'selectionSource' => $gUSERS,
		 'selectMode' => "single",
		 'command' => "sendToEditor",
		 'outputProgram' => $gNOTEPAD,
		 'outputFile' => "userTablePrivs.txt",
		 'outputColumns' => [0]
	       },
	       { 'id' => $gTEMP_SEGS_USAGE,
			 'windowType' => $gPARENT,
			 'name' => "hlstTempSegsUsage",
			 'parent' => "tlTempSegsUsage",
			 'title' => "Temporary Segments Usage",
			 'columns' => [ "segment_file",
					"tablespace_name",
					"free_blocks",
					"free_extents",
					"used_blocks",
					"used_extents",
					"total_blocks",
					"total_extents",
					"current_users",
					"inst_id",
					"relative_fno",
					"max_sort_blocks",
					"max_sort_size",
					"max_used_blocks",
					"max_used_size",
					"max_blocks",
					"max_size",
					"free_requests",
					"freed_extents",
					"extent_hits",
					"added_extents",
					"extent_size",
					"segment_block"
					   ],
			 'headers' => [ "segment_file",
					"tablespace_name",
					"free_blocks",
					"free_extents",
					"used_blocks",
					"used_extents",
					"total_blocks",
					"total_extents",
					"current_users",
					"inst_id",
					"relative_fno",
					"max_sort_blocks",
					"max_sort_size",
					"max_used_blocks",
					"max_used_size",
					"max_blocks",
					"max_size",
					"free_requests",
					"freed_extents",
					"extent_hits",
					"added_extents",
					"extent_size",
					"segment_block"
					   ],
			 'query' => qq{ SELECT segment_file,
						   tablespace_name,
						   free_blocks,
						   free_extents,
						   used_blocks,
						   used_extents,
						   total_blocks,
						   total_extents,
						   current_users,
						   inst_id,
						   relative_fno,
						   max_sort_blocks,
						   max_sort_size,
						   max_used_blocks,
						   max_used_size,
						   max_blocks,
						   max_size,
						   free_requests,
						   freed_extents,
						   extent_hits,
						   added_extents,
						   extent_size,
						   segment_block
					FROM gv\$sort_segment 
					ORDER BY varOrderBy
					   },
			 'orderBy' => "tablespace_name",
			 'sortOrder' => "ASC",
			 'selectionSource' => undef,
			 'selectMode' => "extended",
			 'command' => "getSQLText",
			 'outputProgram' => $gEXCEL ,
			 'outputFile' => "SQLTempSegs.xls",
			 'outputColumns' => [0 .. 22]
	       },      
	       { 'id' => $gSQL_FULL_TEXT,
			 'windowType' => $gCHILD,
			 'name' => "hlstSQLFullText",
			 'parent' => "tlSQLFullText",
			 'title' => "SQL Full Text",
			 'columns' => ["osuser",
					   "username",
					   "sid", 
					   "sql_fulltext"
					   ],
			 'headers' => ["OSUser",
					   "Username",
					   "SID", 
					   "SQL Text", 
					   ],
			 'query' => "Dynamically constructed",
			 'orderBy' => "username",
			 'sortOrder' => "ASC",
			 'selectionSource' => $gSQL,
			 'selectMode' => "extended",
			 'command' => "sendToEditor",
			 'outputProgram' =>  $gSQL_DEV ,
			 'outputFile' => "SQL.sql",
			 'outputColumns' => [3]
	       },      
	       { 'id' => $gSESS_OBJECT,
			 'windowType' => $gCHILD,
			 'name' => "hlstSessionObjects",
			 'parent' => "tlSessionObjects",
			 'title' => "Session Object",
			 'columns' => ["object_name",
					   "row_wait_obj",
					   "row_wait_file", 
					   "row_wait_block",
					   "row_wait_row", 
					   "row_id"
					   ],
			 'headers' => ["Object Name",
					   "ROW_WAIT_OBJ#",
					   "ROW_WAIT_FILE#", 
					   "ROW_WAIT_BLOCK#", , 
					   "ROW_WAIT_ROW#", 
					   "ROWID"
					   ],
			 'query' => "Dynamically constructed",
			 'orderBy' => "object_name",
			 'sortOrder' => "ASC",
			 'selectionSource' => $gSESSIONS,
			 'selectMode' => "extended",
			 'command' => "sendToEditor",
			 'outputProgram' =>  $gNOTEPAD ,
			 'outputFile' => "sessionObjects.txt",
			 'outputColumns' => [0 .. 5]
	       },
	       { 'id' => $gTBLSPC_USER_USAGE,
			 'windowType' => $gPARENT,
			 'name' => "hlstTablespaceUsersUsage",
			 'parent' => "tlTablespaceUsersUsage",
			 'title' => "Tablespace Users Usage",
			 'columns' => ["tablespace_name",
						   "owner", 
					   "mbytes",
					   "num_objs"
					   ],
			 'headers' => ["Tablespace",
						   "Owner",
						   "Usage (MB)",
					   "Objects"
					   ],
			 'query' => "Dynamically constructed",
			 'orderBy' => "owner",
			 'sortOrder' => "ASC",
			 'selectionSource' => $gTBLSPC_USER_USAGE,
			 'selectMode' => "extended",
			 'command' => "getUserObjects",
			 'outputProgram' => $gNOTEPAD,
			 'outputFile' => "TablespaceUsersUsage.txt",
			 'outputColumns' => [0,1]
	       },
	       { 'id' => $gLAYERS,
			 'windowType' => $gPARENT,
			 'name' => "hlstLayers",
			 'parent' => "tlLayers",
			 'title' => "SDE Layers",
			 'columns' => [ "layer_id",
							"owner",
					"table_name",
					"spatial_column",
					"eflags",
					"gsize1",
					"gsize2",
					"gsize3",
					"minx",
					"miny",
					"maxx",
					"maxy",
					"layer_config"
					  ],
			 'headers' => ["Layer ID",
						   "Owner" ,
					   "Table Name",
					   "Spatial Column",
					   "EFlags",
					   "Size of 1st Spatial Grid",
					   "Size of 2nd Spatial Grid",
					   "Size of 3rd Spatial Grid",
					   "Min X",
					   "Min Y",
					   "Max X",
					   "Max Y",
					   "Layer Config"
					   ],
			 'query' => qq{ SELECT  layer_id ,
						 owner ,
						 table_name ,
						 spatial_column ,
						 eflags ,
						 gsize1 ,
						 gsize2 ,
						 gsize3 ,
						 minx ,
						 miny ,
						 maxx ,
						 maxy ,
						 layer_config 
					FROM sde.layers 
					ORDER BY varOrderBy
					   },
			 'orderBy' => "table_name",
			 'sortOrder' => "ASC",
			 'selectionSource' => undef,
			 'selectMode' => "extended",
			 'command' => "sendToEditor",
			 'outputProgram' => $gNOTEPAD,
			 'outputFile' => "sde_layers.txt",
			 'outputColumns' => [0 .. 12]
	       },
	       { 'id' => $gDISPLAY_TABLE,
			 'windowType' => $gPARENT,
			 'name' => "hlstDisplayTable",
			 'parent' => "tlDisplayTable",
			 'title' => "Display Table",
			 'columns' => [],
			 'headers' => [],
			 'query' => "Dynamically constructed",
			 'orderBy' => "1",
			 'sortOrder' => "ASC",
			 'selectionSource' => undef,
			 'selectMode' => "extended",
			 'command' => "sendToEditor",
			 'outputProgram' => $gNOTEPAD,
			 'outputFile' => "display_table.txt",
			 'outputColumns' => [0 .. 1]
	       },
	       { 'id' => $gTABLE_COLUMNS,
			 'windowType' => $gPARENT,
			 'name' => "hlstTableColumns",
			 'parent' => "tlTableColumns",
			 'title' => "Table Columns",
			 'columns' => [ "owner",
							"table_name",
							"column_name" ,
							"data_type",
							"data_length",
							"data_precision_scale" ,
							"internal_column_id"
					      ],
			 'headers' => [ "Owner",
							"Table Name",
							"Column Name",
							"Data Type",
							"Data Length",
							"Data Precision,Scale", 
						   "Internal Column ID" 
			          ],
			 'query' => qq{ SELECT RPAD(owner,40),
							   RPAD(table_name,40),
						   RPAD(column_name,40),
						   data_type,
						   data_length,
						   DECODE(data_precision,NULL,\' \',\'(\'||data_precision||\',\'||data_scale||\')\') data_precision_scale, 
						   internal_column_id
					FROM dba_tab_cols 
					WHERE varWhereClause
					ORDER BY varOrderBy
			       },
			 'orderBy' => "internal_column_id",
			 'sortOrder' => "ASC",
			 'selectionSource' => $gTABLE_COLUMNS,
			 'selectMode' => "extended",
			 'command' => "sendToEditor",
			 'outputProgram' => $gNOTEPAD,
			 'outputFile' => "table_columns.txt",
			 'outputColumns' => [0 .. 6]
			},
	        { 'id' => $gDBA_REGISTRY,
			 'windowType' => $gPARENT,
			 'name' => "hlstDBARegistry",
			 'parent' => "tlDBARegistry",
			 'title' => "DBA Registry",
			 'columns' => [ "comp_id",
							"comp_name",
						    "version",
						    "status",
						    "modified",
						    "namespace", 
						    "control",
							"schema",
							"procedure",
							"startup",
							"parent_id",
							"other_schemas"
					      ],
			 'headers' => [  "Component ID",
							"Component Name",
						    "Version",
						    "Status",
						    "Date Modified",
						    "Namespace", 
						    "Control",
							"Schema",
							"Validation Procedure",
							"Startup",
							"Parent ID",
							"Other Schemas"
			          ],
			 'query' => qq{ SELECT comp_id,
							comp_name,
						    version,
						    status,
						    modified,
						    namespace, 
						    control,
							schema,
							procedure,
							startup,
							parent_id,
							other_schemas 
					FROM dba_registry 
					ORDER BY varOrderBy
			       },
			 'orderBy' => "comp_name",
			 'sortOrder' => "ASC",
			 'selectionSource' => $gDBA_REGISTRY,
			 'selectMode' => "extended",
			 'command' => "sendToEditor",
			 'outputProgram' => $gNOTEPAD,
			 'outputFile' => "table_columns.txt",
			 'outputColumns' => [0 .. 11]
			}
	   );
	   
	   
#-----------------------------------------------------------------------------  
#                  End of HList widgets' data structures.  
#-----------------------------------------------------------------------------	 



#/////////////////////////////////////////////////////////////////////////////


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ 	  
#             Build the main window display and login
# Create the main window
$winMain = MainWindow->new;
$winMain->title("User Sessions"); 

$blue = $winMain->ItemStyle('text', -foreground => 'blue', 
                            -selectforeground => 'white', -font => "Courier 8");

# Create the login dialog box
buildLoginDialogBox();

#  Create the HList widget that displays the
# user sessions for the selected database. 
buildHList($gSESSIONS);
#$lblSessions = $winMain->Label(-textvariable=> \$gTotalSessions,
#			       -font => '-adobe-helvetica-bold-r-narrow--12-120'
#			      )->pack(-side => 'left',
#				      -pady => 10,
#				      -padx => 5
#				      ); 
				      
# Build a menu of all the Oracle databases 
# that are available through tnsnmames.ora
buildMainMenus();

#  Prompt the user to login. The database that 
# the user logs on to must hold the password
# repository
login();

# Display the user sessions for the database
# the user logged in to.
displayWindow($gSESSIONS);
#displaySessions();

# Set the main window's title to reflect the
# database it's connected to
#$winMain->title("User Sessions on $gdbSessions"); 
MainLoop();

#/////////////////////////////////////////////////////////////////////////////


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

#_____________________________________________________________________________
#                                   Widgets
#_____________________________________________________________________________

#--------------------------------------------------------
#                   buildLoginDialogBox
# Creates the dialog box for logging into the database. It
# consists of username, password and database fields.
#--------------------------------------------------------
sub buildLoginDialogBox
{
   $dlgLogin = $winMain->DialogBox(-title => 'Login', 
			           -buttons => ['Ok', 'Cancel'], 
			           -default_button => 'Ok'
				  );
   # Create a variable to reference the username field later on
   # when setting the focus.
   my $user = $dlgLogin->add('LabEntry', 
			     -textvariable => \$gUserName, 
			     -width => 20, 
			     -label => 'Username', 
			     -labelPack => [-side => 'left']
			    )->pack;
   			    
   $dlgLogin->add('LabEntry', 
		   -textvariable => \$pwd, 
		   -width => 20, 
		   -label => 'Password',
		   -show => '*', 
		   -labelPack => [-side => 'left'] 
		 )->pack;
   $dlgLogin->add('LabEntry', 
		   -textvariable => \$db, 
		   -width => 20, 
		   -label => 'Database', 
		   -labelPack => [-side => 'left']
		 )->pack;
		 
  #  Set the current focus to the username entry field so the user
  # can begin typing without having to navigate to the field with 
  # the mouse
  $user->focus;
}

#--------------------------------------------------------
#                  buildHList
# Builds the HList widget that displays the designated
# data
#--------------------------------------------------------
sub buildHList
{
  my ($HListID) = @_;
  my $HListParent = $gHLists[$HListID]{'parent'} ;
  
  my $HListName=  $gHLists[$HListID]{'name'}; 
  my $maxColumnIndex = $#{$gHLists[$HListID]{'columns'}};
  my $selectMode = $gHLists[$HListID]{'selectMode'};
 
  ${$HListName} = ${$HListParent}->Scrolled("HList",
				     -header => 1,                   
				     -columns => $maxColumnIndex+1,          
				     -scrollbars => 'osoe',                  
				     -width => 100,           
				     -height => 20,
				     -selectmode => $selectMode,
				     -selectbackground => 'SeaGreen3',
				     -font => '-adobe-helvetica-bold-r-narrow--12-120', 
				     -command => [\&{$gHLists[$HListID]{'command'}},$HListID]  #\&{$gHLists[$HListID]{'command'}} #
				    )->pack(-expand => 1, 
					    -fill => 'both',
					    -padx => 10,
					    -pady => 10
					   );
					   
  # Build clickable buttons for the column headers. Whenever the user clicks
  # on the header the data is re-sorted by the field associated with
  # the header.	
  foreach my $column ( 0 .. $maxColumnIndex) 
  {   
      #Create the button widget for the header
      my $btnHeader = ${$HListName}->Button(-anchor     => 'center',
					-text       => "$gHLists[$HListID]{'headers'}[$column]",
					-background => 'LightGrey',
					-command => sub { &sortData($HListID, $column)} #[\&sortData,$HListID,$column] # 
					); 
     #Create the header using the button widget                                   
     ${$HListName}->headerCreate( $column,
			      -itemtype  => 'window',
			      -borderwidth => -2, 
			      -widget => $btnHeader
			     );    
  }
  
  # Add the label that displays the total number of rows selected
  my $lblRows =  ${$HListParent}->Label(-textvariable=> \$gTotalRows[$HListID],
			                 -font => '-adobe-helvetica-bold-r-narrow--12-120'
			                 )->pack(-side => 'left',
				                 -pady => 10,
				                 -padx => 5
				                 ); 
						 
  #****************************************************************************
  # Add the buttons and menus that are displayed on all the HLists
  #
  # Create a button to refresh the display
  my $btnRefresh = ${$HListParent}->Button(-text => 'Refresh',
					   -font => '-adobe-helvetica-bold-r-narrow--12-120',
					   -command => sub { &refreshDisplay($HListID)}
				           )->pack(-side => 'right',
					           -pady => 10,
					           -padx => 10
					           );  
 # Create a button to send the selected text to an editor
  my $btnEdit = ${$HListParent}->Button(-text => 'Edit',
					-font => '-adobe-helvetica-bold-r-narrow--12-120',
					-command => sub { &sendToEditor($HListID)}
				       )->pack(-side => 'right',
					       -pady => 10,
					       -padx => 10
					      );
  # Create a button to select all the rows in the HList
  my $btnSelectAll = ${$HListParent}->Button(-text => 'Select All',
					   -font => '-adobe-helvetica-bold-r-narrow--12-120',
					   -command => sub { &selectAll($HListID)}
				           )->pack(-side => 'right',
					           -pady => 10,
					           -padx => 10
					           );   
   # Create a button to envoke SQL*Plus
    my $btnShowSQL = ${$HListParent}->Button(-text => 'Show SQL',
					      -font => '-adobe-helvetica-bold-r-narrow--12-120',
					      -foreground => 'darkblue',
					      -command => sub { &showSQL($HListID)}
					     )->pack(-side => 'left',
						     -pady => 10,
						     -padx => 10
						    );  
						   
 
   #****************************************************************************
   # Add any buttons and menus that are specific to just certain HLists
   # Change the select mode if necessary for certain HLists.
   
   #.........................................................
   switch ($HListID)
   {
          case "$gSESSIONS"  
	  {
	        # Create a button to kill the selected users' sessions
		my $btnLock = ${$HListParent}->Button(-text => 'Kill Session',
						      -font => '-adobe-helvetica-bold-r-narrow--12-120',
						      -foreground => 'red',
						      -command => sub { &confirmKillSessions}
						     )->pack(-side => 'left',
							     -pady => 10,
							     -padx => 50
							    );  
	    
		# Create a button to envoke SQL*Plus
		my $btnSQLPlus = ${$HListParent}->Button(-text => 'SQL*Plus',
						      -font => '-adobe-helvetica-bold-r-narrow--12-120',
						      -foreground => 'forestgreen',
						      -command => sub { &SQLPlus}
						     )->pack(-side => 'left',
							     -pady => 10,
							     -padx => 10
							    );  
		
	  }
	  
	  case "$gUSERS"  
	  {
	    buildUserListMenu($HListParent);   
	  }
	  
	  case "$gROLES"
	  {  					    
	    buildRolesMenu($HListParent);  
	  }
	  
	  case [ $gTABLESPACES,$gFREE_SPACE  ]
          {  	
	    buildTablespaceMenu($HListID);    
            ${$HListName}->configure(-selectmode=>'single');
          }
	  
	  case [ $gTBLSPC_OBJS,$gDATAFILE_OBJS,$gUSER_OBJS,$gDATABASE_OBJS,$gDBA_OBJECTS ]
          {  	
	    buildObjectsMenu($HListID);
            #${$HListName}->configure(-selectmode=>'single');
          }
	  
	  case "$gSDE_SESSIONS"
          {  					    
	    buildSDESessionsMenu($HListID);    
          }
	   
	  case "$gDB_LINKS"
          {  					    
	    buildDBLinksMenu($HListID);    
          }
	  
	  case "$gTABLE_COLUMNS"  
	  {
	        # Create a button to kill the selected users' sessions
		my $btnLock = ${$HListParent}->Button(-text => 'Display Table',
						      -font => '-adobe-helvetica-bold-r-narrow--12-120',
						      -foreground => 'forestgreen',
						      -command => sub {&displaySelectedTable($gTABLE_COLUMNS)}
						     )->pack(-side => 'left',
							     -pady => 10,
							     -padx => 50
							    );  
	  }					    
   }
   
 
}
######_________________________________________________________________________
######_________________________________ Menus _________________________________
######_________________________________________________________________________
#--------------------------------------------------------
#                   buildMainMenus
#   
#--------------------------------------------------------
sub buildMainMenus
{
    # Add the menu bar that the dropdown menus are attached to
    $winMain->configure(-menu => $mnuBar = $winMain->Menu);
    #Build the dropdown menus
    buildDatabaseMenu();
    buildUtilitiesMenu();
    buildSQLMenu();
    buildMemoryMenu();
    buildSDEMenu();
}

#--------------------------------------------------------
#                   buildDatabaseMenu
#  Creates a menu dropdown of all the datasources the Oracle
# driver has access to.
#--------------------------------------------------------
sub buildDatabaseMenu
{
  my @oracleDBs =();	

  #  Get a list of all the datasources available to
  # the Oracle driver and build a list of just the
  # datasource names, i.e. remove "dbi:Oracle:" from 
  # the front end of each datasource
  my @DBs = DBI->data_sources( 'Oracle' );
  foreach my $DB ( @DBs ) 
  {
     my  @db = split(/\:/,$DB);
     push(@oracleDBs,$db[2]);
  } 
  
  # Build the dropdown menu and add all the datasource
  # names to it
  my $mnuDatabase = $mnuBar->cascade(-label => '~Databases'); 
  
  foreach my $database (@oracleDBs)
  {
    $mnuDatabase->command(-label => $database, 
                          -command => sub { &connectToDB($database)});			
  }
  
}

#--------------------------------------------------------
#                   buildMemoryMenu
#   
#  
#--------------------------------------------------------
sub buildMemoryMenu
{
   # Create the MEMORY cascade menu
  $mnuMemory = $mnuBar->cascade(-label => 'Memory'); 
  $mnuMemory->command(-label => "SGA Info", 
                   -command => sub { &getSGAInfo($gSGA)});
		   
  $mnuSharedPool = $mnuMemory->cascade(-label => 'Shared Pool');
  $mnuSharedPool->command(-label => "Components Usage", 
                          -command => sub { &displayWindow($gSHARED_POOL); print "I can do more\n";});
  $mnuSharedPool->command(-label => "Chart", 
                          -command => sub { &displaySharedPoolChart;});
  $mnuSharedPool->command(-label => "Reserved Pool Stats", 
                          -command => sub { &displayWindow($gSHARED_POOL_RESERVED)});
		   
  $mnuLibraryCache = $mnuMemory->cascade(-label => 'Library Cache');		   
  $mnuLibraryCache->command(-label => "Packages Procedures Functions", 
                            -command => sub { &getCachedObjects('PACKAGE','PACKAGE BODY','FUNCTION','PROCEDURE')});   
  $mnuLibraryCache->command(-label => "Cursors", 
                            -command => sub { &getCachedObjects('CURSOR')});  
  $mnuLibraryCache->command(-label => "Statistics", 
                            -command => sub { &displayWindow($gLIBRARY_CACHE)});
  		    
			    
}

#--------------------------------------------------------
#                   buildSQLMenu
#   
#  
#--------------------------------------------------------
sub buildSQLMenu
{
   # Create the SQL cascade menu
  $mnuSQL = $mnuBar->cascade(-label => 'SQL'); 
  $mnuSQL->command(-label => "Active SQL", 
                   -command => sub { &displayWindow($gSYS_ACTIVE_SQL)});
  $mnuSQL->command(-label => "Session's Current SQL", 
                   -command => sub { &displayWindow($gSQL)});
  $mnuSQL->command(-label => "Session's Previous SQL", 
                   -command => sub { &displayWindow($gPREV_SQL)});
  $mnuSQL->command(-label => "Session's SQL in v\$open_cursor", 
                   -command => sub { &displayWindow($gOPEN_CURSORS)});  
  $mnuSQL->command(-label => "Sql History (ASH)", 
                     -command => sub { &displayWindow($gSESS_HISTORY)}); 
  $mnuSQL->command(-label => "Top 10 SQL", 
                   -command => sub { &displayWindow($gTOP_10_SQL)});
  $mnuSQL->command(-label => "v\$session_longops", 
                     -command => sub { &displayWindow($gSESS_LONGOPS)});  
}

#--------------------------------------------------------
#                   buildUtilitiesMenu
#   
#  
#--------------------------------------------------------
sub buildUtilitiesMenu
{
  $mnuUtils = $mnuBar->cascade(-label => '~Utilities'); 
  
  # Create the Tablespace cascade menu
  $mnuTablespaces = $mnuUtils->cascade(-label => 'Tablespaces'); 
  $mnuTablespaces->command(-label => "Dba_Tablespaces", 
                     -command => sub {&displayWindow($gTABLESPACES)});
  $mnuTablespaces->command(-label => "Usage", 
                     -command => sub { &showHourGlass($gSESSIONS);
		                      &displayWindow($gFREE_SPACE);
		                      &removeHourGlass($gSESSIONS)});  
 
  #$mnuUtils->command(-label => "Database Objects", 
  #                   -command => sub {&showHourGlass($gSESSIONS);
  #	                      &displayWindow($gDATABASE_OBJS);
  #	                      &removeHourGlass($gSESSIONS)});  

    $mnuDBObjects = $mnuUtils->cascade(-label => 'Database Objects'); 
    $mnuDBObjects ->command(-label => "All Objects", 
                           -command => sub { &getDBAObjects($gDATABASE_OBJS)});     
    $mnuDBObjects ->command(-label => "Tables", 
                           -command => sub { &getDBAObjects($gDATABASE_OBJS,'TABLE')});  
    $mnuDBObjects ->command(-label => "Views", 
                           -command => sub { &getDBAObjects($gDATABASE_OBJS,'VIEW')});   
    $mnuDBObjects ->command(-label => "Materialized Views", 
                           -command => sub { &getDBAObjects($gDATABASE_OBJS,'MATERIALIZED VIEW')});  
    $mnuDBObjects ->command(-label => "Triggers", 
                           -command => sub { &getDBAObjects($gDATABASE_OBJS,'TRIGGER')});  
    $mnuDBObjects ->command(-label => "Synonyms", 
                           -command => sub { &getDBAObjects($gDATABASE_OBJS,'SYNONYM')});   
    $mnuDBObjects ->command(-label => "Sequences", 
                           -command => sub { &getDBAObjects($gDATABASE_OBJS,'SEQUENCE')});      
    $mnuDBObjects ->command(-label => "Functions", 
                           -command => sub { &getDBAObjects($gDATABASE_OBJS,'FUNCTION')});    
    $mnuDBObjects ->command(-label => "Procedures", 
                           -command => sub { getDBAObjects($gDATABASE_OBJS,'PROCEDURE')});  
    $mnuDBObjects ->command(-label => "Packages", 
                           -command => sub { &getDBAObjects($gDATABASE_OBJS,'PACKAGE')});    
    $mnuDBObjects ->command(-label => "Package Bodies", 
                           -command => sub { &getDBAObjects($gDATABASE_OBJS,'PACKAGE BODY')});    							  
 
 # Create the Session cascade menu
  $mnuSession = $mnuUtils->cascade(-label => 'Session'); 
		   
  $mnuSession->command(-label => "IO", 
                     -command => sub { &displayWindow($gSESS_IO)});		    
  $mnuSession->command(-label => "Events", 
                     -command => sub { &displayWindow($gSESS_EVENTS)}); 
  $mnuSession->command(-label => "Waits", 
                     -command => sub { &displayWindow($gSESS_WAITS)}); 
  # Create the Session Statistics cascade menu
  $mnuSessionStats = $mnuSession->cascade(-label => 'Statistics'); 		     
  $mnuSessionStats->command(-label => "Summary", 
                     -command => sub { &displayWindow($gSESS_STATS)});  		     
  $mnuSessionStats->command(-label => "Time Model", 
                     -command => sub { &displayWindow($gSESS_TIME_MODEL)});
		     
  $mnuSession->command(-label => "Row Wait Object", 
                     -command => sub { &getSessionObject($gSESSIONS)}); 
		     
  # Create the System cascade menu
  $mnuEvents = $mnuUtils->cascade(-label => 'System'); 		    
  $mnuEvents->command(-label => "All System Events ", 
                     -command => sub { &displayWindow($gSYS_EVENTS)}); 	    
  $mnuEvents->command(-label => "System Events Percentages", 
                     -command => sub { &displayWindow($gSYS_EVENTS_PERCENTAGES)}); 
		     
 
		     
 # Create the Locks cascade menu
  $mnuLocks = $mnuUtils->cascade(-label => 'Locks'); 			     
  $mnuLocks->command(-label => "DML Locks", 
                     -command => sub { &displayWindow($gDML_LOCKS)});			     
  $mnuLocks->command(-label => "Blocking Locks", 
                     -command => sub { &displayWindow($gBLOCKING_LOCKS)});
		     
 # Create the TEMP Segments cascade menu
  $mnuSegments = $mnuUtils->cascade(-label => 'TEMP Segments'); 	
  $mnuSegments->command(-label => "Usage", 
                     -command => sub { &displayWindow($gTEMP_SEGS_USAGE)});  	
  $mnuSegments->command(-label => "SQL in TEMP Segments", 
                     -command => sub { &displayWindow($gSQL_TEMP_SEGS)});   
  $mnuSegments->command(-label => "High Water Mark", 
                     -command => sub { &displayWindow($gTEMP_SEGS_HWM)}); 
		     

  $mnuJobs = $mnuUtils->cascade(-label => 'Jobs'); 		     
  $mnuJobs->command(-label => "Defined Jobs", 
                     -command => sub { &displayWindow($gJOBS)}); 	     
  $mnuJobs->command(-label => "Running Jobs", 
                     -command => sub { &displayWindow($gRUNNING_JOBS)}); 
		     
# Create theAlert Log cascade menu
  $mnuAlertLog = $mnuUtils->cascade(-label => 'Alert Log'); 			     
  $mnuAlertLog->command(-label => "Log", 
                     -command => sub { &displayWindow($gALERT_LOG)}); 			     
  $mnuAlertLog->command(-label => "Errors", 
                     -command => sub { &displayWindow($gALERT_LOG_ERRORS)}); 
					 
  $mnuUtils->command(-label => "DBA Registry", 
                     -command => sub { &displayWindow($gDBA_REGISTRY)});	
					 
  $mnuParmas = $mnuUtils->cascade(-label => 'DB Parameters'); 		     
  $mnuParmas->command(-label => "Regular", 
                     -command => sub { &displayWindow($gDB_PARAMETERS)}); 	     
  $mnuParmas->command(-label => "Hidden", 
                     -command => sub { &displayWindow($gDB_HIDDEN_PARAMS)}); 


  $mnuDBUsers = $mnuUtils->cascade(-label => 'DB Users'); 		     
  $mnuDBUsers->command(-label => "User List", 
                     -command => sub { &displayWindow($gUSERS)});		     
  $mnuDBUsers->command(-label => "Failed Logons", 
                     -command => sub { &displayWindow($gFAILED_LOGONS)});		     
  $mnuDBUsers->command(-label => "Invalid User Logons", 
                     -command => sub { &displayWindow($gINVALID_LOGONS)});		     

  $mnuUtils->command(-label => "Roles", 
                     -command => sub { &displayWindow($gROLES)});
		     
  $mnuUtils->command(-label => "Database Links", 
                     -command => sub { &displayWindow($gDB_LINKS)});		     
 # $mnuUtils->command(-label => "Kill Sessions", 
 #                    -command => sub { &confirmKillSessions});  
 #$mnuUtils->command(-label => "Display Table", 
 #                    -command => sub { &displaySelectedTableColumns('powellt','data_elements_diff')});	
}
 
#--------------------------------------------------------
#                   buildUserListMenus
#   
#--------------------------------------------------------
sub buildUserListMenu
{
    (my $HListParent) = @_;
    ${$HListParent}->configure(-menu => $mnuUserBar = ${$HListParent}->Menu); 
    $mnuUserUtils = $mnuUserBar->cascade(-label => '~User Utilities');
    $mnuUserUtils->command(-label => "Lock User Account", 
                           -command => sub { &alterUserStatus('LOCK')});
    $mnuUserUtils->command(-label => "Unlock User Account", 
                           -command => sub { &alterUserStatus('UNLOCK')});
    $mnuUserUtils->command(-label => "Add User to Reserve List", 
                           -command => sub { &reservedUserList('ADD')});
    $mnuUserUtils->command(-label => "Remove User from Reserve List", 
                           -command => sub { &reservedUserList('REMOVE')});
			   
    $mnuUserUtils->command(-label => "Display User Roles and System Privs", 
                           -command => sub { &displayRolesAndPrivs($gUSER_PRIVS)});
    $mnuUserUtils->command(-label => "Create User Script With Role and Sys Privs", 
                           -command => sub { &createUserScript($gUSERS)});
    $mnuUserUtils->command(-label => "Create Script of User Table Privs", 
                           -command => sub { &createUserTablePrivsScript($gUSERS)});
  
    $mnuDBObjects = $mnuUserUtils->cascade(-label => 'User Objects'); 
    $mnuDBObjects ->command(-label => "All Objects", 
                           -command => sub { &getDBAObjects($gUSERS)});   
    $mnuDBObjects ->command(-label => "Object space usage", 
                           -command => sub { &getUserObjects($gUSERS)});   
    $mnuDBObjects ->command(-label => "Tables", 
                           -command => sub { &getDBAObjects($gUSERS,'TABLE')});  
    $mnuDBObjects ->command(-label => "Views", 
                           -command => sub { &getDBAObjects($gUSERS,'VIEW')});   
    $mnuDBObjects ->command(-label => "Materialized Views", 
                           -command => sub { &getDBAObjects($gUSERS,'MATERIALIZED VIEW')});  
    $mnuDBObjects ->command(-label => "Triggers", 
                           -command => sub { &getDBAObjects($gUSERS,'TRIGGER')});  
    $mnuDBObjects ->command(-label => "Synonyms", 
                           -command => sub { &getDBAObjects($gUSERS,'SYNONYM')});   
    $mnuDBObjects ->command(-label => "Sequences", 
                           -command => sub { &getDBAObjects($gUSERS,'SEQUENCE')});      
    $mnuDBObjects ->command(-label => "Functions", 
                           -command => sub { &getDBAObjects($gUSERS,'FUNCTION')});    
    $mnuDBObjects ->command(-label => "Procedures", 
                           -command => sub { &getDBAObjects($gUSERS,'PROCEDURE')});  
    $mnuDBObjects ->command(-label => "Packages", 
                           -command => sub { &getDBAObjects($gUSERS,'PACKAGE')});    
    $mnuDBObjects ->command(-label => "Package Bodies", 
                           -command => sub { &getDBAObjects($gUSERS,'PACKAGE BODY')});     
}

#--------------------------------------------------------
#                   buildRolesMenus
#   
#--------------------------------------------------------
sub buildRolesMenu
{
    (my $HListParent) = @_;
    ${$HListParent}->configure(-menu => $mnuRolesBar = ${$HListParent}->Menu); 
    $mnuRolesUtils = $mnuRolesBar->cascade(-label => '~Roles Utilities');
    $mnuRolesUtils->command(-label => "Privileges", 
                           -command => sub { &displayRolesAndPrivs($gROLE_PRIVS)});
    $mnuRolesUtils->command(-label => "Grantees", 
                           -command => sub { &getUsersGrantedRole($gROLES)});
}

#--------------------------------------------------------
#                   buildTablespaceMenus
#   
#--------------------------------------------------------
sub buildTablespaceMenu
{
    my ($HListID) = @_;
    my $HListParent = $gHLists[$HListID]{'parent'} ;
    ${$HListParent}->configure(-menu => $mnuTablespaceBar = ${$HListParent}->Menu); 
    $mnuTablespaceUtils = $mnuTablespaceBar->cascade(-label => '~Tablespace Utilities');
    $mnuTablespaceUtils->command(-label => "Tablespace Data Files", 
                           -command => sub { &getTablespaceDataFiles($HListID)});
    $mnuTablespaceUtils->command(-label => "Tablespace Objects", 
                           -command => sub {  &getTablespaceObjects($HListID) }); 
    $mnuTablespaceUtils->command(-label => "Tablespace Definition", 
                           -command => sub { &getObjectDefinition($HListID)});
    $mnuTablespaceUtils->command(-label => "Tablespace User Usage", 
                           -command => sub {&getTablespaceUserUsage($HListID)}); 
}

#--------------------------------------------------------
#                   buildObjectsMenu
#   
#--------------------------------------------------------
sub buildObjectsMenu
{
  my ($HListID) = @_;
  my $HListParent = $gHLists[$HListID]{'parent'} ;
  ${$HListParent}->configure(-menu => $mnuObjectsBar = ${$HListParent}->Menu); 
  $mnuObjectsUtils = $mnuObjectsBar->cascade(-label => '~DB Objects Utilities');
  $mnuObjectsUtils->command(-label => "Object Access Privs", 
                           -command => sub { &getObjectAccessPrivileges($HListID)});
  $mnuObjectsUtils->command(-label => "Object Definition", 
                           -command => sub { &getObjectDefinitionText($HListID)});
  $mnuObjectsUtils->command(-label => "Display Table,View", 
                           -command => sub { &displaySelectedTableColumns($HListID)});
  
  
}

#--------------------------------------------------------
#                   buildSDEMenu
#   
#--------------------------------------------------------
sub buildSDEMenu
{ 
  #Create the SDE cascade menu
  $mnuSDE = $mnuBar->cascade(-label => 'SDE'); 
  $mnuSDE->command(-label => "SDE Version", 
                   -command => sub { &getSDEVersion($gSDE_VERSION)});
  $mnuSDE->command(-label => "Server Config", 
                   -command => sub { &displayWindow($gSDE_SERVER_CONFIG)});
  $mnuSDE->command(-label => "DBTune", 
                   -command => sub { &displayWindow($gSDE_DBTUNE)});
  $mnuSDE->command(-label => "SDE Layers", 
                   -command => sub { &displayWindow($gLAYERS)});
  $mnuSDE->command(-label => "Table Registry", 
                   -command => sub { &displayWindow($gSDE_TABLE_REGISTRY)});
  $mnuSDE->command(-label => "SDE Sessions", 
                   -command => sub { &getSDESessions($gSDE_SESSIONS)});   
  		   
}

#--------------------------------------------------------
#                   buildSDESessionsMenu
#   
#--------------------------------------------------------
sub buildSDESessionsMenu
{ 
  
  my ($HListID) = @_;
  my $HListParent = $gHLists[$HListID]{'parent'} ;
  ${$HListParent}->configure(-menu => $mnuSDEBar = ${$HListParent}->Menu); 
  $mnuSDEUtils = $mnuSDEBar->cascade(-label => '~SDE Utilities');
  $mnuSDEUtils->command(-label => "SDE Tables", 
                   -command => sub { &displayWindow($gSDE_TABLES)}); 
  
  
}
#--------------------------------------------------------
#                   buildDBLinksMenu
#   
#--------------------------------------------------------
sub buildDBLinksMenu
{ 
  
  my ($HListID) = @_;
  my $HListParent = $gHLists[$HListID]{'parent'} ;
  ${$HListParent}->configure(-menu => $mnuSDEBar = ${$HListParent}->Menu); 
  $mnuSDEUtils = $mnuSDEBar->cascade(-label => '~Link Utilities');
  $mnuSDEUtils->command(-label => "DB Link Definition", 
                   -command => sub { &getObjectDefinitionText($gDB_LINKS)}); 
  $mnuSDEUtils->command(-label => "Test DB Link", 
                   -command => sub { &testDBLink($gDB_LINKS)}); 
  
  
}
######_________________________________________________________________________
######____________________________  End Menus _________________________________
######_________________________________________________________________________



#/////////////////////////////////////////////////////////////////////////////

#_____________________________________________________________________________
#                                   Subprograms
#_____________________________________________________________________________

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#                         Login related subs


#--------------------------------------------------------
#                       login
#  Attempts to login to the database with the values 
# entered into the login dialog box. If unsuccessful it
# calls the loginFailed routine.
#  The database entered in the dialog box must be the 
# database containing the password repository.
#--------------------------------------------------------
sub login
{   
   my $answer = $dlgLogin->Show( ); 
   if ($answer eq "Ok") 
   {
      #  Connect to the database that holds the encrypted
      # password repository
      $gdbhPasswordDB = DBI->connect("dbi:Oracle:$db",
                                     $gUserName,
		                     $pwd  )||loginFailed($DBI::errstr);
			  
      # Make a separate connection to display the user sessions
      $gdbSessions = $db;
      $gdbhSessionDB = DBI->connect("dbi:Oracle:$db",
                                    $gUserName,
		                    $pwd  )||loginFailed($DBI::errstr);
    }
    else
    {
      $winMain->destroy();	
    }	   
}

#--------------------------------------------------------
#                       loginFailed
#  Displays the error created by the failed login attempt
# and redisplays the login dialog box. 
#--------------------------------------------------------
sub loginFailed
{
   displayMsg($gERROR,"winMain","Invalid Login",@_);		    
   login();	
}


#--------------------------------------------------------
#                    connectToDB
#  Attempts to connect the database selected in the menu
# dropdown and displays the user sessions for the selected
# database
# The user is the user that initially logged into the 
# program.
#--------------------------------------------------------
sub connectToDB
{
  my ($db) = @_;  
  #  Get the user's password for the selected database
  # from the password repository
  my $pwd=&getPassword($db,$gUserName); 
  #  Disconnect from the current database and attempt to
  # connect to the selected database and display the
  # user sessions.
  $rc=$gdbhSessionDB->disconnect();
  $gdbSessions = $db;
  $gdbhSessionDB = DBI->connect("dbi:Oracle:$db",
                                 $gUserName,
		                 $pwd  
			       )|| loginFailed($DBI::errstr);		      
  &refreshDisplay($gSESSIONS);
}

#--------------------------------------------------------
#                    getPassword
#  Attempts to retrieve the user's password for the database
# selected in the menu dropdown 
#  The user is the user that initially logged into the 
# program.
#--------------------------------------------------------
sub getPassword
{
  my ($database,$user)=@_;
  my $pwd;
  eval {  my $func = $gdbhPasswordDB->prepare(q{
					        BEGIN
						  :pwd := pwd.get_pwd( varDatabase => :parameter1,
								       varUsername => :parameter2
								     );
					        END;
					       }
				              );
	  $func->bind_param(":parameter1",$database);
	  $func->bind_param(":parameter2",$user);
	  $func->bind_param_inout(":pwd",\$pwd,250);
	  $func->execute; 
       };
	
   if( $@ ) 
   {
      warn "Execution of stored procedure failed: $DBI::errstr\n"; 
   }
   
   return $pwd;

}
#/////////////////////////////////////////////////////////////////////////////


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#                     Subs specific to the Sessions HList 


#--------------------------------------------------------
#                  confirmKillSessions 
#  Displays all the sesssions the user has selected to 
# terminate and if given the go ahead kills all the sessions.
#--------------------------------------------------------
sub confirmKillSessions
{
   $HListSessions = $gHLists[$gSESSIONS]{'name'}; 
   my @selectedIndices =  ${$HListSessions}->info('selection');     
   if (! @selectedIndices )
   { 
       displayMsg($gERROR,$HListSessions,"Selection Error", "No sessions selected to kill");
   }
   else
   {
       my @sessionIDs = ();
       my $osuser = "";
       my @sessions = ();
       my $session = "";
       my $sid = "";
       my $serialNo = "";
       my $message = "";
       foreach my $r (@selectedIndices) 
       { 
	  $osuser = ${$HListSessions}->itemCget($r,0, '-text') ;
	  $sid =  ${$HListSessions}->itemCget($r,2, '-text') ;
	  $serialNo = ${$HListSessions}->itemCget($r,3, '-text') ;
	  $session = "$osuser,$sid,$serialNo";
	  push(@sessions,$session);
       }
       $message = "Kill the following sessions? \n OSUser ,SID, Serial\#";
       foreach (@sessions) 
       { 
	 $message = "$message \n $_"  
       }
       my  $response = displayOption("winMain","Kill Sessions?",$message);
       
       if ( $response eq 'OK')
       {
	 foreach my $session (@sessions) 
	 {
	    @sessionIDs = split(/\,/,$session );   
	    killSession( $sessionIDs[1],$sessionIDs[2]);
	 }
       }
       refreshDisplay($gSESSIONS);
   }
}


#--------------------------------------------------------
#                   killSession
# Kills the session passed to the procedure 
#--------------------------------------------------------
sub killSession
{
   my($sid,$serialNo)= @_;
   #  Add 0 to the SID and serial number which effectively trims
   # any padded spaces surrounding the values when they are
   # included in the killSession string. If you do not do this
   # then your statement looks like
   #   ALTER SYSTEM KILL SESSION ' 9  , 1343  '; 
   #   instead of
   #   ALTER SYSTEM KILL SESSION '9,1343';
   
   $sid=$sid+0;
   $serialNo=$serialNo+0;
   my $sql =  "ALTER SYSTEM KILL SESSION  \'$sid,$serialNo\' IMMEDIATE" ;
  my $sth = $gdbhSessionDB->prepare($sql);
   $sth->execute();
   if ( $@ ) 
   {
      warn "Database error: $DBI::errstr\n";
   }
}


#--------------------------------------------------------
#                   getSessionObject
# Kills the session passed to the procedure 
#--------------------------------------------------------
sub getSessionObject 
{
   # Get the ID of the HList widget	
   my ($sidSelectSource) = @_;  
   
   # Get the name of the HList widget
   my $HListName = $gHLists[$sidSelectSource]{'name'};
   
   # Get the index of the row selected in the HList widget
   my $selectedIndex = ${$HListName}->info('selection');
    
   my $colSID = columnIndex($sidSelectSource,"sid"); 
   my $SID = ${$HListName}->itemCget($selectedIndex,$colSID, '-text') ; 
  
   my $sql = qq{ SELECT row_wait_obj\#,          
	                row_wait_file\#,         
			row_wait_block\#,        
			row_wait_row\#
                   FROM v\$session
                  WHERE sid = $SID
                };
		 
   my $sth = $gdbhSessionDB->prepare( $sql );
   $sth->execute();     
   my @row = (); 
   @row = $sth->fetchrow_array;  
   print "session SID=$SID $row[0] $row[1] $row[2] $row[3]\n";
   if ( $row[0] != -1)
   {
     my $sql = qq{ SELECT do.object_name,
		          row_wait_obj\# row_wait_obj,
		          row_wait_file\# row_wait_file,
		          row_wait_block\# row_wait_block,
		          row_wait_row\# row_wait_row,
		          dbms_rowid.rowid_create ( 1, ROW_WAIT_OBJ\#, ROW_WAIT_FILE\#, ROW_WAIT_BLOCK\#, ROW_WAIT_ROW\# ) row_id
		   FROM v\$session s,
		        dba_objects DO
	           WHERE sid = $SID
		     AND s.row_wait_obj\# = do.OBJECT_ID
	};
     $gHLists[$gSESS_OBJECT]{'query'} = $sql;
    ($gHLists[$gSESS_OBJECT]{'title'}) = "Row Wait Object for SID $SID";
    
    displayWindow($gSESS_OBJECT);	 
   #  my $sth = $gdbhSessionDB->prepare( $sql );
   #  $sth->execute();     
   #  my @row = (); 
   #  @row = $sth->fetchrow_array;  
   #  print "$row[0] $row[1] $row[2] $row[3] $row[4] $row[5]\n";       
   }
   else
   {
      displayMsg($gINFO,"winMain","No Row ID Object","ROW_WAIT_OBJ# = -1 for $SID."); 
   }
}
#///////////////////////////////////////////////////////////////////////////// 


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#                   Subs specific to the Locked Object HList 


#--------------------------------------------------------
#                      getLockedObject
#  
#--------------------------------------------------------
sub getLockedObject
{
   # Get the ID of the HList widget and the index of 
   # the row that was selected
   my ($HListID,$selectedIndex) = @_;  
   
   # Get the name of the HList widget 
   my $HListName = $gHLists[$HListID]{'name'};
   
   #                   Get the blocked SID 
   my $sid = ${$HListName}->itemCget($selectedIndex,$gCOL_SID_BLOCKED, '-text') ;
   
   #                   Get the locked table
   #  Get the table that the blocked SID is waiting for by getting the object ID
   # contained in the SID's ID1 field of v$lock and then looking up the table 
   # that this object ID corresponds to in the dba_objects table.
   my $sql = qq{ SELECT object_name
                   FROM dba_objects
                  WHERE object_id = (SELECT id1
                                       FROM v\$lock
                                      WHERE sid = $sid
                                        AND type = 'TM') 
                 };
		 
   my $sth = $gdbhSessionDB->prepare( $sql );
   $sth->execute();     
   my @row = (); 
   @row = $sth->fetchrow_array; 
   my $table = $row[0]; 
   $gLockedTable = $table;
   
   #              Get the column names of the locked table
   #   Execute a query on the locked table in order to generate a list
   #  of column names.
   $sql  = qq{SELECT *
	       FROM $table
	      WHERE 1=2
              };
   $sth = $gdbhSessionDB->prepare( $sql );
   $sth->execute(); 
   
   my @columnNames =(); 
   for ($i = 1 ; $i <= $sth->{NUM_OF_FIELDS}; $i++)
   { 
     push(@columnNames,$sth->{NAME}->[$i-1]);
   }
   @gLockedColumns = @columnNames;    
    
   #             Build a query of the locked table
   #  Using the array of columns, query the locked table for the
   # locked row by re-constructing a rowid from the data contained 
   # in the SID's entry in the v$session rtable.
   $sql = sprintf "SELECT %s 
                     FROM %s
		   WHERE rowid = 
		       (SELECT DBMS_ROWID.ROWID_CREATE(1, 
		                                 row_wait_obj\#,
						 row_wait_file\#, 
						 row_wait_block\#, 
						 row_wait_row\#)
			 FROM v\$session
			WHERE sid = %s)",
	    join(", ", @columnNames), $table, $sid;
	    
   $gHLists[$gLOCKED_OBJECT]{'query'} = $sql;
   ($gHLists[$gLOCKED_OBJECT]{'title'}) =~ s/varTable/$table/; 
    
    displayWindow($gLOCKED_OBJECT);
   
}

#///////////////////////////////////////////////////////////////////////////// 


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#                   Subs specific to the Jobs HList 

#--------------------------------------------------------
#                  confirmExecuteJob
#   
#--------------------------------------------------------
sub confirmExecuteJob
{
   my ($HListID, $jobIndex) = @_;  
   
   my $HListName=  $gHLists[$HListID]{'name'};
   my $HListParent=  $gHLists[$HListID]{'parent'};
   $jobNoColumn = columnIndex($HListID,"job");
   $jobNo = ${$HListName}->itemCget($jobIndex, $jobNoColumn, '-text') ;  
   $whatColumn = columnIndex($HListID,"what");
   $job = ${$HListName}->itemCget($jobIndex, $whatColumn, '-text') ;  
   
   $message = "Run job $jobNo ?";  
   my  $response = displayOption($HListParent,"Execute Job ?",$message);
   if ( $response eq 'OK')
   {
      my $results = $gdbhSessionDB->do( " BEGIN SYS.DBMS_IJOB.RUN($jobNo); END;")||displayMsg($gERROR,$HListName,"Procedure Failed", $DBI::errstr);
      if ($gDEBUG)
      {
        print "results = $results\n";
      }
      if ($results == 1)
      {
	 displayMsg($gINFO, $HListParent,"Procedure Completed","Job No $jobNo succesfully completed" ); 
      }
   }
  
}

#///////////////////////////////////////////////////////////////////////////// 


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#                   Subs specific to the SQL Text HList 

#--------------------------------------------------------
#                      getSQLText
#  
#--------------------------------------------------------
sub getSQLText
{
 
   my ($sidSelectSource) = @_;  
    
   my $HListName = $gHLists[$sidSelectSource]{'name'};
   my $selectedIndex = ${$HListName}->info('selection');
    
   my $colAddress = columnIndex($sidSelectSource,"address");
   my $colHashValue = columnIndex($sidSelectSource,"hash_value");   
   my $address = ${$HListName}->itemCget($selectedIndex,$colAddress, '-text') ;
   my $hashValue = ${$HListName}->itemCget($selectedIndex,$colHashValue, '-text') ;
    
   $gHLists[$gSQL_TEXT]{'query'}=qq{ SELECT osuser,
					    username,
					    sid,
					    piece,
					    sql_text
				    FROM v\$sqltext ,
					 v\$session 
				    WHERE sid IN (varSIDs)
				      AND address =  \'$address\'
				      AND hash_value =  \'$hashValue\'
				    ORDER BY varOrderBy
				   };
   $gHLists[$gSQL_TEXT]{'selectionSource'}=$sidSelectSource; 
    
   
 print "address=$address hashvalue= $hashValue sql=$gHLists[$gSQL_TEXT]{'query'}\n";
   
   displayWindow($gSQL_TEXT);

}
#--------------------------------------------------------
#                      getSQLFullText
#  
#--------------------------------------------------------
sub getSQLFullText
{
 
   my ($sidSelectSource) = @_;  
   # Versions earlier than 10g did not have the column 
   #sql_fulltext in the v$sql table, so use the alternate 
   #script that queries the table v$sqltext and displays 
   #the full text in 64 character pieces
   if ($gOracleVersion ne '10g' )
   { 
     getSQLText($sidSelectSource);
     return undef;
   }
    
   my $HListName = $gHLists[$sidSelectSource]{'name'};
   my $selectedIndex = ${$HListName}->info('selection');
   
   my $colAddress = columnIndex($sidSelectSource,"address");
   
   my $colHashValue = columnIndex($sidSelectSource,"hash_value");   
   my $address = ${$HListName}->itemCget($selectedIndex,$colAddress, '-text') ;
   my $hashValue = ${$HListName}->itemCget($selectedIndex,$colHashValue, '-text') ;
   
   my $SQLTextColumn = "";
   my $sql=qq{ SELECT osuser,
		    username,
		    sid,
		    sql_fulltext
	    FROM v\$sql ,
		 v\$session 
	    WHERE sid IN (varSIDs)
	      AND address =  \'$address\'
	      AND hash_value =  \'$hashValue\'
	    ORDER BY varOrderBy
	   };
				   
  print "SQL = $sql \n";
   $gHLists[$gSQL_FULL_TEXT]{'query'}=$sql;
   $gHLists[$gSQL_FULL_TEXT]{'selectionSource'}=$sidSelectSource; 
    
   
  print "address=$address hashvalue= $hashValue sql=$gHLists[$gSQL_FULL_TEXT]{'query'}\n";
   
   displayWindow($gSQL_FULL_TEXT);

}
#///////////////////////////////////////////////////////////////////////////// 


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#                   Subs specific to the Users HList 


#--------------------------------------------------------
#                  alterUserStatus
#   
#--------------------------------------------------------
sub alterUserStatus
{
   my ($accountStatus) = @_;
   
   $HListUsers = $gHLists[$gUSERS]{'name'}; 
   my @selectedIndices =  ${$HListUsers}->info('selection');     
   if (! @selectedIndices )
   { 
       displayMsg($gERROR,$HListUsers,"Selection Error", "No users selected");
   }
   else
   { 
       my $oracleUser = "";
       my @usernames = (); 
       my $message = "";
       foreach my $r (@selectedIndices) 
       { 
	  $oracleUser  = ${$HListUsers}->itemCget($r,0, '-text') ;  
	  push(@usernames,$oracleUser);
       }
       $message = "$accountStatus the Oracle user accounts? ";
       foreach (@usernames) 
       { 
	 $message = "$message \n $_"  
       }
       my $response = displayOption($gHLists[$gUSERS]{'name'},"$accountStatus users?",$message);
       
       if ( $response eq 'OK')
       {
	 foreach my $username (@usernames) 
	 {   
	     my $sql =  "ALTER USER $username ACCOUNT $accountStatus" ;
             my $sth = $gdbhSessionDB->prepare($sql);
	     $sth->execute();
	     if ( $@ ) 
	     {
	       warn "Database error: $DBI::errstr\n";
	     }
	     $sth->finish; 
	 }
       }
      # refreshDisplay($gUsers);
      displayWindow($gUSERS);
   }
}

#--------------------------------------------------------
#                   displayUserList 
# 
#--------------------------------------------------------
sub displayUserList
{
    my ($HListID,$sql) = @_; 
    # Get the name of the HList widget 
    my $HListName = $gHLists[$HListID]{'name'};  
     # Create a button to refresh the display
    my $HListParent = $gHLists[$HListID]{'parent'} ;
    my $tlHList = $gHLists[$HListID]{'parent'};  
  
    #  Retrieve the list of reserved users which should not
    # be locked. The source table is in either the DEVDBA or 
    # CUATDBA schema
    my @reservedUsers =();
    my $usersSQL = qq{SELECT username 
                    FROM reserved_users
                    ORDER BY username};
    	 
    if (my $sth = $gdbhSessionDB->prepare($usersSQL))
    { 
       $sth->execute();     
       my @row = (); 
       while (@row = $sth->fetchrow_array)
       {      
	  push(@reservedUsers,$row[0]);
	  
       }
    }
    #  Create the 3 different HList styles that are used
    # to higlight the locked users, the reserved users 
    # and the reserved users that are locked so that they 
    # are readily identified.
    my $styleLocked = ${$HListName}->ItemStyle("text",
			                 -foreground => "yellow",
			                 -background => "red"); 
    my $styleReserved = ${$HListName}->ItemStyle("text",
			                 -foreground => "yellow",
			                 -background => "steelblue"); 
    my $styleReservedLocked = ${$HListName}->ItemStyle("text",
			                 -foreground => "red",
			                 -background => "steelblue"); 
    
    
    my $rowCount= 0;				 
    if (my $sth = $gdbhSessionDB->prepare( $sql ))
    {
	$sth->execute();     
	my @row = (); 
	while (@row = $sth->fetchrow_array)
	{     
	   ${$HListName}->add(++$i, 
		       -text => $row[0],
		       -data => $row[0] 
		       );   	
           foreach my $column(1 .. $#row)
	   {
	     ${$HListName}->itemCreate($i, 
			               $column, 
			               -text => $row[$column] 
			               ); 
	   }   
	   #............................................
	   #  Highlight the user's name depending on the 
	   # status of his account
	   
	   # If the user's account is locked then use the LOCKED style
	   # to highlight it
	   if ($row[1] =~ 'LOCKED')
	   {
	     ${$HListName}->itemConfigure($i,0,-style => $styleLocked);
	   } 
	   # If the user is in the list of reserved users then use the
	   # RESERVED style to hightlight it
	   if (grep  {/^$row[0]$/}  @reservedUsers)
	   {
	     ${$HListName}->itemConfigure($i,0,-style => $styleReserved);
	     # If the reserved user is locked then use the RESERVEDLOCKED
	     # style to highlight it
	     if ($row[1] =~ 'LOCKED')
	     {
	       ${$HListName}->itemConfigure($i,0,-style => $styleReservedLocked);
	     }
	   }
	   $rowCount++;  
        }
    }
    else
    {
	displayMsg($gERROR, $tlHList,"Window Display Error",$DBI::errstr);  
    }
    $gTotalRows[$HListID] = "Total Rows:    $rowCount";
}

#--------------------------------------------------------
#                  reservedUserList
#   
#--------------------------------------------------------
sub reservedUserList
{
   my ($reserveStatus) = @_;
   
   $HListUsers = $gHLists[$gUSERS]{'name'}; 
   my @selectedIndices =  ${$HListUsers}->info('selection');     
   if (! @selectedIndices )
   { 
       displayMsg($gERROR,$HListUsers,"Selection Error", "No users selected");
   }
   else
   { 
       my $oracleUser = "";
       my @usernames = (); 
       my $message = "";
       foreach my $r (@selectedIndices) 
       { 
	  $oracleUser  = ${$HListUsers}->itemCget($r,0, '-text') ;  
	  push(@usernames,$oracleUser);
       }
       if ($reserveStatus eq 'REMOVE')
       {
          $message = "Remove the following Oracle users from the Reserved list? ";
       }
       else
       {
          $message = "Add the following Oracle users to the Reserved list? ";
       }
	   
       
       foreach (@usernames) 
       { 
	 $message = "$message \n $_"  
       }
       my $response = displayOption($gHLists[$gUSERS]{'name'},"Reserved List Management",$message);
       
       if ( $response eq 'OK')
       {
	 foreach my $username (@usernames) 
	 {   
	     my $sql = '';
	     if ($reserveStatus eq 'REMOVE')
	     {
		 $sql = qq{ DELETE 
		            FROM reserved_users 
		            WHERE username= '$username'} ;
	     }
	     else
	     { 
		 $sql = qq{ INSERT INTO reserved_users 
		            VALUES ('$username')} ;
	     }
             my $sth = $gdbhSessionDB->prepare($sql);
	     $sth->execute();
	     if ( $@ ) 
	     {
	       warn "Database error: $DBI::errstr\n";
	     }
	     $sth->finish; 
	 }
       }
      # refreshDisplay($gUsers);
      displayWindow($gUSERS);
   }
}

#--------------------------------------------------------
#                      getUserObjects
#  
#--------------------------------------------------------
sub getUserObjects
{
 
   my ($userSelectSource) = @_;  
   
   my $andClause = ""; 
   my $owner = "";
   my $HListName = $gHLists[$userSelectSource]{'name'};
   my $selectedIndex = ${$HListName}->info('selection'); 
   if (! $selectedIndex )
   { 
      displayMsg($gERROR,$HListName,"Selection Error", "No username selected");
      return undef;
   }
   if ($userSelectSource == $gUSERS )
   {
      my $colUsername = columnIndex($userSelectSource,"username");   
      $owner = ${$HListName}->itemCget($selectedIndex,$colUsername, '-text') ;  
     ($gHLists[$gUSER_OBJS]{'title'}) = "Objects owned by $owner";  
   }
   elsif ($userSelectSource == $gTBLSPC_USER_USAGE )
   {
      my $colOwner = columnIndex($userSelectSource,"owner");   
      $owner = ${$HListName}->itemCget($selectedIndex,$colOwner, '-text') ;  
      my $colTablespace = columnIndex($userSelectSource,"tablespace_name");
      $tablespace = ${$HListName}->itemCget($selectedIndex,$colTablespace, '-text') ;  
      ($gHLists[$gUSER_OBJS]{'title'}) = "Objects owned by $owner in tablespace $tablespace";  
      $andClause = "AND tablespace_name = '$tablespace'";
   }
   $gHLists[$gUSER_OBJS]{'query'}=qq{SELECT SUBSTR(owner, 1, 32) owner,
	 				     SUBSTR(segment_name, 1, 32) obj_name,
					     segment_type, 
					     ROUND(bytes / 1024 /1024, 2) mbytes,
					     ROUND(bytes / 1024 , 2) kbytes,
					     tablespace_name
				      FROM dba_segments
				      WHERE owner =\'$owner\' 
				      $andClause
				      ORDER BY varOrderBy
				      };
  # print "changing cursor for $HListName\n";	
   ${$HListName}->configure(-cursor=>'watch');	
   ${$HListName}->update;
   displayWindow($gUSER_OBJS);  
   ${$HListName}->configure(-cursor=>'top_left_arrow');
}

#--------------------------------------------------------
#                      createUserScript
#  
#--------------------------------------------------------
sub createUserScript
{
 
   my ($userSelectSource) = @_;  
    
   my $HListName = $gHLists[$userSelectSource]{'name'};
   my $selectedIndex = ${$HListName}->info('selection'); 
   if (! $selectedIndex )
   { 
      displayMsg($gERROR,$HListName,"Selection Error", "No username selected");
      return undef;
   }
   
   my $colUsername = columnIndex($userSelectSource,"username");   
   my $user_name = ${$HListName}->itemCget($selectedIndex,$colUsername, '-text') ;
   
   my $query=qq{select 'CREATE USER '||username||' IDENTIFIED BY <PASSWORD> 
DEFAULT TABLESPACE '||default_tablespace||'
TEMPORARY TABLESPACE '||temporary_tablespace ||';' user_text
from dba_users
where username = upper('$user_name')
UNION
select 'GRANT '||granted_role ||' TO '||grantee||';' user_text
from dba_role_privs
where grantee = upper('$user_name')
UNION
select 'GRANT '||privilege ||' TO '||grantee||';' user_text
from dba_sys_privs
where grantee = upper('$user_name')  
		  };
$gHLists[$gUSER_SCRIPT]{'query'} = $query;	

  print "query = $query\n";
      # refreshDisplay($gUsers);
    displayWindow($gUSER_SCRIPT);

}

#--------------------------------------------------------
#                      createUserTablePrivsScript
#  
#--------------------------------------------------------
sub createUserTablePrivsScript
{
 
   my ($userSelectSource) = @_;  
    
   my $HListName = $gHLists[$userSelectSource]{'name'};
   my $selectedIndex = ${$HListName}->info('selection'); 
   if (! $selectedIndex )
   { 
      displayMsg($gERROR,$HListName,"Selection Error", "No username selected");
      return undef;
   }
   
   my $colUsername = columnIndex($userSelectSource,"username");   
   my $user_name = ${$HListName}->itemCget($selectedIndex,$colUsername, '-text') ;
   
   my $query=qq{
     select 'GRANT '||privilege ||' ON '||owner||'.'||table_name||' TO '||grantee||';' user_text
     from dba_tab_privs
     where grantee = upper('$user_name')  
     order by table_name};
$gHLists[$gUSER_TABLE_PRIVS]{'query'} = $query;	

  print "query = $query\n";
      # refreshDisplay($gUsers);
    displayWindow($gUSER_TABLE_PRIVS);

}
#///////////////////////////////////////////////////////////////////////////// 

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#                   Subs specific to the DB Links HList 

#--------------------------------------------------------
#--------------------------------------------------------
#                    testDBLink
#  Attempts to connect as the user that owns the selected link 
# and then test the db link
#--------------------------------------------------------
sub testDBLink
{
   my ($linkSelectSource) = @_;  
    
   my $HListName = $gHLists[$linkSelectSource]{'name'};
   my $selectedIndex = ${$HListName}->info('selection'); 
   if (! $selectedIndex )
   { 
      displayMsg($gERROR,$HListName,"Selection Error", "No link selected");
      return undef;
   }
   
   my $colOwner = columnIndex($linkSelectSource,"owner");   
   my $owner = ${$HListName}->itemCget($selectedIndex,$colOwner, '-text') ;
   my $colDBLink = columnIndex($linkSelectSource,"db_link");   
   my $linkName = ${$HListName}->itemCget($selectedIndex,$colDBLink, '-text') ;
  #  Get the user's password for the selected database
  # from the password repository
  if ( $owner eq "PUBLIC" )
  {
    $owner = $gUserName; 
  } 
  my $pwd=&getPassword($gdbSessions,$owner); 
  #print "pwd = $pwd\n";
  if ($pwd eq "NOT_FOUND")
  {
    displayMsg($gERROR,"winMain","Invalid Login","No password found for user $owner on $gdbSessions");
    return undef;
  }
  
  #  Disconnect from the current database and attempt to
  # connect to the selected database and display the
  # user sessions.
  #$rc=$gdbhSessionDB->disconnect();
  #$gdbSessions = $db; 
  my $sql = qq{	select * from dual\@$linkName};	
 # print "user = $owner pwd = $pwd link = $linkName\n query = $sql\n";
  
  if (my $dbh = DBI->connect("dbi:Oracle:$gdbSessions", $owner, $pwd   ))
  {
    if ($sth = $dbh->prepare($sql))
    { 
       $sth->execute;	
       my ($testResults);
       $sth->bind_columns(undef,\$testResults);
       $sth->fetch();	
       print "test results = $testResults\n";
       if ( $testResults eq "X" )
       {
	  displayMsg($gINFO,"winMain","DB Link Test", "$linkName connected successfully" );    
       }
       else
       {
	  displayMsg($gINFO,"winMain","DB Link Test", "$linkName test returned $testResults " );        
       }
       $sth->finish; 
    }
    else
    {
      displayMsg($gERROR,"winMain","Invalid Login ", $DBI::errstr );
    }
    my $rc=$dbh->disconnect();	
  }
  else
  { 
    displayMsg($gERROR,"winMain","Invalid password ", $DBI::errstr );
  }
			       
}

#///////////////////////////////////////////////////////////////////////////// 

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#                   Subs specific to the Roles HList 

#--------------------------------------------------------
#                    displayRolesAndPrivs
#   
#--------------------------------------------------------
sub displayRolesAndPrivs
{
   my ($HListID) = @_; 
   my $sql="";
   my @usernames = ();
   # Get the name of the HList widget 
   my $HListName = $gHLists[$HListID]{'name'};
   my $selectionSourceName=$gHLists[$gHLists[$HListID]{'selectionSource'}]{name};
   #  If the HList query depends upon selections in a
   # parent window then retreive the selected column
   # values. If no selections have been made then
   # exit the program
   if ( $gHLists[$HListID]{'windowType'} == $gCHILD)
   {   
       my $selectColumn = "";
       switch ($HListID)
      {
          case "$gUSER_PRIVS"  
	  {
	    $selectColumn = 'username';
	  }
	  case "$gROLE_PRIVS"  
	  {
	    $selectColumn = 'role';
	  }
      }
       @usernames = selections($HListID,$selectColumn); 
       if (@usernames)
       {
	    if ($#usernames > 1)
	    { 
	      displayMsg($gERROR,$selectionSourceName,"Selection Error","Only 1 $selectColumn is allowed to display privileges."); 
	      return undef;
	    }
       }  
       else  
       {  
	   displayMsg($gERROR,$selectionSourceName,"Selection Error","No $selectColumn has been selected."); 
	   return undef;
       }
   }
   
   
   #  Get the top level object where the HList
   # is being created. If it doesn't already
   # exist then create it and its HList.
   my $tlHList = $gHLists[$HListID]{'parent'};  
   if (! Exists(${$tlHList})) 
   {
     ${$tlHList} = $winMain->Toplevel( );
     ${$tlHList}->Button(-text => "Close", 
		         -command => sub { ${$tlHList}->withdraw }
		        )->pack( -pady => 5);  
     
      buildHList($HListID); 
     # my $widget = ${$HListName}->headerCget(0,-widget);
     # $widget->configure(-command => "doNothing");
   } 
   else 
   {
     ${$tlHList}->deiconify( );
     ${$tlHList}->raise( );
   }      
   
       
    
   ${$HListName}->configure(-cursor=>'watch');
   # Clear out all data currently displayed in the HList
   ${$HListName}->delete('all');
   # Set the title of the HList window
    ${$tlHList}->title( "$gHLists[$HListID]{'title'} on $gdbSessions");
    
    #  Get the SQL query  
 $user = $usernames[0] ;
 ($sql = $gHLists[$HListID]{'query'}) =~ s/varUser/$user/;
 #print "$sql\n";
  my $rowCount= 0; 
 #Enable DBMS_OUTPUT				    
 $gdbhSessionDB->func(1000000,'dbms_output_enable');
 
	   $sth = $gdbhSessionDB->prepare($sql);
	   $sth->execute;
	   #print "Loop SQL = $sql\n";
	  # retrieve the string
	    while (my $strRole = $gdbhSessionDB->func( 'dbms_output_get' ))
	    {    
		 #print "strRole = $strRole\n"; 
		  #print "rowcount =$rowCount";
		 # $strRole = "$strRole,some stuff";
		 # my @row = (); 
		 #@row = $strRole;
		 # print "@row $#row\n"; 
	      ${$HListName}->add( ++$i, -text => $strRole); 
	       $rowCount++;   
  }
  print "rowcount =$rowCount";
  ${$HListName}->configure(-cursor=>'top_left_arrow');
}


#--------------------------------------------------------
#                      getUsersGrantedRole
#  
#--------------------------------------------------------
sub getUsersGrantedRole
{
 
   my ($roleSelectSource) = @_;  
    
   my $HListName = $gHLists[$roleSelectSource]{'name'};
   my $selectedIndex = ${$HListName}->info('selection'); 
   if (! $selectedIndex )
   { 
      displayMsg($gERROR,$HListName,"Selection Error", "No role selected");
      return undef;
   }
   my $colRole = columnIndex($roleSelectSource,"role");   
   my $role = ${$HListName}->itemCget($selectedIndex,$colRole, '-text') ; 
   #print "role=$role\n";
   $gHLists[$gROLE_USERS]{'query'}=qq{SELECT grantee,
					     default_role,
					     admin_option
				    FROM dba_role_privs
				    WHERE granted_role =\'$role\'
				    ORDER BY varOrderBy
				   };
				   
   			   
   ($gHLists[$gROLE_USERS]{'title'}) = "Users Granted Role $role";
   
   displayWindow($gROLE_USERS);
   # After the datafile HList is created.
   # Change the select mode to single.
   #my $HListName=  $gHLists[$gDATA_FILES]{'name'}; 
   #${$HListName}->configure(-selectmode=>'single');

}

#///////////////////////////////////////////////////////////////////////////// 


#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#                   Subs specific to the Free Space HList 

#--------------------------------------------------------
#                      getTablespaceDataFiles
#  
#--------------------------------------------------------
sub getTablespaceDataFiles
{
 
   my ($tablespaceSelectSource) = @_;  
    
   my $HListName = $gHLists[$tablespaceSelectSource]{'name'};
   my $selectedIndex = ${$HListName}->info('selection');  
   if (! $selectedIndex )
   { 
      displayMsg($gERROR,$HListName,"Selection Error", "No tablespace selected");
      return undef;
   } 
   my $colTablespace = columnIndex($tablespaceSelectSource,"tablespace_name");   
   my $tablespace_name = ${$HListName}->itemCget($selectedIndex,$colTablespace, '-text') ; 
   $gHLists[$gDATA_FILES]{'query'}=qq{SELECT tablespace_name,
					    file_name,
					    file_id,
					    bytes \/ 1024 \/ 1024 size_mb,
					    maxbytes \/ 1024 \/ 1024 max_size_mb,
					    autoextensible 
				    FROM dba_data_files
				    WHERE tablespace_name =\'$tablespace_name\'
				    ORDER BY varOrderBy
				   };
				    
   ($gHLists[$gDATA_FILES]{'title'}) = "Datafiles in tablespace $tablespace_name";
   
   displayWindow($gDATA_FILES);
   # After the datafile HList is created.
   # Change the select mode to single.
   my $HListName=  $gHLists[$gDATA_FILES]{'name'}; 
   ${$HListName}->configure(-selectmode=>'single');

}
#--------------------------------------------------------
#                      getDatafileObjects
#  
#--------------------------------------------------------
sub getDatafileObjects
{
 
   my ($tablespaceSelectSource) = @_;  
   
 #  my $andClause = "";
   
   my $HListName = $gHLists[$tablespaceSelectSource]{'name'};
   my $selectedIndex = ${$HListName}->info('selection');  
   
   if (! $selectedIndex )
   { 
      displayMsg($gERROR,$HListName,"Selection Error", "No data file selected");
      return undef;
   } 
   ${$HListName}->configure(-cursor=>'watch');
   
   my $colTablespace = columnIndex($tablespaceSelectSource,"tablespace_name");   
   my $tablespace_name = ${$HListName}->itemCget($selectedIndex,$colTablespace, '-text') ;  
   my $colFileID = columnIndex($tablespaceSelectSource,"file_id");  
   my $fileID = ${$HListName}->itemCget($selectedIndex,$colFileID, '-text') ; 
  # $andClause = " AND file_id=$fileID";
   my $colFileName = columnIndex($tablespaceSelectSource,"file_name");  
   my $fileName = ${$HListName}->itemCget($selectedIndex,$colFileName, '-text') ; 
   ($gHLists[$gDATAFILE_OBJS]{'title'}) = "Objects in datafile $fileName";  
   
   $gHLists[$gDATAFILE_OBJS]{'query'}=qq{SELECT SUBSTR(owner, 1, 32) owner,
	 				     SUBSTR(segment_name, 1, 32) obj_name,
					     segment_type,
					     file_id,
					     block_id,
					     ROUND(bytes / 1024 /1024, 2) mbytes,
					     ROUND(bytes / 1024 , 2) kbytes
				      FROM dba_extents
				      WHERE tablespace_name =\'$tablespace_name\' 
				      AND file_id=$fileID
				      ORDER BY varOrderBy
				      };
   			      
   displayWindow($gDATAFILE_OBJS); 
   
    
   ${$HListName}->configure(-cursor=>'top_left_arrow');


}
#--------------------------------------------------------
#                      getTablespaceObjects
#  
#--------------------------------------------------------
sub getTablespaceObjects
{ 
   my ($tablespaceSelectSource, $objectType) = @_;  
   my $HListName = $gHLists[$tablespaceSelectSource]{'name'};
   my $tablespace_name = "";
   my $whereClause = "";
   my $andClause = "";
  # $gTABLESPACES,$gFREE_SPACE ,$gDATABASE_OBJS
   switch ($tablespaceSelectSource)
   { 
      case [ $gTABLESPACES,$gFREE_SPACE ]
      {   
	       my $selectedIndex = ${$HListName}->info('selection'); 
		   if (! $selectedIndex )
		   { 
			  displayMsg($gERROR,$HListName,"Selection Error", "No tablespace selected");
			  return undef;
		   } 
		   my $colTablespace = columnIndex($tablespaceSelectSource,"tablespace_name");   
		   $tablespace_name = ${$HListName}->itemCget($selectedIndex,$colTablespace, '-text') ;  
		   ($gHLists[$gTBLSPC_OBJS]{'title'}) = "Objects in tablespace $tablespace_name";  
		   $whereClause = "WHERE tablespace_name =\'$tablespace_name\' ";
      }
      case [$gDATABASE_OBJS ]
      {  
	    $whereClause = "WHERE segment_type = \'$objectType\'";
      } 
   }
   

   $gHLists[$gTBLSPC_OBJS]{'query'}=qq{SELECT SUBSTR(owner, 1, 32) owner,
	 				     SUBSTR(segment_name, 1, 32) obj_name,
					     segment_type,
					     ROUND(bytes / 1024 /1024, 2) mbytes,
					     ROUND(bytes / 1024 , 2) kbytes
				      FROM dba_segments
				      $whereClause
				      ORDER BY varOrderBy
				      };
  # print "changing cursor for $HListName\n";	
   ${$HListName}->configure(-cursor=>'watch');
   ${$HListName}->update;
   displayWindow($gTBLSPC_OBJS);  
   ${$HListName}->configure(-cursor=>'top_left_arrow');
}
#--------------------------------------------------------
#                      getTablespaceUserUsage
#  
#--------------------------------------------------------
sub getTablespaceUserUsage
{
 
   my ($tablespaceSelectSource) = @_;  
    
   my $HListName = $gHLists[$tablespaceSelectSource]{'name'};
   my $selectedIndex = ${$HListName}->info('selection'); 
   if (! $selectedIndex )
   { 
      displayMsg($gERROR,$HListName,"Selection Error", "No tablespace selected");
      return undef;
   } 
   my $colTablespace = columnIndex($tablespaceSelectSource,"tablespace_name");   
   my $tablespace_name = ${$HListName}->itemCget($selectedIndex,$colTablespace, '-text') ; 
   $gHLists[$gTBLSPC_USER_USAGE]{'query'}=qq{SELECT tablespace_name,
	                                             owner , 
					            SUM(ROUND(bytes / 1024/1024 , 2)) mbytes,
						    COUNT(DISTINCT segment_name) num_objs
				             FROM dba_segments
				             WHERE tablespace_name =\'$tablespace_name\'
					     GROUP BY tablespace_name,owner
				             ORDER BY varOrderBy
				             };
				    
   ($gHLists[$gTBLSPC_USER_USAGE]{'title'}) = "User Usage in tablespace $tablespace_name";
   #print "SQL = $gHLists[$gTBLSPC_USER_USAGE]{'query'}\n";
   ${$HListName}->configure(-cursor=>'watch');
   ${$HListName}->update;
   displayWindow($gTBLSPC_USER_USAGE);
   # After the datafile HList is created.
   # Change the select mode to single.
   ${$HListName}->configure(-cursor=>'top_left_arrow');

}
#///////////////////////////////////////////////////////////////////////////// 


#--------------------------------------------------------
#                      getDBAObjects
#  
#--------------------------------------------------------
sub getDBAObjects
{ 
   my ($userSelectSource,$objectType) = @_;  
   my $HListName = $gHLists[$userSelectSource]{'name'};
   my $whereClause = "";
   my $andClause = ""; 
   
   if ($userSelectSource == $gUSERS)
   {   
	   my $selectedIndex = ${$HListName}->info('selection'); 
	   if (! $selectedIndex )
	   { 
	      displayMsg($gERROR,$HListName,"Selection Error", "No username selected");
	      return undef;
	   } 
	   my $colUsername = columnIndex($userSelectSource,"username");   
	   my $user_name = ${$HListName}->itemCget($selectedIndex,$colUsername, '-text') ;    
	   $whereClause = "WHERE owner =\'$user_name\' ";
	   if ($objectType ne "")
	   {
	      $andClause = "AND object_type = \'$objectType\'";
	   } 
	  ($gHLists[$gDBA_OBJECTS]{'title'}) = "All $objectType objects owned by $user_name";  
   }
   elsif ($userSelectSource == $gDATABASE_OBJS)
   {
	   $HListName = $gHLists[$gSESSIONS]{'name'};
	   if ($objectType ne "")
	   {
	     $whereClause = "WHERE object_type = \'$objectType\'";
	   }
   }
   $gHLists[$gDBA_OBJECTS]{'query'}=qq
   {
	 SELECT owner,
		 SUBSTR(object_name, 1, 32) obj_name,
		 object_id,
		 object_type, 
		 status,
		 created,
		 last_ddl_time,
		 timestamp
	 FROM dba_objects
	 $whereClause
	   $andClause
	 ORDER BY varOrderBy
    };
				      
    print "${$HListName} sql = $gHLists[$gDBA_OBJECTS]{'query'}\n";
   # print "changing cursor for $HListName\n";	
   # ${$HListName}->configure(-cursor=>'watch');	
   # ${$HListName}->update;
   displayWindow($gDBA_OBJECTS);  
  #  ${$HListName}->configure(-cursor=>'top_left_arrow');
}

#--------------------------------------------------------
#                      getDBATriggers
#  
#--------------------------------------------------------
sub getDBATriggers
{ 
   my ($userSelectSource) = @_;  
   
   my $andClause = "";
   if ($objectType ne "")
   {
      $andClause = "AND object_type = \'$objectType\'";
   }
   my $HListName = $gHLists[$userSelectSource]{'name'};
   my $selectedIndex = ${$HListName}->info('selection'); 
   if (! $selectedIndex )
   { 
      displayMsg($gERROR,$HListName,"Selection Error", "No username selected");
      return undef;
   } 
   my $colUsername = columnIndex($userSelectSource,"username");   
   my $user_name = ${$HListName}->itemCget($selectedIndex,$colUsername, '-text') ;  
  ($gHLists[$gDBA_OBJECTS]{'title'}) = "All Objects owned by $user_name";  
   $gHLists[$gDBA_OBJECTS]{'query'}=qq{SELECT owner,
	 				     SUBSTR(object_name, 1, 32) obj_name,
					     object_id,
					     object_type, 
					     status,
					     created,
					     last_ddl_time,
					     timestamp
				      FROM dba_objects
				      WHERE owner =\'$user_name\' 
				      $andClause
				      ORDER BY varOrderBy
				      };
   # print "changing cursor for $HListName\n";	
   ${$HListName}->configure(-cursor=>'watch');	
   ${$HListName}->update;
   displayWindow($gDBA_OBJECTS);  
   ${$HListName}->configure(-cursor=>'top_left_arrow');
}

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#               Subs specific to the database objects HLists 

#--------------------------------------------------------
#                 getObjectAccessPrivileges
#--------------------------------------------------------
sub getObjectAccessPrivileges
{
   # Get the HList ID that called the program and declare
   #the variables for the object and owner lists
   my ($objectSelectSource) = @_;  
   my $objectList="";
   my $ownerList=""; 
   my @DBObjects = ();
   if ($gDEBUG)
   {
     print "source =$objectSelectSource\n";
   }
   #  Get the objects the user selected and build a comma separated 
   # list of them.
   switch ($objectSelectSource)
   { 
      case [ $gTBLSPC_OBJS,$gDATAFILE_OBJS,$gUSER_OBJS,$gDATABASE_OBJS ]
      {   
	     @DBObjects = selections($objectSelectSource,"obj_name"); 
      }
      case [$gDBA_OBJECTS ]
      {  
	     @DBObjects = selections($objectSelectSource,"object_name"); 
      } 
   }
   if (@DBObjects)
   {
     my @objs = ();
     foreach my $obj (@DBObjects) 
     {
       push(@objs,"\'$obj\'");
     }
     $objectList = join(',',@objs); 
   }  
   else  
   {  
      displayMsg($gERROR,$HListName,"Selection Error","No object selections have been made."); 
      return undef;
   }
   
   #  Get the owners of the objects the user selected 
   # and build a comma separated list of them.
   # NOTE: Due to the way the query is built below there is not
   #       a one to one correspondence between the object and
   #       its owner, i.e., if an object name exists in any of
   #       the schemas listed in the owner list then it will
   #       show up in the display
   my @objectOwners = selections($objectSelectSource,"owner"); 
   if (@objectOwners)
   {
     my @owners = ();
     foreach my $owner (@objectOwners) 
     {
       push(@owners,"\'$owner\'");
     }
     $ownerList = join(',',@owners);  
   }   
   print "owners=$ownerList objects=$objectList\n";
   # Padding is added to the query to add space around the columns thus making the
   #displayed results more readable
   $gHLists[$gOBJECT_ACCESS]{'query'}=qq{SELECT rpad(owner,35) owner,
					        rpad(table_name,35) table_name,
					        rpad(grantee,35) grantee,
					        rpad(privilege,15) privilege,
					        grantable
				         FROM dba_tab_privs
				         WHERE table_name in ($objectList)
					   AND owner IN ($ownerList)
				         ORDER BY varOrderBy
				        }; 
   	
   # Build the header and display the HList  
   ($gHLists[$gOBJECT_ACCESS]{'title'}) = "Users Granted Access to $objectList"; 
    displayWindow($gOBJECT_ACCESS);   
}

sub getObjectAccessPrivilegesOld
{
   my ($objectSelectSource) = @_;  
    
   my $HListName = $gHLists[$objectSelectSource]{'name'};
   my $selectedIndex = ${$HListName}->info('selection'); 
   if (! $selectedIndex )
   { 
      displayMsg($gERROR,$HListName,"Selection Error", "No object selected");
      return undef;
   }
   my $colObjectName = columnIndex($objectSelectSource,"obj_name");   
   my $object = ${$HListName}->itemCget($selectedIndex,$colObjectName, '-text') ; 
   print "object=$object\n";
   # Padding is added to the query to add space around the columns thus making the
   #displayed results more readable
   $gHLists[$gOBJECT_ACCESS]{'query'}=qq{SELECT rpad(owner,35) owner,
					        rpad(table_name,35) table_name,
					        rpad(grantee,35) grantee,
					        rpad(privilege,15) privilege,
					        grantable
				         FROM dba_tab_privs
				         WHERE table_name=\'$object\'
				         ORDER BY varOrderBy
				        };
				   
   			   
   ($gHLists[$gOBJECT_ACCESS]{'title'}) = "Users Granted Access to $object";
   
   displayWindow($gOBJECT_ACCESS);   
}


#--------------------------------------------------------
#                    getObjectDefinition
#  Extracts the necessary info from the HList fields to 
# pass to the DBMS_METADATA.GET_DDL function that returns  
# the selected object's definition.
#--------------------------------------------------------
sub getObjectDefinition
{
   # Get the ID of the HList that called the sub
   my ($objectSelectSource) = @_;   
   
   my $colObjectName = "";
   my $colObjectType = "";
   my $colObjectOwner = "";
   my $objectType = "";
   my $objectOwner = "";
   
   # Get the name of the HList that called the sub and 
   # get the HList index of the object selected
   my $HListName = $gHLists[$objectSelectSource]{'name'};
   my $selectedIndex = ${$HListName}->info('selection');  
   
  
   # If no object was selected then display an error
   # and exit the sub
   if (! $selectedIndex )
   { 
      displayMsg($gERROR, $HListName, "Selection Error", "No object selected");
      return undef;
   }
   
   #  For most of the database object tables the object name field is
   # called OBJ_NAME and the object type field is called SEGMENT_TYPE, exit
   # however for the table DBA_OBJECTS the fields are called OBJECT_NAME 
   # and OBJECT_TYPE respectively. 
   # Get the HList indices of the columns that contains the object name 
   # and the object type.
   switch ($objectSelectSource)
   { 
      case [ $gTBLSPC_OBJS,$gDATAFILE_OBJS,$gUSER_OBJS,$gDATABASE_OBJS ]
      {   
	$colObjectName = columnIndex($objectSelectSource,"obj_name");   
	$colObjectType = columnIndex($objectSelectSource,"segment_type");   
      }
      case [$gDBA_OBJECTS ]
      {  
	$colObjectName = columnIndex($objectSelectSource,"object_name");   
	$colObjectType = columnIndex($objectSelectSource,"object_type");    
      } 
      case [ $gTABLESPACES,$gFREE_SPACE]
      {  
	$colObjectName = columnIndex($objectSelectSource,"tablespace_name");    
	$objectType = "TABLESPACE";    
      } 
      case [$gDB_LINKS]
      {  
	$colObjectName = columnIndex($objectSelectSource,"db_link");   
	$objectType = "DB_LINK";    
        $colObjectOwner = columnIndex($objectSelectSource,"owner");   
        $objectOwner = ${$HListName}->itemCget($selectedIndex,$colObjectOwner, '-text') ; 
      } 
   }
    
   # From the indices returned above, extract the name and type of the 
   # selected object.
   my $objectName = ${$HListName}->itemCget($selectedIndex,$colObjectName, '-text') ;  
   
   if ($objectSelectSource != $gFREE_SPACE && $objectSelectSource != $gTABLESPACES && $objectSelectSource != $gDB_LINKS)
   {
     $objectType = ${$HListName}->itemCget($selectedIndex,$colObjectType, '-text');
     # Get the owner of the object.
     $colObjectOwner = columnIndex($objectSelectSource,"owner");   
     $objectOwner = ${$HListName}->itemCget($selectedIndex,$colObjectOwner, '-text') ; 
   } 
   #  Some object types need to translated into a type that the 
   # DBMS_METADATA.GET_DDL function understands.
   switch ($objectType)
   { 
      case [ "DATABASE LINK" ]
      {   
	$objectType = "DB_LINK";
      }
      case ["MATERIALIZED VIEW"]
      {  
	$objectType = "MATERIALIZED_VIEW";      
      } 
      case ["PACKAGE BODY"]
      {  
	$objectType = "PACKAGE";      
      } 
   }
    # Build the query to extract the definition of the selected object.
   if( $objectSelectSource != $gDB_LINKS )
   {
    $gHLists[$gOBJECT_DEFINITION]{'query'}= qq{SELECT dbms_metadata.get_ddl(\'$objectType\',
 					              \'$objectName\',
 					              \'$objectOwner\')  
					     FROM dual 
				            };
   }
   else
   {
     $gHLists[$gOBJECT_DEFINITION]{'query'}=qq{SELECT dbms_metadata.get_ddl(\'$objectType\',
 					              \'$objectName\',
 						      \'$objectOwner\',
						      '10.2.0.1')  
					     FROM dual 
				            };
   }
  
   
  
   #print "query = $gHLists[$gOBJECT_DEFINITION]{'query'}=$objectQuery\n";
				   
   # Construct the title of the object definition HList			   
   ($gHLists[$gOBJECT_DEFINITION]{'title'}) = "Definition of $objectName";
   
   # Display the object definition HList.
   ${$HListName}->configure(-cursor=>'watch');
   ${$HListName}->update;
   displayWindow($gOBJECT_DEFINITION);   
   ${$HListName}->configure(-cursor=>'top_left_arrow');
   
}
#--------------------------------------------------------
#                    getObjectDefinitionText
#  Extracts the necessary info from the HList fields to 
# pass to the DBMS_METADATA.GET_DDL function that returns  
# the selected object's definition.
#--------------------------------------------------------
sub getObjectDefinitionText
{
   # Get the ID of the HList that called the sub
   my ($objectSelectSource) = @_;   
   
   my $colObjectName = "";
   my $colObjectType = "";
   my $colObjectOwner = "";
   my $objectType = "";
   my $objectOwner = "";
   my $sql = "";
   
   # Get the name of the HList that called the sub and 
   # get the HList index of the object selected
   my $HListName = $gHLists[$objectSelectSource]{'name'};
   my $selectedIndex = ${$HListName}->info('selection');  
   
  
   # If no object was selected then display an error
   # and exit the sub
   if (! $selectedIndex )
   { 
      displayMsg($gERROR, $HListName, "Selection Error", "No object selected");
      return undef;
   }
   ${$HListName}->configure(-cursor=>'watch');
   ${$HListName}->update;
   #  For most of the database object tables the object name field is
   # called OBJ_NAME and the object type field is called SEGMENT_TYPE, exit
   # however for the table DBA_OBJECTS the fields are called OBJECT_NAME 
   # and OBJECT_TYPE respectively. 
   # Get the HList indices of the columns that contains the object name 
   # and the object type.
   switch ($objectSelectSource)
   { 
      case [ $gTBLSPC_OBJS,$gDATAFILE_OBJS,$gUSER_OBJS,$gDATABASE_OBJS ]
      {   
	$colObjectName = columnIndex($objectSelectSource,"obj_name");   
	$colObjectType = columnIndex($objectSelectSource,"segment_type");   
      }
      case [$gDBA_OBJECTS ]
      {  
	$colObjectName = columnIndex($objectSelectSource,"object_name");   
	$colObjectType = columnIndex($objectSelectSource,"object_type");    
      } 
      case [ $gTABLESPACES,$gFREE_SPACE]
      {  
	$colObjectName = columnIndex($objectSelectSource,"tablespace_name");    
	$objectType = "TABLESPACE";    
      } 
      case [$gDB_LINKS]
      {  
	$colObjectName = columnIndex($objectSelectSource,"db_link");   
	$objectType = "DB_LINK";    
        $colObjectOwner = columnIndex($objectSelectSource,"owner");   
        $objectOwner = ${$HListName}->itemCget($selectedIndex,$colObjectOwner, '-text') ; 
      } 
   }
    
   # From the indices returned above, extract the name and type of the 
   # selected object.
   my $objectName = ${$HListName}->itemCget($selectedIndex,$colObjectName, '-text') ;  
   
   if ($objectSelectSource != $gFREE_SPACE && $objectSelectSource != $gTABLESPACES && $objectSelectSource != $gDB_LINKS)
   {
     $objectType = ${$HListName}->itemCget($selectedIndex,$colObjectType, '-text');
     # Get the owner of the object.
     $colObjectOwner = columnIndex($objectSelectSource,"owner");   
     $objectOwner = ${$HListName}->itemCget($selectedIndex,$colObjectOwner, '-text') ; 
   } 
   #  Some object types need to translated into a type that the 
   # DBMS_METADATA.GET_DDL function understands.
   switch ($objectType)
   { 
      case [ "DATABASE LINK" ]
      {   
	$objectType = "DB_LINK";
      }
      case ["MATERIALIZED VIEW"]
      {  
	$objectType = "MATERIALIZED_VIEW";      
      } 
      case ["PACKAGE BODY"]
      {  
	$objectType = "PACKAGE";      
      } 
   }
    # Build the query to extract the definition of the selected object.
   if( $objectSelectSource != $gDB_LINKS )
   {
    $sql = qq{SELECT dbms_metadata.get_ddl(\'$objectType\',
 					   \'$objectName\',
 					   \'$objectOwner\')  
					   FROM dual 
				           };
   }
   else
   {
     $sql =qq{SELECT dbms_metadata.get_ddl(\'$objectType\',
 				           \'$objectName\',
 				           \'$objectOwner\',
					   '10.2.0.1')  
					     FROM dual 
				            };
   }
  
   
  
   #print "query = $gHLists[$gOBJECT_DEFINITION]{'query'}=$objectQuery\n";
				   
   # Construct the title of the object definition HList			   
   #($gHLists[$gOBJECT_DEFINITION]{'title'}) = "Definition of $objectName";
   
   $gdbhSessionDB->{LongReadLen} = 1000 * 1024; 
   
   #  Execute the query and populate the HList
	# or display an error if the query fails.
   if (my $sth = $gdbhSessionDB->prepare( $sql ))
   {
      $sth->execute();     
      my ($objectDefinition);
      $sth->bind_columns(undef,\$objectDefinition);
      $sth->fetch();  
      print "db link = $objectDefinition\n";
      my $title = "$objectType definition for $objectOwner.$objectName";
       ${$HListName}->configure(-cursor=>'top_left_arrow');
      displayText($objectDefinition,$title);
    }
    else
    {
     displayMsg($gERROR, $winMain,"Window Display Error",$DBI::errstr);  
    } 
} 
#--------------------------------------------------------
#                      displayText
#  
#--------------------------------------------------------
sub displayText
{
   my ($text,$title) = @_;  	 
   my $winText = $winMain->Toplevel( );
   my $frame1 = $winText->Frame();
   my $frame2 = $winText->Frame();
   
   $winText->configure(-title => $title);
   
   $frame1->pack(-side => 'top');
   $frame2->pack(-side => 'top');
   #my $b1 = $frame1->Button();
   my $quitButton = $frame1->Button();
   $quitButton->configure(-text    => 'Close', 
   		          -width   => 5,
   	                  -height  => 1,
   		          -command => sub {  $winText ->withdraw } );   
   $quitButton->pack(-side => 'left'); 


   
   
   

   # Pack the widgets in the frames
   #my $b1->pack(-side => 'left');
    
   my $textBox= $frame2->Scrolled("Text" ,                
				  -width => 120,           
				  -height => 50,)->pack(-expand => 1, 
					    -fill => 'both',
					    -padx => 10,
					    -pady => 10
					   );
   $textBox->configure(-font => '-*-helvetica-bold-r-*-*-*-130-*-*-*-*-*-*');
   $textBox->insert('end',$text);
   
   #$b1->configure(-text => 'Clear',
   #	       -command => [ \&HandleClear, $textBox ]);
   $text = $textBox->get("1.0","end");
   print "text =$text\n";
}

sub HandleClear
{
    my $text = $_[0];
    $text->delete('1.0','end');
    $text->insert("end", ">>  ");
}


#--------------------------------------------------------
#                      getSDESessions
#  
#--------------------------------------------------------
sub getSDESessions
{ 
   my ($SDESessionsID) = @_;  
   if ("$gSDEVersion" == "8")
   {
     $gHLists[$SDESessionsID]{'query'}=qq{SELECT owner,
	 			                 sde_id as sid,
				                 server_id,
						 'UNKNOWN',
				                 TO_CHAR(start_time,'Mon DD, YYYY HH24:MI:ss ') start_time,
                                                 rcount,
				                 wcount,
				                 opcount,
				                 numlocks
				          FROM sde.process_information
		                         ORDER BY varOrderBy
		                         };
   }
   else
   {
     $gHLists[$SDESessionsID]{'query'}=qq{SELECT owner,
	 			                 sde_id as sid,
				                 server_id,
						 nodename,
				                 TO_CHAR(start_time,'Mon DD, YYYY HH24:MI:ss ') start_time,
                                                 rcount,
				                 wcount,
				                 opcount,
				                 numlocks
				          FROM sde.process_information
		                         ORDER BY varOrderBy
		                         };
   }
   displayWindow($SDESessionsID);   
}
#--------------------------------------------------------
#                      getSDEVersion
#  
#--------------------------------------------------------
sub getSDEVersion
{ 
   my ($SDEVersionID) = @_;  
   if ("$gSDEVersion" == "8")
   {
     $gHLists[$SDEVersionID]{'query'}=qq{SELECT major||'.'||minor version,
	 			                 bugfix,
				                 description,
				                 release, 
				                 'UNKNOWN'
				          FROM sde.version 
		                         };
   }
   else
   {
     $gHLists[$SDEVersionID]{'query'}=qq{SELECT major||'.'||minor version,
	 			                 bugfix,
				                 description,
				                 release, 
				                 sdesvr_rel_low
				          FROM sde.version 
		                         };
   }
   displayWindow($SDEVersionID);  
}

#--------------------------------------------------------
#                      getCachedObjects
#  
#--------------------------------------------------------
sub getCachedObjects
{ 
   my $objectList = join('\',\'', @_);  
   $gHLists[$gDB_OBJECT_CACHE]{'query'}=qq{SELECT owner,
		                                 name,  
			                         db_link,
						 type,
			                         TO_CHAR(sharable_mem,'999,999,999') sharable_mem,
			                         loads,
			                         TO_CHAR(executions,'999,999,999') executions,
			                         locks,
				                 pins
				           FROM v\$db_object_cache
				           WHERE type IN ('$objectList')
		                           ORDER BY varOrderBy
		                          };					  
   displayWindow($gDB_OBJECT_CACHE);  
}
#--------------------------------------------------------
#                      getSGAInfo
#  
#--------------------------------------------------------
sub getSGAInfo
{ 
   my ($SGAInfoID) = @_;  
   if ("$gOracleVersion" == "8i" || "$gOracleVersion" == "9i")
   {
     $gHLists[$SGAInfoID]{'query'}=qq{SELECT name,
					     TO_CHAR(value/1024/1024,'999,999,999.00')  MB,
						     TO_CHAR(value,'999,999,999,999')  value
				      FROM v\$sga
				      UNION
				      SELECT '____ Total SGA ____',
					     TO_CHAR(SUM(value)/1024/1024,'999,999,999.00') MB,
					     TO_CHAR(SUM(value),'999,999,999,999')  value
				      FROM v\$sga 
				      UNION
				      SELECT name,
					     TO_CHAR(value/1024/1024,'999,999,999.00')  MB,
					     TO_CHAR(value,'999,999,999,999')  value
				      FROM v\$parameter
				      WHERE name IN ('java_pool_size',
						     'large_pool_size', 
						     'sga_max_size' ,
						     'shared_pool_size',
						     'shared_pool_reserved_size')
				      UNION
				      SELECT pool  ||' '|| name ,
					     TO_CHAR(sum(bytes)/1024/1024,'999,999,999.00') MB,
					     TO_CHAR(sum(bytes),'999,999,999,999')  value
				      FROM v\$sgastat
				      WHERE name='free memory'
				      GROUP BY pool ||' '||name 
				      };
	   }
   else
   {
     $gHLists[$SGAInfoID]{'query'}=qq{SELECT name,
					     TO_CHAR(bytes/1024/1024,'999,999,999.00') MB,
					     TO_CHAR(bytes,'999,999,999,999') value
				     FROM v\$sgainfo
				     UNION
				    SELECT INITCAP(pool) || ' ' || INITCAP(name),
					    TO_CHAR(bytes/1024/1024,'999,999,999.00') MB,
					    TO_CHAR(bytes,'999,999,999,999') value
				     FROM v\$sgastat
				     WHERE name='free memory' };
				     };
   displayWindow($SGAInfoID);  
}
#///////////////////////////////////////////////////////////////////////////// 

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#                               Generic subs

#--------------------------------------------------------
#                      columnIndex
#  Retrieves the index of the designated column for
# the HLIist ID that is passed to the sub
#--------------------------------------------------------
sub columnIndex
{
   my ($HListID, $columnName) = @_;
   
   my $maxColumnIndex = $#{$gHLists[$HListID]{'columns'}};
    
   foreach my $column ( 0 .. $maxColumnIndex) 
   { 
      if ( $gHLists[$HListID]{'columns'}[$column] eq uc($columnName) ||
           $gHLists[$HListID]{'columns'}[$column] eq lc($columnName)
          )
      { 
	  return $column;
      }
   }
   return undef;
}

#--------------------------------------------------------
#                    displayMsg
#  
#--------------------------------------------------------
sub displayMsg
{
   my ($type,$tlSource,$title,$message) = @_; 
   ${$tlSource}->bell();
   my $response = ${$tlSource}->Dialog(-title => $title, 
				   -text => $message, 
				   -buttons => ['OK'], 
				   -default_button => 'OK', 
				   -font => '-adobe-helvetica-bold-r-narrow--12-120',
				   -bitmap => $type 
				   )->Show( );
}

#--------------------------------------------------------
#                    displayOption
#  
#--------------------------------------------------------
sub displayOption
{
   my ($tlSource,$title,$message) = @_; 
   ${$tlSource}->bell();
   my $response = ${$tlSource}->Dialog(-title => $title, 
				   -text => $message, 
				   -buttons => ['OK','NO'], 
				   -default_button => 'NO', 
				   -font => '-adobe-helvetica-bold-r-narrow--12-120',
				   -bitmap => 'question' 
				   )->Show( );
}



#--------------------------------------------------------
#                    displayWindow
#   
#--------------------------------------------------------
sub displayWindow
{
   my ($HListID) = @_;
   my $inSIDs = "";
   my $sql="";
   # Get the name of the HList widget 
   my $HListName = $gHLists[$HListID]{'name'};
   #  If the HList query depends upon selections in a
   # parent window then retreive the selected column
   # values. If no selections have been made then
   # exit the program
   if ( $gHLists[$HListID]{'windowType'} == $gCHILD)
   {
       my @sids = selections($HListID,"sid"); 
       if (@sids)
       {
	 $inSIDs = join(',',@sids); 
       }  
       else  
       {  
	   displayMsg($gERROR,"winMain","Selection Error","No selections have been made."); 
	  return undef;
       }
   }
   
   #  Get the top level object where the HList
   # is being created. If it doesn't already
   # exist then create it and its HList.
   my $tlHList = $gHLists[$HListID]{'parent'};  
   if (! Exists(${$tlHList})) 
   {
     ${$tlHList} = $winMain->Toplevel( );
     ${$tlHList}->Button(-text => "Close", 
		         -command => sub { ${$tlHList}->withdraw }
		        )->pack( -pady => 5);  
     
      buildHList($HListID); 
     # my $widget = ${$HListName}->headerCget(0,-widget);
     # $widget->configure(-command => "doNothing");
   } 
   else 
   {
     ${$tlHList}->deiconify( );
     ${$tlHList}->raise( );
   }      
   
  
   # Clear out all data currently displayed in the HList
   ${$HListName}->delete('all');
   
   # Set the title of the HList window and the global variables 
   # for the Oracle version and the ArcSDE version
   ${$tlHList}->title( "$gHLists[$HListID]{'title'} on $gdbSessions");
   if ($HListID == $gSESSIONS)
   {
	if (my $sth = $gdbhSessionDB->prepare( "SELECT banner FROM v\$version WHERE ROWNUM < 2" ))
	{
	    $sth->execute(); 
	    my ($banner);
	    $sth->bind_columns(undef,\$banner);
	    $sth->fetch();
	    $banner =~ s/64bi$/64 bit/;
	    ${$tlHList}->title( "$gHLists[$HListID]{'title'} on $gdbSessions ... $banner"); 
	    
	    $gOracleVersion ="0";
	    switch ($banner)
	    {
		case m/10g/ {$gOracleVersion = "10g";}
		case m/9i/  {$gOracleVersion = "9i";}
		case m/8i/  {$gOracleVersion = "8i";}
	    }
	}
	if (my $sth = $gdbhSessionDB->prepare( "SELECT major FROM sde.version" ))
	{
	    $sth->execute(); 
	    my ($version);
	    $sth->bind_columns(undef,\$version);
	    $sth->fetch();
	    $gSDEVersion = $version;
	}
   } 
    #  Get the SQL query for sessions and pop in the 
    # ORDER BY column If the HList is a child window
    # then pop in the list of selected SIDS
    if ( $gHLists[$HListID]{'windowType'} == $gCHILD)
    {
      ($sql = $gHLists[$HListID]{'query'}) =~ s/varSIDs/$inSIDs/;
    }
    else
    {
      $sql = $gHLists[$HListID]{'query'}; 
    } 
     #print "HListID=$HListID\n";
     
    $sql =~ s/varOrderBy/$gHLists[$HListID]{'orderBy'}/; 
    
    if ($gDEBUG)
    {
      print "sql=$sql\n";
    }
    
    # We make a special exception in the display of the 
    # user list because we do some special color coding
    # for the type and account status of the users.
    # All the other HList displays are the same format.
    if ($HListID != $gUSERS)
    {
	my $rowCount= 0;
	if ($HListID == $gOBJECT_DEFINITION || $HListID == $gSQL_FULL_TEXT )
	{
	    $gdbhSessionDB->{LongReadLen} = 1000 * 1024; 
	}
	#  Execute the query and populate the HList
	# or display an error if the query fails.
	if (my $sth = $gdbhSessionDB->prepare( $sql ))
	{
	    $sth->execute();     
	    my @row = (); 
	    while (@row = $sth->fetchrow_array)
	    {  
	       ${$HListName}->add(++$i,
				  -text => $row[0] ,
				  -data => $row[0] 
				  );  
	       foreach my $column(1 .. $#row)
	       {
		 ${$HListName}->itemCreate($i, 
					   $column, 
					   -text => $row[$column] 
					   ); 
	       }   
	       $rowCount++;  
	    }  
	}
	else
	{
	    displayMsg($gERROR, $tlHList,"Window Display Error",$DBI::errstr);  
	}
	$gTotalRows[$HListID] = "Total Rows:    $rowCount";
    }
    else
    {
      displayUserList($HListID,$sql);
    }
}


#--------------------------------------------------------
#                   refreshDisplay 
#  Clears out the display and repopulates it
#--------------------------------------------------------
sub refreshDisplay 
{ 
  my ($HListID) = @_;
  
  #  Get the name of the HList and clear out the 
  # data currently displayed 
  my $HListName = $gHLists[$HListID]{'name'};
  if (Exists(${$HListName})) 
  {
     ${$HListName}->delete(all);  
  }
  
  # Display the new data
  displayWindow($HListID);  
}


#--------------------------------------------------------
#                      selectAll
#  Loops through all the HList entries and selects them
#--------------------------------------------------------
sub selectAll
{
  # Get the HList ID passed to the sub
  my ($HListID) = @_;
  my $HListName = $gHLists[$HListID]{'name'};  
  
 #  Since HList entries are re-numbered by an
 # internal counter whenever you delete and 
 # add entries, loop until you find the first
 # entry and then loop again until all existing
 # entries are selected.
  my $row = 0;
  while(! ${$HListName}->info('exists',$row))
  {
    $row++; 
  }
  while(${$HListName}->info('exists',$row))
  {
    ${$HListName}->selectionSet($row);
    $row++; 
  }
   
}

#--------------------------------------------------------
#                      selections
#  
#--------------------------------------------------------
sub selections
{
   # Get the HList ID that was passed to the sub
   my ($HListID, $columnName) = @_; 
   my @columnValues = ();  
   #  Get the parent HList that is the source of selections 
   # to build the query for the child HList
   my $selectionSource = $gHLists[$HListID]{'selectionSource'};
   my $hlstSelections = $gHLists[$selectionSource]{'name'}; 
   
  # print "searching $hlstSelections for the column $columnName\n";
  
   # Get the SID column for the parent HList
   my $column = columnIndex($selectionSource,$columnName);
   
  # print "found column index of $column \n";
  
   # If the column name is not found in the parent HList, 
   # return an empty array
   if ( ! defined $column)
   {
      print "-----> $columnName does NOT exist in $hlstSelections\n";
      return ();
   }
   
   #  Find out if any selections have been made and
   # if not then return an empty array, otherwise
   # process the selections and return an array of the
   # column values that are found.
   my @selectedIndices = ${$hlstSelections}->info('selection'); 
  # print "@selectedIndices\n";
   if (! @selectedIndices)
   {
      return ();
   }
   else
   {  
       #  Generate and return an array of the column values for 
       # the  selected rows
       foreach my $row (@selectedIndices) 
       {  
	  my $value = ${$hlstSelections}->itemCget($row,$column, '-text') ;
	  push(@columnValues,$value);
       }        
       return @columnValues;
   }
}


#--------------------------------------------------------
#                   sendToEditor
#  
#--------------------------------------------------------
sub sendToEditor
{
    # Get the ID of the HList widget and the array of 
    # indices that were selected
    my ($HListID,@selectedIndices) = @_;  
    # Get the name of the HList widget 
    my $HListName = $gHLists[$HListID]{'name'};
    
    # If there are no selections passed to the sub then check
    # for any selections on the HList widget
    if (! @selectedIndices)
    {
      @selectedIndices = ${$HListName}->info('selection'); 
    }
    
    # If no selections were found then display an error message
    if (! @selectedIndices)
    {
       displayMsg($gERROR,$HListName,"Selection Error","Nothing has been selected to send to the editor");
    }
    else
    {
	#  Get the program and file that the HList widget uses to output
	#  the selected data and build the output command
	my $programID = $gHLists[$HListID]{'outputProgram'};
	my $outputFile = $gHLists[$HListID]{'outputFile'};
	(my $command = $gOutput[$programID]{'command'}) =~ s/varOutputFile/$outputFile/;  
	
	# Get the index count of the columns that are being sent to the output file
	my $maxColumnIndex = $#{$gHLists[$HListID]{'outputColumns'}};
	 
	#print "input = $HListName @selectedIndices output = $programID  $command $maxColumnIndex \n";
	
	open (OUTPUT_FILE,">$outputFile");
	
	# If the output program is Excel then spit out the headers first
	if ($gHLists[$HListID]{'outputProgram'} == $gEXCEL)
	{ 
	   foreach my $column ( 0 .. $maxColumnIndex) 
	   {  
	   # ( my $excelColumn = $gHLists[$HListID]{'headers'}[$column] ) =~ s/\,//g;
	     print OUTPUT_FILE "  $gHLists[$HListID]{'headers'}[$column]";
	     print OUTPUT_FILE "|";
	   }
	    print OUTPUT_FILE "\n";  
        }
	
	# Print all the data to the output file
	foreach my $row (@selectedIndices) 
	{   
	   foreach my $column ( 0 .. $maxColumnIndex) 
	   {  
	      my $data = ${$HListName}->itemCget($row, $gHLists[$HListID]{'outputColumns'}[$column], -text);
	      print OUTPUT_FILE "$data ";
	      
	      # If the output program is Excel then slap a comma on the end of every column
	      if ($gHLists[$HListID]{'outputProgram'} == $gEXCEL)
	      {
	        print OUTPUT_FILE "|";
	      }
	   }
	   # Put a return after the row of data
	   print OUTPUT_FILE "\n";
	}
	# All data has been output so close the file
	close OUTPUT_FILE;    
	 
	# Launch the output program 
	Win32::Process::Create($ProcessObj,
			       $gOutput[$programID]{'exePath'}, 
			       $command,
				0,
			       NORMAL_PRIORITY_CLASS,
				"."
			       )|| die errorReport(); 
			       
	while ( $ProcessObj->Wait( 1000 ) )
	{
	   sleep(1);     
	}
	my $ExitCode;
	my $ReturnVal = 0;
	$ProcessObj->GetExitCode( $ExitCode );
	if ( $ExitCode != 0 )      
	{       
	    $ReturnVal = 1;      
	}  
    }
}


#--------------------------------------------------------
#                   errorReport
#  
#--------------------------------------------------------
sub errorReport
{
    print Win32::FormatMessage( Win32::GetLastError() );
}

#--------------------------------------------------------
#                    sortData
#  
#--------------------------------------------------------
sub sortData
{
  # Get the HList ID and column number passed to the sub
  my ($HListID,$col) = @_;
  
  # Toggle the sort order 
  if ($gHLists[$HListID]{'sortOrder'} eq "ASC")
  {
    $gHLists[$HListID]{'sortOrder'} = "DESC"
  }
  else
  {
    $gHLists[$HListID]{'sortOrder'} = "ASC";
  }
 
   # Set the ORDER BY column to the column that the user clicked  
  $gHLists[$HListID]{'orderBy'} = "$gHLists[$HListID]{'columns'}[$col] $gHLists[$HListID]{'sortOrder'}";  
  
  #  Get the HList name and the index of the last 
  # column of the HList
  my $HListName=  $gHLists[$HListID]{'name'};
  my $maxColumnIndex = $#{$gHLists[$HListID]{'columns'}};
  
  # Set the color of all the column headers to LightGrey
  foreach my $column ( 0 .. $maxColumnIndex )
  {
     my $widget = ${$HListName}->headerCget($column,-widget);
     $widget->configure(-background => 'LightGrey');
  }
  
  # Set the color of the clicked column header to SeaGreen3
  my $widget =  ${$HListName}->headerCget($col,-widget);
  $widget->configure(-background => 'SeaGreen3');
  
  #  Refresh the display based upon the new ORDER BY column
   &refreshDisplay($HListID); 
}

#--------------------------------------------------------
#                   SQLPlus
#  
#--------------------------------------------------------
sub SQLPlus
{	
    my $pwd=&getPassword($gdbSessions,$gUserName);  
    $pwd=trim($pwd);
    my $login = " $gUserName/$pwd\@$gdbSessions";
   (my $command = $gOutput[$gSQL_PLUS]{'command'}) =~ s/varLogin/$login/;    
    # Launch the output program 
    Win32::Process::Create($ProcessObj,
			   $gOutput[$gSQL_PLUS]{'exePath'}, 
			   $command,
			    0,
			   NORMAL_PRIORITY_CLASS,
			    "."
			   )|| die errorReport(); 
			   
    while ( $ProcessObj->Wait( 1000 ) )
    {
       sleep(1);     
    }
    my $ExitCode;
    my $ReturnVal = 0;
    $ProcessObj->GetExitCode( $ExitCode );
    if ( $ExitCode != 0 )      
    {       
	$ReturnVal = 1;      
    }  
}

sub trim
{
	my ($string) = @_;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
#--------------------------------------------------------
#                       showSQL
#  
#--------------------------------------------------------
sub showSQL
{	
    # Get the ID of the HList widget  
    my ($HListID) = @_;  
    # Get the name of the HList widget 
    my $HListName = $gHLists[$HListID]{'name'};
    my $sql = $gHLists[$HListID]{'query'};
    
   
    my $outputFile = "SQL_$HListName.sql";
    open (OUTPUT_FILE,">$outputFile");
    print OUTPUT_FILE $sql; 
    # All data has been output so close the file
    close OUTPUT_FILE;    
    
   (my $command = $gOutput[$gSQL_DEV]{'command'}) =~ s/varOutputFile/$outputFile/;   
    # Launch the output program 
    Win32::Process::Create($ProcessObj,
			   $gOutput[$gSQL_DEV]{'exePath'}, 
			   $command,
			    0,
			   NORMAL_PRIORITY_CLASS,
			    "."
			   )|| die errorReport(); 
			   
    while ( $ProcessObj->Wait( 1000 ) )
    {
       sleep(1);     
    }
    my $ExitCode;
    my $ReturnVal = 0;
    $ProcessObj->GetExitCode( $ExitCode );
    if ( $ExitCode != 0 )      
    {       
	$ReturnVal = 1;      
    }  
}


#--------------------------------------------------------
#                       showHourGlass
#  
#--------------------------------------------------------
sub showHourGlass
{	
   my ($HListID) = @_;   
   # Get the name of the HList widget 
   my $HListName = $gHLists[$HListID]{'name'}; 
   ${$HListName}->configure(-cursor=>'watch');
   ${$HListName}->update;
   
}

#--------------------------------------------------------
#                       removeHourGlass
#  
#--------------------------------------------------------
sub removeHourGlass
{	
   my ($HListID) = @_;   
   # Get the name of the HList widget 
   my $HListName = $gHLists[$HListID]{'name'}; 
   ${$HListName}->configure(-cursor=>'top_left_arrow');
   #${$HListName}->update;
   
}


#--------------------------------------------------------
#                       displaySharedPoolChart
#  
#--------------------------------------------------------
sub displaySharedPoolChart
{ 
   my $sharedPoolComponents = {};
   $tlChart->destroy if Tk::Exists($tlChart);
 #  if (! Exists($tlChart)) 
 #  {
    $tlChart = $winMain->Toplevel( );
    $tlChart->Button(-text => "Close", 
                             -command => sub { $tlChart->withdraw }
                             )->pack( -pady => 5);  
    my $btnRefresh =$tlChart->Button(-text => 'Refresh',
					     -font => '-adobe-helvetica-bold-r-narrow--12-120',
					     -command => sub { &displaySharedPoolChart}
					     )->pack(-side => 'right',
						   -pady => 10,
						   -padx => 10
						   );  
 #  }
 #  else 
 #  {
 #    $tlChart->deiconify( );
 #    $tlChart->raise( );
 #    $tlChart->delete(all);  
 #  }    
   
   my $dbh = DBI->connect('dbi:Chart:'); 
   
   my $SQL = qq{SELECT INITCAP(name) name, round(bytes/(1024*1024),2) bytes
                FROM v\$sgastat
                    WHERE pool = 'shared pool'
                      AND round(bytes/(1024*1024),2) >= 1
                         ORDER BY INITCAP(name)
               };
   if (my $sth = $gdbhSessionDB->prepare($SQL))
   { 
     $sth->execute();   
     $dbh->do('CREATE TABLE bars (name CHAR(20), bytes DECIMAL)');
     my $sthMem = $dbh->prepare('INSERT INTO bars VALUES( ?, ?)');
 
     my @row = (); 
     while (@row = $sth->fetchrow_array)
     {     
       $sthMem->execute($row[0],$row[1]);
       print "$row[0]  =$row[1]\n";
     }
   }
    
   my $rsth = $dbh->prepare("SELECT BARCHART FROM bars 
			     WHERE WIDTH=800 AND HEIGHT=500 AND X-AXIS=\'Name\' AND
			     Y-AXIS=\'Megabytes\' AND TITLE = \'Shared Pool Components >= 1MB\' AND 
			     FORMAT='GIF' AND
			     SHOWVALUES=1 AND SHOWGRID=1  
			     AND BACKGROUND='transparent'");
                                                    
                                                    #AND SHOWGRID=1  
                                                    # X-ORIENT='VERTICAL' AND
   $rsth->execute;
   $rsth->bind_col(1, \$buf);
   $rsth->fetch; 
   my $sga = $tlChart->Photo(-data => $buf, -format => 'GIF');
   my $chart =  $tlChart->Label(-image => $sga)->pack(-side  =>'right',
                                                   -fill  =>'both',
                                                   -expand=>1);
  
}


sub displaySharedPoolChart_old
{
    
    my $memory = {};
    my $maxMem = 0;
    my $sql= qq{SELECT INITCAP(name) AS name,
		        mb
		 FROM
		      (SELECT name,
			      ROUND(bytes /(1024*1024), 3) mb
		       FROM v\$sgastat
		       WHERE pool = 'shared pool'
		       AND bytes /(1024 *1024) >= 1)
		 ORDER BY mb DESC
	        };  
 
    if (my $sth = $gdbhSessionDB->prepare( $sql ))
    {
	$sth->execute();     
	my @row = (); 
	while (@row = $sth->fetchrow_array)
	{  
	   #foreach my $column(0 .. $#row)
	  # {
	      #print "$row[0]\n";
	      #print "$row[1]\n";
	      if ( $row[1] > $maxMem)
	      {
	          $maxMem = $row[1];
	      }  
	      $memory->{$row[0]} =$row[1];
	  # }    
	}  
    }
    else
    {
	displayMsg($gERROR, $tlChart,"Window Display Error",$DBI::errstr);  
    }
    
    my $chartMax = int($maxMem) - ($maxMem % 10) + 10;
    my $chartXticks = $chartMax/10;
    print "int $maxMem = $chartMax  $chartXticks\n";
    
    my $jp = 'java pool mem';
    my $data = {
        Sleep   => 51,
        Work    => 135,
        Access  => 124,
        mySQL   => 5
        };
    
	$data->{$jp} = '34';
	
    my $tlChart ="tlSharedPoolChart";
    if (! Exists($tlChart)) 
    {
     $tlChart = $winMain->Toplevel( );
     $tlChart->Button(-text => "Close", 
		         -command => sub { $tlChart->withdraw }
		        )->pack( -pady => 5);  
    }
    else 
    {
      $tlChart->deiconify( );
      $tlChart->raise( );
    }    
    
    my $count = keys %$memory;
    my $topPadding = ((int($count/10)) * 20) + 5;
    if ($topPadding == 5)
    {
      $topPadding = 20;
    }
    print "count = $count top padding = $topPadding\n---------------------------------\n";
    my $sharedPoolChart= $tlChart->Graph( -type => 'HBARS', 
				     -width => 700,           
				     -height => 500,
				     -lineheight => 15,
				    # -padding => [$topPadding,50,20,150],
				     -barwidth => 15,
				     -xtick => $chartXticks,
				     -ytick => $chartXticks,
				     -max => $chartMax, 
				     -printvalue => '%s %.2f' 
                                         )->pack( -expand => 1,
                                                   -fill => 'both',
                                                 );
						  
   #$sharedPoolChart->configure(-variable => $memory);     # bind to data
   $sharedPoolChart->set($memory);
   $sharedPoolChart->redraw();
}


#--------------------------------------------------------
#                       displaySelectedTableColumns
#  
#--------------------------------------------------------
sub displaySelectedTableColumns
{	
    my ($HListID) = @_;   
    print "HListID for displaySelectedTableColumns = $HListID\n";
    my $tlHList = $gHLists[$gTABLE_COLUMNS]{'parent'};  
    if (Exists(${$tlHList}))  
    {  
      ${$tlHList}->destroy(); 
    }  
    
    my $owner = "";
    my @owners = selections($HListID,"owner"); 
    if (@owners)
    {
      $owner = $owners[0];
      $owner =~ s/\s+$//; #remove trailing spaces
    }  
    else  
    {  
	displayMsg($gERROR,"winMain","Selection Error","No selections have been made."); 
	return undef;
    }
    my $table_name = "";
	my 	@tableNames = ();
	
   switch ($HListID)
   { 
      case [ $gTBLSPC_OBJS,$gDATAFILE_OBJS,$gUSER_OBJS,$gDATABASE_OBJS ]
      {   
	    @tableNames = selections($HListID,"obj_name");    
      }
      case [$gDBA_OBJECTS ]
      {  
	    @tableNames = selections($HListID,"object_name");   
      } 
    }
    
    if (@tableNames)
    {
      $table_name = $tableNames[0];
      $table_name =~ s/\s+$//; #remove trailing spaces
    }  
    else  
    {  
	displayMsg($gERROR,"winMain","Selection Error","No selections have been made."); 
	return undef;
    }
   print "owner = $owner and table = $table_name\n";
   my $sql= qq{SELECT RPAD(owner,40),
		      RPAD(table_name,40),
		      RPAD(column_name,40),
		      data_type,
		      data_length,
		      DECODE(data_precision,NULL,\' \',\'(\'||data_precision||\',\'||data_scale||\')\') data_precision_scale, 
		      internal_column_id
		FROM dba_tab_cols 
	        WHERE owner = UPPER(\'$owner\')
	          AND table_name = UPPER(\'$table_name\')
		  AND column_name NOT LIKE \'SYS%$\'
	        ORDER BY varOrderBy
	      };  
 
   $gHLists[$gTABLE_COLUMNS]{'query'} = $sql;
   #print "query = $gHLists[$gTABLE_COLUMNS]{'query'}\n";
   $gHLists[$gTABLE_COLUMNS]{'title'} = "Columns in table $owner.$table_name";
   # Create a button to kill the selected users' sessions
   my $HListName = $gHLists[$gTABLE_COLUMNS]{'name'};
   $HListParent = $gHLists[$gTABLE_COLUMNS]{'parent'};
   #print "name = $HListName parent = $HListParent\n";
   #my $tableButton = ${$HListParent}->Button();
   #my $b = $HListParent->Button( -text => 'Hit me!')->pack;
   #$HListParent->configure(-menu => $mnuBar = $HListParent->Menu);	
   displayWindow($gTABLE_COLUMNS);   
    
}

#--------------------------------------------------------
#                       displaySelectedTable
#  
#--------------------------------------------------------
sub displaySelectedTable
{	
   
    my ($HListID) = @_; 
    
    my $tlHList = $gHLists[$gDISPLAY_TABLE]{'parent'};  
    if (Exists(${$tlHList}))  
    {  
      ${$tlHList}->destroy(); 
    }  
    
   # Get the name of the HList widget 
    my $HListName = $gHLists[$HListID]{'name'}; 
   print "hlistId = $HListID name = $HListName\n";
   #${$HListName}->update;
    my $owner = "";
    my @owners = selections($HListID,"owner"); 
    if (@owners)
    {
      $owner = $owners[0];
      $owner =~ s/\s+$//; #remove trailing spaces
    }  
    else  
    {  
	displayMsg($gERROR,"winMain","Selection Error","No selections have been made."); 
	return undef;
    }
   
    my $table_name = "";
    my @table_names = selections($HListID,"table_name"); 
    if (@table_names)
    {
      $table_name = $table_names[0];
      $table_name =~ s/\s+$//; #remove trailing spaces
    }  
    else  
    {  
	displayMsg($gERROR,"winMain","Selection Error","No selections have been made."); 
	return undef;
    }
    
    @columnNames = ();
    print "owner = $owner and table = $table_name\n";
    my @column_names = selections($HListID,"column_name"); 
    if (@column_names)
    {
      foreach my $column_name ( @column_names ) 
      {
	$column_name =~ s/\s+$//; #remove trailing spaces
        push(@columnNames, "\"$column_name\"");
      }
    }  
    else  
    {  
	displayMsg($gERROR,"winMain","Selection Error","No selections have been made."); 
	return undef;
    }
    print "column names = @columnNames\n";
    
    $gHLists[$gDISPLAY_TABLE]{'query'} = sprintf "SELECT %s 
				       FROM %s.%s
				       ORDER BY 1", join(',', @columnNames), $owner, $table_name;

     print "query = $gHLists[$gDISPLAY_TABLE]{'query'}\n";
   
   
    $gHLists[$gDISPLAY_TABLE]{'columns'} = [@columnNames];
     print "columns = $gHLists[$gDISPLAY_TABLE]{'columns'}[0]\n";
    $gHLists[$gDISPLAY_TABLE]{'headers'} = [@columnNames];  
    $gHLists[$gDISPLAY_TABLE]{'title'} = "$owner.$table_name";
 
    
    displayWindow($gDISPLAY_TABLE);
}



