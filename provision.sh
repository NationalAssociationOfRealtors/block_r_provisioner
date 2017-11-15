#!/bin/bash

CHAINCODE_ID='blockrCC'
CHAINCODE_VERSION='1.0'
CONFIG_DIR=blockr_config
DEBUG=false
FABRIC_PATH=$GOPATH/src/github.com/hyperledger/fabric
KAFKA_DIR=/var/kafka-logs
HYPERLEDGER_DIR=/var/hyperledger
LOCAL_CFG_PATH=./$CONFIG_DIR
PACKAGE_CHAINCODE_DRIVER_NAME=package_chaincode_driver.sh
PREPARE_DRIVER_NAME=prepare_node_driver.sh
RESET_DRIVER_NAME=reset_node_driver.sh
RESET_ZOOKEEPER_DRIVER_NAME=reset_zookeeper_driver.sh
TARGET_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR
TEMP_CFG_PATH=./$CONFIG_DIR.temp
WITH_ANCHOR_PEERS=true
WITH_TLS=true
ZOOKEEPER_DIR=/var/zookeeper

package_chaincode() {
  echo "----------"
  echo " Package chaincode on $1 then distribute"
  echo "----------"

  scp -q ./chaincode/blockr_example.go $2@$1:$TARGET_CFG_PATH

  driver_header $PACKAGE_CHAINCODE_DRIVER_NAME 'Block R Package Chaincode Driver'

  echo -n 'export GOPATH=' >> $PACKAGE_CHAINCODE_DRIVER_NAME
  echo $GOPATH >> $PACKAGE_CHAINCODE_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $PACKAGE_CHAINCODE_DRIVER_NAME
  echo $TARGET_CFG_PATH >> $PACKAGE_CHAINCODE_DRIVER_NAME
  echo -n 'FABRIC_PATH=' >> $PACKAGE_CHAINCODE_DRIVER_NAME
  echo $FABRIC_PATH >> $PACKAGE_CHAINCODE_DRIVER_NAME
  echo -n 'CHAINCODE_ID=' >> $PACKAGE_CHAINCODE_DRIVER_NAME
  echo $CHAINCODE_ID >> $PACKAGE_CHAINCODE_DRIVER_NAME
  echo -n 'CHAINCODE_VERSION=' >> $PACKAGE_CHAINCODE_DRIVER_NAME
  echo $CHAINCODE_VERSION >> $PACKAGE_CHAINCODE_DRIVER_NAME
  echo -n 'PACKAGE_PATH=' >> $PACKAGE_CHAINCODE_DRIVER_NAME
  echo  $TARGET_CFG_PATH >> $PACKAGE_CHAINCODE_DRIVER_NAME
  echo -n 'CHAINCODE_LOCATION=github.com/hyperledger/fabric/' >> $PACKAGE_CHAINCODE_DRIVER_NAME
  echo $CONFIG_DIR >> $PACKAGE_CHAINCODE_DRIVER_NAME
  echo -n '$FABRIC_PATH/build/bin/peer chaincode package -n $CHAINCODE_ID -v $CHAINCODE_VERSION -p $CHAINCODE_LOCATION -s -S $FABRIC_CFG_PATH/$CHAINCODE_ID' >> $PACKAGE_CHAINCODE_DRIVER_NAME
  if [ "$DEBUG" != true ]; then
    echo '.pack &> /dev/null' >> $PACKAGE_CHAINCODE_DRIVER_NAME
  else
    echo '.pack' >> $PACKAGE_CHAINCODE_DRIVER_NAME
  fi

  COUNTER=0
  while [  $COUNTER -lt $node_count ]; do
    let COUNTER=COUNTER+1
    target=$(parse_lookup "$COUNTER" "$nodes")
    if ! [ $1 == $target ]; then
    target_account=$(parse_lookup "$COUNTER" "$accounts")
    echo -n 'echo " - ' >> $PACKAGE_CHAINCODE_DRIVER_NAME
    echo -n $target >> $PACKAGE_CHAINCODE_DRIVER_NAME
    echo '"' >> $PACKAGE_CHAINCODE_DRIVER_NAME
    echo -n 'scp -rq ' >> $PACKAGE_CHAINCODE_DRIVER_NAME
    echo -n $TARGET_CFG_PATH >> $PACKAGE_CHAINCODE_DRIVER_NAME
    echo -n '/' >> $PACKAGE_CHAINCODE_DRIVER_NAME
    echo -n $CHAINCODE_ID >> $PACKAGE_CHAINCODE_DRIVER_NAME
    echo -n '.pack ' >> $PACKAGE_CHAINCODE_DRIVER_NAME
    echo -n $target_account >> $PACKAGE_CHAINCODE_DRIVER_NAME
    echo -n '@' >> $PACKAGE_CHAINCODE_DRIVER_NAME
    echo -n $target >> $PACKAGE_CHAINCODE_DRIVER_NAME
    echo -n ':' >> $PACKAGE_CHAINCODE_DRIVER_NAME
    echo $TARGET_CFG_PATH >> $PACKAGE_CHAINCODE_DRIVER_NAME
    fi
  done

  run_driver $PACKAGE_CHAINCODE_DRIVER_NAME $1 $2
}

