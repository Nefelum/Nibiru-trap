#!/bin/bash

# Ouput list of active validator running Oracle (filter by moniker name included Oracle) to file `oracle_val_list.txt`
nibid q staking validators -oj --limit=5000 |  jq '.validators[] | select(.status=="BOND_STATUS_BONDED")' | jq -r '[.operator_address,.description.moniker] | join(" ")' | grep -i "Oracle" > oracle_val_list.txt


CHAIN_ID="nibiru-itn-1";

echo "========================================================================="
echo "Log file will be in format"
echo "WALLETNAME 1ST_VAL_ADDR 2ND_VAL_ADDR DELEGATE_TXH REDELEGATE_TXH DELEGATE_PRICEFEEDER_TXH WITHDRAW_TXH UNSTAKE_TXH"
echo "========================================================================="
cat ./wallet_name_addr.txt | head -n 18 | while read wallet_name wallet_addr wallet_privatekey; do

SEL_VAL_1=$(cat ./oracle_val_list.txt | head -n $(grep $wallet_addr ./wallet_name_addr.txt -n | awk -F ":" '{print $1}' ) | tail -n 1 | awk '{print $1}')
SEL_VAL_2=$(cat ./oracle_val_list.txt | head -n $(expr $(grep $wallet_addr ./wallet_name_addr.txt -n | awk -F ":" '{print $1}') + 20) | tail -n 1 | awk '{print $1}')

# Delegate to 1st Oracle active validator 
DEL_TXH=$(nibid tx staking delegate $SEL_VAL_1 3000000unibi --from $wallet_name --chain-id $CHAIN_ID --gas-prices 0.1unibi --gas-adjustment 1.5 --gas auto -y | grep -e "^txhash" | awk '{print $2}');
sleep 10;

# Redelegate to 2nd Oracle active validator
REDEL_TXH=$(nibid tx staking redelegate $SEL_VAL_1 $SEL_VAL_2 1200000unibi --from $wallet_name --chain-id $CHAIN_ID --gas-prices 0.1unibi --gas-adjustment 1.5 --gas auto -y | grep -e "^txhash" | awk '{print $2}');
sleep 10;

# Delegate pricefeeder responsibility to 1st Oracle
PRICE_FEEDER_ADDR=$(nibid query oracle feeder $SEL_VAL_1 | awk '{print $2}')
DEL_PRI_FEEDER_TXH=$(nibid tx oracle set-feeder $PRICE_FEEDER_ADDR --from $wallet_name --chain-id $CHAIN_ID --gas-prices 0.1unibi --gas-adjustment 1.5 --gas auto -y | grep -e "^txhash" | awk '{print $2}');
sleep 10;

# Claim reward 
sleep 300;
WITHDRAW_RW_TXH=$(nibid tx distribution withdraw-all-rewards --from $wallet_name --chain-id $CHAIN_ID --gas-prices 0.1unibi --gas-adjustment 1.5 --gas auto -y | grep -e "^txhash" | awk '{print $2}');
sleep 10;

# Unstake token
UNSTAKE_TXH=$(nibid tx staking unbond $SEL_VAL_1 10000unibi --from $wallet_name --chain-id $CHAIN_ID --gas-prices 0.1unibi --gas-adjustment 1.5 --gas auto -y | grep -e "^txhash" | awk '{print $2}');
sleep 10;

echo "$wallet_name $SEL_VAL_1 $SEL_VAL_2 $DEL_TXH $REDEL_TXH $DEL_PRI_FEEDER_TXH $WITHDRAW_RW_TXH $UNSTAKE_TXH" >> nibiru_task.log

done
