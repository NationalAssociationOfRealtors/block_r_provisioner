
export DEBUG=false
export STOP_DAEMON_DRIVER_NAME=stop_daemon_driver.sh

shutdown_node() {
  echo "----------"
  echo " Shutdown Node $1"
  echo "----------"

  echo " - Orderer"
  ssh $1 "pkill orderer"
  echo " - Peer"
  ssh $1 "pkill peer"
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
  echo '  echo "- stopping"' >> $STOP_DAEMON_DRIVER_NAME
  #echo '  sudo /etc/init.d/couchdb stop &> /dev/null' >> $STOP_DAEMON_DRIVER_NAME
  echo '  sudo systemctl stop couchdb' >> $STOP_DAEMON_DRIVER_NAME
  echo 'else' >> $STOP_DAEMON_DRIVER_NAME
  echo '  echo "- not running"' >> $STOP_DAEMON_DRIVER_NAME
  echo 'fi' >> $STOP_DAEMON_DRIVER_NAME

  echo 'echo -n " - Kafka "' >> $STOP_DAEMON_DRIVER_NAME
  echo 'if $(/usr/bin/systemctl -q is-active kafka) ; then' >> $STOP_DAEMON_DRIVER_NAME
  echo '  echo "- stopping"' >> $STOP_DAEMON_DRIVER_NAME
  echo '  sudo systemctl stop kafka' >> $STOP_DAEMON_DRIVER_NAME
  echo 'else' >> $STOP_DAEMON_DRIVER_NAME
  echo '  echo "- not running"' >> $STOP_DAEMON_DRIVER_NAME
  echo 'fi' >> $STOP_DAEMON_DRIVER_NAME

  echo 'echo -n " - Zookeeper "' >> $STOP_DAEMON_DRIVER_NAME
  echo 'if $(/usr/bin/systemctl -q is-active zookeeper) ; then' >> $STOP_DAEMON_DRIVER_NAME
  echo '  echo " stopping"' >> $STOP_DAEMON_DRIVER_NAME
  echo '  sudo systemctl stop zookeeper' >> $STOP_DAEMON_DRIVER_NAME
  echo 'else' >> $STOP_DAEMON_DRIVER_NAME
  echo '  echo " not running"' >> $STOP_DAEMON_DRIVER_NAME
  echo 'fi' >> $STOP_DAEMON_DRIVER_NAME

  scp -q ./$STOP_DAEMON_DRIVER_NAME $1: 
  ssh $1 "chmod 777 $STOP_DAEMON_DRIVER_NAME"
  ssh $1 "./$STOP_DAEMON_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
    ssh $1 "rm ./$STOP_DAEMON_DRIVER_NAME"
  fi
  rm ./$STOP_DAEMON_DRIVER_NAME
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
