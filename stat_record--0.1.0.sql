--
-- PostgreSQL database dump
--

-- Dumped from database version 10.7 (Ubuntu 10.7-1.pgdg16.04+1)
-- Dumped by pg_dump version 11.2 (Ubuntu 11.2-1.pgdg16.04+1)

-- Started on 2019-03-21 15:53:40 -03
CREATE SERVER fs
   FOREIGN DATA WRAPPER file_fdw;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 263539)
-- Name: _stat_record; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA _stat_record;


--
-- TOC entry 661 (class 1247 OID 263705)
-- Name: detail_record; Type: TYPE; Schema: _stat_record; Owner: -
--

CREATE TYPE _stat_record.detail_record AS (
	variable text,
	value text
);


--
-- TOC entry 701 (class 1247 OID 264922)
-- Name: global_report_record; Type: TYPE; Schema: _stat_record; Owner: -
--

CREATE TYPE _stat_record.global_report_record AS (
	col1 text,
	col2 text
);


--
-- TOC entry 247 (class 1255 OID 264241)
-- Name: delete_record(bigint); Type: FUNCTION; Schema: _stat_record; Owner: -
--

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
      RAISE EXCEPTION 'Otro error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return false ;
end;$_$;


--
-- TOC entry 252 (class 1255 OID 264270)
-- Name: detail_record(bigint); Type: FUNCTION; Schema: _stat_record; Owner: -
--

