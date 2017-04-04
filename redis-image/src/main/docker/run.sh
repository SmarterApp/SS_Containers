#!/bin/bash

# Note this is heavily based off of the kubernetes example at:
# https://github.com/kubernetes/kubernetes/blob/master/examples/storage/redis/image/run.sh
# This script has been modified for initial redis master bootstrapping using a leader election sidecar.

function findmaster() {
  #First check with the sentinels
  master=$(redis-cli -h ${REDIS_SENTINEL_SERVICE_HOST} -p ${REDIS_SENTINEL_SERVICE_PORT} --csv SENTINEL get-master-addr-by-name mymaster | tr ',' ' ' | cut -d' ' -f1)
  echo "Master from sentinels: ${master}"
  if [[ -n ${master} ]]; then
    master="${master//\"}"
  else
    #Check with leader election via service
    master=$(curl http://${REDIS_SERVER_SERVICE_HOST}:4040/ | python -c 'import sys, json; print json.load(sys.stdin)["name"]')
    echo "Master from leader election via service: ${master}"

    if [[ -z ${master} ]]; then
      #Check with leader election via localhost
      master=$(curl http://localhost:4040/ | python -c 'import sys, json; print json.load(sys.stdin)["name"]')
      echo "Master from leader election via localhost: ${master}"
    fi
  fi
}

function launchmaster() {
  echo "Launching as Master"
  if [[ ! -e /redis-master-data ]]; then
    echo "Redis master data doesn't exist, data won't be persistent!"
    mkdir /redis-master-data
  fi
  redis-server /redis-master/redis.conf --protected-mode no
}

function launchsentinel() {
  while true; do
    findmaster

    redis-cli -h ${master} INFO
    if [[ "$?" == "0" ]]; then
      break
    fi
    echo "Connecting to master failed.  Waiting..."
    sleep 10
  done

  sentinel_conf=sentinel.conf

  echo "sentinel monitor mymaster ${master} 6379 2" > ${sentinel_conf}
  echo "sentinel down-after-milliseconds mymaster 60000" >> ${sentinel_conf}
  echo "sentinel failover-timeout mymaster 180000" >> ${sentinel_conf}
  echo "sentinel parallel-syncs mymaster 1" >> ${sentinel_conf}

  redis-sentinel ${sentinel_conf} --protected-mode no
}

function launchslave() {
  echo "Launching as Slave"
  redis-cli -h ${master} INFO
  if [[ "$?" != "0" ]]; then
    slave_success=false
    echo "Connecting to master failed.  Waiting..."
    sleep 10
    return
  fi

  sed -i "s/%master-ip%/${master}/" /redis-slave/redis.conf
  sed -i "s/%master-port%/6379/" /redis-slave/redis.conf
  redis-server /redis-slave/redis.conf --protected-mode no
}

if [[ ${SENTINEL} == "true" ]]; then
  launchsentinel
fi

while true; do
  findmaster
  if [[ -z ${master} ]]; then
    echo "Cannot find master.  Waiting..."
    sleep 10
    continue
  fi

  if [[ ${master} == $(hostname -i) ]]; then
    launchmaster
    break
  else
    slave_success=true
    launchslave
    if [[ ${slave_success} == true ]]; then
      break
    fi
  fi
done
