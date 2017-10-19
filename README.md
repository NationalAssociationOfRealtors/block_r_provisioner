# Network Provisioner of the Block R Series

This tool was created to help maintain the regional Block R processing nodes.  Here are some notes:

- Each processing node consists of a single orderer and a single peer
- If Hyperledger Fabric is not installed on a targeted node, it will be installed
- The network can be specified to communicate with or without TLS.   
- Only one channel is defined. 

---

**Prerequisites**

- Local git repo of Hyperledger Fabric in `$GOPATH/src/github.com/hyperledger/fabric`
- Empty physical servers/virtual machines to be used as a solo ordering service and peers
- Tested with Centos 7, other distributions might also work
- git client installed on the servers
- Ability to do "sudo" without having to enter a password on the servers
- Ability to ssh without having to enter a password from the machine that runs this script
- Ability of peers to resolve each other's DNS names and the orderer's DNS name
- Installed and operatonal Apache Kafka at least at level 0.10.2.0 

---

**Installation**

1. Use the systemd definitions in the /scripts diretory for zooeeper and kafka.
2. Run the `install.sh` script to setup the environment and install Hyperledger Fabric
3. Edit `blockr-config.yaml` and `confitx.yaml` in the templates directory with the hostnames of the servers that are to be used as nodes 
4. Provision the system using the instructions below. 

---

**Operation**

The following primary scripts are included:

- `create_channel.sh` adds the peer on each node to the "blockr" channel  
- `install.sh` install Hyperledget Fabric and prepared the server 
- `install_chaincode.sh` installs chaincode on each node 
- `provision.sh` performs the provisioning 
- `reset_nodes.sh` sets the all nodes on the channel to its initial state 
- `start_nodes.sh` starts both peer and orderer daemons on each node of the system. 
- `stop_nodes.sh` stops both peer and orderer daemons on each node of the system. 

There is also a `scripts` directory that contains:

- `invoke.sh' used to modify contents of the edger for testing
- `query.sh' used to inspect the contents of the ledger duting testing

Here is the sequence of operations neeeded to install a network: 

- `reset_nodes.sh` ensures there are no artifacts remaining on any of the nodes.
- `provision.sh` prepares each node using configuration information from the `blockr-config.yaml` and `confitx.yaml` files in the templates directory.  Creates blocks and transactions required fro the `blockr` channel.    
- `start_nodes.sh` starts peer and orderer daemons on each node of the system. 
- `create_channel.sh` performs three operations on the peer of each node:
-- defines the `blockr` channel 
-- joins the `blockr` channel 
-- defines the peer as an `AnchorPeer` to facilitate Hyperledger gossip communications 
- `install_chaincode.sh` installs chaincode on each.

After installation, each node can be tested using the `query.sh` and `invoke.sh` scripts.

When you are done testing, use the `stop_nodes.sh` script to stop the nodes.  

---

**Disclaimers/Warnings**

The script is destructive to any server running Hyperledger Fabric.  It resets `/var/hyperledger/production`and deletes docker images.  Only run this script on VMs / servers created solely for Block R installation.

---

**Acknowledgements**

This work is a collaborative effort of six REALTOR(R) Associations.

