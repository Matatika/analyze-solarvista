#!/bin/bash

#
# Setup
#
meltano install

#
# Store meltano config and tap state in database
#
export MELTANO_DATABASE_URI=postgresql://${TARGET_POSTGRES_USER}:${TARGET_POSTGRES_PASSWORD}@${TARGET_POSTGRES_HOST}:${TARGET_POSTGRES_PORT}/${TARGET_POSTGRES_DBNAME}?options=-csearch_path%3D${TARGET_POSTGRES_SCHEMA}-meltano
#
# Transform into our custom target schema (these variables all required by dbt see profiles.yml)
#
export DBT_TARGET=postgres
export PG_ADDRESS=${TARGET_POSTGRES_HOST}
export PG_PORT=${TARGET_POSTGRES_PORT}
export PG_USERNAME=${TARGET_POSTGRES_USER}
export PG_PASSWORD=${TARGET_POSTGRES_PASSWORD}
export PG_DATABASE=${TARGET_POSTGRES_DBNAME}
export DBT_SOURCE_SCHEMA=${TARGET_POSTGRES_SCHEMA}
export DBT_TARGET_SCHEMA=${TARGET_POSTGRES_SCHEMA}

# try to drop the users_stream table to allow dbt snapshot to capture hard deleted users from source
set +e
time meltano invoke dbt run-operation drop_users_stream_table

# exit when any command fails
set -e

#
# Run the elt, and dbt commands and tests
#
time meltano elt tap-solarvista target-postgres --transform=skip --job_id=$TARGET_POSTGRES_SCHEMA
time meltano invoke dbt deps
time meltano invoke dbt snapshot
time meltano invoke dbt run --full-refresh
time meltano invoke dbt test
