#!/bin/bash
# 
# Start Celery with sirepo.celery_tasks
#
set -e
: ${RADIA_RUN_CHANNEL:=dev}
export SIREPO_SERVER_JOB_QUEUE=Celery
if [[ $RADIA_RUN_CHANNEL != dev ]]; then
    SIREPO_SERVER_SESSION_SECRET=$(cat "$RADIA_RUN_DIR/sirepo_celery_secret" || exit 1)
fi
export SIREPO_SERVER_SESSION_KEY=sirepo_$RADIA_RUN_CHANNEL
export SIREPO_CELERY_TASKS_BROKER_URL=amqp://guest@"$RADIA_RUN_RABBITMQ_HOST"//
export PYTHONUNBUFFERED=1
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') celery worker -A sirepo.celery_tasks" > celery_sirepo.log
celery worker -A sirepo.celery_tasks -l info 2>&1 >> celery_repo.log
