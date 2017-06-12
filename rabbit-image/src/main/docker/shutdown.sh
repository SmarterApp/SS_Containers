#!/bin/bash

#Use our FQDN as hostname
export NODENAME=rabbit@$(hostname -f)

rabbitmqctl stop_app
rabbitmqctl stop
