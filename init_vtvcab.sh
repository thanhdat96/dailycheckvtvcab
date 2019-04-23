#########################################
# Version 1.2							
# Update: 								
#	- Fix script dailycheck_wec.sql		
#	- Fix script checkos.sh	
# Update 28/2
#	- Tail alert log
#	- Check FRA			
#	- Check CRS
#	- Bo remove file
#########################################

# add .bash_profile entry
cat >> $HOME/.bash_profile <<EOF
OSWREPORT=`pwd`/report; export OSWREPORT
OSWHOME=`pwd`; export OSWHOME
EOF
. $HOME/.bash_profile
echo "Added environment variables to "$HOME/.bash_profile"!"
#create awr.sql
echo "set serveroutput on" >> awr.sql
echo " " >> awr.sql
echo "create or replace directory AWR_DIR as '"$OSWHOME"/logcheck/awr';" >> awr.sql
echo "prompt Runing AWR general by snap_id..." >> awr.sql
echo " " >> awr.sql
echo "declare" >> awr.sql
echo "	l_file			UTL_FILE.file_type;" >> awr.sql
echo "	l_min_snap_id 	number;" >> awr.sql
echo "	l_max_snap_id 	number;" >> awr.sql
echo "	l_dbid 			number;" >> awr.sql
echo "	l_instance_name varchar2(50);" >> awr.sql
echo "	l_awr_name		varchar2(100); " >> awr.sql
echo "	l_date 			varchar2(20);" >> awr.sql
echo " " >> awr.sql
echo " cursor get_cursor(p_snap_id dba_hist_snapshot.snap_id%type) is" >> awr.sql
echo " select startup_time,to_char(begin_interval_time,'yyyy_mm_dd_hh24_mi') " >> awr.sql
echo " from dba_hist_snapshot" >> awr.sql
echo "where snap_id = p_snap_id; " >> awr.sql
echo " " >> awr.sql
echo " current_startup_time	dba_hist_snapshot.startup_time%type; " >> awr.sql
echo " next_startup_time	dba_hist_snapshot.startup_time%type; " >> awr.sql
echo " l_begin_interval		varchar2(30);" >> awr.sql
echo " " >> awr.sql
echo "begin" >> awr.sql
echo " " >> awr.sql
echo "--select min(snap_id) into l_min_snap_id from dba_hist_snapshot where to_char(BEGIN_INTERVAL_TIME,'yyyy_mm_dd')='2013_03_11';" >> awr.sql
echo "--select max(snap_id) into l_max_snap_id from dba_hist_snapshot where to_char(BEGIN_INTERVAL_TIME,'yyyy_mm_dd')='2013_03_11';" >> awr.sql
echo " " >> awr.sql
echo "select min(snap_id) into l_min_snap_id from dba_hist_snapshot where to_char(BEGIN_INTERVAL_TIME,'yyyy_mm_dd')=to_char(sysdate-1,'yyyy_mm_dd'); " >> awr.sql
echo "select max(snap_id) into l_max_snap_id from dba_hist_snapshot where to_char(BEGIN_INTERVAL_TIME,'yyyy_mm_dd')=to_char(sysdate,'yyyy_mm_dd'); " >> awr.sql
echo " " >> awr.sql
echo " " >> awr.sql
echo "for ints in (select gd.dbid,gi.inst_id,gi.instance_name from gv\$instance gi,gv\$database gd where gi.inst_id=gd.inst_id) loop " >> awr.sql
echo " for i in l_min_snap_id..l_max_snap_id-1 loop" >> awr.sql
echo " " >> awr.sql
echo "	open get_cursor(i);" >> awr.sql
echo "		fetch get_cursor into current_startup_time,l_begin_interval; " >> awr.sql
echo "	close get_cursor;" >> awr.sql
echo "	open get_cursor(i+1);" >> awr.sql
echo "		fetch get_cursor into next_startup_time,l_begin_interval;" >> awr.sql
echo "	close get_cursor;" >> awr.sql
echo " " >> awr.sql
echo "		 if ( current_startup_time = next_startup_time) then " >> awr.sql
echo "		 	begin" >> awr.sql
echo "		 		 " >> awr.sql
echo "			begin" >> awr.sql
echo "		 		l_awr_name:='awr_'||ints.instance_name||'_'||ints.inst_id||'_'|| i || '_' || (i+1) || '_'||l_begin_interval||'.html';" >> awr.sql
echo "				 		l_file := UTL_FILE.fopen('AWR_DIR',l_awr_name, 'w', 32767);" >> awr.sql
echo "		 					for l_awrrpt in (select output from table (DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_HTML(ints.dbid,ints.inst_id,i,i+1))) loop " >> awr.sql
echo "								utl_file.put_line(l_file, l_awrrpt.output);" >> awr.sql
echo "		 					end loop;" >> awr.sql
echo "		 				utl_file.fclose(l_file); " >> awr.sql
echo "		 			end; " >> awr.sql
echo "		 		 " >> awr.sql
echo "		 	end; " >> awr.sql
echo "		 end if; " >> awr.sql
echo " end loop; " >> awr.sql
echo "end loop;" >> awr.sql
echo "Exception" >> awr.sql
echo "when others then " >> awr.sql
echo " RAISE_APPLICATION_ERROR(-20101,'Check date format or no value min/max!'); " >> awr.sql
echo "end; " >> awr.sql
echo "/" >> awr.sql
chmod +x $OSWHOME/awr.sql

#create checkos.sh

