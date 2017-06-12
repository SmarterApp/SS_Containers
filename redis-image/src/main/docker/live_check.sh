#!/bin/bash

#This script checks if a Redis server is running as a Master or as a Slave
#able to communicate with its Master.

function isRedisRunning() {
    local __resultvar=$1
    redis-cli INFO > /dev/null
    if [[ "$?" == "0" ]]; then
        eval $__resultvar=true
    else
        eval $__resultvar=false
    fi
}

isRedisRunning isRunning
echo "Is redis running: $isRunning"
if [[ "$isRunning" == false ]]; then
    echo "Redis is not running"
    exit 1
fi

exit 0