#include "postgres.h"

/* These are always necessary for a bgworker */
#include "miscadmin.h"
#include "postmaster/bgworker.h"
#include "storage/ipc.h"
#include "storage/latch.h"
#include "storage/lwlock.h"
#include "storage/proc.h"
#include "storage/shmem.h"

/* these headers are used by this particular worker's code */
#include "access/xact.h"
#include "executor/spi.h"
#include "fmgr.h"
#include "lib/stringinfo.h"
#include "pgstat.h"
#include "utils/builtins.h"
#include "utils/snapmgr.h"
#include "tcop/utility.h"

PG_MODULE_MAGIC;

void		_PG_init(void);
void    stat_record_main(Datum) pg_attribute_noreturn();

/* flags set by signal handlers */
static volatile sig_atomic_t sigterm_activated = false;
static char *countDatabaseName = "postgres";
static int interval = 3600;




static void
sighup_handler( SIGNAL_ARGS )
{
	int	caught_errno = errno;
	if (MyProc)
		SetLatch(&MyProc->procLatch);

  /* restore original errno */
	errno = caught_errno;
}

static void
sigterm_handler( SIGNAL_ARGS )
{
  sighup_handler( postgres_signal_arg );
  sigterm_activated = true;
}


 void
stat_record_main( Datum main_arg )
{

	StringInfoData queryStringData;
	initStringInfo( &queryStringData );


  char *log_username       = "postgres";



	elog( LOG, "Starting stat_record worker" );



	pqsignal( SIGHUP,  sighup_handler );
	pqsignal( SIGTERM, sigterm_handler );
  sigterm_activated = false;
	BackgroundWorkerUnblockSignals();

    #if (PG_VERSION_NUM < 110000)
	BackgroundWorkerInitializeConnection(countDatabaseName, log_username);
#else
	BackgroundWorkerInitializeConnection(countDatabaseName, log_username, 0);
#endif

	

	/*
	 * Main loop: do this until the SIGTERM handler tells us to terminate
	 */
	while ( ! sigterm_activated )
	{
		int	ret;
		int	rc;


		rc = WaitLatch( &MyProc->procLatch,
					          WL_LATCH_SET | WL_TIMEOUT | WL_POSTMASTER_DEATH,
                    1000L * interval ,
                    PG_WAIT_EXTENSION ); /* 10 seconds */
		ResetLatch( &MyProc->procLatch );

		if ( rc & WL_POSTMASTER_DEATH )
			proc_exit( 1 );


		SetCurrentStatementStartTimestamp();
		StartTransactionCommand();
		SPI_connect();
		PushActiveSnapshot( GetTransactionSnapshot() );
		pgstat_report_activity( STATE_RUNNING, queryStringData.data );

		resetStringInfo( &queryStringData );
		appendStringInfo( &queryStringData,
                      "select _stat_record.take_record(); " );


		elog( LOG, "Taking record with stat_record" );

		ret = SPI_execute( queryStringData.data, /* query to execute */
                       false,                /* not readonly query */
                       0 );                  /* no count limit */
        
		if ( ret != SPI_OK_SELECT )
			elog( FATAL, "stat_record: SPI_execute failed with error code: %d", ret );


		SPI_finish();
		PopActiveSnapshot();
		CommitTransactionCommand();
		pgstat_report_activity( STATE_IDLE, NULL );
	}

	proc_exit(0);

}


void
_PG_init(void)
{
	BackgroundWorker worker;

    DefineCustomStringVariable(
		"stat_record.database_name",
		"Database in which stat_record work.",
		NULL,
		&countDatabaseName,
		"postgres",
		PGC_SIGHUP,
        0,
        NULL,
        NULL,
        NULL);

	DefineCustomIntVariable(
		"stat_record.interval",
		"Interval which stat_record will work  for take a record",
		NULL,
		&interval,
		3600,
		1,
		INT_MAX,
		PGC_SIGHUP,
		0,
		NULL,
		NULL,
		NULL);  
		

	/* set up worker data */
	worker.bgw_flags         = BGWORKER_SHMEM_ACCESS
                             | BGWORKER_BACKEND_DATABASE_CONNECTION;
	worker.bgw_start_time    = BgWorkerStart_RecoveryFinished;
	worker.bgw_restart_time  = BGW_NEVER_RESTART;
	snprintf( worker.bgw_name, BGW_MAXLEN, "stat_record worker" );
    snprintf( worker.bgw_function_name, BGW_MAXLEN, "stat_record_main" );
    snprintf( worker.bgw_library_name, BGW_MAXLEN, "stat_record" );
    worker.bgw_notify_pid    = 0;

    elog( LOG, "stat_record::_PG_init registering worker [%s]", worker.bgw_name );

	/* register worker */
	RegisterBackgroundWorker(&worker);
}