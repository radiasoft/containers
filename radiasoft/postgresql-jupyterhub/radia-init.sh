#!/bin/bash
set -e
export POSTGRES_USER=postgres
export POSTGRES_DB=postgres
export JPY_PSQL_USER=jupyterhub
export JPY_PSQL_DB=jupyterhub
initdb $POSTGRES_INITDB_ARGS
pg_ctl -D "$PGDATA" -w start
psql -v ON_ERROR_STOP=1 --username postgres <<EOF
ALTER USER $POSTGRES_USER WITH SUPERUSER PASSWORD '$POSTGRES_PASSWORD';
CREATE DATABASE $JPY_PSQL_DB;
CREATE USER $JPY_PSQL_USER WITH ENCRYPTED PASSWORD '$JPY_PSQL_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE $JPY_PSQL_DB TO $JPY_PSQL_USER;
EOF
cat > "$PGDATA/pg_hba.conf" <<EOF
local all all md5
host all all 127.0.0.1/32 md5
host all all ::1/128 md5
host all all 0.0.0.0/0 md5
EOF
chmod -R go-rwx /var/lib/postgresql/data /run/postgresql
