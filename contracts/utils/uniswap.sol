pragma solidity ^0.8.0;

import "./constants.sol";
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

library uniswap {
    uint24 constant poolFee = 3000;
    IUniswapV2Router02 internal constant uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function swapCrvForDai(uint256 crvAmountIn) internal {
        TransferHelper.safeApprove(StableCoins.CRV, address(uniswapRouter), crvAmountIn);

        address[] memory path = new address[](2);
        path[0] = StableCoins.CRV;
        path[1] = StableCoins.DAI;

        uniswapRouter.swapExactTokensForTokens(
            crvAmountIn, 0, path, address (this), block.timestamp + 15
        );
    }

}
