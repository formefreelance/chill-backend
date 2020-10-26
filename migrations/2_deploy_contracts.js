const ChillFinance = artifacts.require("ChillFinance");
const ChillToken = artifacts.require("ChillToken");

module.exports = function(deployer) {
  var ethDaiPairforKovan = "0xBbB8eeA618861940FaDEf3071e79458d4c2B42e3";
  var unirouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  var unifactory = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
  var weth= "0xd0A1E359811322d97991E03f863a0C30C2cF029C";
  // var amountA = 200000000;
  // var amountB = 1000000;
  var account = "0x48845392F5a7c6b360A733e0ABE2EdcC74f1F4d6";
  var deadline = 1666671378;


  deployer.deploy(ChillToken, unirouter, unifactory, weth).then(function(chillToken) {
    return deployer.deploy(ChillFinance, ChillToken.address, "0x48845392F5a7c6b360A733e0ABE2EdcC74f1F4d6", ethDaiPairforKovan)
        .then(async function(chillFinance) {
          await chillToken.transferOwnership(chillFinance.address);
    });
  });
};
