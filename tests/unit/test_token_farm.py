import pytest
from brownie import network

from scripts.deploy import deploy_token_and_farm_token
from scripts.helpful_scripts import get_contract, get_account,LOCAL_BLOCKCHAIN_ENVIRONMENTS, INITIAL_PRICE_FEED_VALUE
from web3 import Web3

# Things to test
# Every pieice of code in solidity file
# setPriceFeedContract


def test_set_price_feed_contract():
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("only for local testing")
    non_owner = get_account(index=1)
    token_farm, simba_token = deploy_token_and_farm_token()

    # All price feeds where set during deployment. Check if they exist

    # Assert
    assert token_farm.tokenPriceFeedMapping(simba_token.address) == get_contract("eth_usd_price_feed").address

    # Assert non-owner can't set price feed
    with pytest.raises(Exception):
        token_farm.setPriceFeedContract(simba_token.address, get_contract("dai_usd_price_feed"), {'from': non_owner})
    
def test_stake_tokens(amount_staked):
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("only for local testing")
    account = get_account()
    non_owner = get_account(index=1)
    token_farm, simba_token = deploy_token_and_farm_token()
    

    # Act
    # stake simba tokens 
    simba_token.approve(token_farm.address,amount_staked, {"from":account})

    tx = token_farm.stakeTokens(amount_staked,simba_token,{"from":account})
    tx.wait(1)
    # check that stakingBalance is equal to staked amount
    assert token_farm.stakingBalance(simba_token, account) == amount_staked
    assert token_farm.uniqueTokensStaked(account) == 1
    assert token_farm.stakers(0) == account
    return token_farm, simba_token

def test_issue_tokens(amount_staked):
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("only for local testing")
    account = get_account()
    token_farm, simba_token = test_stake_tokens(amount_staked)
    startingBalance = simba_token.balanceOf(account)
    
    # Act
    token_farm.issueTokens({"from":account})
    # check that stakingBalance is equal to staked amount + issued tokens
    assert simba_token.balanceOf(account.address) == startingBalance + INITIAL_PRICE_FEED_VALUE








