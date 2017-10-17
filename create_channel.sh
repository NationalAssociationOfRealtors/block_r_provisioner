
export CONFIG_DIR=blockr_config
export DEBUG=false
export DELAY_TIME=60
export FABRIC_PATH=$GOPATH/src/github.com/hyperledger/fabric
export FABRIC_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR
export COPY_BLOCK_DRIVER_NAME=copy_block_driver.sh
export CREATE_ANCHOR_DRIVER_NAME=create_anchor_driver.sh
export CREATE_CHANNEL_DRIVER_NAME=create_channel_driver.sh
export JOIN_CHANNEL_DRIVER_NAME=join_channel_driver.sh
export WAIT_SECONDS=0
export WITH_ANCHOR_PEERS=false
export WITH_TLS=true

copy_block_driver() {
  echo "----------"
  echo " Copy channel block from Node $1 to Node $2"
  echo "----------"

  echo '#!/bin/bash' > $COPY_BLOCK_DRIVER_NAME
  echo '' >> $COPY_BLOCK_DRIVER_NAME
  echo '#----------------' >> $COPY_BLOCK_DRIVER_NAME
  echo '#' >> $COPY_BLOCK_DRIVER_NAME
  echo '# Block R Create Channel Driver' >> $COPY_BLOCK_DRIVER_NAME
  echo '#' >> $COPY_BLOCK_DRIVER_NAME
  echo '#----------------' >> $COPY_BLOCK_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $COPY_BLOCK_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $COPY_BLOCK_DRIVER_NAME
  echo -n 'scp -q ' >> $COPY_BLOCK_DRIVER_NAME
  echo -n $FABRIC_CFG_PATH >> $COPY_BLOCK_DRIVER_NAME
  echo -n '/blockr.block ' >> $COPY_BLOCK_DRIVER_NAME
  echo -n $2 >> $COPY_BLOCK_DRIVER_NAME
  echo -n ':' >> $COPY_BLOCK_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $COPY_BLOCK_DRIVER_NAME

  scp -q ./$COPY_BLOCK_DRIVER_NAME $1:
  ssh $1 "chmod 777 $COPY_BLOCK_DRIVER_NAME"
  ssh $1 "./$COPY_BLOCK_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
   ssh $1 "rm ./$COPY_BLOCK_DRIVER_NAME"
  fi
  rm ./$COPY_BLOCK_DRIVER_NAME
}

create_channel_driver() {
  echo "----------"
  echo " Create channel from Node $1"
  echo "----------"

  ORDERER_TLS=''
  if [ "$WITH_TLS" = true ]; then
    ORDERER_TLS=" --tls true --cafile $FABRIC_CFG_PATH/ordererOrganizations/$3/orderers/$1.$3/tls/ca.crt"
  fi
  echo '#!/bin/bash' > $CREATE_CHANNEL_DRIVER_NAME
  echo '' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '#----------------' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '#' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '# Block R Create Channel Driver' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '#' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '#----------------' >> $CREATE_CHANNEL_DRIVER_NAME
#  echo -n 'export CORE_PEER_LOCALMSPID=' >> $CREATE_CHANNEL_DRIVER_NAME
#  echo $2 >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n 'export FABRIC_PATH=' >> $CREATE_CHANNEL_DRIVER_NAME
  echo $FABRIC_PATH >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $CREATE_CHANNEL_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n 'export CORE_PEER_MSPCONFIGPATH=' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n $FABRIC_CFG_PATH >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n '/peerOrganizations/' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n $3 >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n '/users/Admin@' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n $3 >> $CREATE_CHANNEL_DRIVER_NAME
  echo '/msp' >> $CREATE_CHANNEL_DRIVER_NAME
  echo 'echo " - Create the channel block"' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n '$FABRIC_PATH/build/bin/peer channel create -f $FABRIC_CFG_PATH/blockr.tx -c blockr -o ' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n $1 >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n ':7050 ' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n '-t ' >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n $DELAY_TIME >> $CREATE_CHANNEL_DRIVER_NAME
  echo -n " " >> $CREATE_CHANNEL_DRIVER_NAME
  echo $ORDERER_TLS >> $CREATE_CHANNEL_DRIVER_NAME
  if ! [ $WAIT_SECONDS = 0 ]; then
    echo 'echo " - Wait for Kafka to complete"' >> $CREATE_CHANNEL_DRIVER_NAME
    echo -n "sleep " >> $CREATE_CHANNEL_DRIVER_NAME
    echo $WAIT_SECONDS >> $CREATE_CHANNEL_DRIVER_NAME
    echo 'echo " - Kafka complete"' >> $CREATE_CHANNEL_DRIVER_NAME
  fi
  echo 'if ! [ -f blockr.block ]; then' >> $CREATE_CHANNEL_DRIVER_NAME
  echo 'echo ERROR' >> $CREATE_CHANNEL_DRIVER_NAME
  echo 'exit 1' >> $CREATE_CHANNEL_DRIVER_NAME
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
    ORDERER_TLS=" --tls true --cafile $FABRIC_CFG_PATH/ordererOrganizations/$3/orderers/$1.$3/tls/ca.crt"
  fi
  echo '#!/bin/bash' > $JOIN_CHANNEL_DRIVER_NAME
  echo '' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '#----------------' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '#' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '# Block R Join Channel Driver' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '#' >> $JOIN_CHANNEL_DRIVER_NAME
  echo '#----------------' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n 'export FABRIC_PATH=' >> $JOIN_CHANNEL_DRIVER_NAME
  echo $FABRIC_PATH >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $JOIN_CHANNEL_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n 'export CORE_PEER_MSPCONFIGPATH=' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $FABRIC_CFG_PATH >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n '/peerOrganizations/' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $3 >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n '/users/Admin@' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $3 >> $JOIN_CHANNEL_DRIVER_NAME
  echo '/msp' >> $JOIN_CHANNEL_DRIVER_NAME
  echo 'echo " - Join the channel"' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n '$FABRIC_PATH/build/bin/peer channel join -b $FABRIC_CFG_PATH/blockr.block -o ' >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n $1 >> $JOIN_CHANNEL_DRIVER_NAME
  echo -n ':7050 ' >> $JOIN_CHANNEL_DRIVER_NAME
  echo $ORDERER_TLS >> $JOIN_CHANNEL_DRIVER_NAME
  if ! [ $WAIT_SECONDS = 0 ]; then
    echo 'echo " - Wait for Kafka to complete"' >> $JOIN_CHANNEL_DRIVER_NAME
    echo -n "sleep " >> $JOIN_CHANNEL_DRIVER_NAME
    echo $WAIT_SECONDS >> $JOIN_CHANNEL_DRIVER_NAME
    echo 'echo " - Kafka complete"' >> $JOIN_CHANNEL_DRIVER_NAME
  fi

  scp -q ./$JOIN_CHANNEL_DRIVER_NAME $1:
  ssh $1 "chmod 777 $JOIN_CHANNEL_DRIVER_NAME"
  ssh $1 "./$JOIN_CHANNEL_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
   ssh $1 "rm ./$JOIN_CHANNEL_DRIVER_NAME"
  fi
  rm ./$JOIN_CHANNEL_DRIVER_NAME
}

