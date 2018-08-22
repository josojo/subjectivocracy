var RealityFund = artifacts.require("./RealityFund.sol");
var RealityCheck = artifacts.require("./RealityCheck.sol");

var ForkonomicToken = artifacts.require("./ForkonomicToken.sol")
var Distribution= artifacts.require("./Distribution.sol");

const feeForRealityToken = 1000000000000000000

module.exports = function(deployer, network, accounts) {
    deployer.deploy(RealityFund)
    .then(()=> deployer.deploy(Distribution))
    .then(()=> deployer.deploy(ForkonomicToken, RealityFund.address, [Distribution.address]))
    .then(()=> deployer.deploy(RealityCheck))
    .then(()=> Distribution.deployed())
    .then((t)=> t.setRealityVariables(ForkonomicToken.address, RealityCheck.address, RealityFund.address))
}
