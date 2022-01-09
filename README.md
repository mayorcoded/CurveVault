# `CurveFi 3Pool Vault Integration`
![CurveVault](https://user-images.githubusercontent.com/17001801/148681816-05ee3dd2-557b-4e87-a479-18114ee0a38a.jpeg)

This is an implementation of a single-asset DAI vault that earns profit through depositing funds into the Curve 3pool.
For accounting purposes, the vault is an ERC20 token, it tracks the funds of individual depositors and mints an LP token
to represent their position in the vault. The vault implements the follow functions:
- Deposit: The vault allows a user deposit DAI and receive LP tokens in return. The DAI is then deposited into the Curve
            3Pool by the vault for the 3Pool LP tokens. To gain CRV rewards on the LP token, the Curve 3Pool LP token is
            deposited into the 3Pool Liquidity Gauge for liquidity mining. 
- Withdraw: The vault withdraws the user's deposited asset from the 3Pool pool and Liquidity Gauge. The 3Pool LP tokens 
            is burned and the equivalent in DAI is returned to the user. 
- Harvest: The vault claims accumulated CRV rewards from the 3Pool Liquidity Gauge and converts them to DAI on Uniswap V2.
- Exchange Rate: The vault returns the underlying exchange rate between the underlying token (DAI) and the vault LP token.
       The exchange rate is calculated by dividing the total value locked (TVL) into the vault by the total 
       supply of the vault's LP token. The TVL is calculated by adding the vault's unstaked and staked 3CRV LP tokens.



### Setup
Run the command `$ npm install` to install all the dependencies specified in `package.json`.


### Testing
Run `$ npx hardhat test` to start the forked mainnet network and run all tests from the `test/` directory.

#### *Disclaimer:* 
The contracts in this project are written to demonstrate how to integrate with Curve 3Pool's pool, 
they are unaudited and therefore could be potentially unsafe. Use them as references and test examples only.
