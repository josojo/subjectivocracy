var RealityFund = artifacts.require("./RealityFund.sol");
var ForkonomicToken = artifacts.require("./ForkonomicToken.sol")
var InitialDistribution= artifacts.require("./Distribution.sol");

const feeForRealityToken = 1000000000000000000

module.exports = function(deployer, network, accounts) {
    deployer.deploy(RealityFund)
    .then((t)=> deployer.deploy(Distribution))
    .then((t)=> deployer.deploy(ForkonomicToken, RealityFund.address, [Distribution.address]))
}
