
export DEBUG=false
export FABRIC=$GOPATH/src/github.com/hyperledger/fabric
export INSTALL_DRIVER_NAME=install_blockr_driver.sh
export MASTER_BRANCH=true

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
echo -n 'export FABRIC=' >> $INSTALL_DRIVER_NAME
echo $FABRIC >> $INSTALL_DRIVER_NAME
echo 'echo " - Install Hyperledger"' >> $INSTALL_DRIVER_NAME
echo -n 'if [ -d ' >> $INSTALL_DRIVER_NAME
echo -n $FABRIC >> $INSTALL_DRIVER_NAME
echo ' ]; then' >> $INSTALL_DRIVER_NAME
echo -n '  echo "GO directory ' >> $INSTALL_DRIVER_NAME
echo -n $FABRIC >> $INSTALL_DRIVER_NAME
echo ' already exists, it will be removed"' >> $INSTALL_DRIVER_NAME
echo -n '  rm -rf ' >> $INSTALL_DRIVER_NAME
echo $FABRIC >> $INSTALL_DRIVER_NAME
echo 'fi' >> $INSTALL_DRIVER_NAME
echo -n 'mkdir -p ' >> $INSTALL_DRIVER_NAME
echo $FABRIC >> $INSTALL_DRIVER_NAME
echo -n 'chown -R $(whoami):$(whoami) ' >> $INSTALL_DRIVER_NAME
echo $FABRIC >> $INSTALL_DRIVER_NAME
echo -n 'git clone https://github.com/hyperledger/fabric ' >> $INSTALL_DRIVER_NAME
echo $FABRIC >> $INSTALL_DRIVER_NAME
echo -n 'cd ' >> $INSTALL_DRIVER_NAME
echo $FABRIC >> $INSTALL_DRIVER_NAME
if [ "$MASTER_BRANCH" != true ]; then
  echo 'git checkout master' >> $INSTALL_DRIVER_NAME 
fi
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
scp -q ./$INSTALL_DRIVER_NAME localhost:
ssh localhost "chmod 777 $INSTALL_DRIVER_NAME"
ssh localhost "./$INSTALL_DRIVER_NAME"
if [ "$DEBUG" != true ]; then
  ssh localhost "rm ./$INSTALL_DRIVER_NAME"
fi
rm ./$INSTALL_DRIVER_NAME

