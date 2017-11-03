#!/bin/bash

export CONFIG_DIR=blockr_config
export DEBUG=false
export FABRIC_PATH=$GOPATH/src/github.com/hyperledger/fabric
export FABRIC_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR
export MAX_RETRIES=7
export START_DAEMON_DRIVER_NAME=start_daemon_driver.sh
export START_NODE_DRIVER_NAME=start_node_driver.sh
export START_ZOOKEEPER_DRIVER_NAME=start_zookeeper_driver.sh
export WAIT_SECONDS=4

start_zookeeper() {
  echo '#!/bin/bash' > $START_ZOOKEEPER_DRIVER_NAME
  echo '' >> $START_ZOOKEEPER_DRIVER_NAME
  echo '#----------------' >> $START_ZOOKEEPER_DRIVER_NAME
  echo '#' >> $START_ZOOKEEPER_DRIVER_NAME
  echo '# Block R Start Zookeeper Driver' >> $START_ZOOKEEPER_DRIVER_NAME
  echo '#' >> $START_ZOOKEEPER_DRIVER_NAME
  echo '#----------------' >> $START_ZOOKEEPER_DRIVER_NAME
  echo -n 'echo -n " - ' >> $START_ZOOKEEPER_DRIVER_NAME
  echo -n $1 >> $START_ZOOKEEPER_DRIVER_NAME
  echo ' - "' >> $START_ZOOKEEPER_DRIVER_NAME
  echo 'if $(/usr/bin/systemctl -q is-active zookeeper) ; then' >> $START_ZOOKEEPER_DRIVER_NAME
  echo '  echo "Already running"' >> $START_ZOOKEEPER_DRIVER_NAME
  echo 'else' >> $START_ZOOKEEPER_DRIVER_NAME
  echo '  sudo systemctl start zookeeper' >> $START_ZOOKEEPER_DRIVER_NAME
  echo '  echo "Started"' >> $START_ZOOKEEPER_DRIVER_NAME
  echo 'fi' >> $START_ZOOKEEPER_DRIVER_NAME

  scp -q ./$START_ZOOKEEPER_DRIVER_NAME $1: 
  ssh $1 "chmod 777 $START_ZOOKEEPER_DRIVER_NAME"
  ssh $1 "./$START_ZOOKEEPER_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
    ssh $1 "rm ./$START_ZOOKEEPER_DRIVER_NAME"
  fi
  rm ./$START_ZOOKEEPER_DRIVER_NAME
}

start_daemons() {
  echo "----------"
  echo " Starting Daemons on Node $1"
  echo "----------"

  echo '#!/bin/bash' > $START_DAEMON_DRIVER_NAME
  echo '' >> $START_DAEMON_DRIVER_NAME
  echo '#----------------' >> $START_DAEMON_DRIVER_NAME
  echo '#' >> $START_DAEMON_DRIVER_NAME
  echo '# Block R Start Daemon Driver' >> $START_DAEMON_DRIVER_NAME
  echo '#' >> $START_DAEMON_DRIVER_NAME
  echo '#----------------' >> $START_DAEMON_DRIVER_NAME
  echo -n 'MAX_RETRIES=' >> $START_DAEMON_DRIVER_NAME
  echo $MAX_RETRIES >> $START_DAEMON_DRIVER_NAME
  echo 'COUNTER=1' >> $START_DAEMON_DRIVER_NAME

  echo 'start_daemon() {' >> $START_DAEMON_DRIVER_NAME
  echo '  if $(/usr/bin/systemctl -q is-active $1) ; then' >> $START_DAEMON_DRIVER_NAME
  echo '    echo "- Already running"' >> $START_DAEMON_DRIVER_NAME
  echo '  else' >> $START_DAEMON_DRIVER_NAME
  echo '    sudo systemctl start $1' >> $START_DAEMON_DRIVER_NAME
  if ! [ $WAIT_SECONDS = 0 ]; then
    echo '    echo -n " - "' >> $START_DAEMON_DRIVER_NAME
    echo -n '    sleep ' >> $START_DAEMON_DRIVER_NAME
    echo $WAIT_SECONDS >> $START_DAEMON_DRIVER_NAME
  fi
  echo '    if $(/usr/bin/systemctl -q is-active $1) ; then' >> $START_DAEMON_DRIVER_NAME
  echo '      COUNTER=1' >> $START_DAEMON_DRIVER_NAME
  echo '      echo "Started"' >> $START_DAEMON_DRIVER_NAME
  echo '    else' >> $START_DAEMON_DRIVER_NAME
  echo '      if [ $COUNTER -le $MAX_RETRIES ] ; then' >> $START_DAEMON_DRIVER_NAME
  echo '        ((COUNTER++))' >> $START_DAEMON_DRIVER_NAME
  echo '        echo "Failed to start, retry"' >> $START_DAEMON_DRIVER_NAME
  echo '        echo -n "           "' >> $START_DAEMON_DRIVER_NAME
  echo '        start_daemon $1' >> $START_DAEMON_DRIVER_NAME
  echo '      fi' >> $START_DAEMON_DRIVER_NAME
  echo '    fi' >> $START_DAEMON_DRIVER_NAME
  echo '  fi' >> $START_DAEMON_DRIVER_NAME
  echo '}' >> $START_DAEMON_DRIVER_NAME

  echo 'echo -n " - CouchDB "' >> $START_DAEMON_DRIVER_NAME
  echo 'start_daemon couchdb' >> $START_DAEMON_DRIVER_NAME
  echo 'echo -n " - Kafka   "' >> $START_DAEMON_DRIVER_NAME
  echo 'start_daemon kafka' >> $START_DAEMON_DRIVER_NAME

  scp -q ./$START_DAEMON_DRIVER_NAME $1: 
  ssh $1 "chmod 777 $START_DAEMON_DRIVER_NAME"
  ssh $1 "./$START_DAEMON_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
    ssh $1 "rm ./$START_DAEMON_DRIVER_NAME"
  fi
  rm ./$START_DAEMON_DRIVER_NAME
}

