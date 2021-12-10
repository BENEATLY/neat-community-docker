#!/bin/bash

################################################################################
# Author:     Thomas D'haenens
# License:    GPL-3.0
# Link:       https://github.com/BENEATLY/neat-community-docker/
# Contact:    https://neatly.be/
################################################################################


# Start PostgreSQL
su -c "/usr/pgsql-12/bin/postgres" - postgres &> /dev/null &

# Wait for PostgreSQL to be Up
sleep 5

# Execute Init SQL File
su -c 'psql -f postgres-init.sql' - postgres

# Stop PostgreSQL
pkill -f postgres
