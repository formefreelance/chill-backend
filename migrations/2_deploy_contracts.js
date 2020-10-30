const ChillFinance = artifacts.require("ChillFinance");
const ChillToken = artifacts.require("ChillToken");
const ERC20 = artifacts.require('ERC20');
module.exports = async function(deployer) {
  var ethDaiPairforKovan = "0xBbB8eeA618861940FaDEf3071e79458d4c2B42e3";
  var unirouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  var unifactory = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
  var weth= "0xd0A1E359811322d97991E03f863a0C30C2cF029C";
  var account = "0x48845392F5a7c6b360A733e0ABE2EdcC74f1F4d6";
  var deadline = 1666671378;

  deployer.deploy(ChillToken, unirouter, unifactory, weth).then(async function(chillToken) {
    await chillToken.createPair(chillToken.address, weth);
    let token1 = await ERC20.at(chillToken.address);
    await token1.approve(chillToken.address, '2000000000000000000000');
    let token2 = await ERC20.at("0xd0A1E359811322d97991E03f863a0C30C2cF029C");
    await token2.approve(chillToken.address, '100000000000000');
    await chillToken.addLiquidity(chillToken.address, weth, "2000000000000000000000", "100000000000000", "0", "0", account, deadline, { value: '100000000000000'});
    return deployer.deploy(ChillFinance, ChillToken.address, "0x48845392F5a7c6b360A733e0ABE2EdcC74f1F4d6", ethDaiPairforKovan)
        .then(async function(chillFinance) {
          await chillToken.transferOwnership(chillFinance.address);
          await chillFinance.add("100", "0xBbB8eeA618861940FaDEf3071e79458d4c2B42e3", true);
          await chillFinance.add("300", "0x22C648CD8B6a91d24E8449cBc8acF53fcf565aE0", true);
          await chillFinance.add("200", "0x3C30B799bB64485FDB52f249DA0e74F67f35b5E7", true);
          await chillFinance.setStablePairAddress("0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD", "1000000000000000000");
    });
  });
};