start_node() {
  echo "----------"
  echo " Start Node $1"
  echo "----------"

  echo '#!/bin/bash' > $START_NODE_DRIVER_NAME
  echo '' >> $START_NODE_DRIVER_NAME
  echo '#----------------' >> $START_NODE_DRIVER_NAME
  echo '#' >> $START_NODE_DRIVER_NAME
  echo '# Block R Start Node Driver' >> $START_NODE_DRIVER_NAME
  echo '#' >> $START_NODE_DRIVER_NAME
  echo '#----------------' >> $START_NODE_DRIVER_NAME
  echo -n 'export FABRIC_PATH=' >> $START_NODE_DRIVER_NAME
  echo $FABRIC_PATH >> $START_NODE_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $START_NODE_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $START_NODE_DRIVER_NAME
  if [ "$DEBUG" = true ]; then
    echo 'export GENERAL_LOGLEVEL=debug' >> $START_NODE_DRIVER_NAME
    echo 'export CORE_LOGGING_LEVEL=debug' >> $START_NODE_DRIVER_NAME
  fi
  echo 'echo " - Peer"' >> $START_NODE_DRIVER_NAME
  echo -n 'export LOG_FILE=' >> $START_NODE_DRIVER_NAME
  echo -n '$FABRIC_PATH/' >> $START_NODE_DRIVER_NAME
  echo -n $1 >> $START_NODE_DRIVER_NAME
  echo '_peer.out' >> $START_NODE_DRIVER_NAME
  echo 'if [ -f $LOG_FILE ]; then' >> $START_NODE_DRIVER_NAME
  echo '  rm $LOG_FILE' >> $START_NODE_DRIVER_NAME
  echo 'fi' >> $START_NODE_DRIVER_NAME
  echo '$FABRIC_PATH/build/bin/peer node start &> $LOG_FILE &' >> $START_NODE_DRIVER_NAME
  echo 'echo " - Orderer"' >> $START_NODE_DRIVER_NAME
  echo -n 'export LOG_FILE=' >> $START_NODE_DRIVER_NAME
  echo -n '$FABRIC_PATH/' >> $START_NODE_DRIVER_NAME
  echo -n $1 >> $START_NODE_DRIVER_NAME
  echo '_orderer.out' >> $START_NODE_DRIVER_NAME
  echo 'if [ -f $LOG_FILE ]; then' >> $START_NODE_DRIVER_NAME
  echo '  rm $LOG_FILE' >> $START_NODE_DRIVER_NAME
  echo 'fi' >> $START_NODE_DRIVER_NAME
  echo '$FABRIC_PATH/build/bin/orderer &> $LOG_FILE &' >> $START_NODE_DRIVER_NAME

  scp -q ./$START_NODE_DRIVER_NAME $1:
  ssh $1 "chmod 777 $START_NODE_DRIVER_NAME"
  ssh $1 "./$START_NODE_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
    ssh $1 "rm ./$START_NODE_DRIVER_NAME"
  fi
  rm ./$START_NODE_DRIVER_NAME
}

echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"


. config.sh
. ./scripts/common.sh

echo "----------"
echo " Starting Zookeeper"
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

