#!/bin/bash

# Set Variables
CHANNEL_NAME="orangeapp"
CHAINCODE_NAME="bidding"
CHAINCODE_PATH="./biddingm/chaincode-go/chaincode"  # Update this path
CHAINCODE_VERSION="1.0"
CHAINCODE_SEQUENCE="1"
ORDERER_ADDRESS="localhost:7050"

# Function to set the environment for each Org
setGlobals() {
    ORG=$1
    if [ "$ORG" == "Org1" ]; then
        CORE_PEER_LOCALMSPID="Org1MSP"
        CORE_PEER_MSPCONFIGPATH="$PWD/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
        CORE_PEER_ADDRESS="localhost:7051"
    elif [ "$ORG" == "Org2" ]; then
        CORE_PEER_LOCALMSPID="Org2MSP"
        CORE_PEER_MSPCONFIGPATH="$PWD/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp"
        CORE_PEER_ADDRESS="localhost:8051"
    elif [ "$ORG" == "Org4" ]; then
        CORE_PEER_LOCALMSPID="Org4MSP"
        CORE_PEER_MSPCONFIGPATH="$PWD/crypto-config/peerOrganizations/org4.example.com/users/Admin@org4.example.com/msp"
        CORE_PEER_ADDRESS="localhost:9051"
    fi
}

# Function to install chaincode
installChaincode() {
    ORG=$1
    setGlobals $ORG
    echo "Installing chaincode on $ORG..."
    peer lifecycle chaincode install ${CHAINCODE_PATH}/${CHAINCODE_NAME}.tar.gz
}

# Function to approve chaincode for an Org
approveChaincode() {
    ORG=$1
    setGlobals $ORG
    echo "Approving chaincode on $ORG..."
    peer lifecycle chaincode approveformyorg -o $ORDERER_ADDRESS --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --package-id $PACKAGE_ID --sequence $CHAINCODE_SEQUENCE --tls --cafile "$ORDERER_CA"
}

# Function to commit chaincode on the channel
commitChaincode() {
    setGlobals Org1  # Setting Org1 as committer (update if necessary)
    echo "Committing chaincode on the channel..."
    peer lifecycle chaincode commit -o $ORDERER_ADDRESS --channelID $CHANNEL_NAME --name $CHAINCODE_NAME --version $CHAINCODE_VERSION --sequence $CHAINCODE_SEQUENCE --tls --cafile "$ORDERER_CA" --peerAddresses localhost:7051 --peerAddresses localhost:8051 --peerAddresses localhost:9051
}

# Function to invoke chaincode
invokeChaincode() {
    echo "Invoking chaincode..."
    peer chaincode invoke -o $ORDERER_ADDRESS --tls --cafile "$ORDERER_CA" -C $CHANNEL_NAME -n $CHAINCODE_NAME -c '{"Args":["<function>","<args>"]}' --peerAddresses localhost:7051 --peerAddresses localhost:8051 --peerAddresses localhost:9051
}

# Main process
echo "Packaging chaincode..."
peer lifecycle chaincode package ${CHAINCODE_PATH}/${CHAINCODE_NAME}.tar.gz --path $CHAINCODE_PATH --lang golang --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION}

installChaincode Org1
installChaincode Org2
installChaincode Org4

echo "Querying installed chaincodes to retrieve package ID..."
setGlobals Org1
PACKAGE_ID=$(peer lifecycle chaincode queryinstalled | grep ${CHAINCODE_NAME}_${CHAINCODE_VERSION} | awk '{print $3}' | sed 's/.$//')

approveChaincode Org1
approveChaincode Org2
approveChaincode Org4

commitChaincode
invokeChaincode
