
shutdown_node() {
  echo "----------"
  echo " Shutdown Node $1"
  echo "----------"
  echo " - Orderer"
  ssh $1 "pkill orderer"
  echo " - Peer"
  ssh $1 "pkill peer"
}
 
echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

shutdown_node vm2
shutdown_node vm1

