#!/bin/bash
rabbitmq-server -detached
sleep 10
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster rabbit@rabbitmq1
rabbitmqctl start_app

tail -f /var/log/rabbitmq/rabbit@rabbitmq2.log