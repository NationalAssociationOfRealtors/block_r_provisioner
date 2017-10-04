
export CHAINCODE_ID='exampleCC -v 1.0'
export CHAINCODE_PATH='github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02'
export CONFIG_DIR=blockr_config
export FABRIC_PATH=/work/projects/go/src/github.com/hyperledger/fabric
export FABRIC_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR
export GOPATH=/work/projects/go 
export INSTALL_DRIVER_NAME=install_chaincode_driver.sh
export INSTANTIATE_DRIVER_NAME=instantiate_chaincode_driver.sh
export WAIT_SECONDS=5

distribute_chaincode_install_driver() {
  echo ""
  echo "----------"
  echo " Install chaincode on Node $1"
  echo "----------"

#
# create the driver script
#
  echo '#!/bin/bash' > $INSTALL_DRIVER_NAME
  echo '' >> $INSTALL_DRIVER_NAME
  echo '#----------------' >> $INSTALL_DRIVER_NAME
  echo '#' >> $INSTALL_DRIVER_NAME
  echo '# Block R Chaincode Driver' >> $INSTALL_DRIVER_NAME
  echo '#' >> $INSTALL_DRIVER_NAME
  echo '#----------------' >> $INSTALL_DRIVER_NAME
  echo -n 'export FABRIC_PATH=' >> $INSTALL_DRIVER_NAME
  echo $FABRIC_PATH >> $INSTALL_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $INSTALL_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $INSTALL_DRIVER_NAME
  echo -n 'export CORE_PEER_ADDRESS=' >> $INSTALL_DRIVER_NAME
  echo -n $1 >> $INSTALL_DRIVER_NAME
  echo ':7051' >> $INSTALL_DRIVER_NAME
  echo -n 'export CORE_PEER_LOCALMSPID=' >> $INSTALL_DRIVER_NAME
  echo $2 >> $INSTALL_DRIVER_NAME
  echo -n 'export CORE_PEER_MSPCONFIGPATH=' >> $INSTALL_DRIVER_NAME
  echo -n $FABRIC_CFG_PATH >> $INSTALL_DRIVER_NAME
  echo -n '/peerOrganizations/' >> $INSTALL_DRIVER_NAME
  echo -n $3 >> $INSTALL_DRIVER_NAME
  echo -n '/users/Admin@' >> $INSTALL_DRIVER_NAME
  echo -n $3 >> $INSTALL_DRIVER_NAME
  echo '/msp/' >> $INSTALL_DRIVER_NAME
  echo -n 'export GOPATH=' >> $INSTALL_DRIVER_NAME
  echo $GOPATH >> $INSTALL_DRIVER_NAME
  echo -n '$FABRIC_PATH/build/bin/peer chaincode install -n ' >> $INSTALL_DRIVER_NAME
  echo -n $CHAINCODE_ID >> $INSTALL_DRIVER_NAME
  echo -n ' -p ' >> $INSTALL_DRIVER_NAME
  echo -n $CHAINCODE_PATH >> $INSTALL_DRIVER_NAME
  echo -n ' -o ' >> $INSTALL_DRIVER_NAME
  echo -n $1 >> $INSTALL_DRIVER_NAME
  echo ':7050' >> $INSTALL_DRIVER_NAME

#
# remotely execute the driver script
#
  scp -q ./$INSTALL_DRIVER_NAME $1:
  ssh $1 "chmod 777 $INSTALL_DRIVER_NAME"
  ssh $1 "./$INSTALL_DRIVER_NAME"
  ssh $1 "rm ./$INSTALL_DRIVER_NAME"
  rm ./$INSTALL_DRIVER_NAME
}

distribute_chaincode_instantiate_driver() {
  echo ""
  echo "----------"
  echo " Instantiate the chaincode from Node $1"
  echo "----------"

#
# create the driver script
#
  export CHAINCODE_ARGS='{"Args":["init","a","100","b","200"]}'
  echo '#!/bin/bash' > $INSTANTIATE_DRIVER_NAME
  echo '' >> $INSTANTIATE_DRIVER_NAME
  echo '#----------------' >> $INSTANTIATE_DRIVER_NAME
  echo '#' >> $INSTANTIATE_DRIVER_NAME
  echo '# Block R Chaincode Driver' >> $INSTANTIATE_DRIVER_NAME
  echo '#' >> $INSTANTIATE_DRIVER_NAME
  echo '#----------------' >> $INSTANTIATE_DRIVER_NAME
  echo -n 'export FABRIC_PATH=' >> $INSTANTIATE_DRIVER_NAME
  echo $FABRIC_PATH >> $INSTANTIATE_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $INSTANTIATE_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $INSTANTIATE_DRIVER_NAME
  echo -n 'export CORE_PEER_ADDRESS=' >> $INSTANTIATE_DRIVER_NAME
  echo -n $1 >> $INSTANTIATE_DRIVER_NAME
  echo ':7051' >> $INSTANTIATE_DRIVER_NAME
  echo -n 'export CORE_PEER_LOCALMSPID=' >> $INSTANTIATE_DRIVER_NAME
  echo $2 >> $INSTANTIATE_DRIVER_NAME
  echo -n 'export CORE_PEER_MSPCONFIGPATH=' >> $INSTANTIATE_DRIVER_NAME
  echo -n $FABRIC_CFG_PATH >> $INSTANTIATE_DRIVER_NAME
  echo -n '/peerOrganizations/' >> $INSTANTIATE_DRIVER_NAME
  echo -n $3 >> $INSTANTIATE_DRIVER_NAME
  echo -n '/users/Admin@' >> $INSTANTIATE_DRIVER_NAME
  echo -n $3 >> $INSTANTIATE_DRIVER_NAME
  echo '/msp/' >> $INSTANTIATE_DRIVER_NAME
  echo -n 'export GOPATH=' >> $INSTANTIATE_DRIVER_NAME
  echo $GOPATH >> $INSTANTIATE_DRIVER_NAME
  echo -n '$FABRIC_PATH/build/bin/peer chaincode instantiate -n ' >> $INSTANTIATE_DRIVER_NAME
  echo -n $CHAINCODE_ID >> $INSTANTIATE_DRIVER_NAME
  echo -n " -C blockr -c '" >> $INSTANTIATE_DRIVER_NAME
  echo -n $CHAINCODE_ARGS >> $INSTANTIATE_DRIVER_NAME
  echo -n "' -o " >> $INSTANTIATE_DRIVER_NAME
  echo -n $1 >> $INSTANTIATE_DRIVER_NAME
  echo ':7050' >> $INSTANTIATE_DRIVER_NAME

#
# remotely execute the driver script
#
  scp -q ./$INSTANTIATE_DRIVER_NAME $1:
  ssh $1 "chmod 777 $INSTANTIATE_DRIVER_NAME"
  ssh $1 "./$INSTANTIATE_DRIVER_NAME"
  ssh $1 "rm ./$INSTANTIATE_DRIVER_NAME"
  rm ./$INSTANTIATE_DRIVER_NAME
}

echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

distribute_chaincode_install_driver vm1 Org1MSP nar.blockr
distribute_chaincode_install_driver vm2 Org2MSP car.blockr
sleep $WAIT_SECONDS 

distribute_chaincode_instantiate_driver vm1 Org1MSP nar.blockr
sleep $WAIT_SECONDS 

