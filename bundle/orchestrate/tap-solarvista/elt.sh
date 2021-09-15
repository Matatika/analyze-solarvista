#!/bin/bash

# Exit on error
set -e

# Meltano setup
meltano install extractor "$EXTRACTOR"
meltano install loader "$LOADER"
meltano install transform "$EXTRACTOR"
meltano install transformer dbt

# Store meltano config and tap state in database
export MELTANO_DATABASE_URI=postgresql://${TARGET_POSTGRES_USER}:${TARGET_POSTGRES_PASSWORD}@${TARGET_POSTGRES_HOST}:${TARGET_POSTGRES_PORT}/${TARGET_POSTGRES_DBNAME}?options=-csearch_path%3Dpublic

# Transform into our custom target schema (these variables all required by dbt see profiles.yml)
export DBT_TARGET=postgres
export PG_ADDRESS=${TARGET_POSTGRES_HOST}
export PG_PORT=${TARGET_POSTGRES_PORT}
export PG_USERNAME=${TARGET_POSTGRES_USER}
export PG_PASSWORD=${TARGET_POSTGRES_PASSWORD}
export PG_DATABASE=${TARGET_POSTGRES_DBNAME}
export DBT_SOURCE_SCHEMA=${TARGET_POSTGRES_SCHEMA}
export DBT_TARGET_SCHEMA=${TARGET_POSTGRES_SCHEMA}

# Install dbt dependencies files
meltano invoke dbt deps

# Try to drop the users_stream table to allow dbt snapshot to capture hard deleted users from source
meltano invoke dbt run-operation drop_users_stream_table || true

# Run the elt, and dbt commands and tests
meltano elt tap-solarvista target-postgres --transform=skip --job_id=$TARGET_POSTGRES_SCHEMA
meltano invoke dbt snapshot
meltano invoke dbt run --full-refresh
meltano invoke dbt test
