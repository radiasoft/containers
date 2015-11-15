#!/bin/bash
#
# Start rabbitmq-server with appropriate commands
#
set -e
# RabbitMQ seems to need this
export HOME=$RADIA_RUN_DIR
export RABBITMQ_HOME=$RADIA_RUN_DIR
export RABBITMQ_CONFIG_FILE=$RADIA_RUN_DIR/rabbitmq
export RABBITMQ_LOG_BASE=$RADIA_RUN_DIR/log
export RABBITMQ_MNESIA_BASE=$RADIA_RUN_DIR/mnesia
# Erlang appends the .config to $RABBITMQ_CONFIG_FILE so we have to here
# loopback_users is empty, because we want all users to be able to connect
# via any host interface (default is [<<"guest">>])
cat <<EOF > "$RABBITMQ_CONFIG_FILE.config"
[{rabbit, [{loopback_users, []}]}].
EOF
mkdir -p "$RABBITMQ_LOG_BASE" "$RABBITMQ_MNESIA_BASE"

# /usr/sbin/rabbitmq-server script hardwires the rabbit user to be root or rabbit
# so we execute it directly after setting up the environment
exec /usr/lib/rabbitmq/bin/rabbitmq-server
