
export WAIT_SECONDS=1

shutdown_node() {
  echo "----------"
  echo " Shutdown Node $1"
  echo "----------"
  ssh $1 "pkill orderer"
  ssh $1 "pkill peer"
}
 
echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

shutdown_node vm1
sleep $WAIT_SECONDS 
shutdown_node vm2

