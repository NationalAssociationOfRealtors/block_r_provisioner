#!/bin/bash -e

echo ".----------"
echo "|"
echo "|  Block R Network Provisoner"
echo "|  Association Engagement Tracker"
echo "|"
echo "'----------"

CONFIG_DIR=blockr_config
DEBUG=true
FABRIC=$GOPATH/src/github.com/hyperledger/fabric
GOPATH=/work/projects/go
PRODUCTION_DIR=/var/hyperledger
SYNC_WAIT=5
WITH_TLS=true

deployFabric() {
  sendLocal "scp install.sh $1:install.sh"
  sendSSH $1 "bash install.sh"
}

getIP() {
  ssh $1 "/usr/sbin/ip addr | grep 'inet .*global' | cut -f 6 -d ' ' | cut -f1 -d '/' | head -n 1"
}

invoke() {
  NODE_ROOT_TLS=""
  ORDERER_TLS=""
  if [ "$WITH_TLS" = true ]; then
    NODE_ROOT_TLS="CORE_PEER_TLS_ROOTCERT_FILE=$FABRIC/$CONFIG_DIR/peerOrganizations/blockr/peers/$1.blockr/tls/ca.crt"
    ORDERER_TLS="--tls true --cafile $FABRIC/$CONFIG_DIR/ordererOrganizations/blockr/orderers/$1.blockr/tls/ca.crt"
  fi
  ssh_args='{"Args":["invoke","a","b","10"]}'
  sendSSH $1 "$NODE_ROOT_TLS FABRIC_CFG_PATH=$FABRIC/$CONFIG_DIR CORE_PEER_MSPCONFIGPATH=$NODE_ADMIN_MSP CORE_PEER_LOCALMSPID=PeerOrg CORE_PEER_ADDRESS=$1:7051 $FABRIC/build/bin/peer chaincode invoke -n exampleCC -v 1.0 -C blockr -c '$ssh_args' -o $1:7050 $ORDERER_TLS"
}

probePeerOrOrderer() {
  echo "" | nc $1 7050 && return 0
  echo "" | nc $1 7051 && return 0
  return 1
}

probeFabric() {
  ssh $1 "ls $FABRIC &> /dev/null || echo 'not found'" | grep -q "not found"
  if [ $? -eq 0 ];then
    echo "1"
    return
  fi
  echo "0"
}

query() {
  NODE_ROOT_TLS=""
  ORDERER_TLS=""
  if [ "$WITH_TLS" = true ]; then
    NODE_ROOT_TLS="CORE_PEER_TLS_ROOTCERT_FILE=$FABRIC/$CONFIG_DIR/peerOrganizations/blockr/peers/$1.blockr/tls/ca.crt"
    ORDERER_TLS="--tls true --cafile $FABRIC/$CONFIG_DIR/ordererOrganizations/blockr/orderers/$1.blockr/tls/ca.crt"
  fi
  ssh_args='{"Args":["query","a"]}'
  sendSSH $1 "$NODE_ROOT_TLS FABRIC_CFG_PATH=$FABRIC/$CONFIG_DIR CORE_PEER_MSPCONFIGPATH=$NODE_ADMIN_MSP CORE_PEER_LOCALMSPID=PeerOrg CORE_PEER_ADDRESS=$1:7051 $FABRIC/build/bin/peer chaincode query -n exampleCC -v 1.0 -C blockr -c '$ssh_args' $ORDERER_TLS"
}

sendLocal() {
  if [ "$DEBUG" = true ]; then
    echo "==> $1"
  fi
  eval $1
}

sendSSH() {
  if [ "$DEBUG" = true ]; then
    echo "==> $2"
  fi
  ssh $1 $2
}

userFeedback() {
echo ""
echo ".----------"
echo "|  $1"
echo "'----------"
}

[[ -z $GOPATH ]] && (echo "Environment variable GOPATH isn't set!"; exit 1)
[[ -d "$FABRIC" ]] || (echo "Directory $FABRIC doesn't exist!"; exit 1)

#
# read config and set variables
#
userFeedback "Read config.sh to determine which servers to provision"
. config.sh
bootPeer=$(echo ${nodes} | awk '{print $1}')
NODE_ADMIN_MSP=$FABRIC/$CONFIG_DIR/peerOrganizations/blockr/users/Admin@blockr/msp/

#
# make sure fabric is installed on all servers
#
userFeedback "Ensure Hyperledger Fabric is installed on each node"
for p in $nodes; do
  if [ `probeFabric $p` == "1" ];then
    echo "Didn't detect fabric installation on $p, proceeding to install fabric on it"
    deployFabric $p
  fi
done

#
# prepare configuraton files
#
userFeedback "Create configuraton files for the network"
sendLocal "rm -rf $CONFIG_DIR" 
for p in $nodes ; do
  sendLocal "rm -rf $p"
done

