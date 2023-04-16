#!/bin/bash

: '
############# Claim faucet with proxy  ##########################
# Note: The file wallet_name_addr.txt will be created which contains addr, name and privatekey
sudo bash ./create_wallet.sh;
'

############# Claim faucet with proxy  ##########################
cat ./wallet_name_addr.txt | while read wallet_name wallet_addr wallet_privatekey; do
	FAUCET_URL="https://faucet.itn-1.nibiru.fi/"
	PROXY=$(cat ./proxy.txt | head -n $(grep $wallet_addr ./wallet_name_addr.txt -n | awk -F ":" '{print $1}' ) | tail -n 1)
	while [[ $(echo "$(nibid query bank balances $wallet_addr --output json | jq -r .balances[])")  == "" ]] 
	do 
		curl --proxy $PROXY -X POST -d '{"address": "'"$wallet_addr"'", "coins": ["11000000unibi","100000000unusd","100000000uusdt"]}' $FAUCET_URL; sleep 2;
	done
	echo "========================= Faucet is claimed for $wallet_addr ============================" # $PROXY"
done
