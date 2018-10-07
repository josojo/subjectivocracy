const ForkonomicSystem = artifacts.require("ForkonomicSystem.sol")


const {
  assertRejects,
  timestamp,
  increaseTime,
  increaseTimeTo,
  padAddressToBytes32,
} = require("./utilities.js")


contract("ForkonomicSystem", (accounts) => {
  const [operator, arbitrator1, arbitrator2, nonArbitrator] = accounts
    it("Create new arbitrator list", async () => {
      const fSystem = await ForkonomicSystem.deployed()
      const keyForArbitrators = await fSystem.createArbitratorWhitelist.call([arbitrator1, arbitrator2])
      await fSystem.createArbitratorWhitelist([arbitrator1, arbitrator2])

      const genesis_branch = await fSystem.genesisBranchHash();
      const waitingTime = (await fSystem.WINDOWTIMESPAN()).toNumber()+1
    await increaseTime(waitingTime)
      const newBranchHash =  await fSystem.createBranch.call(genesis_branch, keyForArbitrators)
      await fSystem.createBranch(genesis_branch, keyForArbitrators)

      assert.isTrue(await  fSystem.isArbitratorWhitelisted(arbitrator1, newBranchHash), "arbitrator1 should have been whitelisted");

      assert.isTrue(await  fSystem.isArbitratorWhitelisted(arbitrator2, newBranchHash), "arbitrator2 should have been whitelisted");

      assert.isFalse(await  fSystem.isArbitratorWhitelisted(nonArbitrator, newBranchHash), "arbitrator1 should not have been whitelisted");
  })

	it("tests parentHash", async () => {
	      const fSystem = await ForkonomicSystem.deployed()
	      const keyForArbitrators = await fSystem.createArbitratorWhitelist.call([arbitrator1])
	      await fSystem.createArbitratorWhitelist([arbitrator1, arbitrator2])

	      const genesis_branch = await fSystem.genesisBranchHash();
	      const waitingTime = (await fSystem.WINDOWTIMESPAN()).toNumber()+1
    	  await increaseTime(waitingTime)
	      const newBranchHash =  await fSystem.createBranch.call(genesis_branch, keyForArbitrators)
	      await fSystem.createBranch(genesis_branch, keyForArbitrators)

	      assert.equal(await  fSystem.branchParentHash(newBranchHash), genesis_branch, "parentHash is not stored correctly");

	      assert.notEqual(await  fSystem.branchParentHash(newBranchHash), newBranchHash, "parentHash is not stored correctly");
	  })
})