CREATE FUNCTION _stat_record.detail_record(id bigint) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $_$
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

   for result in ( select '  '||'10 Querys with more call: '
               union all
               select '    '||'db: '|| bd||' -- query: ' ||query_text||' -- calls: '||stat_val from ( select * from _stat_record._query_stat where id_Record =$1 order by stat_val::bigint desc )  as sub 
                where id_Record =$1 and stat_name='calls'  limit 10 ) loop
    RETURN NEXT result ;
   end loop;

   for result in ( select '  '||'10 Querys with more total time: '
               union all
               select '    '||'db: '|| bd||' -- query: ' ||query_text||' -- total_time: '||stat_val ||' ms' from ( select * from _stat_record._query_stat  where id_Record =$1 order by stat_val::numeric desc )  as sub 
                where id_Record =$1 and stat_name='total_time'  limit 10 ) loop
    RETURN NEXT result ;
   end loop; 

    for result in ( select '  '||'10 Querys with more mean time: '
               union all
               select '    '||'db: '|| bd||' -- query: ' ||query_text||' -- mean_time: '||stat_val ||' ms' from ( select * from _stat_record._query_stat  where id_Record =$1 order by stat_val::numeric desc )  as sub 
                where id_Record =$1 and stat_name='mean_time'  limit 10 ) loop
     RETURN NEXT result ;
    end loop;

    for result in ( select '  '||'10 Querys with  max time: '
               union all
               select '    '||'db: '|| bd||' -- query: ' ||query_text||' -- max_time: '||stat_val ||' ms' from ( select * from _stat_record._query_stat where id_Record =$1 order by stat_val::numeric desc )  as sub 
                where id_Record =$1 and stat_name='max_time'  limit 10 ) loop
     RETURN NEXT result ;
    end loop;

    for result in ( select '  '||'10 Querys with  more row  returned: '
               union all
               select '    '||'db: '|| bd||' -- query: ' ||query_text||' -- rows: '||stat_val  from ( select * from _stat_record._query_stat where id_Record =$1 order by stat_val::numeric desc )  as sub 
                where id_Record =$1 and stat_name='rows'  limit 10 ) loop
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

    for result in ( select '  '||'10 tables Weigth: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='table' and var_name='weigth' limit 10 ) loop
     RETURN NEXT result ;
    end loop;

    for result in ( select '  '||'10 tables with more estimated tuples: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='table' and var_name='reltuples' limit 10 ) loop
     RETURN NEXT result ;
     end loop;

     for result in ( select '  '||'10 most consulted tables: '
               union all
               select '    '|| objname ||': '||total::text  from ( select objname,sum(var_val::bigint)as  total from _stat_record._db_stat where id_Record =$1  and objtyp='table'  and
                (var_name='seq_scan' or var_name='index_scan') group by objname order by 2 desc )  as sub 
                     limit 10 ) loop
     RETURN NEXT result ;
    end loop;

    for result in ( select '  '||'10 tables with more Inserted tuples: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='table' and var_name='n_tup_ins' limit 10 ) loop
     RETURN NEXT result ;
     end loop;

     for result in ( select '  '||'10 tables with more Updated tuples: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='table' and var_name='n_tup_upd' limit 10 ) loop
     RETURN NEXT result ;
     end loop;

     for result in ( select '  '||'10 tables with more Deleted tuples: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='table' and var_name='n_tup_del' limit 10 ) loop
     RETURN NEXT result ;
     end loop;

     for result in ( select '  '||'10 tables with more Autovacuum: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='maintenance' and var_name='autovacuum_count' limit 10 ) loop
     RETURN NEXT result ;
     end loop;

      for result in ( select '  '||'10 tables with more Manual Vacuum: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='maintenance' and var_name='vacuum_count' limit 10 ) loop
     RETURN NEXT result ;
     end loop;

     for result in ( select '  '||'10 tables with more Auto Analyze: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='maintenance' and var_name='autoanalyze_count' limit 10 ) loop
     RETURN NEXT result ;
     end loop;

      for result in ( select '  '||'10 tables with more Manual Analyze: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='maintenance' and var_name='analyze_count' limit 10 ) loop
     RETURN NEXT result ;
     end loop;

     for result in ( select '  '||'10 indexs Weigth: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='index' and var_name='index_size' limit 10 ) loop
     RETURN NEXT result ;
    end loop;

    for result in ( select '  '||'10 indexs used: '
               union all
               select '    '|| objname ||': '||var_val ||' '||um  from ( select * from _stat_record._db_stat where id_Record =$1 order by var_val::numeric desc )  as sub 
                where id_Record =$1 and objtyp='index' and var_name='times_used' limit 10 ) loop
     RETURN NEXT result ;
    end loop;


   
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Otro error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return  ;

 return  ; 
 raise notice 'record detail';
end;
$_$;


--
-- TOC entry 255 (class 1255 OID 264925)
-- Name: export_total_report_record(bigint, bigint, text); Type: FUNCTION; Schema: _stat_record; Owner: -
--

CREATE FUNCTION _stat_record.export_total_report_record(pid_record_ini bigint, pid_record_last bigint, p_file text DEFAULT '/tmp/global_report.csv'::text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
declare 
id bigint;
mensaje text;
mensaje_detalle text;
sqlerror text;
result record ;
cmd text := 'copy (select * from _stat_record.total_report_record('||$1::text||','||$2||')   ) to '''||p_file ||''' csv ';
begin 

   execute  cmd;
   return 'Exported successfully to: '||p_file ;
   EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Otro error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      
  raise notice 'record global report';
 return 'Error' ; 
		 


end;
$_$;


--
-- TOC entry 254 (class 1255 OID 264269)
-- Name: global_report_record(bigint, bigint); Type: FUNCTION; Schema: _stat_record; Owner: -
--

CREATE FUNCTION _stat_record.global_report_record(pid_record_ini bigint, pid_record_last bigint) RETURNS SETOF text
    LANGUAGE plpgsql
    AS $_$
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
                select '  Partitions Disc:->'
                union all
                select '    '||fs from _stat_record._so_partitions where   id_record=1

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
                select '  Partitions Disc:->'
                union all
                select '    '||fs from _stat_record._so_partitions where   id_record=$2
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
                
		) 
		loop

		return next result;

   end loop;

   EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Otro error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return  ;
  raise notice 'record global report';
 return  ; 
		 


end;
$_$;


--
-- TOC entry 234 (class 1255 OID 264455)
-- Name: lastest_records(bigint); Type: FUNCTION; Schema: _stat_record; Owner: -
--

CREATE FUNCTION _stat_record.lastest_records(p_count bigint DEFAULT 1) RETURNS TABLE(id bigint, record_time timestamp without time zone, record_description text)
    LANGUAGE sql
    AS $_$ 
select * from _stat_record._record_number  order by 1 desc  limit $1 ;

$_$;


--
-- TOC entry 251 (class 1255 OID 263630)
-- Name: take_record(text); Type: FUNCTION; Schema: _stat_record; Owner: -
--

CREATE FUNCTION _stat_record.take_record(p_des text DEFAULT ''::text) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
declare 
id bigint;
mensaje text;
mensaje_detalle text;
sqlerror text;
reg record;
so text;
begin 
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
  with sub as (select sum(xact_commit) cmit,sum(xact_rollback) rback,sum (tup_returned) returned ,sum (tup_fetched) fetched,sum(tup_inserted) inserted,sum(tup_updated) updated ,sum(tup_deleted) deleted,sum(temp_files) tempfiles from pg_stat_database where  datname not like 'template%'),
  
  cm as (INSERT INTO _stat_record._global_stat select id,1,'Databases commit',cmit,'' from sub),
  rb as (INSERT INTO _stat_record._global_stat select id,1,'Databases rollback',rback,'' from sub),
  rt as (INSERT INTO _stat_record._global_stat select id,1,'Databases tuples returned',returned,'' from sub),
  ft as (INSERT INTO _stat_record._global_stat select id,1,'Databases tuples fetched',fetched,'' from sub),
  ins as (INSERT INTO _stat_record._global_stat select id,1,'Databases tuples inserted',inserted,'' from sub),
  upt as (INSERT INTO _stat_record._global_stat select id,1,'Databases tuples updated',updated,'' from sub),
  del as (INSERT INTO _stat_record._global_stat select id,1,'Databases tuples deleted',deleted,'' from sub)
  INSERT INTO _stat_record._global_stat select id,1,'Databases tuples tempfiles',tempfiles,'' from sub
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
  where name in ('autovacuum','autovacuum_analyze_scale_factor','autovacuum_vacuum_scale_factor','autovacuum_naptime',
  'log_statement','max_wal_size','statement_timeout','shared_buffers','work_mem','maintenance_work_mem','effective_cache_size','wal_level','max_connections','log_line_prefix',
  'log_connections','log_disconnections','log_min_duration_statement');
  
 

 ----recording config variables

 ----recording querys stats
 --checking pg_stat_statemets
  select * into reg from pg_available_extensions where name ='pg_stat_statements' and installed_version is not null and  position ('pg_stat_statements' in current_setting('shared_preload_libraries') ) >0;
   if found then 
       with sub as (select d.datname,queryid, query, calls, total_time,min_time,max_time,mean_time,stddev_time,rows from public.pg_stat_statements  s  join   pg_database d on  (d.oid=s.dbid) ),
  
	  cal as (INSERT INTO _stat_record._query_stat select id,datname,queryid,query,'calls',calls from sub),
	  total as (INSERT INTO _stat_record._query_stat select id,datname,queryid,query,'total_time',total_time from sub),
	  min as (INSERT INTO _stat_record._query_stat select id,datname,queryid,query,'min_time',min_time from sub),
	  max as (INSERT INTO _stat_record._query_stat select id,datname,queryid,query,'max_time',max_time from sub),
	  mean as (INSERT INTO _stat_record._query_stat select id,datname,queryid,query,'mean_time',mean_time from sub),
	  std as (INSERT INTO _stat_record._query_stat select id,datname,queryid,query,'stddev_time',stddev_time from sub)
	  INSERT INTO _stat_record._query_stat select id,datname,queryid,query,'rows',rows from sub
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

   reltuple as (INSERT INTO _stat_record._db_stat select id,1,'reltuples',reltuples,'','table',name from sub),
   wei as (INSERT INTO _stat_record._db_stat select id,1,'weigth',weigth,'MB','table',name from sub),
   dead as (INSERT INTO _stat_record._db_stat select id,1,'n_dead_tup',n_dead_tup,'','table',name from sub),
   scan as (INSERT INTO _stat_record._db_stat select id,1,'seq_scan',seq_scan,'','table',name from sub),
   seq_read as (INSERT INTO _stat_record._db_stat select id,1,'seq_tup_read',seq_tup_read,'','table',name from sub),
   idx_scan as (INSERT INTO _stat_record._db_stat select id,1,'index_scan',index_scan,'','table',name from sub),
   idx_fetch as (INSERT INTO _stat_record._db_stat select id,1,'index_fetch',index_fetch,'','table',name from sub),
   ins as (INSERT INTO _stat_record._db_stat select id,1,'n_tup_ins',n_tup_ins,'','table',name from sub),
   del as (INSERT INTO _stat_record._db_stat select id,1,'n_tup_del',n_tup_del,'','table',name from sub)
   INSERT INTO _stat_record._db_stat select id,1,'n_tup_upd',n_tup_upd,'','table',name from sub  ;                 
                   
  --index stats 
   with sub as (

   SELECT 'index' idx, idstat.schemaname||'.'||idstat.relname||'.'||indexrelname AS index_name,idstat.idx_scan AS times_used,
                round((pg_relation_size(idstat.indexrelid::regclass)/1024)/1024::numeric,2)  AS index_size
                FROM pg_stat_user_indexes AS idstat  JOIN pg_stat_user_tables AS tabstat ON idstat.relname = tabstat.relname  
                where idstat.schemaname <>'_stat_record' ORDER BY 3 desc ),

  
   use as (INSERT INTO _stat_record._db_stat select id,1,'times_used',times_used,'','index',index_name from sub)
   INSERT INTO _stat_record._db_stat select id,1,'index_size',index_size,'MB','index',index_name from sub
   ;                 

   --maintenance stats 
   with sub as (

     SELECT 'maintenance' maintenance, ns.nspname||'.'|| pg.relname as name ,  autovacuum_count,vacuum_count,autoanalyze_count,analyze_count  FROM pg_class pg JOIN pg_stat_user_tables psat ON (pg.relname = psat.relname)  join pg_namespace a on
                 ( pg.relnamespace = a.oid)  join pg_namespace ns  on (pg.relnamespace = ns.oid) 
                 where ns.nspname<>'_stat_record' ORDER BY 2 DESC),
     autovac as (INSERT INTO _stat_record._db_stat select id,1,'autovacuum_count',autovacuum_count,'','maintenance',name from sub),
   vac as (INSERT INTO _stat_record._db_stat select id,1,'vacuum_count',vacuum_count,'','maintenance',name from sub),             
   autoanalyze as (INSERT INTO _stat_record._db_stat select id,1,'autoanalyze_count',autoanalyze_count,'','maintenance',name from sub)
   INSERT INTO _stat_record._db_stat select id,1,'analyze_count',analyze_count,'','maintenance',name from sub
   ;                 



 ----recording databases  stats object


 ----SO data
 begin 
   select * into so from _stat_record.distribution;

   if found then
     --record partition size/use
     INSERT into _stat_record._so_partitions  select id,* from _stat_record.partitions;

   end if;

 EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE Notice 'Not SO allowed: %, %, %', sqlerror, mensaje,mensaje_detalle;
    
end;

 ----SO data

 
 
 
 raise notice 'record taked';
 return true;

 EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Otro error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return false ;
    
end;
$_$;


--
-- TOC entry 256 (class 1255 OID 264926)
-- Name: total_report_for_2last_record(); Type: FUNCTION; Schema: _stat_record; Owner: -
--

CREATE FUNCTION _stat_record.total_report_for_2last_record() RETURNS SETOF _stat_record.global_report_record
    LANGUAGE plpgsql
    AS $$
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
   for result in select _stat_record.detail_record(id1), _stat_record.detail_record(id2)  loop
      return next result;
   end loop;
   
   EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Otro error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return  ;
  raise notice 'record global report';
 return  ; 
		 


end;
$$;


--
-- TOC entry 257 (class 1255 OID 264927)
-- Name: total_report_for_amonth_record(date); Type: FUNCTION; Schema: _stat_record; Owner: -
--

CREATE FUNCTION _stat_record.total_report_for_amonth_record(p_month date DEFAULT date(now())) RETURNS SETOF _stat_record.global_report_record
    LANGUAGE plpgsql
    AS $_$
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
   for result in select _stat_record.detail_record(id1), _stat_record.detail_record(id2)  loop
      return next result;
   end loop;
   
   EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Otro error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return  ;
  raise notice 'record global report';
 return  ; 
		 


end;
$_$;


--
-- TOC entry 253 (class 1255 OID 264924)
-- Name: total_report_record(bigint, bigint); Type: FUNCTION; Schema: _stat_record; Owner: -
--

CREATE FUNCTION _stat_record.total_report_record(pid_record_ini bigint, pid_record_last bigint) RETURNS SETOF _stat_record.global_report_record
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
   for result in select _stat_record.detail_record($1), _stat_record.detail_record($2)  loop
      return next result;
   end loop;
   
   EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS mensaje = message_text, mensaje_detalle =pg_exception_detail, sqlerror = returned_sqlstate;
      RAISE EXCEPTION 'Otro error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return  ;
  raise notice 'record global report';
 return  ; 
		 


end;
$_$;


--
-- TOC entry 250 (class 1255 OID 263629)
-- Name: truncate_record(boolean); Type: FUNCTION; Schema: _stat_record; Owner: -
--

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
      RAISE EXCEPTION 'Otro error: %, %, %', sqlerror, mensaje,mensaje_detalle;
      return false ;
       
 
end;$_$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 228 (class 1259 OID 264928)
-- Name: _config_var; Type: TABLE; Schema: _stat_record; Owner: -
--

CREATE TABLE _stat_record._config_var (
    config_var_name text
);


--
-- TOC entry 204 (class 1259 OID 263608)
-- Name: _db_stat; Type: TABLE; Schema: _stat_record; Owner: -
--

CREATE TABLE _stat_record._db_stat (
    id_record bigint,
    id_var_type integer,
    var_name text,
    var_val text,
    um character varying,
    objtyp character varying,
    objname character varying
);


--
-- TOC entry 206 (class 1259 OID 263640)
-- Name: _global_object; Type: TABLE; Schema: _stat_record; Owner: -
--

CREATE TABLE _stat_record._global_object (
    id_record bigint,
    id_object_type integer,
    object_name text,
    object_val text,
    um character varying,
    des character varying
);


--
-- TOC entry 203 (class 1259 OID 263592)
-- Name: _global_stat; Type: TABLE; Schema: _stat_record; Owner: -
--

CREATE TABLE _stat_record._global_stat (
    id_record bigint,
    id_var_type integer,
    var_name text,
    var_val text,
    um character varying
);


--
-- TOC entry 205 (class 1259 OID 263632)
-- Name: _object_type; Type: TABLE; Schema: _stat_record; Owner: -
--

CREATE TABLE _stat_record._object_type (
    id_object_type integer NOT NULL,
    description text
);


--
-- TOC entry 225 (class 1259 OID 264533)
-- Name: _query_stat; Type: TABLE; Schema: _stat_record; Owner: -
--

CREATE TABLE _stat_record._query_stat (
    id_record bigint,
    bd text,
    query_id bigint,
    query_text text,
    stat_name text,
    stat_val text,
    um character varying
);


--
-- TOC entry 201 (class 1259 OID 263542)
-- Name: _record_number; Type: TABLE; Schema: _stat_record; Owner: -
--

CREATE TABLE _stat_record._record_number (
    id_record bigint NOT NULL,
    date_take timestamp without time zone,
    description text
);


--
-- TOC entry 200 (class 1259 OID 263540)
-- Name: _record_number_id_record_seq; Type: SEQUENCE; Schema: _stat_record; Owner: -
--

CREATE SEQUENCE _stat_record._record_number_id_record_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3077 (class 0 OID 0)
-- Dependencies: 200
-- Name: _record_number_id_record_seq; Type: SEQUENCE OWNED BY; Schema: _stat_record; Owner: -
--

ALTER SEQUENCE _stat_record._record_number_id_record_seq OWNED BY _stat_record._record_number.id_record;


--
-- TOC entry 233 (class 1259 OID 273632)
-- Name: _so_partitions; Type: TABLE; Schema: _stat_record; Owner: -
--

CREATE TABLE _stat_record._so_partitions (
    id_record bigint,
    fs character varying
);


--
-- TOC entry 202 (class 1259 OID 263551)
-- Name: _variable_type; Type: TABLE; Schema: _stat_record; Owner: -
--

CREATE TABLE _stat_record._variable_type (
    id_var_type integer NOT NULL,
    description text
);


--
-- TOC entry 230 (class 1259 OID 273545)
-- Name: distribution; Type: FOREIGN TABLE; Schema: _stat_record; Owner: -
--

CREATE FOREIGN TABLE _stat_record.distribution (
    version text
)
SERVER fs
OPTIONS (
    delimiter ';',
    program 'cat /proc/version'
);


--
-- TOC entry 231 (class 1259 OID 273605)
-- Name: meminfo; Type: FOREIGN TABLE; Schema: _stat_record; Owner: -
--

CREATE FOREIGN TABLE _stat_record.meminfo (
    value text
)
SERVER fs
OPTIONS (
    delimiter ';',
    program ' awk ''{$2=($2/1024)/1024;$3="GB";} 1'' /proc/meminfo | column -t'
);


--
-- TOC entry 232 (class 1259 OID 273629)
-- Name: partitions; Type: FOREIGN TABLE; Schema: _stat_record; Owner: -
--

CREATE FOREIGN TABLE _stat_record.partitions (
    fs character varying
)
SERVER fs
OPTIONS (
    delimiter ':',
    program 'df -h | awk ''{print $1 "	" $2 "	" $3 "	" $4 "	" $5 "	" $6}'''
);


--
-- TOC entry 2921 (class 2604 OID 263545)
-- Name: _record_number id_record; Type: DEFAULT; Schema: _stat_record; Owner: -
--

ALTER TABLE ONLY _stat_record._record_number ALTER COLUMN id_record SET DEFAULT nextval('_stat_record._record_number_id_record_seq'::regclass);


--
-- TOC entry 3070 (class 0 OID 264928)
-- Dependencies: 228
-- Data for Name: _config_var; Type: TABLE DATA; Schema: _stat_record; Owner: -
--

INSERT INTO _stat_record._config_var (config_var_name) VALUES ('autovacuum');
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


--
-- TOC entry 3066 (class 0 OID 263608)
-- Dependencies: 204
-- Data for Name: _db_stat; Type: TABLE DATA; Schema: _stat_record; Owner: -
--



--
-- TOC entry 3068 (class 0 OID 263640)
-- Dependencies: 206
-- Data for Name: _global_object; Type: TABLE DATA; Schema: _stat_record; Owner: -
--



--
-- TOC entry 3065 (class 0 OID 263592)
-- Dependencies: 203
-- Data for Name: _global_stat; Type: TABLE DATA; Schema: _stat_record; Owner: -
--



--
-- TOC entry 3067 (class 0 OID 263632)
-- Dependencies: 205
-- Data for Name: _object_type; Type: TABLE DATA; Schema: _stat_record; Owner: -
--

INSERT INTO _stat_record._object_type (id_object_type, description) VALUES (1, 'users');
INSERT INTO _stat_record._object_type (id_object_type, description) VALUES (2, 'databases');
INSERT INTO _stat_record._object_type (id_object_type, description) VALUES (3, 'tablespaces');
INSERT INTO _stat_record._object_type (id_object_type, description) VALUES (4, 'conf');


--
-- TOC entry 3069 (class 0 OID 264533)
-- Dependencies: 225
-- Data for Name: _query_stat; Type: TABLE DATA; Schema: _stat_record; Owner: -
--



--
-- TOC entry 3063 (class 0 OID 263542)
-- Dependencies: 201
-- Data for Name: _record_number; Type: TABLE DATA; Schema: _stat_record; Owner: -
--



--
-- TOC entry 3071 (class 0 OID 273632)
-- Dependencies: 233
-- Data for Name: _so_partitions; Type: TABLE DATA; Schema: _stat_record; Owner: -
--



--
-- TOC entry 3064 (class 0 OID 263551)
-- Dependencies: 202
-- Data for Name: _variable_type; Type: TABLE DATA; Schema: _stat_record; Owner: -
--

INSERT INTO _stat_record._variable_type (id_var_type, description) VALUES (1, 'numeric');
INSERT INTO _stat_record._variable_type (id_var_type, description) VALUES (2, 'text');
INSERT INTO _stat_record._variable_type (id_var_type, description) VALUES (3, 'timestamp');


--
-- TOC entry 3078 (class 0 OID 0)
-- Dependencies: 200
-- Name: _record_number_id_record_seq; Type: SEQUENCE SET; Schema: _stat_record; Owner: -
--

SELECT pg_catalog.setval('_stat_record._record_number_id_record_seq', 1, false);


--
-- TOC entry 2929 (class 2606 OID 263639)
-- Name: _object_type _object_type_pkey; Type: CONSTRAINT; Schema: _stat_record; Owner: -
--

ALTER TABLE ONLY _stat_record._object_type
    ADD CONSTRAINT _object_type_pkey PRIMARY KEY (id_object_type);


--
-- TOC entry 2923 (class 2606 OID 263550)
-- Name: _record_number _record_number_pkey; Type: CONSTRAINT; Schema: _stat_record; Owner: -
--

ALTER TABLE ONLY _stat_record._record_number
    ADD CONSTRAINT _record_number_pkey PRIMARY KEY (id_record);


--
-- TOC entry 2925 (class 2606 OID 263558)
-- Name: _variable_type _variable_type_pkey; Type: CONSTRAINT; Schema: _stat_record; Owner: -
--

ALTER TABLE ONLY _stat_record._variable_type
    ADD CONSTRAINT _variable_type_pkey PRIMARY KEY (id_var_type);


--
-- TOC entry 2930 (class 1259 OID 264594)
-- Name: idx_glb_ob_id_record; Type: INDEX; Schema: _stat_record; Owner: -
--

CREATE INDEX idx_glb_ob_id_record ON _stat_record._global_object USING btree (id_record);


--
-- TOC entry 2926 (class 1259 OID 264593)
-- Name: idx_glo_id_record; Type: INDEX; Schema: _stat_record; Owner: -
--

CREATE INDEX idx_glo_id_record ON _stat_record._global_stat USING btree (id_record);


--
-- TOC entry 2931 (class 1259 OID 264592)
-- Name: idx_id_record; Type: INDEX; Schema: _stat_record; Owner: -
--

CREATE INDEX idx_id_record ON _stat_record._query_stat USING btree (id_record);


--
-- TOC entry 2927 (class 1259 OID 264595)
-- Name: idx_stat_id_record; Type: INDEX; Schema: _stat_record; Owner: -
--

CREATE INDEX idx_stat_id_record ON _stat_record._db_stat USING btree (id_record);


--
-- TOC entry 2939 (class 2606 OID 273638)
-- Name: _so_partitions _db_so_id_record_fkey; Type: FK CONSTRAINT; Schema: _stat_record; Owner: -
--

ALTER TABLE ONLY _stat_record._so_partitions
    ADD CONSTRAINT _db_so_id_record_fkey FOREIGN KEY (id_record) REFERENCES _stat_record._record_number(id_record) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2934 (class 2606 OID 263614)
-- Name: _db_stat _db_stat_id_record_fkey; Type: FK CONSTRAINT; Schema: _stat_record; Owner: -
--

ALTER TABLE ONLY _stat_record._db_stat
    ADD CONSTRAINT _db_stat_id_record_fkey FOREIGN KEY (id_record) REFERENCES _stat_record._record_number(id_record) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2935 (class 2606 OID 263619)
-- Name: _db_stat _db_stat_id_var_type_fkey; Type: FK CONSTRAINT; Schema: _stat_record; Owner: -
--

ALTER TABLE ONLY _stat_record._db_stat
    ADD CONSTRAINT _db_stat_id_var_type_fkey FOREIGN KEY (id_var_type) REFERENCES _stat_record._variable_type(id_var_type) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2938 (class 2606 OID 264539)
-- Name: _query_stat _global_object_id_query_fkey; Type: FK CONSTRAINT; Schema: _stat_record; Owner: -
--

ALTER TABLE ONLY _stat_record._query_stat
    ADD CONSTRAINT _global_object_id_query_fkey FOREIGN KEY (id_record) REFERENCES _stat_record._record_number(id_record) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2936 (class 2606 OID 263646)
-- Name: _global_object _global_object_id_record_fkey; Type: FK CONSTRAINT; Schema: _stat_record; Owner: -
--

ALTER TABLE ONLY _stat_record._global_object
    ADD CONSTRAINT _global_object_id_record_fkey FOREIGN KEY (id_record) REFERENCES _stat_record._record_number(id_record) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2937 (class 2606 OID 263651)
-- Name: _global_object _global_oject_id_var_object_fkey; Type: FK CONSTRAINT; Schema: _stat_record; Owner: -
--

ALTER TABLE ONLY _stat_record._global_object
    ADD CONSTRAINT _global_oject_id_var_object_fkey FOREIGN KEY (id_object_type) REFERENCES _stat_record._object_type(id_object_type) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2932 (class 2606 OID 263598)
-- Name: _global_stat _global_stat_id_record_fkey; Type: FK CONSTRAINT; Schema: _stat_record; Owner: -
--

ALTER TABLE ONLY _stat_record._global_stat
    ADD CONSTRAINT _global_stat_id_record_fkey FOREIGN KEY (id_record) REFERENCES _stat_record._record_number(id_record) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 2933 (class 2606 OID 263603)
-- Name: _global_stat _global_stat_id_var_type_fkey; Type: FK CONSTRAINT; Schema: _stat_record; Owner: -
--

ALTER TABLE ONLY _stat_record._global_stat
    ADD CONSTRAINT _global_stat_id_var_type_fkey FOREIGN KEY (id_var_type) REFERENCES _stat_record._variable_type(id_var_type) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2019-03-21 15:53:40 -03

--
-- PostgreSQL database dump complete
--

