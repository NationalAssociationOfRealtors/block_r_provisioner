
export DEBUG=false
export STOP_DAEMON_DRIVER_NAME=stop_daemon_driver.sh
export STOP_NODE_DRIVER_NAME=stop_node_driver.sh
export STOP_ZOOKEEPER_DRIVER_NAME=stop_zookeeper_driver.sh

shutdown_node() {
  echo "----------"
  echo " Shutdown Node $1"
  echo "----------"

  echo '#!/bin/bash' > $STOP_NODE_DRIVER_NAME
  echo '' >> $STOP_NODE_DRIVER_NAME
  echo '#----------------' >> $STOP_NODE_DRIVER_NAME
  echo '#' >> $STOP_NODE_DRIVER_NAME
  echo '# Block R Stop Node Driver' >> $STOP_NODE_DRIVER_NAME
  echo '#' >> $STOP_NODE_DRIVER_NAME
  echo '#----------------' >> $STOP_NODE_DRIVER_NAME

  echo 'echo -n " - Orderer "' >> $STOP_NODE_DRIVER_NAME
  echo 'sudo pkill orderer' >> $STOP_NODE_DRIVER_NAME
  echo 'echo "- Stopped"' >> $STOP_NODE_DRIVER_NAME
  echo 'echo -n " - Peer "' >> $STOP_NODE_DRIVER_NAME
  echo 'sudo pkill peer' >> $STOP_NODE_DRIVER_NAME
  echo 'echo "- Stopped"' >> $STOP_NODE_DRIVER_NAME

  scp -q ./$STOP_NODE_DRIVER_NAME $1: 
  ssh $1 "chmod 777 $STOP_NODE_DRIVER_NAME"
  ssh $1 "./$STOP_NODE_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
    ssh $1 "rm ./$STOP_NODE_DRIVER_NAME"
  fi
  rm ./$STOP_NODE_DRIVER_NAME
}

shutdown_daemons() {
  echo "----------"
  echo " Stopping daemons on $1"
  echo "----------"

  echo '#!/bin/bash' > $STOP_DAEMON_DRIVER_NAME
  echo '' >> $STOP_DAEMON_DRIVER_NAME
  echo '#----------------' >> $STOP_DAEMON_DRIVER_NAME
  echo '#' >> $STOP_DAEMON_DRIVER_NAME
  echo '# Block R Stop Daemon Driver' >> $STOP_DAEMON_DRIVER_NAME
  echo '#' >> $STOP_DAEMON_DRIVER_NAME
  echo '#----------------' >> $STOP_DAEMON_DRIVER_NAME

  echo 'echo -n " - CouchDB "' >> $STOP_DAEMON_DRIVER_NAME
  echo 'if $(/usr/bin/systemctl -q is-active couchdb) ; then' >> $STOP_DAEMON_DRIVER_NAME
  #echo '  sudo /etc/init.d/couchdb stop &> /dev/null' >> $STOP_DAEMON_DRIVER_NAME
  echo '  sudo systemctl stop couchdb' >> $STOP_DAEMON_DRIVER_NAME
  echo '  echo "- Stopped"' >> $STOP_DAEMON_DRIVER_NAME
  echo 'else' >> $STOP_DAEMON_DRIVER_NAME
  echo '  echo "- Not running"' >> $STOP_DAEMON_DRIVER_NAME
  echo 'fi' >> $STOP_DAEMON_DRIVER_NAME

  echo 'echo -n " - Kafka "' >> $STOP_DAEMON_DRIVER_NAME
  echo 'if $(/usr/bin/systemctl -q is-active kafka) ; then' >> $STOP_DAEMON_DRIVER_NAME
  echo '  sudo systemctl stop kafka' >> $STOP_DAEMON_DRIVER_NAME
  echo '  echo "- Stopped"' >> $STOP_DAEMON_DRIVER_NAME
  echo 'else' >> $STOP_DAEMON_DRIVER_NAME
  echo '  echo "- Not running"' >> $STOP_DAEMON_DRIVER_NAME
  echo 'fi' >> $STOP_DAEMON_DRIVER_NAME

#  echo 'echo -n " - Zookeeper "' >> $STOP_DAEMON_DRIVER_NAME
#  echo 'if $(/usr/bin/systemctl -q is-active zookeeper) ; then' >> $STOP_DAEMON_DRIVER_NAME
#  echo '  echo " stopping"' >> $STOP_DAEMON_DRIVER_NAME
#  echo '  sudo systemctl stop zookeeper' >> $STOP_DAEMON_DRIVER_NAME
#  echo 'else' >> $STOP_DAEMON_DRIVER_NAME
#  echo '  echo " not running"' >> $STOP_DAEMON_DRIVER_NAME
#  echo 'fi' >> $STOP_DAEMON_DRIVER_NAME

  scp -q ./$STOP_DAEMON_DRIVER_NAME $1: 
  ssh $1 "chmod 777 $STOP_DAEMON_DRIVER_NAME"
  ssh $1 "./$STOP_DAEMON_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
    ssh $1 "rm ./$STOP_DAEMON_DRIVER_NAME"
  fi
  rm ./$STOP_DAEMON_DRIVER_NAME
}
 
shutdown_zookeeper() {
  echo '#!/bin/bash' > $STOP_ZOOKEEPER_DRIVER_NAME
  echo '' >> $STOP_ZOOKEEPER_DRIVER_NAME
  echo '#----------------' >> $STOP_ZOOKEEPER_DRIVER_NAME
  echo '#' >> $STOP_ZOOKEEPER_DRIVER_NAME
  echo '# Block R Stop Zookeeper Driver' >> $STOP_ZOOKEEPER_DRIVER_NAME
  echo '#' >> $STOP_ZOOKEEPER_DRIVER_NAME
  echo '#----------------' >> $STOP_ZOOKEEPER_DRIVER_NAME
  echo -n 'echo -n " - ' >> $STOP_ZOOKEEPER_DRIVER_NAME
  echo -n $1 >> $STOP_ZOOKEEPER_DRIVER_NAME
  echo ' - "' >> $STOP_ZOOKEEPER_DRIVER_NAME
  echo 'if $(/usr/bin/systemctl -q is-active zookeeper) ; then' >> $STOP_ZOOKEEPER_DRIVER_NAME
  echo '  sudo systemctl stop zookeeper' >> $STOP_ZOOKEEPER_DRIVER_NAME
  echo '  echo "Stopped"' >> $STOP_ZOOKEEPER_DRIVER_NAME
  echo 'else' >> $STOP_ZOOKEEPER_DRIVER_NAME
  echo '  echo "Not running"' >> $STOP_ZOOKEEPER_DRIVER_NAME
  echo 'fi' >> $STOP_ZOOKEEPER_DRIVER_NAME

  scp -q ./$STOP_ZOOKEEPER_DRIVER_NAME $1: 
  ssh $1 "chmod 777 $STOP_ZOOKEEPER_DRIVER_NAME"
  ssh $1 "./$STOP_ZOOKEEPER_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
    ssh $1 "rm ./$STOP_ZOOKEEPER_DRIVER_NAME"
  fi
  rm ./$STOP_ZOOKEEPER_DRIVER_NAME
}
 
echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

shutdown_node vm2
shutdown_node vm1

shutdown_daemons vm2
shutdown_daemons vm1

echo "----------"
echo " Stopping Zookeeper"
echo "----------"
shutdown_zookeeper vm2
shutdown_zookeeper vm1
