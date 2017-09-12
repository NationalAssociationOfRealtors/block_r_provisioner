#!/bin/bash -e

FABRIC=$GOPATH/src/github.com/hyperledger/fabric
WITH_TLS=true

getIP() {
  ssh $1 "/usr/sbin/ip addr | grep 'inet .*global' | cut -f 6 -d ' ' | cut -f1 -d '/' | head -n 1"
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

deployFabric() {
        scp install.sh $1:install.sh
        ssh $1 "bash install.sh"
}

query() {
  ORDERER_TLS=""
  if [ "$WITH_TLS" = true ]; then
    orderer_cert=`pwd`/crypto-config/ordererOrganizations/blockr/orderers/$1.blockr/tls/ca.crt
    ORDERER_TLS="--tls true --cafile ${orderer_cert}"
  fi
  ssh_args='{"Args":["query","a"]}'
  SSH_CMD="${ROOT_TLS} CORE_PEER_MSPCONFIGPATH=${ADMIN_MSP} CORE_PEER_LOCALMSPID=PeerOrg CORE_PEER_ADDRESS=$1:7051 ./peer chaincode query -n exampleCC -v 1.0 -C blockr -c '${ssh_args}' ${ORDERER_TLS}"
  echo $SSH_CMD
  eval "$SSH_CMD" 
}

invoke() {
  ORDERER_TLS=""
  if [ "$WITH_TLS" = true ]; then
    orderer_cert=`pwd`/crypto-config/ordererOrganizations/blockr/orderers/$1.blockr/tls/ca.crt
    ORDERER_TLS="--tls true --cafile ${orderer_cert}"
  fi
  ssh_args='{"Args":["invoke","a","b","10"]}'
  SSH_CMD="${ROOT_TLS} CORE_PEER_MSPCONFIGPATH=${ADMIN_MSP} CORE_PEER_LOCALMSPID=PeerOrg CORE_PEER_ADDRESS=$1:7051 ./peer chaincode invoke -n exampleCC -v 1.0 -C blockr -c '${ssh_args}' -o ${bootPeer}:7050 ${ORDERER_TLS}"
  echo $SSH_CMD
  eval "$SSH_CMD" 
}

[[ -z $GOPATH ]] && (echo "Environment variable GOPATH isn't set!"; exit 1)
[[ -d "$FABRIC" ]] || (echo "Directory $FABRIC doesn't exist!"; exit 1)

#
# copy binaries into this local space
#
for file in configtxgen peer cryptogen; do
  [[ -f $file ]] && continue
  binary=$FABRIC/build/bin/$file
  [[ ! -f $binary ]] && ( cd $FABRIC ; make $file)
  cp $binary $file && continue
done
for file in configtxgen peer cryptogen; do
  [[ ! -f $file ]] && echo "$file isn't found, aborting!" && exit 1
done

#
# read config and set variables
#
. config.sh
bootPeer=$(echo ${nodes} | awk '{print $1}')
ADMIN_MSP=`pwd`/crypto-config/peerOrganizations/blockr/users/Admin@blockr/msp/
ROOT_TLS=""
if [ "$WITH_TLS" = true ]; then
  root_cert=`pwd`/crypto-config/peerOrganizations/blockr/peers/${bootPeer}.blockr/tls/ca.crt
  ROOT_TLS="CORE_PEER_TLS_ROOTCERT_FILE=${root_cert}"
fi

#
# make sure fabric is installed on all servers
#
for p in $nodes; do
  if [ `probeFabric $p` == "1" ];then
    echo "Didn't detect fabric installation on $p, proceeding to install fabric on it"
    deployFabric $p
  fi
done

#
# prepapre configuraton files
#
echo "Preparing configuration..."
rm -rf crypto-config
for p in $nodes ; do
  rm -rf $p
done

PROPAGATEPEERNUM=${PROPAGATEPEERNUM:-3}
i=0
for p in $nodes ; do
  mkdir -p $p/sampleconfig
#  mkdir -p $p/sampleconfig/crypto
#  mkdir -p $p/sampleconfig/tls
  ip=$(getIP $p)
  echo "${p}'s ip address is ${ip}"
  orgLeader=false
  if [[ $i -eq 0 ]];then
    orgLeader=true
  fi
  (( i += 1 ))

  cat core.yml.template | sed "s/PROPAGATEPEERNUM/${PROPAGATEPEERNUM}/ ; s/PEERID/$p/ ; s/ADDRESS/$p/ ; s/ORGLEADER/$orgLeader/ ; s/BOOTSTRAP/$bootPeer:7051/ ; s/WITH_TLS/$WITH_TLS/ " > $p/sampleconfig/core.yaml

  cat orderer.yml.template | sed "s/WITH_TLS/$WITH_TLS/ " > $p/sampleconfig/orderer.yaml

  cat configtx.yml.template | sed "s/ANCHOR_PEER_IP/$bootPeer/ ; s/ORDERER_IP/$p/" > configtx.yaml
  cp configtx.yaml $p/sampleconfig/configtx.yaml

done

rm crypto-config.yaml
cat << EOF >> crypto-config.yaml
################################################################################
#
#  Block R Network Configuration 
#
################################################################################
OrdererOrgs:
  - Name: Org0
    Domain: blockr 
    Specs:
EOF

for p in $nodes ; do
  echo "        - Hostname: $p" >> crypto-config.yaml
done
cat << EOF >> crypto-config.yaml
PeerOrgs:
  - Name: Org1
    Domain: blockr 
    Specs:
EOF
for p in $nodes ; do
  echo "        - Hostname: $p" >> crypto-config.yaml
done
cat << EOF >> crypto-config.yaml
    Users:
      Count: 1
EOF

#
# generate configuraton files
#
echo "Generating configuration..."

./cryptogen generate --config crypto-config.yaml

./configtxgen -profile Channels -outputCreateChannelTx blockr.tx -channelID blockr 
cp blockr.tx $bootPeer/sampleconfig/

./configtxgen -profile Genesis -outputBlock $bootPeer/sampleconfig/genesis.block -channelID system

for p in $nodes ; do
  cp -r crypto-config $p/sampleconfig
#  cp -r crypto-config/peerOrganizations/blockr/peers/$p.blockr/msp/* $p/sampleconfig/crypto
#  cp -r crypto-config/peerOrganizations/blockr/peers/$p.blockr/tls/* $p/sampleconfig/tls/
#  if [ $p = $orderer ]; then
#echo "orderer runs on peer $p, making sure certificates match ..."
#    cp -r crypto-config/peerOrganizations/blockr/peers/$p.blockr/msp/* crypto-config/ordererOrganizations/blockr/orderers/${orderer}.blockr/msp
#    cp -r crypto-config/peerOrganizations/blockr/peers/$p.blockr/tls/* crypto-config/ordererOrganizations/blockr/orderers/${orderer}.blockr/tls
#  fi
#    cp -r crypto-config/peerOrganizations/blockr/peers/$p.blockr/msp/* $orderer/sampleconfig/crypto
#    cp -r crypto-config/peerOrganizations/blockr/peers/$p.blockr/tls/* $orderer/sampleconfig/tls
done
#cp -r crypto-config/ordererOrganizations/blockr/orderers/${orderer}.blockr/msp/* $orderer/sampleconfig/crypto
#cp -r crypto-config/ordererOrganizations/blockr/orderers/${orderer}.blockr/msp/* $orderer/sampleconfig/crypto
#cp -r crypto-config/ordererOrganizations/blockr/orderers/${orderer}.blockr/tls/* $orderer/sampleconfig/tls

#
# Deploy configuration
#
echo "Deploying configuration"

for p in $nodes ; do
  ssh $p "pkill orderer; pkill peer" || echo ""
  ssh $p "rm -rf /var/hyperledger/production/*"
#  SSH_CMD="cd $FABRIC; git reset HEAD --hard && git pull"
#  ssh $p $SSH_CMD 
  scp -r $p/sampleconfig/* $p:$FABRIC/sampleconfig/
done

echo "killing docker containers"
for p in $nodes ; do
  ssh $p "docker ps -aq | xargs docker kill &> /dev/null " || echo -n "."
  ssh $p "docker ps -aq | xargs docker rm &> /dev/null " || echo -n "."
  ssh $p "docker images | grep 'dev-' | awk '{print $3}' | xargs docker rmi &> /dev/null " || echo -n "."
done

#echo "Installing orderer"
#SSH_CMD="bash -c '. ~/.bash_profile; cd $FABRIC; make orderer && make peer'"
#ssh $orderer $SSH_CMD 
#for p in $peers ; do
#  echo "Installing peer $p"
#  SSH_CMD="bash -c '. ~/.bash_profile; cd $FABRIC; make peer' " 
#  ssh $p $SSH_CMD 
#done

echo "Starting orderer on $bootPeer"
#SSH_CMD=" . ~/.bash_profile; cd $FABRIC;  echo 'ORDERER_GENERAL_LOGLEVEL=debug ./build/bin/orderer &> orderer.out &' > start.sh; bash start.sh "
SSH_CMD=" . ~/.bash_profile; cd $FABRIC;  echo './build/bin/orderer &> orderer.out &' > start.sh; bash start.sh "
echo $SSH_CMD
ssh $bootPeer $SSH_CMD 
ORDERER_TLS=""
if [ "$WITH_TLS" = true ]; then
  orderer_cert=`pwd`/crypto-config/ordererOrganizations/blockr/orderers/${bootPeer}.blockr/tls/ca.crt
  ORDERER_TLS="--tls true --cafile ${orderer_cert}"
fi

for p in $nodes ; do
  echo "Starting peer on $p"
  SSH_CMD=" . ~/.bash_profile; cd $FABRIC; echo './build/bin/peer node start &> $p.out &' > start.sh; bash start.sh "
  echo $SSH_CMD
  ssh $p $SSH_CMD 
done

echo "waiting for orderer and peers to be online"
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
  sleep 5
done
sleep 20

#
# creating channel
#
echo "Creating channel"
SSH_CMD="${ROOT_TLS} CORE_PEER_MSPCONFIGPATH=${ADMIN_MSP} CORE_PEER_LOCALMSPID=PeerOrg ./peer channel create -f blockr.tx  -c blockr -o ${bootPeer}:7050 ${ORDERER_TLS}"
echo $SSH_CMD
eval "$SSH_CMD"

for p in $nodes ; do
  echo -n "Joining $p to channel..."
  SSH_CMD="${ROOT_TLS} CORE_PEER_MSPCONFIGPATH=${ADMIN_MSP} CORE_PEER_LOCALMSPID=PeerOrg CORE_PEER_ADDRESS=${p}:7051 ./peer channel join -b blockr.block"
  echo $SSH_CMD
  eval "$SSH_CMD"

  echo -n "Installing chaincode on $p..."
  SSH_CMD="${ROOT_TLS} CORE_PEER_MSPCONFIGPATH=${ADMIN_MSP} CORE_PEER_LOCALMSPID=PeerOrg CORE_PEER_ADDRESS=${p}:7051 ./peer chaincode install -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 -n exampleCC -v 1.0"
  echo $SSH_CMD
  eval "$SSH_CMD"
done

echo "Instantiating chaincode..."
ssh_args='{"Args":["init","a","100","b","200"]}'
SSH_CMD="${ROOT_TLS} CORE_PEER_MSPCONFIGPATH=${ADMIN_MSP} CORE_PEER_LOCALMSPID=PeerOrg CORE_PEER_ADDRESS=${bootPeer}:7051 ./peer chaincode instantiate -n exampleCC -v 1.0 -C blockr -c '${ssh_args}' -o ${bootPeer}:7050 ${ORDERER_TLS}"
echo $SSH_CMD
eval "$SSH_CMD" 

sleep 10

echo "Invoking chaincode..."
for p in $nodes ; do
  query $p
done

exit 1

for i in `seq 5`; do
  invoke ${bootPeer}
done

echo "Waiting for peers $nodes to sync..."
t1=`date +%s`
while :; do
  allInSync=true
  for p in $nodes ; do
    echo "Querying $p..."
    query $p | grep -q 'Query Result: 60'
    if [[ $? -ne 0 ]];then
      allInSync=false
    fi
  done
  if [ "${allInSync}" == "true" ];then
    echo Sync took $(( $(date +%s) - $t1 ))s
    break
  fi
done

