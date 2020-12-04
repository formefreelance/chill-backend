const ChillFinance = artifacts.require("ChillFinance");
const ChillToken = artifacts.require("ChillToken");

module.exports = function(deployer) {
  var unirouter = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
  var unifactory = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
  var weth= "0xd0A1E359811322d97991E03f863a0C30C2cF029C";
  // var chillToken = "0x49245e07Cf3A358Dc80Ac92FEd5444762718807B";
  deployer.deploy(ChillToken, unirouter, unifactory, weth).then(async function(chillToken) {
    await deployer.deploy(ChillFinance, chillToken.address, "0x48845392F5a7c6b360A733e0ABE2EdcC74f1F4d6", "0")
        .then(async function(chillFinance) {
          await chillToken.transferOwnership(chillFinance.address);
          await chillFinance.add("100", "0xBbB8eeA618861940FaDEf3071e79458d4c2B42e3", true);
          await chillFinance.add("200", "0x3C30B799bB64485FDB52f249DA0e74F67f35b5E7", true);
    });
  });
};
