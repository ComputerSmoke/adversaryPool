from brownie import BackingToken, AdversaryPool, network, accounts, ACAB, interface
from web3 import Web3
from brownie.network import gas_price
import pytest 

initial_supply = Web3.toWei(1000000, "ether")

@pytest.fixture
def deployment():
    account = accounts[0]
    token = BackingToken.deploy(initial_supply, {"from": account})
    pool = AdversaryPool.deploy(token, initial_supply, accounts[1], {"from": account})
    return token,pool

def test_pool_deposit(deployment):
    (token,pool,) = deployment
    assert token.balanceOf(accounts[0], {"from": accounts[0]}) == initial_supply
    estimatedAmountOut = pool.getBuyACABAmount(initial_supply, {"from": accounts[0]})
    tx = token.approve(pool, initial_supply, {"from": accounts[0]})
    tx.wait(1)
    tx = pool.buyACAB(initial_supply, estimatedAmountOut, {"from": accounts[0]})
    tx.wait(1)

    acab = interface.IERC20(pool.getACABAddress({"from": accounts[0]}))
    amountOut = acab.balanceOf(accounts[0], {"from": accounts[0]})
    assert amountOut == estimatedAmountOut

    tx = acab.approve(pool, initial_supply, {"from": accounts[0]})
    tx.wait(1)
    tx = pool.sellACAB(initial_supply/2, initial_supply, {"from": accounts[0]})
    tx.wait(1)
    assert(token.balanceOf(accounts[0], {"from": accounts[0]}) == int(initial_supply*0.9))