anchor_peer_driver() {
  echo ""
  echo "----------"
  echo " Create anchor peer from Node $1"
  echo "----------"

  ORDERER_TLS=''
  if [ "$WITH_TLS" = true ]; then
    ORDERER_TLS=" --tls true --cafile $FABRIC_CFG_PATH/ordererOrganizations/$3/orderers/$1.$3/tls/ca.crt"
  fi
  echo '#!/bin/bash' > $CREATE_CHANNEL_DRIVER_NAME
  echo '' >> $CREATE_CHANNEL_DRIVER_NAME
  echo '#----------------' >> $CREATE_ANCHOR_DRIVER_NAME
  echo '#' >> $CREATE_ANCHOR_DRIVER_NAME
  echo '# Block R Join Channel Driver' >> $CREATE_ANCHOR_DRIVER_NAME
  echo '#' >> $CREATE_ANCHOR_DRIVER_NAME
  echo '#----------------' >> $CREATE_ANCHOR_DRIVER_NAME
  echo -n 'export FABRIC_PATH=' >> $CREATE_ANCHOR_DRIVER_NAME
  echo $FABRIC_PATH >> $CREATE_ANCHOR_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $CREATE_ANCHOR_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $CREATE_ANCHOR_DRIVER_NAME
  echo -n 'export CORE_PEER_MSPCONFIGPATH=' >> $CREATE_ANCHOR_DRIVER_NAME
  echo -n $FABRIC_CFG_PATH >> $CREATE_ANCHOR_DRIVER_NAME
  echo -n '/peerOrganizations/' >> $CREATE_ANCHOR_DRIVER_NAME
  echo -n $3 >> $CREATE_ANCHOR_DRIVER_NAME
  echo -n '/users/Admin@' >> $CREATE_ANCHOR_DRIVER_NAME
  echo -n $3 >> $CREATE_ANCHOR_DRIVER_NAME
  echo '/msp' >> $CREATE_ANCHOR_DRIVER_NAME
  echo 'echo " - Update the channel for Anchor Peer"' >> $CREATE_ANCHOR_DRIVER_NAME
  echo -n '$FABRIC_PATH/build/bin/peer channel update -f $FABRIC_CFG_PATH/' >> $CREATE_ANCHOR_DRIVER_NAME
  echo -n "$2" >> $CREATE_ANCHOR_DRIVER_NAME
  echo -n 'anchors.tx -c blockr -o ' >> $CREATE_ANCHOR_DRIVER_NAME
  echo -n "$1" >> $CREATE_ANCHOR_DRIVER_NAME
  echo -n ':7050 ' >> $CREATE_ANCHOR_DRIVER_NAME
  echo $ORDERER_TLS >> $CREATE_ANCHOR_DRIVER_NAME
  if ! [ $WAIT_SECONDS = 0 ]; then
    echo 'echo " - Wait for Kafka to complete"' >> $CREATE_ANCHOR_DRIVER_NAME
    echo -n "sleep " >> $CREATE_ANCHOR_DRIVER_NAME
    echo $WAIT_SECONDS >> $CREATE_ANCHOR_DRIVER_NAME
    echo 'echo " - Kafka complete"' >> $CREATE_ANCHOR_DRIVER_NAME
  fi

  scp -q ./$CREATE_ANCHOR_DRIVER_NAME $1:
  ssh $1 "chmod 777 $CREATE_ANCHOR_DRIVER_NAME"
  ssh $1 "./$CREATE_ANCHOR_DRIVER_NAME"
  if [ "$DEBUG" != true ]; then
   ssh $1 "rm ./$CREATE_ANCHOR_DRIVER_NAME"
  fi
  rm ./$CREATE_ANCHOR_DRIVER_NAME
}


echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

create_channel_driver vm1 Org1MSP nar.blockr
copy_block_driver vm1 vm2 
join_channel_driver vm1 Org1MSP nar.blockr
join_channel_driver vm2 Org2MSP car.blockr
if [ "$WITH_ANCHOR_PEERS" = true ]; then
  anchor_peer_driver vm1 Org1MSP nar.blockr
  anchor_peer_driver vm2 Org2MSP car.blockr
fi
