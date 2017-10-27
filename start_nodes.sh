
export CONFIG_DIR=blockr_config
export DEBUG=false
export FABRIC_PATH=$GOPATH/src/github.com/hyperledger/fabric
export FABRIC_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR
export MAX_RETRIES=7
export ORDERER_DRIVER_NAME=start_orderer_driver.sh
export PEER_DRIVER_NAME=start_peer_driver.sh
export START_DAEMON_DRIVER_NAME=start_daemon_driver.sh
export START_ZOOKEEPER_DRIVER_NAME=start_zookeeper_driver.sh
export WAIT_SECONDS=5

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

start_node_driver() {
  echo "----------"
  echo " Start Node $1"
  echo "----------"

  echo '#!/bin/bash' > $PEER_DRIVER_NAME
  echo '' >> $PEER_DRIVER_NAME
  echo '#----------------' >> $PEER_DRIVER_NAME
  echo '#' >> $PEER_DRIVER_NAME
  echo '# Block R Peer Start Driver' >> $PEER_DRIVER_NAME
  echo '#' >> $PEER_DRIVER_NAME
  echo '#----------------' >> $PEER_DRIVER_NAME
  echo -n 'export FABRIC_PATH=' >> $PEER_DRIVER_NAME
  echo $FABRIC_PATH >> $PEER_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $PEER_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $PEER_DRIVER_NAME
  if [ "$DEBUG" = true ]; then
    echo 'export CORE_LOGGING_LEVEL=debug' >> $PEER_DRIVER_NAME
  fi
  echo 'echo " - Peer"' >> $PEER_DRIVER_NAME
  echo -n 'export LOG_FILE=' >> $PEER_DRIVER_NAME
  echo -n '$FABRIC_PATH/' >> $PEER_DRIVER_NAME
  echo -n $1 >> $PEER_DRIVER_NAME
  echo '_peer.out' >> $PEER_DRIVER_NAME
  echo 'if [ -f $LOG_FILE ]; then' >> $PEER_DRIVER_NAME
  echo '  rm $LOG_FILE' >> $PEER_DRIVER_NAME
  echo 'fi' >> $PEER_DRIVER_NAME
  echo '$FABRIC_PATH/build/bin/peer node start &> $LOG_FILE &' >> $PEER_DRIVER_NAME

  scp -q ./$PEER_DRIVER_NAME $1:
  ssh $1 "chmod 777 $PEER_DRIVER_NAME"
  ssh $1 "./$PEER_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
    ssh $1 "rm ./$PEER_DRIVER_NAME"
  fi
  rm ./$PEER_DRIVER_NAME

  echo '#!/bin/bash' > $ORDERER_DRIVER_NAME
  echo '' >> $ORDERER_DRIVER_NAME
  echo '#----------------' >> $ORDERER_DRIVER_NAME
  echo '#' >> $ORDERER_DRIVER_NAME
  echo '# Block R Orderer Start Driver' >> $ORDERER_DRIVER_NAME
  echo '#' >> $ORDERER_DRIVER_NAME
  echo '#----------------' >> $ORDERER_DRIVER_NAME
  echo -n 'export FABRIC_PATH=' >> $ORDERER_DRIVER_NAME
  echo $FABRIC_PATH >> $ORDERER_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $ORDERER_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $ORDERER_DRIVER_NAME
  if [ "$DEBUG" = true ]; then
    echo 'export GENERAL_LOGLEVEL=debug' >> $ORDERER_DRIVER_NAME
  fi
  echo 'echo " - Orderer"' >> $ORDERER_DRIVER_NAME
  echo -n 'export LOG_FILE=' >> $ORDERER_DRIVER_NAME
  echo -n '$FABRIC_PATH/' >> $ORDERER_DRIVER_NAME
  echo -n $1 >> $ORDERER_DRIVER_NAME
  echo '_orderer.out' >> $ORDERER_DRIVER_NAME
  echo -n 'export LOG_FILE=' >> $ORDERER_DRIVER_NAME
  echo -n '$FABRIC_PATH/' >> $ORDERER_DRIVER_NAME
  echo -n $1 >> $ORDERER_DRIVER_NAME
  echo '_orderer.out' >> $ORDERER_DRIVER_NAME
  echo 'if [ -f $LOG_FILE ]; then' >> $ORDERER_DRIVER_NAME
  echo '  rm $LOG_FILE' >> $ORDERER_DRIVER_NAME
  echo 'fi' >> $ORDERER_DRIVER_NAME
  echo '$FABRIC_PATH/build/bin/orderer &> $LOG_FILE &' >> $ORDERER_DRIVER_NAME

  scp -q ./$ORDERER_DRIVER_NAME $1:
  ssh $1 "chmod 777 $ORDERER_DRIVER_NAME"
  ssh $1 "./$ORDERER_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
    ssh $1 "rm ./$ORDERER_DRIVER_NAME"
  fi
  rm ./$ORDERER_DRIVER_NAME
}

echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

echo "----------"
echo " Starting Zookeeper"
echo "----------"
start_zookeeper vm1
start_zookeeper vm2

start_daemons vm1
start_daemons vm2

start_node_driver vm1
start_node_driver vm2

