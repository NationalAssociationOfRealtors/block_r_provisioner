#!/bin/bash

CONFIG_DIR=blockr_config
FABRIC_PATH=/work/projects/go/src/github.com/hyperledger/fabric
WITH_TLS=true

export FABRIC_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR

ORDERER_TLS=''
if [ "$WITH_TLS" = true ]; then
  ORDERER_TLS="--tls --cafile $FABRIC_CFG_PATH/ordererOrganizations/nar.blockr/orderers/vm1.nar.blockr/tls/ca.crt"
fi

$FABRIC_PATH/build/bin/peer chaincode query -n exampleCC -v 1.0 -C blockr -c '{"Args":["query","a"]}' -o vm1:7050 $ORDERER_TLS &> ./result.txt
while read line ; do
  if [[ $line == *"Query Result:"* ]]; then
echo "$line"
  else
    if [[ $line == *"Error:"* ]]; then
      echo ${line#*Error:}
    fi
  fi
done < ./result.txt 
rm result.txt

