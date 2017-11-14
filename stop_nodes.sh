#!/bin/bash

DEBUG=false
STOP_DAEMON_DRIVER_NAME=stop_daemon_driver.sh
STOP_NODE_DRIVER_NAME=stop_node_driver.sh
STOP_ZOOKEEPER_DRIVER_NAME=stop_zookeeper_driver.sh

stop_process() {
  echo -n 'echo -n " - ' >> $1
  echo -n $2 >> $1
  echo ' - "' >> $1
  echo -n 'if $(/usr/bin/systemctl -q is-active ' >> $1
  echo -n $3 >> $1
  echo ') ; then' >> $1
  echo "  sudo systemctl stop $3" >> $1
  echo '  echo "Stopped"' >> $1
  echo 'else' >> $1
  echo '  echo "Not running"' >> $1
  echo 'fi' >> $1
}

shutdown_node() {
  echo "----------"
  echo " Shutdown Hyperledger on Node $1"
  echo "----------"

  driver_header $STOP_NODE_DRIVER_NAME 'Block R Stop Node Driver'

  echo 'echo -n " - Orderer "' >> $STOP_NODE_DRIVER_NAME
  echo 'sudo pkill orderer' >> $STOP_NODE_DRIVER_NAME
  echo 'echo "- Stopped"' >> $STOP_NODE_DRIVER_NAME
  echo 'echo -n " - Peer "' >> $STOP_NODE_DRIVER_NAME
  echo 'sudo pkill peer' >> $STOP_NODE_DRIVER_NAME
  echo 'echo "- Stopped"' >> $STOP_NODE_DRIVER_NAME

  run_driver $STOP_NODE_DRIVER_NAME $1 $2
}

shutdown_daemons() {
  echo "----------"
  echo " Stop daemons on $1"
  echo "----------"

  driver_header $STOP_DAEMON_DRIVER_NAME 'Block R Stop Daemon Driver'

  stop_process $STOP_DAEMON_DRIVER_NAME CouchDB couchdb 
  stop_process $STOP_DAEMON_DRIVER_NAME Kafka kafka 

  run_driver $STOP_DAEMON_DRIVER_NAME $1 $2
}
 
shutdown_zookeeper() {

  driver_header $STOP_ZOOKEEPER_DRIVER_NAME 'Block R Stop Zookeeper Driver'

  stop_process $STOP_ZOOKEEPER_DRIVER_NAME $1 zookeeper 

  run_driver $STOP_ZOOKEEPER_DRIVER_NAME $1 $2
}
 
echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

. config.sh
. ./scripts/common.sh

#
# shutdown nodes 
#
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  shutdown_node $(parse_lookup "$COUNTER" "$nodes") $(parse_lookup "$COUNTER" "$accounts")
done

#
# shutdown daemons
#
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  shutdown_daemons $(parse_lookup "$COUNTER" "$nodes") $(parse_lookup "$COUNTER" "$accounts")
done

echo "----------"
echo " Stop Zookeeper"
echo "----------"
COUNTER=0
while [  $COUNTER -lt $zookeeper_count ]; do
  let COUNTER=COUNTER+1
  shutdown_zookeeper $(parse_lookup "$COUNTER" "$zookeepers") $(parse_lookup "$COUNTER" "$zookeeper_accounts")
done
