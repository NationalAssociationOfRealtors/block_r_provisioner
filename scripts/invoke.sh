#!/bin/bash

CHAINCODE_ID='blockrCC -v 1.0'
CONFIG_DIR=blockr_config
FABRIC_PATH=/work/projects/go/src/github.com/hyperledger/fabric
WITH_TLS=true

export FABRIC_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR

. config.sh
. ./scripts/common.sh

LOCAL_INDEX=$(find_index "$HOSTNAME" "$nodes")
LOCAL_DOMAIN=$(parse_lookup "$LOCAL_INDEX" "$domains")

ORDERER_TLS=''
if [ "$WITH_TLS" = true ]; then
  ORDERER_TLS="--tls --cafile $FABRIC_CFG_PATH/ordererOrganizations/$LOCAL_DOMAIN/orderers/$HOSTNAME.$LOCAL_DOMAIN/tls/ca.crt"
fi

$FABRIC_PATH/build/bin/peer chaincode invoke -n $CHAINCODE_ID -C blockr -c '{"Args":["invoke","a","b","10"]}' -o $HOSTNAME:7050 $ORDERER_TLS &> ./result.txt
while read line ; do
  if [[ $line == *"result: status:"* ]]; then
    echo ${line#*result:}
  else
    if [[ $line == *"Error:"* ]]; then
      echo ${line#*Error:}
    fi
  fi
done < ./result.txt
rm ./result.txt