PROPAGATEPEERNUM=${PROPAGATEPEERNUM:-3}
i=0
for p in $nodes ; do
  mkdir -p $p/$CONFIG_DIR
  ip=$(getIP $p)
  echo "${p}'s ip address is ${ip}"
  orgLeader=false
  if [[ $i -eq 0 ]];then
    orgLeader=true
  fi
  (( i += 1 ))

  PEER_MSP_ROOT="peerOrganizations/blockr/peers/$p.blockr"
  cat core.yml.template | sed "s|PROPAGATEPEERNUM|${PROPAGATEPEERNUM}| ; s|PEERID|$p| ; s|ADDRESS|$p| ; s|ORGLEADER|$orgLeader| ; s|BOOTSTRAP|$bootPeer:7051| ; s|WITH_TLS|$WITH_TLS| ; s|PEER_MSP_ROOT|$PEER_MSP_ROOT| " > $p/$CONFIG_DIR/core.yaml

  ORDERER_MSP_ROOT="ordererOrganizations/blockr/orderers/$bootPeer.blockr"
  cat orderer.yml.template | sed "s:WITH_TLS:$WITH_TLS: ; s:ORDERER_MSP_ROOT:$ORDERER_MSP_ROOT: " > $p/$CONFIG_DIR/orderer.yaml

  cat configtx.yml.template | sed "s:ANCHOR_PEER_IP:$bootPeer: ; s:ORDERER_IP:$p: ; s:ORDERER_MSP_ROOT:$ORDERER_MSP_ROOT: ; s:PEER_MSP_ROOT:$PEER_MSP_ROOT: " > configtx.yaml

done

if [ -f "blockr-config.yaml" ];then
  rm blockr-config.yaml
fi
cat << EOF >> blockr-config.yaml
################################################################################
#
#  Block R Network Configuration generated from config.sh 
#
################################################################################
OrdererOrgs:
  - Name: Org0
    Domain: blockr 
    Specs:
EOF

for p in $nodes ; do
  echo "        - Hostname: $p" >> blockr-config.yaml
done
cat << EOF >> blockr-config.yaml
PeerOrgs:
  - Name: Org1
    Domain: blockr 
    Specs:
EOF
for p in $nodes ; do
  echo "        - Hostname: $p" >> blockr-config.yaml
done
cat << EOF >> blockr-config.yaml
    Users:
      Count: 1
EOF

sendLocal "cat blockr-config.yaml"

#
# generate configuraton
#
userFeedback "Generate encryption keys"
sendLocal "$FABRIC/build/bin/cryptogen generate --config blockr-config.yaml --output $CONFIG_DIR"
sendLocal "mv configtx.yaml $CONFIG_DIR; mv blockr-config.yaml $CONFIG_DIR"

userFeedback "Generate 'blockr' channel definition"
sendLocal "FABRIC_CFG_PATH=./$CONFIG_DIR $FABRIC/build/bin/configtxgen -profile Channels -outputCreateChannelTx $CONFIG_DIR/blockr.tx -channelID blockr" 

userFeedback "Create genesis block"
sendLocal "FABRIC_CFG_PATH=./$CONFIG_DIR $FABRIC/build/bin/configtxgen -profile Genesis -outputBlock $CONFIG_DIR/genesis.block -channelID system"

for p in $nodes ; do
  userFeedback "Reset enviroment on $p"
  echo "Stop peer and orderer daemons"
  sendSSH $p "pkill orderer; pkill peer" || echo -n ""

  if [ -d $PRODUCTION_DIR ]; then
    echo "Removing production directories under $PRODUCTION_DIR"
    sendSSH $p "rm -rf $PRODUCTION_DIR/production/*"
  else
    echo "Creating production directory $PRODUCTION_DIR"
    sendSSH $p "sudo mkdir -p $PRODUCTION_DIR; sudo chown $(whoami):$(whoami) $PRODUCTION_DIR; mkdir -p $PRODUCTION_DIR/production; chown $(whoami):$(whoami) $PRODUCTION_DIR/production" 
  fi

#  SSH_CMD="cd $FABRIC; git reset HEAD --hard && git pull"

  userFeedback "Deploy configuration $CONFOG_DIR on node $p"
  sendLocal "cp -r $CONFIG_DIR $p; scp -rq $p/$CONFIG_DIR/* $p:$FABRIC/$CONFIG_DIR"

  userFeedback "Stop any running Docker containers on $p"
  sendSSH $p "docker ps -aq | xargs docker kill &> /dev/null" || echo -n "" 
  sendSSH $p "docker ps -aq | xargs docker rm &> /dev/null" || echo -n "" 
  sendSSH $p "docker images | grep 'dev-' | awk '{print $3}' | xargs docker rmi &> /dev/null" || echo -n "" 

  userFeedback "Start orderer on $p"
  sendSSH $p "echo 'FABRIC_CFG_PATH=$FABRIC/$CONFIG_DIR $FABRIC/build/bin/orderer &> $FABRIC/orderer.out &' > start.sh; bash start.sh "

  userFeedback "Start peer on $p"
  sendSSH $p "echo 'FABRIC_CFG_PATH=$FABRIC/$CONFIG_DIR $FABRIC/build/bin/peer node start &> $FABRIC/$p.out &' > start.sh; bash start.sh "

