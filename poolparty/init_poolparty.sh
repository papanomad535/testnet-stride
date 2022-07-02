#!/bin/bash
set -e
clear 

# you can always install this script with
# curl -L install.poolparty.stridelabs.co | sh

PURPLE='\033[0;35m'
BOLD="\033[1m"
BLUE='\033[1;34m'
ITALIC="\033[3m"
NC="\033[0m"

printf "\n\n${BOLD}Welcome to the setup script for Stride's Testnet, ${PURPLE}PoolParty${NC}!\n\n"
printf "This script will guide you through setting up your very own Stride node locally.\n\n"

printf "First, we need to give your node a nickname. "

while true; do
    read -p "$(echo $PURPLE"What would you like to call it? "$NC)" NODE_NAME
    if [ -z "$NODE_NAME" ]; then
    printf 'Please enter a node name.'
    else
        break
    fi
done

TESTNET="internal"
INSTALL_FOLDER="$HOME/.stride/$TESTNET"
STRIDE_FOLDER="$HOME/.stride"

BLINE="\n${BLUE}============================================================================================${NC}\n"
printf $BLINE

printf "\nGreat, now we'll download the latest version of Stride.\n"
printf "Stride will keep track of blockchain state in ${BOLD}$STRIDE_FOLDER${NC}\n\n"

if [ -d $STRIDE_FOLDER ] 
then
    printf "${BOLD}Looks like you already have Stride installed.${NC}\n"
    printf "Proceed carefully, because you won't be able to recover your data if you overwrite it.\n\n"
    pstr="Do you want to overwrite your existing $TESTNET installation and proceed? [y/n] "
    while true; do
        read -p "$(echo $PURPLE"$pstr"$NC)" yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.\n";;
        esac
    done
fi
printf $BLINE

rm -rf $STRIDE_FOLDER > /dev/null 2>&1
rm -f launch_testnet.sh > /dev/null 2>&1

mkdir -p $INSTALL_FOLDER
cd $INSTALL_FOLDER

echo "\nFetching Stride's code...\n"
git clone https://github.com/Stride-Labs/stride.git > /dev/null 2>&1
cd stride 
git checkout 62e897c34f66d9cd0a7e0307517cd41c55a8f473 > /dev/null 2>&1

mkdir -p $INSTALL_FOLDER/build/

# pick install location
DEFAULT_BINARY="$HOME/go/bin"
rstr="Where do you want to install your stride binary? [default: $DEFAULT_BINARY] "
read -p "$(echo Almost there\! $PURPLE"$rstr"$NC)" BINARY_LOCATION
if [ -z "$BINARY_LOCATION" ]; then
    BINARY_LOCATION=$DEFAULT_BINARY
fi
printf "\n"
mkdir -p $BINARY_LOCATION
sh $INSTALL_FOLDER/stride/scripts-local/build.sh -s $BINARY_LOCATION
printf "\n"

printf $BLINE

BINARY=$BINARY_LOCATION/strided
printf "\nLast step, we need to setup your genesis state to match PoolParty...\n"

$BINARY init $NODE_NAME --home $STRIDE_FOLDER --chain-id STRIDE --overwrite > /dev/null 2>&1

# Now pull the genesis file
curl https://bafkreid3dxxitn75gwr6dllhouasrdzgwmlj6wcyvrbspzzlsi453iskye.ipfs.dweb.link/ -o $STRIDE_FOLDER/config/genesis.json > /dev/null 2>&1

# # add persistent peer
config_path="$STRIDE_FOLDER/config/config.toml"
app_path="$STRIDE_FOLDER/config/app.toml"
PEER_ID="2ccf88e4c18e072f6173f80392ed5e61fccaf719@stride-node1.internal.stridenet.co:26656"
sed -i -E "s|persistent_peers = \".*\"|persistent_peers = \"$PEER_ID\"|g" $config_path

fstr="$BINARY start --home $STRIDE_FOLDER"

launch_file=$INSTALL_FOLDER/launch_poolparty.sh
rm -f $launch_file
echo $fstr >> $launch_file
printf $BLINE
printf "\n\n"
echo "You're all done! You can now launch your node with the following command:\n"
echo "     ${PURPLE}strided start${NC}\n"
echo "Or, if you'd prefer:\n"
echo "     ${PURPLE}sh $launch_file${NC}\n"
echo "Just make sure $BINARY_LOCATION is in your PATH."

sleep 2
printf "\nNow for the fun part.\n\n"
sleep 2

while true; do
    read -p "$(echo $PURPLE"Do you want to launch your blockchain? [y/n] "$NC)" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

sh $launch_file