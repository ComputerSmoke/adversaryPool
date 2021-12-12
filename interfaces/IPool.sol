// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface Pool {
    function buy(uint256 amountIn, uint256 minOut) external;
    function sell(uint256 amountIn, uint256 minOut) external;
}