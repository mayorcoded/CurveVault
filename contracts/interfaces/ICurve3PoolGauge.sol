pragma solidity ^0.8.0;

interface ICurve3PoolGauge {
    function lp_token() external view returns(address);
    function crv_token() external view returns(address);

    function balanceOf(address addr) external view returns (uint256);
    function deposit(uint256 _value) external;
    function withdraw(uint256 _value) external;

    function claimable_tokens(address addr) external returns (uint256);
    function minter() external view returns(address);

    function integrate_fraction(address _for) external view returns(uint256);
    function user_checkpoint(address _for) external returns(bool);
}