#!/bin/bash

# Start PostgreSQL
su -c "/usr/pgsql-12/bin/postgres" - postgres &> /dev/null &

# Wait for PostgreSQL to be Up
sleep 5

# Execute Init SQL File
su -c 'psql -f postgres-init.sql' - postgres

# Stop PostgreSQL
pkill -f postgres
