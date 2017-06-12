#!/bin/bash

#Use our FQDN as hostname
export NODENAME=rabbit@$(hostname -f)

# Set the memory high watermark
sed -i "s/%memory_limit%/${RABBITMQ_MEMORY_LIMIT}/" /etc/rabbitmq/rabbitmq.config

# Set the free disk alarm
sed -i "s/%disk_limit%/${RABBITMQ_DISK_LIMIT}/" /etc/rabbitmq/rabbitmq.config

rabbitmq-server