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

# Install dbt dependencies files
meltano invoke dbt deps

# Try to drop the users_stream table to allow dbt snapshot to capture hard deleted users from source
meltano invoke dbt run-operation solarvista_drop_users_stream_table || true

# Run the elt, and dbt commands and tests
meltano elt "$EXTRACTOR" "$LOADER" --transform=skip --job_id="$EXTRACTOR"-"$LOADER"-"$IMPORTRUNNERID"
meltano invoke dbt snapshot --select tap_solarvista
meltano invoke dbt run -m tap_solarvista --full-refresh
