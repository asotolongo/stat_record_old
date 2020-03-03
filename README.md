stat_record  extension
======================================

This PostgreSQL extension can be useful for the DBA to analyze server behavior over time. 
Because PostgreSQL stores current statistics, this extension is implemented to record statistics on the database server at any time and can be consulted when required,
and also display several reports on statistics such as: connection, size, cache, usage of table and index, 
queries, bloat, etc. and you can compare some statistics over time to see the changes and evolution.
#required PG10+ and  pg_stat_statements extension


IMPORTANT: There're bugs in the existing version, please contact to me.


Building and install
--------
Run: 
```
make
make install 
```

If not install,  you must make sure you can see the binary pg_config,
maybe setting PostgreSQL binary path in the OS  or setting PG_CONFIG = /path_to_pg_config/  in the makefile 
or run: `make  PG_CONFIG = /path_to_pg_config/` and  `make install  PG_CONFIG = /path_to_pg_config/`

In your database execute: 
```
CREATE EXTENSION stat_record CASCADE;
```

After, must configurate stat_record  extension  adding to shared_preload_libraries parameter in postgresql.conf , the pg_stat_statements,stat_record libraries  like:
```
shared_preload_libraries = 'pg_stat_statements,stat_record' --require restart services

```
and GUC variables:

```
stat_record.database_name = 'your_database' --default postgres 
stat_record.interval = 3600 -- in sec default 3600 seconds (1 hour)
```
Restart PostgreSQL services.

A bgworker called `stat_record worker` will start and will take record every (stat_record.interval), but you can also take a manual record.

```
24819 postgres  20   0  333264  29388  27312 S   0,0  0,2   0:00.10 /usr/lib/postgresql/10/bin/postgres -D /var/lib/postgresql/10/main -c config_file=/etc/postgresql/10/main/postgresql.conf               
24820 postgres  20   0  184940   3560   1496 S   0,0  0,0   0:00.00 postgres: 10/main: logger process                                                                                                       
24822 postgres  20   0  333264   4068   1992 S   0,0  0,0   0:00.00 postgres: 10/main: checkpointer process                                                                                                 
24823 postgres  20   0  333400   4068   1992 S   0,0  0,0   0:00.01 postgres: 10/main: writer process                                                                                                       
24824 postgres  20   0  333264   8992   6916 S   0,0  0,1   0:00.01 postgres: 10/main: wal writer process                                                                                                   
24825 postgres  20   0  333968   7460   4912 S   0,0  0,0   0:00.01 postgres: 10/main: autovacuum launcher process                                                                                          
24826 postgres  20   0  188780   5444   2200 S   0,0  0,0   0:00.01 postgres: 10/main: stats collector process                                                                                              
24827 postgres  20   0  346840  32132  20396 S   0,0  0,2   0:00.24 postgres: 10/main: bgworker: stat_record worker                                                                                         
24828 postgres  20   0  333664   5064   2868 S   0,0  0,0   0:00.00 postgres: 10/main: bgworker: logical replication launcher 

```


The extension create schema stat_record and tables/functions

--Tables:
```
_stat_record._record_number ----table where store data about the record taked

_stat_record._global_stat ---- table where store data about global stats

_stat_record._db_stat ---- table where store data about database stats

_stat_record._query_stat ---- table where store data about database query stats

```

--Functions:
```
select _stat_record.take_record()  ---- take stats record about server and databases
select _stat_record.truncate_record( boolean) ---- truncate all record taked (boolean = true, reset id_record to 1)
select _stat_record.delete_record(bigint) ---- delete a record with id_record parameter
select * from _stat_record.detail_record (bigint) ----get report with all global, database , objects and  querys stats about one specific record
select * from _stat_record.lastest_records(bigint) ---- get the lastes record (if a number (N) is specified, it shows the last N records)
--nice to compare record taken, to see evolution of database
select * from _stat_record.global_report_record(bigint,bigint) ----get report with global stats about id_record specified
select * from _stat_record.total_report_record(bigint,bigint) ----get report with all global, database, objects and  querys stats about id_records specified
select * from _stat_record.total_report_for_2last_record() -----get report with all global, database , objects and  querys stats about two last record taked
select * from _stat_record.total_report_for_amonth_record(date) -----get report with all global,  database , objecst and  querys stats about first and the last record taked a moth specified
select _stat_record.export_total_report_record(bigint,bigint,text) ----export CSV report with all global,  database , objects and  querys stats about first and the last record taked a moth specified y some path(by default /tmp/global_report.csv)
--nice to compare record taken, to see evolution of database
```