#create checkos.sh
gridhome=`cat /etc/oratab | grep ASM |sed -r 's/[:]+/ /g' | tail -n 1 | awk '{print $2}'`
echo $gridhome
sqlplus -s / as sysdba > tabs << EOF
SET SERVEROUTPUT ON
SET FEEDBACK OFF
DECLARE
   adrloc VARCHAR2(1000);
BEGIN
   SELECT value INTO adrloc
   FROM v\$diag_info where name='Diag Trace';

   DBMS_OUTPUT.PUT_LINE(adrloc);
END;
/
EXIT
EOF

adrloc=`cat tabs`
echo $adrloc

echo "export OSWHOME="$OSWHOME" " >> checkos.sh
echo "df -h > $OSWHOME/logcheck/logOS/1_1.txt " >> checkos.sh
echo "uname -r > $OSWHOME/logcheck/logOS/1_2.txt " >> checkos.sh
echo "free -m > $OSWHOME/logcheck/logOS/1_3.txt " >> checkos.sh
echo "cat /proc/cpuinfo | grep processor | wc -l > $OSWHOME/logcheck/logOS/1_4.txt " >> checkos.sh
echo "cat /etc/fstab > $OSWHOME/logcheck/logOS/1_5.txt " >> checkos.sh
echo "lsnrctl status > $OSWHOME/logcheck/logOS/2_1.txt " >> checkos.sh
echo "cp $adrloc/alert*.log $OSWHOME/logcheck/logOS/2_2.txt" >> checkos.sh
echo "$gridhome/bin/crsctl check crs > $OSWHOME/logcheck/logOS/3_1.txt">> checkos.sh
echo "$gridhome/bin/crsctl stat res -t > $OSWHOME/logcheck/logOS/3_2.txt">> checkos.sh
chmod +x $OSWHOME/checkos.sh
echo "export OSWHOME="$OSWHOME" " >> backupalert.sh
echo "mv $adrloc/alert*.log $adrloc/\`date +%Y_%m_%d_%H%M\`_alert.log" >> backupalert.sh
echo "Created "$OSWHOME/backupalert.sh"!"
chmod 755 $OSWHOME/backupalert.sh
# Add to crontab
crontab -l > crontmp
echo "00 00 * * * "$OSWHOME/backupalert.sh " >> $OSWHOME/backupalert.log 2>&1" >> crontmp
crontab crontmp
echo "Added entry to crontab!"
#create dailycheck_wec
echo "REM =====================================================================  " >> dailycheck_wec.sql
echo "REM  " >> dailycheck_wec.sql
echo "REM Script: Dailycheck_WEC.sql  " >> dailycheck_wec.sql
echo "REM Purpose: Generate Excel readable Database Daily Check Status " >> dailycheck_wec.sql
echo "REM Author : Wecommit .,JSC  " >> dailycheck_wec.sql
echo "REM  " >> dailycheck_wec.sql
echo "REM =====================================================================  " >> dailycheck_wec.sql
echo "SET ECHO OFF " >> dailycheck_wec.sql
echo "SET FEED OFF " >> dailycheck_wec.sql
echo "SET TERM OFF " >> dailycheck_wec.sql
echo "SET RECSEP OFF " >> dailycheck_wec.sql
echo "SET VERIFY OFF " >> dailycheck_wec.sql
echo "SET HEADING OFF  " >> dailycheck_wec.sql
echo "SET PAGES 0  " >> dailycheck_wec.sql
echo "SET LINES 20000 " >> dailycheck_wec.sql
echo "SET TRIMSPOOL ON " >> dailycheck_wec.sql
echo "SET SERVEROUTPUT ON  " >> dailycheck_wec.sql
echo " " >> dailycheck_wec.sql
echo "COLUMN 	db_name	NEW_VALUE	db_name  " >> dailycheck_wec.sql
echo "COLUMN	run_date	NEW_VALUE	run_date " >> dailycheck_wec.sql
echo "COLUMN	run_date2	NEW_VALUE	run_date2	 " >> dailycheck_wec.sql
echo " " >> dailycheck_wec.sql
echo "SELECT to_char(sysdate, 'DD-Mon-YYYY') run_date, to_char(sysdate, 'YYYY_MM_DD') run_date2  " >> dailycheck_wec.sql
echo "FROM dual; " >> dailycheck_wec.sql
echo "select name db_name from v\$database; " >> dailycheck_wec.sql
echo " " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/1_1.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "select instance_name||'#_#' || host_name||'#_#' || archiver||'#_#' || thread#||'#_#' || status " >> dailycheck_wec.sql
echo "from gv\$instance;  " >> dailycheck_wec.sql
echo "SPOOL OFF  " >> dailycheck_wec.sql
echo " " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/1_3.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "select name||'#_#' ||path||'#_#' ||group_number||'#_#' ||header_status||'#_#' ||total_mb||'#_#' ||free_mb from v\$asm_disk; " >> dailycheck_wec.sql
echo "SPOOL OFF  " >> dailycheck_wec.sql
echo " " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/2_2_1.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "select group_number||'#_#' ||name||'#_#' ||block_size||'#_#' ||allocation_unit_size||'#_#' ||type||'#_#' ||total_mb||'#_#' ||free_mb from v\$asm_diskgroup " >> dailycheck_wec.sql
echo "order by group_number; " >> dailycheck_wec.sql
echo "SPOOL OFF " >> dailycheck_wec.sql
echo " " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/2_2_2.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "select d.group_number||'#_#' ||g.name||'#_#' || d.disk_number||'#_#' || d.name||'#_#' || d.path||'#_#' || d.os_mb " >> dailycheck_wec.sql
echo "||'#_#' ||d.total_mb||'#_#' || " >> dailycheck_wec.sql
echo "d.free_mb||'#_#' ||d.read_errs ||'#_#' ||d.write_errs from v\$asm_disk d inner join v\$asm_diskgroup g  " >> dailycheck_wec.sql
echo "on d.group_number=g.group_number " >> dailycheck_wec.sql
echo "order by d.group_number, d.disk_number;  " >> dailycheck_wec.sql
echo "SPOOL OFF  " >> dailycheck_wec.sql
echo " " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_1_1.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "select * from v\$version; " >> dailycheck_wec.sql
echo "SPOOL OFF  " >> dailycheck_wec.sql
echo " " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_1_2.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "select name from v\$database; " >> dailycheck_wec.sql
echo "SPOOL OFF  " >> dailycheck_wec.sql
echo "  " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_1_4.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "select " >> dailycheck_wec.sql
echo "( select sum(bytes)/1024/1024/1024 data_size from dba_data_files ) + " >> dailycheck_wec.sql
echo "( select nvl(sum(bytes),0)/1024/1024/1024 temp_size from dba_temp_files ) +  " >> dailycheck_wec.sql
echo "( select sum(bytes)/1024/1024/1024 redo_size from sys.v_\$log ) + " >> dailycheck_wec.sql
echo "( select sum(BLOCK_SIZE*FILE_SIZE_BLKS)/1024/1024/1024 controlfile_size from v\$controlfile) \"Size in GB\" " >> dailycheck_wec.sql
echo "from " >> dailycheck_wec.sql
echo "dual;  " >> dailycheck_wec.sql
echo "SPOOL OFF  " >> dailycheck_wec.sql
echo "  " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_1_5.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "           set lines 290 " >> dailycheck_wec.sql
echo "		   select tablespace_name  ||'#_#' || max_ts_pct_used ||'#_#' || max_ts_size ||'#_#' || used_ts_size ||'#_#' ||  curr_ts_size ||'#_#' || ts_pct_used ||'#_#' || free_ts_size    from (  ">> dailycheck_wec.sql
echo "		   SELECT df.tablespace_name tablespace_name,                                      ">> dailycheck_wec.sql
echo "        max(df.autoextensible) auto_ext,                                                 ">> dailycheck_wec.sql
echo "        round(df.maxbytes / (1024 * 1024), 2) max_ts_size,                               ">> dailycheck_wec.sql
echo "        round((df.bytes - sum(fs.bytes)) / (df.maxbytes) * 100, 2) max_ts_pct_used,      ">> dailycheck_wec.sql
echo "        round(df.bytes / (1024 * 1024), 2) curr_ts_size,                                 ">> dailycheck_wec.sql
echo "        round((df.bytes - sum(fs.bytes)) / (1024 * 1024), 2) used_ts_size,               ">> dailycheck_wec.sql
echo "        round((df.bytes-sum(fs.bytes)) * 100 / df.bytes, 2) ts_pct_used,                 ">> dailycheck_wec.sql
echo "        round(sum(fs.bytes) / (1024 * 1024), 2) free_ts_size,                            ">> dailycheck_wec.sql
echo "        nvl(round(sum(fs.bytes) * 100 / df.bytes), 2) ts_pct_free                        ">> dailycheck_wec.sql
echo "       FROM dba_free_space fs,                                                           ">> dailycheck_wec.sql
echo "        (select tablespace_name,                                                         ">> dailycheck_wec.sql
echo "        sum(bytes) bytes,                                                                ">> dailycheck_wec.sql
echo "        sum(decode(maxbytes, 0, bytes, maxbytes)) maxbytes,                              ">> dailycheck_wec.sql
echo "        max(autoextensible) autoextensible                                               ">> dailycheck_wec.sql
echo "        from dba_data_files                                                              ">> dailycheck_wec.sql
echo "        group by tablespace_name) df                                                     ">> dailycheck_wec.sql
echo "       WHERE fs.tablespace_name (+) = df.tablespace_name                                 ">> dailycheck_wec.sql
echo "       GROUP BY df.tablespace_name, df.bytes, df.maxbytes                                ">> dailycheck_wec.sql
echo "       UNION ALL                                                                         ">> dailycheck_wec.sql
echo "       SELECT df.tablespace_name tablespace_name,                                        ">> dailycheck_wec.sql
echo "        max(df.autoextensible) auto_ext,                                                 ">> dailycheck_wec.sql
echo "        round(df.maxbytes / (1024 * 1024), 2) max_ts_size,                               ">> dailycheck_wec.sql
echo "        round((df.bytes - sum(fs.bytes)) / (df.maxbytes) * 100, 2) max_ts_pct_used,      ">> dailycheck_wec.sql
echo "        round(df.bytes / (1024 * 1024), 2) curr_ts_size,                                 ">> dailycheck_wec.sql
echo "        round((df.bytes - sum(fs.bytes)) / (1024 * 1024), 2) used_ts_size,               ">> dailycheck_wec.sql
echo "        round((df.bytes-sum(fs.bytes)) * 100 / df.bytes, 2) ts_pct_used,                 ">> dailycheck_wec.sql
echo "        round(sum(fs.bytes) / (1024 * 1024), 2) free_ts_size,                            ">> dailycheck_wec.sql
echo "        nvl(round(sum(fs.bytes) * 100 / df.bytes), 2) ts_pct_free                        ">> dailycheck_wec.sql
echo "       FROM (select tablespace_name, bytes_used bytes                                    ">> dailycheck_wec.sql
echo "        from V\$temp_space_header                                                         ">> dailycheck_wec.sql
echo "        group by tablespace_name, bytes_free, bytes_used) fs,                            ">> dailycheck_wec.sql
echo "        (select tablespace_name,                                                         ">> dailycheck_wec.sql
echo "        sum(bytes) bytes,                                                                ">> dailycheck_wec.sql
echo "        sum(decode(maxbytes, 0, bytes, maxbytes)) maxbytes,                              ">> dailycheck_wec.sql
echo "        max(autoextensible) autoextensible                                               ">> dailycheck_wec.sql
echo "        from dba_temp_files                                                              ">> dailycheck_wec.sql
echo "        group by tablespace_name) df                                                     ">> dailycheck_wec.sql
echo "       WHERE fs.tablespace_name (+) = df.tablespace_name                                 ">> dailycheck_wec.sql
echo "       GROUP BY df.tablespace_name, df.bytes, df.maxbytes                                ">> dailycheck_wec.sql
echo "       ORDER BY 1);                                                                      ">> dailycheck_wec.sql
echo "SPOOL OFF  " >> dailycheck_wec.sql
echo " " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_2_1.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "select value from v\$parameter where name='spfile'; " >> dailycheck_wec.sql
echo "SPOOL OFF  " >> dailycheck_wec.sql
echo "  " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_2_2.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "SELECT Group#||'#_#' ||Thread#||'#_#' ||Sequence#||'#_#' ||bytes||'#_#' ||Blocksize||'#_#' ||members " >> dailycheck_wec.sql
echo "||'#_#' ||archived||'#_#' ||status||'#_#' ||First_change#||'#_#' || " >> dailycheck_wec.sql
echo "First_time||'#_#' ||Next_change#||'#_#' ||Next_time FROM V\$LOG; " >> dailycheck_wec.sql
echo "SPOOL OFF  " >> dailycheck_wec.sql
echo "  " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_2_3.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "SELECT " >> dailycheck_wec.sql
echo "to_char(first_time,'YYYY-MON-DD')||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'00',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'01',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'02',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'03',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'04',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'05',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'06',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'07',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'08',1,0)),'9999') ||'#_#' ||  " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'09',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'10',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'11',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'12',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'13',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'14',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'15',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'16',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'17',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'18',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'19',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'20',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'21',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'22',1,0)),'9999') ||'#_#' || " >> dailycheck_wec.sql
echo "to_char(sum(decode(to_char(first_time,'HH24'),'23',1,0)),'9999')   " >> dailycheck_wec.sql
echo "from " >> dailycheck_wec.sql
echo "v\$log_history  " >> dailycheck_wec.sql
echo "where first_time >= trunc (sysdate - 1)  " >> dailycheck_wec.sql
echo "GROUP by " >> dailycheck_wec.sql
echo "to_char(first_time,'YYYY-MON-DD'); " >> dailycheck_wec.sql
echo "SPOOL OFF  " >> dailycheck_wec.sql
echo " " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_2_4.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "select group#||'#_#' || status||'#_#' || type||'#_#' || member||'#_#' || IS_RECOVERY_DEST_FILE from v\$logfile; " >> dailycheck_wec.sql
echo "SPOOL OFF " >> dailycheck_wec.sql
echo " " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_3_1.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "select to_char (start_time, 'DD-MON-RR HH24:MI:SS')  " >> dailycheck_wec.sql
echo "||'#_#' ||output_device_type " >> dailycheck_wec.sql
echo "||'#_#' ||input_type " >> dailycheck_wec.sql
echo "||'#_#' ||status " >> dailycheck_wec.sql
echo "||'#_#' ||input_bytes_display  " >> dailycheck_wec.sql
echo "||'#_#' ||output_bytes_display " >> dailycheck_wec.sql
echo "||'#_#' ||time_taken_display " >> dailycheck_wec.sql
echo "from v\$rman_backup_job_details " >> dailycheck_wec.sql
echo " where start_time >= trunc (sysdate - 14)  " >> dailycheck_wec.sql
echo "order by start_time desc;  " >> dailycheck_wec.sql
echo "SPOOL OFF  " >> dailycheck_wec.sql
echo " " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_3_3.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "select count(block#) " >> dailycheck_wec.sql
echo "||'#_#' ||case count (block#) " >> dailycheck_wec.sql
echo " when 0 then 'No corrupted block'  " >> dailycheck_wec.sql
echo " else count (block#) " >> dailycheck_wec.sql
echo " || ' corrupted blocks need to check carefully'  " >> dailycheck_wec.sql
echo " end   " >> dailycheck_wec.sql
echo "from v\$database_block_corruption;  " >> dailycheck_wec.sql
echo "SPOOL OFF  " >> dailycheck_wec.sql
echo " " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_4_1.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "select owner||'#_#' || job_name||'#_#' || STATE||'#_#' || start_date " >> dailycheck_wec.sql
echo "||'#_#' || repeat_interval||'#_#' || LAST_START_DATE||'#_#' || LAST_RUN_DURATION||'#_#' || " >> dailycheck_wec.sql
echo "NEXT_RUN_DATE from DBA_SCHEDULER_JOBS;  " >> dailycheck_wec.sql
echo "SPOOL OFF  " >> dailycheck_wec.sql
echo "  " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_5_1.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "/* Formatted on 2/15/2019 4:07:04 PM (QP5 v5.256.13226.35538) */ " >> dailycheck_wec.sql
echo "WITH schema_object " >> dailycheck_wec.sql
echo "     AS (  SELECT /*+MATERIALIZE NO_MERGE/ / 2b.191 */ " >> dailycheck_wec.sql
echo "                 segment_type, " >> dailycheck_wec.sql
echo "                  owner, " >> dailycheck_wec.sql
echo "                  segment_name, " >> dailycheck_wec.sql
echo "                  tablespace_name, " >> dailycheck_wec.sql
echo "                  COUNT (*) segments, " >> dailycheck_wec.sql
echo "                  SUM (extents) extents, " >> dailycheck_wec.sql
echo "                  SUM (blocks) blocks, " >> dailycheck_wec.sql
echo "                  SUM (bytes) bytes " >> dailycheck_wec.sql
echo "             FROM dba_segments " >> dailycheck_wec.sql
echo "            WHERE 'Y' = 'Y' " >> dailycheck_wec.sql
echo "         GROUP BY segment_type, " >> dailycheck_wec.sql
echo "                  owner, " >> dailycheck_wec.sql
echo "                  segment_name, " >> dailycheck_wec.sql
echo "                  tablespace_name), " >> dailycheck_wec.sql
echo "     totals " >> dailycheck_wec.sql
echo "     AS (SELECT /*+MATERIALIZE NO_MERGE/ / 2b.191 */ " >> dailycheck_wec.sql
echo "               SUM (segments) segments, " >> dailycheck_wec.sql
echo "                SUM (extents) extents, " >> dailycheck_wec.sql
echo "                SUM (blocks) blocks, " >> dailycheck_wec.sql
echo "                SUM (bytes) bytes " >> dailycheck_wec.sql
echo "           FROM schema_object), " >> dailycheck_wec.sql
echo "     top_200_pre " >> dailycheck_wec.sql
echo "     AS (SELECT /*+MATERIALIZE NO_MERGE/ / 2b.191 */ " >> dailycheck_wec.sql
echo "               ROWNUM RANK, v1.* " >> dailycheck_wec.sql
echo "           FROM (  SELECT so.segment_type, " >> dailycheck_wec.sql
echo "                          so.owner, " >> dailycheck_wec.sql
echo "                          so.segment_name, " >> dailycheck_wec.sql
echo "                          so.tablespace_name, " >> dailycheck_wec.sql
echo "                          so.segments, " >> dailycheck_wec.sql
echo "                          so.extents, " >> dailycheck_wec.sql
echo "                          so.blocks, " >> dailycheck_wec.sql
echo "                          so.bytes, " >> dailycheck_wec.sql
echo "                          ROUND ( (so.segments / t.segments) * 100, 3) " >> dailycheck_wec.sql
echo "                             segments_perc, " >> dailycheck_wec.sql
echo "                          ROUND ( (so.extents / t.extents) * 100, 3) " >> dailycheck_wec.sql
echo "                             extents_perc, " >> dailycheck_wec.sql
echo "                          ROUND ( (so.blocks / t.blocks) * 100, 3) blocks_perc, " >> dailycheck_wec.sql
echo "                          ROUND ( (so.bytes / t.bytes) * 100, 3) bytes_perc " >> dailycheck_wec.sql
echo "                     FROM schema_object so, totals t " >> dailycheck_wec.sql
echo "                 ORDER BY bytes_perc DESC NULLS LAST) v1 " >> dailycheck_wec.sql
echo "          WHERE ROWNUM < 201), " >> dailycheck_wec.sql
echo "     top_200 " >> dailycheck_wec.sql
echo "     AS (SELECT p.*, " >> dailycheck_wec.sql
echo "                (SELECT object_id " >> dailycheck_wec.sql
echo "                   FROM dba_objects o " >> dailycheck_wec.sql
echo "                  WHERE     o.object_type = p.segment_type " >> dailycheck_wec.sql
echo "                        AND o.owner = p.owner " >> dailycheck_wec.sql
echo "                        AND o.object_name = p.segment_name " >> dailycheck_wec.sql
echo "                        AND o.object_type NOT LIKE '%PARTITION%') " >> dailycheck_wec.sql
echo "                   object_id, " >> dailycheck_wec.sql
echo "                (SELECT data_object_id " >> dailycheck_wec.sql
echo "                   FROM dba_objects o " >> dailycheck_wec.sql
echo "                  WHERE     o.object_type = p.segment_type " >> dailycheck_wec.sql
echo "                        AND o.owner = p.owner " >> dailycheck_wec.sql
echo "                        AND o.object_name = p.segment_name " >> dailycheck_wec.sql
echo "                        AND o.object_type NOT LIKE '%PARTITION%') " >> dailycheck_wec.sql
echo "                   data_object_id, " >> dailycheck_wec.sql
echo "                (SELECT SUM (p2.bytes_perc) " >> dailycheck_wec.sql
echo "                   FROM top_200_pre p2 " >> dailycheck_wec.sql
echo "                  WHERE p2.RANK <= p.RANK) " >> dailycheck_wec.sql
echo "                   bytes_perc_cum " >> dailycheck_wec.sql
echo "           FROM top_200_pre p), " >> dailycheck_wec.sql
echo "     top_200_totals " >> dailycheck_wec.sql
echo "     AS (SELECT /*+MATERIALIZE NO_MERGE/ / 2b.191 */ " >> dailycheck_wec.sql
echo "               SUM (segments) segments, " >> dailycheck_wec.sql
echo "                SUM (extents) extents, " >> dailycheck_wec.sql
echo "                SUM (blocks) blocks, " >> dailycheck_wec.sql
echo "                SUM (bytes) bytes, " >> dailycheck_wec.sql
echo "                SUM (segments_perc) segments_perc, " >> dailycheck_wec.sql
echo "                SUM (extents_perc) extents_perc, " >> dailycheck_wec.sql
echo "                SUM (blocks_perc) blocks_perc, " >> dailycheck_wec.sql
echo "                SUM (bytes_perc) bytes_perc " >> dailycheck_wec.sql
echo "           FROM top_200), " >> dailycheck_wec.sql
echo "     top_100_totals " >> dailycheck_wec.sql
echo "     AS (SELECT /*+MATERIALIZE NO_MERGE/ / 2b.191 */ " >> dailycheck_wec.sql
echo "               SUM (segments) segments, " >> dailycheck_wec.sql
echo "                SUM (extents) extents, " >> dailycheck_wec.sql
echo "                SUM (blocks) blocks, " >> dailycheck_wec.sql
echo "                SUM (bytes) bytes, " >> dailycheck_wec.sql
echo "                SUM (segments_perc) segments_perc, " >> dailycheck_wec.sql
echo "                SUM (extents_perc) extents_perc, " >> dailycheck_wec.sql
echo "                SUM (blocks_perc) blocks_perc, " >> dailycheck_wec.sql
echo "                SUM (bytes_perc) bytes_perc " >> dailycheck_wec.sql
echo "           FROM top_200 " >> dailycheck_wec.sql
echo "          WHERE RANK < 101), " >> dailycheck_wec.sql
echo "     top_20_totals " >> dailycheck_wec.sql
echo "     AS (SELECT /*+MATERIALIZE NO_MERGE/ / 2b.191 */ " >> dailycheck_wec.sql
echo "               SUM (segments) segments, " >> dailycheck_wec.sql
echo "                SUM (extents) extents, " >> dailycheck_wec.sql
echo "                SUM (blocks) blocks, " >> dailycheck_wec.sql
echo "                SUM (bytes) bytes, " >> dailycheck_wec.sql
echo "                SUM (segments_perc) segments_perc, " >> dailycheck_wec.sql
echo "                SUM (extents_perc) extents_perc, " >> dailycheck_wec.sql
echo "                SUM (blocks_perc) blocks_perc, " >> dailycheck_wec.sql
echo "                SUM (bytes_perc) bytes_perc " >> dailycheck_wec.sql
echo "           FROM top_200 " >> dailycheck_wec.sql
echo "          WHERE RANK < 21) " >> dailycheck_wec.sql
echo "SELECT v.RANK ||'#_#' || " >> dailycheck_wec.sql
echo "       v.segment_type ||'#_#' || " >> dailycheck_wec.sql
echo "       v.owner||'#_#' || " >> dailycheck_wec.sql
echo "       v.segment_name||'#_#' || " >> dailycheck_wec.sql
echo "       v.object_id||'#_#' || " >> dailycheck_wec.sql
echo "       v.data_object_id||'#_#' || " >> dailycheck_wec.sql
echo "       v.tablespace_name||'#_#' || " >> dailycheck_wec.sql
echo "       CASE " >> dailycheck_wec.sql
echo "          WHEN v.segment_type LIKE 'INDEX%' " >> dailycheck_wec.sql
echo "          THEN " >> dailycheck_wec.sql
echo "             (SELECT i.table_name " >> dailycheck_wec.sql
echo "                FROM dba_indexes i " >> dailycheck_wec.sql
echo "               WHERE i.owner = v.owner AND i.index_name = v.segment_name) " >> dailycheck_wec.sql
echo "          WHEN v.segment_type LIKE 'LOB%' " >> dailycheck_wec.sql
echo "          THEN " >> dailycheck_wec.sql
echo "             (SELECT l.table_name " >> dailycheck_wec.sql
echo "                FROM dba_lobs l " >> dailycheck_wec.sql
echo "               WHERE l.owner = v.owner AND l.segment_name = v.segment_name) " >> dailycheck_wec.sql
echo "       END " >> dailycheck_wec.sql
echo "          ||'#_#' || " >> dailycheck_wec.sql
echo "       v.segments||'#_#' || " >> dailycheck_wec.sql
echo "       v.extents||'#_#' || " >> dailycheck_wec.sql
echo "       v.blocks||'#_#' || " >> dailycheck_wec.sql
echo "       v.bytes||'#_#' || " >> dailycheck_wec.sql
echo "       ROUND (v.bytes / POWER (10, 9), 3)||'#_#' || " >> dailycheck_wec.sql
echo "       LPAD (TO_CHAR (v.segments_perc, '990.000'), 7)||'#_#' || " >> dailycheck_wec.sql
echo "       LPAD (TO_CHAR (v.extents_perc, '990.000'), 7)||'#_#' || " >> dailycheck_wec.sql
echo "       LPAD (TO_CHAR (v.blocks_perc, '990.000'), 7) ||'#_#' || " >> dailycheck_wec.sql
echo "       LPAD (TO_CHAR (v.bytes_perc, '990.000'), 7)||'#_#' || " >> dailycheck_wec.sql
echo "       LPAD (TO_CHAR (v.bytes_perc_cum, '990.000'), 7) perc_cum " >> dailycheck_wec.sql
echo "  FROM (SELECT d.RANK, " >> dailycheck_wec.sql
echo "               d.segment_type, " >> dailycheck_wec.sql
echo "               d.owner, " >> dailycheck_wec.sql
echo "               d.segment_name, " >> dailycheck_wec.sql
echo "               d.object_id, " >> dailycheck_wec.sql
echo "               d.data_object_id, " >> dailycheck_wec.sql
echo "               d.tablespace_name, " >> dailycheck_wec.sql
echo "               d.segments, " >> dailycheck_wec.sql
echo "               d.extents, " >> dailycheck_wec.sql
echo "               d.blocks, " >> dailycheck_wec.sql
echo "               d.bytes, " >> dailycheck_wec.sql
echo "               d.segments_perc, " >> dailycheck_wec.sql
echo "               d.extents_perc, " >> dailycheck_wec.sql
echo "               d.blocks_perc, " >> dailycheck_wec.sql
echo "               d.bytes_perc, " >> dailycheck_wec.sql
echo "               d.bytes_perc_cum " >> dailycheck_wec.sql
echo "          FROM top_200 d " >> dailycheck_wec.sql
echo "        UNION ALL " >> dailycheck_wec.sql
echo "        SELECT TO_NUMBER (NULL) RANK, " >> dailycheck_wec.sql
echo "               NULL segment_type, " >> dailycheck_wec.sql
echo "               NULL owner, " >> dailycheck_wec.sql
echo "               NULL segment_name, " >> dailycheck_wec.sql
echo "               TO_NUMBER (NULL), " >> dailycheck_wec.sql
echo "               TO_NUMBER (NULL), " >> dailycheck_wec.sql
echo "               'TOP20' tablespace_name, " >> dailycheck_wec.sql
echo "               st.segments, " >> dailycheck_wec.sql
echo "               st.extents, " >> dailycheck_wec.sql
echo "               st.blocks, " >> dailycheck_wec.sql
echo "               st.bytes, " >> dailycheck_wec.sql
echo "               st.segments_perc, " >> dailycheck_wec.sql
echo "               st.extents_perc, " >> dailycheck_wec.sql
echo "               st.blocks_perc, " >> dailycheck_wec.sql
echo "               st.bytes_perc, " >> dailycheck_wec.sql
echo "               TO_NUMBER (NULL) bytes_perc_cum " >> dailycheck_wec.sql
echo "          FROM top_20_totals st " >> dailycheck_wec.sql
echo "        UNION ALL " >> dailycheck_wec.sql
echo "        SELECT TO_NUMBER (NULL) RANK, " >> dailycheck_wec.sql
echo "               NULL segment_type, " >> dailycheck_wec.sql
echo "               NULL owner, " >> dailycheck_wec.sql
echo "               NULL segment_name, " >> dailycheck_wec.sql
echo "               TO_NUMBER (NULL), " >> dailycheck_wec.sql
echo "               TO_NUMBER (NULL), " >> dailycheck_wec.sql
echo "               'TOP 100' tablespace_name, " >> dailycheck_wec.sql
echo "               st.segments, " >> dailycheck_wec.sql
echo "               st.extents, " >> dailycheck_wec.sql
echo "               st.blocks, " >> dailycheck_wec.sql
echo "               st.bytes, " >> dailycheck_wec.sql
echo "               st.segments_perc, " >> dailycheck_wec.sql
echo "               st.extents_perc, " >> dailycheck_wec.sql
echo "               st.blocks_perc, " >> dailycheck_wec.sql
echo "               st.bytes_perc, " >> dailycheck_wec.sql
echo "               TO_NUMBER (NULL) bytes_perc_cum " >> dailycheck_wec.sql
echo "          FROM top_100_totals st " >> dailycheck_wec.sql
echo "        UNION ALL " >> dailycheck_wec.sql
echo "        SELECT TO_NUMBER (NULL) RANK, " >> dailycheck_wec.sql
echo "               NULL segment_type, " >> dailycheck_wec.sql
echo "               NULL owner, " >> dailycheck_wec.sql
echo "               NULL segment_name, " >> dailycheck_wec.sql
echo "               TO_NUMBER (NULL), " >> dailycheck_wec.sql
echo "               TO_NUMBER (NULL), " >> dailycheck_wec.sql
echo "               'TOP 200' tablespace_name, " >> dailycheck_wec.sql
echo "               st.segments, " >> dailycheck_wec.sql
echo "               st.extents, " >> dailycheck_wec.sql
echo "               st.blocks, " >> dailycheck_wec.sql
echo "               st.bytes, " >> dailycheck_wec.sql
echo "               st.segments_perc, " >> dailycheck_wec.sql
echo "               st.extents_perc, " >> dailycheck_wec.sql
echo "               st.blocks_perc, " >> dailycheck_wec.sql
echo "               st.bytes_perc, " >> dailycheck_wec.sql
echo "               TO_NUMBER (NULL) bytes_perc_cum " >> dailycheck_wec.sql
echo "          FROM top_200_totals st " >> dailycheck_wec.sql
echo "        UNION ALL " >> dailycheck_wec.sql
echo "        SELECT TO_NUMBER (NULL) RANK, " >> dailycheck_wec.sql
echo "               NULL segment_type, " >> dailycheck_wec.sql
echo "               NULL owner, " >> dailycheck_wec.sql
echo "               NULL segment_name, " >> dailycheck_wec.sql
echo "               TO_NUMBER (NULL), " >> dailycheck_wec.sql
echo "               TO_NUMBER (NULL), " >> dailycheck_wec.sql
echo "               'TOTAL' tablespace_name, " >> dailycheck_wec.sql
echo "               t.segments, " >> dailycheck_wec.sql
echo "               t.extents, " >> dailycheck_wec.sql
echo "               t.blocks, " >> dailycheck_wec.sql
echo "               t.bytes, " >> dailycheck_wec.sql
echo "               100 segemnts_perc, " >> dailycheck_wec.sql
echo "               100 extents_perc, " >> dailycheck_wec.sql
echo "               100 blocks_perc, " >> dailycheck_wec.sql
echo "               100 bytes_perc, " >> dailycheck_wec.sql
echo "               TO_NUMBER (NULL) bytes_perc_cum " >> dailycheck_wec.sql
echo "          FROM totals t) v; " >> dailycheck_wec.sql
echo "SPOOL OFF  " >> dailycheck_wec.sql
echo "  " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_5_2.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "SELECT owner||'#_#' || index_name||'#_#' || tablespace_name  " >> dailycheck_wec.sql
echo "FROM dba_indexes " >> dailycheck_wec.sql
echo "WHERE status = 'UNUSABLE';  " >> dailycheck_wec.sql
echo "SPOOL OFF  " >> dailycheck_wec.sql
echo "  " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_5_3.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "COLUMN object_name FORMAT A30             ">>dailycheck_wec.sql
echo "set lines 200;                            ">>dailycheck_wec.sql
echo "SELECT owner||'#_#' ||                             ">>dailycheck_wec.sql
echo "       object_type||'#_#' ||                       ">>dailycheck_wec.sql
echo "       object_name||'#_#' ||                       ">>dailycheck_wec.sql
echo "       status                             ">>dailycheck_wec.sql
echo "FROM   dba_objects                        ">>dailycheck_wec.sql
echo "WHERE  status = 'INVALID'                 ">>dailycheck_wec.sql
echo "ORDER BY owner, object_type, object_name; ">>dailycheck_wec.sql
echo "SPOOL OFF " >> dailycheck_wec.sql
echo " " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_5_4.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "select FILE_TYPE ||'#_#'|| PERCENT_SPACE_USED from V\$RECOVERY_AREA_USAGE;" >> dailycheck_wec.sql
echo "SPOOL OFF " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_5_5.txt' " >> dailycheck_wec.sql
echo "SPOOL &daily_report  " >> dailycheck_wec.sql
echo "SELECT " >> dailycheck_wec.sql
echo "record_id|| '#_#' || " >> dailycheck_wec.sql
echo "to_char(originating_timestamp,'DD.MM.YYYY HH24:MI:SS')|| '#_#' || " >> dailycheck_wec.sql
echo "message_text " >> dailycheck_wec.sql
echo "FROM " >> dailycheck_wec.sql
echo "	X\$DBGALERTEXT  " >> dailycheck_wec.sql
echo "WHERE originating_timestamp > cast(sysdate -1 as timestamp) order by 1   ;" >> dailycheck_wec.sql
echo "SPOOL OFF " >> dailycheck_wec.sql
echo "DEF daily_report='"$OSWHOME"/logcheck/logDB/3_6_1.txt'                                                                                                                                                  "    >>dailycheck_wec.sql
echo "SPOOL &daily_report   "    >>dailycheck_wec.sql
echo "SELECT NAME ||'#_#' || VALUE ||'#_#' || TIME_COMPUTED FROM V\$DATAGUARD_STATS;  " >>dailycheck_wec.sql
echo "SPOOL OFF    "    >>dailycheck_wec.sql
echo " " >> dailycheck_wec.sql
echo "SET TERM ON  " >> dailycheck_wec.sql
echo "PROMPT " >> dailycheck_wec.sql
echo "PROMPT Generated file: &daily_report " >> dailycheck_wec.sql

