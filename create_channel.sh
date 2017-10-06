
export CONFIG_DIR=blockr_config
#export CORE_PEER_ADDRESS=vm1:7051 
#export CORE_PEER_LOCALMSPID=Org1MSP 
export FABRIC_PATH=$GOPATH/src/github.com/hyperledger/fabric
export FABRIC_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR
#export CORE_PEER_MSPCONFIGPATH=$FABRIC_CFG_PATH/peerOrganizations/nar.blockr/users/Admin@nar.blockr/msp/ 
export CHANNEL_DRIVER_NAME=join_channel_driver.sh
export WITH_TLS=true
export WAIT_SECONDS=1

distribute_channel_driver() {
  echo ""
  echo "----------"
  echo " Create channel on Node $1"
  echo "----------"

  ORDERER_TLS=''
  if [ "$WITH_TLS" = true ]; then
    ORDERER_TLS="--tls true --cafile $FABRIC_CFG_PATH/ordererOrganizations/$3/orderers/$1.$3/tls/ca.crt"
  fi

#
# create the driver script
#
  echo '#!/bin/bash' > $CHANNEL_DRIVER_NAME
  echo '' >> $CHANNEL_DRIVER_NAME
  echo '#----------------' >> $CHANNEL_DRIVER_NAME
  echo '#' >> $CHANNEL_DRIVER_NAME
  echo '# Block R Channel Driver' >> $CHANNEL_DRIVER_NAME
  echo '#' >> $CHANNEL_DRIVER_NAME
  echo '#----------------' >> $CHANNEL_DRIVER_NAME
  echo -n 'export FABRIC_PATH=' >> $CHANNEL_DRIVER_NAME
  echo $FABRIC_PATH >> $CHANNEL_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $CHANNEL_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $CHANNEL_DRIVER_NAME
  echo -n 'export CORE_PEER_MSPCONFIGPATH=' >> $CHANNEL_DRIVER_NAME
  echo -n $FABRIC_CFG_PATH >> $CHANNEL_DRIVER_NAME
  echo -n '/peerOrganizations/' >> $CHANNEL_DRIVER_NAME
  echo -n $3 >> $CHANNEL_DRIVER_NAME
  echo -n '/users/Admin@' >> $CHANNEL_DRIVER_NAME
  echo -n $3 >> $CHANNEL_DRIVER_NAME
  echo '/msp' >> $CHANNEL_DRIVER_NAME
  echo 'echo "----------"' >> $CHANNEL_DRIVER_NAME
  echo 'echo " Create the channel block"' >> $CHANNEL_DRIVER_NAME
  echo 'echo "----------"' >> $CHANNEL_DRIVER_NAME
  echo -n '$FABRIC_PATH/build/bin/peer channel create -f $FABRIC_CFG_PATH/blockr.tx -c blockr -o ' >> $CHANNEL_DRIVER_NAME
  echo -n $1 >> $CHANNEL_DRIVER_NAME
  echo -n ':7050 ' >> $CHANNEL_DRIVER_NAME
  echo $ORDERER_TLS >> $CHANNEL_DRIVER_NAME
  echo 'if ! [ -f blockr.block ]; then' >> $CHANNEL_DRIVER_NAME
  echo 'echo ERROR' >> $CHANNEL_DRIVER_NAME
  echo 'exit 1' >> $CHANNEL_DRIVER_NAME
  echo 'fi' >> $CHANNEL_DRIVER_NAME
  echo 'mv blockr.block $FABRIC_CFG_PATH' >> $CHANNEL_DRIVER_NAME
  echo 'echo "----------"' >> $CHANNEL_DRIVER_NAME
  echo 'echo " Join the channel"' >> $CHANNEL_DRIVER_NAME
  echo 'echo "----------"' >> $CHANNEL_DRIVER_NAME
  echo -n '$FABRIC_PATH/build/bin/peer channel join -b $FABRIC_CFG_PATH/blockr.block -o ' >> $CHANNEL_DRIVER_NAME
  echo -n $1 >> $CHANNEL_DRIVER_NAME
  echo -n ':7050' >> $CHANNEL_DRIVER_NAME
  echo $ORDERER_TLS >> $CHANNEL_DRIVER_NAME
  echo 'echo "----------"' >> $CHANNEL_DRIVER_NAME
  echo 'echo " Update the channel for Anchor Peer"' >> $CHANNEL_DRIVER_NAME
  echo 'echo "----------"' >> $CHANNEL_DRIVER_NAME
  echo -n '#$FABRIC_PATH/build/bin/peer channel update -f $FABRIC_CFG_PATH/' >> $CHANNEL_DRIVER_NAME
  echo -n "$2" >> $CHANNEL_DRIVER_NAME
  echo -n 'anchors.tx -c blockr -o ' >> $CHANNEL_DRIVER_NAME
  echo -n "$1" >> $CHANNEL_DRIVER_NAME
  echo -n ':7050' >> $CHANNEL_DRIVER_NAME
  echo $ORDERER_TLS >> $CHANNEL_DRIVER_NAME

  scp -q ./$CHANNEL_DRIVER_NAME $1:
  ssh $1 "chmod 777 $CHANNEL_DRIVER_NAME"
  ssh $1 "./$CHANNEL_DRIVER_NAME"
  ssh $1 "rm ./$CHANNEL_DRIVER_NAME"
  rm ./$CHANNEL_DRIVER_NAME

  sleep $WAIT_SECONDS
}

echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

distribute_channel_driver vm1 Org1MSP nar.blockr
distribute_channel_driver vm2 Org2MSP car.blockr

