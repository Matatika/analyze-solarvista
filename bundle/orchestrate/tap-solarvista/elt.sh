#!/bin/bash

# Exit on error
set -e

# Meltano setup
meltano install extractor "$EXTRACTOR"
meltano install loader "$LOADER"
meltano install transform "$EXTRACTOR"
meltano install transformer dbt

# Install dbt dependencies files
meltano invoke dbt deps

# Try to drop the users_stream table to allow dbt snapshot to capture hard deleted users from source
meltano invoke dbt run-operation drop_users_stream_table || true

# Run the elt, and dbt commands and tests
meltano elt tap-solarvista target-postgres --transform=skip
meltano invoke dbt snapshot --select tap_solarvista
meltano invoke dbt run -m tap_solarvista --full-refresh