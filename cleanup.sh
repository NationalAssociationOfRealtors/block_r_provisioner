#!/bin/bash

CONFIG_DIR="blockr_config"
LOCAL_DIR=`pwd`
PRODUCTION_DIR=/var/hyperledger

deleteFile() {
  if [ -f $1 ]; then
    echo "Copy of $1 will be removed"
    rm -f $1 
  fi
}

#
# stop running binaries
#
pkill orderer 
pkill peer

#
# stop couchdb and remove production artifacts
#
sudo su - $(whoami) - << EOF
sudo /etc/init.d/couchdb stop
if [ -d $PRODUCTION_DIR ]; then
  echo "Production directory $PRODUCTION_DIR will be removed"
  sudo rm -rf $PRODUCTION_DIR
fi
EOF

#
# local artifact cleanup
#
cd $LOCAL_DIR
echo "Cleaning up artifacts in the directory {$LOCAL_DIR}"
rm -rf $CONFIG_DIR 
. config.sh
for p in $nodes ; do
  rm -rf $p
done

#
# restart couchdb
#
sudo su - $(whoami) - << EOF
sudo /etc/init.d/couchdb start
EOF

