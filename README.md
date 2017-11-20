# Provisioner for the Block R Network  

This tool was created to help maintain the regional Block R processing nodes.  Here are some notes:

- Each processing node consists of a single orderer and a single peer.
- Optimized for an odd number of nodes to facilitate consensus.
- Hyperledger Fabric will be installed on each node
- The network can be specified to communicate with or without TLS.   
- Only one channel is defined. 
- Tested with Centos 7, other distributions might need adjustments. 

---

**Prerequisites**

- Local git repo of Hyperledger Fabric in `$GOPATH/src/github.com/hyperledger/fabric`
- git client installed on the servers
- Ability to do "sudo" without having to enter a password on the servers.  One way to do this is to add the user account to the `wheel` group.
- Ability to ssh without having to enter a password from the machine that runs this script
- Ability of nodes to resolve each other's DNS names
- Installed and operatonal Apache Kafka at least at level 0.10.2.0 
- Docker at least at level 17.09.0-ce

---

**Installation**

This appears to be a complex section, but it is less painful if you are able to build a development system for Hyperledger using the project's instructions.  Their instructions will help you identify all of the dependencies.  Once you have a working system, the following (detail) instructions can be used to build the system and use the scripts.  The `install.sh` script referenced below can be used at anytime to rebuild Hyperledger components from the Master Branch.

1. Configure you user accould to have sudo capabilities without being prompted for a password.
2. Configure your server to execute SSH commands on all servers that will run compoments without being prompted for a password.
3. Make sure that the HOSTNAME environmental variable is set for all servers and that their static addresses are captured in the `/etc/hosts` files on each server.
4. Install Kafaka version 0.10.2.  This also contains zookeeper.
5. Install the systemd definitions in the /scripts directory for zooeeper and kafka.
6. There is no package for CouchDB on Centos 7, so find the package on the web and build from source.  Use all of the default settings.
7. Run the `install.sh` script to setup the environment and install Hyperledger Fabric.
- By default, the `MASTER_BRANCH` variable is set to `true`.  If you do not want to work from the Hyperledger master branch, set this variable to `false`.
- Setting the `DEBUG` to `true` will leave a copy of script in the home directory to give you a chance to instapect the file.   
8. Copy the `config.sh-sample` file in the root directory to `config.sh'
9. Edit `config.sh` in the root directory with the following information: 
- zookeepers: a space delimited list of server names that run zookeeper.  For example, "vm1 vm2".
- zookeeper_accounts: a space delimited list of accounts that run zookeeper.  For example, "user1 user2a.  When used with `zookeepers` from above, can be used for ssh arguments like "user1@vm1" and user2@vm2"
- nodes: a space delimited list of server names operating regional nodes.  For eample, "west1 central1 east2".
- accounts: a space delimited list of accounts used to administrate regional nodes.  For example, "user_west user_central user_east".  When used with `nodes` above, can be used for ssh arguments like "user_west@west1", "user_central@central1" and "user_east@east2". 
- domains: a space delimited list of domain names representing regional nodes.  For example, "west.blockr central.blockr east.blockr".
- orderer_names: a space delimited list of names representing orderers.  For example, "WEST-Orderer-0 CENTRAL-Orderer-0 EAST-Orderer-0".
- orderers: a space delimited list of names representing orderer MSPs.  For example, "Orderer1MSP Orderer2MSP Orderer3MSP".
- peer_names: a space delimited list of names representing peers.  For example, "WEST-Peer-0 CENTRAL-Peer-0 EAST-Peer-0".
- peers: a space delimited list of names representing peer MSPs.  For example, "Org1MSP Org2MSP Org3MSP".
10. Provision the system using the instructions below. 

---

**Contents**

The following primary scripts can be found in the root directory:

- `config.sh` - configuration file  
- `create_channel.sh` - adds the peer on each node to the "blockr" channel  
- `install.sh` - install Hyperledget Fabric and systyemd scripts 
- `install_chaincode.sh` - installs chaincode on each node 
- `provision.sh` - performs the provisioning 
- `run.sh` - interactive shell to run scripts 
- `start_nodes.sh` - starts both peer and orderer daemons on each node of the system. 
- `stop_nodes.sh` - stops both peer and orderer daemons on each node of the system. 

There is also a `scripts` directory that contains:

- `common.sh` - shared functions  
- `invoke.sh` - used to modify contents of the edger for testing
- `kafka.service` - systemd service for Kafka
- `list_channels.sh` - lists the channels that the peer is subscribed to 
- `query.sh` - used to inspect the contents of the ledger during testing
- `zookeeper.service` - systemd service for Zookeeper 

Configuration templates are found in the `templates` directory.  These are used to create operational configurations from the definitions provided in the `config.sh` file.  They contain default settings:

- `core.yaml` - peer configuration template file
- `orderer.yaml` - orderer configuration template file
- `server.properties` - kafka configuration template file
- `zookeeper.properties` - zookeeper configuration template file

Two other files files are included in the `templates` directory for reference purposes only.  They are not used but can be used to understand what the `provision.sh` script is trying to build.  They are auto-generated.  If you work with the Hyperledger official documentation, these files will be familiar.  They represent a two node system.  

- `blockr-config.yaml` - network configuration file
- `configtx.yaml` - genesis block and channel configuration file

---

**Operation**

You can either execute scripts from the `run.sh` interactive script or run them individually.  If you run them individually, read the rest of this section carefully.

Here is the sequence of operations neeeded to install a network.  It is important that theses scripts are run in order.  They have been designed to capture particularly sensitive sequences inside of scripts to avoid problems.  For instance, the sequence of operations needed to bring up Zookeeper, Kafka and CouchDB daemons is sensitive and thus are contained with the `start_nodes.sh` and `stop_nodes.sh` scripts: 

- `provision.sh` - performs three operations:
  - creates configuration information from the `config.sh` file.  It creates a `blockr-config.yaml` and `confitx.yaml` files.
  - creates blocks and transactions required for the `blockr` channel
  - packages validation chaincode using the first node specified in the `config.sh` file.  Make sure you can ssh without passwords from the first node in the `consif.sh` to all nodes to avoid being prompted for a password.    
  - distributes configuration information and chaincode to each server.
- `create_channel.sh` - performs three operations on the peer of each node:
  - defines the `blockr` channel 
  - joins the `blockr` channel 
  - defines the peer as an `AnchorPeer` to facilitate Hyperledger gossip communications 
- `install_chaincode.sh` - installs chaincode on each node.

Once the nodes are running, each node can be tested using the `./scripts/query.sh` and `./scripts/invoke.sh` scripts.

When you are done testing, use the `stop_nodes.sh` script to stop the nodes.  

---

**Configuration**

All configuration is conducted on files in the `templates` directory.  The distribution is pre-configured for a two node system.  These nodes are called `vm1` and `vm2`.  You can add more servers by modifying `config.sh`  

In order to test run the system, set up two Centos 7 servers and define their addresses in `/etc/hosts`.  

Each node should have the following components:

- Hyperledger Fabric source code
- Peer instance
- Orderer instance
- CouchDB instance
- Kafka instance

A primary and secondary Zookeeper instance should be defined on seperate servers.  The two Zookeeper server do not have to be the same servers used for Hyperledger and in production, you probably would not want them on the same servers anyway.

Other configurations are possible, but this approach results in a regional processing center that can serve to meet the falut-tolerant, high-availability system for membership information.  If one regional center is down, others still operate and take over the load.  Sensing which nodes are operational is the job of Zookeeper.  Kafka provides a queue of messages that allow a node to rejoin a network and "catch up" with messages that have been transmitted while absent.

Here on notes for changing the pre-configured network:

- All configurations and subsequent provisioning should be made on a single computer.  This server will be used to provision other servers.
- Ensure that all HOSTNAME environmental variables are set and that they are defined in the `/etc/hsots` files of each server.
- The `core.yaml` file contains configuration information for each PEER.  It is used as a template for the `provision.sh` script so be careful what you change.  Elements that are used for templating are in all caps such as PEER_ID, PEER_ADDRESS and PEER_BOOTSTRAP.  The top of the file contains log settings. The definition for talking to the underlying CouchDB process is also contained in this file.  You should not have to change thigs here, but have fun tuning and please report your results!
- The `orderer.yaml` file contains configuration information for orderers.  The primary concerns here are the location of underlying database (not how to talk to CouchDB, but where the repository is located) and how to talk to Kafka.  Kafka is a queue of messages between the nodes.
- The `server.properties` file  is a template file for the Kafka daemon that runs on each node.  Be careful editing this file because settings in all caps (like BROKER_ID and SERVER_ADDRESS) are modified by the `provision.sh' script.  Feel free to adjust parameters to improve performance and report your improvements.
- The `zookeeper.properties` file contains configuration parameters for the zookeer instance that runs on each node.  There is very little to configure in this file. 