create_anchor() {
  ANCHOR_PEER_NAME=$LOCAL_CFG_PATH/$1-anchor.tx
  if [ "$DEBUG" != true ]; then
    $FABRIC_PATH/build/bin/configtxgen -profile Channels -outputAnchorPeersUpdate $ANCHOR_PEER_NAME -channelID blockr -asOrg $1 &> /dev/null
  else 
    $FABRIC_PATH/build/bin/configtxgen -profile Channels -outputAnchorPeersUpdate $ANCHOR_PEER_NAME -channelID blockr -asOrg $1
  fi
  if ! [ -f $ANCHOR_PEER_NAME ]; then
    echo "ERROR failed to create Anchor Peer Transaction for $1"
  fi
}

distribute_conf() {

  echo " - $1"

  NODE_CFG_PATH=./$CONFIG_DIR.$1.$3
  if [ -d $NODE_CFG_PATH ]; then
    rm -rf $NODE_CFG_PATH
  fi
  mkdir -p $NODE_CFG_PATH
  mkdir -p $NODE_CFG_PATH/peerOrganizations/$3
  cp -r $LOCAL_CFG_PATH/peerOrganizations/$3 ./$NODE_CFG_PATH/peerOrganizations
  mkdir -p $NODE_CFG_PATH/ordererOrganizations/$3
  cp -r $LOCAL_CFG_PATH/ordererOrganizations/$3 ./$NODE_CFG_PATH/ordererOrganizations
  cp $LOCAL_CFG_PATH/genesis.block ./$NODE_CFG_PATH
  if [ $1 == $lead_node ]; then
    cp $LOCAL_CFG_PATH/blockr.tx ./$NODE_CFG_PATH
  fi
  ANCHOR_PEER_NAME=$LOCAL_CFG_PATH/$5-anchor.tx
  if [ -f $ANCHOR_PEER_NAME ]; then
    cp $ANCHOR_PEER_NAME ./$NODE_CFG_PATH
  fi

#  CHAINCODE_NAME=./chaincode/blockr_example.go
#  CHAINCODE_NAME=./chaincode/chaincode_example02.go
#  cp $CHAINCODE_NAME ./$NODE_CFG_PATH

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

  cat ./templates/core.yaml | sed "s|PEER_ID|$2| ; s|PEER_ENDPOINT|$1| ; s|PEER_ADDRESS|$1:7051| ; s|PEER_BOOTSTRAP|$1:7051| ; s|WITH_TLS|$WITH_TLS| ; s|PEER_CERT|$CORE_PEER_TLS_CERT_FILE| ; s|PEER_KEY|$CORE_PEER_TLS_KEY_FILE| ; s|PEER_ROOTCERT|$CORE_PEER_TLS_ROOTCERT_FILE| ; s|PEER_MSP_PATH|$CORE_PEER_MSP_PATH| ; s|PEER_MSP_ID|$2| " > $NODE_CFG_PATH/core.yaml

  cat ./templates/orderer.yaml | sed "s:WITH_TLS:$WITH_TLS: ; s:ORDERER_CERT:$ORDERER_GENERAL_TLS_CERTIFICATE: ; s:ORDERER_KEY:$ORDERER_GENERAL_TLS_PRIVATEKEY: ; s:ORDERER_ROOTCERT:$ORDERER_GENERAL_TLS_ROOTCAS: ; s:ORDERER_MSP_PATH:$ORDERER_MSP_PATH: ; s:ORDERER_MSP_ID:$4:   " > $NODE_CFG_PATH/orderer.yaml

  scp -rq $NODE_CFG_PATH/* $6@$1:$TARGET_CFG_PATH
  rm -rf $NODE_CFG_PATH
}

prepare() {
  echo "----------"
  echo " Preparing Node $1"
  echo "----------"

  driver_header $PREPARE_DRIVER_NAME 'Block R Preparation Driver'

  echo -n 'export TARGET_CFG_PATH=' >> $PREPARE_DRIVER_NAME 
  echo $TARGET_CFG_PATH >> $PREPARE_DRIVER_NAME 
  echo 'echo " - Stop Hyperledger, CouchDB, Zookeeper and Kafka daemons"' >> $PREPARE_DRIVER_NAME
  echo 'sudo pkill orderer' >> $PREPARE_DRIVER_NAME
  echo 'sudo pkill peer' >> $PREPARE_DRIVER_NAME
  echo 'sudo systemctl stop couchdb' >> $PREPARE_DRIVER_NAME
  echo 'sudo systemctl stop kafka' >> $PREPARE_DRIVER_NAME
  echo 'sudo systemctl stop zookeeper' >> $PREPARE_DRIVER_NAME
  echo 'echo " - Remove docker images"' >> $PREPARE_DRIVER_NAME
  echo 'sudo docker ps -aq | xargs docker kill &> /dev/null' >> $PREPARE_DRIVER_NAME
  echo 'sudo docker ps -aq | xargs docker rm &> /dev/null' >> $PREPARE_DRIVER_NAME
  echo "sudo docker images | grep 'dev-' | awk '{print $3}' | xargs docker rmi &> /dev/null" >> $PREPARE_DRIVER_NAME
  echo 'echo " - Reset configuration $TARGET_CFG_PATH"' >> $PREPARE_DRIVER_NAME
  echo 'rm -rf $TARGET_CFG_PATH' >> $PREPARE_DRIVER_NAME
  echo 'mkdir $TARGET_CFG_PATH' >> $PREPARE_DRIVER_NAME

  run_driver $PREPARE_DRIVER_NAME $1 $2
}

reset_zookeeper() {

  echo " - $1"

  scp -q $TEMP_CFG_PATH/zookeeper.properties $3@$1:/opt/kafka_2.11-0.10.2.0/config 

  driver_header $RESET_ZOOKEEPER_DRIVER_NAME 'Block R Reset Zookeepxeer Driver'

  echo -n 'ZOOKEEPER_DIR=' >> $RESET_ZOOKEEPER_DRIVER_NAME 
  echo $ZOOKEEPER_DIR >> $RESET_ZOOKEEPER_DRIVER_NAME 
  echo 'if [ -d $ZOOKEEPER_DIR ]; then' >> $RESET_ZOOKEEPER_DRIVER_NAME
  echo '  sudo rm -rf $ZOOKEEPER_DIR' >> $RESET_ZOOKEEPER_DRIVER_NAME
  echo 'fi' >> $RESET_ZOOKEEPER_DRIVER_NAME
  echo 'sudo mkdir $ZOOKEEPER_DIR' >> $RESET_ZOOKEEPER_DRIVER_NAME
  echo -n 'sudo echo "' >> $RESET_ZOOKEEPER_DRIVER_NAME
  echo -n $2 >> $RESET_ZOOKEEPER_DRIVER_NAME
  echo '"> ~/myid' >> $RESET_ZOOKEEPER_DRIVER_NAME
  echo 'sudo mv ~/myid $ZOOKEEPER_DIR' >> $RESET_ZOOKEEPER_DRIVER_NAME

  run_driver $RESET_ZOOKEEPER_DRIVER_NAME $1 $3
}

reset_node() {
  echo "----------"
  echo " Reset Node $1"
  echo "----------"

  cp ./templates/server.properties $TEMP_CFG_PATH/server.properties.template
  cat $TEMP_CFG_PATH/server.properties.template | sed "s|BROKER_ID|$2| ; s|SERVER_ADDRESS|$1| ; s|ZOOKEEPER_CONNECT|$3| " > $TEMP_CFG_PATH/server.properties
  scp -q $TEMP_CFG_PATH/server.properties $4@$1:/opt/kafka_2.11-0.10.2.0/config 

  driver_header $RESET_DRIVER_NAME 'Block R Reset Driver'

  echo -n 'HYPERLEDGER_DIR=' >> $RESET_DRIVER_NAME 
  echo $HYPERLEDGER_DIR >> $RESET_DRIVER_NAME 
  echo -n 'KAFKA_DIR=' >> $RESET_DRIVER_NAME 
  echo $KAFKA_DIR >> $RESET_DRIVER_NAME 
  echo 'echo " - Hyperledger repository"' >> $RESET_DRIVER_NAME
  echo 'if [ -d $HYPERLEDGER_DIR ]; then' >> $RESET_DRIVER_NAME
  echo '  sudo rm -rf $HYPERLEDGER_DIR' >> $RESET_DRIVER_NAME
  echo 'fi' >> $RESET_DRIVER_NAME
  echo 'sudo mkdir $HYPERLEDGER_DIR' >> $RESET_DRIVER_NAME
  echo 'sudo chown $(whoami):$(whoami) $HYPERLEDGER_DIR' >> $RESET_DRIVER_NAME
  echo 'echo " - Kafka repository"' >> $RESET_DRIVER_NAME
  echo 'if [ -d $KAFKA_DIR ]; then' >> $RESET_DRIVER_NAME
  echo '  sudo rm -rf $KAFKA_DIR' >> $RESET_DRIVER_NAME
  echo 'fi' >> $RESET_DRIVER_NAME

  run_driver $RESET_DRIVER_NAME $1 $4

  rm -rf $TEMP_CFG_PATH/server.properties
}

echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

. config.sh
. ./scripts/common.sh

#
# prepare all nodes
#
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1 
  prepare $(parse_lookup "$COUNTER" "$nodes") $(parse_lookup "$COUNTER" "$accounts")
done

#
# setup zookeepers to look at all orderer nodes 
# create a list of zookeepers for each kafka 
#
if [ -d $TEMP_CFG_PATH ]; then
  rm -rf $TEMP_CFG_PATH
fi
mkdir -p $TEMP_CFG_PATH
cp ./templates/zookeeper.properties $TEMP_CFG_PATH
zookeeper_connect=""
COUNTER=0
while [  $COUNTER -lt $zookeeper_count ]; do
  let COUNTER=COUNTER+1 
  z=$(parse_lookup "$COUNTER" "$zookeepers")
  echo "server.$COUNTER=$z:2888:3888" >> $TEMP_CFG_PATH/zookeeper.properties 
  zookeeper_connect="$zookeeper_connect$z:2181,"
done
zookeeper_connect=${zookeeper_connect:0:-1}

#
# setup kafkas for each node and including all zookeepers 
#
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1 
  reset_node $(parse_lookup "$COUNTER" "$nodes") $COUNTER $zookeeper_connect $(parse_lookup "$COUNTER" "$accounts")
done

#
# setup zookeepers 
#
echo "----------"
echo " Reset Zookeeper"
echo "----------"
COUNTER=0
while [  $COUNTER -lt $zookeeper_count ]; do
  let COUNTER=COUNTER+1 
  reset_zookeeper $(parse_lookup "$COUNTER" "$zookeepers") $COUNTER $(parse_lookup "$COUNTER" "$zookeeper_accounts")
done
rm -rf $TEMP_CFG_PATH

echo "----------"
echo " Reset local configuration directory $LOCAL_CFG_PATH"
echo "----------"
rm -rf $LOCAL_CFG_PATH 
mkdir -p $LOCAL_CFG_PATH 

echo "----------"
echo " Generate keys from blockr-config.yaml"
echo "----------"

#cp ./templates/blockr-config.yaml $LOCAL_CFG_PATH
#$FABRIC_PATH/build/bin/cryptogen generate --config $LOCAL_CFG_PATH/blockr-config.yaml --output $LOCAL_CFG_PATH &> generate_keys.txt

#
# create blockr definitions 
#
blockr_config=$LOCAL_CFG_PATH/blockr-config.yaml
echo "################################################################################" >> $blockr_config 
echo "#" >> $blockr_config 
echo "#  Block R Network Configuration generated from config.sh" >> $blockr_config 
echo "#" >> $blockr_config 
echo "################################################################################" >> $blockr_config 
echo "OrdererOrgs:" >> $blockr_config 
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  echo -n "  - Name: " >> $blockr_config 
  echo $(parse_lookup "$COUNTER" "$orderers") >> $blockr_config 
  echo -n "    Domain: " >> $blockr_config 
  echo $(parse_lookup "$COUNTER" "$domains") >> $blockr_config 
  echo "    Specs:" >> $blockr_config 
  echo -n "      - Hostname: " >> $blockr_config 
  echo $(parse_lookup "$COUNTER" "$nodes") >> $blockr_config 
done
echo "PeerOrgs:" >> $blockr_config 
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  echo -n "  - Name: " >> $blockr_config 
  echo $(parse_lookup "$COUNTER" "$peers") >> $blockr_config 
  echo -n "    Domain: " >> $blockr_config 
  echo $(parse_lookup "$COUNTER" "$domains") >> $blockr_config 
  echo "    Users:" >> $blockr_config 
  echo "      Count: 1" >> $blockr_config 
  echo "    Specs:" >> $blockr_config 
  echo -n "      - Hostname: " >> $blockr_config 
  echo $(parse_lookup "$COUNTER" "$nodes") >> $blockr_config 
done
$FABRIC_PATH/build/bin/cryptogen generate --config $blockr_config --output $LOCAL_CFG_PATH &> generate_keys.txt
cat generate_keys.txt
rm generate_keys.txt

echo "----------"
echo " Generate artifacts from configtx.yaml"
echo "----------"

#cp ./templates/configtx.yaml $LOCAL_CFG_PATH
blockr_config=$LOCAL_CFG_PATH/configtx.yaml
echo "---" >> $blockr_config 
echo "################################################################################" >> $blockr_config 
echo "#" >> $blockr_config 
echo "#  Block R Profile generated from config.sh" >> $blockr_config 
echo "#" >> $blockr_config 
echo "################################################################################" >> $blockr_config 
echo "Profiles:" >> $blockr_config 
echo "  Genesis:" >> $blockr_config 
echo "    Capabilities:" >> $blockr_config 
echo "      <<: *GlobalCapabilities" >> $blockr_config
echo "    Orderer:" >> $blockr_config 
echo "      <<: *OrdererDefaults" >> $blockr_config
echo "      Organizations:" >> $blockr_config
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  echo "        - *OrdererOrg$COUNTER" >> $blockr_config 
done
echo "      Capabilities:" >> $blockr_config
echo "        <<: *OrdererCapabilities" >> $blockr_config
echo "    Consortiums:" >> $blockr_config 
echo "      RealtorAssociations:" >> $blockr_config 
echo "        Organizations:" >> $blockr_config
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  echo "          - *Org$COUNTER" >> $blockr_config 
done
echo "  Channels:" >> $blockr_config 
echo "    Consortium: RealtorAssociations" >> $blockr_config 
echo "    Application:" >> $blockr_config 
echo "      <<: *ApplicationDefaults" >> $blockr_config
echo "      Organizations:" >> $blockr_config
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  echo "        - *Org$COUNTER" >> $blockr_config 
done
echo "      Capabilities:" >> $blockr_config
echo "        <<: *ApplicationCapabilities" >> $blockr_config
echo "Organizations:" >> $blockr_config 
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  echo "  - &OrdererOrg$COUNTER" >> $blockr_config 
  anOrderer=$(parse_lookup "$COUNTER" "$orderers")
  anOrdererName=$(parse_lookup "$COUNTER" "$orderer_names")
  echo -n "    Name: " >> $blockr_config
  echo $anOrdererName >> $blockr_config 
  echo -n "    ID: " >> $blockr_config
  echo $anOrderer >> $blockr_config 
  echo "    AdminPrincipal: Role.ADMIN" >>$blockr_config
#    AdminPrincipal: Role.MEMBER
  aDomain=$(parse_lookup "$COUNTER" "$domains")
  echo -n "    MSPDir: ordererOrganizations/" >> $blockr_config
  echo -n $aDomain >> $blockr_config 
  echo "/msp" >> $blockr_config
done
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  echo "  - &Org$COUNTER" >> $blockr_config 
  aPeer=$(parse_lookup "$COUNTER" "$peers")
  aPeerName=$(parse_lookup "$COUNTER" "$peer_names")
  echo -n "    Name: " >> $blockr_config
  echo $aPeerName >> $blockr_config 
  echo -n "    ID: " >> $blockr_config
  echo $aPeer >> $blockr_config 
  echo "    AdminPrincipal: Role.ADMIN" >>$blockr_config
#    AdminPrincipal: Role.MEMBER
  aDomain=$(parse_lookup "$COUNTER" "$domains")
  echo -n "    MSPDir: peerOrganizations/" >> $blockr_config
  echo -n $aDomain >> $blockr_config 
  echo "/msp" >> $blockr_config
  echo "    AnchorPeers:" >> $blockr_config
  echo -n "      - Host: " >> $blockr_config
  echo $(parse_lookup "$COUNTER" "$nodes") >> $blockr_config
  echo "        Port: 7051" >> $blockr_config
done
echo "Orderer: &OrdererDefaults" >> $blockr_config 
echo "  OrdererType: kafka" >> $blockr_config
echo "  Addresses:" >> $blockr_config
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  echo -n "    - " >> $blockr_config 
  echo -n $(parse_lookup "$COUNTER" "$nodes") >> $blockr_config 
  echo ":7050" >> $blockr_config 
done
echo "  BatchTimeout: 1ms" >> $blockr_config
echo "  BatchSize:" >> $blockr_config
echo "    MaxMessageCount: 10" >> $blockr_config
echo "    AbsoluteMaxBytes: 95 MB" >> $blockr_config
echo "    PreferredMaxBytes: 95 KB" >> $blockr_config
echo "  MaxChannels: 0" >> $blockr_config
echo "  Kafka:" >> $blockr_config
echo "    Brokers:" >> $blockr_config
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  echo -n "      - " >> $blockr_config 
  echo -n $(parse_lookup "$COUNTER" "$nodes") >> $blockr_config 
  echo ":9092" >> $blockr_config 
done
echo "  Organizations:" >> $blockr_config
echo "Application: &ApplicationDefaults" >> $blockr_config 
echo "  Organizations:" >> $blockr_config
echo "Capabilities:" >> $blockr_config 
echo "  Global: &GlobalCapabilities" >> $blockr_config
echo '    "V1.1": true' >> $blockr_config
echo "  Orderer: &OrdererCapabilities" >> $blockr_config
echo '    "V1.1": true' >> $blockr_config
echo "  Application: &ApplicationCapabilities" >> $blockr_config
echo '    "V1.1": true' >> $blockr_config

export FABRIC_CFG_PATH=./$CONFIG_DIR

echo " - Genesis block using profile:Genesis"
if [ "$DEBUG" != true ]; then
  $FABRIC_PATH/build/bin/configtxgen -profile Genesis -outputBlock $LOCAL_CFG_PATH/genesis.block -channelID system &> /dev/null
else
  $FABRIC_PATH/build/bin/configtxgen -profile Genesis -outputBlock $LOCAL_CFG_PATH/genesis.block -channelID system
fi
if ! [ -f $LOCAL_CFG_PATH/genesis.block ]; then
  echo 'ERROR'
  exit 1
fi

echo " - Channel block using profile:Channels"
if [ "$DEBUG" != true ]; then
  $FABRIC_PATH/build/bin/configtxgen -profile Channels -outputCreateChannelTx $LOCAL_CFG_PATH/blockr.tx -channelID blockr &> /dev/null
else
  $FABRIC_PATH/build/bin/configtxgen -profile Channels -outputCreateChannelTx $LOCAL_CFG_PATH/blockr.tx -channelID blockr
fi
if ! [ -f $LOCAL_CFG_PATH/blockr.tx ]; then
  echo 'ERROR'
  exit 1
fi

#
# AnchorPeer transactions
#
if [ "$WITH_ANCHOR_PEERS" = true ]; then
  echo " - AnchorPeer transactions using profile:Channels"
  COUNTER=0
  while [  $COUNTER -lt $node_count ]; do
    let COUNTER=COUNTER+1 
    create_anchor $(parse_lookup "$COUNTER" "$peer_names")
  done
fi

#
# Peer and orderer configuration distribution
#
echo "----------"
echo " Distribute configuration"
echo "----------"
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1 
  distribute_conf $(parse_lookup "$COUNTER" "$nodes") $(parse_lookup "$COUNTER" "$peers") $(parse_lookup "$COUNTER" "$domains") $(parse_lookup "$COUNTER" "$orderers") $(parse_lookup "$COUNTER" "$peer_names") $(parse_lookup "$COUNTER" "$accounts")
done

rm -rf $LOCAL_CFG_PATH 

#
# Package and distribute validation chaincode 
#
package_chaincode $(parse_lookup 1 "$nodes") $(parse_lookup 1 "$accounts")

