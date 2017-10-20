
export CONFIG_DIR=blockr_config
export FABRIC_PATH=/work/projects/go/src/github.com/hyperledger/fabric
export FABRIC_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR
export WITH_TLS=true

ORDERER_TLS=''
if [ "$WITH_TLS" = true ]; then
  ORDERER_TLS="--tls --cafile $FABRIC_CFG_PATH/ordererOrganizations/nar.blockr/orderers/vm1.nar.blockr/tls/ca.crt"
fi

$FABRIC_PATH/build/bin/peer chaincode invoke -n exampleCC -v 1.0 -C blockr -c '{"Args":["invoke","a","b","10"]}' -o vm1:7050 $ORDERER_TLS

