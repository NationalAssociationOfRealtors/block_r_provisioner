#!/bin/bash

CONFIG_DIR=blockr_config
DEBUG=false
FABRIC_PATH=$GOPATH/src/github.com/hyperledger/fabric
FABRIC_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR
MAX_RETRIES=7
START_DAEMON_DRIVER_NAME=start_daemon_driver.sh
START_NODE_DRIVER_NAME=start_node_driver.sh
START_ZOOKEEPER_DRIVER_NAME=start_zookeeper_driver.sh
WAIT_SECONDS=3

daemon_control() {
  echo 'start_daemon() {' >> $1
  echo '  if $(/usr/bin/systemctl -q is-active $1) ; then' >> $1
  echo '    echo "- Already running"' >> $1
  echo '  else' >> $1
  echo '    sudo systemctl start $1' >> $1
  if ! [ $WAIT_SECONDS = 0 ]; then
    echo '    echo -n " - "' >> $1
    echo -n '    sleep ' >> $1
    echo $WAIT_SECONDS >> $1
  fi
  echo '    if $(/usr/bin/systemctl -q is-active $1) ; then' >> $1
  echo '      COUNTER=1' >> $1
  echo '      echo "Started"' >> $1
  echo '    else' >> $1
  echo '      if [ $COUNTER -le $MAX_RETRIES ] ; then' >> $1
  echo '        ((COUNTER++))' >> $1
  echo '        echo "Failed to start, retry"' >> $1
  echo '        echo -n "           "' >> $1
  echo '        start_daemon $1' >> $1
  echo '      fi' >> $1
  echo '    fi' >> $1
  echo '  fi' >> $1
  echo '}' >> $1
  echo -n 'MAX_RETRIES=' >> $1
  echo $MAX_RETRIES >> $1
  echo 'COUNTER=1' >> $1
}

start_process() {
  echo -n 'echo -n " - ' >> $1
  echo -n $2 >> $1
  echo ' "' >> $1
  echo -n 'start_daemon ' >> $1
  echo $3 >> $1
}

start_zookeeper() {

  driver_header $START_ZOOKEEPER_DRIVER_NAME 'Block R Start Zookeeper Driver'
  daemon_control $START_ZOOKEEPER_DRIVER_NAME 
  start_process $START_ZOOKEEPER_DRIVER_NAME $1 zookeeper 
  run_driver $START_ZOOKEEPER_DRIVER_NAME $1
}

start_daemons() {
  echo "----------"
  echo " Start daemons on Node $1"
  echo "----------"

  driver_header $START_DAEMON_DRIVER_NAME 'Block R Start Daemon Driver'
  daemon_control $START_DAEMON_DRIVER_NAME 
  start_process $START_DAEMON_DRIVER_NAME CouchDB couchdb
  start_process $START_DAEMON_DRIVER_NAME Kafka kafka 
  run_driver $START_DAEMON_DRIVER_NAME $1
}

start_node() {
  echo "----------"
  echo " Start Hyperleder on Node $1"
  echo "----------"

  driver_header $START_NODE_DRIVER_NAME 'Block R Start Node Driver'

  echo -n 'export FABRIC_PATH=' >> $START_NODE_DRIVER_NAME
  echo $FABRIC_PATH >> $START_NODE_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $START_NODE_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $START_NODE_DRIVER_NAME
  if [ "$DEBUG" = true ]; then
    echo 'export GENERAL_LOGLEVEL=debug' >> $START_NODE_DRIVER_NAME
    echo 'export CORE_LOGGING_LEVEL=debug' >> $START_NODE_DRIVER_NAME
  fi
  echo 'echo " - Peer"' >> $START_NODE_DRIVER_NAME
  echo -n 'LOG_FILE=' >> $START_NODE_DRIVER_NAME
  echo -n '$FABRIC_PATH/' >> $START_NODE_DRIVER_NAME
  echo -n $1 >> $START_NODE_DRIVER_NAME
  echo '_peer.out' >> $START_NODE_DRIVER_NAME
  echo 'if [ -f $LOG_FILE ]; then' >> $START_NODE_DRIVER_NAME
  echo '  rm $LOG_FILE' >> $START_NODE_DRIVER_NAME
  echo 'fi' >> $START_NODE_DRIVER_NAME
  echo '$FABRIC_PATH/build/bin/peer node start &> $LOG_FILE &' >> $START_NODE_DRIVER_NAME
  echo 'echo " - Orderer"' >> $START_NODE_DRIVER_NAME
  echo -n 'LOG_FILE=' >> $START_NODE_DRIVER_NAME
  echo -n '$FABRIC_PATH/' >> $START_NODE_DRIVER_NAME
  echo -n $1 >> $START_NODE_DRIVER_NAME
  echo '_orderer.out' >> $START_NODE_DRIVER_NAME
  echo 'if [ -f $LOG_FILE ]; then' >> $START_NODE_DRIVER_NAME
  echo '  rm $LOG_FILE' >> $START_NODE_DRIVER_NAME
  echo 'fi' >> $START_NODE_DRIVER_NAME
  echo '$FABRIC_PATH/build/bin/orderer &> $LOG_FILE &' >> $START_NODE_DRIVER_NAME

  run_driver $START_NODE_DRIVER_NAME $1
}

echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"


. config.sh
. ./scripts/common.sh

echo "----------"
echo " Start Zookeeper"
echo "----------"
COUNTER=0
while [  $COUNTER -lt $zookeeper_count ]; do
  let COUNTER=COUNTER+1
  start_zookeeper $(parse_lookup "$COUNTER" "$zookeepers")
done

#
# start daemons
#
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  start_daemons $(parse_lookup "$COUNTER" "$nodes")
done

#
# start nodes 
#
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  start_node $(parse_lookup "$COUNTER" "$nodes")
done

