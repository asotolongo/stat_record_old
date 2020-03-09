stat_record  extension
======================================



Because of PostgreSQL stores current statistics, this extension is implemented the concept of "snapshots" to record statistics(pg_stat_* and some other information) from the PostgreSQL database server at any time and can be consulted when required,
Periodic snapshots can help you see/analyze the evolution of the database server and can characterize it, the take the "snapshot" is made by self PostgreSQL , no need external agent or cron tool
Also display several reports on statistics and evolution such as: connection, size, cache, usage of table and index, 
queries, bloat, etc. and you can compare some statistics over time to see the changes. This PostgreSQL extension can be useful for the DBA to analyze server behavior over time. 

#required PG10+ and  pg_stat_statements extension


Statistics and information collected
-------
  * Information 
   * server version
   * server start/reload
   * WAL information
   * Users
   * Tablespaces
   * Configurations
 * Statistics
   * Database 
   * Bgwriter 
   * Queries 
   * Tables
   * Indexes
   * Maintenance
   * Bloat
       
 
 


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
stat_record.interval = 3600 -- in sec default 3600 seconds (1h)
stat_record.retention = 7 -- in days default 7 days 
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


The extension create schema stat_record and tables/functions/view

--Tables:
```
_stat_record._record_number ----table where store data about the record taked

_stat_record._global_stat ---- table where store data about global stats

_stat_record._db_stat ---- table where store data about database stats

_stat_record._query_stat ---- table where store data about database query stats

```

--View
```v_global_stat_value_diff ---- show information about global server values and snapshot diff, to see evolution of database
```

--Functions:
```
select _stat_record.take_record()  ---- take stats record about server and databases
select _stat_record.truncate_record( boolean) ---- truncate all record taked (boolean = true, reset id_record to 1)
select _stat_record.delete_record(bigint) ---- delete a record with id_record parameter

--reports functions
select * from _stat_record.detail_record (bigint) ----get report with all global, database , objects and  querys stats about one specific record
select * from _stat_record.lastest_records(bigint) ---- get the lastes record (if a number (N) is specified, it shows the last N records)
select * from _stat_record.global_report_record(bigint,bigint) ----get report with global stats about id_record specified
select * from _stat_record.total_report_record(bigint,bigint) ----get report with all global, database, objects and  querys stats about id_records specified
select * from _stat_record.total_report_for_2last_record() -----get report with all global, database , objects and  querys stats about two last record taked
select * from _stat_record.total_report_for_amonth_record(date) -----get report with all global,  database , objecst and  querys stats about first and the last record taked a moth specified
select _stat_record.export_total_report_record(bigint,bigint,text) ----export CSV report with all global,  database , objects and  querys stats about first and the last record taked a moth specified y some path(by default /tmp/global_report.csv)
--reports functions
```


Example of use:
--------

