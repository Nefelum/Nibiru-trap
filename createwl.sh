#!/bin/bash

for wallet_name in `cat ./wallet_name.txt`; do
	/root/go/bin/nibid keys add $wallet_name
	echo -e "$wallet_name\t$(/root/go/bin/nibid keys show $wallet_name -a)\t$(echo y|/root/go/bin/nibid keys export $wallet_name --unarmored-hex --unsafe)" >> ./wallet_name_addr.txt;
        echo "Created $wallet_name $(/root/go/bin/nibid keys show $wallet_name -a)"; sleep 1;
done
