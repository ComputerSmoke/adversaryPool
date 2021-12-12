from brownie import BackingToken, AdversaryPool, network, accounts
from web3 import Web3
from brownie.network import gas_price
gas_price("60 gwei")
initial_supply = Web3.toWei(1000000, "ether")

def get_account():
    if network.show_active() == "development":
        return accounts[0]
    else:
        return accounts.load("met")

def main():
    account = get_account()
    token = BackingToken.deploy(initial_supply, {"from": account})
    print("token deployed")
    pool = AdversaryPool.deploy(token, initial_supply, {"from": account})
    print("pool deployed")
