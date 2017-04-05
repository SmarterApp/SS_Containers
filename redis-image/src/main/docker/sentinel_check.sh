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

function getMasterAddress() {
    local __resultvar=$1
    local master=$(redis-cli -p ${REDIS_SENTINEL_SERVICE_PORT} --csv SENTINEL get-master-addr-by-name mymaster | tr ',' ' ' | cut -d' ' -f1)
    if [[ -n ${master} ]]; then
        eval $__resultvar="${master//\"}"
    fi
}

function isMasterDown() {
    local __resultvar=$1
    redis-cli -h ${masterAddr} INFO > /dev/null
    if [[ "$?" == "0" ]]; then
        eval $__resultvar=false
    else
        eval $__resultvar=true
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

getMasterAddress masterAddr
echo "Master addr: $masterAddr"
if [[ -z ${masterAddr} ]]; then
    echo "No master found"
    exit 1
fi

isMasterDown masterDown
echo "Is master down: $masterDown"
if [[ "$masterDown" == true ]]; then
    echo "Redis Sentinel is unable to contact Master"
    exit 1
fi

exit 0