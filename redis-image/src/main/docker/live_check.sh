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

function isSlaveInstance() {
    local __resultvar=$1
    redis-cli INFO | grep 'role:slave' > /dev/null
    if [[ "$?" == "0" ]]; then
        eval $__resultvar=true
    else
        eval $__resultvar=false
    fi
}

function isMasterLinkDown() {
    local __resultvar=$1
    redis-cli INFO | grep 'master_link_down_since_seconds' > /dev/null
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

isSlaveInstance isSlave
echo "Is slave: $isSlave"
if [[ "$isSlave" == false ]]; then
    echo "Redis is a master instance"
    exit 0
fi

isMasterLinkDown isLinkDown
echo "Is link down: $isLinkDown"
if [[ "$isLinkDown" == true ]]; then
    echo "Redis Slave is unable to contact Master"
    exit 1
fi

exit 0