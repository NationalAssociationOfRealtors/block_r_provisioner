
export CONFIG_DIR=blockr_config
export DEBUG=false
export FABRIC_PATH=$GOPATH/src/github.com/hyperledger/fabric
export PRODUCTION_DIR=/var/hyperledger
export RESET_DRIVER_NAME=reset_node_driver.sh
export TARGET_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR

reset_node() {
  echo ""
  echo "----------"
  echo " Reset Node $1"
  echo "----------"

  echo '#!/bin/bash' > $RESET_DRIVER_NAME
  echo '' >> $RESET_DRIVER_NAME
  echo '#----------------' >> $RESET_DRIVER_NAME
  echo '#' >> $RESET_DRIVER_NAME
  echo '# Block R Preparation Driver' >> $RESET_DRIVER_NAME
  echo '#' >> $RESET_DRIVER_NAME
  echo -n 'export TARGET_CFG_PATH=' >> $RESET_DRIVER_NAME
  echo $TARGET_CFG_PATH >> $RESET_DRIVER_NAME
  echo 'echo " - Stop Hyperledger, CouchDB, Zookeeper and Kafka daemons"' >> $RESET_DRIVER_NAME
  echo 'sudo pkill orderer' >> $RESET_DRIVER_NAME
  echo 'sudo pkill peer' >> $RESET_DRIVER_NAME
  echo 'sudo systemctl stop couchdb' >> $RESET_DRIVER_NAME
  echo 'sudo systemctl stop kafka' >> $RESET_DRIVER_NAME
  echo 'sudo systemctl stop zookeeper' >> $RESET_DRIVER_NAME
  echo "Remove docker images"
  ssh $1 "docker ps -aq | xargs docker kill &> /dev/null " || echo -n "."
  ssh $1 "docker ps -aq | xargs docker rm &> /dev/null " || echo -n "."
  ssh $1 "docker images | grep 'dev-' | awk '{print $3}' | xargs docker rmi &> /dev/null " || echo -n "."
  echo -n 'echo " - Reset configuration ' >> $RESET_DRIVER_NAME
  echo -n $TARGET_CFG_PATH >> $RESET_DRIVER_NAME
  echo '"' >> $RESET_DRIVER_NAME
  echo -n 'rm -rf ' >> $RESET_DRIVER_NAME
  echo $TARGET_CFG_PATH >> $RESET_DRIVER_NAME
  echo -n 'mkdir ' >> $RESET_DRIVER_NAME
  echo $TARGET_CFG_PATH >> $RESET_DRIVER_NAME
  scp -q ./$RESET_DRIVER_NAME $1:
  ssh $1 "chmod 777 $RESET_DRIVER_NAME"
  ssh $1 "./$RESET_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
    ssh $1 "rm ./$RESET_DRIVER_NAME"
  fi

  scp -q ./$RESET_DRIVER_NAME $1:
  ssh $1 "chmod 777 $RESET_DRIVER_NAME"
  ssh $1 "./$RESET_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
    ssh $1 "rm ./$RESET_DRIVER_NAME"
  fi
  rm ./$RESET_DRIVER_NAME
}

echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

#
# create the driver script
#
#echo '#!/bin/bash' > $RESET_DRIVER_NAME
#echo '' >> $RESET_DRIVER_NAME
#echo '#----------------' >> $RESET_DRIVER_NAME
#echo '#' >> $RESET_DRIVER_NAME
#echo '# Block R Setup Driver' >> $RESET_DRIVER_NAME
#echo '#' >> $RESET_DRIVER_NAME
#echo '#----------------' >> $RESET_DRIVER_NAME
#echo -n 'export TARGET_CFG_PATH=' >> $RESET_DRIVER_NAME 
#echo $TARGET_CFG_PATH >> $RESET_DRIVER_NAME 
#echo -n 'export PRODUCTION_DIR=' >> $RESET_DRIVER_NAME 
#echo $PRODUCTION_DIR >> $RESET_DRIVER_NAME 
#echo '
#echo "----------"
#echo " Reset configuration $TARGET_CFG_PATH"
#echo "----------"
#rm -rf $TARGET_CFG_PATH
#mkdir -p $TARGET_CFG_PATH
#sudo /etc/init.d/couchdb stop
#echo "----------"
#echo " Reset Production directory $PRODUCTION_DIR"
#echo "----------"
#if [ -d $PRODUCTION_DIR ]; then
#  sudo rm -rf $PRODUCTION_DIR
#fi
#sudo mkdir -p $PRODUCTION_DIR 
#sudo chown $(whoami):$(whoami) $PRODUCTION_DIR 
#sudo /etc/init.d/couchdb start
#' >> $RESET_DRIVER_NAME 

reset_node vm1
reset_node vm2
#rm ./$RESET_DRIVER_NAME

