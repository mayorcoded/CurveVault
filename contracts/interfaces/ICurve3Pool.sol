pragma solidity ^0.8.0;

interface ICurve3Pool {
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;
    function get_virtual_price() external view returns(uint256);
    function remove_liquidity(uint256 _amount, uint256[3] calldata min_amounts) external;
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);
    function calc_token_amount(uint256[3] calldata amounts, bool deposit) external view returns(uint256);
}
