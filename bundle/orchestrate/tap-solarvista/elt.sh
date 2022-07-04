#!/bin/bash

# exit on error
set -e

# install dbt dependencies
meltano invoke dbt deps

# try to drop users_stream table to allow snapshot to capture hard-deleted users from source
meltano invoke dbt run-operation solarvista_drop_users_stream_table || true

# run extract-load
meltano run tap-solarvista "$LOADER"

# snapshot and run transforms
meltano invoke dbt snapshot --select tap_solarvista
meltano invoke dbt run -m tap_solarvista --full-refresh
