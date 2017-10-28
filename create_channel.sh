
export CONFIG_DIR=blockr_config
export DEBUG=false
export DELAY_TIME=60
export FABRIC_PATH=$GOPATH/src/github.com/hyperledger/fabric
export FABRIC_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR
export CREATE_ANCHOR_DRIVER_NAME=create_anchor_driver.sh
export CREATE_CHANNEL_DRIVER_NAME=create_channel_driver.sh
export JOIN_CHANNEL_DRIVER_NAME=join_channel_driver.sh
export WITH_TLS=true

create_channel_driver() {
  echo "----------"
  echo " Create channel from Node $1"
  echo "----------"

  ORDERER_TLS=''
  if [ "$WITH_TLS" = true ]; then
    ORDERER_TLS=" --tls --cafile $FABRIC_CFG_PATH/ordererOrganizations/$3/orderers/$1.$3/tls/ca.crt"
  fi
  echo '#!/bin/bash' > $CREATE_CHANNEL_DRIVER_NAME
  echo '' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '#----------------' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '#' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '# Block R Create Channel Driver' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '#' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '#----------------' >> $CREATE_CHANNEL_DRIVER_NAME
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
  echo ' $ORDERER_TLS &> /dev/null' >> $CREATE_CHANNEL_DRIVER_NAME
  echo 'if ! [ -f blockr.block ]; then' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '  echo ERROR' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '  exit 1' >> $CREATE_CHANNEL_DRIVER_NAME
  echo 'fi' >> $CREATE_CHANNEL_DRIVER_NAME
 echo 'mv blockr.block $FABRIC_CFG_PATH' >> $CREATE_CHANNEL_DRIVER_NAME

  scp -q ./$CREATE_CHANNEL_DRIVER_NAME $1:
  ssh $1 "chmod 777 $CREATE_CHANNEL_DRIVER_NAME"
  ssh $1 "./$CREATE_CHANNEL_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
   ssh $1 "rm ./$CREATE_CHANNEL_DRIVER_NAME"
  fi
  rm ./$CREATE_CHANNEL_DRIVER_NAME
}

join_channel_driver() {
  echo "----------"
  echo " Join channel from Node $1"
  echo "----------"

  ORDERER_TLS=''
  if [ "$WITH_TLS" = true ]; then
    ORDERER_TLS=" --tls --cafile $FABRIC_CFG_PATH/ordererOrganizations/$3/orderers/$1.$3/tls/ca.crt"
  fi
  echo '#!/bin/bash' > $JOIN_CHANNEL_DRIVER_NAME
  echo '' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '#----------------' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '#' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '# Block R Join Channel Driver' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '#' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '#----------------' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n 'export ANCHOR_PEER_NAME=' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $2 >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'anchor.tx' >> $JOIN_CHANNEL_DRIVER_NAME
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
  echo 'if grep -q blockr joined_channels.txt; then' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '  echo " - Channel is already joined"' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '  rm joined_channels.txt' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '  exit 1' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'fi' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'rm joined_channels.txt' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'if ! [ -f $FABRIC_CFG_PATH/blockr.block ]; then' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '  echo " - Fetch missing channel definition"' >> $JOIN_CHANNEL_DRIVER_NAME
#  echo -n '  $FABRIC_PATH/build/bin/peer channel fetch 0 $FABRIC_CFG_PATH/blockr.block -c blockr -o ' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n '  $FABRIC_PATH/build/bin/peer channel fetch oldest $FABRIC_CFG_PATH/blockr.block -c blockr -o ' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $1 >> $JOIN_CHANNEL_DRIVER_NAME
  echo ':7050 $ORDERER_TLS &> /dev/null' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'fi' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'echo " - Join the channel"' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n '$FABRIC_PATH/build/bin/peer channel join -b $FABRIC_CFG_PATH/blockr.block -o ' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $1 >> $JOIN_CHANNEL_DRIVER_NAME
  echo ':7050 $ORDERER_TLS &> joined_channels.txt' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'if grep -q "Peer joined the channel!" joined_channels.txt; then' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '  echo " - Peer joined the channel!"' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '  rm joined_channels.txt' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '  exit 1' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'fi' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'rm joined_channels.txt' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'if [ -f $FABRIC_CFG_PATH/$ANCHOR_PEER_NAME ]; then' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '  echo " - Add AnchorPeer"' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n '  $FABRIC_PATH/build/bin/peer channel update -f $FABRIC_CFG_PATH/$ANCHOR_PEER_NAME -c blockr -o ' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $1 >> $JOIN_CHANNEL_DRIVER_NAME
  echo ':7050 $ORDERER_TLS &> /dev/null' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'fi' >> $JOIN_CHANNEL_DRIVER_NAME

  scp -q ./$JOIN_CHANNEL_DRIVER_NAME $1:
  ssh $1 "chmod 777 $JOIN_CHANNEL_DRIVER_NAME"
  ssh $1 "./$JOIN_CHANNEL_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
   ssh $1 "rm ./$JOIN_CHANNEL_DRIVER_NAME"
  fi
  rm ./$JOIN_CHANNEL_DRIVER_NAME
}

echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

create_channel_driver vm1 Org1MSP nar.blockr
join_channel_driver vm1 Org1MSP nar.blockr
join_channel_driver vm2 Org2MSP car.blockr

