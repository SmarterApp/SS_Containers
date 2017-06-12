#!/bin/bash

#Use our FQDN as hostname
export NODENAME=rabbit@$(hostname -f)

rabbitmqctl status