EXTENSION = stat_record
MODULES = stat_record
OBJS = stat_record.so
DATA = stat_record--0.3.0.sql
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
