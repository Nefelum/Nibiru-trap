#!/bin/bash

nibid config node https://nibiru-testnet.nodejumper.io:443
nibid config chain-id nibiru-itn-1
nibid config broadcast-mode block

rm -rf smartcontract/*.json
# mkdir -p smartcontract

#wget -O smartcontract/cw1_whitelist.wasm https://github.com/NibiruChain/cw-nibiru/raw/main/artifacts-cw-plus/cw1_whitelist.wasm

CONTRACT_PATH="./smartcontract"
# CONTRACT_WASM="cw1_whitelist.wasm"
NIBI=000000unibi
CODE_ID="2257"

echo -e "\nList of contract, kindly select:
	1. cw1_subkeys.wasm
	2. cw1_whitelist.wasm
	3. cw3_fixed_multisig.wasm # ERROR
	4. cw3_flex_multisig.wasm
	5. cw4_group.wasm
	6. cw4_stake.wasm #ERROR \n"

read  CONTRACT_WASM


read -p "Starting line: " START_LINE
read -p "Ending line: " END_LINE

#cat ./wallet_name_addr.txt |  while read wallet_name wallet_addr wallet_privatekey moniker_name; do
#cat wallet_name_addr.txt | tail -n `expr $(cat wallet_name_addr.txt | wc -l) - 15` | head -n 5 | while read wallet_name wallet_addr wallet_privatekey moniker_name; do
cat ./wallet_name_addr.txt | sed -n "${START_LINE},${END_LINE}p" | while read wallet_name wallet_addr wallet_privatekey moniker_name
do
	nibid tx wasm store ${CONTRACT_PATH}/${CONTRACT_WASM} --from $wallet_name --gas=3000000 --fees=2$NIBI --output json -y | jq > ${CONTRACT_PATH}/wasm_store.json
	sleep 5;

	CODE_ID_CW=$(cat ${CONTRACT_PATH}/wasm_store.json | jq -r '.logs[] | .events[] | select(.type=="store_code") | .attributes[] | select(.key=="code_id") | .value')

	TOKEN_SYMBOL=$(rig -c 1 | head -n 1 | awk '{print $1}')

	sudo tee ${CONTRACT_PATH}/inst.json > /dev/null <<EOF
{
  "name": "Custom CW20 token",
  "symbol": "$TOKEN_SYMBOL",
  "decimals": 6,
  "initial_balances": [
    {
      "address": "$wallet_addr",
      "amount": "1000000"
    }
  ],
  "mint": { "minter": "$wallet_addr" },
  "marketing": {}
}
EOF
	sleep 5;

	nibid tx wasm inst $CODE_ID "$(cat ${CONTRACT_PATH}/inst.json)" --label="mint CWXX contract" --no-admin --from=$wallet_name --fees=10000unibi --output json -y | jq > ${CONTRACT_PATH}/tx-inst.json;
	sleep 5;

        TX_HASH=$(cat ${CONTRACT_PATH}/tx-inst.json | jq -r .txhash)
	CONTRACT=$(cat ${CONTRACT_PATH}/tx-inst.json | jq -r '.logs[] | .events[] | select (.type=="instantiate") | .attributes[] | select(.key=="_contract_address") | .value')

	sudo tee ${CONTRACT_PATH}/cw_transfer.json > /dev/null <<EOF
{
  "transfer": {
    "recipient": "$wallet_addr",
    "amount": "5"
  }
}
EOF
	sleep 5;
        nibid tx wasm execute $CONTRACT "$(cat ${CONTRACT_PATH}/cw_transfer.json)" --from $wallet_name --gas 8000000 --fees=200000unibi -oj -y > ${CONTRACT_PATH}/tx_exec_resp.json
	sleep 5;


	echo -e "DONE for $wallet_name"
	sleep 120;

done
