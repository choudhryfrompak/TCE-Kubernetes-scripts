#!/bin/bash

# Wait for SQL Server to be ready
echo "Waiting for PostgreSQL to be ready..."
for i in {1..50}; do
    TABLE_EXISTS=$(PGPASSWORD=$POSTGRES_PASSWORD psql -h test-pg-db -U $POSTGRES_USER -d $POSTGRES_DB -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'Summaries')" 2>/dev/null | xargs)
    if [ "$TABLE_EXISTS" = "t" ]; then
        echo "User table exists. PostgreSQL is ready."
        break
    else
        echo "Not ready yet or User table does not exist..."
        sleep 1
    fi
done

# Run the SQL script
PGPASSWORD=$POSTGRES_PASSWORD psql -h test-pg-db -U $POSTGRES_USER -d $POSTGRES_DB -f /scripts/seed-pg-db.sql

