pragma solidity ^0.8.0;

import "./utils/constants.sol";
import "./utils/uniswap.sol";
import "./interfaces/ICurve3Pool.sol";
import "./interfaces/ICurve3PoolLp.sol";
import "./interfaces/ICurve3Minter.sol";
import "./interfaces/ICurve3PoolGauge.sol";
import "./interfaces/ICurveMetapool.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Curve3poolVault is ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private _exchangeRate;
    address immutable Curve3Pool;
    address immutable Curve3PoolLp;
    address immutable Curve3PoolLiquidityGauge;

    event CrvTokensHarvested(uint256 indexed _crvAmount);
    event AssetDeposited(
        uint256 indexed depositAmount,
        address indexed sender,
        uint256 indexed lpTokenAmount
    );
    event AssetWithdrawn(
        uint256 indexed withdrawalAmount,
        address indexed receiver,
        uint256 indexed lpTokenAmount
    );


    /**
     * @notice Instantiate Vault, ERC20 token, and other constants
     * @param _curve3Pool Curve 3Pool contract
     * @param _curve3PoolLp Curve 3Pool LP contract
     * @param _curve3PoolLiquidityGauge Curve 3pool Liquidity Gauge
     */
    constructor(
        address _curve3Pool,
        address _curve3PoolLp,
        address _curve3PoolLiquidityGauge
    ) ERC20("DAI-3CRV-LP", "DAI-3CRV") {
        Curve3Pool = _curve3Pool;
        Curve3PoolLp = _curve3PoolLp;
        Curve3PoolLiquidityGauge = _curve3PoolLiquidityGauge;
    }

    /**
    * @notice Deposit DAI into the Curve 3Pool contract and mint LP tokens in return
    * @dev the contract's ERC20 is minted as LP tokens for the sender
    * @param underlyingAmount the deposit DAI amount from the sender
    * @return lpTokenAmount amount of LP tokens minted for sender
    */
    function deposit(uint256 underlyingAmount) external returns(uint256 lpTokenAmount){
        address[3] memory coins = StableCoins.underlyingCoins();
        uint256[3] memory amounts = [underlyingAmount, 0, 0];

        for(uint256 i = 0; i < coins.length; i++){
            IERC20(coins[i]).safeTransferFrom(msg.sender, address (this), amounts[i]);
            IERC20(coins[i]).safeApprove(Curve3Pool, amounts[i]);
        }

        //Step 1: deposit stable token into the liquidity pool to get Curve LP tokens
        ICurve3Pool(Curve3Pool).add_liquidity(amounts, 0);

        //Step 2: calculate the lp tokens minted from the deposit
        uint256 sender3PoolLPBalance = ICurve3Pool(Curve3Pool).calc_token_amount(amounts, true);
        _mint(msg.sender, sender3PoolLPBalance);

        //step 3: stake the lp tokens into a gauge and get CRV rewards
        IERC20(Curve3PoolLp).safeApprove(Curve3PoolLiquidityGauge, sender3PoolLPBalance);
        ICurve3PoolGauge(Curve3PoolLiquidityGauge).deposit(sender3PoolLPBalance);
        emit AssetDeposited(underlyingAmount, msg.sender, lpTokenAmount);

        _exchangeRate =  exchangeRate();
        return lpTokenAmount;
    }

    /**
     * @notice Harvest CRV rewards from the Curve 3Pool Liquidity Gauge
     * @dev there is a check to ensure that the mintable CRV is greater 0 to avoid breaking the function
     * @return totalUnMintedCrv is the amount of mintable CRV rewards
     */
    function harvest() external returns (uint256) {
        address minter = ICurve3PoolGauge(Curve3PoolLiquidityGauge).minter();

        uint256 totalMintableCrv = ICurve3PoolGauge(Curve3PoolLiquidityGauge).integrate_fraction(address (this));
        uint256 totalMintedCrv = ICurve3Minter(minter).minted(address (this), Curve3PoolLiquidityGauge);
        uint256 totalUnMintedCrv = totalMintableCrv.sub(totalMintedCrv);

        if(totalUnMintedCrv > 0){
            ICurve3Minter(minter).mint(Curve3PoolLiquidityGauge);
            uniswap.swapCrvForDai(totalUnMintedCrv);
            emit CrvTokensHarvested(totalUnMintedCrv);
        }

        return totalUnMintedCrv;
    }

    /**
     * @notice Withdraw underlying asset from the vault based on LP token amount
     * @dev The lpAmount is equivalent to the amount of 3CRV LP token minted from the 3Pool ie. 1 DAI-3CRV == 1 3CRV
     * @dev The lpAmount of the minted DAI-3CRV is burned during withdrawal to keep a correct balance per sender
     * @param lpAmount Amount of
     */
    function withdraw(uint256 lpAmount) external {
        require(balanceOf(msg.sender) >= lpAmount, "Insufficient LP token balance.");
        ICurve3PoolGauge(Curve3PoolLiquidityGauge).withdraw(lpAmount);
        _burn(msg.sender, lpAmount);
        uint256[3] memory minAmounts = [uint256(0), uint256(0), uint(0)];
        ICurve3Pool(Curve3Pool).remove_liquidity(lpAmount, minAmounts);
        IERC20(StableCoins.DAI).transfer(msg.sender, IERC20(StableCoins.DAI).balanceOf(address (this)));
        emit AssetWithdrawn(lpAmount, msg.sender, IERC20(StableCoins.DAI).balanceOf(address (this)));
    }

    /**
     * @notice Calculates the exchange rate between the underlying token DAI and the lpToken DAI-3CRV
     * @dev The exchange rate is calculated by dividing the total value locked (TVL) into the vault by the total supply of
     * @dev DAI-3CRV LP token. The TVL is calculated by adding the vault's unstaked and staked 3CRV LP tokens
     * @return exchangeRate is the calculated exchange rate
     */
    function exchangeRate() public view returns (uint256 exchangeRate) {
        if(_exchangeRate != 0) return _exchangeRate;

        uint256 unstakedLpAmount = IERC20(Curve3PoolLp).balanceOf(address (this));
        uint256 stakedLPAmount = ICurve3PoolGauge(Curve3PoolLiquidityGauge).balanceOf(address (this));
        uint256 lpTokenBalance = unstakedLpAmount.add(stakedLPAmount);

        uint256 totalValueLocked = lpTokenBalance.mul(ICurve3Pool(Curve3Pool).get_virtual_price());
        exchangeRate = totalValueLocked.div(totalSupply());
        return exchangeRate;
    }
}
