const hre = require("hardhat");
const { expect, } = require("chai");
const {before} = require("mocha/mocha");
const ERC20Abi = require('../test/abi/ERC20.json');
const Curve3PoolDepositAbi = require('../test/abi/Curve3poolDeposit.json');
const Curve3PoolLPTokenAbi = require('../test/abi/Curve3PoolLPToken.json');
const Curve3PoolLiquidityGaugeAbi = require('../test/abi/Curve3poolLiquidityGauge.json');

describe("Curve 3Pool Vault", function() {
  let DAI;
  let CRV;
  let accounts;
  let impersonatedSigner;
  let Curve3PoolVaultContract;
  let Curve3PoolDepositContract;
  let Curve3PoolLPTokenContract;
  let Curve3PoolLiquidityGaugeContract;

  const CRVAddress = "0xD533a949740bb3306d119CC777fa900bA034cd52";
  const DAIAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
  const impersonatedAccount = "0x92d934e043c4ddf3a30e666de74cb21668134d65";
  const Curve3PoolLPTokenAddress = "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490";
  const Curve3PoolLiquidityGaugeAddress = "0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A";
  const Curve3PoolDepositContractAddress = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7";

  let hreProvider;
  before(async function (){
    hreProvider = await hre.network.provider;

    CRV = await ethers.getContractAt(ERC20Abi, CRVAddress);
    DAI = await ethers.getContractAt(ERC20Abi, DAIAddress);

    Curve3PoolDepositContract = await ethers.getContractAt(
        Curve3PoolDepositAbi,
        Curve3PoolDepositContractAddress
    );

    Curve3PoolLPTokenContract = await ethers.getContractAt(
        Curve3PoolLPTokenAbi,
        Curve3PoolLPTokenAddress
    );

    Curve3PoolLiquidityGaugeContract = await ethers.getContractAt(
        Curve3PoolLiquidityGaugeAbi,
        Curve3PoolLiquidityGaugeAddress
    );

    const Curve3PoolVaultFactory = await ethers.getContractFactory("Curve3poolVault");
    Curve3PoolVaultContract = await Curve3PoolVaultFactory.deploy(
        Curve3PoolDepositContractAddress,
        Curve3PoolLPTokenAddress,
        Curve3PoolLiquidityGaugeAddress);

    accounts = await ethers.getSigners();
    await hreProvider.request({
      method: "hardhat_impersonateAccount",
      params: [impersonatedAccount],
    });

    impersonatedSigner = await ethers.getSigner(impersonatedAccount);
  });

  it("should connect to mainnet contracts", async function () {
    const virtualPrice = await Curve3PoolDepositContract.get_virtual_price();
    expect(virtualPrice).to.not.be.null;

    const lpTokenSymbol = await Curve3PoolLPTokenContract.symbol();
    expect(lpTokenSymbol).to.not.be.null;

    const curveToken = await Curve3PoolLiquidityGaugeContract.crv_token();
    expect(curveToken).to.not.be.null;
  });

  it("should send DAI tokens from impersonated account to account[0]", async function (){
    const prevBalance = await DAI.balanceOf(accounts[0].address);
    await DAI.connect(impersonatedSigner).transfer(accounts[0].address, 10000, { gasLimit: 1000000 });
    const currentBalance = await DAI.balanceOf(accounts[0].address);
    expect(currentBalance - prevBalance).to.equal(10000);
  });

  it("should deposit DAI into vault and get lp tokens in return", async function (){
    await DAI.approve(Curve3PoolVaultContract.address, 100);
    await Curve3PoolVaultContract.deposit(100, { gasLimit: 1000000 });
    const vault3CRVBalance = await Curve3PoolLPTokenContract.balanceOf(Curve3PoolVaultContract.address);
    expect(vault3CRVBalance).to.be.equal(0);

    const senderLpBalance = await Curve3PoolVaultContract.balanceOf(accounts[0].address);
    expect(senderLpBalance).to.be.above(0);
  }).timeout(50000);

  it("should harvest CRV from the Liquidity Gauge and swap it for DAI", async function (){
    await DAI.approve(Curve3PoolVaultContract.address, 100);
    const claimableCrvTokens = await Curve3PoolLiquidityGaugeContract.claimable_tokens(
        Curve3PoolVaultContract.address
    );

    await Curve3PoolVaultContract.harvest({ gasLimit: 1000000 });
    const curveBalance = await CRV.balanceOf(Curve3PoolVaultContract.address, { gasLimit: 1000000 });
    expect(claimableCrvTokens).to.be.equal(curveBalance);
  });

  it("should withdraw LP tokens and receive underlying DAI in return", async function (){
    let senderLpTokenBalance = await Curve3PoolVaultContract.balanceOf(accounts[0].address);
    senderLpTokenBalance = senderLpTokenBalance.toString();
    expect(parseInt(senderLpTokenBalance.toString())).to.be.above(0);

    await Curve3PoolVaultContract.withdraw(senderLpTokenBalance, { gasLimit: 1000000 });

    const senderLpTokenBalanceAfterWithdrawal = await Curve3PoolVaultContract.balanceOf(accounts[0].address);
    expect(senderLpTokenBalanceAfterWithdrawal).to.equal(0);

    const lpTokenBalance = await Curve3PoolLPTokenContract.balanceOf(Curve3PoolVaultContract.address);
    expect(lpTokenBalance).to.be.equal(0);
  });

  it("should return exchange rate of the lp vs underlying token", async function (){
    const exchangeRate = await Curve3PoolVaultContract.exchangeRate();
    expect(parseInt(exchangeRate.toString())).to.be.above(0);
  });
});
