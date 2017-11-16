#!/bin/bash

DEBUG=true
STOP_ORDERER_DRIVER_NAME=stop_orderer_driver.sh
STOP_PEER_DRIVER_NAME=stop_peer_driver.sh
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

shutdown_orderer() {
  driver_header $STOP_ORDERER_DRIVER_NAME 'Block R Stop Orderer Driver'

  echo 'echo -n " - Orderer "' >> $STOP_ORDERER_DRIVER_NAME
  echo 'sudo pkill -f /bin/orderer' >> $STOP_ORDERER_DRIVER_NAME
  echo 'echo " - Stopped"' >> $STOP_ORDERER_DRIVER_NAME
  stop_process $STOP_ORDERER_DRIVER_NAME Kafka kafka 

  run_driver $STOP_ORDERER_DRIVER_NAME $1 $2
}

shutdown_peer() {
  driver_header $STOP_PEER_DRIVER_NAME 'Block R Stop Peer Driver'

  echo 'echo -n " - Peer "' >> $STOP_PEER_DRIVER_NAME
  echo 'sudo pkill -f /bin/peer' >> $STOP_PEER_DRIVER_NAME
  echo 'echo "- Stopped"' >> $STOP_PEER_DRIVER_NAME
  stop_process $STOP_PEER_DRIVER_NAME CouchDB couchdb 

  run_driver $STOP_PEER_DRIVER_NAME $1 $2
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
# shutdown daemons
#
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  node_name=$(parse_lookup "$COUNTER" "$nodes")
  account_name=$(parse_lookup "$COUNTER" "$accounts")
  echo "----------"
  echo " Stop Node $node_name"
  echo "----------"
  shutdown_orderer $node_name $account_name
  shutdown_peer $node_name $account_name
done

echo "----------"
echo " Stop Zookeeper"
echo "----------"
COUNTER=0
while [  $COUNTER -lt $zookeeper_count ]; do
  let COUNTER=COUNTER+1
  shutdown_zookeeper $(parse_lookup "$COUNTER" "$zookeepers") $(parse_lookup "$COUNTER" "$zookeeper_accounts")
done
