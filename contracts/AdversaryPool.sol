pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./TokenA.sol";
import "./TokenB.sol";

contract AdversaryPool {
    using SafeERC20 for IERC20;
    using SafeERC20 for TokenA;
    using SafeERC20 for TokenB;
    //TokenA token
    TokenA public tokenA;
    //TokenB token
    TokenB public tokenB;
    //backing token (backingToken)
    IERC20 private backingToken;
    //Amount of backing token (backingToken) backing TokenA and TokenB. Tracked seperately to simulate having an independent liquidity pool for each.
    uint256 private tokenABacking;
    uint256 private tokenBBacking;
    //Address to pay dev fees to
    address dev;
    //Addresses for donation payouts
    address tokenADonation;
    address tokenBDonation;
    //Amount of each token type paid out to dev fee
    uint256 tokenADonated;
    uint256 tokenBDonated;
    /*
    Create new adversary pool with backingTokenAddress as address of backing token (DAI), and initialSupply number of TokenA and TokenB in the pool.
    In an adversary pool, buying one token decreases the value of the other.
    */
    constructor(address backingTokenAddress, uint256 initialSupply, address devAddress, address tokenADonationAddress, address tokenBDonationAddress) {
        backingToken = IERC20(backingTokenAddress);
        tokenA = new TokenA(initialSupply);
        tokenB = new TokenB(initialSupply);
        dev = devAddress;
        tokenADonation = tokenADonationAddress;
        tokenBDonation = tokenBDonationAddress;
        tokenABacking = 0;
        tokenBBacking = 0;
        tokenADonated = 0;
        tokenBDonated = 0;
    }
    /*
    Exchange backing token (DAI) for TokenB. minOut specifies a minimum output amount to limit sandwich attacks, and should be set 
    before the transaction begins.
    */
    function buyTokenB(uint256 amountIn, uint256 minOut) external {
        uint256 k = calculateK(tokenB.balanceOf(address(this)), tokenBBacking, tokenA.balanceOf(address(this)));
        uint256 fee = amountIn / uint256(50);
        uint256 amountOut = calculateBuy(
            amountIn-fee, 
            tokenB.balanceOf(address(this)), 
            tokenBBacking, 
            tokenA.balanceOf(address(this))
        );
        require(amountOut >= minOut, "Amount out would be below specified minimum.");
        backingToken.safeTransferFrom(msg.sender, address(this), amountIn-fee);
        backingToken.safeTransferFrom(msg.sender, dev, fee/2);
        backingToken.safeTransferFrom(msg.sender, tokenBDonation, fee/2);
        tokenBDonated += fee;
        tokenBBacking += amountIn-fee;
        tokenB.safeTransfer(msg.sender, amountOut);
        require(k <= calculateK(tokenB.balanceOf(address(this)), tokenBBacking, tokenA.balanceOf(address(this))), "Invalid K");
        require(tokenABacking + tokenBBacking == backingToken.balanceOf(address(this)), "Invalid backing");
        emit Swap(amountIn-fee, amountOut, address(backingToken), address(tokenB));
    }
    /*
    Exchange TokenB for backing token (DAI). minOut specifies a minimum output amount to limit sandwich attacks, and should be set 
    before the transaction begins.
    */
    function sellTokenB(uint256 amountIn, uint256 minOut) external {
        uint256 k = calculateK(tokenB.balanceOf(address(this)), tokenBBacking, tokenA.balanceOf(address(this)));
        uint256 amountOut = calculateSell(
            amountIn, 
            tokenB.balanceOf(address(this)), 
            tokenBBacking, 
            tokenA.balanceOf(address(this))
        );
        require(amountOut >= minOut, "Amount out would be below specified minimum.");
        tokenB.safeTransferFrom(msg.sender, address(this), amountIn);
        tokenBBacking -= amountOut;
        backingToken.safeTransfer(msg.sender, amountOut);
        require(k <= calculateK(tokenB.balanceOf(address(this)), tokenBBacking, tokenA.balanceOf(address(this))), "Invalid K");
        require(tokenABacking + tokenBBacking == backingToken.balanceOf(address(this)), "Invalid backing");
        emit Swap(amountIn, amountOut, address(tokenB), address(backingToken));
    }
    /*
    Exchange backing token (DAI) for TokenA. minOut specifies a minimum output amount to limit sandwich attacks, and should be set 
    before the transaction begins.
    */
    function buyTokenA(uint256 amountIn, uint256 minOut) external {
        uint256 k = calculateK(tokenA.balanceOf(address(this)), tokenABacking, tokenB.balanceOf(address(this)));
        uint256 fee = amountIn / uint256(50);
        uint256 amountOut = calculateBuy(
            amountIn-fee, 
            tokenA.balanceOf(address(this)), 
            tokenABacking, 
            tokenB.balanceOf(address(this))
        );
        require(amountOut >= minOut, "Amount out would be below specified minimum.");
        backingToken.safeTransferFrom(msg.sender, address(this), amountIn-fee);
        backingToken.safeTransferFrom(msg.sender, dev, fee/2);
        backingToken.safeTransferFrom(msg.sender, tokenADonation, fee/2);
        tokenADonated += fee;
        tokenABacking += amountIn-fee;
        tokenA.safeTransfer(msg.sender, amountOut);
        require(k <= calculateK(tokenA.balanceOf(address(this)), tokenABacking, tokenB.balanceOf(address(this))), "Invalid K");
        require(tokenABacking + tokenBBacking == backingToken.balanceOf(address(this)), "Invalid backing");
        emit Swap(amountIn-fee, amountOut, address(backingToken), address(tokenA));
    }
    /*
    Exchange TokenA for backing token (DAI). minOut specifies a minimum output amount to limit sandwich attacks, and should be set 
    before the transaction begins.
    */
    function sellTokenA(uint256 amountIn, uint256 minOut) external {
        uint256 k = calculateK(tokenA.balanceOf(address(this)), tokenABacking, tokenB.balanceOf(address(this)));
        uint256 amountOut = calculateSell(
            amountIn, 
            tokenA.balanceOf(address(this)), 
            tokenABacking, 
            tokenB.balanceOf(address(this))
        );
        require(amountOut >= minOut, "Amount out would be below specified minimum.");
        tokenA.safeTransferFrom(msg.sender, address(this), amountIn);
        tokenABacking -= amountOut;
        backingToken.safeTransfer(msg.sender, amountOut);
        require(k <= calculateK(tokenA.balanceOf(address(this)), tokenABacking, tokenB.balanceOf(address(this))), "Invalid K");
        require(tokenABacking + tokenBBacking == backingToken.balanceOf(address(this)), "Invalid backing");
        emit Swap(amountIn, amountOut, address(tokenA), address(backingToken));
    }

    /*
    Get the amount of TokenB recieved for depositing specified amount of backing token (DAI).
    */
    function getBuyTokenBAmount(uint256 amountIn) external view returns (uint256) {
        uint256 fee = amountIn / uint256(100);
        return calculateBuy(amountIn-fee, tokenB.balanceOf(address(this)), tokenBBacking, tokenA.balanceOf(address(this)));
    }
    /*
    Get the amount of DAI recieved for depositing specified amount of TokenB
    */
    function getSellTokenBAmount(uint256 amountIn) external view returns (uint256) {
        return calculateSell(amountIn, tokenB.balanceOf(address(this)), tokenBBacking, tokenA.balanceOf(address(this)));
    }
    /*
    Get the amount of TokenA recieved for depositing specified amount of backing token (DAI).
    */
    function getBuyTokenAAmount(uint256 amountIn) external view returns (uint256) {
        uint256 fee = amountIn / uint256(100);
        return calculateBuy(amountIn-fee, tokenA.balanceOf(address(this)), tokenABacking, tokenB.balanceOf(address(this)));
    }
    /*
    Get the amount of DAI recieved for depositing specified amount of TokenA
    */
    function getSellTokenAAmount(uint256 amountIn) external view returns (uint256) {
        return calculateSell(amountIn, tokenA.balanceOf(address(this)), tokenABacking, tokenB.balanceOf(address(this)));
    }
    /*
    Get the address of the TokenB ERC20 token
    */
    function getTokenBAddress() external view returns (address) {
        return address(tokenB);
    }
    /*
    Get the address of the TokenA ERC20 token
    */
    function getTokenAAddress() external view returns (address) {
        return address(tokenA);
    }
    /*
    Get the address of the backing ERC20 token (DAI)
    */
    function getBackingAddress() external view returns (address) {
        return address(backingToken);
    }
    /*
    Get the amount of backing token (backingToken) backing TokenA
    */
    function getTokenABackingAmount() external view returns (uint256) {
        return tokenABacking;
    }
    /*
    Get the amount of backing token (backingToken) backing TokenB
    */
    function getTokenBBackingAmount() external view returns (uint256) {
        return tokenBBacking;
    }

    /*
    Solve for amount out that preserves our invariant product formula given amount in of pool token (TokenA or TokenB), such that:
    boughtTokenBalance * (otherTokenBalance + boughtTokenBacking) = 
    (boughtTokenBalance - amountOut) * (otherTokenBalance + (boughtTokenBacking + amountIn))
    */
    function calculateBuy(
        uint256 amountIn, 
        uint256 boughtTokenBalance, 
        uint256 boughtTokenBacking,
        uint256 otherTokenBalance
    ) internal pure returns(uint256){
        return boughtTokenBalance * amountIn / (boughtTokenBacking + otherTokenBalance + amountIn);
    }
    /*
    Solve for amount out that preserves our invariant product formula given amount in of backing token (DAI, MATIC, etc.), such that:
    boughtTokenBalance * (otherTokenBalance + boughtTokenBacking) = 
    (boughtTokenBalance + amountIn) * (otherTokenBalance + (boughtTokenBacking - amountOut))
    */
    function calculateSell(
        uint256 amountIn, 
        uint256 soldTokenBalance, 
        uint256 soldTokenBacking,
        uint256 otherTokenBalance
    ) internal pure returns(uint256){
        return amountIn * (otherTokenBalance + soldTokenBacking) / (soldTokenBalance + amountIn);
    }
    function calculateK(
        uint256 tokenBalance,
        uint256 tokenBacking,
        uint256 otherTokenBalance
    ) internal pure returns(uint256) {
        return tokenBalance * (tokenBacking + otherTokenBalance);
    }
    /*
    Emitted when a token is bought or sold with the adversarial pool.
    amountIn: amount of token put in pool.
    amountOut: amount of token recieved from pool.
    tokenIn: the token (TokenA, TokenB, or backing) put into the pool.
    tokenOut: the token (TokenA, TokenB, or backing) recieved from the pool.
    */
    event Swap(
        uint256 amountIn,
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    );

    
}