done

userFeedback "Waiting for all nodes to start up"
while :; do
  allOnline=true
  for p in $nodes; do
    if [[ `probePeerOrOrderer $p` -ne 0 ]];then
      echo "$p isn't online yet"
      allOnline=false
      break;
    fi
  done
  if [ "${allOnline}" == "true" ];then
    break;
  fi
  sleep $SYNC_WAIT 
done
sleep $SYNC_WAIT 

#
# creating channel
#
BOOT_NODE_ROOT_TLS=""
BOOT_ORDERER_TLS=""
if [ "$WITH_TLS" = true ]; then
  BOOT_NODE_ROOT_TLS="CORE_PEER_TLS_ROOTCERT_FILE=$FABRIC/$CONFIG_DIR/peerOrganizations/blockr/peers/$bootPeer.blockr/tls/ca.crt"
  BOOT_ORDERER_TLS="--tls true --cafile $FABRIC/$CONFIG_DIR/ordererOrganizations/blockr/orderers/$bootPeer.blockr/tls/ca.crt"
fi

userFeedback "Creating a channel from one node (using the bootPeer $bootPeer)"
sendSSH $bootPeer "$BOOT_NODE_ROOT_TLS FABRIC_CFG_PATH=$FABRIC/$CONFIG_DIR CORE_PEER_MSPCONFIGPATH=$NODE_ADMIN_MSP CORE_PEER_LOCALMSPID=PeerOrg $FABRIC/build/bin/peer channel create -f $FABRIC/$CONFIG_DIR/blockr.tx  -c blockr -o $bootPeer:7050 $BOOT_ORDERER_TLS"

for p in $nodes ; do
  NODE_ROOT_TLS=""
  ORDERER_TLS=""
  if [ "$WITH_TLS" = true ]; then
    NODE_ROOT_TLS="CORE_PEER_TLS_ROOTCERT_FILE=$FABRIC/$CONFIG_DIR/peerOrganizations/blockr/peers/$p.blockr/tls/ca.crt"
    ORDERER_TLS="--tls true --cafile $FABRIC/$CONFIG_DIR/ordererOrganizations/blockr/orderers/$p.blockr/tls/ca.crt"
  fi
  userFeedback "Joining peer $p to the channel"
  sendSSH $p "$NODE_ROOT_TLS FABRIC_CFG_PATH=$FABRIC/$CONFIG_DIR  CORE_PEER_MSPCONFIGPATH=$NODE_ADMIN_MSP CORE_PEER_LOCALMSPID=PeerOrg CORE_PEER_ADDRESS=$p:7051 $FABRIC/build/bin/peer channel join -b blockr.block"

  userFeedback "Install chaincode into peer on $p"
  sendSSH $p "$NODE_ROOT_TLS FABRIC_CFG_PATH=$FABRIC/$CONFIG_DIR  CORE_PEER_MSPCONFIGPATH=$NODE_ADMIN_MSP CORE_PEER_LOCALMSPID=PeerOrg CORE_PEER_ADDRESS=$p:7051 GOPATH=$GOPATH $FABRIC/build/bin/peer chaincode install -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 -n exampleCC -v 1.0"

done

userFeedback "Instantiate chaincode from one node (using the bootPeer $bootPeer)"
t1=`date +%s`
ssh_args='{"Args":["init","a","100","b","200"]}'
sendSSH $bootPeer "$BOOT_NODE_ROOT_TLS FABRIC_CFG_PATH=$FABRIC/$CONFIG_DIR CORE_PEER_MSPCONFIGPATH=$NODE_ADMIN_MSP CORE_PEER_LOCALMSPID=PeerOrg CORE_PEER_ADDRESS=$bootPeer:7051 $FABRIC/build/bin/peer chaincode instantiate -n exampleCC -v 1.0 -C blockr -c '${ssh_args}' -o $bootPeer:7050 $BOOT_ORDERER_TLS"
echo ".=========="
echo "|  Commit took $(( $(date +%s) - $t1 ))s"
echo "'=========="

for p in $nodes ; do
  userFeedback "Querying chaincode on node $p"
  query $p
done

userFeedback "Invoking chaincode five times"
for i in `seq 5`; do
  invoke $bootPeer
done

userFeedback "Waiting for nodes to synchronize"
t1=`date +%s`
while :; do
  allInSync=true
  for p in $nodes ; do
#    echo "Querying $p..."
    query $p | grep -q 'Query Result: 50'
    if [[ $? -ne 0 ]];then
      allInSync=false
    fi
  done
  if [ "${allInSync}" == "true" ];then
    echo "Sync took $(( $(date +%s) - $t1 ))s"
    break
  fi
done

