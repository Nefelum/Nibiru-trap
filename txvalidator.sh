#!/bin/bash

: '
############# Create txh of validator ##########################

# Backup current json file
mkdir -p ./wallet
mkdir -p ./wallet/temp

sudo systemctl stop nibid; sleep 1;
mv /root/.nibid/config/node_key.json ./wallet/temp/node_key.json
mv /root/.nibid/config/priv_validator_key.json ./wallet/temp/priv_validator_key.json
mv /root/.nibid/data/priv_validator_state.json /wallet/temp/priv_validator_state.json
sudo systemctl restart nibid; sleep 5;

# Spam validator txh
cat ./wallet_name_addr.txt | while read wallet_name wallet_addr wallet_privatekey; do
	# Create validator
	nibid tx staking create-validator \
        --amount 100000unibi \
        --from ${wallet_name} \
        --commission-max-change-rate "0.01" \
        --commission-max-rate "0.2" \
        --commission-rate "0.07" \
        --min-self-delegation "1" \
        --pubkey  $(nibid tendermint show-validator) \
        --moniker ${wallet_name} \
        --chain-id nibiru-itn-1 \
        --fees 10000unibi \
        --node https://nibiru.rpc.t.anode.team:443 \
        -y

  	sleep 5;

	# Save txh of validator creating	
        VAL_ADDR=$(nibid keys show $wallet_name --bech val | grep address | awk '{print $NF}')
        VAL_TXHASH=$(nibid q txs --events create_validator.validator=$VAL_ADDR --output json --node https://nibiru.rpc.t.anode.team:443 |jq -r .txs[].txhash)
        echo "$VAL_ADDR create validator at $VAL_TXHASH" >> nibiru_val_txh.log

	# Backup json of created validator
        mkdir -p ./wallet/$wallet_name
        sudo systemctl stop nibid; sleep 1;
        mv /root/.nibid/config/node_key.json ./wallet/$wallet_name/node_key.json
        mv /root/.nibid/config/priv_validator_key.json ./wallet/$wallet_name/priv_validator_key.json
        sudo systemctl restart nibid; sleep 5;

done

