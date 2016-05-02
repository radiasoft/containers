#!/bin/bash
gosu postgres psql -f - <<EOF
CREATE DATABASE jupyterhub;
CREATE USER jupyterhub WITH ENCRYPTED PASSWORD '$JPY_PSQL_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE jupyterhub TO jupyterhub;
EOF
