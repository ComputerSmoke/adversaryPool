// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract tokenB is ERC20 {
    constructor(uint256 initialSupply) ERC20("tokenB", "TB") {
        _mint(msg.sender, initialSupply);
    }
}