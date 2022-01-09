pragma solidity ^0.8.0;

library StableCoins {
    address constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function underlyingCoins() internal view returns(address[3] memory){
        address[3] memory coins = [DAI, USDC, USDT];
        return coins;
    }
}
