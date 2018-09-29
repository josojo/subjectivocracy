var ForkonomicSystem = artifacts.require("./ForkonomicSystem.sol");
var RealityCheck = artifacts.require("./RealityCheck.sol");

var ForkonomicToken = artifacts.require("./ForkonomicToken.sol")
var Distribution= artifacts.require("./Distribution.sol");
var ForkonomicETF = artifacts.require("./ForkonomicETF.sol")

const feeForRealityToken = 1000000000000000000

module.exports = function(deployer, network, accounts) {
    deployer.deploy(ForkonomicSystem)
    .then(()=> deployer.deploy(Distribution))
    .then(()=> deployer.deploy(RealityCheck))
    .then(()=> deployer.deploy(ForkonomicToken, ForkonomicSystem.address, [accounts[1], accounts[2], accounts[3], Distribution.address]))
    .then(()=> {
    	deployer.deploy(ForkonomicETF, RealityCheck.address, ForkonomicSystem.address)})
}
