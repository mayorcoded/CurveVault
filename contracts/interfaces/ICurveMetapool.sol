pragma solidity ^0.8.0;

interface ICurveMetapool {
    function coins() external view returns (address[2] memory);
    function exchange(uint256 i, uint256 j, uint256 _dx, uint256 _min_dy) external returns(uint256);
    function exchange_underlying(uint256 i, uint256 j, uint256 _dx, uint256 _min_dy) external returns(uint256);
}
