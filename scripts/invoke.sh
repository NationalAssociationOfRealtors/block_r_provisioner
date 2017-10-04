
export CONFIG_DIR=blockr_config
export FABRIC_PATH=/work/projects/go/src/github.com/hyperledger/fabric
export FABRIC_CFG_PATH=$FABRIC_PATH/$CONFIG_DIR
export CORE_PEER_ADDRESS=vm1:7051
export CORE_PEER_LOCALMSPID=Org1MSP
export CORE_PEER_MSPCONFIGPATH=$FABRIC_CFG_PATH/peerOrganizations/nar.blockr/users/Admin@nar.blockr/msp/

$FABRIC_PATH/build/bin/peer chaincode invoke -n exampleCC -v 1.0 -C blockr -c '{"Args":["invoke","a","b","10"]}' -o vm1:7050

