pragma solidity ^0.8.0;


interface ICurve3Minter {
    function mint(address gauge_addr) external;
    function mint_for(address gauge_addr, address _for) external;
    function minted(address _for, address gauge_addr) external view returns(uint256);

    function toggle_approve_mint(address minting_user) external;

    function token() external view returns(address);
}