```
--get all records taken
stat_record=#select * from  _stat_record._record_number order by 2 desc;
 id_record |         date_take          | description 
-----------+----------------------------+-------------
         7 | 2020-03-07 07:12:58.459051 | 
         6 | 2020-03-07 07:12:12.856504 | 
         5 | 2020-03-07 07:06:05.774309 | 
         4 | 2020-03-07 07:02:03.645995 | 
         3 | 2020-03-07 06:52:03.288628 | 
(7 filas)


--take a manual record
stat_record=# select _stat_record.take_record();
NOTICE:  record taked
 take_record 
-------------
 t
(1 fila)


--get global report about 3 and 7 records
stat_record=# select * from _stat_record.global_report_record(1,2);
                                                               global_report_record                                                                  
-------------------------------------------------------------------------------------------------------------------------------------------------------
 Global report from database server, generate by stat_record extension 
 Record id 3, taked: 2020-03-07 06:52:03.288628 :->
   Version server: PostgreSQL 10.12 (Ubuntu 10.12-2.pgdg18.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 7.4.0-1ubuntu1~18.04.1) 7.4.0, 64-bit
   Server start: 2020-03-04 08:49:58.207547-03
   Server reload: 2020-03-04 08:49:57.626657-03
   Wal file: 000000010000000B00000011
   Wal Location: B/11ED6FA8
   Users:20
   Databases: 38
   Tablespaces: 2
   Tablespaces Names/size: 
     pg_default: 7431.00 MB
     pg_global: 1.00 MB
 Record id 7, taked: 2020-03-07 07:12:58.459051 :->
   Version server: PostgreSQL 10.12 (Ubuntu 10.12-2.pgdg18.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 7.4.0-1ubuntu1~18.04.1) 7.4.0, 64-bit
   Server start: 2020-03-04 08:49:58.207547-03
   Server reload: 2020-03-07 07:06:19.320798-03
   Wal file: 000000010000000B00000016
   Wal Location: B/16485178
   Users: 20
   Databases: 38
   Tablespaces: 2
   Tablespaces Names/size: 
     pg_default: 7473.00 MB
     pg_global: 1.00 MB
 Configuration Differences:->
 Databases Differences:->
     Databases count: 0 
     Databases sizes: 41.36 MB
     Databases chache ratio: 0.00 %
     Databases connections: 2 
     Databases active connections: 0 
     Databases deadlocks: 0 
     Databases conflicts: 0 
     Databases tempfiles: 0 
     Databases tuples deleted: 32 
     Databases tuples updated: 14 
     Databases tuples inserted: 1004597 
     Databases tuples fetched: 56896 
     Databases tuples returned: 786847 
     Databases rollback: 10 
     Databases commit: 771 
     BGwriter Buffers_alloc: 5505 
     BGwriter Buffers_backend_fsync: 0 
     BGwriter Buffers_backend: 633 
     BGwriter Maxwritten_clean: 0 
     BGwriter Buffers_clean: 0 
     BGwriter Buffers_checkpoint: 986 
     BGwriter Checkpoint_sync_time: 1371 
     BGwriter Checkpoint_write_time: 98844 
     BGwriter Checkpoints_req: 0 
     BGwriter Checkpoints_timed: 4 
     Wal Location: 70 MB 
(53 filas)


--get the total(global and databse statistics) from specific record
stat_record=#select * from _stat_record.detail_record(7,5) ;
detail_record                                                                                                                                                                                                                                                                                                                                          
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 id: 7 - take date: 2020-03-07 07:12:58.459051
   --Cluster level--
   Version server: PostgreSQL 10.12 (Ubuntu 10.12-2.pgdg18.04+1) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 7.4.0-1ubuntu1~18.04.1) 7.4.0, 64-bit
   Server start: 2020-03-04 08:49:58.207547-03
   Server reload: 2020-03-07 07:06:19.320798-03
   Databases count: 38
   Databases sizes: 7457.47
   Databases chache ratio: 99.31
   Databases connections: 7
   Databases active connections: 1
   Databases deadlocks: 0
   Databases conflicts: 0
   Databases tempfiles: 43
   Databases tuples deleted: 58678
   Databases tuples updated: 48621
   Databases tuples inserted: 35339579
   Databases tuples fetched: 6958996
   Databases tuples returned: 623421970
   Databases rollback: 4778
   Databases commit: 541687
   BGwriter Buffers_alloc: 880117
   BGwriter Buffers_backend_fsync: 0
   BGwriter Buffers_backend: 3775014
   BGwriter Maxwritten_clean: 1210
   BGwriter Buffers_clean: 225413
   BGwriter Buffers_checkpoint: 486566
   BGwriter Checkpoint_sync_time: 1170930
   BGwriter Checkpoint_write_time: 18046732
   BGwriter Checkpoints_req: 97
   BGwriter Checkpoints_timed: 4287
   Wal file: 000000010000000B00000016
   Wal Location: B/16485178
   Users: 20
     postgres
     ...
     Tablespaces: 2
     pg_default: 7473.00 MB
     pg_global: 1.00 MB
   Databases: 38
     postgres: 9.53 MB
     ...
   Configuration: 
     autovacuum_analyze_scale_factor: 0.1 
     autovacuum_max_workers: 3 
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
     max_parallel_workers: 8 
     max_parallel_workers_per_gather: 2 
     max_wal_size: 1024 MB
     shared_buffers: 16384 8kB
     statement_timeout: 0 ms
     wal_level: replica 
     work_mem: 4096 kB
   5 Queries with more call: 
   5 Queries with more total time: 
   5 Queries with more mean time: 
   5 Queriess with  max time: 
   5 Queries with  more row  returned: 
   5 Queries with least cache ratio: 
   --Database level--(lpm)
   Schemas: 
     public: 51.32 MB
   Table count: 10
   5 tables Weigth: 
     public.tabla1: 34.57 MB
     public.customers: 3.81 MB
     public.orderlines: 3.01 MB
     public.cust_hist: 2.55 MB
     public.products: 0.79 MB
   5 tables with more estimated tuples: 
     public.cust_hist: 60350 
     public.orderlines: 60350 
     public.customers: 20000 
     public.orders: 12000 
     public.inventory: 10000 
   5 most consulted tables: 
   5 tables with more Inserted tuples: 
     public.tabla1: 3213000 
     public.orderlines: 60350 
     public.cust_hist: 60350 
     public.customers: 20000 
     public.orders: 12000 
   5 tables with more Updated tuples: 
     public.customers: 11516 
     public.tab: 0 
     public.reorder: 0 
     public.products: 0 
     public.orders: 0 
   5 tables with more Deleted tuples: 
     public.tabla1: 13000 
     public.tab: 0 
     public.reorder: 0 
     public.products: 0 
 public.orders: 0 
   5 tables with more Autovacuum: 
     public.customers: 1 
     public.tabla1: 1 
     public.reorder: 0 
     public.products: 0 
     public.orders: 0 
   5 tables with more Manual Vacuum: 
     public.customers: 1 
     public.tab: 0 
     public.reorder: 0 
     public.products: 0 
     public.orders: 0 
   5 tables with more Auto Analyze: 
     public.tabla1: 6 
     public.customers: 3 
     public.orders: 1 
     public.orderlines: 1 
     public.products: 1 
   5 tables with more Manual Analyze: 
     public.tabla1: 0 
     public.tab: 0 
     public.reorder: 0 
     public.products: 0 
     public.orders: 0 
   5 indexs Weigth: 
     public.orderlines.ix_orderlines_orderid: 1.30 MB
     public.cust_hist.ix_cust_hist_customerid: 1.30 MB
     public.customers.ix_cust_username: 0.61 MB
     public.customers.customers_pkey: 0.45 MB
     public.orders.ix_order_custid: 0.27 MB
   5 indexs used: 
     public.customers.customers_pkey: 6 
     public.cust_hist.ix_cust_hist_customerid: 2 
     public.products.ix_prod_special: 0 
     public.products.ix_prod_category: 0 
     public.products.products_pkey: 0 
   5 table bloat: 
     public.cust_hist: 0.24 MB
     public.orderlines: 0.23 MB
     public.orders: 0.09 MB
     public.inventory: 0.05 MB
     public.products: 0.02 MB
   5 index bloat: 
     public.cust_hist->ix_cust_hist_customerid: 0.00 MB
     public.customers->customers_pkey: 0.00 MB
     public.customers->ix_cust_username: 0.00 MB
     public.inventory->inventory_pkey: 0.00 MB
     public.orderlines->ix_orderlines_orderid: 0.00 MB
(205 filas)


--get information about global server values and diff of snapshots
stat_record=#select * from _stat_record.v_global_stat_value_diff;
 id_record |         date_take          |            var_name            |    val     |  diff   
-----------+----------------------------+--------------------------------+------------+---------
         3 | 2020-03-07 06:52:03.288628 | BGwriter Buffers_alloc         | 874612     | 
         4 | 2020-03-07 07:02:03.645995 | BGwriter Buffers_alloc         | 875028     | 416
         5 | 2020-03-07 07:06:05.774309 | BGwriter Buffers_alloc         | 875240     | 212
         6 | 2020-03-07 07:12:12.856504 | BGwriter Buffers_alloc         | 875458     | 218
         7 | 2020-03-07 07:12:58.459051 | BGwriter Buffers_alloc         | 880117     | 4659
         3 | 2020-03-07 06:52:03.288628 | BGwriter Buffers_backend       | 3774381    | 
         4 | 2020-03-07 07:02:03.645995 | BGwriter Buffers_backend       | 3774589    | 208
         5 | 2020-03-07 07:06:05.774309 | BGwriter Buffers_backend       | 3774802    | 213
         6 | 2020-03-07 07:12:12.856504 | BGwriter Buffers_backend       | 3775014    | 212
         7 | 2020-03-07 07:12:58.459051 | BGwriter Buffers_backend       | 3775014    | 0
         3 | 2020-03-07 06:52:03.288628 | BGwriter Buffers_backend_fsync | 0          | 
         4 | 2020-03-07 07:02:03.645995 | BGwriter Buffers_backend_fsync | 0          | 0
         5 | 2020-03-07 07:06:05.774309 | BGwriter Buffers_backend_fsync | 0          | 0
         6 | 2020-03-07 07:12:12.856504 | BGwriter Buffers_backend_fsync | 0          | 0
         7 | 2020-03-07 07:12:58.459051 | BGwriter Buffers_backend_fsync | 0          | 0
         3 | 2020-03-07 06:52:03.288628 | BGwriter Buffers_checkpoint    | 485580     | 
         4 | 2020-03-07 07:02:03.645995 | BGwriter Buffers_checkpoint    | 486094     | 514
         5 | 2020-03-07 07:06:05.774309 | BGwriter Buffers_checkpoint    | 486191     | 97
         6 | 2020-03-07 07:12:12.856504 | BGwriter Buffers_checkpoint    | 486566     | 375
         7 | 2020-03-07 07:12:58.459051 | BGwriter Buffers_checkpoint    | 486566     | 0
         3 | 2020-03-07 06:52:03.288628 | BGwriter Buffers_clean         | 225413     | 
         4 | 2020-03-07 07:02:03.645995 | BGwriter Buffers_clean         | 225413     | 0
         5 | 2020-03-07 07:06:05.774309 | BGwriter Buffers_clean         | 225413     | 0
         6 | 2020-03-07 07:12:12.856504 | BGwriter Buffers_clean         | 225413     | 0
         7 | 2020-03-07 07:12:58.459051 | BGwriter Buffers_clean         | 225413     | 0
         3 | 2020-03-07 06:52:03.288628 | BGwriter Checkpoints_req       | 97         | 
         4 | 2020-03-07 07:02:03.645995 | BGwriter Checkpoints_req       | 97         | 0
         5 | 2020-03-07 07:06:05.774309 | BGwriter Checkpoints_req       | 97         | 0
         6 | 2020-03-07 07:12:12.856504 | BGwriter Checkpoints_req       | 97         | 0
         7 | 2020-03-07 07:12:58.459051 | BGwriter Checkpoints_req       | 97         | 0
         3 | 2020-03-07 06:52:03.288628 | BGwriter Checkpoints_timed     | 4283       | 
         4 | 2020-03-07 07:02:03.645995 | BGwriter Checkpoints_timed     | 4285       | 2
         5 | 2020-03-07 07:06:05.774309 | BGwriter Checkpoints_timed     | 4286       | 1
         6 | 2020-03-07 07:12:12.856504 | BGwriter Checkpoints_timed     | 4287       | 1
         7 | 2020-03-07 07:12:58.459051 | BGwriter Checkpoints_timed     | 4287       | 0
         3 | 2020-03-07 06:52:03.288628 | BGwriter Checkpoint_sync_time  | 1169559    | 
         4 | 2020-03-07 07:02:03.645995 | BGwriter Checkpoint_sync_time  | 1169668    | 109
         5 | 2020-03-07 07:06:05.774309 | BGwriter Checkpoint_sync_time  | 1169668    | 0
         6 | 2020-03-07 07:12:12.856504 | BGwriter Checkpoint_sync_time  | 1170930    | 1262
         7 | 2020-03-07 07:12:58.459051 | BGwriter Checkpoint_sync_time  | 1170930    | 0
         3 | 2020-03-07 06:52:03.288628 | BGwriter Checkpoint_write_time | 17947888   | 
         4 | 2020-03-07 07:02:03.645995 | BGwriter Checkpoint_write_time | 17999167   | 51279
         5 | 2020-03-07 07:06:05.774309 | BGwriter Checkpoint_write_time | 17999167   | 0
         6 | 2020-03-07 07:12:12.856504 | BGwriter Checkpoint_write_time | 18046732   | 47565
         7 | 2020-03-07 07:12:58.459051 | BGwriter Checkpoint_write_time | 18046732   | 0
         3 | 2020-03-07 06:52:03.288628 | BGwriter Maxwritten_clean      | 1210       | 
         4 | 2020-03-07 07:02:03.645995 | BGwriter Maxwritten_clean      | 1210       | 0
         5 | 2020-03-07 07:06:05.774309 | BGwriter Maxwritten_clean      | 1210       | 0
         6 | 2020-03-07 07:12:12.856504 | BGwriter Maxwritten_clean      | 1210       | 0
         7 | 2020-03-07 07:12:58.459051 | BGwriter Maxwritten_clean      | 1210       | 0
          3 | 2020-03-07 06:52:03.288628 | Databases active connections   | 1          | 
         4 | 2020-03-07 07:02:03.645995 | Databases active connections   | 1          | 0
         5 | 2020-03-07 07:06:05.774309 | Databases active connections   | 1          | 0
         6 | 2020-03-07 07:12:12.856504 | Databases active connections   | 1          | 0
         7 | 2020-03-07 07:12:58.459051 | Databases active connections   | 1          | 0
         3 | 2020-03-07 06:52:03.288628 | Databases chache ratio         | 99.31      | 
         4 | 2020-03-07 07:02:03.645995 | Databases chache ratio         | 99.31      | 0.00
         5 | 2020-03-07 07:06:05.774309 | Databases chache ratio         | 99.31      | 0.00
         6 | 2020-03-07 07:12:12.856504 | Databases chache ratio         | 99.31      | 0.00
         7 | 2020-03-07 07:12:58.459051 | Databases chache ratio         | 99.31      | 0.00
         3 | 2020-03-07 06:52:03.288628 | Databases commit               | 540916     | 
         4 | 2020-03-07 07:02:03.645995 | Databases commit               | 541267     | 351
         5 | 2020-03-07 07:06:05.774309 | Databases commit               | 541405     | 138
         6 | 2020-03-07 07:12:12.856504 | Databases commit               | 541653     | 248
         7 | 2020-03-07 07:12:58.459051 | Databases commit               | 541687     | 34
         3 | 2020-03-07 06:52:03.288628 | Databases conflicts            | 0          | 
         4 | 2020-03-07 07:02:03.645995 | Databases conflicts            | 0          | 0
         5 | 2020-03-07 07:06:05.774309 | Databases conflicts            | 0          | 0
         6 | 2020-03-07 07:12:12.856504 | Databases conflicts            | 0          | 0
         7 | 2020-03-07 07:12:58.459051 | Databases conflicts            | 0          | 0
         3 | 2020-03-07 06:52:03.288628 | Databases connections          | 5          | 
         4 | 2020-03-07 07:02:03.645995 | Databases connections          | 8          | 3
         5 | 2020-03-07 07:06:05.774309 | Databases connections          | 7          | -1
         6 | 2020-03-07 07:12:12.856504 | Databases connections          | 7          | 0
         7 | 2020-03-07 07:12:58.459051 | Databases connections          | 7          | 0
         3 | 2020-03-07 06:52:03.288628 | Databases count                | 38         | 
         4 | 2020-03-07 07:02:03.645995 | Databases count                | 38         | 0
         5 | 2020-03-07 07:06:05.774309 | Databases count                | 38         | 0
         6 | 2020-03-07 07:12:12.856504 | Databases count                | 38         | 0
         7 | 2020-03-07 07:12:58.459051 | Databases count                | 38         | 0
         3 | 2020-03-07 06:52:03.288628 | Databases deadlocks            | 0          | 
         4 | 2020-03-07 07:02:03.645995 | Databases deadlocks            | 0          | 0
         5 | 2020-03-07 07:06:05.774309 | Databases deadlocks            | 0          | 0
         6 | 2020-03-07 07:12:12.856504 | Databases deadlocks            | 0          | 0
         7 | 2020-03-07 07:12:58.459051 | Databases deadlocks            | 0          | 0
         3 | 2020-03-07 06:52:03.288628 | Databases rollback             | 4768       | 
         4 | 2020-03-07 07:02:03.645995 | Databases rollback             | 4773       | 5
         5 | 2020-03-07 07:06:05.774309 | Databases rollback             | 4773       | 0
         6 | 2020-03-07 07:12:12.856504 | Databases rollback             | 4778       | 5
         7 | 2020-03-07 07:12:58.459051 | Databases rollback             | 4778       | 0
         3 | 2020-03-07 06:52:03.288628 | Databases sizes                | 7416.11    | 
         4 | 2020-03-07 07:02:03.645995 | Databases sizes                | 7417.73    | 1.62
         5 | 2020-03-07 07:06:05.774309 | Databases sizes                | 7419.40    | 1.67
         6 | 2020-03-07 07:12:12.856504 | Databases sizes                | 7421.07    | 1.67
         7 | 2020-03-07 07:12:58.459051 | Databases sizes                | 7457.47    | 36.40
         3 | 2020-03-07 06:52:03.288628 | Databases tempfiles            | 43         | 
         4 | 2020-03-07 07:02:03.645995 | Databases tempfiles            | 43         | 0
         5 | 2020-03-07 07:06:05.774309 | Databases tempfiles            | 43         | 0
         6 | 2020-03-07 07:12:12.856504 | Databases tempfiles            | 43         | 0
         7 | 2020-03-07 07:12:58.459051 | Databases tempfiles            | 43         | 0
         3 | 2020-03-07 06:52:03.288628 | Databases tuples deleted       | 58646      | 
         4 | 2020-03-07 07:02:03.645995 | Databases tuples deleted       | 58658      | 12
         5 | 2020-03-07 07:06:05.774309 | Databases tuples deleted       | 58658      | 0
         6 | 2020-03-07 07:12:12.856504 | Databases tuples deleted       | 58678      | 20
         7 | 2020-03-07 07:12:58.459051 | Databases tuples deleted       | 58678      | 0
         3 | 2020-03-07 06:52:03.288628 | Databases tuples fetched       | 6902100    | 
         4 | 2020-03-07 07:02:03.645995 | Databases tuples fetched       | 6951068    | 48968
         5 | 2020-03-07 07:06:05.774309 | Databases tuples fetched       | 6951808    | 740
         6 | 2020-03-07 07:12:12.856504 | Databases tuples fetched       | 6953170    | 1362
         7 | 2020-03-07 07:12:58.459051 | Databases tuples fetched       | 6958996    | 5826
         3 | 2020-03-07 06:52:03.288628 | Databases tuples inserted      | 34334982   | 
         4 | 2020-03-07 07:02:03.645995 | Databases tuples inserted      | 34334994   | 12
         5 | 2020-03-07 07:06:05.774309 | Databases tuples inserted      | 34334994   | 0
         6 | 2020-03-07 07:12:12.856504 | Databases tuples inserted      | 34335014   | 20
         7 | 2020-03-07 07:12:58.459051 | Databases tuples inserted      | 35339579   | 1004565
         3 | 2020-03-07 06:52:03.288628 | Databases tuples returned      | 622635123  | 
         4 | 2020-03-07 07:02:03.645995 | Databases tuples returned      | 623036689  | 401566
         5 | 2020-03-07 07:06:05.774309 | Databases tuples returned      | 623172504  | 135815
         6 | 2020-03-07 07:12:12.856504 | Databases tuples returned      | 623382317  | 209813
         7 | 2020-03-07 07:12:58.459051 | Databases tuples returned      | 623421970  | 39653
         3 | 2020-03-07 06:52:03.288628 | Databases tuples updated       | 48607      | 
         4 | 2020-03-07 07:02:03.645995 | Databases tuples updated       | 48613      | 6
         5 | 2020-03-07 07:06:05.774309 | Databases tuples updated       | 48613      | 0
         6 | 2020-03-07 07:12:12.856504 | Databases tuples updated       | 48619      | 6
         7 | 2020-03-07 07:12:58.459051 | Databases tuples updated       | 48621      | 2
         3 | 2020-03-07 06:52:03.288628 | Wal Location                   | B/11ED6FA8 | 
         4 | 2020-03-07 07:02:03.645995 | Wal Location                   | B/120EC350 | 2133 kB
         5 | 2020-03-07 07:06:05.774309 | Wal Location                   | B/122F6220 | 2088 kB
         6 | 2020-03-07 07:12:12.856504 | Wal Location                   | B/1251C000 | 2199 kB
         7 | 2020-03-07 07:12:58.459051 | Wal Location                   | B/16485178 | 63 MB
(130 filas)



 
--get the total(global and databse statistics) reports about 3 and 7 records and some different
stat_record=#select * from _stat_record.total_report_record(3,7);
...

--get the total reports about 3 and 7 records and some different and export to some file csv, limit 3 for objects statistics
stat_record=#select _stat_record.export_total_report_record(3,7,3,'/tmp/reporte.csv')
...

--get the total reports about last tow records taked and some different
stat_record=#select * from _stat_record.total_report_for_2last_record()
...

--get the total reports about fisrt and the last records taked in the month 
stat_record=#select * from _stat_record.total_report_for_amonth_record('2020-03-01') --get report in march 2020
...

--delete some record by id
stat_record=# select _stat_record.delete_record(3);
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



Anthony R. Sotolongo León
asotolongo@gmail.com