It is in everyone's interest to report changes and improvements in configurtion.  Remember to post your results.

---

**Generated Configuration Files**

Two files controlling a Hyperledger setup are auto-configured by the contents of the `config.sh` file.  They are created and distributed by the `provision.sh` script.

- `blockr-config.yaml` - Contains the names and locations of the various peers and orderers in your system. 
- `configtx.yaml` - Contains confiigurations for both the genesis block of the system as well as any channels you would like to define.
  - Profiles section: You will find the obvious names `Genesis` and `Channels`.  If you would like to define multiple channels, create another section under `Profiles` using `Channels` as a pattern.
  - Organizations section: Defines the various servers and which encryption keys to use for each.  If you would like a node to have nultiple peers (in order to handle heavy transaction loads), use the AnchorPeers section to point to identify the server that takes the lead when exchanging information with other servers.
  - Orderer:  This section defines how Orderers exchange information and the addresses of each orderer.  We are usinf Kafka to enable communication between Orderes, so the address of each Kafka server needs to be defined.
  - Application: Special configuration information for applications.  No applications configurations are defined in the distribution, but you should have this section defined.
  - Capabilities: The distribution ensures that all processing is conducted with Hyyperledger V1.1 capabilities.  These capabilities are defined in the distribution, but you should have this section defined.

The long term goal of this project is to be able to modify these files once created. 

---

**Disclaimers/Warnings**

The script is destructive to any server running Hyperledger Fabric.  It resets `/var/hyperledger/production`and deletes docker images.  Only run this script on VMs / servers created solely for Block R installation.

---

**Acknowledgements**

This work is a collaborative effort of six REALTOR(R) Associations.

