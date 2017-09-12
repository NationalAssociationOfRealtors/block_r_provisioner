# Network Provisioner of the Block R Series

This tool was created to help maintain the regional Block R processing nodes.  Here are some notes:

- Each processing node consists of a single orderer and a single peer
- If Hyperledger Fabric is inot installed on a targeted xsnode, it will be installed
- The network can be specified to communicate with or without TLS.   
- Only one channel is defined. 

---

**Prerequisites**

- Local git repo of Hyperledger Fabric in `$GOPATH/src/github.com/hyperledger/fabric`
- Empty physical servers/virtual machines to be used as a solo ordering service and peers
- Tested with CENTOS 7, other distributions might also work
- git client installed on the servers
- Ability to do "sudo" without having to enter a password on the servers
- Ability to ssh without having to enter a password from the machine that runs this script
- Ability of peers to resolve each other's DNS names and the orderer's DNS name

---

**Installation**

1. Run the `install.sh` script to setup the environment and install Hyperledger Fabric
2. Edit `config.sh` with the hostnames of the servers that are to be used as nodes 
3. Run the `provision.sh` script

---

**Operation**

The following scripts are included:

- `config.sh` a space delimited list of Fully Qualified Domain Names (FQDN) for the nodes 
- `install.sh` install Hyperledget Fabric and prepared the server 
- `provision.sh` performs the provisioning 
- `reset.sh` sets the server to its initial state, but does not install Hyperledger Fabric 

---

---

**Disclaimers/Warnings**

 The script is destructive to any server running Hyperledger Fabric.  It resets `/var/hyerledger/production` and deletes docker images.  Only run this script on VMs / servers created solely for Block R installation.

The following binaries are copied from Hyperledger Fabric to for provisioning:

- configtxgen 
- cryptogen 
- peer
 
---

**Acknowledgements**

This work was paterned after work from Yacov Manevich found on [github] (https://github.com/yacovm/fabricDeployment)