chmod 755 $OSWHOME/dailycheck_wec.sql
#-----------------------------------------#
mkdir logcheck
gohusip=`hostname -I | awk '{print $1}'`
echo $gohusip
# create scriptcheck.sh
rm -f $OSWHOME/scriptcheck.sh 2>/dev/null
echo "#!/bin/bash" >> $OSWHOME/scriptcheck.sh
echo "export ORACLE_HOME="$ORACLE_HOME >> $OSWHOME/scriptcheck.sh 
echo "export ORACLE_SID="$ORACLE_SID >> $OSWHOME/scriptcheck.sh
echo "export OSWREPORT="$OSWREPORT >> $OSWHOME/scriptcheck.sh
echo "export OSWHOME="$OSWHOME >> $OSWHOME/scriptcheck.sh
echo "export RPTDATE=1801" >> $OSWHOME/scriptcheck.sh
echo "export gohusip="$gohusip >> $OSWHOME/scriptcheck.sh
echo "export LD_LIBRARY_PATH="$ORACLE_HOME/lib >> $OSWHOME/scriptcheck.sh
echo "mkdir \$OSWHOME/logcheck/logDB" >> $OSWHOME/scriptcheck.sh
echo "mkdir \$OSWHOME/logcheck/awr" >> $OSWHOME/scriptcheck.sh
echo "mkdir \$OSWHOME/logcheck/logOS" >> $OSWHOME/scriptcheck.sh
cat >> $OSWHOME/scriptcheck.sh <<EOF
export PATH=\$ORACLE_HOME/jdk/jre/bin:\$ORACLE_HOME/bin:\$PATH
sqlplus / as sysdba <<EOF
@\$OSWHOME/dailycheck_wec.sql 
@\$OSWHOME/awr.sql 
exit
EOF
echo "EOF" >> $OSWHOME/scriptcheck.sh
cat >> $OSWHOME/scriptcheck.sh <<EOF
cd \$OSWHOME
./checkos.sh
cd \$OSWHOME/logcheck
tar -cvf log_\$ORACLE_SID\_\$gohusip\_\`date +%Y_%m_%d_%H%M\`.tar logDB logOS awr
rm -rf logDB
rm -rf logOS
rm -rf awr
gzip \$OSWHOME/logcheck/log_\$ORACLE_SID\_\$gohusip\_\`date +%Y_%m_%d_%H%M\`.tar
EOF
echo "Created "$OSWHOME/scriptcheck.sh"!"
chmod 755 $OSWHOME/scriptcheck.sh
# Add to crontab
crontab -l > crontmp
echo "0 5 * * * "$OSWHOME/scriptcheck.sh " >> $OSWHOME/scriptcheck.log 2>&1" >> crontmp
crontab crontmp
echo "Added entry to crontab!"

