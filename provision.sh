
export CONFIG_DIR=blockr_config
export SETUP_DRIVER_NAME=prepare_node_driver.sh
export FABRIC_CFG_PATH=./$CONFIG_DIR
export FABRIC_PATH=/work/projects/go/src/github.com/hyperledger/fabric
export PRODUCTION_DIR=/var/hyperledger
export TARGET_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR
export WAIT_SECONDS=5

distribute_conf() {
  echo ""
  echo "----------"
  echo " Distribute configuration to Node $1"
  echo "----------"
  ssh $1 "rm -rf $TARGET_CFG_PATH"
  ssh $1 "mkdir -p $TARGET_CFG_PATH"
  scp -rq $FABRIC_CFG_PATH/* $1:$TARGET_CFG_PATH
}

prepare() {
  echo ""
  echo "----------"
  echo " Preparing Node $1"
  echo "----------"
  echo "Stop running daemons"
  ssh $1 "pkill orderer"
  ssh $1 "pkill peer"
  scp -q ./$SETUP_DRIVER_NAME $1: 
  ssh $1 "chmod 777 $SETUP_DRIVER_NAME"
  ssh $1 "./$SETUP_DRIVER_NAME"
  ssh $1 "rm ./$SETUP_DRIVER_NAME"
}

echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

echo "----------"
echo " Reset local configuration directory $CONFIG_DIR"
echo "----------"
rm -rf ./$CONFIG_DIR
mkdir -p ./$CONFIG_DIR

#
# create the driver script
#
echo '#!/bin/bash' > $SETUP_DRIVER_NAME
echo '' >> $SETUP_DRIVER_NAME
echo '#----------------' >> $SETUP_DRIVER_NAME
echo '#' >> $SETUP_DRIVER_NAME
echo '# Block R Setup Driver' >> $SETUP_DRIVER_NAME
echo '#' >> $SETUP_DRIVER_NAME
echo '#----------------' >> $SETUP_DRIVER_NAME
echo -n 'export TARGET_CFG_PATH=' >> $SETUP_DRIVER_NAME 
echo $TARGET_CFG_PATH >> $SETUP_DRIVER_NAME 
echo -n 'export PRODUCTION_DIR=' >> $SETUP_DRIVER_NAME 
echo $PRODUCTION_DIR >> $SETUP_DRIVER_NAME 
echo '
echo "----------"
echo " Reset configuration $TARGET_CFG_PATH"
echo "----------"
rm -rf $TARGET_CFG_PATH
mkdir -p $TARGET_CFG_PATH
sudo /etc/init.d/couchdb stop
echo "----------"
echo " Reset Production directory $PRODUCTION_DIR"
echo "----------"
if [ -d $PRODUCTION_DIR ]; then
  sudo rm -rf $PRODUCTION_DIR
fi
sudo mkdir -p $PRODUCTION_DIR 
sudo chown $(whoami):$(whoami) $PRODUCTION_DIR 
sudo /etc/init.d/couchdb start
' >> $SETUP_DRIVER_NAME 

prepare vm1
prepare vm2
sleep $WAIT_SECONDS 
rm ./$SETUP_DRIVER_NAME

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

echo "----------"
echo " Generate channel block from $FABRIC_CFG_PATH/configtx.yaml, profile:Channels"
echo "----------"
$FABRIC_PATH/build/bin/configtxgen -profile Channels -outputCreateChannelTx $FABRIC_CFG_PATH/blockr.tx -channelID blockr

echo "----------"
echo " Generate Anchorpeer transactions from $FABRIC_CFG_PATH/configtx.yaml, profile:Channels"
echo "----------"
$FABRIC_PATH/build/bin/configtxgen -profile Channels -outputAnchorPeersUpdate $FABRIC_CFG_PATH/Org1MSPanchors.tx -channelID blockr -asOrg Org1MSP
$FABRIC_PATH/build/bin/configtxgen -profile Channels -outputAnchorPeersUpdate $FABRIC_CFG_PATH/Org2MSPanchors.tx -channelID blockr -asOrg Org2MSP

cp ./templates/core.yaml $FABRIC_CFG_PATH 
cp ./templates/orderer.yaml $FABRIC_CFG_PATH 
distribute_conf vm1
distribute_conf vm2
sleep $WAIT_SECONDS 

