
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;



CREATE SCHEMA _stat_record;



CREATE TYPE _stat_record.detail_record AS (
	variable text,
	value text
);




CREATE TYPE _stat_record.global_report_record AS (
	col1 text,
	col2 text
);




CREATE FUNCTION _stat_record.delete_record(id bigint) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
declare 
mensaje text;
mensaje_detalle text;
sqlerror text;
begin 
 delete  from _stat_record._record_number where id_record=$1;
 raise notice 'record deleted';
 return  true;
 EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Other error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return false ;
end;$_$;

CREATE OR REPLACE FUNCTION _stat_record.detail_record(id bigint, lim integer DEFAULT 5)
 RETURNS SETOF text
 LANGUAGE plpgsql
AS $function$
declare 
result record ;
mensaje text;
mensaje_detalle text;
sqlerror text;
begin 

  for result in ( select 'id: '||id_record::text ||' -'||description ||' '||'take date: '|| date_take::text from  _stat_record._record_number where id_record=$1 union all select '  --Cluster level--' union all select '  '||var_name||': '||var_val from _stat_record._global_stat where id_record=$1) loop
   RETURN NEXT result ;
  end loop;
   
  for result in ( select '  '||'Users: '|| (select count (*) from _stat_record._global_object where id_record=$1 and object_name='Username'  )::text
               union all
               select '    '||object_val from  _stat_record._global_object  where id_record=$1 and object_name='Username') loop
   RETURN NEXT result ;
  end loop;

  for result in ( select '  '||'Tablespaces: '|| (select count (*) from _stat_record._global_object where id_record=$1 and id_object_type=3  )::text
               union all
               select '    '||object_name||': '||object_val||' '||um from  _stat_record._global_object  where id_record=$1 and id_object_type=3 ) loop
   RETURN NEXT result ;
  end loop;

  for result in ( select '  '||'Databases: '|| (select count (*) from _stat_record._global_object where id_record=$1 and id_object_type=2  )::text
               union all
               select '    '||object_name||': '||object_val||' '||um from  _stat_record._global_object  where id_record=$1 and id_object_type=2 ) loop
   RETURN NEXT result ;
  end loop;


  for result in ( select '  '||'Configuration: '
               union all
               (select '    '||object_name||': '||object_val||' '||um from  _stat_record._global_object  where id_record=$1 and id_object_type=4 order by 1   )) loop
    RETURN NEXT result ;
   end loop;

   for result in ( select '  '|| lim::text ||' Queries with more call: '
               union all
               select '    '||'db: '|| bd||' -- query: ' ||query_text||' -- calls: '||stat_val from ( select * from _stat_record._query_stat where id_Record =$1 order by stat_val::bigint desc )  as sub 
                where id_Record =$1 and stat_name='Statements calls'  limit $2+1 ) loop
    RETURN NEXT result ;
   end loop;

   for result in ( select '  '|| lim::text ||' Queries with more total time: '
               union all
               select '    '||'db: '|| bd||' -- query: ' ||query_text||' -- total_time: '||stat_val ||' ms' from ( select * from _stat_record._query_stat  where id_Record =$1 order by stat_val::numeric desc )  as sub 
                where id_Record =$1 and stat_name='Statements total_time'  limit $2+1 ) loop
    RETURN NEXT result ;
   end loop; 

    for result in ( select '  '|| lim::text ||' Queries with more mean time: '
               union all
               select '    '||'db: '|| bd||' -- query: ' ||query_text||' -- mean_time: '||stat_val ||' ms' from ( select * from _stat_record._query_stat  where id_Record =$1 order by stat_val::numeric desc )  as sub 
                where id_Record =$1 and stat_name='Statements mean_time'  limit $2+1 ) loop
     RETURN NEXT result ;
    end loop;

    for result in ( select '  '|| lim::text ||' Queriess with  max time: '
               union all
               select '    '||'db: '|| bd||' -- query: ' ||query_text||' -- max_time: '||stat_val ||' ms' from ( select * from _stat_record._query_stat where id_Record =$1 order by stat_val::numeric desc )  as sub 
                where id_Record =$1 and stat_name='Statements max_time'  limit $2+1 ) loop
     RETURN NEXT result ;
    end loop;

    for result in ( select '  '|| lim::text ||' Queries with  more row  returned: '
               union all
               select '    '||'db: '|| bd||' -- query: ' ||query_text||' -- rows: '||stat_val  from ( select * from _stat_record._query_stat where id_Record =$1 order by stat_val::numeric desc )  as sub 
                where id_Record =$1 and stat_name='Statements rows'  limit $2+1 ) loop
     RETURN NEXT result ;
    end loop;
    for result in ( select '  '|| lim::text ||' Queries with least cache ratio: '
               union all
               select '    '||'db: '|| bd||' -- query: ' ||query_text||' -- hit_percent: '||stat_val  from ( select * from _stat_record._query_stat where id_Record =$1 order by stat_val::numeric  nulls last )  as sub 
                where id_Record =$1 and stat_name='Statements hit_percent'  limit $2+1 ) loop
     RETURN NEXT result ;
    end loop;

   
    RETURN NEXT '  --Database level--('||(select current_database())||')' ;
    
    for result in ( select '  '||'Schemas: '
               union all
               select '    '||objname ||': '||var_val::text||' '||um from _stat_record._db_stat where id_record=$1 and objtyp='schema' ) loop
     RETURN NEXT result ;
    end loop;

    for result in ( select '  '||'Table count: '|| (select var_val::text from _stat_record._db_stat   where id_record=$1 and var_name='table_count')
               ) loop
     RETURN NEXT result ;
    end loop;

    for result in ( select '  '|| lim::text ||' tables Weigth: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='table' and var_name='Tables weigth' limit $2+1 ) loop
     RETURN NEXT result ;
    end loop;

    for result in ( select '  '|| lim::text ||' tables with more estimated tuples: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='table' and var_name='Tables reltuples' limit $2+1 ) loop
     RETURN NEXT result ;
     end loop;

     for result in ( select '  '|| lim::text ||' most consulted tables: '
               union all
               select '    '|| objname ||': '||total::text  from ( select objname,sum(var_val::bigint)as  total from _stat_record._db_stat where id_Record =$1  and objtyp='table'  and
                (var_name='seq_scan' or var_name='index_scan') group by objname order by 2 desc )  as sub 
                     limit $2+1 ) loop
     RETURN NEXT result ;
    end loop;

    for result in ( select '  '|| lim::text ||' tables with more Inserted tuples: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='table' and var_name='Tables n_tup_ins' limit $2+1 ) loop
     RETURN NEXT result ;
     end loop;

     for result in ( select '  '|| lim::text ||' tables with more Updated tuples: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='table' and var_name='Tables n_tup_upd' limit $2+1 ) loop
     RETURN NEXT result ;
     end loop;

     for result in ( select '  '|| lim::text ||' tables with more Deleted tuples: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='table' and var_name='Tables n_tup_del' limit $2+1 ) loop
     RETURN NEXT result ;
     end loop;

     for result in ( select '  '|| lim::text ||' tables with more Autovacuum: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='maintenance' and var_name='Maintenance autovacuum_count' limit $2+1 ) loop
     RETURN NEXT result ;
     end loop;

      for result in ( select '  '|| lim::text ||' tables with more Manual Vacuum: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='maintenance' and var_name='Maintenance vacuum_count' limit $2+1 ) loop
     RETURN NEXT result ;
     end loop;

     for result in ( select '  '|| lim::text ||' tables with more Auto Analyze: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='maintenance' and var_name='Maintenance autoanalyze_count' limit $2+1 ) loop
     RETURN NEXT result ;
     end loop;

      for result in ( select '  '|| lim::text ||' tables with more Manual Analyze: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='maintenance' and var_name='Maintenance analyze_count' limit $2+1 ) loop
     RETURN NEXT result ;
     end loop;

     for result in ( select '  '|| lim::text ||' indexs Weigth: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='index' and var_name='Indexes index_size' limit $2+1 ) loop
     RETURN NEXT result ;
    end loop;

    for result in ( select '  '|| lim::text ||' indexs used: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='index' and var_name='Indexes times_used' limit $2+1 ) loop
     RETURN NEXT result ;
    end loop;
   
   for result in ( select '  '|| lim::text ||' table bloat: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='bloat' and var_name='table_bloat' limit $2+1 ) loop
     RETURN NEXT result ;
    end loop;
   
    for result in ( select '  '|| lim::text ||' index bloat: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='bloat' and var_name='index_bloat' limit $2+1 ) loop
     RETURN NEXT result ;
    end loop;


   
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Other error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return  ;

 return  ; 
 raise notice 'record detail';
end;
$function$
;


CREATE OR REPLACE FUNCTION _stat_record.export_total_report_record(pid_record_ini bigint, pid_record_last bigint, lim int default 5 , p_file text DEFAULT '/tmp/global_report.csv'::text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
declare 
id bigint;
mensaje text;
mensaje_detalle text;
sqlerror text;
result record ;
cmd text := 'copy (select * from _stat_record.total_report_record('||$1::text||','||$2||','||$3||')   ) to '''||p_file ||''' csv ';
begin 

   execute  cmd;
   return 'Exported successfully to: '||p_file ;
   EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Other error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      
  raise notice 'record global report';
 return 'Error' ; 
		 


end;
$function$
;



CREATE OR REPLACE FUNCTION _stat_record.global_report_record(pid_record_ini bigint, pid_record_last bigint)
 RETURNS SETOF text
 LANGUAGE plpgsql
AS $function$
declare 
id bigint;
mensaje text;
mensaje_detalle text;
sqlerror text;
result text ;
begin 


  for result in  (
		select 'Global report from database server, generate by stat_record extension '
		union all 
		select 'Record id '  ||$1||', taked: '||(select date_take::text from _stat_record._record_number where  id_record=$1)|| ' :->'
		union all
		select '  '||var_name ||': '|| var_val from _stat_record._global_stat where id_record=$1 and   id_var_type in (2,3)
		union all 
		select '  '||'Users:' || count (*)::text from _stat_record._global_object where id_record=$1 and object_name='Username' 
		union all
		select '  '||'Databases: '|| count (*)::text from _stat_record._global_object where id_record=$1 and id_object_type=2  
		union all
		select '  '||'Tablespaces: '|| count (*)::text from _stat_record._global_object where id_record=$1 and id_object_type=3  
		union all
		select '  '||'Tablespaces Names/size: '
		union all
		select  '    '||object_name||': '||object_val||' '||um from _stat_record._global_object where id_record=$1 and id_object_type=3
		union all
		select 'Record id '  ||$2||', taked: '||(select date_take::text from _stat_record._record_number where  id_record=$2)|| ' :->'
		union all
		select '  '||var_name ||': '|| var_val from _stat_record._global_stat where id_record=$2 and   id_var_type in (2,3)
		union all 
		select '  '||'Users: '|| count (*)::text from _stat_record._global_object where id_record=$2 and object_name='Username'  
		union all
		select '  '||'Databases: '|| count (*)::text from _stat_record._global_object where id_record=$2 and id_object_type=2 
		union all
		select '  '||'Tablespaces: '|| count (*)::text from _stat_record._global_object where id_record=$2 and id_object_type=3  
		union all
		select '  '||'Tablespaces Names/size: '
		union all
		select '    '|| object_name||': '||object_val||' '||um from _stat_record._global_object where id_record=$2 and id_object_type=3  
		union all
		select 'Configuration Differences:->'
		union all 
		select * from (select '    '||object_name ||': '|| (select 'id->'||$1::text ||': '|| p.object_val|| ' ----> '|| 'id->'||$1::text|| ': ' ||s.object_val 
				from _stat_record._global_object s 
				where id_record=$2 and p.object_name=s.object_name and s.object_val<>p.object_val ) ||' ' || um as diff  
				from _stat_record._global_object p  where id_record=$1 and id_object_type=4 ) as sub where trim(diff)<>''
		union all 
		select 'Databases Differences:->'
		union all 
		select '    '||var_name ||': '|| (select s.var_val::numeric-p.var_val::numeric from _stat_record._global_stat s where id_record=$2 and p.var_name=s.var_name) ||' ' || um as diff  
		from _stat_record._global_stat p  where id_record=$1 and id_var_type=1 
		union all 
		select '    '||var_name ||': '|| (select pg_size_pretty(pg_wal_lsn_diff(s.var_val::pg_lsn, p.var_val::pg_lsn))  from _stat_record._global_stat s where id_record=$2 and p.var_name=s.var_name) ||' ' || um as diff  
		from _stat_record._global_stat p  where id_record=$1 and var_name ='Wal Location'
		
                
		) 
		loop

		return next result;

   end loop;

   EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Other error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return  ;
  raise notice 'record global report';
 return  ; 
		 


end;
$function$
;



CREATE FUNCTION _stat_record.lastest_records(p_count bigint DEFAULT 1) RETURNS TABLE(id bigint, record_time timestamp without time zone, record_description text)
    LANGUAGE sql
    AS $_$ 
select * from _stat_record._record_number  order by 1 desc  limit $1 ;

$_$;


CREATE OR REPLACE FUNCTION _stat_record.take_record(p_des text DEFAULT ''::text)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
declare 
id bigint;
mensaje text;
mensaje_detalle text;
sqlerror text;
reg record;
so text;
ret int;
begin
	
 --verify retention
 if current_setting('stat_record.retention') <> '' then
   ret:= current_setting('stat_record.retention')::int;
 else
   ret:= 7;
 end if;
 perform _stat_record.delete_record(id_record) from "_stat_record"."_record_number" rn where now()::date-date_take::date >  ret ;

raise notice 'ret: %',ret;
 
	
 INSERT INTO _stat_record._record_number  (date_take,description) values (now(),$1) returning id_record 
 into id;
 ----recording global stat

 --database version
  INSERT INTO _stat_record._global_stat  
  SELECT id,2,'Version server',version(), 'text';
  
  --database startup
  INSERT INTO _stat_record._global_stat
  SELECT id,3,'Server start',pg_postmaster_start_time(), 'timestamp'   ;
  

  --database reload conf
  INSERT INTO _stat_record._global_stat
  SELECT id,3,'Server reload',pg_conf_load_time(), 'timestamp'   ;

   

  --database count 
  INSERT INTO _stat_record._global_stat 
  SELECT  id,1,'Databases count',count(datname),'' from pg_database where  datname not like 'template%' ;
  
  --database zise
  INSERT INTO _stat_record._global_stat 
  SELECT id,1,'Databases sizes',round(sum((pg_database_size(datname)/1024)/1024::numeric),2),'MB'  from pg_database where  datname not like 'template%';
 
  --databases chache ratio
  INSERT INTO _stat_record._global_stat 
  with  sub as ( 
	SELECT round((blks_hit) * 100::numeric / ((blks_read) + (blks_hit))::numeric,2) as hit FROM pg_stat_database where  datname not like 'template%' and blks_read + blks_hit<>0
	)
	select id,1,'Databases chache ratio',round(avg(hit),2),'%' from sub 
	;
 
  --SELECT id,1,'Databases chache ratio',round(sum(blks_hit) * 100 / (sum(blks_read) + sum(blks_hit)),2),'%' FROM pg_stat_database where  datname not like 'template%' and blks_read + blks_hit<>0;

  --databases connections 
  INSERT INTO _stat_record._global_stat  
  SELECT id,1,'Databases connections',sum(numbackends), '' FROM pg_stat_database where  datname not like 'template%' ;
  --databases active/idle in transaction connections 
  INSERT INTO _stat_record._global_stat  
  SELECT id,1,'Databases active connections',count(*),'' from pg_stat_activity where state in ('active','idle in transaction');

  --databases stats 
  with sub as (select sum(xact_commit) cmit,sum(xact_rollback) rback,sum (tup_returned) returned ,sum (tup_fetched) fetched,sum(tup_inserted) inserted,sum(tup_updated) updated ,sum(tup_deleted) deleted,sum(temp_files) tempfiles,
  sum(conflicts) conflicts, sum (deadlocks) deadlocks from pg_stat_database where  datname not like 'template%'),
  
  cm as (INSERT INTO _stat_record._global_stat select id,1,'Databases commit',cmit,'' from sub),
  rb as (INSERT INTO _stat_record._global_stat select id,1,'Databases rollback',rback,'' from sub),
  rt as (INSERT INTO _stat_record._global_stat select id,1,'Databases tuples returned',returned,'' from sub),
  ft as (INSERT INTO _stat_record._global_stat select id,1,'Databases tuples fetched',fetched,'' from sub),
  ins as (INSERT INTO _stat_record._global_stat select id,1,'Databases tuples inserted',inserted,'' from sub),
  upt as (INSERT INTO _stat_record._global_stat select id,1,'Databases tuples updated',updated,'' from sub),
  del as (INSERT INTO _stat_record._global_stat select id,1,'Databases tuples deleted',deleted,'' from sub),
  tmp as  (INSERT INTO _stat_record._global_stat select id,1,'Databases tempfiles',tempfiles,'' from sub),
  con as (INSERT INTO _stat_record._global_stat select id,1,'Databases conflicts',conflicts,'' from sub)
  INSERT INTO _stat_record._global_stat select id,1,'Databases deadlocks',deadlocks,'' from sub
  ;
 
 --BGwriter stats
  with sub as (select * from pg_stat_bgwriter ),
  
  cpt as (INSERT INTO _stat_record._global_stat select id,1,'BGwriter Checkpoints_timed',checkpoints_timed,'' from sub),
  cpr as (INSERT INTO _stat_record._global_stat select id,1,'BGwriter Checkpoints_req',checkpoints_req,'' from sub),
  cpwt as (INSERT INTO _stat_record._global_stat select id,1,'BGwriter Checkpoint_write_time',checkpoint_write_time,'' from sub),
  cpst as (INSERT INTO _stat_record._global_stat select id,1,'BGwriter Checkpoint_sync_time',checkpoint_sync_time,'' from sub),
  bcp as (INSERT INTO _stat_record._global_stat select id,1,'BGwriter Buffers_checkpoint',buffers_checkpoint,'' from sub),
  bc as (INSERT INTO _stat_record._global_stat select id,1,'BGwriter Buffers_clean',buffers_clean,'' from sub),
  mc as (INSERT INTO _stat_record._global_stat select id,1,'BGwriter Maxwritten_clean',maxwritten_clean,'' from sub),
  bb as (INSERT INTO _stat_record._global_stat select id,1,'BGwriter Buffers_backend',buffers_backend,'' from sub),
  bbs as (INSERT INTO _stat_record._global_stat select id,1,'BGwriter Buffers_backend_fsync',buffers_backend_fsync,'' from sub)
  INSERT INTO _stat_record._global_stat select id,1,'BGwriter Buffers_alloc',buffers_alloc,'' from sub
  ;
 
 --WAL
 with sub as ( select pg_current_wal_lsn() as wal_location, pg_walfile_name(pg_current_wal_lsn()) wal_file),
   wl as (INSERT INTO _stat_record._global_stat select id,2,'Wal Location',wal_location,'' from sub)
   INSERT INTO _stat_record._global_stat select id,2,'Wal file',wal_file,'' from sub
 ; 

 ----recording global stat


 ----recording global object

  --users objects
  INSERT INTO _stat_record._global_object
  SELECT id,1,'Username',rolname, '',''  from pg_roles
  join pg_shadow on  (pg_shadow.usesysid=pg_roles.oid ) where pg_roles.rolcanlogin=true  ;
  
  --Database size
  INSERT INTO _stat_record._global_object
  SELECT id,2, datname,round(((pg_database_size(datname)/1024)/1024::numeric),2),'MB',''  from pg_database where  datname not like 'template%'
  order by 1  ;

  --tablespace size
  INSERT INTO _stat_record._global_object
  SELECT id,3, spcname,round(  (pg_tablespace_size(spcname)/1024)/1024,2)  ,'MB', pg_tablespace_location(oid)  FROM pg_tablespace;
  

 ----recording global object


----recording config variables

  --config variables
  INSERT INTO _stat_record._global_object
  SELECT id,4,name,setting, COALESCE(unit,'')   from pg_settings 
  where name in (select config_var_name  from _stat_record._config_var );
  
 

 ----recording config variables

 ----recording querys stats
 --checking pg_stat_statemets
  select * into reg from pg_available_extensions where name ='pg_stat_statements' and installed_version is not null and  position ('pg_stat_statements' in current_setting('shared_preload_libraries') ) >0;
   if found then 
       with sub as (select d.datname,queryid, query, calls, total_time,min_time,max_time,mean_time,stddev_time,rows,100.0 * shared_blks_hit /
               nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent from public.pg_stat_statements  s  join   pg_database d on  (d.oid=s.dbid) ),
  
	  cal as (INSERT INTO _stat_record._query_stat select id,datname,queryid,query,'Statements calls',calls from sub),
	  total as (INSERT INTO _stat_record._query_stat select id,datname,queryid,query,'Statements total_time',total_time from sub),
	  min as (INSERT INTO _stat_record._query_stat select id,datname,queryid,query,'Statements min_time',min_time from sub),
	  max as (INSERT INTO _stat_record._query_stat select id,datname,queryid,query,'Statements max_time',max_time from sub),
	  mean as (INSERT INTO _stat_record._query_stat select id,datname,queryid,query,'Statements mean_time',mean_time from sub),
	  std as (INSERT INTO _stat_record._query_stat select id,datname,queryid,query,'Statements stddev_time',stddev_time from sub),
	  hit as (INSERT INTO _stat_record._query_stat select id,datname,queryid,query,'Statements hit_percent',round(hit_percent,2) from sub)
	  INSERT INTO _stat_record._query_stat select id,datname,queryid,query,'Statements rows',rows from sub
	  ;
 
     
    end if; 
  
 

 ----recording config variables


 ----recording databases  stats object

  --schema size 
  INSERT INTO _stat_record._db_stat 
  SELECT id,1,schemaname,round((SUM(pg_total_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename)))::numeric/1024)/1024,2),'MB','schema', schemaname FROM pg_tables
  where schemaname not in ('information_schema','pg_catalog','_stat_record')
  group by schemaname order by 1;

  --table count 
  INSERT INTO _stat_record._db_stat 
  SELECT id,1,'table_count',count(*),'','table_count','table_count' from pg_tables where schemaname not in ('_stat_record','information_schema','pg_catalog');

 
  --tables stats 
  with sub as (
  SELECT 'table' tab,ns.nspname||'.'|| pg.relname as name , reltuples::int ,round((pg_relation_size(psat.relid::regclass)/1024)/1024::numeric,2) Weigth,n_dead_tup,
		 psat.seq_scan,psat.seq_tup_read,COALESCE( psat.idx_scan,0) as index_scan , COALESCE( psat.idx_tup_fetch,0) as index_fetch,n_tup_ins,n_tup_del,n_tup_upd FROM pg_class pg JOIN 
		 pg_stat_user_tables psat ON (pg.relname = psat.relname)
		join pg_namespace a on ( pg.relnamespace = a.oid)  join pg_namespace ns  on (pg.relnamespace = ns.oid)
		where ns.nspname <>'_stat_record'
		   ORDER BY 2 DESC  ),

   reltuple as (INSERT INTO _stat_record._db_stat select id,1,'Tables reltuples',reltuples,'','table',name from sub),
   wei as (INSERT INTO _stat_record._db_stat select id,1,'Tables weigth',weigth,'MB','table',name from sub),
   dead as (INSERT INTO _stat_record._db_stat select id,1,'Tables  n_dead_tup',n_dead_tup,'','table',name from sub),
   scan as (INSERT INTO _stat_record._db_stat select id,1,'Tables seq_scan',seq_scan,'','table',name from sub),
   seq_read as (INSERT INTO _stat_record._db_stat select id,1,'Tables seq_tup_read',seq_tup_read,'','table',name from sub),
   idx_scan as (INSERT INTO _stat_record._db_stat select id,1,'Tables index_scan',index_scan,'','table',name from sub),
   idx_fetch as (INSERT INTO _stat_record._db_stat select id,1,'Tables index_fetch',index_fetch,'','table',name from sub),
   ins as (INSERT INTO _stat_record._db_stat select id,1,'Tables n_tup_ins',n_tup_ins,'','table',name from sub),
   del as (INSERT INTO _stat_record._db_stat select id,1,'Tables n_tup_del',n_tup_del,'','table',name from sub)
   INSERT INTO _stat_record._db_stat select id,1,'Tables n_tup_upd',n_tup_upd,'','table',name from sub  ;                 
                   
  --index stats 
   with sub as (

   SELECT 'index' idx, idstat.schemaname||'.'||idstat.relname||'.'||indexrelname AS index_name,idstat.idx_scan AS times_used,
                round((pg_relation_size(idstat.indexrelid::regclass)/1024)/1024::numeric,2)  AS index_size
                FROM pg_stat_user_indexes AS idstat  JOIN pg_stat_user_tables AS tabstat ON idstat.relname = tabstat.relname  
                where idstat.schemaname <>'_stat_record' ORDER BY 3 desc ),

  
   use as (INSERT INTO _stat_record._db_stat select id,1,'Indexes times_used',times_used,'','index',index_name from sub)
   INSERT INTO _stat_record._db_stat select id,1,'Indexes index_size',index_size,'MB','index',index_name from sub
   ;                 

   --maintenance stats 
   with sub as (

     SELECT 'maintenance' maintenance, ns.nspname||'.'|| pg.relname as name ,  autovacuum_count,vacuum_count,autoanalyze_count,analyze_count  FROM pg_class pg JOIN pg_stat_user_tables psat ON (pg.relname = psat.relname)  join pg_namespace a on
                 ( pg.relnamespace = a.oid)  join pg_namespace ns  on (pg.relnamespace = ns.oid) 
                 where ns.nspname<>'_stat_record' ORDER BY 2 DESC),
     autovac as (INSERT INTO _stat_record._db_stat select id,1,'Maintenance autovacuum_count',autovacuum_count,'','maintenance',name from sub),
   vac as (INSERT INTO _stat_record._db_stat select id,1,'Maintenance vacuum_count',vacuum_count,'','maintenance',name from sub),             
   autoanalyze as (INSERT INTO _stat_record._db_stat select id,1,'Maintenance autoanalyze_count',autoanalyze_count,'','maintenance',name from sub)
   INSERT INTO _stat_record._db_stat select id,1,'Maintenance analyze_count',analyze_count,'','maintenance',name from sub
   ;                 

 --tables  and indexs bloat
 
  
WITH index_bloat AS (
    SELECT
        current_database(), schemaname, tablename, 
        ROUND((CASE WHEN otta=0 THEN 0.0 ELSE sml.relpages::FLOAT/otta END)::NUMERIC,1) AS tbloat,
        CASE WHEN relpages < otta THEN 0 ELSE bs*(sml.relpages-otta)::BIGINT END AS wastedbytes,
        iname, 
        ROUND((CASE WHEN iotta=0 OR ipages=0 THEN 0.0 ELSE ipages::FLOAT/iotta END)::NUMERIC,1) AS ibloat,
        CASE WHEN ipages < iotta THEN 0 ELSE bs*(ipages-iotta) END AS wastedibytes
    FROM (
        SELECT
            schemaname, tablename, cc.reltuples, cc.relpages, bs,
            CEIL((cc.reltuples*((datahdr+ma-
                (CASE WHEN datahdr%ma=0 THEN ma ELSE datahdr%ma END))+nullhdr2+4))/(bs-20::FLOAT)) AS otta,
            COALESCE(c2.relname,'?') AS iname, COALESCE(c2.reltuples,0) AS ituples, COALESCE(c2.relpages,0) AS ipages,
            COALESCE(CEIL((c2.reltuples*(datahdr-12))/(bs-20::FLOAT)),0) AS iotta
        FROM (
            SELECT
                ma,bs,schemaname,tablename,
                (datawidth+(hdr+ma-(CASE WHEN hdr%ma=0 THEN ma ELSE hdr%ma END)))::NUMERIC AS datahdr,
                (maxfracsum*(nullhdr+ma-(CASE WHEN nullhdr%ma=0 THEN ma ELSE nullhdr%ma END))) AS nullhdr2
            FROM (
                SELECT
                    schemaname, tablename, hdr, ma, bs,
                    SUM((1-null_frac)*avg_width) AS datawidth,
                    MAX(null_frac) AS maxfracsum,
                    hdr+(
                        SELECT 1+COUNT(*)/8
                        FROM pg_stats s2
                        WHERE null_frac<>0 AND s2.schemaname = s.schemaname AND s2.tablename = s.tablename
                    ) AS nullhdr
                FROM pg_stats s, (
                    SELECT
                        (SELECT current_setting('block_size')::NUMERIC) AS bs,
                        CASE WHEN SUBSTRING(v,12,3) IN ('8.0','8.1','8.2') THEN 27 ELSE 23 END AS hdr,
                        CASE WHEN v ~ 'mingw32'  THEN 8 ELSE 4 END AS ma
                    FROM (SELECT version() AS v) AS foo
                ) AS constants
                GROUP BY 1,2,3,4,5
            ) AS foo
        ) AS rs
        JOIN pg_class cc ON cc.relname = rs.tablename
        JOIN pg_namespace nn ON cc.relnamespace = nn.oid AND nn.nspname = rs.schemaname AND nn.nspname <> 'information_schema'
        LEFT JOIN pg_index i ON indrelid = cc.oid
        LEFT JOIN pg_class c2 ON c2.oid = i.indexrelid
    ) AS sml
    ORDER BY wastedibytes DESC), 
    summary as (
SELECT schemaname||'.'|| tablename as name ,round( (wastedbytes/1024)/1024,2) table_bloat, iname, round( (wastedibytes::numeric/1024)/1024,2) as index_bloat
    FROM index_bloat where  schemaname not in  ('pg_catalog','information_schema','_stat_record') ),
    tb as (INSERT INTO _stat_record._db_stat select distinct id,1,'table_bloat',table_bloat,'MB','bloat',name from summary)
    INSERT INTO _stat_record._db_stat select distinct id,1,'index_bloat',index_bloat,'MB','bloat',name||'->'||iname from summary;

 

 ----recording databases  stats object




 
 
 
 raise notice 'record taked';
 return true;

 EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Other error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return false ;
    
end;
$function$
;


CREATE OR REPLACE FUNCTION _stat_record.total_report_for_2last_record(lim integer DEFAULT 5)
 RETURNS SETOF _stat_record.global_report_record
 LANGUAGE plpgsql
AS $function$
declare 
mensaje text;
mensaje_detalle text;
sqlerror text;
result record ;
labels _stat_record.global_report_record;
id1 bigint;
id2 bigint;

begin 
select min(id),max(id) into id1,id2 from _stat_record.lastest_records(2);


   for result in select *,'' from _stat_record.global_report_record(id1,id2) loop
      return next result;
   end loop;
   labels.col1:= 'Detail for id:'||id1;
   labels.col2:= 'Detail for id:'||id2;
   return next labels;
   for result in select _stat_record.detail_record(id1, lim), _stat_record.detail_record(id2,lim)  loop
      return next result;
   end loop;
   
   EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Other error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return  ;
  raise notice 'record global report';
 return  ; 
		 


end;
$function$
;




CREATE OR REPLACE FUNCTION _stat_record.total_report_for_amonth_record(p_month date DEFAULT date(now()), lim integer DEFAULT 5)
 RETURNS SETOF _stat_record.global_report_record
 LANGUAGE plpgsql
AS $function$
declare 
mensaje text;
mensaje_detalle text;
sqlerror text;
result record ;
labels _stat_record.global_report_record;
id1 bigint;
id2 bigint;

begin 
select min(id_record),max(id_record) into id1,id2 from _stat_record._record_number where  extract(year from  date(date_take))= extract(year from  date($1)) and extract(month from  date(date_take))= extract(month from  date($1));


   for result in select *,'' from _stat_record.global_report_record(id1,id2) loop
      return next result;
   end loop;
   labels.col1:= 'Detail for id:'||id1;
   labels.col2:= 'Detail for id:'||id2;
   return next labels;
   for result in select _stat_record.detail_record(id1,lim), _stat_record.detail_record(id2,lim)  loop
      return next result;
   end loop;
   
   EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Other error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return  ;
  raise notice 'record global report';
 return  ; 
		 


end;
$function$
;




CREATE FUNCTION _stat_record.total_report_record(pid_record_ini bigint, pid_record_last bigint, lim int default 5) RETURNS SETOF _stat_record.global_report_record
    LANGUAGE plpgsql
    AS $_$
declare 
id bigint;
mensaje text;
mensaje_detalle text;
sqlerror text;
result record ;
labels _stat_record.global_report_record;
begin 

   for result in select *,'' from _stat_record.global_report_record($1,$2) loop
      return next result;
   end loop;
   labels.col1:= 'Detail for id:'||$1;
   labels.col2:= 'Detail for id:'||$2;
   return next labels;
   for result in select _stat_record.detail_record($1,$3), _stat_record.detail_record($2,$3)  loop
      return next result;
   end loop;
   
   EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Other error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return  ;
  raise notice 'record global report';
 return  ; 
		 


end;
$_$;




CREATE FUNCTION _stat_record.truncate_record(p_trunc boolean DEFAULT false) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
declare 
mensaje text;
mensaje_detalle text;
sqlerror text;
begin 
 truncate _stat_record._record_number cascade ;
 if $1 then
  perform setval('_stat_record._record_number_id_record_seq',1,false);
 end if;
 return true;
 EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Other error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return false ;
       
 
end;$_$;


SET default_tablespace = '';

SET default_with_oids = false;



CREATE TABLE _stat_record._config_var (
    config_var_name text
);




CREATE TABLE _stat_record._db_stat (
    id_record bigint,
    id_var_type integer,
    var_name text,
    var_val text,
    um character varying,
    objtyp character varying,
    objname character varying
);




CREATE TABLE _stat_record._global_object (
    id_record bigint,
    id_object_type integer,
    object_name text,
    object_val text,
    um character varying,
    des character varying
);




CREATE TABLE _stat_record._global_stat (
    id_record bigint,
    id_var_type integer,
    var_name text,
    var_val text,
    um character varying
);




CREATE TABLE _stat_record._object_type (
    id_object_type integer NOT NULL,
    description text
);




CREATE TABLE _stat_record._query_stat (
    id_record bigint,
    bd text,
    query_id bigint,
    query_text text,
    stat_name text,
    stat_val text,
    um character varying
);




CREATE TABLE _stat_record._record_number (
    id_record bigint NOT NULL,
    date_take timestamp without time zone,
    description text
);




CREATE SEQUENCE _stat_record._record_number_id_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;




ALTER SEQUENCE _stat_record._record_number_id_record_seq OWNED BY _stat_record._record_number.id_record;







CREATE TABLE _stat_record._variable_type (
    id_var_type integer NOT NULL,
    description text
);



create  view _stat_record.v_global_stat_value_diff as 
with sub as (

select rn.id_record ,rn.date_take , gs2.var_name ,sum(gs2.var_val ::numeric) val from "_stat_record"."_global_stat" gs2 join "_stat_record"."_record_number" rn  using(id_record) where id_var_type =1
group by 1,2,3 order by 1) ,
sub2 as (
select rn.id_record ,rn.date_take , gs2.var_name ,gs2.var_val::pg_lsn val from "_stat_record"."_global_stat" gs2 join "_stat_record"."_record_number" rn  using(id_record) where var_name='Wal Location'
 order by 1)

(select id_record,date_take, var_name, val::text , (val-lag(val) over (partition by var_name order by id_record))::text as  diff from sub) 
union all 
(select id_record,date_take, var_name, val::text ,pg_size_pretty( pg_wal_lsn_diff(val, lag(val) over (partition by var_name order by id_record))) as  diff from sub2) 
order by  var_name, id_record,date_take;



ALTER TABLE ONLY _stat_record._record_number ALTER COLUMN id_record SET DEFAULT nextval('_stat_record._record_number_id_record_seq'::regclass);




INSERT INTO _stat_record._config_var (config_var_name) VALUES ('autovacuum');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('autovacuum_max_workers');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('autovacuum_analyze_scale_factor');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('autovacuum_vacuum_scale_factor');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('autovacuum_naptime');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('log_statement');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('max_wal_size');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('statement_timeout');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('shared_buffers');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('work_mem');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('maintenance_work_mem');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('effective_cache_size');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('wal_level');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('max_connections');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('log_line_prefix');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('log_connections');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('log_disconnections');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('log_min_duration_statement');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('max_parallel_workers_per_gather');
INSERT INTO _stat_record._config_var (config_var_name) VALUES ('max_parallel_workers');




INSERT INTO _stat_record._object_type (id_object_type, description) VALUES (1, 'users');
INSERT INTO _stat_record._object_type (id_object_type, description) VALUES (2, 'databases');
INSERT INTO _stat_record._object_type (id_object_type, description) VALUES (3, 'tablespaces');
INSERT INTO _stat_record._object_type (id_object_type, description) VALUES (4, 'conf');




INSERT INTO _stat_record._variable_type (id_var_type, description) VALUES (1, 'numeric');
INSERT INTO _stat_record._variable_type (id_var_type, description) VALUES (2, 'text');
INSERT INTO _stat_record._variable_type (id_var_type, description) VALUES (3, 'timestamp');




SELECT pg_catalog.setval('_stat_record._record_number_id_record_seq', 1, false);




ALTER TABLE ONLY _stat_record._object_type
    ADD CONSTRAINT _object_type_pkey PRIMARY KEY (id_object_type);




ALTER TABLE ONLY _stat_record._record_number
    ADD CONSTRAINT _record_number_pkey PRIMARY KEY (id_record);



ALTER TABLE ONLY _stat_record._variable_type
    ADD CONSTRAINT _variable_type_pkey PRIMARY KEY (id_var_type);




CREATE INDEX idx_glb_ob_id_record ON _stat_record._global_object USING btree (id_record);




CREATE INDEX idx_glo_id_record ON _stat_record._global_stat USING btree (id_record);




CREATE INDEX idx_id_record ON _stat_record._query_stat USING btree (id_record);




CREATE INDEX idx_stat_id_record ON _stat_record._db_stat USING btree (id_record);









ALTER TABLE ONLY _stat_record._db_stat
    ADD CONSTRAINT _db_stat_id_record_fkey FOREIGN KEY (id_record) REFERENCES _stat_record._record_number(id_record) ON UPDATE CASCADE ON DELETE CASCADE;




ALTER TABLE ONLY _stat_record._db_stat
    ADD CONSTRAINT _db_stat_id_var_type_fkey FOREIGN KEY (id_var_type) REFERENCES _stat_record._variable_type(id_var_type) ON UPDATE CASCADE ON DELETE CASCADE;




ALTER TABLE ONLY _stat_record._query_stat
    ADD CONSTRAINT _global_object_id_query_fkey FOREIGN KEY (id_record) REFERENCES _stat_record._record_number(id_record) ON UPDATE CASCADE ON DELETE CASCADE;




ALTER TABLE ONLY _stat_record._global_object
    ADD CONSTRAINT _global_object_id_record_fkey FOREIGN KEY (id_record) REFERENCES _stat_record._record_number(id_record) ON UPDATE CASCADE ON DELETE CASCADE;




ALTER TABLE ONLY _stat_record._global_object
    ADD CONSTRAINT _global_oject_id_var_object_fkey FOREIGN KEY (id_object_type) REFERENCES _stat_record._object_type(id_object_type) ON UPDATE CASCADE ON DELETE CASCADE;




ALTER TABLE ONLY _stat_record._global_stat
    ADD CONSTRAINT _global_stat_id_record_fkey FOREIGN KEY (id_record) REFERENCES _stat_record._record_number(id_record) ON UPDATE CASCADE ON DELETE CASCADE;




ALTER TABLE ONLY _stat_record._global_stat
    ADD CONSTRAINT _global_stat_id_var_type_fkey FOREIGN KEY (id_var_type) REFERENCES _stat_record._variable_type(id_var_type) ON UPDATE CASCADE ON DELETE CASCADE;


