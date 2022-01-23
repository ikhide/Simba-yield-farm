from scripts.helpful_scripts import get_account, get_contract
from brownie import SimbaToken, TokenFarm, config, network
from web3 import Web3
import yaml
import json
import os
import shutil

KEPT_BALANCE =  Web3.toWei(100, "ether")
TOTAL_SUPPLY =  Web3.toWei(1000000, "ether")

def deploy_token_and_farm_token(front_end_update=True):
    account  = get_account() 
    # deploy tokens
    simba_token = SimbaToken.deploy(TOTAL_SUPPLY,{'from': account})
    token_farm = TokenFarm.deploy(
        simba_token.address,
        {'from': account},
        publish_source=config['networks'][network.show_active()].get('verify', False)
    )
    
    # send all simba tokens tokens to token farm and leave just a few.
    tx = simba_token.transfer(token_farm.address, simba_token.totalSupply() - KEPT_BALANCE, {'from': account})
    tx.wait(1)
 
    #simba, fau/dai, weth
    weth_token = get_contract('weth_token')
    fau_token = get_contract('fau_token')

    dict_of_allowed_tokens = {
        simba_token:  get_contract('dai_usd_price_feed'),
        fau_token: get_contract('dai_usd_price_feed'),
        weth_token: get_contract('eth_usd_price_feed'),
    }
    add_allowed_tokens(token_farm,dict_of_allowed_tokens,account)
    if front_end_update:
        update_front_end()

    return token_farm, simba_token


def add_allowed_tokens(token_farm, dict_of_allowed_tokens,account):
    for token in dict_of_allowed_tokens:
        print(token)
        add_tx = token_farm.addAllowedToken(token.address, {'from':account})
        add_tx.wait(1)
        set_tx = token_farm.setPriceFeedContract(token.address, dict_of_allowed_tokens[token], {'from':account})
        set_tx.wait(1)
    return token_farm

def update_front_end():
    # Send the build folder
    copy_folders_to_front_end("./build", "./yield_farm_frontend/src/chain-info")

    # Sending the front end our config in JSON format
    with open("brownie-config.yaml", "r") as brownie_config:
        config_dict = yaml.load(brownie_config, Loader=yaml.FullLoader)
        with open("./yield_farm_frontend/src/brownie-config.json", "w") as brownie_config_json:
            json.dump(config_dict, brownie_config_json)
    print("Front end updated!")


def copy_folders_to_front_end(src, dest):
    if os.path.exists(dest):
        shutil.rmtree(dest)
    shutil.copytree(src, dest)


def main():
    deploy_token_and_farm_token(front_end_update=True)