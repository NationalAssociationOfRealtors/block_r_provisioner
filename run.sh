
echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

DIVIDER="-------------------------------"
USER_MESSAGE=""

help_screen() {
  echo -e "Invalid option.\n Choose from the list below"
}

display_options() {
clear
echo $DIVIDER
echo "    Block R Provisioner"
echo $DIVIDER
if ! [ "$USER_MESSAGE" = "" ]; then
  echo " $USER_MESSAGE"
  echo $DIVIDER
fi
echo " 1) Provision"
echo " 2) Start Nodes"
echo " 3) Create Channel"
echo " 4) Install Chaincode"
echo " 5) Stop Nodes"
echo ""
echo " q) Quit"
echo $DIVIDER
echo ""
read -p "Enter an option: " USER_OPTION 
if [ "$USER_OPTION" = "q" -o "$USER_OPTION" = "Q" ]; then
  clear
  echo $DIVIDER
  echo "    Block R Provisioner"
  echo $DIVIDER
  echo " Goodbye"
  echo $DIVIDER
  echo ""
  exit 0
else
  case $USER_OPTION in
    1) ./provision.sh
       USER_MESSAGE="All nodes are provisoned" ;;
    2) ./start_nodes.sh 
       USER_MESSAGE="Nodes have started" ;;
    3) ./create_channel.sh 
       USER_MESSAGE="Channel created" ;;
    4) ./install_chaincode.sh 
       USER_MESSAGE="Chaincode installed" ;;
    5) ./stop_nodes.sh
       USER_MESSAGE="Nodes have stopped" ;;
    *) USER_MESSAGE=$(help_screen) ;;
  esac
  display_options
fi
}

display_options


