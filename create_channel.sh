#!/bin/bash

CONFIG_DIR=blockr_config
DEBUG=true
DELAY_TIME=60
FABRIC_PATH=$GOPATH/src/github.com/hyperledger/fabric
FABRIC_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR
CREATE_ANCHOR_DRIVER_NAME=create_anchor_driver.sh
CREATE_CHANNEL_DRIVER_NAME=create_channel_driver.sh
JOIN_CHANNEL_DRIVER_NAME=join_channel_driver.sh
WITH_TLS=true

create_channel() {
  echo "----------"
  echo " Create channel from Node $1"
  echo "----------"

  ORDERER_TLS=''
  if [ "$WITH_TLS" = true ]; then
    ORDERER_TLS=" --tls --cafile $FABRIC_CFG_PATH/ordererOrganizations/$3/orderers/$1.$3/tls/ca.crt"
  fi

  driver_header $CREATE_CHANNEL_DRIVER_NAME 'Block R Channel Driver'

  echo -n 'export CORE_PEER_MSPCONFIGPATH=' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n $FABRIC_CFG_PATH >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n '/peerOrganizations/' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n $3 >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n '/users/Admin@' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n $3 >> $CREATE_CHANNEL_DRIVER_NAME
  echo '/msp' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n 'export FABRIC_PATH=' >> $CREATE_CHANNEL_DRIVER_NAME
  echo $FABRIC_PATH >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $CREATE_CHANNEL_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n 'export ORDERER_TLS="' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n $ORDERER_TLS >> $CREATE_CHANNEL_DRIVER_NAME
  echo '"' >> $CREATE_CHANNEL_DRIVER_NAME

  echo -n '$FABRIC_PATH/build/bin/peer channel list -o ' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n $1 >> $CREATE_CHANNEL_DRIVER_NAME
  echo ':7050 $ORDERER_TLS &> joined_channels.txt' >> $CREATE_CHANNEL_DRIVER_NAME
  if [ "$DEBUG" == true ]; then
    echo 'cat joined_channels.txt' >> $CREATE_CHANNEL_DRIVER_NAME
  fi
  echo 'if grep -q blockr joined_channels.txt; then' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '  echo " - Channel exists"' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '  rm joined_channels.txt' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '  exit 1' >> $CREATE_CHANNEL_DRIVER_NAME
  echo 'fi' >> $CREATE_CHANNEL_DRIVER_NAME
  echo 'rm joined_channels.txt' >> $CREATE_CHANNEL_DRIVER_NAME

  echo 'echo " - Create the channel block"' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n '$FABRIC_PATH/build/bin/peer channel create -f $FABRIC_CFG_PATH/blockr.tx -c blockr -o ' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n $1 >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n ':7050 ' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n '-t ' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n $DELAY_TIME >> $CREATE_CHANNEL_DRIVER_NAME
  if [ "$DEBUG" != true ]; then
    echo ' $ORDERER_TLS &> /dev/null' >> $CREATE_CHANNEL_DRIVER_NAME
  else 
    echo ' $ORDERER_TLS' >> $CREATE_CHANNEL_DRIVER_NAME
  fi
  echo 'if ! [ -f blockr.block ]; then' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '  echo ERROR' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '  exit 1' >> $CREATE_CHANNEL_DRIVER_NAME
  echo 'fi' >> $CREATE_CHANNEL_DRIVER_NAME
  echo 'mv blockr.block $FABRIC_CFG_PATH' >> $CREATE_CHANNEL_DRIVER_NAME

  run_driver $CREATE_CHANNEL_DRIVER_NAME $1 $4
}

