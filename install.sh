#!/bin/bash

CONFIG_DIR="blockr_config"
FABRIC=$GOPATH/src/github.com/hyperledger/fabric
PRODUCTION_DIR=/var/hyperledger

sudo su - $(whoami) - << EOF
if [ -d $PRODUCTION_DIR ]; then
  echo "Production directory $PRODUCTION_DIR already exists, it will be removed"
  rm -rf $PRODUCTION_DIR
fi
echo "Creating Production directory $PRODUCTION_DIR"
sudo mkdir -p $PRODUCTION_DIR 
sudo chown $(whoami):$(whoami) $PRODUCTION_DIR 
if [ -d $FABRIC ]; then
  echo "GO directory $FABRIC already exists, it will be removed"
  rm -rf $FABRIC
fi
mkdir -p $FABRIC
chown -R $(whoami):$(whoami) $FABRIC
git clone https://github.com/hyperledger/fabric $FABRIC
cd $FABRIC
mkdir $CONFIG_DIR
make native 
EOF

#  exit 1
