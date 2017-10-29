#!/bin/bash

echo ".----------------"
echo "|"
echo "| Block R Provisoner"
echo "|"
echo "'----------------"

DIVIDER="-------------------------------"
USER_MESSAGE=""
OPTION_1_TRAIL=""
OPTION_2_TRAIL=""
OPTION_3_TRAIL="*"
OPTION_4_TRAIL="*"
OPTION_5_TRAIL="*"

help_screen() {
  echo -e "Invalid option.\n Choose from the list below.\n * indicates an illogical choice."
}

run_status() {
  RUN_COUNT=0;
  if $(/usr/bin/systemctl -q is-active couchdb) ; then
    ((RUN_COUNT++))
  fi
  if $(/usr/bin/systemctl -q is-active kafka) ; then
    ((RUN_COUNT++))
  fi
  if $(/usr/bin/systemctl -q is-active zookeeper) ; then
    ((RUN_COUNT++))
  fi
  if [ $RUN_COUNT = '3' ]; then
    echo true;
  else
    echo false;
  fi
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
echo " 1) Provision $OPTION_1_TRAIL"
echo " 2) Start Nodes $OPTION_2_TRAIL"
echo " 3) Create Channel $OPTION_3_TRAIL"
echo " 4) Install Chaincode $OPTION_4_TRAIL"
echo " 5) Stop Nodes $OPTION_5_TRAIL"
echo ""
echo " ?) Help"
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
       echo $DIVIDER
       read -p "Hit Enter to return" 
       OPTION_1_TRAIL="*" 
       OPTION_1_TRAIL="" 
       OPTION_3_TRAIL="*" 
       OPTION_4_TRAIL="*" 
       OPTION_5_TRAIL="*" 
       USER_MESSAGE="All nodes are provisoned" ;;
    2) ./start_nodes.sh
       echo $DIVIDER
       read -p "Hit Enter to return" 
       OPTION_1_TRAIL="*" 
       OPTION_2_TRAIL="*" 
       OPTION_3_TRAIL="" 
       OPTION_4_TRAIL="*" 
       OPTION_5_TRAIL="" 
       USER_MESSAGE="Nodes have started" ;;
    3) ./create_channel.sh 
       echo $DIVIDER
       read -p "Hit Enter to return" 
       OPTION_1_TRAIL="*" 
       OPTION_2_TRAIL="*" 
       OPTION_3_TRAIL="*" 
       OPTION_4_TRAIL="" 
       OPTION_5_TRAIL="" 
       USER_MESSAGE="Channel created" ;;
    4) ./install_chaincode.sh 
       echo $DIVIDER
       read -p "Hit Enter to return" 
       OPTION_1_TRAIL="*" 
       OPTION_2_TRAIL="*" 
       OPTION_3_TRAIL="*" 
       OPTION_4_TRAIL="*" 
       OPTION_5_TRAIL="" 
       USER_MESSAGE="Chaincode installed" ;;
    5) ./stop_nodes.sh
       echo $DIVIDER
       read -p "Hit Enter to return" 
       OPTION_1_TRAIL="" 
       OPTION_2_TRAIL="" 
       OPTION_3_TRAIL="*" 
       OPTION_4_TRAIL="*" 
       OPTION_5_TRAIL="*" 
       USER_MESSAGE="Nodes have stopped" ;;
    *) USER_MESSAGE=$(help_screen) ;;
  esac
  display_options
fi
}

if [ "$(run_status)" = "true" ]; then
  USER_MESSAGE="Nodes are active"
  OPTION_1_TRAIL="*"
  OPTION_2_TRAIL="*"
  OPTION_3_TRAIL="*"
  OPTION_4_TRAIL="*"
  OPTION_5_TRAIL=""
fi
display_options