Example of use:
--------

```
--get all records taken
stat_record=#select * from  _stat_record._record_number order by 2 desc;
 id |        record_time         | record_description 
----+----------------------------+--------------------
  2 | 2020-03-01 13:51:11.009518 | 
  1 | 2020-03-01 13:50:44.495992 | 

--take a manual record
stat_record=# select _stat_record.take_record();
NOTICE:  record taked
 take_record 
-------------
 t
(1 fila)

--wait a time and take the record again 
stat_record=# select _stat_record.take_record(); --take other  manual record
NOTICE:  record taked
 take_record 
-------------
 t
(1 fila)

--getting the last two records
stat_record=# select * from _stat_record.lastest_records(2);
 id |        record_time         | record_description 
----+----------------------------+--------------------
  2 | 2020-03-01 13:51:11.009518 | 
  1 | 2020-03-01 13:50:44.495992 | 
(2 filas)

--get global report about 1 and 2 records
stat_record=# select * from _stat_record.global_report_record(1,2);
                                                               global_report_record                                                                  
-------------------------------------------------------------------------------------------------------------------------------------------------------
 Global report from database server, generate by stat_record extension 
 Record id 1, taked: 2020-03-01 13:50:44.495992 :->
   Version server: PostgreSQL 10.12 (Ubuntu 10.12-1.pgdg18.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 7.4.0-1ubuntu1~18.04.1) 7.4.0, 64-bit
   Server start: 2020-03-01 13:41:20.916476-03
   Server reload: 2020-03-01 13:41:20.772422-03
   Users:20
   Databases: 37
   Tablespaces: 2
   Tablespaces Names/size: 
     pg_default: 7405.00 MB
     pg_global: 1.00 MB
 Record id 2, taked: 2020-03-01 13:51:11.009518 :->
   Version server: PostgreSQL 10.12 (Ubuntu 10.12-1.pgdg18.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 7.4.0-1ubuntu1~18.04.1) 7.4.0, 64-bit
   Server start: 2020-03-01 13:41:20.916476-03
   Server reload: 2020-03-01 13:41:20.772422-03
   Users: 20
   Databases: 37
   Tablespaces: 2
   Tablespaces Names/size: 
     pg_default: 7406.00 MB
     pg_global: 1.00 MB
 Configuration Differences:->
 Databases Differences:->
     Databases count: 0 
     Databases sizes: 0.51 MB
     Databases chache ratio: 0.06 %
     Databases connections: 0 
     Databases active connections: 0 
     Databases tempfiles: 0 
     Databases tuples deleted: 0 
     Databases tuples updated: 3781 
     Databases tuples inserted: 542 
     Databases tuples fetched: 4463 
     Databases tuples returned: 107113 
     Databases rollback: 0 
     Databases commit: 20 
     Buffers_alloc: 67 
     Buffers_backend_fsync: 0 
     Buffers_backend: 0 
     Maxwritten_clean: 0 
     Buffers_clean: 0 
     Buffers_checkpoint: 0 
     Checkpoint_sync_time: 0 
     Checkpoint_write_time: 0 
     Checkpoints_req: 0 
     Checkpoints_timed: 0 
(46 filas)

--get the total(global and databse statistics) from specific record
stat_record=#select * from _stat_record.detail_record(2,10) ;
detail_record                                                                                                                                                                                                                                                                                                                                          
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 id: 2 - take date: 2020-03-01 13:51:11.009518
   --Cluster level--
   Version server: PostgreSQL 10.12 (Ubuntu 10.12-1.pgdg18.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 7.4.0-1ubuntu1~18.04.1) 7.4.0, 64-bit
   Server start: 2020-03-01 13:41:20.916476-03
   Server reload: 2020-03-01 13:41:20.772422-03
   Databases count: 37
   Databases sizes: 7390.74
   Databases chache ratio: 99.23
   Databases connections: 4
   Databases active connections: 1
   Databases tempfiles: 43
   Databases tuples deleted: 42851
   Databases tuples updated: 31239
   Databases tuples inserted: 31660959
   Databases tuples fetched: 4128815
   Databases tuples returned: 537865817
   Databases rollback: 389
   Databases commit: 425400
   Buffers_alloc: 794138
   Buffers_backend_fsync: 0
   Buffers_backend: 3716052
   Maxwritten_clean: 1210
   Buffers_clean: 225412
   Buffers_checkpoint: 430767
   Checkpoint_sync_time: 1038571
   Checkpoint_write_time: 12924989
   Checkpoints_req: 89
   Checkpoints_timed: 3780
   Users: 20
     postgres
     ...
   Tablespaces: 2
     pg_default: 7406.00 MB
     pg_global: 1.00 MB
   Databases: 37
     sr: 25.89 MB
     ...
   Configuration: 
     autovacuum_analyze_scale_factor: 0.1 
     autovacuum_naptime: 60 s
     autovacuum: on 
     autovacuum_vacuum_scale_factor: 0.2 
     effective_cache_size: 524288 8kB
     log_connections: on 
     log_disconnections: off 
     log_line_prefix: %m [%p] %q%u@%d  
     log_min_duration_statement: -1 ms
     log_statement: ddl 
     maintenance_work_mem: 65536 kB
     max_connections: 100 
     max_wal_size: 1024 MB
     shared_buffers: 16384 8kB
     statement_timeout: 0 ms
     wal_level: replica 
     work_mem: 4096 kB
   10 Querys with more call: 
     db: sr -- query: update customers set age=age+$1 where age<$2 -- calls: 7
     db: sr -- query: SELECT pg_catalog.quote_ident(c.relname) FROM pg_catalog.pg_class c WHERE c.relkind IN ($1, $2, $3, $4, $5, $6) AND substring(pg_catalog.quote_ident(c.relname),$7,$8)=$9 AND pg_catalog.pg_table_is_visible(c.oid) AND c.relnamespace <> (SELECT oid FROM pg_catalog.pg_namespace WHERE nspname = $10)                                                                                                                                                                                                                                                                                                                                                                  +
 UNION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         +
 SELECT pg_catalog.quote_ident(n.nspname) || $11 FROM pg_catalog.pg_namespace n WHERE substring(pg_catalog.quote_ident(n.nspname) || $12,$13,$14)=$15 AND (SELECT pg_catalog.count(*) FROM pg_catalog.pg_namespace WHERE substring(pg_catalog.quote_ident(nspname) || $16,$17,$18) = substring($19,$20,pg_catalog.length(pg_catalog.quote_ident(nspname))+$21)) > $22                                                                                                                                                                                                                                                                                                                          +
 UNION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         +
 SELECT pg_catalog.quote_ident(n.nspname) || $23 || pg_catalog.quote_ident(c.relname) FROM pg_catalog.pg_class c, pg_catalog.pg_namespace n WHERE c.relnamespace = n.oid AND c.relkind IN ($24, $25, $26, $27, $28, $29) AND substring(pg_catalog.quote_ident(n.nspname) || $30 || pg_catalog.quote_ident(c.relname),$31,$32)=$33 AND substring(pg_catalog.quote_ident(n.nspname) || $34,$35,$36) = substring($37,$38,pg_catalog.length(pg_catalog.quote_ident(n.nspname))+$39) AND (SELECT pg_catalog.count(*) FROM pg_catalog.pg_namespace WHERE substring(pg_catalog.quote_ident(nspname) || $40,$41,$42) = substring($43,$44,pg_catalog.length(pg_catalog.quote_ident(nspname))+$45)) = $46+
 LIMIT $47 -- calls: 7
     db: sr -- query: select * from public.products where actor = $1 -- calls: 5
     db: sr -- query: select * from public.products where actor like $1 -- calls: 4
     db: sr -- query: SELECT pg_catalog.quote_ident(attname)   FROM pg_catalog.pg_attribute a, pg_catalog.pg_class c, pg_catalog.pg_namespace n  WHERE c.oid = a.attrelid    AND n.oid = c.relnamespace    AND a.attnum > $1    AND NOT a.attisdropped    AND substring(pg_catalog.quote_ident(attname),$2,$3)=$4    AND (pg_catalog.quote_ident(relname)=$5         OR $6 || relname || $7 =$8)    AND (pg_catalog.quote_ident(nspname)=$9         OR $10 || nspname || $11 =$12)                                                                                                                                                                                                             +
 LIMIT $13 -- calls: 3
     db: stat_record -- query: SET application_name = 'PostgreSQL JDBC Driver' -- calls: 3
     db: stat_record -- query: SELECT e.typdelim FROM pg_catalog.pg_type t, pg_catalog.pg_type e WHERE t.oid = $1 and t.typelem = e.oid -- calls: 3
     db: sr -- query: SELECT pg_catalog.quote_ident(attname)   FROM pg_catalog.pg_attribute a, pg_catalog.pg_class c  WHERE c.oid = a.attrelid    AND a.attnum > $1    AND NOT a.attisdropped    AND substring(pg_catalog.quote_ident(attname),$2,$3)=$4    AND (pg_catalog.quote_ident(relname)=$5         OR $6 || relname || $7=$8)    AND pg_catalog.pg_table_is_visible(c.oid)                                                                                                                                                                                                                                                                                                            +
 LIMIT $9 -- calls: 3
     db: stat_record -- query: SELECT n.nspname = ANY(current_schemas($2)), n.nspname, t.typname FROM pg_catalog.pg_type t JOIN pg_catalog.pg_namespace n ON t.typnamespace = n.oid WHERE t.oid = $1 -- calls: 3
   10 Querys with more total time: 
     db: sr -- query: CREATE EXTENSION stat_record CASCADE -- total_time: 2725.854297 ms
     db: sr -- query: select _stat_record.take_record() -- total_time: 1184.850743 ms
     db: sr -- query: select _stat_record.take_record() -- total_time: 330.896484 ms
     db: sr -- query: update customers set age=age+$1 where age<$2 -- total_time: 251.025926 ms
     db: sr -- query: select _stat_record.take_record() -- total_time: 185.016182 ms
     db: sr -- query: drop extension stat_record -- total_time: 45.338512 ms
     db: sr -- query: select * from customers where age=$1 -- total_time: 28.807474 ms
     db: sr -- query: select * from public.products where actor like $1 -- total_time: 28.728929 ms
     db: sr -- query: select * from public.products where actor = $1 -- total_time: 22.049578 ms
   10 Querys with more mean time: 
     db: sr -- query: CREATE EXTENSION stat_record CASCADE -- mean_time: 1362.9271485 ms
     db: sr -- query: select _stat_record.take_record() -- mean_time: 1184.850743 ms
     db: sr -- query: select _stat_record.take_record() -- mean_time: 185.016182 ms
     db: sr -- query: select _stat_record.take_record() -- mean_time: 165.448242 ms
     db: sr -- query: update customers set age=age+$1 where age<$2 -- mean_time: 35.8608465714286 ms
     db: sr -- query: select * from customers where age=$1 -- mean_time: 28.807474 ms
     db: sr -- query: drop extension stat_record -- mean_time: 22.669256 ms
     db: sr -- query: select * from _stat_record.global_report_record($1,$2) -- mean_time: 13.378969 ms
     db: sr -- query: select * from public.products where actor like $1 -- mean_time: 7.18223225 ms
   10 Querys with  max time: 
     db: sr -- query: CREATE EXTENSION stat_record CASCADE -- max_time: 1373.484445 ms
     db: sr -- query: select _stat_record.take_record() -- max_time: 1184.850743 ms
     db: sr -- query: select _stat_record.take_record() -- max_time: 185.016182 ms
     db: sr -- query: select _stat_record.take_record() -- max_time: 176.612708 ms
     db: sr -- query: update customers set age=age+$1 where age<$2 -- max_time: 44.467953 ms
     db: sr -- query: select * from customers where age=$1 -- max_time: 28.807474 ms
     db: sr -- query: drop extension stat_record -- max_time: 24.294903 ms
     db: sr -- query: select * from _stat_record.global_report_record($1,$2) -- max_time: 13.378969 ms
     db: sr -- query: select * from public.products where actor like $1 -- max_time: 7.742774 ms
   10 Querys with  more row  returned: 
     db: sr -- query: update customers set age=age+$1 where age<$2 -- rows: 5645
     db: sr -- query: select * from customers where age=$1 -- rows: 297
     db: sr -- query: select * from public.products where actor like $1 -- rows: 297
     db: stat_record -- query: SELECT t.oid,t.*,c.relkind                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      +
 FROM pg_catalog.pg_type t                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     +
 LEFT OUTER JOIN pg_class c ON c.oid=t.typrelid                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                +
 WHERE typnamespace=$1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         +
 ORDER by t.oid -- rows: 284
     db: sr -- query: select * from _stat_record.global_report_record($1,$2) -- rows: 48
     db: stat_record -- query: SELECT a.oid,a.* FROM pg_catalog.pg_roles a                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     +
 ORDER BY a.oid -- rows: 30
     db: sr -- query: SELECT pg_catalog.quote_ident(c.relname) FROM pg_catalog.pg_class c WHERE c.relkind IN ($1, $2, $3, $4, $5, $6) AND substring(pg_catalog.quote_ident(c.relname),$7,$8)=$9 AND pg_catalog.pg_table_is_visible(c.oid) AND c.relnamespace <> (SELECT oid FROM pg_catalog.pg_namespace WHERE nspname = $10)                                                                                                                                                                                                                                                                                                                                                                  +
 UNION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         +
 SELECT pg_catalog.quote_ident(n.nspname) || $11 FROM pg_catalog.pg_namespace n WHERE substring(pg_catalog.quote_ident(n.nspname) || $12,$13,$14)=$15 AND (SELECT pg_catalog.count(*) FROM pg_catalog.pg_namespace WHERE substring(pg_catalog.quote_ident(nspname) || $16,$17,$18) = substring($19,$20,pg_catalog.length(pg_catalog.quote_ident(nspname))+$21)) > $22                                                                                                                                                                                                                                                                                                                          +
 UNION                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         +
 SELECT pg_catalog.quote_ident(n.nspname) || $23 || pg_catalog.quote_ident(c.relname) FROM pg_catalog.pg_class c, pg_catalog.pg_namespace n WHERE c.relnamespace = n.oid AND c.relkind IN ($24, $25, $26, $27, $28, $29) AND substring(pg_catalog.quote_ident(n.nspname) || $30 || pg_catalog.quote_ident(c.relname),$31,$32)=$33 AND substring(pg_catalog.quote_ident(n.nspname) || $34,$35,$36) = substring($37,$38,pg_catalog.length(pg_catalog.quote_ident(n.nspname))+$39) AND (SELECT pg_catalog.count(*) FROM pg_catalog.pg_namespace WHERE substring(pg_catalog.quote_ident(nspname) || $40,$41,$42) = substring($43,$44,pg_catalog.length(pg_catalog.quote_ident(nspname))+$45)) = $46+
 LIMIT $47 -- rows: 22
     db: sr -- query: select * from categories -- rows: 16
     db: sr -- query: SELECT pg_catalog.quote_ident(attname)   FROM pg_catalog.pg_attribute a, pg_catalog.pg_class c, pg_catalog.pg_namespace n  WHERE c.oid = a.attrelid    AND n.oid = c.relnamespace    AND a.attnum > $1    AND NOT a.attisdropped    AND substring(pg_catalog.quote_ident(attname),$2,$3)=$4    AND (pg_catalog.quote_ident(relname)=$5         OR $6 || relname || $7 =$8)    AND (pg_catalog.quote_ident(nspname)=$9         OR $10 || nspname || $11 =$12)                                                                                                                                                                                                             +
 LIMIT $13 -- rows: 15
   --Database level--(sr)
   Schemas: 
     public: 17.30 MB
   Table count: 8
   10 tables Weigth: 
     public.customers: 4.42 MB
     public.orderlines: 3.01 MB
     public.cust_hist: 2.55 MB
     public.products: 0.79 MB
     public.orders: 0.78 MB
     public.inventory: 0.43 MB
     public.categories: 0.01 MB
     public.reorder: 0.00 MB
   10 tables with more estimated tuples: 
     public.cust_hist: 60350 
     public.orderlines: 60350 
     public.customers: 20000 
     public.orders: 12000 
     public.products: 10000 
     public.inventory: 10000 
     public.categories: 16 
     public.reorder: 0 
   10 most consulted tables: 
     public.products: 12
     public.customers: 12
     public.orders: 4
     public.orderlines: 2
     public.cust_hist: 2
     public.categories: 2
     public.inventory: 1
     public.reorder: 0
   10 tables with more Inserted tuples: 
     public.cust_hist: 60350 
     public.orderlines: 60350 
     public.customers: 20000 
     public.orders: 12000 
     public.products: 10000 
     public.inventory: 10000 
     public.categories: 16 
     public.reorder: 0 
   10 tables with more Updated tuples: 
     public.customers: 5645 
     public.products: 0 
     public.orders: 0 
     public.orderlines: 0 
     public.inventory: 0 
     public.cust_hist: 0 
     public.reorder: 0 
     public.categories: 0 
   10 tables with more Deleted tuples: 
     public.reorder: 0 
     public.products: 0 
     public.orders: 0 
     public.orderlines: 0 
     public.inventory: 0 
     public.customers: 0 
     public.cust_hist: 0 
     public.categories: 0 
   10 tables with more Autovacuum: 
     public.reorder: 0 
     public.products: 0 
     public.orders: 0 
     public.orderlines: 0 
     public.inventory: 0 
     public.customers: 0 
     public.cust_hist: 0 
     public.categories: 0 
   10 tables with more Manual Vacuum: 
     public.reorder: 0 
     public.products: 0 
     public.orders: 0 
     public.orderlines: 0 
     public.inventory: 0 
     public.customers: 0 
     public.cust_hist: 0 
     public.categories: 0 
   10 tables with more Auto Analyze: 
     public.cust_hist: 1 
     public.products: 1 
     public.orders: 1 
     public.orderlines: 1 
     public.inventory: 1 
     public.customers: 1 
     public.categories: 0 
     public.reorder: 0 
   10 tables with more Manual Analyze: 
     public.reorder: 0 
     public.products: 0 
     public.orders: 0 
     public.orderlines: 0 
     public.inventory: 0 
     public.customers: 0 
     public.cust_hist: 0 
     public.categories: 0 
   10 indexs Weigth: 
     public.orderlines.ix_orderlines_orderid: 1.30 MB
     public.cust_hist.ix_cust_hist_customerid: 1.30 MB
     public.customers.ix_cust_username: 0.61 MB
     public.customers.customers_pkey: 0.45 MB
     public.orders.ix_order_custid: 0.27 MB
     public.orders.orders_pkey: 0.27 MB
     public.inventory.inventory_pkey: 0.23 MB
     public.products.ix_prod_category: 0.23 MB
     public.products.products_pkey: 0.23 MB
   10 indexs used: 
     public.categories.categories_pkey: 0 
     public.inventory.inventory_pkey: 0 
     public.products.ix_prod_special: 0 
     public.products.ix_prod_category: 0 
     public.products.products_pkey: 0 
     public.cust_hist.ix_cust_hist_customerid: 0 
     public.customers.ix_cust_username: 0 
     public.customers.customers_pkey: 0 
     public.orders.ix_order_custid: 0 
   10 table bloat: 
     public.cust_hist: 0.24 MB
     public.orderlines: 0.23 MB
     public.orders: 0.09 MB
     public.inventory: 0.05 MB
     public.products: 0.02 MB
     public.customers: 0.00 MB
   10 index bloat: 
     public.cust_hist->ix_cust_hist_customerid: 0.00 MB
     public.customers->customers_pkey: 0.00 MB
     public.customers->ix_cust_username: 0.00 MB
     public.inventory->inventory_pkey: 0.00 MB
     public.orderlines->ix_orderlines_orderid: 0.00 MB
     public.orders->ix_order_custid: 0.00 MB
     public.orders->orders_pkey: 0.00 MB
     public.products->ix_prod_category: 0.00 MB
     public.products->ix_prod_special: 0.00 MB
(289 filas)

--get the total(global and databse statistics) reports about 1 and 2 records and some different
stat_record=#select * from _stat_record.total_report_record(1,2);
...

--get the total reports about 1 and 2 records and some different and export to some file csv, limit 3 for objects statistics
stat_record=#select _stat_record.export_total_report_record(1,2,3,'/tmp/reporte.csv')
...

--get the total reports about last tow records taked and some different
stat_record=#select * from select * from _stat_record.total_report_for_2last_record()
...

--get the total reports about fisrt and the last records taked in the month 
stat_record=#select * from _stat_record.total_report_for_amonth_record('2019-03-01') --get report in march 2019
...

--delete some record by id
stat_record=# select _stat_record.delete_record(1);
NOTICE:  record deleted
 delete_record 
---------------
 t
(1 fila)

--delete all records and restart the id from 1, if parameters if false do nor restart de id from 1
stat_record=# select _stat_record.truncate_record( true);
NOTICE:  truncando además la tabla «_global_stat»
NOTICE:  truncando además la tabla «_db_stat»
NOTICE:  truncando además la tabla «_global_object»
NOTICE:  truncando además la tabla «_query_stat»
NOTICE:  truncando además la tabla «_so_partitions»
 truncate_record 
-----------------
 t
(1 fila)

```



Anthony R. Sotolongo leon
asotolongo@gmail.com

