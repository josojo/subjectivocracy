var ForkonomicSystem = artifacts.require("./ForkonomicSystem.sol");
var RealityCheck = artifacts.require("./RealityCheck.sol");

var ForkonomicToken = artifacts.require("./ForkonomicToken.sol")
var Distribution= artifacts.require("./Distribution.sol");
var ForkonomicETTF = artifacts.require("./ForkonomicETTF.sol")

const feeForRealityToken = 1000000000000000000

module.exports = function(deployer, network, accounts) {
    deployer.deploy(ForkonomicSystem)
    .then(()=> deployer.deploy(Distribution))
    .then(()=> deployer.deploy(RealityCheck))
    .then(()=> deployer.deploy(ForkonomicToken, ForkonomicSystem.address, [accounts[0], accounts[1], accounts[2], Distribution.address]))
    .then(()=> deployer.deploy(ForkonomicETTF, RealityCheck.address, ForkonomicSystem.address, []))
}
