
export CONFIG_DIR=blockr_config
export CORE_PEER_ADDRESS=vm1:7051 
export CORE_PEER_LOCALMSPID=Org1MSP 
export FABRIC_PATH=/work/projects/go/src/github.com/hyperledger/fabric
export FABRIC_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR
export CORE_PEER_MSPCONFIGPATH=$FABRIC_CFG_PATH/peerOrganizations/nar.blockr/users/Admin@nar.blockr/msp/ 
export ORDERER_DRIVER_NAME=start_orderer_driver.sh
export PEER_DRIVER_NAME=start_peer_driver.sh
export WAIT_SECONDS=5

start_node_driver() {
  echo "----------"
  echo " Start Node $1"
  echo "----------"

  echo '#!/bin/bash' > $PEER_DRIVER_NAME
  echo '' >> $PEER_DRIVER_NAME
  echo -n 'export FABRIC_PATH=' >> $PEER_DRIVER_NAME
  echo $FABRIC_PATH >> $PEER_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $PEER_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $PEER_DRIVER_NAME
  echo 'export CORE_LOGGING_LEVEL=debug' >> $PEER_DRIVER_NAME
  echo -n 'export CORE_PEER_ADDRESS=' >> $PEER_DRIVER_NAME
  echo -n $1 >> $PEER_DRIVER_NAME
  echo ':7051' >> $PEER_DRIVER_NAME
  echo -n 'export CORE_PEER_GOSSIP_BOOTSTRAP=' >> $PEER_DRIVER_NAME
  echo -n $1 >> $PEER_DRIVER_NAME
  echo ':7051' >> $PEER_DRIVER_NAME
  echo 'export CORE_PEER_GOSSIP_ORGLEADER=true' >> $PEER_DRIVER_NAME
  echo 'export CORE_PEER_GOSSIP_USELEADERELECTION=false' >> $PEER_DRIVER_NAME
  echo -n 'export CORE_PEER_ID=' >> $PEER_DRIVER_NAME
  echo $1 >> $PEER_DRIVER_NAME
  echo -n 'export CORE_PEER_LOCALMSPID=' >> $PEER_DRIVER_NAME
  echo $2 >> $PEER_DRIVER_NAME
  echo -n 'export CORE_PEER_MSPCONFIGPATH=' >> $PEER_DRIVER_NAME
  echo -n $FABRIC_CFG_PATH >> $PEER_DRIVER_NAME
  echo -n '/peerOrganizations/' >> $PEER_DRIVER_NAME
  echo -n $3 >> $PEER_DRIVER_NAME
  echo -n '/peers/' >> $PEER_DRIVER_NAME
  echo -n $1 >> $PEER_DRIVER_NAME
  echo -n '.' >> $PEER_DRIVER_NAME
  echo -n $3 >> $PEER_DRIVER_NAME
  echo '/msp/' >> $PEER_DRIVER_NAME
  echo -n '$FABRIC_PATH/build/bin/peer node start &> $FABRIC_PATH/' >> $PEER_DRIVER_NAME
  echo -n $1 >> $PEER_DRIVER_NAME
  echo '_peer.out &' >> $PEER_DRIVER_NAME
  scp -q ./$PEER_DRIVER_NAME $1:
  ssh $1 "chmod 777 $PEER_DRIVER_NAME"
  ssh $1 "./$PEER_DRIVER_NAME"
  ssh $1 "rm ./$PEER_DRIVER_NAME"
  rm ./$PEER_DRIVER_NAME

  echo '#!/bin/bash' > $ORDERER_DRIVER_NAME
  echo '' >> $ORDERER_DRIVER_NAME
  echo '#----------------' >> $ORDERER_DRIVER_NAME
  echo '#' >> $ORDERER_DRIVER_NAME
  echo '# Block R Orderer Start Driver' >> $ORDERER_DRIVER_NAME
  echo '#' >> $ORDERER_DRIVER_NAME
  echo '#----------------' >> $ORDERER_DRIVER_NAME
  echo -n 'export FABRIC_PATH=' >> $ORDERER_DRIVER_NAME
  echo $FABRIC_PATH >> $ORDERER_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $ORDERER_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $ORDERER_DRIVER_NAME
  echo -n 'export ORDERER_GENERAL_LOCALMSPDIR=' >> $ORDERER_DRIVER_NAME
  echo -n 'ordererOrganizations/' >> $ORDERER_DRIVER_NAME
  echo -n $3 >> $ORDERER_DRIVER_NAME
  echo -n '/orderers/' >> $ORDERER_DRIVER_NAME
  echo -n $1 >> $ORDERER_DRIVER_NAME
  echo -n '.' >> $ORDERER_DRIVER_NAME
  echo -n $3 >> $ORDERER_DRIVER_NAME
  echo '/msp' >> $ORDERER_DRIVER_NAME
  echo -n 'export ORDERER_GENERAL_LOCALMSPID=' >> $ORDERER_DRIVER_NAME
  echo $2 >> $ORDERER_DRIVER_NAME
  echo -n '$FABRIC_PATH/build/bin/orderer &> $FABRIC_PATH/' >> $ORDERER_DRIVER_NAME
  echo -n $1 >> $ORDERER_DRIVER_NAME
  echo '_orderer.out &' >> $ORDERER_DRIVER_NAME
  scp -q ./$ORDERER_DRIVER_NAME $1:
  ssh $1 "chmod 777 $ORDERER_DRIVER_NAME"
  ssh $1 "./$ORDERER_DRIVER_NAME"
  ssh $1 "rm ./$ORDERER_DRIVER_NAME"
  rm ./$ORDERER_DRIVER_NAME

  sleep $WAIT_SECONDS
}


echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

start_node_driver vm1 Org1MSP nar.blockr
start_node_driver vm2 Org2MSP car.blockr
