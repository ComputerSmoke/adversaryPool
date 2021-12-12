// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract tokenA is ERC20 {
    constructor(uint256 initialSupply) tokenA("Token A", "TA") {
        _mint(msg.sender, initialSupply);
    }
}