#!/bin/bash
#
# Start sirepo
#
set -e
if [[ $RADIA_RUN_DIR && $RADIA_RUN_PORT ]]; then
    db_dir=$RADIA_RUN_DIR
    port=$RADIA_RUN_PORT
else
    db_dir=$1
    port=$2
fi
if [[ $RADIA_RUN_RABBITMQ_HOST ]]; then
    : ${RADIA_RUN_CHANNEL:=dev}
    export SIREPO_SERVER_JOB_QUEUE=Celery
    if [[ $RADIA_RUN_CHANNEL != dev ]]; then
        SIREPO_SERVER_SESSION_SECRET=$(cat "$RADIA_RUN_DIR/sirepo_celery_secret" || exit 1)
    fi
    export SIREPO_SERVER_SESSION_KEY=sirepo_$RADIA_RUN_CHANNEL
    export SIREPO_CELERY_TASKS_BROKER_URL=amqp://guest@"$RADIA_RUN_RABBITMQ_HOST"//
fi
if [[ ! -d $db_dir ]]; then
    echo "$db_dir: db_dir doesn't exist" 1>&2
    exit 1
fi
if [[ ! $port =~ ^[0-9]{2,5}$ ]]; then
    echo "$port: port invalid port (100-99999)" 1>&2
    exit 1
fi
. ~/.bashrc
export PYTHONUNBUFFERED=1
mkdir -p "$db_dir"
cd "$db_dir"
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') sirepo service http --db-dir '$db_dir' --port '$port'" > start.log
env >> start.log
exec sirepo service http --db-dir "$db_dir" --port "$port" >> start.log 2>&1
