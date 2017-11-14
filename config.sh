################################################################################
#
#  Block R Network Configuration
#
################################################################################

#
# Zookeeper configurationam - There should be two servers configured.
#
zookeepers="vm1 vm2"
zookeeper_accounts="mal mal"

#
# Node configuration - There should be an odd number of servers
#
nodes="vm1 vm2"
accounts="mal mal"
domains="nar.blockr car.blockr"
orderer_names="NAR-Orderer-0 CAR-Orderer-0"
orderers="Orderer1MSP Orderer2MSP"
peer_names="NAR-Peer-0 CAR-Peer-0"
peers="Org1MSP Org2MSP"