join_channel() {
  echo "----------"
  echo " Join Node $1 to channel"
  echo "----------"

  ORDERER_TLS=''
  if [ "$WITH_TLS" = true ]; then
    ORDERER_TLS=" --tls --cafile $FABRIC_CFG_PATH/ordererOrganizations/$3/orderers/$1.$3/tls/ca.crt"
  fi

  driver_header $JOIN_CHANNEL_DRIVER_NAME 'Block R Join Channel Driver'

  echo -n 'export ANCHOR_PEER_NAME=' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $5 >> $JOIN_CHANNEL_DRIVER_NAME
  echo '-anchor.tx' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n 'export CORE_PEER_MSPCONFIGPATH=' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $FABRIC_CFG_PATH >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n '/peerOrganizations/' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $3 >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n '/users/Admin@' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $3 >> $JOIN_CHANNEL_DRIVER_NAME
  echo '/msp' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n 'export FABRIC_PATH=' >> $JOIN_CHANNEL_DRIVER_NAME
  echo $FABRIC_PATH >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $JOIN_CHANNEL_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n 'export ORDERER_TLS="' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $ORDERER_TLS >> $JOIN_CHANNEL_DRIVER_NAME
  echo '"' >> $JOIN_CHANNEL_DRIVER_NAME

  echo -n '$FABRIC_PATH/build/bin/peer channel list -o ' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $1 >> $JOIN_CHANNEL_DRIVER_NAME
  echo ':7050 $ORDERER_TLS &> joined_channels.txt' >> $JOIN_CHANNEL_DRIVER_NAME
  if [ "$DEBUG" == true ]; then
    echo 'cat joined_channels.txt' >> $JOIN_CHANNEL_DRIVER_NAME
  fi
  echo 'if grep -q blockr joined_channels.txt; then' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '  echo " - Channel is already joined"' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '  rm joined_channels.txt' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '  exit 1' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'fi' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'rm joined_channels.txt' >> $JOIN_CHANNEL_DRIVER_NAME

  echo 'if [ -f $FABRIC_CFG_PATH/blockr.block ]; then' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '  echo " - Use channel block"' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'else' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '  echo " - Fetch channel block"' >> $JOIN_CHANNEL_DRIVER_NAME
#  echo -n '  $FABRIC_PATH/build/bin/peer channel fetch 0 $FABRIC_CFG_PATH/blockr.block -c blockr -o ' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n '  $FABRIC_PATH/build/bin/peer channel fetch oldest $FABRIC_CFG_PATH/blockr.block -c blockr -o ' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $1 >> $JOIN_CHANNEL_DRIVER_NAME
  if [ "$DEBUG" != true ]; then
    echo ':7050 $ORDERER_TLS &> /dev/null' >> $JOIN_CHANNEL_DRIVER_NAME
  else 
    echo ':7050 $ORDERER_TLS' >> $JOIN_CHANNEL_DRIVER_NAME
  fi
  echo 'fi' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n '$FABRIC_PATH/build/bin/peer channel join -b $FABRIC_CFG_PATH/blockr.block -o ' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $1 >> $JOIN_CHANNEL_DRIVER_NAME
  if [ "$DEBUG" != true ]; then
    echo ':7050 $ORDERER_TLS &> /dev/null' >> $JOIN_CHANNEL_DRIVER_NAME
  else 
    echo ':7050 $ORDERER_TLS' >> $JOIN_CHANNEL_DRIVER_NAME
  fi

  echo -n '$FABRIC_PATH/build/bin/peer channel list -o ' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $1 >> $JOIN_CHANNEL_DRIVER_NAME
  echo ':7050 $ORDERER_TLS &> joined_channels.txt' >> $JOIN_CHANNEL_DRIVER_NAME
  if [ "$DEBUG" == true ]; then
    echo 'cat joined_channels.txt' >> $JOIN_CHANNEL_DRIVER_NAME
  fi
  echo 'if grep -q blockr joined_channels.txt; then' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '  echo " - Peer joined the channel!"' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'fi' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'rm joined_channels.txt' >> $JOIN_CHANNEL_DRIVER_NAME

  echo 'if [ -f $FABRIC_CFG_PATH/$ANCHOR_PEER_NAME ]; then' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '  echo " - Add AnchorPeer"' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n '  $FABRIC_PATH/build/bin/peer channel update -f $FABRIC_CFG_PATH/$ANCHOR_PEER_NAME -c blockr -o ' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $1 >> $JOIN_CHANNEL_DRIVER_NAME
  if [ "$DEBUG" != true ]; then
    echo ':7050 $ORDERER_TLS &> /dev/null' >> $JOIN_CHANNEL_DRIVER_NAME
  else
    echo ':7050 $ORDERER_TLS' >> $JOIN_CHANNEL_DRIVER_NAME
  fi
  echo 'fi' >> $JOIN_CHANNEL_DRIVER_NAME

  run_driver $JOIN_CHANNEL_DRIVER_NAME $1 $4
}

echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

. config.sh
. ./scripts/common.sh

#
# create the channel 
#
create_channel $(parse_lookup 1 "$nodes") $(parse_lookup 1 "$peers") $(parse_lookup 1 "$domains") $(parse_lookup 1 "$accounts")

#
# join the channel 
#
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  join_channel $(parse_lookup "$COUNTER" "$nodes") $(parse_lookup "$COUNTER" "$peers") $(parse_lookup "$COUNTER" "$domains") $(parse_lookup "$COUNTER" "$accounts") $(parse_lookup "$COUNTER" "$peer_names")
done


