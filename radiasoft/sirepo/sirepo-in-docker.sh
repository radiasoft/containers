#!/bin/bash
set -e
proto='uwsgi --docker'
if [[ $1 == http ]]; then
    proto=$1
    shift
fi
db_dir=$1
port=$2
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
sirepo service $proto --db-dir "$db_dir" --port "$port" >& start.log


# docker run -i -t -v $PWD/run:/vagrant -p 8000:8000 --link rabbit:rabbit -u vagrant radiasoft/sirepo:20151111.232429 /bin/bash -i -c 'SIREPO_SERVER_JOB_QUEUE=Celery SIREPO_CELERY_TASKS_BROKER_URL=amqp://guest@rabbit// sirepo service http --port 8000 --db-dir /vagrant'

# docker run --rm --link rabbit:rabbit --name celery -v $PWD/run:/vagrant -u vagrant radiasoft/sirepo:20151111.232429 /bin/bash -i -c 'SIREPO_CELERY_TASKS_BROKER_URL=amqp://guest@$RABBIT_PORT_5672_TCP_ADDR// celery worker -A sirepo.celery_tasks -l info'

# docker run --rm --hostname rabbit --name rabbit -p 5672:5672 rabbitmq
