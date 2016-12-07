#!/bin/bash

set -e -u -o pipefail

BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CRED_FILE="$BASE_DIR/comsol_credentials.txt"

test -f "$CRED_FILE" || echo "$CRED_FILE not found"

while IFS='' read -r line || [[ -n "$line" ]]; do
    USERNAME=$(echo "$line" | awk '{print $1}') 
    PASSWORD=$(echo "$line" | awk '{print $2}')
    docker exec -u root jupyterhub /opt/conda/bin/comsoljupyter db add-credentials -s /var/db/jupyterhub "$USERNAME" "$PASSWORD"
done < $CRED_FILE
