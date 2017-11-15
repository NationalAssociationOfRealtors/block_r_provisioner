
DEBUG=false
FABRIC=$GOPATH/src/github.com/hyperledger/fabric
INSTALL_DRIVER_NAME=install_blockr_driver.sh
MASTER_BRANCH=true

echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

export CURRENT_LOCATION=`pwd`
echo '#!/bin/bash' > $INSTALL_DRIVER_NAME
echo '' >> $INSTALL_DRIVER_NAME
echo '#----------------' >> $INSTALL_DRIVER_NAME
echo '#' >> $INSTALL_DRIVER_NAME
echo '# Block R Installation Driver' >> $INSTALL_DRIVER_NAME
echo '#' >> $INSTALL_DRIVER_NAME
echo '#----------------' >> $INSTALL_DRIVER_NAME
echo -n 'FABRIC=' >> $INSTALL_DRIVER_NAME
echo $FABRIC >> $INSTALL_DRIVER_NAME
echo 'echo " - Install Hyperledger"' >> $INSTALL_DRIVER_NAME
echo 'if [ -d $FABRIC ]; then' >> $INSTALL_DRIVER_NAME
echo '  echo "GO directory $FABRIC already exists, it will be removed"' >> $INSTALL_DRIVER_NAME
echo '  rm -rf $FABRIC' >> $INSTALL_DRIVER_NAME
echo 'fi' >> $INSTALL_DRIVER_NAME
#echo 'mkdir -p $FABRIC' >> $INSTALL_DRIVER_NAME
#echo 'chown -R $(whoami):$(whoami) $FABRIC' >> $INSTALL_DRIVER_NAME
echo 'git clone https://github.com/hyperledger/fabric $FABRIC' >> $INSTALL_DRIVER_NAME
echo 'if ! [ -d $FABRIC ]; then' >> $INSTALL_DRIVER_NAME
echo '  echo "ERROR - git repository not accessible"' >> $INSTALL_DRIVER_NAME
echo '  exit' >> $INSTALL_DRIVER_NAME
echo 'fi' >> $INSTALL_DRIVER_NAME
echo 'cd $FABRIC' >> $INSTALL_DRIVER_NAME
if [ "$MASTER_BRANCH" == true ]; then
  echo "echo 'Change to the master branch'" >> $INSTALL_DRIVER_NAME 
  echo 'git checkout master' >> $INSTALL_DRIVER_NAME 
fi
echo -n 'export GOPATH=' >> $INSTALL_DRIVER_NAME
echo $GOPATH >> $INSTALL_DRIVER_NAME
echo -n 'export PATH=' >> $INSTALL_DRIVER_NAME
echo $PATH >> $INSTALL_DRIVER_NAME
echo 'make native' >> $INSTALL_DRIVER_NAME 
echo 'echo " - Install systemd scripts"' >> $INSTALL_DRIVER_NAME
echo -n 'sudo cp ' >> $INSTALL_DRIVER_NAME
echo -n $CURRENT_LOCATION >> $INSTALL_DRIVER_NAME
echo '/scripts/kafka.service /etc/systemd/system' >> $INSTALL_DRIVER_NAME
echo 'sudo chmod 755 /etc/systemd/system/kafka.service' >> $INSTALL_DRIVER_NAME
echo -n 'sudo cp ' >> $INSTALL_DRIVER_NAME
echo -n $CURRENT_LOCATION >> $INSTALL_DRIVER_NAME
echo '/scripts/zookeeper.service /etc/systemd/system' >> $INSTALL_DRIVER_NAME
echo 'sudo chmod 755 /etc/systemd/system/zookeeper.service' >> $INSTALL_DRIVER_NAME
echo 'sudo systemctl daemon-reload' >> $INSTALL_DRIVER_NAME

scp -q ./$INSTALL_DRIVER_NAME $HOSTNAME:
ssh $HOSTNAME "chmod 777 $INSTALL_DRIVER_NAME"
ssh $HOSTNAME "./$INSTALL_DRIVER_NAME"
if [ "$DEBUG" != true ]; then
  ssh $HOSTNAME "rm ./$INSTALL_DRIVER_NAME"
fi
rm ./$INSTALL_DRIVER_NAME

