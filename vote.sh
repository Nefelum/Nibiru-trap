#!/bin/bash

echo "========================================================================="
echo "Log file will be in format"
echo "GOV_TXH"
echo "========================================================================="
cat ./wallet_name_addr.txt | while read wallet_name wallet_addr wallet_privatekey; do
	# Create governance
GOV_TXH=$(nibi1d tx gov vote 266 yes --from $wallet_name --chain-id nibiru-itn-1 --node="https://t-nibiru.rpc.utsa.tech:443" --fees 10000unibi --gas=auto --gas-adjustment 1.4 -y) | grep -e "^txhash" | awk '{print $2}');
  	sleep 5;

echo "$GOV_TXH" >> governance_task.log

done
