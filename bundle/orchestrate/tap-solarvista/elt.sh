#!/bin/bash

# Exit on error
set -e

# Meltano setup
meltano install extractor "$EXTRACTOR"
meltano install loader "$LOADER"
meltano install transform "$EXTRACTOR"
meltano install transformer dbt

# Temporary fix for markdown dependencies issue: https://github.com/dbt-labs/dbt-core/issues/4745
.meltano/transformers/dbt/venv/bin/pip3 install --force-reinstall MarkupSafe==2.0.1

# Store meltano config and tap state in database
if [ $DBT_TARGET = "postgres" ]; then
    export MELTANO_DATABASE_URI=postgresql://${TARGET_POSTGRES_USER}:${TARGET_POSTGRES_PASSWORD}@${TARGET_POSTGRES_HOST}:${TARGET_POSTGRES_PORT}/${TARGET_POSTGRES_DBNAME}?options=-csearch_path%3Dpublic
    export MELTANO_JOB_ID="${EXTRACTOR}"_"${LOADER}"_"${TARGET_POSTGRES_SCHEMA}"
else
    export MELTANO_JOB_ID="$EXTRACTOR"
fi

# Install dbt dependencies files
meltano invoke dbt deps

# Try to drop the users_stream table to allow dbt snapshot to capture hard deleted users from source
meltano invoke dbt run-operation solarvista_drop_users_stream_table || true

# Run the elt, and dbt commands and tests
meltano elt "$EXTRACTOR" "$LOADER" --transform=skip --job_id=$MELTANO_JOB_ID
meltano invoke dbt snapshot --select tap_solarvista
meltano invoke dbt run -m tap_solarvista --full-refresh
