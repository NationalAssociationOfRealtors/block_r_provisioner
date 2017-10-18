
export CONFIG_DIR=blockr_config
export DEBUG=true
export PREPARE_DRIVER_NAME=prepare_node_driver.sh
export RESET_DRIVER_NAME=reset_node_driver.sh
export FABRIC_CFG_PATH=./$CONFIG_DIR
export FABRIC_PATH=$GOPATH/src/github.com/hyperledger/fabric
export PRODUCTION_DIR=/var/hyperledger
export TARGET_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR
export TEMP_CFG_PATH=./$CONFIG_DIR.temp
export TEMP1_CFG_PATH=./$CONFIG_DIR.temp1
export WAIT_SECONDS=0
export WITH_ANCHOR_PEERS=false
export WITH_TLS=true

distribute_conf() {
  echo "----------"
  echo " Distribute configuration to Node $1"
  echo "----------"
  if [ -d $TEMP_CFG_PATH ]; then
    rm -rf $TEMP_CFG_PATH
  fi
  mkdir -p $TEMP_CFG_PATH
  cp -r $FABRIC_CFG_PATH/* $TEMP_CFG_PATH 
  cp ./templates/core.yaml $TEMP_CFG_PATH/core.yml.template 
  cp ./templates/orderer.yaml $TEMP_CFG_PATH/orderer.yml.template 

  CORE_PEER_MSP_PATH=''
  CORE_PEER_TLS_CERT_FILE=''
  CORE_PEER_TLS_KEY_FILE=''
  CORE_PEER_TLS_ROOTCERT_FILE=''
  ORDERER_GENERAL_TLS_CERTIFICATE=''
  ORDERER_GENERAL_TLS_PRIVATEKEY=''
  ORDERER_GENERAL_TLS_ROOTCAS=''
  CORE_PEER_MSP_PATH="peerOrganizations/$3/peers/$1.$3/msp"
  ORDERER_MSP_PATH="ordererOrganizations/$3/orderers/$1.$3/msp"
  if [ "$WITH_TLS" = true ]; then
    CORE_PEER_TLS_CERT_FILE="peerOrganizations/$3/peers/$1.$3/tls/server.crt"
    CORE_PEER_TLS_KEY_FILE="peerOrganizations/$3/peers/$1.$3/tls/server.key"
    CORE_PEER_TLS_ROOTCERT_FILE="peerOrganizations/$3/peers/$1.$3/tls/ca.crt"
    ORDERER_GENERAL_TLS_CERTIFICATE="ordererOrganizations/$3/orderers/$1.$3/tls/server.crt"
    ORDERER_GENERAL_TLS_PRIVATEKEY="ordererOrganizations/$3/orderers/$1.$3/tls/server.key"
    ORDERER_GENERAL_TLS_ROOTCAS="ordererOrganizations/$3/orderers/$1.$3/tls/ca.crt"
  fi

  cat $TEMP_CFG_PATH/core.yml.template | sed "s|PEER_ID|$2| ; s|PEER_ENDPOINT|$1| ; s|PEER_ADDRESS|$1:7051| ; s|PEER_BOOTSTRAP|$1:7051| ; s|WITH_TLS|$WITH_TLS| ; s|PEER_CERT|$CORE_PEER_TLS_CERT_FILE| ; s|PEER_KEY|$CORE_PEER_TLS_KEY_FILE| ; s|PEER_ROOTCERT|$CORE_PEER_TLS_ROOTCERT_FILE| ; s|PEER_MSP_PATH|$CORE_PEER_MSP_PATH| ; s|PEER_MSP_ID|$2| " > $TEMP_CFG_PATH/core.yaml
  rm $TEMP_CFG_PATH/core.yml.template

  cat $TEMP_CFG_PATH/orderer.yml.template | sed "s:WITH_TLS:$WITH_TLS: ; s:ORDERER_CERT:$ORDERER_GENERAL_TLS_CERTIFICATE: ; s:ORDERER_KEY:$ORDERER_GENERAL_TLS_PRIVATEKEY: ; s:ORDERER_ROOTCERT:$ORDERER_GENERAL_TLS_ROOTCAS: ; s:ORDERER_MSP_PATH:$ORDERER_MSP_PATH: ; s:ORDERER_MSP_ID:$4:   " > $TEMP_CFG_PATH/orderer.yaml
  rm $TEMP_CFG_PATH/orderer.yml.template

  scp -rq $TEMP_CFG_PATH/* $1:$TARGET_CFG_PATH
  rm -rf $TEMP_CFG_PATH
}

prepare() {
  echo "----------"
  echo " Preparing Node $1"
  echo "----------"

  echo '#!/bin/bash' > $PREPARE_DRIVER_NAME
  echo '' >> $PREPARE_DRIVER_NAME
  echo '#----------------' >> $PREPARE_DRIVER_NAME
  echo '#' >> $PREPARE_DRIVER_NAME
  echo '# Block R Preparation Driver' >> $PREPARE_DRIVER_NAME
  echo '#' >> $PREPARE_DRIVER_NAME
  echo '#----------------' >> $PREPARE_DRIVER_NAME
  echo -n 'export TARGET_CFG_PATH=' >> $PREPARE_DRIVER_NAME 
  echo $TARGET_CFG_PATH >> $PREPARE_DRIVER_NAME 
  echo 'echo " - Stop Hyperledger daemons"' >> $PREPARE_DRIVER_NAME
  echo 'sudo pkill orderer' >> $PREPARE_DRIVER_NAME
  echo 'sudo pkill peer' >> $PREPARE_DRIVER_NAME
  echo 'echo " - Remove docker images"' >> $PREPARE_DRIVER_NAME
  echo 'sudo docker ps -aq | xargs docker kill &> /dev/null' >> $PREPARE_DRIVER_NAME
  echo 'sudo docker ps -aq | xargs docker rm &> /dev/null' >> $PREPARE_DRIVER_NAME
  echo "sudo docker images | grep 'dev-' | awk '{print $3}' | xargs docker rmi &> /dev/null" >> $PREPARE_DRIVER_NAME
  echo -n 'echo " - Reset configuration ' >> $PREPARE_DRIVER_NAME
  echo -n $TARGET_CFG_PATH >> $PREPARE_DRIVER_NAME
  echo '"' >> $PREPARE_DRIVER_NAME
  echo -n 'rm -rf ' >> $PREPARE_DRIVER_NAME
  echo $TARGET_CFG_PATH >> $PREPARE_DRIVER_NAME
  echo -n 'mkdir ' >> $PREPARE_DRIVER_NAME
  echo $TARGET_CFG_PATH >> $PREPARE_DRIVER_NAME
  echo 'echo " - Stop CouchDB, Zookeeper and Kafka daemons"' >> $PREPARE_DRIVER_NAME
  echo 'sudo /etc/init.d/couchdb stop &> /dev/null' >> $PREPARE_DRIVER_NAME
  echo 'sudo systemctl stop kafka' >> $PREPARE_DRIVER_NAME
  echo 'sudo systemctl stop zookeeper' >> $PREPARE_DRIVER_NAME
  scp -q ./$PREPARE_DRIVER_NAME $1: 
  ssh $1 "chmod 777 $PREPARE_DRIVER_NAME"
  ssh $1 "./$PREPARE_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
    ssh $1 "rm ./$PREPARE_DRIVER_NAME"
  fi
  rm ./$PREPARE_DRIVER_NAME
}

reset() {
  echo "----------"
  echo " Resetting Node $1"
  echo "----------"

  cp ./templates/server.properties $TEMP1_CFG_PATH/server.properties.template
  cat $TEMP1_CFG_PATH/server.properties.template | sed "s|BROKER_ID|$2| ; s|SERVER_ADDRESS|$1| " > $TEMP1_CFG_PATH/server.properties
  scp -q $TEMP1_CFG_PATH/server.properties $1:/opt/kafka_2.11-0.10.2.0/config 
  scp -q $TEMP1_CFG_PATH/zookeeper.properties $1:/opt/kafka_2.11-0.10.2.0/config 

  echo '#!/bin/bash' > $RESET_DRIVER_NAME
  echo '' >> $RESET_DRIVER_NAME
  echo '#----------------' >> $RESET_DRIVER_NAME
  echo '#' >> $RESET_DRIVER_NAME
  echo '# Block R Reset Driver' >> $RESET_DRIVER_NAME
  echo '#' >> $RESET_DRIVER_NAME
  echo '#----------------' >> $RESET_DRIVER_NAME
  echo -n 'export PRODUCTION_DIR=' >> $RESET_DRIVER_NAME 
  echo $PRODUCTION_DIR >> $RESET_DRIVER_NAME 
  echo 'echo " - Reset production repositories"' >> $RESET_DRIVER_NAME
  echo 'if [ -d $PRODUCTION_DIR ]; then' >> $RESET_DRIVER_NAME
  echo '  sudo rm -rf $PRODUCTION_DIR' >> $RESET_DRIVER_NAME
  echo 'fi' >> $RESET_DRIVER_NAME
  echo 'sudo mkdir $PRODUCTION_DIR' >> $RESET_DRIVER_NAME
  echo 'sudo chown $(whoami):$(whoami) $PRODUCTION_DIR' >> $RESET_DRIVER_NAME
  echo 'if [ -d /var/zookeeper ]; then' >> $RESET_DRIVER_NAME
  echo '  sudo rm -rf /var/zookeeper' >> $RESET_DRIVER_NAME
  echo 'fi' >> $RESET_DRIVER_NAME
  echo 'sudo mkdir /var/zookeeper' >> $RESET_DRIVER_NAME
  echo -n 'sudo echo "' >> $RESET_DRIVER_NAME
  echo -n $2 >> $RESET_DRIVER_NAME
  echo '"> ~/myid' >> $RESET_DRIVER_NAME
  echo 'sudo mv ~/myid /var/zookeeper' >> $RESET_DRIVER_NAME
  echo 'if [ -d /var/kafka-logs ]; then' >> $RESET_DRIVER_NAME
  echo '  sudo rm -rf /var/kafka-logs' >> $RESET_DRIVER_NAME
  echo 'fi' >> $RESET_DRIVER_NAME
  echo 'echo " - Start CouchDB"' >> $RESET_DRIVER_NAME

  echo 'sudo systemctl start zookeeper' >> $RESET_DRIVER_NAME
  if ! [ $WAIT_SECONDS = 0 ]; then
    echo 'echo " - Wait for Zookeeper to start"' >> $RESET_DRIVER_NAME
    echo -n 'sleep ' >> $RESET_DRIVER_NAME
    echo $WAIT_SECONDS >> $RESET_DRIVER_NAME
    echo 'echo " - Zookeeper started"' >> $RESET_DRIVER_NAME
  fi
  echo 'sudo systemctl start kafka' >> $RESET_DRIVER_NAME

  echo 'sudo /etc/init.d/couchdb start &> /dev/null' >> $RESET_DRIVER_NAME

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

prepare vm2
prepare vm1

if [ -d $TEMP1_CFG_PATH ]; then
  rm -rf $TEMP1_CFG_PATH
fi
mkdir -p $TEMP1_CFG_PATH
cp ./templates/zookeeper.properties $TEMP1_CFG_PATH
echo "server.1=vm1:2888:3888" >> $TEMP1_CFG_PATH/zookeeper.properties 
echo "server.2=vm2:2888:3888" >> $TEMP1_CFG_PATH/zookeeper.properties 
reset vm1 1
rm -rf $TEMP1_CFG_PATH/server.properties
reset vm2 2
rm -rf $TEMP1_CFG_PATH

echo "----------"
echo " Reset local configuration directory $FABRIC_CFG_PATH"
echo "----------"
rm -rf $FABRIC_CFG_PATH 
mkdir -p $FABRIC_CFG_PATH 

echo "----------"
echo " Generate keys from $FABRIC_CFG_PATH/blockr-config.yaml"
echo "----------"
cp ./templates/blockr-config.yaml $FABRIC_CFG_PATH
$FABRIC_PATH/build/bin/cryptogen generate --config $FABRIC_CFG_PATH/blockr-config.yaml --output $FABRIC_CFG_PATH 

echo "----------"
echo " Generate genesis block from $FABRIC_CFG_PATH/configtx.yaml, profile:Genesis"
echo "----------"
cp ./templates/configtx.yaml $FABRIC_CFG_PATH
$FABRIC_PATH/build/bin/configtxgen -profile Genesis -outputBlock $FABRIC_CFG_PATH/genesis.block -channelID system
if ! [ -f $FABRIC_CFG_PATH/genesis.block ]; then
  echo 'ERROR'
  exit 1
fi

echo "----------"
echo " Generate channel block from $FABRIC_CFG_PATH/configtx.yaml, profile:Channels"
echo "----------"
$FABRIC_PATH/build/bin/configtxgen -profile Channels -outputCreateChannelTx $FABRIC_CFG_PATH/blockr.tx -channelID blockr
if ! [ -f $FABRIC_CFG_PATH/blockr.tx ]; then
  echo 'ERROR'
  exit 1
fi

if [ "$WITH_ANCHOR_PEERS" = true ]; then
  echo "----------"
  echo " Generate Anchorpeer transactions from $FABRIC_CFG_PATH/configtx.yaml, profile:Channels"
  echo "----------"
  $FABRIC_PATH/build/bin/configtxgen -profile Channels -outputAnchorPeersUpdate $FABRIC_CFG_PATH/Org1MSPanchors.tx -channelID blockr -asOrg Org1MSP
  if ! [ -f $FABRIC_CFG_PATH/Org1MSPanchors.tx ]; then
    echo 'ERROR'
    exit 1
  fi

  $FABRIC_PATH/build/bin/configtxgen -profile Channels -outputAnchorPeersUpdate $FABRIC_CFG_PATH/Org2MSPanchors.tx -channelID blockr -asOrg Org2MSP
  if ! [ -f $FABRIC_CFG_PATH/Org2MSPanchors.tx ]; then
    echo 'ERROR'
    exit 1
  fi
fi

distribute_conf vm1 Org1MSP nar.blockr Orderer1MSP 0
distribute_conf vm2 Org2MSP car.blockr Orderer2MSP 1

rm -rf $FABRIC_CFG_PATH 

