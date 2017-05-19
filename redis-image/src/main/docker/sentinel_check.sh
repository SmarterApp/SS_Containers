#!/bin/bash

#This script checks if a Redis sentinel is able to communicate with its selected
#Redis Server Master.

function isSentinelRunning() {
    local __resultvar=$1
    redis-cli -p ${REDIS_SENTINEL_SERVICE_PORT} sentinel master mymaster > /dev/null
    if [[ "$?" == "0" ]]; then
        eval $__resultvar=true
    else
        eval $__resultvar=false
    fi
}

#Reset the current state to remove stale sentinels and slaves
redis-cli -p ${REDIS_SENTINEL_SERVICE_PORT} sentinel reset mymaster

isSentinelRunning isRunning
echo "Is sentinel running: $isRunning"
if [[ "$isRunning" == false ]]; then
    echo "Sentinel is not running"
    exit 1
fi

exit 0