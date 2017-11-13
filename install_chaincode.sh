#!/bin/bash

CHAINCODE_ID='blockrCC -v 1.0'
CONFIG_DIR=blockr_config
DEBUG=false
FABRIC_PATH=$GOPATH/src/github.com/hyperledger/fabric
FABRIC_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR
INSTALL_DRIVER_NAME=install_chaincode_driver.sh
INSTANTIATE_DRIVER_NAME=instantiate_chaincode_driver.sh
WITH_TLS=true

CHAINCODE_PATH="github.com/hyperledger/fabric/$CONFIG_DIR"

distribute_chaincode_install() {
  echo "----------"
  echo " Install chaincode on Node $1"
  echo "----------"

  ORDERER_TLS=''
  if [ "$WITH_TLS" = true ]; then
    ORDERER_TLS="--tls --cafile $FABRIC_CFG_PATH/ordererOrganizations/$2/orderers/$1.$2/tls/ca.crt"
  fi

  driver_header $INSTALL_DRIVER_NAME 'Block R Install Chaincode Driver'

  echo -n 'export FABRIC_PATH=' >> $INSTALL_DRIVER_NAME
  echo $FABRIC_PATH >> $INSTALL_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $INSTALL_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $INSTALL_DRIVER_NAME
  echo -n 'export CORE_PEER_MSPCONFIGPATH=' >> $INSTALL_DRIVER_NAME
  echo -n $FABRIC_CFG_PATH >> $INSTALL_DRIVER_NAME
  echo -n '/peerOrganizations/' >> $INSTALL_DRIVER_NAME
  echo -n $2 >> $INSTALL_DRIVER_NAME
  echo -n '/users/Admin@' >> $INSTALL_DRIVER_NAME
  echo -n $2 >> $INSTALL_DRIVER_NAME
  echo '/msp' >> $INSTALL_DRIVER_NAME
  echo -n 'export GOPATH=' >> $INSTALL_DRIVER_NAME
  echo $GOPATH >> $INSTALL_DRIVER_NAME
  echo -n 'export ORDERER_TLS="' >> $INSTALL_DRIVER_NAME
  echo -n $ORDERER_TLS >> $INSTALL_DRIVER_NAME
  echo '"' >> $INSTALL_DRIVER_NAME
  echo -n '$FABRIC_PATH/build/bin/peer chaincode install -n ' >> $INSTALL_DRIVER_NAME
  echo -n $CHAINCODE_ID >> $INSTALL_DRIVER_NAME
  echo -n ' -p ' >> $INSTALL_DRIVER_NAME
  echo -n $CHAINCODE_PATH >> $INSTALL_DRIVER_NAME
  echo -n ' -o ' >> $INSTALL_DRIVER_NAME
  echo -n $1 >> $INSTALL_DRIVER_NAME
  if [ "$DEBUG" != true ]; then
    echo ':7050 $ORDERER_TLS &> /dev/null' >> $INSTALL_DRIVER_NAME
  else
    echo ':7050 $ORDERER_TLS' >> $INSTALL_DRIVER_NAME
  fi

  run_driver $INSTALL_DRIVER_NAME $1
}

distribute_chaincode_instantiate() {
  echo "----------"
  echo " Instantiate the chaincode from Node $1"
  echo "----------"

  ORDERER_TLS=''
  if [ "$WITH_TLS" = true ]; then
    ORDERER_TLS="--tls --cafile $FABRIC_CFG_PATH/ordererOrganizations/$2/orderers/$1.$2/tls/ca.crt"
  fi
  export CHAINCODE_ARGS='{"Args":["init","a","100","b","200"]}'
  export CHAINCODE_POLICY="OR('Org1.member', 'Org2.member')"

  driver_header $INSTANTIATE_DRIVER_NAME 'Block R Instantiate Chaincode Driver'

  echo -n 'export FABRIC_PATH=' >> $INSTANTIATE_DRIVER_NAME
  echo $FABRIC_PATH >> $INSTANTIATE_DRIVER_NAME
  echo -n 'export FABRIC_CFG_PATH=' >> $INSTANTIATE_DRIVER_NAME
  echo $FABRIC_CFG_PATH >> $INSTANTIATE_DRIVER_NAME
  echo -n 'export CORE_PEER_MSPCONFIGPATH=' >> $INSTANTIATE_DRIVER_NAME
  echo -n $FABRIC_CFG_PATH >> $INSTANTIATE_DRIVER_NAME
  echo -n '/peerOrganizations/' >> $INSTANTIATE_DRIVER_NAME
  echo -n $2 >> $INSTANTIATE_DRIVER_NAME
  echo -n '/users/Admin@' >> $INSTANTIATE_DRIVER_NAME
  echo -n $2 >> $INSTANTIATE_DRIVER_NAME
  echo '/msp/' >> $INSTANTIATE_DRIVER_NAME
  echo -n 'export GOPATH=' >> $INSTANTIATE_DRIVER_NAME
  echo $GOPATH >> $INSTANTIATE_DRIVER_NAME
  echo -n 'export ORDERER_TLS="' >> $INSTANTIATE_DRIVER_NAME
  echo -n $ORDERER_TLS >> $INSTANTIATE_DRIVER_NAME
  echo '"' >> $INSTANTIATE_DRIVER_NAME
  echo -n '$FABRIC_PATH/build/bin/peer chaincode instantiate -n ' >> $INSTANTIATE_DRIVER_NAME
  echo -n $CHAINCODE_ID >> $INSTANTIATE_DRIVER_NAME
  echo -n " -C blockr -c '" >> $INSTANTIATE_DRIVER_NAME
  echo -n $CHAINCODE_ARGS >> $INSTANTIATE_DRIVER_NAME
  echo -n "' " >> $INSTANTIATE_DRIVER_NAME

#  echo -n "-P " >> $INSTANTIATE_DRIVER_NAME
#  echo -n '"' >> $INSTANTIATE_DRIVER_NAME
#  echo -n $CHAINCODE_POLICY >> $INSTANTIATE_DRIVER_NAME
#  echo -n '" ' >> $INSTANTIATE_DRIVER_NAME

  echo -n '-o ' >> $INSTANTIATE_DRIVER_NAME
  echo -n $1 >> $INSTANTIATE_DRIVER_NAME
  if [ "$DEBUG" != true ]; then
    echo ':7050 $ORDERER_TLS &>/dev/null' >> $INSTANTIATE_DRIVER_NAME
  else 
    echo ':7050 $ORDERER_TLS' >> $INSTANTIATE_DRIVER_NAME
  fi

  run_driver $INSTANTIATE_DRIVER_NAME $1
}

echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"


. config.sh
. ./scripts/common.sh

#
#  distribute chaincode 
#
COUNTER=0
while [  $COUNTER -lt $node_count ]; do
  let COUNTER=COUNTER+1
  distribute_chaincode_install $(parse_lookup "$COUNTER" "$nodes") $(parse_lookup "$COUNTER" "$domains")
done

#
# instantiate chaincode 
#
distribute_chaincode_instantiate $(parse_lookup 1 "$nodes") $(parse_lookup 1 "$domains")


