from scripts.helpful_scripts import *
from brownie import SimbaToken, TokenFarm, config, network
from web3 import Web3


KEPT_BALANCE =  Web3.toWei(100, "ether")
TOTAL_SUPPLY =  Web3.toWei(1000000, "ether")
def deploy_token_and_farm_token():
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
    tx.wait()

    #simba, fau/dai, weth
    weth_token = get_contract('weth_token')
    fau_token = get_contract('fau_token')
    add_allowed_tokens()


def add_allowed_tokens(token_farm,dict_of_allowed_tokens,account):
    for token in dict_of_allowed_tokens:
        token_farm.addAllowedToken(token, {'from':account})



def main():
    deploy_token_and_farm_token()